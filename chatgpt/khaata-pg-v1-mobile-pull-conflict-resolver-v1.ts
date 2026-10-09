/**
 * Khaata PG / Hostel V1 — Mobile Pull + Conflict Resolver v1
 * PROPOSED implementation contract.
 *
 * Rules:
 * - pull batches commit atomically
 * - checkpoint advances only after commit
 * - duplicate remote events are ignored
 * - append-only financial/history entities are inserted, never rewritten
 * - sync metadata for immutable rows lives in sync_entity_state
 * - semantic overlaps become explicit conflicts
 * - bed conflicts preserve both commitments; no automatic reassignment
 */

export type UUID = string;
export interface DbTx {
  run(sql:string, params?:unknown[]):Promise<void>;
  get<T>(sql:string, params?:unknown[]):Promise<T|undefined>;
  all<T>(sql:string, params?:unknown[]):Promise<T[]>;
}
export interface Db { transaction<T>(fn:(tx:DbTx)=>Promise<T>):Promise<T>; }
export interface PullApi {
  fetchChanges(args:{businessId:UUID;cursor?:string;limit:number}):Promise<{
    changes:RemoteChange[]; nextCursor?:string; hasMore:boolean;
  }>;
}
export interface Clock { now():string; }
export interface Ids { next():UUID; }

export interface RemoteChange {
  remoteEventId:UUID;
  businessId:UUID;
  entityType:string;
  entityId:UUID;
  changeType:"insert"|"update"|"append_event"|"retire";
  serverVersion?:number;
  occurredAt?:string;
  payload:Record<string,unknown>;
}

const APPEND_ONLY = new Set([
  "payment_event","payment_allocation","receipt_snapshot",
  "security_event","cash_custody_event","domain_event","financial_adjustment"
]);

const SAFE_MUTABLE = new Set([
  "business","party","payment_promise","expense","staff_membership",
  "tenant_requirement_policy","tenant_requirement_item"
]);

const SEMANTIC = new Set(["occupancy_assignment","rent_term","tenancy"]);

export class PullCoordinator {
  constructor(private d:{db:Db;api:PullApi;clock:Clock;ids:Ids}){}

  async pullOnce(businessId:UUID,limit=100){
    const cp = await this.d.db.transaction(tx=>tx.get<{cursor?:string}>(
      `select cursor from sync_checkpoints where business_id=? and stream_key='domain'`,
      [businessId]
    ));
    const page = await this.d.api.fetchChanges({businessId,cursor:cp?.cursor,limit});
    let applied=0,ignored=0,conflicts=0;

    await this.d.db.transaction(async tx=>{
      for(const ch of page.changes){
        const seen = await tx.get(
          `select remote_event_id from applied_remote_events where remote_event_id=?`,
          [ch.remoteEventId]
        );
        if(seen){ ignored++; continue; }

        await tx.run(
          `insert or ignore into remote_change_inbox
           (remote_event_id,business_id,entity_type,entity_id,change_type,
            server_version,payload_json,occurred_at,received_at,apply_state)
           values (?,?,?,?,?,?,?,?,?,'pending')`,
          [ch.remoteEventId,ch.businessId,ch.entityType,ch.entityId,ch.changeType,
           ch.serverVersion??null,JSON.stringify(ch.payload),ch.occurredAt??null,this.d.clock.now()]
        );

        const outcome = await this.applyOne(tx,ch);
        if(outcome==="applied") applied++;
        else if(outcome==="ignored") ignored++;
        else conflicts++;

        await tx.run(
          `insert or ignore into applied_remote_events(remote_event_id,applied_at)
           values (?,?)`,
          [ch.remoteEventId,this.d.clock.now()]
        );
      }

      if(page.nextCursor){
        await tx.run(
          `insert into sync_checkpoints(business_id,stream_key,cursor,updated_at)
           values (?,'domain',?,?)
           on conflict(business_id,stream_key)
           do update set cursor=excluded.cursor,updated_at=excluded.updated_at`,
          [businessId,page.nextCursor,this.d.clock.now()]
        );
      }
    });

    return {fetched:page.changes.length,applied,ignored,conflicts,nextCursor:page.nextCursor};
  }

  private async applyOne(tx:DbTx,ch:RemoteChange):Promise<"applied"|"ignored"|"conflict">{
    if(APPEND_ONLY.has(ch.entityType)) return this.applyAppendOnly(tx,ch);
    if(SEMANTIC.has(ch.entityType)) return this.applySemantic(tx,ch);
    if(SAFE_MUTABLE.has(ch.entityType)) return this.applyVersionMerge(tx,ch);
    return this.createConflict(tx,ch,"unknown_merge_policy",null,{});
  }

