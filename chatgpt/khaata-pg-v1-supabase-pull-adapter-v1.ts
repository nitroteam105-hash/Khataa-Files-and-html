/**
 * Khaata PG / Hostel V1 — Supabase Pull Adapter v1
 * STATUS: PROPOSED IMPLEMENTATION.
 *
 * Converts pg_fetch_changes rows into the RemoteChange interface consumed by
 * PullCoordinator. It does not perform merge policy or SQLite writes.
 */

export type UUID = string;

export interface SupabaseRpc {
  call<T=unknown>(name:string,args:Record<string,unknown>):Promise<T>;
}

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

type FeedRow = {
  cursor_id:number|string;
  remote_event_id:UUID;
  business_id:UUID;
  entity_type:string;
  entity_id:UUID;
  change_type:"insert"|"update"|"append_event"|"retire";
  server_version?:number|string|null;
  payload:Record<string,unknown>;
  occurred_at?:string|null;
  created_at:string;
};

export class SupabasePullApi {
  constructor(private rpc:SupabaseRpc){}

  async fetchChanges(args:{
    businessId:UUID;
    cursor?:string;
    limit:number;
  }):Promise<{
    changes:RemoteChange[];
    nextCursor?:string;
    hasMore:boolean;
  }>{
    const after = args.cursor ? Number(args.cursor) : 0;
    if(!Number.isSafeInteger(after) || after<0){
      throw new Error("INVALID_SYNC_CURSOR");
    }

    const requested=Math.max(1,Math.min(args.limit,500));

    const rows = await this.rpc.call<FeedRow[]>(
      "pg_fetch_changes",
      {
        p_business_id:args.businessId,
        p_after_cursor:after,
        p_limit:requested
      }
    );

    const list=Array.isArray(rows) ? rows : [];

    let last=after;
    const changes=list.map(row=>{
      const cursor=Number(row.cursor_id);
      if(!Number.isSafeInteger(cursor) || cursor<=last){
        throw new Error("NON_MONOTONIC_CHANGE_FEED");
      }
      last=cursor;

      return {
        remoteEventId:row.remote_event_id,
        businessId:row.business_id,
        entityType:row.entity_type,
        entityId:row.entity_id,
        changeType:row.change_type,
        serverVersion:
          row.server_version==null ? undefined : Number(row.server_version),
        occurredAt:row.occurred_at??undefined,
        payload:row.payload??{}
      };
    });

    return {
      changes,
      nextCursor:list.length ? String(last) : args.cursor,
      // Server clamps requested page size. Full page means there may be more.
      hasMore:list.length===requested
    };
  }
}

/**
 * Recommended pull loop:
 *
 * do {
 *   const summary = await pullCoordinator.pullOnce(businessId,100);
 *   // pullOnce persists its next cursor only after SQLite COMMIT.
 * } while (server indicated another full page)
 *
 * Realtime notification, if added later, should only wake this pull loop.
 * It should not bypass the durable cursor/change-feed protocol.
 */
