/**
 * Khaata PG / Hostel V1 — Mobile Repository + Service Contract v1
 *
 * STATUS: PROPOSED IMPLEMENTATION CONTRACT.
 * SQLite is the operational source on device.
 * Every command below commits locally first and enqueues sync work atomically.
 *
 * This file defines interfaces and transaction boundaries, not framework-specific code.
 */

export type UUID = string;
export type ISODate = string;      // YYYY-MM-DD
export type ISODateTime = string;  // RFC3339 UTC
export type Minor = number;        // integer minor currency units only

export type Result<T> =
  | { ok: true; value: T }
  | { ok: false; code: string; message: string; retryable?: boolean };

export type TenancyState =
  | "upcoming"
  | "active"
  | "planned_move_out"
  | "moved_out"
  | "cancelled_before_joining";

export type PermissionState =
  | "allowed"
  | "needs_approval"
  | "not_allowed";

export interface CommandContext {
  businessId: UUID;
  actorUserId: UUID;
  deviceId: UUID;
  occurredAt: ISODateTime;
  correlationId?: UUID;
}

export interface LocalDatabase {
  transaction<T>(fn: (tx: LocalTx) => Promise<T>): Promise<T>;
}

export interface LocalTx {
  run(sql: string, params?: unknown[]): Promise<void>;
  get<T>(sql: string, params?: unknown[]): Promise<T | undefined>;
  all<T>(sql: string, params?: unknown[]): Promise<T[]>;
}

/* -------------------------------------------------------------------------- */
/* ID + CLOCK + OUTBOX                                                         */
/* -------------------------------------------------------------------------- */

export interface IdGenerator {
  next(): UUID; // globally unique and safe to create offline
}

export interface Clock {
  now(): ISODateTime;
  today(): ISODate;
}

export interface SyncOutboxWriter {
  enqueue(
    tx: LocalTx,
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

export interface DomainEventWriter {
  append(
    tx: LocalTx,
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
      causationId?: UUID;
      correlationId?: UUID;
      payload: unknown;
    }
  ): Promise<void>;
}

/* -------------------------------------------------------------------------- */
/* ACCESS / ENTITLEMENT                                                        */
/* -------------------------------------------------------------------------- */

export interface AccessService {
  requireAction(
    tx: LocalTx,
    ctx: CommandContext,
    actionKey: string,
    target?: { type: string; id: UUID }
  ): Promise<
    | { state: "allowed" }
    | { state: "needs_approval"; approvalRequestId: UUID }
  >;

  requireEntitlement(
    tx: LocalTx,
    entitlementKey: string
  ): Promise<void>;
}

/* -------------------------------------------------------------------------- */
/* BUSINESS + SETUP                                                            */
/* -------------------------------------------------------------------------- */

export interface CreateBusinessInput {
  name: string;
  businessType: string;
  locationText?: string;
  operationalCurrency: string;
  timezone?: string;
}

export interface BusinessService {
  createBusiness(
    ctx: Omit<CommandContext, "businessId">,
    input: CreateBusinessInput
  ): Promise<Result<{ businessId: UUID }>>;

  retireBusiness(
    ctx: CommandContext
  ): Promise<Result<void>>;
}

/* -------------------------------------------------------------------------- */
/* PROPERTY / CAPACITY                                                         */
/* -------------------------------------------------------------------------- */

export interface CreateCapacityInput {
  parentId?: UUID;
  nodeType: "building" | "block" | "floor" | "room" | "bed";
  label: string;
  metadata?: Record<string, unknown>;
}

export interface PropertyService {
  createCapacity(
    ctx: CommandContext,
    input: CreateCapacityInput
  ): Promise<Result<{ capacityId: UUID }>>;

  setCapacityTemporarilyUnavailable(
    ctx: CommandContext,
    capacityId: UUID,
    reason?: string
  ): Promise<Result<void>>;

  retireCapacity(
    ctx: CommandContext,
    capacityId: UUID,
    reason?: string
  ): Promise<Result<void>>;
}

/* -------------------------------------------------------------------------- */
/* TENANCY                                                                     */
/* -------------------------------------------------------------------------- */

export interface AddUpcomingTenantInput {
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

export interface TenancyService {
  addUpcomingTenant(
    ctx: CommandContext,
    input: AddUpcomingTenantInput
  ): Promise<Result<{ tenancyId: UUID }>>;