  private async applyAppendOnly(tx:DbTx,ch:RemoteChange){
    const exists = await tx.get(
      `select entity_id from sync_entity_state where entity_type=? and entity_id=?`,
      [ch.entityType,ch.entityId]
    );
    if(exists){ await this.markInbox(tx,ch.remoteEventId,"ignored"); return "ignored" as const; }

    // Concrete repository performs typed INSERT here; never UPDATE immutable rows for sync flags.
    await tx.run(`select 1`);

    await tx.run(
      `insert or replace into sync_entity_state
       (entity_type,entity_id,business_id,server_version,sync_status,last_synced_at,last_remote_event_id)
       values (?,?,?,?, 'synced', ?,?)`,
      [ch.entityType,ch.entityId,ch.businessId,ch.serverVersion??null,this.d.clock.now(),ch.remoteEventId]
    );
    await this.markInbox(tx,ch.remoteEventId,"applied");
    return "applied" as const;
  }

  private async applyVersionMerge(tx:DbTx,ch:RemoteChange){
    const s = await tx.get<{server_version?:number;sync_status:string}>(
      `select server_version,sync_status from sync_entity_state
       where entity_type=? and entity_id=?`,
      [ch.entityType,ch.entityId]
    );
    if(s?.sync_status==="pending")
      return this.createConflict(tx,ch,"local_pending_vs_remote_update",s.server_version??null,{});

    if(s?.server_version!=null && ch.serverVersion!=null && ch.serverVersion<=s.server_version){
      await this.markInbox(tx,ch.remoteEventId,"ignored");
      return "ignored" as const;
    }

    await tx.run(`select 1`); // typed UPSERT belongs in concrete repository.
    await tx.run(
      `insert or replace into sync_entity_state
       (entity_type,entity_id,business_id,server_version,sync_status,last_synced_at,last_remote_event_id)
       values (?,?,?,?, 'synced', ?,?)`,
      [ch.entityType,ch.entityId,ch.businessId,ch.serverVersion??null,this.d.clock.now(),ch.remoteEventId]
    );
    await this.markInbox(tx,ch.remoteEventId,"applied");
    return "applied" as const;
  }

  private async applySemantic(tx:DbTx,ch:RemoteChange){
    if(ch.entityType==="occupancy_assignment"){
      const p:any=ch.payload;
      if(p.assignment_state==="active" && p.capacity_id){
        const overlap = await tx.get<any>(
          `select id,tenancy_id from occupancy_assignments
           where capacity_id=? and assignment_state in ('planned','active') and id<>?`,
          [p.capacity_id,ch.entityId]
        );
        if(overlap){
          return this.createConflict(tx,ch,"bed_commitment_overlap",null,{
            localOccupancyId:overlap.id,localTenancyId:overlap.tenancy_id
          });
        }
      }
    }

    const s = await tx.get<{server_version?:number;sync_status:string}>(
      `select server_version,sync_status from sync_entity_state
       where entity_type=? and entity_id=?`,
      [ch.entityType,ch.entityId]
    );
    if(s?.sync_status==="pending")
      return this.createConflict(tx,ch,"semantic_overlap_with_local_pending",s.server_version??null,{});

    await tx.run(`select 1`);
    await tx.run(
      `insert or replace into sync_entity_state
       (entity_type,entity_id,business_id,server_version,sync_status,last_synced_at,last_remote_event_id)
       values (?,?,?,?, 'synced', ?,?)`,
      [ch.entityType,ch.entityId,ch.businessId,ch.serverVersion??null,this.d.clock.now(),ch.remoteEventId]
    );
    await this.markInbox(tx,ch.remoteEventId,"applied");
    return "applied" as const;
  }

  private async createConflict(
    tx:DbTx,ch:RemoteChange,kind:string,localVersion:number|null,localSnapshot:any
  ){
    const id=this.d.ids.next();
    await tx.run(
      `insert into sync_conflicts
       (id,business_id,entity_type,entity_id,conflict_type,local_snapshot_json,
        remote_snapshot_json,detected_at,resolution_state,local_version,remote_version,remote_event_id)
       values (?,?,?,?,?,?,?,?, 'open',?,?,?)`,
      [id,ch.businessId,ch.entityType,ch.entityId,kind,JSON.stringify(localSnapshot),
       JSON.stringify(ch.payload),this.d.clock.now(),localVersion,ch.serverVersion??null,ch.remoteEventId]
    );
    await tx.run(
      `insert or replace into sync_entity_state
       (entity_type,entity_id,business_id,server_version,sync_status,last_synced_at,last_remote_event_id)
       values (?,?,?,?, 'conflict', ?,?)`,
      [ch.entityType,ch.entityId,ch.businessId,localVersion,this.d.clock.now(),ch.remoteEventId]
    );
    await this.markInbox(tx,ch.remoteEventId,"conflict");
    return "conflict" as const;
  }

