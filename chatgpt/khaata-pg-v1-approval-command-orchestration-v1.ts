/**
 * Khaata PG / Hostel V1 — Approval Command Orchestration v1
 *
 * Fixes the rollback contradiction in the earlier integration pattern.
 *
 * OLD (broken):
 *   begin transaction
 *   create approval_request
 *   throw APPROVAL_REQUIRED
 *   transaction rolls back
 *   request disappears
 *
 * NEW:
 *   begin transaction
 *   evaluate permission
 *   if Needs approval:
 *     create/reuse approval_request
 *     return approval_required normally
 *   transaction commits
 *   UI receives approvalRequestId
 *
 * Approval creates authorization only.
 * The underlying command is retried later with that authorization.
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

export interface CommandContext {
  businessId:UUID;
  actorUserId:UUID;
  deviceId:UUID;
  occurredAt:ISODateTime;
  approvalAuthorizationId?:UUID;
  causationId?:UUID;
}

export type PermissionState = "allowed"|"needs_approval"|"not_allowed";

export type GateDecision =
  | {state:"allowed";membershipId?:UUID;authorizationId?:UUID}
  | {state:"approval_required";membershipId?:UUID;approvalRequestId:UUID};

export type CommandResult<T> =
  | {status:"executed";value:T}
  | {status:"approval_required";approvalRequestId:UUID};

export class AccessDenied extends Error {
  constructor(public code:string,message:string){super(message);}
}

function requestKey(input:{
  businessId:UUID;
  actorUserId:UUID;
  actionKey:string;
  target?:{type:string;id:UUID};
  causationId?:UUID;
}):string{
  const target=input.target ? `${input.target.type}:${input.target.id}` : "none";
  // causationId should be stable across user retries of the same command intent.
  return [
    input.businessId,
    input.actorUserId,
    input.actionKey,
    target,
    input.causationId??"no-causation"
  ].join("|");
}

export class ApprovalAwareAccessGate {
  constructor(private d:{
    ids:Ids;
    clock:Clock;
    sync:SyncQueue;
    events:DomainEvents;
  }){}

  async evaluate(
    tx:DbTx,
    ctx:CommandContext,
    actionKey:string,
    target?:{type:string;id:UUID}
  ):Promise<GateDecision>{
    const owner=await tx.get<{owner_user_id:UUID}>(
      `select owner_user_id from businesses where id=?`,
      [ctx.businessId]
    );
    if(!owner) throw new AccessDenied("BUSINESS_NOT_FOUND","Business not found");

    const membership=await tx.get<{id:UUID;membership_state:string}>(
      `select id,membership_state
       from staff_memberships
       where business_id=? and user_id=?`,
      [ctx.businessId,ctx.actorUserId]
    );

    if(owner.owner_user_id===ctx.actorUserId){
      return {state:"allowed",membershipId:membership?.id};
    }

    if(!membership)
      throw new AccessDenied("NO_BUSINESS_ACCESS","User has no business membership");
    if(membership.membership_state!=="active")
      throw new AccessDenied("MEMBERSHIP_DISABLED","Membership is disabled");

    const permission=await tx.get<{permission_state:PermissionState}>(
      `select permission_state
       from v_effective_staff_actions
       where membership_id=? and action_key=?`,
      [membership.id,actionKey]
    );

    if(!permission || permission.permission_state==="not_allowed")
      throw new AccessDenied("ACTION_NOT_ALLOWED",`${actionKey} is not allowed`);

    if(permission.permission_state==="allowed")
      return {state:"allowed",membershipId:membership.id};

    if(ctx.approvalAuthorizationId){
      const auth=await this.validateAuthorization(
        tx,ctx,ctx.approvalAuthorizationId,actionKey,target,membership.id
      );
      return {
        state:"allowed",
        membershipId:membership.id,
        authorizationId:auth.id
      };
    }

    const key=requestKey({
      businessId:ctx.businessId,
      actorUserId:ctx.actorUserId,
      actionKey,
      target,
      causationId:ctx.causationId
    });

    const existing=await tx.get<{id:UUID}>(
      `select id
       from approval_requests
       where business_id=? and request_key=? and state='pending'
       limit 1`,
      [ctx.businessId,key]
    );
    if(existing){
      return {
        state:"approval_required",
        membershipId:membership.id,
        approvalRequestId:existing.id
      };
    }

    const approvalRequestId=this.d.ids.next();
    const now=this.d.clock.now();

    await tx.run(
      `insert into approval_requests(
        id,business_id,requested_by_membership_id,requested_by_user_id,
        action_type,target_type,target_id,request_payload_json,state,
        request_key,created_at
      ) values (?,?,?,?,?,?,?,?, 'pending',?,?)`,
      [
        approvalRequestId,ctx.businessId,membership.id,ctx.actorUserId,
        actionKey,target?.type??null,target?.id??null,
        JSON.stringify({causationId:ctx.causationId??null}),
        key,now
      ]
    );

    const eventId=this.d.ids.next();
    await this.d.events.append(tx,{
      id:eventId,
      businessId:ctx.businessId,
      entityType:"approval_request",
      entityId:approvalRequestId,
      eventType:"approval_requested",
      occurredAt:ctx.occurredAt,
      recordedAt:now,
      recordedByUserId:ctx.actorUserId,
      deviceId:ctx.deviceId,
      payload:{
        actionKey,
        target:target??null,
        requestKey:key
      }
    });

    await this.d.sync.enqueue(tx,{
      businessId:ctx.businessId,
      entityType:"approval_request",
      entityId:approvalRequestId,
      operation:"insert",
      payload:{id:approvalRequestId}
    });

    return {
      state:"approval_required",
      membershipId:membership.id,
      approvalRequestId
    };
  }

  async consumeAuthorization(
    tx:DbTx,
    ctx:CommandContext,
    authorizationId:UUID,
    executedDomainEventId:UUID
  ):Promise<void>{
    const auth=await tx.get<{consumed_at?:ISODateTime}>(
      `select consumed_at from approval_authorizations
       where id=? and business_id=?`,
      [authorizationId,ctx.businessId]
    );
    if(!auth) throw new AccessDenied("APPROVAL_NOT_FOUND","Authorization not found");
    if(auth.consumed_at)
      throw new AccessDenied("APPROVAL_ALREADY_USED","Authorization already used");

    await tx.run(
      `update approval_authorizations
       set consumed_at=?,consumed_by_event_id=?
       where id=? and consumed_at is null`,
      [ctx.occurredAt,executedDomainEventId,authorizationId]
    );
  }

  private async validateAuthorization(
    tx:DbTx,
    ctx:CommandContext,
    id:UUID,
    actionKey:string,
    target:{type:string;id:UUID}|undefined,
    membershipId:UUID
  ):Promise<{id:UUID}>{
    const a=await tx.get<any>(
      `select id,action_type,target_type,target_id,authorized_for_membership_id,
              authorized_for_user_id,consumed_at,expires_at
       from approval_authorizations
       where id=? and business_id=?`,
      [id,ctx.businessId]
    );
    if(!a) throw new AccessDenied("APPROVAL_NOT_FOUND","Authorization not found");
    if(a.consumed_at)
      throw new AccessDenied("APPROVAL_ALREADY_USED","Authorization already used");
    if(a.expires_at && a.expires_at<=ctx.occurredAt)
      throw new AccessDenied("APPROVAL_EXPIRED","Authorization expired");
    if(a.action_type!==actionKey)
      throw new AccessDenied("APPROVAL_WRONG_ACTION","Wrong approved action");
    if(a.authorized_for_user_id && a.authorized_for_user_id!==ctx.actorUserId)
      throw new AccessDenied("APPROVAL_WRONG_ACTOR","Wrong approved actor");
    if(a.authorized_for_membership_id && a.authorized_for_membership_id!==membershipId)
      throw new AccessDenied("APPROVAL_WRONG_ACTOR","Wrong approved membership");
    if(a.target_type && target?.type!==a.target_type)
      throw new AccessDenied("APPROVAL_WRONG_TARGET","Wrong approved target");
    if(a.target_id && target?.id!==a.target_id)
      throw new AccessDenied("APPROVAL_WRONG_TARGET","Wrong approved target");
    return {id:a.id};
  }
}

/* -------------------------------------------------------------------------- */
/* COMMAND ORCHESTRATOR                                                        */
/* -------------------------------------------------------------------------- */

