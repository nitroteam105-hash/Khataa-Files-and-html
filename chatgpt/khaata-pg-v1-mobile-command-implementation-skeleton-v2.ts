/**
 * Khaata PG / Hostel V1 — Mobile Command Implementation Skeleton v2
 *
 * STATUS: PROPOSED IMPLEMENTATION SKELETON.
 *
 * v2 adds concrete handlers for:
 * - addUpcomingTenant
 * - ensureMonthlyObligations
 * - reversePayment
 * - addCharge
 * - addExpense
 * - handoverCash
 * - planMoveOut
 * - endTenancy
 * - refundSecurity
 *
 * It retains the local-first transaction pattern established in v1.
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
export interface Db { transaction<T>(fn: (tx: DbTx) => Promise<T>): Promise<T>; }
export interface Ids { next(): UUID; }
export interface Clock { now(): ISODateTime; today(): ISODate; }

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
  enqueue(tx: DbTx, item: {
    id: UUID;
    businessId: UUID;
    aggregateType: string;
    aggregateId: UUID;
    operation: "insert" | "update" | "append_event" | "retire";
    payload: unknown;
    dependencyIds?: UUID[];
    createdAt: ISODateTime;
  }): Promise<void>;
}

export interface DomainEvents {
  append(tx: DbTx, event: {
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
  }): Promise<void>;
}

export class DomainError extends Error {
  constructor(public code: string, message: string) { super(message); }
}

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
function daysInMonth(year: number, month1: number): number {
  return new Date(Date.UTC(year, month1, 0)).getUTCDate();
}
function clampDueDay(year: number, month1: number, dueDay: number): number {
  return Math.min(dueDay, daysInMonth(year, month1));
}
function isoDate(year: number, month1: number, day: number): ISODate {
  return `${year}-${String(month1).padStart(2,"0")}-${String(day).padStart(2,"0")}`;
}
async function enqueue(
  deps: { ids: Ids; clock: Clock; outbox: Outbox },
  tx: DbTx,
  businessId: UUID,
  aggregateType: string,
  aggregateId: UUID,
  operation: "insert" | "update" | "append_event" | "retire",
  payload: unknown,
  dependencyIds: UUID[] = []
): Promise<void> {
  await deps.outbox.enqueue(tx, {
    id: deps.ids.next(),
    businessId,
    aggregateType,
    aggregateId,
    operation,
    payload,
    dependencyIds,
    createdAt: deps.clock.now()
  });
}

/* -------------------------------------------------------------------------- */
/* ADD UPCOMING TENANT                                                         */
/* -------------------------------------------------------------------------- */