  confirmJoined(
    ctx: CommandContext,
    tenancyId: UUID
  ): Promise<Result<void>>;

  changeJoiningDate(
    ctx: CommandContext,
    tenancyId: UUID,
    newDate: ISODate
  ): Promise<Result<void>>;

  cancelBeforeJoining(
    ctx: CommandContext,
    tenancyId: UUID,
    reason: string
  ): Promise<Result<void>>;

  transferRoom(
    ctx: CommandContext,
    tenancyId: UUID,
    newCapacityId: UUID,
    effectiveAt: ISODateTime
  ): Promise<Result<void>>;

  changeRent(
    ctx: CommandContext,
    tenancyId: UUID,
    newAmountMinor: Minor,
    effectiveFrom: ISODate
  ): Promise<Result<void>>;

  planMoveOut(
    ctx: CommandContext,
    tenancyId: UUID,
    plannedDate: ISODate
  ): Promise<Result<void>>;

  cancelPlannedMoveOut(
    ctx: CommandContext,
    tenancyId: UUID
  ): Promise<Result<void>>;

  endTenancy(
    ctx: CommandContext,
    tenancyId: UUID,
    endedAt: ISODateTime
  ): Promise<Result<void>>;
}

/* -------------------------------------------------------------------------- */
/* BILLING                                                                     */
/* -------------------------------------------------------------------------- */

export interface BillingService {
  ensureMonthlyObligations(
    ctx: CommandContext,
    throughPeriod: ISODate
  ): Promise<Result<{ created: number; alreadyPresent: number }>>;

  getTenantStatement(
    businessId: UUID,
    tenancyId: UUID
  ): Promise<Result<TenantStatement>>;
}

export interface TenantStatement {
  tenancyId: UUID;
  obligations: unknown[];
  payments: unknown[];
  credits: unknown[];
  adjustments: unknown[];
  openingBalances: unknown[];
  security: unknown; // shown separately from rent/charge balance
}

/* -------------------------------------------------------------------------- */
/* PAYMENTS                                                                    */
/* -------------------------------------------------------------------------- */

export interface PaymentAllocationInput {
  obligationId: UUID;
  amountMinor: Minor;
}

export interface RecordPaymentInput {
  tenancyId: UUID;
  payerPartyId?: UUID;
  amountMinor: Minor;
  method?: string;
  allocations: PaymentAllocationInput[];
  receiveCashIntoCustodyOfPartyId?: UUID;
}

export interface PaymentService {
  recordPayment(
    ctx: CommandContext,
    input: RecordPaymentInput
  ): Promise<Result<{ paymentId: UUID; receiptId: UUID }>>;

  reversePayment(
    ctx: CommandContext,
    originalPaymentId: UUID,
    reason: string
  ): Promise<Result<{ reversalPaymentId: UUID }>>;

  recordChargeback(
    ctx: CommandContext,
    originalPaymentId: UUID,
    reason: string
  ): Promise<Result<{ chargebackPaymentId: UUID }>>;
}

/**
 * REQUIRED transaction for recordPayment:
 *
 * BEGIN
 *   validate allocation total <= amount
 *   insert payment_events
 *   insert payment_allocations*
 *   insert receipt_snapshots
 *   if cash collected by staff:
 *      insert cash_custody_events(collection_received)
 *   append domain_events*
 *   enqueue sync_outbox*
 * COMMIT
 *
 * After COMMIT the tenant is considered paid locally.
 * Network availability is irrelevant to payment truth.
 */

/* -------------------------------------------------------------------------- */
/* PAYMENT PROMISE                                                             */
/* -------------------------------------------------------------------------- */

export interface PromiseService {
  recordPromise(
    ctx: CommandContext,
    input: {
      tenancyId: UUID;
      obligationId?: UUID;
      promisedAmountMinor: Minor;
      promisedDate: ISODate;
    }
  ): Promise<Result<{ promiseId: UUID }>>;
}

/* -------------------------------------------------------------------------- */
/* CHARGES + ADJUSTMENTS                                                       */
/* -------------------------------------------------------------------------- */

export interface ChargeService {
  addCharge(
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
  ): Promise<Result<{ chargeId: UUID; obligationId: UUID }>>;

