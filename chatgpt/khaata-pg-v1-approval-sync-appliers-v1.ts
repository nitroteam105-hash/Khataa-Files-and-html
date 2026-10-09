/**
 * Khaata PG V1 — Approval Sync Appliers + RPC Builders v1
 */

export interface DbTx {
  run(sql:string, params?:unknown[]):Promise<void>;
}
export interface RemoteChange {
  entityType:string;
  payload:Record<string,any>;
}

export class ApprovalRemoteAppliers {
  async apply(tx:DbTx,ch:RemoteChange):Promise<boolean>{
    switch(ch.entityType){
      case "approval_request":
        await this.request(tx,ch.payload); return true;
      case "approval_authorization":
        await this.authorization(tx,ch.payload); return true;
      case "approval_decision_event":
        await this.decision(tx,ch.payload); return true;
      default:
        return false;
    }
  }

  private request(tx:DbTx,p:any){
    return tx.run(
      `insert into approval_requests(
        id,business_id,requested_by_membership_id,requested_by_user_id,
        action_type,target_type,target_id,request_payload_json,state,request_key,
        decided_by_membership_id,decided_by_user_id,decided_at,created_at
      ) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?)
      on conflict(id) do update set
        state=excluded.state,
        decided_by_membership_id=excluded.decided_by_membership_id,
        decided_by_user_id=excluded.decided_by_user_id,
        decided_at=excluded.decided_at`,
      [
        p.id,p.business_id,p.requested_by_membership_id??null,p.requested_by_user_id,
        p.action_type,p.target_type??null,p.target_id??null,
        JSON.stringify(p.request_payload??{}),p.state,p.request_key??null,
        p.decided_by_membership_id??null,p.decided_by_user_id??null,
        p.decided_at??null,p.created_at
      ]
    );
  }

  private authorization(tx:DbTx,p:any){
    return tx.run(
      `insert into approval_authorizations(
        id,approval_request_id,business_id,action_type,target_type,target_id,
        authorized_for_user_id,approved_by_user_id,approved_by_membership_id,
        approved_at,consumed_at,consumed_by_event_id,expires_at,created_at
      ) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?)
      on conflict(id) do update set
        consumed_at=excluded.consumed_at,
        consumed_by_event_id=excluded.consumed_by_event_id`,
      [
        p.id,p.approval_request_id,p.business_id,p.action_type,
        p.target_type??null,p.target_id??null,p.authorized_for_user_id,
        p.approved_by_user_id,p.approved_by_membership_id??null,
        p.approved_at,p.consumed_at??null,p.consumed_by_event_id??null,
        p.expires_at??null,p.created_at
      ]
    );
  }

  private decision(tx:DbTx,p:any){
    return tx.run(
      `insert or ignore into approval_decision_events(
        id,business_id,approval_request_id,decision,decided_by_user_id,
        decided_by_membership_id,decided_at,note,created_at
      ) values (?,?,?,?,?,?,?,?,?)`,
      [
        p.id,p.business_id,p.approval_request_id,p.decision,p.decided_by_user_id,
        p.decided_by_membership_id??null,p.decided_at,p.note??null,p.created_at
      ]
    );
  }
}

export const ApprovalRpcBuilder = {
  request(input:any){
    return {
      rpcName:"pg_request_approval",
      args:{
        p_business_id:input.businessId,
        p_device_id:input.deviceId,
        p_approval_request_id:input.approvalRequestId,
        p_request_key:input.requestKey,
        p_action_type:input.actionType,
        p_target_type:input.targetType??null,
        p_target_id:input.targetId??null,
        p_request_payload:input.requestPayload??{}
      }
    };
  },

  approve(input:any){
    return {
      rpcName:"pg_approve_request",
      args:{
        p_business_id:input.businessId,
        p_device_id:input.deviceId,
        p_approval_request_id:input.approvalRequestId,
        p_authorization_id:input.authorizationId,
        p_decision_event_id:input.decisionEventId,
        p_expires_at:input.expiresAt??null,
        p_note:input.note??null
      }
    };
  },

  decline(input:any){
    return {
      rpcName:"pg_decline_request",
      args:{
        p_business_id:input.businessId,
        p_device_id:input.deviceId,
        p_approval_request_id:input.approvalRequestId,
        p_decision_event_id:input.decisionEventId,
        p_note:input.note??null
      }
    };
  }
};

/**
 * Protected action execution remains separate:
 *
 * 1. requester gets approval_required
 * 2. approver executes pg_approve_request
 * 3. requester/device receives approval_authorization via pull
 * 4. original protected command is retried with p_approval_authorization_id
 * 5. domain mutation and authorization consumption happen in the SAME transaction
 */