export async function addUpcomingTenant(
  deps: { db: Db; ids: Ids; clock: Clock; access: AccessGate; outbox: Outbox; events: DomainEvents },
  ctx: CommandContext,
  input: {
    occupantPartyId: UUID;
    responsiblePartyId?: UUID;
    payerPartyId?: UUID;
    depositOwnerPartyId?: UUID;
    plannedJoinDate?: ISODate;
    capacityId: UUID;
    rentAmountMinor: Minor;
    billingTiming: "prepaid" | "postpaid";
    dueDay: number;
    graceDays?: number;
  }
): Promise<{ tenancyId: UUID }> {
  assertPositiveMinor(input.rentAmountMinor);
  assertDueDay(input.dueDay);

  return deps.db.transaction(async tx => {
    const access = await deps.access.requireAction(tx, ctx, "add_tenant");
    if (access.state === "needs_approval") {
      throw new DomainError("APPROVAL_REQUIRED", access.approvalRequestId);
    }

    const capacity = await tx.get<{ id: UUID; lifecycle_state: string }>(
      `select id, lifecycle_state from property_nodes
       where id = ? and business_id = ? and node_type = 'bed'`,
      [input.capacityId, ctx.businessId]
    );
    if (!capacity || capacity.lifecycle_state !== "available") {
      throw new DomainError("CAPACITY_UNAVAILABLE", "Selected bed is not available");
    }

    const conflicting = await tx.get<{ id: UUID }>(
      `select id from occupancy_assignments
       where capacity_id = ? and assignment_state in ('planned','active')`,
      [input.capacityId]
    );
    if (conflicting) {
      throw new DomainError("BED_CONFLICT", "Selected bed already has a planned or active commitment");
    }

    const tenancyId = deps.ids.next();
    const occupancyId = deps.ids.next();
    const rentTermId = deps.ids.next();
    const createdAt = deps.clock.now();

    await tx.run(
      `insert into tenancies
       (id,business_id,lifecycle_state,planned_join_date,created_at,updated_at,sync_status)
       values (?,?,'upcoming',?,?,?,'pending')`,
      [tenancyId, ctx.businessId, input.plannedJoinDate ?? null, createdAt, createdAt]
    );

    const roles: Array<[string, UUID | undefined]> = [
      ["occupant", input.occupantPartyId],
      ["responsible_party", input.responsiblePartyId],
      ["payer", input.payerPartyId],
      ["deposit_owner", input.depositOwnerPartyId]
    ];
    for (const [roleType, partyId] of roles) {
      if (!partyId) continue;
      const roleId = deps.ids.next();
      await tx.run(
        `insert into tenancy_role_assignments
         (id,tenancy_id,party_id,role_type,valid_from,created_at,sync_status)
         values (?,?,?,?,?,?, 'pending')`,
        [roleId, tenancyId, partyId, roleType, ctx.occurredAt, createdAt]
      );
      await enqueue(deps, tx, ctx.businessId, "tenancy_role_assignment", roleId, "insert", { id: roleId }, [tenancyId, partyId]);
    }

    await tx.run(
      `insert into occupancy_assignments
       (id,tenancy_id,capacity_id,assignment_state,start_at,created_at,sync_status)
       values (?,?,?,'planned',null,?,'pending')`,
      [occupancyId, tenancyId, input.capacityId, createdAt]
    );

    await tx.run(
      `insert into rent_terms
       (id,tenancy_id,amount_minor,billing_frequency,billing_timing,due_day,grace_days,valid_from,created_at,sync_status)
       values (?,?,?,'monthly',?,?,?,?,?,'pending')`,
      [
        rentTermId, tenancyId, input.rentAmountMinor, input.billingTiming,
        input.dueDay, input.graceDays ?? 0, input.plannedJoinDate ?? ctx.occurredAt.slice(0,10), createdAt
      ]
    );

    await deps.events.append(tx, {
      id: deps.ids.next(),
      businessId: ctx.businessId,
      entityType: "tenancy",
      entityId: tenancyId,
      eventType: "upcoming_tenancy_created",
      occurredAt: ctx.occurredAt,
      recordedAt: createdAt,
      recordedByUserId: ctx.actorUserId,
      deviceId: ctx.deviceId,
      correlationId: ctx.correlationId,
      payload: { occupancyId, rentTermId, capacityId: input.capacityId }
    });

    await enqueue(deps, tx, ctx.businessId, "tenancy", tenancyId, "insert", { id: tenancyId });
    await enqueue(deps, tx, ctx.businessId, "occupancy_assignment", occupancyId, "insert", { id: occupancyId }, [tenancyId, input.capacityId]);
    await enqueue(deps, tx, ctx.businessId, "rent_term", rentTermId, "insert", { id: rentTermId }, [tenancyId]);

    return { tenancyId };
  });
}

/* -------------------------------------------------------------------------- */
/* MONTHLY OBLIGATION GENERATION                                               */
/* -------------------------------------------------------------------------- */