export async function runApprovalAwareCommand<T>(
  db:Db,
  access:ApprovalAwareAccessGate,
  ctx:CommandContext,
  actionKey:string,
  target:{type:string;id:UUID}|undefined,
  execute:(tx:DbTx,authorizationId?:UUID)=>Promise<{
    value:T;
    executedDomainEventId:UUID;
  }>
):Promise<CommandResult<T>>{
  return db.transaction(async tx=>{
    const gate=await access.evaluate(tx,ctx,actionKey,target);

    if(gate.state==="approval_required"){
      // IMPORTANT: return normally. Transaction commits the approval request.
      return {
        status:"approval_required",
        approvalRequestId:gate.approvalRequestId
      };
    }

    const executed=await execute(tx,gate.authorizationId);

    if(gate.authorizationId){
      // Same transaction as business mutation.
      // If execution throws, this never runs.
      // If consumption throws, whole mutation rolls back.
      await access.consumeAuthorization(
        tx,ctx,gate.authorizationId,executed.executedDomainEventId
      );
    }

    return {status:"executed",value:executed.value};
  });
}

/* -------------------------------------------------------------------------- */
/* APPROVAL DECISION                                                           */
/* -------------------------------------------------------------------------- */

export class ApprovalDecisionService {
  constructor(private d:{
    db:Db;ids:Ids;clock:Clock;sync:SyncQueue;events:DomainEvents;
  }){}

