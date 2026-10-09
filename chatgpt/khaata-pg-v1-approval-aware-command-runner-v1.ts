/**
 * Khaata PG / Hostel V1 — Approval-aware Command Runner v1
 *
 * This is the command-side retrofit for the corrected approval architecture.
 *
 * Broken old pattern:
 *   transaction {
 *     const access = requireAction(...)
 *     if (needsApproval) throw APPROVAL_REQUIRED
 *   }
 *
 * If requireAction inserted approval_request inside that transaction, throwing
 * rolled the request back.
 *
 * Correct pattern:
 *   transaction {
 *     const decision = evaluate(...)
 *     if (approval_required) return approval_required
 *     mutate domain
 *     append domain event
 *     consume authorization, if one was used
 *     return executed
 *   }
 *
 * The transaction commits in BOTH result branches.
 */

export type UUID = string;
export type ISODateTime = string;

export interface DbTx {
  run(sql:string,params?:unknown[]):Promise<void>;
  get<T>(sql:string,params?:unknown[]):Promise<T|undefined>;
}
export interface Db {
  transaction<T>(fn:(tx:DbTx)=>Promise<T>):Promise<T>;
}
export interface Ids { next():UUID; }
export interface Clock { now():ISODateTime; }

export interface CommandContext {
  businessId:UUID;
  actorUserId:UUID;
  deviceId:UUID;
  occurredAt:ISODateTime;
  causationId?:UUID;
  approvalAuthorizationId?:UUID;
}

export type GateDecision =
  | {
      state:"allowed";
      membershipId?:UUID;
      authorizationId?:UUID;
    }
  | {
      state:"approval_required";
      membershipId?:UUID;
      approvalRequestId:UUID;
    };

export type CommandResult<T> =
  | {status:"executed";value:T}
  | {status:"approval_required";approvalRequestId:UUID};

export interface ApprovalAwareAccessGate {
  evaluate(
    tx:DbTx,
    ctx:CommandContext,
    actionKey:string,
    target?:{type:string;id:UUID}
  ):Promise<GateDecision>;

  consumeAuthorization(
    tx:DbTx,
    ctx:CommandContext,
    authorizationId:UUID,
    executedDomainEventId:UUID
  ):Promise<void>;
}

export interface DomainEvents {
  append(tx:DbTx,event:{
    id:UUID;
    businessId:UUID;
    entityType:string;
    entityId:UUID;
    eventType:string;
    occurredAt:ISODateTime;
    recordedAt:ISODateTime;
    recordedByUserId:UUID;
    deviceId:UUID;
    payload:unknown;
  }):Promise<void>;
}

export interface CommandMutation<T> {
  execute(tx:DbTx,args:{
    domainEventId:UUID;
    recordedAt:ISODateTime;
  }):Promise<{
    value:T;
    event:{
      entityType:string;
      entityId:UUID;
      eventType:string;
      payload:unknown;
    };
  }>;
}

export async function runApprovalAwareCommand<T>(
  deps:{
    db:Db;
    ids:Ids;
    clock:Clock;
    access:ApprovalAwareAccessGate;
    events:DomainEvents;
  },
  ctx:CommandContext,
  input:{
    actionKey:string;
    target?:{type:string;id:UUID};
    mutation:CommandMutation<T>;
  }
):Promise<CommandResult<T>>{
  return deps.db.transaction(async tx=>{
    const decision=await deps.access.evaluate(
      tx,ctx,input.actionKey,input.target
    );

    if(decision.state==="approval_required"){
      // IMPORTANT:
      // return normally so the newly-created/reused approval_request COMMITs.
      return {
        status:"approval_required",
        approvalRequestId:decision.approvalRequestId
      };
    }

    const domainEventId=deps.ids.next();
    const recordedAt=deps.clock.now();

    const mutationResult=await input.mutation.execute(tx,{
      domainEventId,recordedAt
    });

    await deps.events.append(tx,{
      id:domainEventId,
      businessId:ctx.businessId,
      entityType:mutationResult.event.entityType,
      entityId:mutationResult.event.entityId,
      eventType:mutationResult.event.eventType,
      occurredAt:ctx.occurredAt,
      recordedAt,
      recordedByUserId:ctx.actorUserId,
      deviceId:ctx.deviceId,
      payload:mutationResult.event.payload
    });

    if(decision.authorizationId){
      // Same SQLite transaction as the real mutation.
      // If anything after this throws, both domain mutation and consumption roll back.
      await deps.access.consumeAuthorization(
        tx,ctx,decision.authorizationId,domainEventId
      );
    }

    return {status:"executed",value:mutationResult.value};
  });
}

/* -------------------------------------------------------------------------- */
/* APPROVAL REQUEST IDEMPOTENCY                                                */
/* -------------------------------------------------------------------------- */