export async function ensureMonthlyObligations(
  deps: { db: Db; ids: Ids; clock: Clock; outbox: Outbox; events: DomainEvents },
  ctx: CommandContext,
  throughPeriod: ISODate
): Promise<{ created: number; alreadyPresent: number }> {
  return deps.db.transaction(async tx => {
    const active = await tx.all<{
      tenancy_id: UUID;
      amount_minor: number;
      billing_timing: "prepaid" | "postpaid";
      due_day: number;
      grace_days: number;
      valid_from: ISODate;
      valid_to?: ISODate;
    }>(
      `select t.id as tenancy_id, rt.amount_minor, rt.billing_timing, rt.due_day,
              rt.grace_days, rt.valid_from, rt.valid_to
       from tenancies t
       join rent_terms rt on rt.tenancy_id = t.id
       where t.business_id = ?
         and t.lifecycle_state in ('active','planned_move_out')
         and (rt.valid_to is null or rt.valid_to >= rt.valid_from)`,
      [ctx.businessId]
    );

    let created = 0, alreadyPresent = 0;
    const through = new Date(`${throughPeriod}T00:00:00Z`);

    for (const row of active) {
      const start = new Date(`${row.valid_from}T00:00:00Z`);
      let y = start.getUTCFullYear();
      let m = start.getUTCMonth() + 1;

      while (new Date(Date.UTC(y, m - 1, 1)) <= through) {
        const periodStart = isoDate(y, m, 1);
        const periodEnd = isoDate(y, m, daysInMonth(y, m));
        const dueDay = clampDueDay(y, m, row.due_day);
        const dueDate = isoDate(y, m, dueDay);
        const key = `rent:${row.tenancy_id}:${periodStart}`;

        const exists = await tx.get<{ id: UUID }>(
          `select id from obligations where business_id = ? and deterministic_key = ?`,
          [ctx.businessId, key]
        );
        if (exists) {
          alreadyPresent++;
        } else {
          const obligationId = deps.ids.next();
          const createdAt = deps.clock.now();
          await tx.run(
            `insert into obligations
             (id,business_id,tenancy_id,obligation_type,period_start,period_end,due_date,
              amount_minor,deterministic_key,created_at,sync_status)
             values (?,?,?,'rent',?,?,?,?,?,?, 'pending')`,
            [
              obligationId, ctx.businessId, row.tenancy_id, periodStart, periodEnd,
              dueDate, row.amount_minor, key, createdAt
            ]
          );
          await deps.events.append(tx, {
            id: deps.ids.next(),
            businessId: ctx.businessId,
            entityType: "obligation",
            entityId: obligationId,
            eventType: "monthly_rent_obligation_created",
            occurredAt: `${periodStart}T00:00:00Z`,
            recordedAt: createdAt,
            recordedByUserId: ctx.actorUserId,
            deviceId: ctx.deviceId,
            correlationId: ctx.correlationId,
            payload: { tenancyId: row.tenancy_id, periodStart, periodEnd, dueDate, billingTiming: row.billing_timing }
          });
          await enqueue(deps, tx, ctx.businessId, "obligation", obligationId, "insert", { id: obligationId }, [row.tenancy_id]);
          created++;
        }

        m++;
        if (m === 13) { m = 1; y++; }
      }
    }
    return { created, alreadyPresent };
  });
}

/* -------------------------------------------------------------------------- */
/* PAYMENT REVERSAL                                                            */
/* -------------------------------------------------------------------------- */

export async function reversePayment(
  deps: { db: Db; ids: Ids; clock: Clock; access: AccessGate; outbox: Outbox; events: DomainEvents },
  ctx: CommandContext,
  originalPaymentId: UUID,
  reason: string
): Promise<{ reversalPaymentId: UUID }> {
  if (!reason.trim()) throw new DomainError("REASON_REQUIRED", "Reversal reason is required");

  return deps.db.transaction(async tx => {
    const access = await deps.access.requireAction(tx, ctx, "reverse_payment", { type: "payment", id: originalPaymentId });
    if (access.state === "needs_approval") throw new DomainError("APPROVAL_REQUIRED", access.approvalRequestId);

    const original = await tx.get<{ tenancy_id: UUID; amount_minor: number; event_type: string }>(
      `select tenancy_id, amount_minor, event_type
       from payment_events where id = ? and business_id = ?`,
      [originalPaymentId, ctx.businessId]
    );
    if (!original || original.event_type !== "payment") {
      throw new DomainError("ORIGINAL_PAYMENT_NOT_FOUND", "Original payment not found");
    }

    const prior = await tx.get<{ id: UUID }>(
      `select id from payment_events
       where original_payment_id = ? and event_type in ('reversal','chargeback')`,
      [originalPaymentId]
    );
    if (prior) throw new DomainError("PAYMENT_ALREADY_REVERSED", "Payment already has reversal/chargeback");

    const reversalId = deps.ids.next();
    const createdAt = deps.clock.now();

    await tx.run(
      `insert into payment_events
       (id,business_id,tenancy_id,event_type,original_payment_id,amount_minor,
        occurred_at,recorded_by_user_id,metadata_json,created_at,sync_status)
       values (?,?,?,'reversal',?,?,?,?,?,?, 'pending')`,
      [
        reversalId, ctx.businessId, original.tenancy_id, originalPaymentId,
        original.amount_minor, ctx.occurredAt, ctx.actorUserId,
        JSON.stringify({ reason }), createdAt
      ]
    );

    const allocations = await tx.all<{ obligation_id: UUID; amount_minor: number }>(
      `select obligation_id, amount_minor from payment_allocations
       where payment_event_id = ? and allocation_effect = 1`,
      [originalPaymentId]
    );

    for (const a of allocations) {
      const id = deps.ids.next();
      await tx.run(
        `insert into payment_allocations
         (id,payment_event_id,obligation_id,amount_minor,allocation_effect,created_at,sync_status)
         values (?,?,?,?, -1, ?, 'pending')`,
        [id, reversalId, a.obligation_id, a.amount_minor, createdAt]
      );
      await enqueue(deps, tx, ctx.businessId, "payment_allocation", id, "insert", { id }, [reversalId, a.obligation_id]);
    }

    await deps.events.append(tx, {
      id: deps.ids.next(),
      businessId: ctx.businessId,
      entityType: "payment",
      entityId: reversalId,
      eventType: "payment_reversed",
      occurredAt: ctx.occurredAt,
      recordedAt: createdAt,
      recordedByUserId: ctx.actorUserId,
      deviceId: ctx.deviceId,
      correlationId: ctx.correlationId,
      payload: { originalPaymentId, reason }
    });

    await enqueue(deps, tx, ctx.businessId, "payment_event", reversalId, "insert", { id: reversalId }, [originalPaymentId]);
    return { reversalPaymentId: reversalId };
  });
}

