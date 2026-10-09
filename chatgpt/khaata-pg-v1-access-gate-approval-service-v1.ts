/**
 * Khaata PG V1 — AccessGate + Approval Execution Service v1
 * STATUS: PROPOSED IMPLEMENTATION CONTRACT.
 *
 * Product invariants:
 * - Allowed / Needs approval / Not allowed.
 * - Visibility is separate from action authority.
 * - Approval never means the underlying action already happened.
 * - Missing-requirement override is an authority rule under Staff & Access.
 * - Disabled staff retain historical attribution but cannot perform new actions.
 */

export type UUID = string;
export type ISODateTime = string;

export interface DbTx {
  run(sql:string, params?:unknown[]):Promise<void>;
  get<T>(sql:string, params?:unknown[]):Promise<T|undefined>;
  all<T>(sql:string, params?:unknown[]):Promise<T[]>;
}
export interface Db { transaction<T>(fn:(tx:DbTx)=>Promise<T>):Promise<T>; }
export interface Ids { next():UUID; }
export interface Clock { now():ISODateTime; }
export interface Outbox {
  enqueue(tx:DbTx,item:{
    id:UUID; businessId:UUID; aggregateType:string; aggregateId:UUID;
    operation:"insert"|"update"|"append_event"; payload:unknown;
    dependencyIds?:UUID[]; createdAt:ISODateTime;
  }):Promise<void>;
}
export interface DomainEvents {
  append(tx:DbTx,event:{
    id:UUID; businessId:UUID; entityType:string; entityId:UUID; eventType:string;
    occurredAt:ISODateTime; recordedAt:ISODateTime; recordedByUserId:UUID; deviceId:UUID;
    payload:unknown;
  }):Promise<void>;
}

export interface CommandContext {
  businessId:UUID;
  actorUserId:UUID;
  deviceId:UUID;
  occurredAt:ISODateTime;
  approvalAuthorizationId?:UUID;
}

export class AccessDenied extends Error {
  constructor(public code:string, message:string){ super(message); }
}

export type AccessDecision =
  | {state:"allowed"; membershipId:UUID; authorizationId?:UUID}
  | {state:"needs_approval"; membershipId:UUID; approvalRequestId:UUID};

export class AccessGate {
  constructor(private deps:{ids:Ids;clock:Clock;outbox:Outbox;events:DomainEvents}){}