export function approvalRequestKey(input:{
  businessId:UUID;
  actorUserId:UUID;
  actionKey:string;
  target?:{type:string;id:UUID};
  causationId?:UUID;
}):string{
  const target=input.target
    ? `${input.target.type}:${input.target.id}`
    : "none";

  return [
    input.businessId,
    input.actorUserId,
    input.actionKey,
    target,
    input.causationId??"no-causation"
  ].join("|");
}

/**
 * Gate implementation rule:
 *
 * For permission = needs_approval:
 *
 * 1. build request_key from stable command intent
 * 2. SELECT pending approval_request by request_key
 * 3. if found, return it
 * 4. otherwise INSERT a new request
 * 5. return approval_required normally
 *
 * Never create duplicate pending requests just because the user tapped again.
 */

/* -------------------------------------------------------------------------- */
/* APPROVER AUTHORITY                                                         */
/* -------------------------------------------------------------------------- */

/**
 * ApprovalService rule:
 *
 * actor may approve if:
 *   A) actor is business owner
 *   OR
 *   B) actor has active staff membership AND effective action permission
 *      approve_requests = allowed
 *
 * Any active staff member is NOT automatically an approver.
 *
 * Audit fields:
 *   decided_by_user_id       = actor user always
 *   decided_by_membership_id = actor staff membership when one exists, else null
 *
 * Never attribute an owner approval to the requester's membership.
 */

/* -------------------------------------------------------------------------- */
/* RETROFIT MAP                                                               */
/* -------------------------------------------------------------------------- */

export const ProtectedCommandMap = {
  addTenant: {
    actionKey:"add_tenant",
    targetType:"business"
  },
  confirmJoined: {
    actionKey:"confirm_joined",
    targetType:"tenancy"
  },
  proceedWithMissingRequirements: {
    actionKey:"proceed_with_missing_requirements",
    targetType:"tenancy"
  },
  recordPayment: {
    actionKey:"record_payment",
    targetType:"tenancy"
  },
  reversePayment: {
    actionKey:"reverse_payment",
    targetType:"payment"
  },
  addExpense: {
    actionKey:"add_expense",
    targetType:"business"
  },
  addCharge: {
    actionKey:"add_charge",
    targetType:"tenancy"
  },
  transferRoom: {
    actionKey:"transfer_room",
    targetType:"tenancy"
  },
  planMoveOut: {
    actionKey:"plan_move_out",
    targetType:"tenancy"
  },
  endTenancy: {
    actionKey:"end_tenancy",
    targetType:"tenancy"
  },
  applySecurityToDues: {
    actionKey:"apply_security_to_dues",
    targetType:"tenancy"
  },
  refundSecurity: {
    actionKey:"refund_security",
    targetType:"tenancy"
  },
  handoverCash: {
    actionKey:"handover_cash",
    targetType:"party"
  },
  retireCapacity: {
    actionKey:"retire_capacity",
    targetType:"capacity"
  },
  manageStaff: {
    actionKey:"manage_staff",
    targetType:"staff_membership"
  },
  setOpeningBalance: {
    actionKey:"set_opening_balance",
    targetType:"tenancy"
  },
  correctOpeningBalance: {
    actionKey:"correct_opening_balance",
    targetType:"tenancy"
  }
} as const;

/* -------------------------------------------------------------------------- */
/* EXAMPLE: RECORD PAYMENT RETROFIT                                            */
/* -------------------------------------------------------------------------- */

/**
 * return runApprovalAwareCommand(deps,ctx,{
 *   actionKey:"record_payment",
 *   target:{type:"tenancy",id:input.tenancyId},
 *   mutation:{
 *     async execute(tx,{domainEventId,recordedAt}){
 *       // validate outstanding / allocation invariants
 *       // INSERT payment_event
 *       // INSERT payment_allocations
 *       // INSERT immutable receipt_snapshot
 *       // INSERT optional cash_custody_event
 *       // enqueue typed sync work + sync_entity_state
 *
 *       return {
 *         value:{paymentId,receiptId},
 *         event:{
 *           entityType:"payment",
 *           entityId:paymentId,
 *           eventType:"payment_recorded",
 *           payload:{...}
 *         }
 *       };
 *     }
 *   }
 * });
 *
 * UI handling:
 *
 * const result=await recordPayment(...);
 *
 * if(result.status==="approval_required"){
 *   openApprovalPending(result.approvalRequestId);
 *   return;
 * }
 *
 * showReceipt(result.value.receiptId);
 */

/* -------------------------------------------------------------------------- */
/* APPROVED RETRY                                                             */
/* -------------------------------------------------------------------------- */

/**
 * The approved command is the SAME command intent retried with:
 *
 * ctx.approvalAuthorizationId = authorizationId
 *
 * The gate validates:
 * - same actor
 * - same business
 * - same action
 * - same target
 * - not expired
 * - not consumed
 *
 * Then the command executes and consumes the authorization in the same tx.
 *
 * Approval itself never calls the mutation callback.
 */