/* -------------------------------------------------------------------------- */
/* ADD CHARGE                                                                  */
/* -------------------------------------------------------------------------- */

export async function addCharge(
  deps: { db: Db; ids: Ids; clock: Clock; access: AccessGate; outbox: Outbox; events: DomainEvents },
  ctx: CommandContext,
  input: {
    tenancyId: UUID;
    chargeType: "recurring" | "variable" | "one_time";
    category: string;
    amountMinor: Minor;
    effectiveDate: ISODate;
    description?: string;
    taxContext?: Record<string, unknown>;
  }
): Promise<{ chargeId: UUID; obligationId: UUID }> {
  assertPositiveMinor(input.amountMinor);
  return deps.db.transaction(async tx => {
    const access = await deps.access.requireAction(tx, ctx, "add_charge", { type: "tenancy", id: input.tenancyId });
    if (access.state === "needs_approval") throw new DomainError("APPROVAL_REQUIRED", access.approvalRequestId);

    const chargeId = deps.ids.next();
    const obligationId = deps.ids.next();
    const createdAt = deps.clock.now();

    await tx.run(
      `insert into charges
       (id,business_id,tenancy_id,charge_type,category,description,amount_minor,effective_date,
        dispute_state,tax_context_json,created_at,sync_status)
       values (?,?,?,?,?,?,?,?, 'none', ?,?,'pending')`,
      [chargeId, ctx.businessId, input.tenancyId, input.chargeType, input.category,
       input.description ?? null, input.amountMinor, input.effectiveDate,
       JSON.stringify(input.taxContext ?? {}), createdAt]
    );

    await tx.run(
      `insert into obligations
       (id,business_id,tenancy_id,obligation_type,source_charge_id,due_date,amount_minor,created_at,sync_status)
       values (?,?,?,'charge',?,?,?,?, 'pending')`,
      [obligationId, ctx.businessId, input.tenancyId, chargeId, input.effectiveDate, input.amountMinor, createdAt]
    );

    await deps.events.append(tx, {
      id: deps.ids.next(),
      businessId: ctx.businessId,
      entityType: "charge",
      entityId: chargeId,
      eventType: "charge_added",
      occurredAt: ctx.occurredAt,
      recordedAt: createdAt,
      recordedByUserId: ctx.actorUserId,
      deviceId: ctx.deviceId,
      correlationId: ctx.correlationId,
      payload: { obligationId, ...input }
    });

    await enqueue(deps, tx, ctx.businessId, "charge", chargeId, "insert", { id: chargeId }, [input.tenancyId]);
    await enqueue(deps, tx, ctx.businessId, "obligation", obligationId, "insert", { id: obligationId }, [chargeId, input.tenancyId]);
    return { chargeId, obligationId };
  });
}