  private async markInbox(tx:DbTx,id:UUID,state:"applied"|"ignored"|"conflict"){
    await tx.run(`update remote_change_inbox set apply_state=? where remote_event_id=?`,[state,id]);
  }
}

export class ConflictResolver {
  constructor(private d:{db:Db;clock:Clock;ids:Ids}){}

  async listOpen(businessId:UUID){
    return this.d.db.transaction(tx=>tx.all(
      `select * from sync_conflicts
       where business_id=? and resolution_state='open'
       order by detected_at asc`,[businessId]
    ));
  }

  async applyRemote(conflictId:UUID,userId:UUID){
    await this.d.db.transaction(async tx=>{
      const c=await this.open(tx,conflictId);
      if(c.conflict_type==="bed_commitment_overlap")
        throw new Error("BED_CONFLICT_REQUIRES_UNDERLYING_DOMAIN_CHANGE");

      await tx.run(
        `insert into sync_conflict_resolutions
         (id,conflict_id,resolution_type,resolution_payload_json,resolved_by_user_id,
          resolved_at,created_at)
         values (?,?,'apply_remote','{}',?,?,?)`,
        [this.d.ids.next(),conflictId,userId,this.d.clock.now(),this.d.clock.now()]
      );
      await tx.run(
        `update sync_conflicts set resolution_state='resolved_remote',resolved_at=? where id=?`,
        [this.d.clock.now(),conflictId]
      );
    });
  }

  async keepLocalAndRepush(conflictId:UUID,userId:UUID,newOutboxId:UUID){
    await this.d.db.transaction(async tx=>{
      const c=await this.open(tx,conflictId);
      if(c.conflict_type==="bed_commitment_overlap")
        throw new Error("BED_CONFLICT_REQUIRES_UNDERLYING_DOMAIN_CHANGE");

      await tx.run(
        `insert into sync_conflict_resolutions
         (id,conflict_id,resolution_type,resolution_payload_json,resolved_by_user_id,
          resolved_at,resulting_outbox_id,created_at)
         values (?,?,'keep_local_and_repush','{}',?,?,?,?)`,
        [this.d.ids.next(),conflictId,userId,this.d.clock.now(),newOutboxId,this.d.clock.now()]
      );
      await tx.run(
        `update sync_conflicts set resolution_state='resolved_local',resolved_at=? where id=?`,
        [this.d.clock.now(),conflictId]
      );
      await tx.run(
        `update sync_entity_state set sync_status='pending'
         where entity_type=? and entity_id=?`,
        [c.entity_type,c.entity_id]
      );
    });
  }

  async markResolvedByDomainAction(conflictId:UUID,userId:UUID,resultingOutboxId?:UUID){
    await this.d.db.transaction(async tx=>{
      await this.open(tx,conflictId);
      await tx.run(
        `insert into sync_conflict_resolutions
         (id,conflict_id,resolution_type,resolution_payload_json,resolved_by_user_id,
          resolved_at,resulting_outbox_id,created_at)
         values (?,?,'merged_by_domain_action','{}',?,?,?,?)`,
        [this.d.ids.next(),conflictId,userId,this.d.clock.now(),resultingOutboxId??null,this.d.clock.now()]
      );
      await tx.run(
        `update sync_conflicts set resolution_state='resolved_merged',resolved_at=? where id=?`,
        [this.d.clock.now(),conflictId]
      );
    });
  }

  private async open(tx:DbTx,id:UUID):Promise<any>{
    const c=await tx.get<any>(
      `select * from sync_conflicts where id=? and resolution_state='open'`,[id]
    );
    if(!c) throw new Error("OPEN_CONFLICT_NOT_FOUND");
    return c;
  }
}

/**
 * BED CONFLICT:
 * never offer generic local-wins / remote-wins.
 * Resolve through a real business action:
 * - change upcoming room/bed
 * - change joining date
 * - change/cancel planned move-out
 * - cancel upcoming tenancy
 */
