/**
 * Khaata PG V1 — Backdated Accounting Sync Appliers v1
 *
 * Add these cases to RemoteChangeAppliers.
 * Opening positions/corrections are append-only on device as well.
 */

export interface DbTx {
  run(sql:string, params?:unknown[]):Promise<void>;
}
export interface RemoteChange {
  entityType:string;
  payload:Record<string,any>;
}

export class BackdatedAccountingRemoteAppliers {
  async apply(tx:DbTx,ch:RemoteChange):Promise<boolean>{
    switch(ch.entityType){
      case "tenancy_accounting_start":
        await this.accountingStart(tx,ch.payload);
        return true;
      case "opening_financial_position":
        await this.openingPosition(tx,ch.payload);
        return true;
      case "opening_position_correction":
        await this.openingCorrection(tx,ch.payload);
        return true;
      default:
        return false;
    }
  }

  private accountingStart(tx:DbTx,p:any){
    return tx.run(
      `insert or ignore into tenancy_accounting_starts(
        id,business_id,tenancy_id,accounting_path,accounting_start_date,
        created_at,created_by_user_id
      ) values (?,?,?,?,?,?,?)`,
      [
        p.id,p.business_id,p.tenancy_id,p.accounting_path,
        p.accounting_start_date,p.created_at,p.created_by_user_id??null
      ]
    );
  }

  private openingPosition(tx:DbTx,p:any){
    return tx.run(
      `insert or ignore into opening_financial_positions(
        id,business_id,tenancy_id,accounting_start_id,effective_date,
        opening_outstanding_minor,opening_tenant_credit_minor,
        opening_security_held_minor,note,created_at,created_by_user_id
      ) values (?,?,?,?,?,?,?,?,?,?,?)`,
      [
        p.id,p.business_id,p.tenancy_id,p.accounting_start_id,p.effective_date,
        p.opening_outstanding_minor,p.opening_tenant_credit_minor,
        p.opening_security_held_minor,p.note??null,p.created_at,
        p.created_by_user_id??null
      ]
    );
  }

  private openingCorrection(tx:DbTx,p:any){
    return tx.run(
      `insert or ignore into opening_position_corrections(
        id,opening_position_id,correction_type,amount_delta_minor,
        reason,occurred_at,created_at,created_by_user_id
      ) values (?,?,?,?,?,?,?,?)`,
      [
        p.id,p.opening_position_id,p.correction_type,p.amount_delta_minor,
        p.reason,p.occurred_at,p.created_at,p.created_by_user_id??null
      ]
    );
  }
}

/**
 * Typed RPC builders for the existing mobile outbox:
 */
export const BackdatedAccountingRpcBuilder = {
  startFromDate(input:any){
    return {
      rpcName:"pg_set_opening_financial_position",
      args:{
        p_business_id:input.businessId,
        p_device_id:input.deviceId,
        p_accounting_start_id:input.accountingStartId,
        p_opening_position_id:input.openingPositionId,
        p_domain_event_id:input.domainEventId,
        p_tenancy_id:input.tenancyId,
        p_accounting_start_date:input.accountingStartDate,
        p_opening_outstanding_minor:input.openingOutstandingMinor,
        p_opening_tenant_credit_minor:input.openingTenantCreditMinor,
        p_opening_security_held_minor:input.openingSecurityHeldMinor,
        p_note:input.note??null,
        p_approval_authorization_id:input.approvalAuthorizationId??null
      }
    };
  },

  bringExistingHistory(input:any){
    return {
      rpcName:"pg_choose_existing_history_path",
      args:{
        p_business_id:input.businessId,
        p_device_id:input.deviceId,
        p_accounting_start_id:input.accountingStartId,
        p_tenancy_id:input.tenancyId,
        p_historical_start_date:input.historicalStartDate,
        p_approval_authorization_id:input.approvalAuthorizationId??null
      }
    };
  },

  correctOpeningPosition(input:any){
    return {
      rpcName:"pg_correct_opening_financial_position",
      args:{
        p_business_id:input.businessId,
        p_device_id:input.deviceId,
        p_correction_id:input.correctionId,
        p_domain_event_id:input.domainEventId,
        p_opening_position_id:input.openingPositionId,
        p_correction_type:input.correctionType,
        p_amount_delta_minor:input.amountDeltaMinor,
        p_reason:input.reason,
        p_occurred_at:input.occurredAt,
        p_approval_authorization_id:input.approvalAuthorizationId??null
      }
    };
  }
};