/* -------------------------------------------------------------------------- */
/* ADD EXPENSE                                                                 */
/* -------------------------------------------------------------------------- */

export async function addExpense(
  deps: { db: Db; ids: Ids; clock: Clock; access: AccessGate; outbox: Outbox; events: DomainEvents },
  ctx: CommandContext,
  input: {
    amountMinor: Minor;
    category: string;
    paidByType: "business" | "staff";
    paidByPartyId?: UUID;
    paymentMethod?: string;
    expenseDate: ISODate;
    vendor?: string;
    propertyContextId?: UUID;
  }
): Promise<{ expenseId: UUID }> {
  assertPositiveMinor(input.amountMinor);
  if (input.paidByType === "staff" && !input.paidByPartyId) {
    throw new DomainError("STAFF_PAYER_REQUIRED", "Staff-paid expense requires paidByPartyId");
  }

  return deps.db.transaction(async tx => {
    const access = await deps.access.requireAction(tx, ctx, "add_expense");
    if (access.state === "needs_approval") throw new DomainError("APPROVAL_REQUIRED", access.approvalRequestId);

    const expenseId = deps.ids.next();
    const createdAt = deps.clock.now();
    const reimbursementState = input.paidByType === "staff" ? "owed" : "not_applicable";

    await tx.run(
      `insert into expenses
       (id,business_id,amount_minor,category,paid_by_type,paid_by_party_id,payment_method,
        expense_date,vendor,property_context_id,reimbursement_state,created_at,sync_status)
       values (?,?,?,?,?,?,?,?,?,?,?,?, 'pending')`,
      [
        expenseId, ctx.businessId, input.amountMinor, input.category, input.paidByType,
        input.paidByPartyId ?? null, input.paymentMethod ?? null, input.expenseDate,
        input.vendor ?? null, input.propertyContextId ?? null, reimbursementState, createdAt
      ]
    );

    await deps.events.append(tx, {
      id: deps.ids.next(),
      businessId: ctx.businessId,
      entityType: "expense",
      entityId: expenseId,
      eventType: "expense_added",
      occurredAt: ctx.occurredAt,
      recordedAt: createdAt,
      recordedByUserId: ctx.actorUserId,
      deviceId: ctx.deviceId,
      correlationId: ctx.correlationId,
      payload: { ...input, reimbursementState }
    });

    await enqueue(deps, tx, ctx.businessId, "expense", expenseId, "insert", { id: expenseId });
    return { expenseId };
  });
}

/* -------------------------------------------------------------------------- */
/* CASH HANDOVER                                                               */
/* -------------------------------------------------------------------------- */

