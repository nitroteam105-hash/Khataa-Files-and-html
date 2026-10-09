/**
 * Khaata PG / Hostel V1 — Mobile Sync Coordinator v1
 *
 * STATUS: PROPOSED IMPLEMENTATION CONTRACT.
 *
 * Responsibility:
 *   Connect SQLite sync_outbox to Supabase typed RPCs and the entitlement-lease
 *   validator. The coordinator never decides domain truth; domain truth was
 *   already committed locally before sync begins.
 */

export type UUID = string;
export type ISODateTime = string;

export interface DbTx {
  run(sql:string, params?:unknown[]):Promise<void>;
  get<T>(sql:string, params?:unknown[]):Promise<T|undefined>;
  all<T>(sql:string, params?:unknown[]):Promise<T[]>;
}
export interface Db {
  transaction<T>(fn:(tx:DbTx)=>Promise<T>):Promise<T>;
}

export interface NetworkState {
  isOnline():Promise<boolean>;
}

export interface EntitlementState {
  hasCurrent(entitlementKey:string):Promise<boolean>;
}

export interface SupabaseRpc {
  call<T=unknown>(name:string,args:Record<string,unknown>):Promise<T>;
}

export interface Clock {
  now():ISODateTime;
}

export interface OutboxRow {
  id: UUID;
  business_id?: UUID;
  aggregate_type: string;
  aggregate_id: UUID;
  operation: string;
  payload_json: string;
  dependency_ids_json: string;
  created_at: ISODateTime;
  next_attempt_at?: ISODateTime;
  attempt_count: number;
  last_error?: string;
  state: "pending"|"sending"|"acknowledged"|"failed"|"blocked";

  required_entitlement?: string;
  lease_id?: UUID;
  local_sequence?: number;
  previous_operation_hash?: string;
  operation_hash?: string;
  effective_server_time_at_creation?: ISODateTime;
  client_created_at?: ISODateTime;
  rpc_name?: string;
  rpc_args_json?: string;
}

export type SyncMode = "normal"|"offline"|"drain_only"|"conflict";

export interface SyncSummary {
  mode: SyncMode;
  attempted: number;
  acknowledged: number;
  conflicts: number;
  failed: number;
  blocked: number;
}

export class SyncCoordinator {
  constructor(
    private deps:{
      db:Db;
      network:NetworkState;
      entitlements:EntitlementState;
      rpc:SupabaseRpc;
      clock:Clock;
    }
  ){}

  async syncNow():Promise<SyncSummary>{
    if(!(await this.deps.network.isOnline())){
      await this.setMode("offline");
      return {mode:"offline",attempted:0,acknowledged:0,conflicts:0,failed:0,blocked:0};
    }

    const pending = await this.loadRunnableOutbox();

    let anyDrain = false;
    for(const row of pending){
      if(row.required_entitlement){
        const current = await this.deps.entitlements.hasCurrent(row.required_entitlement);
        if(!current) anyDrain = true;
      }
    }

    const mode:SyncMode = anyDrain ? "drain_only" : "normal";
    await this.setMode(mode);

    const ordered = this.orderByDependencies(pending);

    let attempted=0, acknowledged=0, conflicts=0, failed=0, blocked=0;

    for(const row of ordered){
      attempted++;
      const result = await this.pushOne(row,mode);

      if(result==="acknowledged") acknowledged++;
      else if(result==="conflict") conflicts++;
      else if(result==="blocked") blocked++;
      else failed++;
    }

    const finalMode = conflicts>0 ? "conflict" : mode;
    await this.setMode(finalMode);

    return {mode:finalMode,attempted,acknowledged,conflicts,failed,blocked};
  }

  private async loadRunnableOutbox():Promise<OutboxRow[]>{
    const now=this.deps.clock.now();
    return this.deps.db.transaction(tx=>tx.all<OutboxRow>(
      `select *
       from sync_outbox
       where state in ('pending','failed','blocked')
         and (next_attempt_at is null or next_attempt_at<=?)
       order by created_at asc`,
      [now]
    ));
  }