  waive(
    ctx: CommandContext,
    obligationId: UUID,
    amountMinor: Minor,
    reason: string
  ): Promise<Result<{ adjustmentId: UUID }>>;

  writeOff(
    ctx: CommandContext,
    obligationId: UUID,
    amountMinor: Minor,
    reason: string
  ): Promise<Result<{ adjustmentId: UUID }>>;

  markDisputed(
    ctx: CommandContext,
    chargeId: UUID
  ): Promise<Result<void>>;
}

/* -------------------------------------------------------------------------- */
/* SECURITY                                                                    */
/* -------------------------------------------------------------------------- */

export interface SecurityService {
  recordDeposit(
    ctx: CommandContext,
    input: {
      tenancyId: UUID;
      amountMinor: Minor;
      depositOwnerPartyId?: UUID;
      paymentMethod?: string;
    }
  ): Promise<Result<{ securityEventId: UUID }>>;

  applySecurityToDues(
    ctx: CommandContext,
    input: {
      tenancyId: UUID;
      obligationId: UUID;
      amountMinor: Minor;
      reason?: string;
    }
  ): Promise<Result<{ securityEventId: UUID }>>;

  refundSecurity(
    ctx: CommandContext,
    input: {
      tenancyId: UUID;
      amountMinor: Minor;
      reason?: string;
    }
  ): Promise<Result<{ securityEventId: UUID }>>;
}

/* -------------------------------------------------------------------------- */
/* EXPENSES                                                                    */
/* -------------------------------------------------------------------------- */

export interface ExpenseService {
  addExpense(
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
  ): Promise<Result<{ expenseId: UUID }>>;
}

/* -------------------------------------------------------------------------- */
/* CASH CUSTODY                                                                */
/* -------------------------------------------------------------------------- */

export interface CashCustodyService {
  handoverCash(
    ctx: CommandContext,
    input: {
      fromPartyId: UUID;
      toPartyId?: UUID;
      expectedAmountMinor: Minor;
      actualAmountMinor: Minor;
    }
  ): Promise<
    Result<{
      handoverEventId: UUID;
      discrepancyEventId?: UUID;
    }>
  >;

  resolveDiscrepancy(
    ctx: CommandContext,
    input: {
      discrepancyEventId: UUID;
      resolutionType: "remaining_cash_handed_over" | "approved_loss" | "recording_correction";
      amountMinor: Minor;
      reason: string;
    }
  ): Promise<Result<{ resolutionEventId: UUID }>>;
}

/* -------------------------------------------------------------------------- */
/* APPROVALS                                                                   */
/* -------------------------------------------------------------------------- */

export interface ApprovalService {
  requestApproval(
    ctx: CommandContext,
    input: {
      actionType: string;
      targetType?: string;
      targetId?: UUID;
      requestPayload?: Record<string, unknown>;
    }
  ): Promise<Result<{ approvalRequestId: UUID }>>;

  approve(
    ctx: CommandContext,
    approvalRequestId: UUID
  ): Promise<Result<void>>;

  decline(
    ctx: CommandContext,
    approvalRequestId: UUID,
    reason?: string
  ): Promise<Result<void>>;
}

/* -------------------------------------------------------------------------- */
/* SYNC                                                                        */
/* -------------------------------------------------------------------------- */

export interface SyncService {
  syncNow(): Promise<Result<{
    pulled: number;
    pushed: number;
    conflicts: number;
    mode: "normal" | "drain_only";
  }>>;

  getStatus(): Promise<{
    pendingCount: number;
    conflictCount: number;
    lastSuccessAt?: ISODateTime;
    mode: "normal" | "offline" | "drain_only" | "conflict";
  }>;
}

/* -------------------------------------------------------------------------- */
/* COMPOSITION ROOT                                                            */
/* -------------------------------------------------------------------------- */

export interface KhaataPgServices {
  business: BusinessService;
  property: PropertyService;
  tenancy: TenancyService;
  billing: BillingService;
  payments: PaymentService;
  promises: PromiseService;
  charges: ChargeService;
  security: SecurityService;
  expenses: ExpenseService;
  cash: CashCustodyService;
  approvals: ApprovalService;
  sync: SyncService;
}