export async function handoverCash(
  deps: { db: Db; ids: Ids; clock: Clock; access: AccessGate; outbox: Outbox; events: DomainEvents },
  ctx: CommandContext,
  input: {
    fromPartyId: UUID;
    toPartyId?: UUID;
    expectedAmountMinor: Minor;
    actualAmountMinor: Minor;
  }
): Promise<{ handoverEventId: UUID; discrepancyEventId?: UUID }> {
  assertPositiveMinor(input.expectedAmountMinor, "expectedAmountMinor");
  if (!Number.isInteger(input.actualAmountMinor) || input.actualAmountMinor < 0) {
    throw new DomainError("INVALID_ACTUAL_AMOUNT", "actualAmountMinor must be a non-negative integer");
  }

  return deps.db.transaction(async tx => {
    const access = await deps.access.requireAction(tx, ctx, "handover_cash");
    if (access.state === "needs_approval") throw new DomainError("APPROVAL_REQUIRED", access.approvalRequestId);

    const createdAt = deps.clock.now();
    const handoverEventId = deps.ids.next();

    await tx.run(
      `insert into cash_custody_events
       (id,business_id,event_type,from_party_id,to_party_id,amount_minor,occurred_at,
        recorded_by_user_id,created_at,sync_status)
       values (?,?, 'handover', ?,?,?,?,?,?, 'pending')`,
      [
        handoverEventId, ctx.businessId, input.fromPartyId, input.toPartyId ?? null,
        input.actualAmountMinor, ctx.occurredAt, ctx.actorUserId, createdAt
      ]
    );

    let discrepancyEventId: UUID | undefined;
    const diff = input.expectedAmountMinor - input.actualAmountMinor;
    if (diff !== 0) {
      discrepancyEventId = deps.ids.next();
      await tx.run(
        `insert into cash_custody_events
         (id,business_id,event_type,from_party_id,to_party_id,amount_minor,related_event_id,
          occurred_at,reason,recorded_by_user_id,created_at,sync_status)
         values (?,?, 'discrepancy', ?,?,?,?,?,?,?,?, 'pending')`,
        [
          discrepancyEventId, ctx.businessId, input.fromPartyId, input.toPartyId ?? null,
          Math.abs(diff), handoverEventId, ctx.occurredAt,
          diff > 0 ? "short_handover" : "excess_handover",
          ctx.actorUserId, createdAt
        ]
      );
    }

    await deps.events.append(tx, {
      id: deps.ids.next(),
      businessId: ctx.businessId,
      entityType: "cash_custody",
      entityId: handoverEventId,
      eventType: "cash_handover_recorded",
      occurredAt: ctx.occurredAt,
      recordedAt: createdAt,
      recordedByUserId: ctx.actorUserId,
      deviceId: ctx.deviceId,
      correlationId: ctx.correlationId,
      payload: { ...input, discrepancyEventId: discrepancyEventId ?? null }
    });

    await enqueue(deps, tx, ctx.businessId, "cash_custody_event", handoverEventId, "insert", { id: handoverEventId });
    if (discrepancyEventId) {
      await enqueue(deps, tx, ctx.businessId, "cash_custody_event", discrepancyEventId, "insert", { id: discrepancyEventId }, [handoverEventId]);
    }
    return { handoverEventId, discrepancyEventId };
  });
}

/* -------------------------------------------------------------------------- */
/* PLAN / END TENANCY                                                          */
/* -------------------------------------------------------------------------- */

export async function planMoveOut(
  deps: { db: Db; ids: Ids; clock: Clock; access: AccessGate; outbox: Outbox; events: DomainEvents },
  ctx: CommandContext,
  tenancyId: UUID,
  plannedDate: ISODate
): Promise<void> {
  await deps.db.transaction(async tx => {
    const access = await deps.access.requireAction(tx, ctx, "plan_move_out", { type: "tenancy", id: tenancyId });
    if (access.state === "needs_approval") throw new DomainError("APPROVAL_REQUIRED", access.approvalRequestId);

    const tenancy = await tx.get<{ lifecycle_state: string }>(
      `select lifecycle_state from tenancies where id = ? and business_id = ?`,
      [tenancyId, ctx.businessId]
    );
    if (!tenancy || !["active","planned_move_out"].includes(tenancy.lifecycle_state)) {
      throw new DomainError("INVALID_LIFECYCLE", "Move-out planning requires an active tenancy");
    }

    await tx.run(
      `update tenancies
       set lifecycle_state='planned_move_out', planned_move_out_date=?, updated_at=?, sync_status='pending'
       where id=?`,
      [plannedDate, deps.clock.now(), tenancyId]
    );

    await deps.events.append(tx, {
      id: deps.ids.next(), businessId: ctx.businessId, entityType: "tenancy", entityId: tenancyId,
      eventType: "moveout_planned", occurredAt: ctx.occurredAt, recordedAt: deps.clock.now(),
      recordedByUserId: ctx.actorUserId, deviceId: ctx.deviceId, correlationId: ctx.correlationId,
      payload: { plannedDate }
    });

    await enqueue(deps, tx, ctx.businessId, "tenancy", tenancyId, "update",
      { lifecycle_state: "planned_move_out", planned_move_out_date: plannedDate });
  });
}

