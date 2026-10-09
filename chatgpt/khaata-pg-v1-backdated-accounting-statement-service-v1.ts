/**
 * Khaata PG / Hostel V1 — Backdated Accounting + Tenant Statement Service v1
 * STATUS: PROPOSED IMPLEMENTATION.
 */

export type UUID = string;
export type ISODate = string;
export type ISODateTime = string;
export type Minor = number;

export interface DbTx {
  run(sql:string, params?:unknown[]):Promise<void>;
  get<T>(sql:string, params?:unknown[]):Promise<T|undefined>;
  all<T>(sql:string, params?:unknown[]):Promise<T[]>;
}
export interface Db { transaction<T>(fn:(tx:DbTx)=>Promise<T>):Promise<T>; }
export interface Ids { next():UUID; }
export interface Clock { now():ISODateTime; }
export interface AccessGate {
  requireAction(
    tx:DbTx,
    ctx:CommandContext,
    actionKey:string,
    target?:{type:string;id:UUID}
  ):Promise<{state:"allowed";authorizationId?:UUID}|{state:"needs_approval";approvalRequestId:UUID}>;
}
export interface SyncQueue {
  enqueue(tx:DbTx,input:{
    businessId:UUID;
    entityType:string;
    entityId:UUID;
    operation:"insert"|"update"|"append_event"|"retire";
    payload:unknown;
    dependencyIds?:UUID[];
  }):Promise<void>;
}
export interface DomainEvents {
  append(tx:DbTx,event:{
    id:UUID;businessId:UUID;entityType:string;entityId:UUID;eventType:string;
    occurredAt:ISODateTime;recordedAt:ISODateTime;recordedByUserId:UUID;
    deviceId:UUID;payload:unknown;
  }):Promise<void>;
}

export interface CommandContext {
  businessId:UUID;
  actorUserId:UUID;
  deviceId:UUID;
  occurredAt:ISODateTime;
}

export class BackdatedAccountingService {
  constructor(private d:{
    db:Db;ids:Ids;clock:Clock;access:AccessGate;sync:SyncQueue;events:DomainEvents;
  }){}