  async requireAction(
    tx:DbTx,
    ctx:CommandContext,
    actionKey:string,
    target?:{type:string;id:UUID}
  ):Promise<AccessDecision>{
    const membership=await tx.get<{id:UUID;membership_state:string;role_name:string}>(
      `select id,membership_state,role_name
       from staff_memberships
       where business_id=? and user_id=?`,
      [ctx.businessId,ctx.actorUserId]
    );

    // Owner-only operation is valid. In a production composition root, the owner
    // account should normally also have a membership. This fallback avoids making
    // staff setup mandatory for a sole owner.
    if(!membership){
      const owner=await tx.get<{owner_user_id:UUID}>(
        `select owner_user_id from businesses where id=?`,
        [ctx.businessId]
      );
      if(owner?.owner_user_id===ctx.actorUserId){
        return {state:"allowed",membershipId:`owner:${ctx.actorUserId}`};
      }
      throw new AccessDenied("NO_BUSINESS_ACCESS","User has no active business access");
    }

    if(membership.membership_state!=="active"){
      throw new AccessDenied("MEMBERSHIP_DISABLED","Staff membership is not active");
    }

    const scope=await tx.get<{access_state:string}>(
      `select access_state
       from staff_property_scopes
       where membership_id=? and business_id=?
         and valid_from<=?
         and (valid_to is null or valid_to>?)
       order by valid_from desc limit 1`,
      [membership.id,ctx.businessId,ctx.occurredAt,ctx.occurredAt]
    );
    if(scope && scope.access_state!=="allowed"){
      throw new AccessDenied("PROPERTY_ACCESS_BLOCKED","Staff member has no access to this business/property");
    }

    const permission=await tx.get<{permission_state:"allowed"|"needs_approval"|"not_allowed"}>(
      `select permission_state
       from v_effective_staff_actions
       where membership_id=? and action_key=?`,
      [membership.id,actionKey]
    );

    if(!permission || permission.permission_state==="not_allowed"){
      throw new AccessDenied("ACTION_NOT_ALLOWED",`${actionKey} is not allowed for this role`);
    }

    if(permission.permission_state==="allowed"){
      return {state:"allowed",membershipId:membership.id};
    }

    // Needs approval. A supplied authorization can be consumed only by the
    // command that performs the actual mutation.
    if(ctx.approvalAuthorizationId){
      const auth=await tx.get<{
        id:UUID;action_type:string;target_type?:string;target_id?:UUID;
        consumed_at?:string;expires_at?:string;authorized_for_membership_id:UUID;
      }>(
        `select id,action_type,target_type,target_id,consumed_at,expires_at,authorized_for_membership_id
         from approval_authorizations where id=? and business_id=?`,
        [ctx.approvalAuthorizationId,ctx.businessId]
      );
      if(!auth) throw new AccessDenied("APPROVAL_NOT_FOUND","Approval authorization not found");
      if(auth.authorized_for_membership_id!==membership.id) {
        throw new AccessDenied("APPROVAL_WRONG_ACTOR","Approval was issued for another staff member");
      }
      if(auth.action_type!==actionKey) {
        throw new AccessDenied("APPROVAL_WRONG_ACTION","Approval does not authorize this action");
      }
      if(auth.consumed_at) throw new AccessDenied("APPROVAL_ALREADY_USED","Approval has already been consumed");
      if(auth.expires_at && auth.expires_at<=ctx.occurredAt) {
        throw new AccessDenied("APPROVAL_EXPIRED","Approval authorization has expired");
      }
      if(target?.type && auth.target_type && auth.target_type!==target.type) {
        throw new AccessDenied("APPROVAL_WRONG_TARGET","Approval target type mismatch");
      }
      if(target?.id && auth.target_id && auth.target_id!==target.id) {
        throw new AccessDenied("APPROVAL_WRONG_TARGET","Approval target mismatch");
      }
      return {state:"allowed",membershipId:membership.id,authorizationId:auth.id};
    }

    const approvalRequestId=this.deps.ids.next();
    const now=this.deps.clock.now();
    await tx.run(
      `insert into approval_requests
       (id,business_id,requested_by_membership_id,action_type,target_type,target_id,
        request_payload_json,state,created_at,sync_status)
       values (?,?,?,?,?,?,?,'pending',?,'pending')`,
      [
        approvalRequestId,ctx.businessId,membership.id,actionKey,target?.type??null,target?.id??null,
        JSON.stringify({source:"access_gate"}),now
      ]
    );

    await this.deps.events.append(tx,{
      id:this.deps.ids.next(),businessId:ctx.businessId,entityType:"approval_request",
      entityId:approvalRequestId,eventType:"approval_requested",occurredAt:ctx.occurredAt,
      recordedAt:now,recordedByUserId:ctx.actorUserId,deviceId:ctx.deviceId,
      payload:{actionKey,target:target??null}
    });

    await this.deps.outbox.enqueue(tx,{
      id:this.deps.ids.next(),businessId:ctx.businessId,aggregateType:"approval_request",
      aggregateId:approvalRequestId,operation:"insert",payload:{id:approvalRequestId},
      createdAt:now
    });

    return {state:"needs_approval",membershipId:membership.id,approvalRequestId};
  }

  async requireProceedWithMissingRequirements(
    tx:DbTx,
    ctx:CommandContext,
    tenancyId:UUID
  ):Promise<AccessDecision>{
    const status=await tx.get<{setup_incomplete:number}>(
      `select setup_incomplete from v_tenancy_requirement_status where tenancy_id=?`,
      [tenancyId]
    );
    if(!status || status.setup_incomplete===0){
      // No missing required data -> no extra permission gate.
      const membership=await tx.get<{id:UUID}>(
        `select id from staff_memberships where business_id=? and user_id=?`,
        [ctx.businessId,ctx.actorUserId]
      );
      return {state:"allowed",membershipId:membership?.id??`owner:${ctx.actorUserId}`};
    }

    return this.requireAction(
      tx,ctx,"proceed_with_missing_requirements",
      {type:"tenancy",id:tenancyId}
    );
  }

  async consumeAuthorization(
    tx:DbTx,
    ctx:CommandContext,
    authorizationId:UUID,
    executedDomainEventId:UUID
  ):Promise<void>{
    const row=await tx.get<{consumed_at?:string}>(
      `select consumed_at from approval_authorizations where id=? and business_id=?`,
      [authorizationId,ctx.businessId]
    );
    if(!row) throw new AccessDenied("APPROVAL_NOT_FOUND","Approval authorization not found");
    if(row.consumed_at) throw new AccessDenied("APPROVAL_ALREADY_USED","Approval already consumed");

    await tx.run(
      `update approval_authorizations
       set consumed_at=?,consumed_by_event_id=?,sync_status='pending'
       where id=?`,
      [ctx.occurredAt,executedDomainEventId,authorizationId]
    );

    await this.deps.outbox.enqueue(tx,{
      id:this.deps.ids.next(),businessId:ctx.businessId,aggregateType:"approval_authorization",
      aggregateId:authorizationId,operation:"update",
      payload:{consumed_at:ctx.occurredAt,consumed_by_event_id:executedDomainEventId},
      createdAt:this.deps.clock.now()
    });
  }
}