export async function endTenancy(
  deps: { db: Db; ids: Ids; clock: Clock; access: AccessGate; outbox: Outbox; events: DomainEvents },
  ctx: CommandContext,
  tenancyId: UUID,
  endedAt: ISODateTime
): Promise<void> {
  await deps.db.transaction(async tx => {
    const access = await deps.access.requireAction(tx, ctx, "end_tenancy", { type: "tenancy", id: tenancyId });
    if (access.state === "needs_approval") throw new DomainError("APPROVAL_REQUIRED", access.approvalRequestId);

    const tenancy = await tx.get<{ lifecycle_state: string }>(
      `select lifecycle_state from tenancies where id = ? and business_id = ?`,
      [tenancyId, ctx.businessId]
    );
    if (!tenancy || !["active","planned_move_out"].includes(tenancy.lifecycle_state)) {
      throw new DomainError("INVALID_LIFECYCLE", "Only active/planned-move-out tenancy can end");
    }

    const activeOccupancy = await tx.get<{ id: UUID }>(
      `select id from occupancy_assignments where tenancy_id=? and assignment_state='active'`,
      [tenancyId]
    );

    if (activeOccupancy) {
      await tx.run(
        `update occupancy_assignments
         set assignment_state='ended', end_at=?, sync_status='pending'
         where id=?`,
        [endedAt, activeOccupancy.id]
      );
      await enqueue(deps, tx, ctx.businessId, "occupancy_assignment", activeOccupancy.id, "update",
        { assignment_state: "ended", end_at: endedAt });
    }

    await tx.run(
      `update tenancies
       set lifecycle_state='moved_out', ended_at=?, updated_at=?, sync_status='pending'
       where id=?`,
      [endedAt, deps.clock.now(), tenancyId]
    );

    await deps.events.append(tx, {
      id: deps.ids.next(), businessId: ctx.businessId, entityType: "tenancy", entityId: tenancyId,
      eventType: "tenancy_ended", occurredAt: endedAt, recordedAt: deps.clock.now(),
      recordedByUserId: ctx.actorUserId, deviceId: ctx.deviceId, correlationId: ctx.correlationId,
      payload: { activeOccupancyId: activeOccupancy?.id ?? null }
    });

    await enqueue(deps, tx, ctx.businessId, "tenancy", tenancyId, "update",
      { lifecycle_state: "moved_out", ended_at: endedAt });

    // Deliberately preserve obligations, payments, security, refunds and statement history.
  });
}

/* -------------------------------------------------------------------------- */
/* SECURITY REFUND                                                             */
/* -------------------------------------------------------------------------- */

export async function refundSecurity(
  deps: { db: Db; ids: Ids; clock: Clock; access: AccessGate; outbox: Outbox; events: DomainEvents },
  ctx: CommandContext,
  input: { tenancyId: UUID; amountMinor: Minor; reason?: string }
): Promise<{ securityEventId: UUID }> {
  assertPositiveMinor(input.amountMinor);

  return deps.db.transaction(async tx => {
    const access = await deps.access.requireAction(tx, ctx, "refund_security", { type: "tenancy", id: input.tenancyId });
    if (access.state === "needs_approval") throw new DomainError("APPROVAL_REQUIRED", access.approvalRequestId);

    const account = await tx.get<{ id: UUID }>(
      `select id from security_accounts where tenancy_id = ?`,
      [input.tenancyId]
    );
    if (!account) throw new DomainError("SECURITY_ACCOUNT_NOT_FOUND", "No security account found");

    const held = await tx.get<{ held_amount_minor: number }>(
      `select held_amount_minor from v_security_balances where security_account_id=?`,
      [account.id]
    );
    if (!held || held.held_amount_minor < input.amountMinor) {
      throw new DomainError("INSUFFICIENT_SECURITY_HELD", "Refund exceeds security actually held");
    }

    const id = deps.ids.next();
    const createdAt = deps.clock.now();

    await tx.run(
      `insert into security_events
       (id,security_account_id,event_type,amount_minor,occurred_at,reason,created_at,sync_status)
       values (?,?,'refund',?,?,?,?, 'pending')`,
      [id, account.id, input.amountMinor, ctx.occurredAt, input.reason ?? null, createdAt]
    );

    await deps.events.append(tx, {
      id: deps.ids.next(), businessId: ctx.businessId, entityType: "security", entityId: account.id,
      eventType: "security_refunded", occurredAt: ctx.occurredAt, recordedAt: createdAt,
      recordedByUserId: ctx.actorUserId, deviceId: ctx.deviceId, correlationId: ctx.correlationId,
      payload: { securityEventId: id, tenancyId: input.tenancyId, amountMinor: input.amountMinor }
    });

    await enqueue(deps, tx, ctx.businessId, "security_event", id, "insert", { id }, [account.id]);
    return { securityEventId: id };
  });
}
