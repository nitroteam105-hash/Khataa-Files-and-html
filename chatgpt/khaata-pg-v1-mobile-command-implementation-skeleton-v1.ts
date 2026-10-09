/**
 * Khaata PG / Hostel V1 — Mobile Command Implementation Skeleton v1
 *
 * STATUS: PROPOSED IMPLEMENTATION SKELETON.
 *
 * Purpose:
 *   Turn the service contract into concrete local-first command-handler patterns.
 *   Every handler:
 *     1) validates domain rules,
 *     2) checks permission,
 *     3) writes SQLite atomically,
 *     4) appends domain history,
 *     5) enqueues sync,
 *     6) returns only after COMMIT.
 *
 * This is intentionally framework-neutral.
 */

export type UUID = string;
export type ISODate = string;
export type ISODateTime = string;
export type Minor = number;

export interface DbTx {
  run(sql: string, params?: unknown[]): Promise<void>;
  get<T>(sql: string, params?: unknown[]): Promise<T | undefined>;
  all<T>(sql: string, params?: unknown[]): Promise<T[]>;
}

export interface Db {
  transaction<T>(fn: (tx: DbTx) => Promise<T>): Promise<T>;
}

export interface Ids {
  next(): UUID;
}

export interface Clock {
  now(): ISODateTime;
  today(): ISODate;
}

export interface CommandContext {
  businessId: UUID;
  actorUserId: UUID;
  deviceId: UUID;
  occurredAt: ISODateTime;
  correlationId?: UUID;
}

export interface AccessGate {
  requireAction(
    tx: DbTx,
    ctx: CommandContext,
    actionKey: string,
    target?: { type: string; id: UUID }
  ): Promise<
    | { state: "allowed" }
    | { state: "needs_approval"; approvalRequestId: UUID }
  >;
}

export interface Outbox {
  enqueue(
    tx: DbTx,
    item: {
      id: UUID;
      businessId: UUID;
      aggregateType: string;
      aggregateId: UUID;
      operation: "insert" | "update" | "append_event" | "retire";
      payload: unknown;
      dependencyIds?: UUID[];
      createdAt: ISODateTime;
    }
  ): Promise<void>;
}

export interface DomainEvents {
  append(
    tx: DbTx,
    event: {
      id: UUID;
      businessId: UUID;
      entityType: string;
      entityId: UUID;
      eventType: string;
      occurredAt: ISODateTime;
      recordedAt: ISODateTime;
      recordedByUserId: UUID;
      deviceId: UUID;
      correlationId?: UUID;
      payload: unknown;
    }
  ): Promise<void>;
}

export class DomainError extends Error {
  constructor(public code: string, message: string) {
    super(message);
  }
}

/* -------------------------------------------------------------------------- */
/* SHARED HELPERS                                                              */
/* -------------------------------------------------------------------------- */

function assertPositiveMinor(amount: Minor, field = "amountMinor"): void {
  if (!Number.isInteger(amount) || amount <= 0) {
    throw new DomainError("INVALID_AMOUNT", `${field} must be a positive integer minor-unit value`);
  }
}

function assertDueDay(day: number): void {
  if (!Number.isInteger(day) || day < 1 || day > 31) {
    throw new DomainError("INVALID_DUE_DAY", "dueDay must be between 1 and 31");
  }
}

async function enqueueInsert(
  deps: { ids: Ids; clock: Clock; outbox: Outbox },
  tx: DbTx,
  businessId: UUID,
  aggregateType: string,
  aggregateId: UUID,
  payload: unknown,
  dependencyIds: UUID[] = []
): Promise<void> {
  await deps.outbox.enqueue(tx, {
    id: deps.ids.next(),
    businessId,
    aggregateType,
    aggregateId,
    operation: "insert",
    payload,
    dependencyIds,
    createdAt: deps.clock.now()
  });
}

/* -------------------------------------------------------------------------- */
/* PAYMENT                                                                     */
/* -------------------------------------------------------------------------- */

export interface RecordPaymentInput {
  tenancyId: UUID;
  payerPartyId?: UUID;
  amountMinor: Minor;
  method?: string;
  allocations: Array<{ obligationId: UUID; amountMinor: Minor }>;
  receiveCashIntoCustodyOfPartyId?: UUID;
}