  async startFromDate(
    ctx:CommandContext,
    input:{
      tenancyId:UUID;
      accountingStartDate:ISODate;
      openingOutstandingMinor:Minor;
      openingTenantCreditMinor:Minor;
      openingSecurityHeldMinor:Minor;
      note?:string;
    }
  ):Promise<{accountingStartId:UUID;openingPositionId:UUID}>{
    for(const [k,v] of Object.entries({
      openingOutstandingMinor:input.openingOutstandingMinor,
      openingTenantCreditMinor:input.openingTenantCreditMinor,
      openingSecurityHeldMinor:input.openingSecurityHeldMinor
    })){
      if(!Number.isInteger(v) || v<0) throw new Error(`INVALID_${k.toUpperCase()}`);
    }

    return this.d.db.transaction(async tx=>{
      const access=await this.d.access.requireAction(
        tx,ctx,"set_opening_balance",{type:"tenancy",id:input.tenancyId}
      );
      if(access.state==="needs_approval") throw new Error(`APPROVAL_REQUIRED:${access.approvalRequestId}`);

      const tenancy=await tx.get<{id:UUID;created_at:string}>(
        `select id,created_at from tenancies where id=? and business_id=?`,
        [input.tenancyId,ctx.businessId]
      );
      if(!tenancy) throw new Error("TENANCY_NOT_FOUND");

      const prior=await tx.get(
        `select id from tenancy_accounting_starts where tenancy_id=?`,
        [input.tenancyId]
      );
      if(prior) throw new Error("ACCOUNTING_START_ALREADY_SET");

      const accountingStartId=this.d.ids.next();
      const openingPositionId=this.d.ids.next();
      const now=this.d.clock.now();

      await tx.run(
        `insert into tenancy_accounting_starts(
          id,business_id,tenancy_id,accounting_path,accounting_start_date,
          created_at,created_by_user_id
        ) values (?,?,?,'start_from_date',?,?,?)`,
        [
          accountingStartId,ctx.businessId,input.tenancyId,
          input.accountingStartDate,now,ctx.actorUserId
        ]
      );

      await tx.run(
        `insert into opening_financial_positions(
          id,business_id,tenancy_id,accounting_start_id,effective_date,
          opening_outstanding_minor,opening_tenant_credit_minor,
          opening_security_held_minor,note,created_at,created_by_user_id
        ) values (?,?,?,?,?,?,?,?,?,?,?)`,
        [
          openingPositionId,ctx.businessId,input.tenancyId,accountingStartId,
          input.accountingStartDate,input.openingOutstandingMinor,
          input.openingTenantCreditMinor,input.openingSecurityHeldMinor,
          input.note??null,now,ctx.actorUserId
        ]
      );

      const eventId=this.d.ids.next();
      await this.d.events.append(tx,{
        id:eventId,
        businessId:ctx.businessId,
        entityType:"opening_financial_position",
        entityId:openingPositionId,
        eventType:"opening_financial_position_set",
        occurredAt:`${input.accountingStartDate}T00:00:00Z`,
        recordedAt:now,
        recordedByUserId:ctx.actorUserId,
        deviceId:ctx.deviceId,
        payload:{
          tenancyId:input.tenancyId,
          accountingStartDate:input.accountingStartDate,
          openingOutstandingMinor:input.openingOutstandingMinor,
          openingTenantCreditMinor:input.openingTenantCreditMinor,
          openingSecurityHeldMinor:input.openingSecurityHeldMinor
        }
      });

      await this.d.sync.enqueue(tx,{
        businessId:ctx.businessId,
        entityType:"tenancy_accounting_start",
        entityId:accountingStartId,
        operation:"insert",
        payload:{id:accountingStartId},
        dependencyIds:[input.tenancyId]
      });
      await this.d.sync.enqueue(tx,{
        businessId:ctx.businessId,
        entityType:"opening_financial_position",
        entityId:openingPositionId,
        operation:"insert",
        payload:{id:openingPositionId},
        dependencyIds:[accountingStartId,input.tenancyId]
      });

      return {accountingStartId,openingPositionId};
    });
  }

  async chooseBringExistingHistory(
    ctx:CommandContext,
    input:{tenancyId:UUID;historicalStartDate:ISODate}
  ):Promise<{accountingStartId:UUID}>{
    return this.d.db.transaction(async tx=>{
      const access=await this.d.access.requireAction(
        tx,ctx,"set_opening_balance",{type:"tenancy",id:input.tenancyId}
      );
      if(access.state==="needs_approval") throw new Error(`APPROVAL_REQUIRED:${access.approvalRequestId}`);

      const prior=await tx.get(
        `select id from tenancy_accounting_starts where tenancy_id=?`,
        [input.tenancyId]
      );
      if(prior) throw new Error("ACCOUNTING_START_ALREADY_SET");

      const id=this.d.ids.next();
      const now=this.d.clock.now();

      await tx.run(
        `insert into tenancy_accounting_starts(
          id,business_id,tenancy_id,accounting_path,accounting_start_date,
          created_at,created_by_user_id
        ) values (?,?,?,'bring_existing_history',?,?,?)`,
        [id,ctx.businessId,input.tenancyId,input.historicalStartDate,now,ctx.actorUserId]
      );

      await this.d.sync.enqueue(tx,{
        businessId:ctx.businessId,
        entityType:"tenancy_accounting_start",
        entityId:id,
        operation:"insert",
        payload:{id},
        dependencyIds:[input.tenancyId]
      });

      // Historical transactions are entered/imported through their real typed
      // obligation/payment/charge/security flows. This command does NOT invent them.
      return {accountingStartId:id};
    });
  }

