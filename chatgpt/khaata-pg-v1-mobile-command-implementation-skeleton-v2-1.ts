/**
 * Khaata PG V1 — Mobile Command Skeleton v2.1 Sync-Metadata Patch
 *
 * This file is intentionally a patch contract rather than a copy of every v2
 * handler. Apply these helpers/patterns to all existing command implementations.
 *
 * Key correction:
 *   domain INSERT/UPDATE SQL no longer writes sync_status/server_version/
 *   last_synced_at as part of business records.
 *
 * Instead, every queued entity receives a sync_entity_state row in the SAME
 * SQLite transaction as the domain write and outbox write.
 */

export type UUID = string;
export type ISODateTime = string;

export interface DbTx {
  run(sql:string, params?:unknown[]):Promise<void>;
}
export interface Ids { next():UUID; }
export interface Clock { now():ISODateTime; }

export interface OutboxInput {
  id:UUID;
  businessId?:UUID;
  aggregateType:string;
  aggregateId:UUID;
  operation:"insert"|"update"|"append_event"|"retire";
  payload:unknown;
  dependencyIds?:UUID[];
  createdAt:ISODateTime;
}

export async function enqueueWithEntityState(
  tx:DbTx,
  deps:{ids:Ids;clock:Clock},
  input:Omit<OutboxInput,"id"|"createdAt">
):Promise<UUID>{
  const operationId=deps.ids.next();
  const now=deps.clock.now();

  await tx.run(
    `insert into sync_outbox(
      id,business_id,aggregate_type,aggregate_id,operation,payload_json,
      dependency_ids_json,created_at,state
    ) values (?,?,?,?,?,?,?,?, 'pending')`,
    [
      operationId,input.businessId??null,input.aggregateType,input.aggregateId,
      input.operation,JSON.stringify(input.payload),
      JSON.stringify(input.dependencyIds??[]),now
    ]
  );

  await tx.run(
    `insert into sync_entity_state(
      entity_type,entity_id,business_id,sync_status,last_error_code
    ) values (?,?,?,'pending',null)
    on conflict(entity_type,entity_id)
    do update set
      business_id=coalesce(excluded.business_id,sync_entity_state.business_id),
      sync_status='pending',
      last_error_code=null`,
    [input.aggregateType,input.aggregateId,input.businessId??null]
  );

  return operationId;
}

/* -------------------------------------------------------------------------- */
/* BEFORE → AFTER examples                                                     */
/* -------------------------------------------------------------------------- */

/**
 * BEFORE (v2):
 *
 * insert into payment_events(...,sync_status)
 * values (...,'pending')
 *
 * AFTER (v2.1):
 *
 * insert into payment_events(
 *   id,business_id,tenancy_id,payer_party_id,event_type,amount_minor,
 *   payment_method,occurred_at,recorded_by_user_id,metadata_json,created_at
 * ) values (?,?,?,?,?,?,?,?,?,?,?)
 *
 * await enqueueWithEntityState(tx,deps,{
 *   businessId:ctx.businessId,
 *   aggregateType:"payment_event",
 *   aggregateId:paymentId,
 *   operation:"append_event",
 *   payload:{id:paymentId}
 * });
 */

/**
 * Immutable rows that MUST NOT receive sync metadata mutations:
 *
 * payment_events
 * payment_allocations
 * receipt_snapshots
 * security_events
 * cash_custody_events
 * domain_events
 * financial_adjustments
 *
 * Mutable entities may still change for BUSINESS reasons, but sync bookkeeping
 * should remain centralized in sync_entity_state.
 */

/* -------------------------------------------------------------------------- */
/* MONTHLY OBLIGATION GENERATION HARDENING NOTE                                */
/* -------------------------------------------------------------------------- */

/**
 * v2.1 obligation generation should also:
 *
 * 1. choose the effective rent term for the specific monthly period,
 * 2. never generate before the tenancy's eligible billing start,
 * 3. never generate after tenancy end,
 * 4. keep deterministic key rent:<tenancyId>:<periodStart>,
 * 5. never invent automatic proration unless a future product decision defines it.
 *
 * Multiple effective-dated rent terms must not create duplicate obligations for
 * the same tenancy/month.
 */