export async function recordPayment(
  deps: { db: Db; ids: Ids; clock: Clock; access: AccessGate; outbox: Outbox; events: DomainEvents },
  ctx: CommandContext,
  input: RecordPaymentInput
): Promise<{ paymentId: UUID; receiptId: UUID }> {
  assertPositiveMinor(input.amountMinor);

  const allocationTotal = input.allocations.reduce((sum, a) => {
    assertPositiveMinor(a.amountMinor, "allocation.amountMinor");
    return sum + a.amountMinor;
  }, 0);

  if (allocationTotal > input.amountMinor) {
    throw new DomainError("OVER_ALLOCATED_PAYMENT", "Allocated amount cannot exceed received amount");
  }

  return deps.db.transaction(async tx => {
    const access = await deps.access.requireAction(tx, ctx, "record_payment", {
      type: "tenancy",
      id: input.tenancyId
    });
    if (access.state === "needs_approval") {
      throw new DomainError("APPROVAL_REQUIRED", access.approvalRequestId);
    }

    const tenancy = await tx.get<{ id: UUID }>(
      `select id from tenancies where id = ? and business_id = ?`,
      [input.tenancyId, ctx.businessId]
    );
    if (!tenancy) throw new DomainError("TENANCY_NOT_FOUND", "Tenancy not found");

    const paymentId = deps.ids.next();
    const receiptId = deps.ids.next();
    const createdAt = deps.clock.now();

    await tx.run(
      `insert into payment_events
       (id,business_id,tenancy_id,payer_party_id,event_type,amount_minor,payment_method,
        occurred_at,recorded_by_user_id,metadata_json,created_at,sync_status)
       values (?,?,?,?,?,?,?,?,?,?,?,'pending')`,
      [
        paymentId,
        ctx.businessId,
        input.tenancyId,
        input.payerPartyId ?? null,
        "payment",
        input.amountMinor,
        input.method ?? null,
        ctx.occurredAt,
        ctx.actorUserId,
        "{}",
        createdAt
      ]
    );

    const allocationIds: UUID[] = [];
    for (const allocation of input.allocations) {
      const obligation = await tx.get<{ id: UUID }>(
        `select id from obligations where id = ? and tenancy_id = ?`,
        [allocation.obligationId, input.tenancyId]
      );
      if (!obligation) {
        throw new DomainError("OBLIGATION_NOT_FOUND", `Obligation ${allocation.obligationId} not found`);
      }

      const allocationId = deps.ids.next();
      allocationIds.push(allocationId);
      await tx.run(
        `insert into payment_allocations
         (id,payment_event_id,obligation_id,amount_minor,allocation_effect,created_at,sync_status)
         values (?,?,?,?,1,?,'pending')`,
        [allocationId, paymentId, allocation.obligationId, allocation.amountMinor, createdAt]
      );
    }

    const receiptSnapshot = JSON.stringify({
      paymentId,
      tenancyId: input.tenancyId,
      amountMinor: input.amountMinor,
      method: input.method ?? null,
      allocations: input.allocations,
      issuedAt: ctx.occurredAt
    });

    await tx.run(
      `insert into receipt_snapshots
       (id,payment_event_id,receipt_number,snapshot_json,issued_at,created_at,sync_status)
       values (?,?,?,?,?,?,'pending')`,
      [
        receiptId,
        paymentId,
        `LOCAL-${receiptId.slice(0, 8)}`,
        receiptSnapshot,
        ctx.occurredAt,
        createdAt
      ]
    );

    let custodyEventId: UUID | undefined;
    if (input.receiveCashIntoCustodyOfPartyId) {
      custodyEventId = deps.ids.next();
      await tx.run(
        `insert into cash_custody_events
         (id,business_id,event_type,payment_event_id,to_party_id,amount_minor,
          occurred_at,recorded_by_user_id,created_at,sync_status)
         values (?,?,?,?,?,?,?,?,?,'pending')`,
        [
          custodyEventId,
          ctx.businessId,
          "collection_received",
          paymentId,
          input.receiveCashIntoCustodyOfPartyId,
          input.amountMinor,
          ctx.occurredAt,
          ctx.actorUserId,
          createdAt
        ]
      );
    }

    await deps.events.append(tx, {
      id: deps.ids.next(),
      businessId: ctx.businessId,
      entityType: "payment",
      entityId: paymentId,
      eventType: "payment_recorded",
      occurredAt: ctx.occurredAt,
      recordedAt: createdAt,
      recordedByUserId: ctx.actorUserId,
      deviceId: ctx.deviceId,
      correlationId: ctx.correlationId,
      payload: {
        tenancyId: input.tenancyId,
        amountMinor: input.amountMinor,
        allocationIds,
        receiptId,
        custodyEventId: custodyEventId ?? null
      }
    });

    await enqueueInsert(deps, tx, ctx.businessId, "payment_event", paymentId, { id: paymentId }, []);
    for (const allocationId of allocationIds) {
      await enqueueInsert(deps, tx, ctx.businessId, "payment_allocation", allocationId, { id: allocationId }, [paymentId]);
    }
    await enqueueInsert(deps, tx, ctx.businessId, "receipt_snapshot", receiptId, { id: receiptId }, [paymentId]);
    if (custodyEventId) {
      await enqueueInsert(deps, tx, ctx.businessId, "cash_custody_event", custodyEventId, { id: custodyEventId }, [paymentId]);
    }

    return { paymentId, receiptId };
  });
}