  private orderByDependencies(rows:OutboxRow[]):OutboxRow[]{
    const byId=new Map(rows.map(r=>[r.id,r]));
    const visited=new Set<string>();
    const visiting=new Set<string>();
    const result:OutboxRow[]=[];

    const visit=(row:OutboxRow)=>{
      if(visited.has(row.id)) return;
      if(visiting.has(row.id)){
        // dependency cycle: keep deterministic order and let server/domain checks reject if needed
        return;
      }
      visiting.add(row.id);

      const deps:string[]=JSON.parse(row.dependency_ids_json||"[]");
      for(const depId of deps){
        const dep=byId.get(depId as UUID);
        if(dep) visit(dep);
      }

      visiting.delete(row.id);
      visited.add(row.id);
      result.push(row);
    };

    for(const row of rows) visit(row);
    return result;
  }

  private async pushOne(
    row:OutboxRow,
    mode:"normal"|"drain_only"
  ):Promise<"acknowledged"|"conflict"|"failed"|"blocked">{
    try{
      await this.markSending(row.id);

      const entitlement = row.required_entitlement;
      const currentEntitled = entitlement
        ? await this.deps.entitlements.hasCurrent(entitlement)
        : true;

      let drainOnly = false;

      if(entitlement && !currentEntitled){
        drainOnly = true;

        if(
          !row.lease_id ||
          !row.local_sequence ||
          !row.operation_hash ||
          !row.effective_server_time_at_creation
        ){
          await this.markBlocked(
            row.id,
            "MISSING_DRAIN_PROVENANCE"
          );
          return "blocked";
        }

        const leaseResult:any = await this.deps.rpc.call(
          "validate_sync_operation_lease",
          {
            p_operation_id: row.id,
            p_business_id: row.business_id,
            p_device_id: this.extractDeviceId(row),
            p_lease_id: row.lease_id,
            p_required_entitlement: entitlement,
            p_local_sequence: row.local_sequence,
            p_previous_operation_hash: row.previous_operation_hash ?? null,
            p_operation_hash: row.operation_hash,
            p_effective_server_time_at_creation: row.effective_server_time_at_creation,
            p_client_created_at: row.client_created_at ?? null
          }
        );

        if(
          leaseResult?.state!=="accepted_drain" &&
          leaseResult?.state!=="accepted_normal"
        ){
          await this.markBlocked(row.id,`LEASE_REJECTED:${leaseResult?.state??"unknown"}`);
          return "blocked";
        }
      }

      if(!row.rpc_name || !row.rpc_args_json){
        await this.markBlocked(row.id,"RPC_DISPATCH_NOT_CONFIGURED");
        return "blocked";
      }

      const rpcArgs=JSON.parse(row.rpc_args_json);

      // operation ID must stay identical across retries and across normal/drain mode
      rpcArgs.p_operation_id=row.id;

      const serverResult:any=await this.deps.rpc.call(row.rpc_name,rpcArgs);

      if(serverResult?.state==="conflict"){
        await this.markConflict(row,serverResult);
        return "conflict";
      }

      if(
        serverResult?.state==="accepted" ||
        serverResult?.state==="accepted_normal" ||
        serverResult?.state==="accepted_drain"
      ){
        await this.markAcknowledged(row,serverResult,drainOnly);
        return "acknowledged";
      }

      await this.markFailed(row.id,`UNEXPECTED_SERVER_RESULT:${JSON.stringify(serverResult)}`);
      return "failed";

    }catch(error:any){
      const code=String(error?.code??error?.message??"SYNC_ERROR");

      if(this.isConflict(code)){
        await this.markConflict(row,{state:"conflict",error:code});
        return "conflict";
      }

      if(this.isPermanentBlock(code)){
        await this.markBlocked(row.id,code);
        return "blocked";
      }

      await this.markFailed(row.id,code);
      return "failed";
    }
  }

  private extractDeviceId(row:OutboxRow):UUID{
    const payload=JSON.parse(row.payload_json||"{}");
    const rpcArgs=row.rpc_args_json ? JSON.parse(row.rpc_args_json) : {};
    const id=rpcArgs.p_device_id ?? payload.device_id ?? payload.deviceId;
    if(!id) throw new Error("DEVICE_ID_MISSING");
    return id;
  }

  private isConflict(code:string):boolean{
    return [
      "BED_CONFLICT",
      "stale_base_version",
      "CONFLICT"
    ].some(x=>code.includes(x));
  }