export class ApprovalService {
  constructor(private deps:{db:Db;ids:Ids;clock:Clock;outbox:Outbox;events:DomainEvents}){}

  async approve(
    ctx:CommandContext,
    approvalRequestId:UUID
  ):Promise<{authorizationId:UUID}>{
    return this.deps.db.transaction(async tx=>{
      const request=await tx.get<{
        id:UUID;state:string;action_type:string;target_type?:string;target_id?:UUID;
        requested_by_membership_id:UUID;
      }>(
        `select id,state,action_type,target_type,target_id,requested_by_membership_id
         from approval_requests where id=? and business_id=?`,
        [approvalRequestId,ctx.businessId]
      );
      if(!request) throw new AccessDenied("APPROVAL_REQUEST_NOT_FOUND","Approval request not found");
      if(request.state!=="pending") throw new AccessDenied("APPROVAL_NOT_PENDING","Approval request is not pending");

      const approver=await tx.get<{id:UUID}>(
        `select id from staff_memberships
         where business_id=? and user_id=? and membership_state='active'`,
        [ctx.businessId,ctx.actorUserId]
      );
      if(!approver){
        const owner=await tx.get<{owner_user_id:UUID}>(
          `select owner_user_id from businesses where id=?`,
          [ctx.businessId]
        );
        if(owner?.owner_user_id!==ctx.actorUserId){
          throw new AccessDenied("NOT_APPROVER","Actor cannot approve this request");
        }
      }

      const authorizationId=this.deps.ids.next();
      const now=this.deps.clock.now();

      await tx.run(
        `update approval_requests
         set state='approved',decided_by_membership_id=?,decided_at=?,sync_status='pending'
         where id=?`,
        [approver?.id??null,ctx.occurredAt,approvalRequestId]
      );

      await tx.run(
        `insert into approval_authorizations
         (id,approval_request_id,business_id,action_type,target_type,target_id,
          authorized_for_membership_id,approved_by_membership_id,approved_at,
          created_at,sync_status)
         values (?,?,?,?,?,?,?,?,?,?,'pending')`,
        [
          authorizationId,approvalRequestId,ctx.businessId,request.action_type,
          request.target_type??null,request.target_id??null,request.requested_by_membership_id,
          approver?.id??request.requested_by_membership_id,ctx.occurredAt,now
        ]
      );

      const eventId=this.deps.ids.next();
      await this.deps.events.append(tx,{
        id:eventId,businessId:ctx.businessId,entityType:"approval_request",
        entityId:approvalRequestId,eventType:"approval_granted",occurredAt:ctx.occurredAt,
        recordedAt:now,recordedByUserId:ctx.actorUserId,deviceId:ctx.deviceId,
        payload:{authorizationId}
      });

      await this.deps.outbox.enqueue(tx,{
        id:this.deps.ids.next(),businessId:ctx.businessId,aggregateType:"approval_request",
        aggregateId:approvalRequestId,operation:"update",payload:{state:"approved"},
        createdAt:now
      });
      await this.deps.outbox.enqueue(tx,{
        id:this.deps.ids.next(),businessId:ctx.businessId,aggregateType:"approval_authorization",
        aggregateId:authorizationId,operation:"insert",payload:{id:authorizationId},
        dependencyIds:[approvalRequestId],createdAt:now
      });

      // IMPORTANT: no underlying domain action is executed here.
      return {authorizationId};
    });
  }
}

/**
 * COMMAND INTEGRATION PATTERN
 *
 * const decision = await access.requireAction(tx, ctx, "refund_security", target);
 * if (decision.state === "needs_approval") {
 *   throw new DomainError("APPROVAL_REQUIRED", decision.approvalRequestId);
 * }
 *
 * const domainEventId = ids.next();
 * ... perform actual mutation ...
 * ... append domain event using domainEventId ...
 *
 * if (decision.authorizationId) {
 *   await access.consumeAuthorization(tx, ctx, decision.authorizationId, domainEventId);
 * }
 *
 * For tenant creation / joining where required info may be missing:
 *
 * 1) perform the base action permission check;
 * 2) check requirement status;
 * 3) if incomplete, call requireProceedWithMissingRequirements(...);
 * 4) if that returns needs_approval, DO NOT mutate tenancy/occupancy;
 * 5) approved authorization is later consumed by the actual command transaction.
 */