/* -------------------------------------------------------------------------- */
/* ROOM TRANSFER                                                               */
/* -------------------------------------------------------------------------- */

export async function transferRoom(
  deps: { db: Db; ids: Ids; clock: Clock; access: AccessGate; outbox: Outbox; events: DomainEvents },
  ctx: CommandContext,
  input: { tenancyId: UUID; newCapacityId: UUID; effectiveAt: ISODateTime }
): Promise<void> {
  await deps.db.transaction(async tx => {
    const access = await deps.access.requireAction(tx, ctx, "transfer_room", {
      type: "tenancy",
      id: input.tenancyId
    });
    if (access.state === "needs_approval") {
      throw new DomainError("APPROVAL_REQUIRED", access.approvalRequestId);
    }

    const current = await tx.get<{ id: UUID; capacity_id: UUID }>(
      `select id, capacity_id
       from occupancy_assignments
       where tenancy_id = ? and assignment_state = 'active'`,
      [input.tenancyId]
    );
    if (!current) throw new DomainError("NO_ACTIVE_OCCUPANCY", "No active occupancy assignment found");

    const target = await tx.get<{ id: UUID; lifecycle_state: string }>(
      `select id, lifecycle_state from property_nodes
       where id = ? and business_id = ? and node_type = 'bed'`,
      [input.newCapacityId, ctx.businessId]
    );
    if (!target || target.lifecycle_state !== "available") {
      throw new DomainError("CAPACITY_UNAVAILABLE", "Target bed is not available");
    }

    const occupied = await tx.get<{ id: UUID }>(
      `select id from occupancy_assignments
       where capacity_id = ? and assignment_state = 'active'`,
      [input.newCapacityId]
    );
    if (occupied) throw new DomainError("BED_CONFLICT", "Target bed already has an active tenancy");

    await tx.run(
      `update occupancy_assignments
       set assignment_state = 'ended', end_at = ?, sync_status = 'pending'
       where id = ?`,
      [input.effectiveAt, current.id]
    );

    const nextId = deps.ids.next();
    const createdAt = deps.clock.now();

    await tx.run(
      `insert into occupancy_assignments
       (id,tenancy_id,capacity_id,assignment_state,start_at,created_at,sync_status)
       values (?,?,?,'active',?,?,'pending')`,
      [nextId, input.tenancyId, input.newCapacityId, input.effectiveAt, createdAt]
    );

    await deps.events.append(tx, {
      id: deps.ids.next(),
      businessId: ctx.businessId,
      entityType: "tenancy",
      entityId: input.tenancyId,
      eventType: "room_transferred",
      occurredAt: input.effectiveAt,
      recordedAt: createdAt,
      recordedByUserId: ctx.actorUserId,
      deviceId: ctx.deviceId,
      correlationId: ctx.correlationId,
      payload: {
        previousOccupancyAssignmentId: current.id,
        previousCapacityId: current.capacity_id,
        newOccupancyAssignmentId: nextId,
        newCapacityId: input.newCapacityId
      }
    });

    await deps.outbox.enqueue(tx, {
      id: deps.ids.next(),
      businessId: ctx.businessId,
      aggregateType: "occupancy_assignment",
      aggregateId: current.id,
      operation: "update",
      payload: { assignment_state: "ended", end_at: input.effectiveAt },
      createdAt
    });

    await enqueueInsert(deps, tx, ctx.businessId, "occupancy_assignment", nextId, { id: nextId }, [input.tenancyId]);

    // Deliberately NO rent_terms mutation here.
  });
}