  private isPermanentBlock(code:string):boolean{
    return [
      "ACTION_NOT_ALLOWED",
      "BUSINESS_ACCESS_DENIED",
      "MEMBERSHIP_DISABLED",
      "DEVICE_REVOKED",
      "LEASE_NOT_FOUND",
      "LEASE_DID_NOT_INCLUDE_ENTITLEMENT",
      "OPERATION_CREATED_AFTER_GRACE",
      "APPROVAL_REQUIRED",
      "APPROVAL_EXPIRED",
      "APPROVAL_WRONG_TARGET",
      "APPROVAL_WRONG_ACTION"
    ].some(x=>code.includes(x));
  }

  private async markSending(operationId:UUID):Promise<void>{
    await this.deps.db.transaction(tx=>tx.run(
      `update sync_outbox
       set state='sending',attempt_count=attempt_count+1,last_error=null
       where id=?`,
      [operationId]
    ));
  }

  private async markAcknowledged(
    row:OutboxRow,
    result:unknown,
    drainOnly:boolean
  ):Promise<void>{
    const now=this.deps.clock.now();
    await this.deps.db.transaction(async tx=>{
      await tx.run(
        `update sync_outbox
         set state='acknowledged',server_result_json=?,acknowledged_at=?,
             next_attempt_at=null,last_error=null
         where id=?`,
        [JSON.stringify(result),now,row.id]
      );

      await tx.run(
        `insert or replace into sync_rpc_receipts
         (operation_id,rpc_name,result_state,result_json,received_at)
         values (?,?,?,?,?)`,
        [row.id,row.rpc_name??"unknown",drainOnly?"accepted_drain":"accepted",
         JSON.stringify(result),now]
      );

      await tx.run(
        `update sync_runtime_state
         set last_success_at=?,last_error=null,updated_at=?
         where id=1`,
        [now,now]
      );
    });
  }

  private async markConflict(row:OutboxRow,result:unknown):Promise<void>{
    const now=this.deps.clock.now();
    await this.deps.db.transaction(async tx=>{
      const conflictId=`conflict:${row.id}`;
      await tx.run(
        `insert or ignore into sync_conflicts
         (id,business_id,entity_type,entity_id,conflict_type,local_snapshot_json,
          remote_snapshot_json,detected_at,resolution_state)
         values (?,?,?,?,?,?,?,?, 'open')`,
        [
          conflictId,row.business_id??null,row.aggregate_type,row.aggregate_id,
          "server_rejected_semantic_overlap",
          row.payload_json,JSON.stringify(result),now
        ]
      );
      await tx.run(
        `update sync_outbox
         set state='blocked',conflict_id=?,last_error='SYNC_CONFLICT'
         where id=?`,
        [conflictId,row.id]
      );
    });
  }

  private async markBlocked(operationId:UUID,error:string):Promise<void>{
    await this.deps.db.transaction(tx=>tx.run(
      `update sync_outbox
       set state='blocked',last_error=?,next_attempt_at=null
       where id=?`,
      [error,operationId]
    ));
  }

  private async markFailed(operationId:UUID,error:string):Promise<void>{
    const now=Date.now();
    const retryAt=new Date(now+this.backoffMs(operationId)).toISOString();
    await this.deps.db.transaction(tx=>tx.run(
      `update sync_outbox
       set state='failed',last_error=?,next_attempt_at=?
       where id=?`,
      [error,retryAt,operationId]
    ));
  }

  private backoffMs(_operationId:UUID):number{
    // Actual attempt_count should be used by the concrete repository.
    // Bounded base example: 5 seconds; implementation may add jitter.
    return 5000;
  }

  private async setMode(mode:SyncMode):Promise<void>{
    const now=this.deps.clock.now();
    await this.deps.db.transaction(async tx=>{
      const counts=await tx.get<{pending:number;conflicts:number}>(
        `select
           sum(case when state<>'acknowledged' then 1 else 0 end) as pending,
           (select count(*) from sync_conflicts where resolution_state='open') as conflicts
         from sync_outbox`
      );
      await tx.run(
        `update sync_runtime_state
         set mode=?,pending_count=?,conflict_count=?,last_attempt_at=?,updated_at=?
         where id=1`,
        [mode,counts?.pending??0,counts?.conflicts??0,now,now]
      );
    });
  }
}

/* -------------------------------------------------------------------------- */
/* TYPED RPC DISPATCH BUILDERS                                                 */
/* -------------------------------------------------------------------------- */

export type TypedRpcEnvelope = {
  rpcName:string;
  args:Record<string,unknown>;
};