  async approve(
    ctx:CommandContext,
    approvalRequestId:UUID,
    note?:string
  ):Promise<{authorizationId:UUID}>{
    return this.d.db.transaction(async tx=>{
      const req=await tx.get<any>(
        `select id,business_id,state,action_type,target_type,target_id,
                requested_by_membership_id,requested_by_user_id
         from approval_requests
         where id=? and business_id=?`,
        [approvalRequestId,ctx.businessId]
      );
      if(!req)
        throw new AccessDenied("APPROVAL_REQUEST_NOT_FOUND","Request not found");
      if(req.state!=="pending")
        throw new AccessDenied("APPROVAL_NOT_PENDING","Request is not pending");

      const owner=await tx.get<{owner_user_id:UUID}>(
        `select owner_user_id from businesses where id=?`,
        [ctx.businessId]
      );
      const approverMembership=await tx.get<{id:UUID;membership_state:string}>(
        `select id,membership_state from staff_memberships
         where business_id=? and user_id=?`,
        [ctx.businessId,ctx.actorUserId]
      );

      const isOwner=owner?.owner_user_id===ctx.actorUserId;

      if(!isOwner){
        if(!approverMembership || approverMembership.membership_state!=="active")
          throw new AccessDenied("NOT_APPROVER","Approver is not active");

        const permission=await tx.get<{permission_state:PermissionState}>(
          `select permission_state
           from v_effective_staff_actions
           where membership_id=? and action_key='approve_requests'`,
          [approverMembership.id]
        );

        if(!permission || permission.permission_state!=="allowed")
          throw new AccessDenied("NOT_APPROVER","approve_requests permission required");
      }

      const authorizationId=this.d.ids.next();
      const decisionEventId=this.d.ids.next();
      const now=this.d.clock.now();

      await tx.run(
        `update approval_requests
         set state='approved',
             decided_by_user_id=?,
             decided_by_membership_id=?,
             decided_at=?
         where id=? and state='pending'`,
        [
          ctx.actorUserId,
          approverMembership?.id??null,
          ctx.occurredAt,
          approvalRequestId
        ]
      );

      await tx.run(
        `insert into approval_authorizations(
          id,approval_request_id,business_id,action_type,target_type,target_id,
          authorized_for_membership_id,authorized_for_user_id,
          approved_by_user_id,approved_by_membership_id,
          approved_at,created_at
        ) values (?,?,?,?,?,?,?,?,?,?,?,?)`,
        [
          authorizationId,approvalRequestId,ctx.businessId,
          req.action_type,req.target_type??null,req.target_id??null,
          req.requested_by_membership_id,req.requested_by_user_id,
          ctx.actorUserId,approverMembership?.id??null,
          ctx.occurredAt,now
        ]
      );

      await tx.run(
        `insert into approval_decision_events(
          id,business_id,approval_request_id,decision,
          decided_by_user_id,decided_by_membership_id,
          decided_at,note,created_at
        ) values (?,?,?,'approved',?,?,?,?,?)`,
        [
          decisionEventId,ctx.businessId,approvalRequestId,
          ctx.actorUserId,approverMembership?.id??null,
          ctx.occurredAt,note??null,now
        ]
      );

      await this.d.events.append(tx,{
        id:this.d.ids.next(),
        businessId:ctx.businessId,
        entityType:"approval_request",
        entityId:approvalRequestId,
        eventType:"approval_granted",
        occurredAt:ctx.occurredAt,
        recordedAt:now,
        recordedByUserId:ctx.actorUserId,
        deviceId:ctx.deviceId,
        payload:{
          authorizationId,
          approvedByUserId:ctx.actorUserId,
          approvedByMembershipId:approverMembership?.id??null
        }
      });

      await this.d.sync.enqueue(tx,{
        businessId:ctx.businessId,
        entityType:"approval_request",
        entityId:approvalRequestId,
        operation:"update",
        payload:{state:"approved"}
      });
      await this.d.sync.enqueue(tx,{
        businessId:ctx.businessId,
        entityType:"approval_authorization",
        entityId:authorizationId,
        operation:"insert",
        payload:{id:authorizationId},
        dependencyIds:[approvalRequestId]
      });

      // No underlying business action is executed here.
      return {authorizationId};
    });
  }
}