/* -------------------------------------------------------------------------- */
/* CONFIRM JOINED                                                              */
/* -------------------------------------------------------------------------- */

export async function confirmJoined(
  deps: { db: Db; ids: Ids; clock: Clock; access: AccessGate; outbox: Outbox; events: DomainEvents },
  ctx: CommandContext,
  tenancyId: UUID
): Promise<void> {
  await deps.db.transaction(async tx => {
    const access = await deps.access.requireAction(tx, ctx, "confirm_joined", { type: "tenancy", id: tenancyId });
    if (access.state === "needs_approval") throw new DomainError("APPROVAL_REQUIRED", access.approvalRequestId);

    const tenancy = await tx.get<{ lifecycle_state: string }>(
      `select lifecycle_state from tenancies where id = ? and business_id = ?`,
      [tenancyId, ctx.businessId]
    );
    if (!tenancy) throw new DomainError("TENANCY_NOT_FOUND", "Tenancy not found");
    if (tenancy.lifecycle_state !== "upcoming") {
      throw new DomainError("INVALID_LIFECYCLE", "Only an Upcoming tenancy can be explicitly confirmed joined");
    }

    const planned = await tx.get<{ id: UUID }>(
      `select id from occupancy_assignments
       where tenancy_id = ? and assignment_state = 'planned'
       order by created_at desc limit 1`,
      [tenancyId]
    );
    if (!planned) throw new DomainError("NO_PLANNED_CAPACITY", "Upcoming tenancy has no planned capacity");

    await tx.run(
      `update tenancies
       set lifecycle_state = 'active', joined_at = ?, updated_at = ?, sync_status = 'pending'
       where id = ?`,
      [ctx.occurredAt, deps.clock.now(), tenancyId]
    );

    await tx.run(
      `update occupancy_assignments
       set assignment_state = 'active', start_at = ?, sync_status = 'pending'
       where id = ?`,
      [ctx.occurredAt, planned.id]
    );

    await deps.events.append(tx, {
      id: deps.ids.next(),
      businessId: ctx.businessId,
      entityType: "tenancy",
      entityId: tenancyId,
      eventType: "tenancy_join_confirmed",
      occurredAt: ctx.occurredAt,
      recordedAt: deps.clock.now(),
      recordedByUserId: ctx.actorUserId,
      deviceId: ctx.deviceId,
      correlationId: ctx.correlationId,
      payload: { occupancyAssignmentId: planned.id }
    });

    await deps.outbox.enqueue(tx, {
      id: deps.ids.next(),
      businessId: ctx.businessId,
      aggregateType: "tenancy",
      aggregateId: tenancyId,
      operation: "update",
      payload: { lifecycle_state: "active", joined_at: ctx.occurredAt },
      createdAt: deps.clock.now()
    });

    await deps.outbox.enqueue(tx, {
      id: deps.ids.next(),
      businessId: ctx.businessId,
      aggregateType: "occupancy_assignment",
      aggregateId: planned.id,
      operation: "update",
      payload: { assignment_state: "active", start_at: ctx.occurredAt },
      createdAt: deps.clock.now()
    });
  });
}

/* -------------------------------------------------------------------------- */
/* SECURITY APPLICATION                                                        */
/* -------------------------------------------------------------------------- */