export const TypedRpcBuilder = {
  recordPayment(input:any):TypedRpcEnvelope{
    return {rpcName:"pg_record_payment",args:{
      p_business_id:input.businessId,
      p_device_id:input.deviceId,
      p_payment_id:input.paymentId,
      p_receipt_id:input.receiptId,
      p_domain_event_id:input.domainEventId,
      p_tenancy_id:input.tenancyId,
      p_payer_party_id:input.payerPartyId??null,
      p_amount_minor:input.amountMinor,
      p_payment_method:input.paymentMethod??null,
      p_occurred_at:input.occurredAt,
      p_allocations:input.allocations,
      p_cash_custody_event_id:input.cashCustodyEventId??null,
      p_cash_custodian_party_id:input.cashCustodianPartyId??null,
      p_approval_authorization_id:input.approvalAuthorizationId??null
    }};
  },

  reversePayment(input:any):TypedRpcEnvelope{
    return {rpcName:"pg_reverse_payment",args:{
      p_business_id:input.businessId,
      p_device_id:input.deviceId,
      p_reversal_payment_id:input.reversalPaymentId,
      p_domain_event_id:input.domainEventId,
      p_original_payment_id:input.originalPaymentId,
      p_reason:input.reason,
      p_occurred_at:input.occurredAt,
      p_allocation_reversal_ids:input.allocationReversalIds,
      p_approval_authorization_id:input.approvalAuthorizationId??null
    }};
  },

  transferRoom(input:any):TypedRpcEnvelope{
    return {rpcName:"pg_transfer_room",args:{
      p_business_id:input.businessId,
      p_device_id:input.deviceId,
      p_tenancy_id:input.tenancyId,
      p_old_occupancy_id:input.oldOccupancyId,
      p_new_occupancy_id:input.newOccupancyId,
      p_new_capacity_id:input.newCapacityId,
      p_domain_event_id:input.domainEventId,
      p_effective_at:input.effectiveAt,
      p_approval_authorization_id:input.approvalAuthorizationId??null
    }};
  },

  applySecurity(input:any):TypedRpcEnvelope{
    return {rpcName:"pg_apply_security_to_dues",args:{
      p_business_id:input.businessId,
      p_device_id:input.deviceId,
      p_security_event_id:input.securityEventId,
      p_domain_event_id:input.domainEventId,
      p_tenancy_id:input.tenancyId,
      p_obligation_id:input.obligationId,
      p_amount_minor:input.amountMinor,
      p_reason:input.reason??null,
      p_occurred_at:input.occurredAt,
      p_approval_authorization_id:input.approvalAuthorizationId??null
    }};
  },

  refundSecurity(input:any):TypedRpcEnvelope{
    return {rpcName:"pg_refund_security",args:{
      p_business_id:input.businessId,
      p_device_id:input.deviceId,
      p_security_event_id:input.securityEventId,
      p_domain_event_id:input.domainEventId,
      p_tenancy_id:input.tenancyId,
      p_amount_minor:input.amountMinor,
      p_reason:input.reason??null,
      p_occurred_at:input.occurredAt,
      p_approval_authorization_id:input.approvalAuthorizationId??null
    }};
  },

  handoverCash(input:any):TypedRpcEnvelope{
    return {rpcName:"pg_handover_cash",args:{
      p_business_id:input.businessId,
      p_device_id:input.deviceId,
      p_handover_event_id:input.handoverEventId,
      p_discrepancy_event_id:input.discrepancyEventId??null,
      p_domain_event_id:input.domainEventId,
      p_from_party_id:input.fromPartyId,
      p_to_party_id:input.toPartyId??null,
      p_expected_amount_minor:input.expectedAmountMinor,
      p_actual_amount_minor:input.actualAmountMinor,
      p_occurred_at:input.occurredAt,
      p_approval_authorization_id:input.approvalAuthorizationId??null
    }};
  },

  endTenancy(input:any):TypedRpcEnvelope{
    return {rpcName:"pg_end_tenancy",args:{
      p_business_id:input.businessId,
      p_device_id:input.deviceId,
      p_tenancy_id:input.tenancyId,
      p_domain_event_id:input.domainEventId,
      p_ended_at:input.endedAt,
      p_approval_authorization_id:input.approvalAuthorizationId??null
    }};
  }
};

/**
 * Pull-side rule remains unchanged:
 * - fetch after checkpoint
 * - apply a remote batch inside one SQLite transaction
 * - record applied_remote_events
 * - advance checkpoint only after commit
 * - preserve append-only history; create sync_conflicts for semantic overlap
 */
