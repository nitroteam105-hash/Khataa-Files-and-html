/**
 * Khaata PG V1 — Sync ACK State Contract v1
 *
 * Central rule:
 *   ACK bookkeeping never updates immutable domain records.
 */

export type UUID = string;
export type ISODateTime = string;

export interface DbTx {
  run(sql:string, params?:unknown[]):Promise<void>;
  get<T>(sql:string, params?:unknown[]):Promise<T|undefined>;
}
export interface Db { transaction<T>(fn:(tx:DbTx)=>Promise<T>):Promise<T>; }
export interface Clock { now():ISODateTime; }

export interface SyncAck {
  operationId:UUID;
  businessId?:UUID;
  entityType:string;
  entityId:UUID;
  serverVersion?:number;
  serverUpdatedAt?:ISODateTime;
  result:unknown;
}

export class SyncStateRepository {
  constructor(private db:Db, private clock:Clock){}

  async markPending(input:{
    businessId?:UUID; entityType:string; entityId:UUID;
  }):Promise<void>{
    await this.db.transaction(tx=>this.upsertState(tx,{
      ...input,syncStatus:"pending"
    }));
  }

  async markInflight(input:{
    operationId:UUID; businessId?:UUID; entityType:string; entityId:UUID;
  }):Promise<void>{
    await this.db.transaction(async tx=>{
      await tx.run(
        `update sync_outbox
         set state='sending',attempt_count=attempt_count+1,last_error=null
         where id=?`,
        [input.operationId]
      );
      await this.upsertState(tx,{
        businessId:input.businessId,
        entityType:input.entityType,
        entityId:input.entityId,
        syncStatus:"inflight"
      });
    });
  }

  async acknowledge(ack:SyncAck):Promise<void>{
    const now=this.clock.now();

    await this.db.transaction(async tx=>{
      const outbox=await tx.get<{state:string}>(
        `select state from sync_outbox where id=?`,
        [ack.operationId]
      );

      // Duplicate ACK: keep operation idempotent.
      if(outbox?.state==="acknowledged"){
        await tx.run(
          `insert or ignore into sync_ack_receipts
           (operation_id,business_id,entity_type,entity_id,server_version,
            server_updated_at,result_json,acknowledged_at)
           values (?,?,?,?,?,?,?,?)`,
          [
            ack.operationId,ack.businessId??null,ack.entityType,ack.entityId,
            ack.serverVersion??null,ack.serverUpdatedAt??null,
            JSON.stringify(ack.result),now
          ]
        );
        return;
      }

      await tx.run(
        `update sync_outbox
         set state='acknowledged',last_error=null,next_attempt_at=null,
             server_result_json=?,acknowledged_at=?
         where id=?`,
        [JSON.stringify(ack.result),now,ack.operationId]
      );

      await tx.run(
        `insert into sync_entity_state(
          entity_type,entity_id,business_id,sync_status,server_version,
          server_updated_at,last_synced_at,last_error_code
        ) values (?,?,?,'synced',?,?,?,null)
        on conflict(entity_type,entity_id)
        do update set
          business_id=coalesce(excluded.business_id,sync_entity_state.business_id),
          sync_status='synced',
          server_version=coalesce(excluded.server_version,sync_entity_state.server_version),
          server_updated_at=coalesce(excluded.server_updated_at,sync_entity_state.server_updated_at),
          last_synced_at=excluded.last_synced_at,
          last_error_code=null`,
        [
          ack.entityType,ack.entityId,ack.businessId??null,ack.serverVersion??null,
          ack.serverUpdatedAt??null,now
        ]
      );

      await tx.run(
        `insert or replace into sync_ack_receipts(
          operation_id,business_id,entity_type,entity_id,server_version,
          server_updated_at,result_json,acknowledged_at
        ) values (?,?,?,?,?,?,?,?)`,
        [
          ack.operationId,ack.businessId??null,ack.entityType,ack.entityId,
          ack.serverVersion??null,ack.serverUpdatedAt??null,
          JSON.stringify(ack.result),now
        ]
      );
    });
  }

  async failTransient(input:{
    operationId:UUID;
    businessId?:UUID;
    entityType:string;
    entityId:UUID;
    errorCode:string;
    retryAt:ISODateTime;
  }):Promise<void>{
    await this.db.transaction(async tx=>{
      await tx.run(
        `update sync_outbox
         set state='failed',last_error=?,next_attempt_at=?
         where id=?`,
        [input.errorCode,input.retryAt,input.operationId]
      );
      await this.upsertState(tx,{
        businessId:input.businessId,
        entityType:input.entityType,
        entityId:input.entityId,
        syncStatus:"error",
        lastErrorCode:input.errorCode
      });
    });
  }

  async markConflict(input:{
    operationId?:UUID;
    businessId?:UUID;
    entityType:string;
    entityId:UUID;
    errorCode?:string;
  }):Promise<void>{
    await this.db.transaction(async tx=>{
      if(input.operationId){
        await tx.run(
          `update sync_outbox
           set state='blocked',last_error=?,next_attempt_at=null
           where id=?`,
          [input.errorCode??"SYNC_CONFLICT",input.operationId]
        );
      }
      await this.upsertState(tx,{
        businessId:input.businessId,
        entityType:input.entityType,
        entityId:input.entityId,
        syncStatus:"conflict",
        lastErrorCode:input.errorCode??"SYNC_CONFLICT"
      });
    });
  }

  private async upsertState(
    tx:DbTx,
    input:{
      businessId?:UUID;
      entityType:string;
      entityId:UUID;
      syncStatus:"local"|"pending"|"inflight"|"synced"|"error"|"conflict";
      serverVersion?:number;
      serverUpdatedAt?:ISODateTime;
      lastErrorCode?:string;
    }
  ):Promise<void>{
    await tx.run(
      `insert into sync_entity_state(
        entity_type,entity_id,business_id,sync_status,server_version,
        server_updated_at,last_synced_at,last_error_code
      ) values (?,?,?,?,?,?,null,?)
      on conflict(entity_type,entity_id)
      do update set
        business_id=coalesce(excluded.business_id,sync_entity_state.business_id),
        sync_status=excluded.sync_status,
        server_version=coalesce(excluded.server_version,sync_entity_state.server_version),
        server_updated_at=coalesce(excluded.server_updated_at,sync_entity_state.server_updated_at),
        last_error_code=excluded.last_error_code`,
      [
        input.entityType,input.entityId,input.businessId??null,input.syncStatus,
        input.serverVersion??null,input.serverUpdatedAt??null,input.lastErrorCode??null
      ]
    );
  }
}

/**
 * Example ACK for immutable payment:
 *
 * await syncState.acknowledge({
 *   operationId,
 *   businessId,
 *   entityType:"payment_event",
 *   entityId:paymentId,
 *   serverVersion:4,
 *   result:serverResult
 * });
 *
 * No UPDATE payment_events ... occurs.
 */