export async function applySecurityToDues(
  deps: { db: Db; ids: Ids; clock: Clock; access: AccessGate; outbox: Outbox; events: DomainEvents },
  ctx: CommandContext,
  input: { tenancyId: UUID; obligationId: UUID; amountMinor: Minor; reason?: string }
): Promise<{ securityEventId: UUID }> {
  assertPositiveMinor(input.amountMinor);

  return deps.db.transaction(async tx => {
    const access = await deps.access.requireAction(tx, ctx, "apply_security_to_dues", {
      type: "tenancy",
      id: input.tenancyId
    });
    if (access.state === "needs_approval") throw new DomainError("APPROVAL_REQUIRED", access.approvalRequestId);

    const account = await tx.get<{ id: UUID }>(
      `select id from security_accounts where tenancy_id = ?`,
      [input.tenancyId]
    );
    if (!account) throw new DomainError("SECURITY_ACCOUNT_NOT_FOUND", "No security account found");

    const held = await tx.get<{ held_amount_minor: number }>(
      `select held_amount_minor from v_security_balances where security_account_id = ?`,
      [account.id]
    );
    if (!held || held.held_amount_minor < input.amountMinor) {
      throw new DomainError("INSUFFICIENT_SECURITY_HELD", "Security held is lower than requested application");
    }

    const obligation = await tx.get<{ outstanding_minor: number }>(
      `select outstanding_minor from v_obligation_balances where obligation_id = ? and tenancy_id = ?`,
      [input.obligationId, input.tenancyId]
    );
    if (!obligation || obligation.outstanding_minor <= 0) {
      throw new DomainError("NO_OUTSTANDING_DUE", "No outstanding amount to settle");
    }
    if (input.amountMinor > obligation.outstanding_minor) {
      throw new DomainError("SECURITY_OVER_APPLICATION", "Cannot apply more security than outstanding due");
    }

    const securityEventId = deps.ids.next();
    const createdAt = deps.clock.now();

    await tx.run(
      `insert into security_events
       (id,security_account_id,event_type,amount_minor,obligation_id,occurred_at,reason,created_at,sync_status)
       values (?,?,'applied_to_dues',?,?,?,?,?,'pending')`,
      [
        securityEventId,
        account.id,
        input.amountMinor,
        input.obligationId,
        ctx.occurredAt,
        input.reason ?? null,
        createdAt
      ]
    );

    await deps.events.append(tx, {
      id: deps.ids.next(),
      businessId: ctx.businessId,
      entityType: "security",
      entityId: account.id,
      eventType: "security_applied_to_dues",
      occurredAt: ctx.occurredAt,
      recordedAt: createdAt,
      recordedByUserId: ctx.actorUserId,
      deviceId: ctx.deviceId,
      correlationId: ctx.correlationId,
      payload: {
        securityEventId,
        tenancyId: input.tenancyId,
        obligationId: input.obligationId,
        amountMinor: input.amountMinor
      }
    });

    await enqueueInsert(deps, tx, ctx.businessId, "security_event", securityEventId, { id: securityEventId }, [account.id, input.obligationId]);
    return { securityEventId };
  });
}

/* -------------------------------------------------------------------------- */
/* PAYMENT PROMISE                                                             */
/* -------------------------------------------------------------------------- */

export async function recordPromise(
  deps: { db: Db; ids: Ids; clock: Clock; access: AccessGate; outbox: Outbox; events: DomainEvents },
  ctx: CommandContext,
  input: { tenancyId: UUID; obligationId?: UUID; promisedAmountMinor: Minor; promisedDate: ISODate }
): Promise<{ promiseId: UUID }> {
  assertPositiveMinor(input.promisedAmountMinor);

  return deps.db.transaction(async tx => {
    const access = await deps.access.requireAction(tx, ctx, "record_promise", {
      type: "tenancy",
      id: input.tenancyId
    });
    if (access.state === "needs_approval") throw new DomainError("APPROVAL_REQUIRED", access.approvalRequestId);

    const promiseId = deps.ids.next();
    const createdAt = deps.clock.now();

    await tx.run(
      `insert into payment_promises
       (id,tenancy_id,obligation_id,promised_amount_minor,promised_date,recorded_by_user_id,created_at,sync_status)
       values (?,?,?,?,?,?,?,'pending')`,
      [
        promiseId,
        input.tenancyId,
        input.obligationId ?? null,
        input.promisedAmountMinor,
        input.promisedDate,
        ctx.actorUserId,
        createdAt
      ]
    );

    await deps.events.append(tx, {
      id: deps.ids.next(),
      businessId: ctx.businessId,
      entityType: "payment_promise",
      entityId: promiseId,
      eventType: "payment_promise_recorded",
      occurredAt: ctx.occurredAt,
      recordedAt: createdAt,
      recordedByUserId: ctx.actorUserId,
      deviceId: ctx.deviceId,
      correlationId: ctx.correlationId,
      payload: input
    });

    await enqueueInsert(deps, tx, ctx.businessId, "payment_promise", promiseId, { id: promiseId }, [input.tenancyId]);

    // Deliberately NO payment_event, NO allocation, NO obligation mutation.
    return { promiseId };
  });
}