  async correctOpeningPosition(
    ctx:CommandContext,
    input:{
      openingPositionId:UUID;
      correctionType:"outstanding"|"tenant_credit"|"security_held";
      amountDeltaMinor:number;
      reason:string;
    }
  ):Promise<{correctionId:UUID}>{
    if(!Number.isInteger(input.amountDeltaMinor) || input.amountDeltaMinor===0)
      throw new Error("INVALID_CORRECTION_DELTA");
    if(!input.reason.trim()) throw new Error("REASON_REQUIRED");

    return this.d.db.transaction(async tx=>{
      const op=await tx.get<{business_id:UUID;tenancy_id:UUID}>(
        `select business_id,tenancy_id from opening_financial_positions where id=?`,
        [input.openingPositionId]
      );
      if(!op || op.business_id!==ctx.businessId) throw new Error("OPENING_POSITION_NOT_FOUND");

      const access=await this.d.access.requireAction(
        tx,ctx,"correct_opening_balance",{type:"tenancy",id:op.tenancy_id}
      );
      if(access.state==="needs_approval") throw new Error(`APPROVAL_REQUIRED:${access.approvalRequestId}`);

      const correctionId=this.d.ids.next();
      const now=this.d.clock.now();

      await tx.run(
        `insert into opening_position_corrections(
          id,opening_position_id,correction_type,amount_delta_minor,
          reason,occurred_at,created_at,created_by_user_id
        ) values (?,?,?,?,?,?,?,?)`,
        [
          correctionId,input.openingPositionId,input.correctionType,
          input.amountDeltaMinor,input.reason,ctx.occurredAt,now,ctx.actorUserId
        ]
      );

      await this.d.sync.enqueue(tx,{
        businessId:ctx.businessId,
        entityType:"opening_position_correction",
        entityId:correctionId,
        operation:"append_event",
        payload:{id:correctionId},
        dependencyIds:[input.openingPositionId]
      });

      return {correctionId};
    });
  }
}

export interface StatementEntry {
  entryType:string;
  entryId:UUID;
  occurredAt:string;
  debitMinor:Minor;
  creditMinor:Minor;
  label:string;
  isOpening:boolean;
  runningBalanceMinor:Minor;
}

export class TenantStatementQueries {
  constructor(private db:Db){}

  async get(tenancyId:UUID):Promise<{
    entries:StatementEntry[];
    security:Array<{
      entryType:string;
      entryId:UUID;
      occurredAt:string;
      amountMinor:Minor;
      label:string;
      isOpening:boolean;
    }>;
    position:{
      netOutstandingMinor:Minor;
      availableCreditMinor:Minor;
      totalSecurityHeldMinor:Minor;
    };
  }>{
    return this.db.transaction(async tx=>{
      const raw=await tx.all<any>(
        `select entry_type,entry_id,occurred_at,debit_minor,credit_minor,label,is_opening
         from v_tenant_statement_entries
         where tenancy_id=?
         order by occurred_at asc,entry_id asc`,
        [tenancyId]
      );

      let balance=0;
      const entries=raw.map((r:any)=>{
        balance += (r.debit_minor??0) - (r.credit_minor??0);
        return {
          entryType:r.entry_type,
          entryId:r.entry_id,
          occurredAt:r.occurred_at,
          debitMinor:r.debit_minor??0,
          creditMinor:r.credit_minor??0,
          label:r.label,
          isOpening:r.is_opening===1,
          runningBalanceMinor:balance
        };
      });

      const security=await tx.all<any>(
        `select entry_type,entry_id,occurred_at,amount_minor,label,is_opening
         from v_tenant_security_statement
         where tenancy_id=?
         order by occurred_at asc,entry_id asc`,
        [tenancyId]
      );

      const pos=await tx.get<any>(
        `select net_outstanding_minor,available_credit_minor,total_security_held_minor
         from v_tenancy_financial_position where tenancy_id=?`,
        [tenancyId]
      );

      return {
        entries,
        security:security.map((r:any)=>({
          entryType:r.entry_type,
          entryId:r.entry_id,
          occurredAt:r.occurred_at,
          amountMinor:r.amount_minor,
          label:r.label,
          isOpening:r.is_opening===1
        })),
        position:{
          netOutstandingMinor:pos?.net_outstanding_minor??0,
          availableCreditMinor:pos?.available_credit_minor??0,
          totalSecurityHeldMinor:pos?.total_security_held_minor??0
        }
      };
    });
  }
}
