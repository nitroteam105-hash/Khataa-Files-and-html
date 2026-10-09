/**
 * Khaata PG / Hostel V1 — Mobile Remote Change Appliers v1
 * STATUS: PROPOSED IMPLEMENTATION.
 *
 * Replaces the placeholder SELECT 1 calls from the first PullCoordinator draft
 * with typed SQLite mappings.
 *
 * Immutable/history rows are INSERT OR IGNORE only.
 * Mutable rows are explicit typed UPSERTs.
 */

export type UUID = string;

export interface DbTx {
  run(sql:string, params?:unknown[]):Promise<void>;
  get<T>(sql:string, params?:unknown[]):Promise<T|undefined>;
}

export interface RemoteChange {
  remoteEventId:UUID;
  businessId:UUID;
  entityType:string;
  entityId:UUID;
  changeType:"insert"|"update"|"append_event"|"retire";
  serverVersion?:number;
  occurredAt?:string;
  payload:Record<string,any>;
}

export class RemoteChangeAppliers {
  async apply(tx:DbTx,ch:RemoteChange):Promise<void>{
    switch(ch.entityType){
      case "payment_event": return this.paymentEvent(tx,ch);
      case "payment_allocation": return this.paymentAllocation(tx,ch);
      case "receipt_snapshot": return this.receiptSnapshot(tx,ch);
      case "security_event": return this.securityEvent(tx,ch);
      case "cash_custody_event": return this.cashCustodyEvent(tx,ch);
      case "domain_event": return this.domainEvent(tx,ch);
      case "financial_adjustment": return this.financialAdjustment(tx,ch);

      case "business": return this.business(tx,ch);
      case "party": return this.party(tx,ch);
      case "payment_promise": return this.paymentPromise(tx,ch);
      case "expense": return this.expense(tx,ch);
      case "staff_membership": return this.staffMembership(tx,ch);
      case "tenant_requirement_policy": return this.requirementPolicy(tx,ch);
      case "tenant_requirement_item": return this.requirementItem(tx,ch);

      case "tenancy": return this.tenancy(tx,ch);
      case "occupancy_assignment": return this.occupancy(tx,ch);
      case "rent_term": return this.rentTerm(tx,ch);

      default: throw new Error(`NO_TYPED_REMOTE_APPLIER:${ch.entityType}`);
    }
  }

  private paymentEvent(tx:DbTx,ch:RemoteChange){
    const p=ch.payload;
    return tx.run(
      `insert or ignore into payment_events
       (id,business_id,tenancy_id,payer_party_id,event_type,original_payment_id,
        amount_minor,payment_method,occurred_at,recorded_by_user_id,metadata_json,created_at)
       values (?,?,?,?,?,?,?,?,?,?,?,?)`,
      [
        p.id,p.business_id,p.tenancy_id,p.payer_party_id??null,p.event_type,
        p.original_payment_id??null,p.amount_minor,p.payment_method??null,
        p.occurred_at,p.recorded_by_user_id??null,JSON.stringify(p.metadata??{}),p.created_at
      ]
    );
  }

  private paymentAllocation(tx:DbTx,ch:RemoteChange){
    const p=ch.payload;
    return tx.run(
      `insert or ignore into payment_allocations
       (id,payment_event_id,obligation_id,amount_minor,allocation_effect,created_at)
       values (?,?,?,?,?,?)`,
      [p.id,p.payment_event_id,p.obligation_id,p.amount_minor,p.allocation_effect,p.created_at]
    );
  }

  private receiptSnapshot(tx:DbTx,ch:RemoteChange){
    const p=ch.payload;
    return tx.run(
      `insert or ignore into receipt_snapshots
       (id,payment_event_id,receipt_number,snapshot_json,issued_at,created_at)
       values (?,?,?,?,?,?)`,
      [
        p.id,p.payment_event_id,p.receipt_number,
        JSON.stringify(p.snapshot??{}),p.issued_at,p.created_at
      ]
    );
  }

  private securityEvent(tx:DbTx,ch:RemoteChange){
    const p=ch.payload;
    return tx.run(
      `insert or ignore into security_events
       (id,security_account_id,event_type,amount_minor,obligation_id,occurred_at,reason,created_at)
       values (?,?,?,?,?,?,?,?)`,
      [
        p.id,p.security_account_id,p.event_type,p.amount_minor,p.obligation_id??null,
        p.occurred_at,p.reason??null,p.created_at
      ]
    );
  }

  private cashCustodyEvent(tx:DbTx,ch:RemoteChange){
    const p=ch.payload;
    return tx.run(
      `insert or ignore into cash_custody_events
       (id,business_id,event_type,payment_event_id,from_party_id,to_party_id,amount_minor,
        related_event_id,occurred_at,reason,recorded_by_user_id,created_at)
       values (?,?,?,?,?,?,?,?,?,?,?,?)`,
      [
        p.id,p.business_id,p.event_type,p.payment_event_id??null,p.from_party_id??null,
        p.to_party_id??null,p.amount_minor,p.related_event_id??null,p.occurred_at,
        p.reason??null,p.recorded_by_user_id??null,p.created_at
      ]
    );
  }

  private domainEvent(tx:DbTx,ch:RemoteChange){
    const p=ch.payload;
    return tx.run(
      `insert or ignore into domain_events
       (id,business_id,entity_type,entity_id,event_type,occurred_at,recorded_at,
        recorded_by_user_id,device_id,payload_json)
       values (?,?,?,?,?,?,?,?,?,?)`,
      [
        p.id,p.business_id,p.entity_type,p.entity_id,p.event_type,p.occurred_at,
        p.recorded_at,p.recorded_by_user_id??null,p.device_id??null,
        JSON.stringify(p.payload??{})
      ]
    );
  }

  private financialAdjustment(tx:DbTx,ch:RemoteChange){
    const p=ch.payload;
    return tx.run(
      `insert or ignore into financial_adjustments
       (id,business_id,tenancy_id,obligation_id,adjustment_type,amount_minor,reason,
        occurred_at,created_at)
       values (?,?,?,?,?,?,?,?,?)`,
      [
        p.id,p.business_id,p.tenancy_id,p.obligation_id??null,p.adjustment_type,
        p.amount_minor,p.reason??null,p.occurred_at,p.created_at
      ]
    );
  }

  private business(tx:DbTx,ch:RemoteChange){
    const p=ch.payload;
    return tx.run(
      `insert into businesses(id,owner_user_id,name,currency,timezone,jurisdiction,created_at,updated_at)
       values (?,?,?,?,?,?,?,?)
       on conflict(id) do update set
         name=excluded.name,currency=excluded.currency,timezone=excluded.timezone,
         jurisdiction=excluded.jurisdiction,updated_at=excluded.updated_at`,
      [p.id,p.owner_user_id,p.name,p.currency,p.timezone,p.jurisdiction,p.created_at,p.updated_at]
    );
  }

  private party(tx:DbTx,ch:RemoteChange){
    const p=ch.payload;
    return tx.run(
      `insert into parties(id,business_id,display_name,phone,email,created_at,updated_at)
       values (?,?,?,?,?,?,?)
       on conflict(id) do update set
         display_name=excluded.display_name,phone=excluded.phone,email=excluded.email,
         updated_at=excluded.updated_at`,
      [p.id,p.business_id,p.display_name,p.phone??null,p.email??null,p.created_at,p.updated_at]
    );
  }

  private paymentPromise(tx:DbTx,ch:RemoteChange){
    const p=ch.payload;
    return tx.run(
      `insert into payment_promises
       (id,business_id,tenancy_id,amount_minor,promised_date,status,note,created_at,updated_at)
       values (?,?,?,?,?,?,?,?,?)
       on conflict(id) do update set
         amount_minor=excluded.amount_minor,promised_date=excluded.promised_date,
         status=excluded.status,note=excluded.note,updated_at=excluded.updated_at`,
      [
        p.id,p.business_id,p.tenancy_id,p.amount_minor,p.promised_date,p.status,
        p.note??null,p.created_at,p.updated_at
      ]
    );
  }

  private expense(tx:DbTx,ch:RemoteChange){
    const p=ch.payload;
    return tx.run(
      `insert into expenses
       (id,business_id,amount_minor,category,paid_by_type,paid_by_party_id,payment_method,
        expense_date,vendor,property_context_id,reimbursement_state,created_at,updated_at)
       values (?,?,?,?,?,?,?,?,?,?,?,?,?)
       on conflict(id) do update set
         amount_minor=excluded.amount_minor,category=excluded.category,
         reimbursement_state=excluded.reimbursement_state,updated_at=excluded.updated_at`,
      [
        p.id,p.business_id,p.amount_minor,p.category,p.paid_by_type,p.paid_by_party_id??null,
        p.payment_method??null,p.expense_date,p.vendor??null,p.property_context_id??null,
        p.reimbursement_state,p.created_at,p.updated_at??p.created_at
      ]
    );
  }

  private staffMembership(tx:DbTx,ch:RemoteChange){
    const p=ch.payload;
    return tx.run(
      `insert into staff_memberships
       (id,business_id,user_id,party_id,role_name,membership_state,role_id,created_at,disabled_at)
       values (?,?,?,?,?,?,?,?,?)
       on conflict(id) do update set
         role_name=excluded.role_name,membership_state=excluded.membership_state,
         role_id=excluded.role_id,disabled_at=excluded.disabled_at`,
      [
        p.id,p.business_id,p.user_id,p.party_id??null,p.role_name,
        p.membership_state,p.role_id??null,p.created_at,p.disabled_at??null
      ]
    );
  }

  private requirementPolicy(tx:DbTx,ch:RemoteChange){
    const p=ch.payload;
    return tx.run(
      `insert into tenant_requirement_policies
       (id,business_id,requirement_key,label,policy_state,display_order,is_system_type,created_at,updated_at)
       values (?,?,?,?,?,?,?,?,?)
       on conflict(id) do update set
         label=excluded.label,policy_state=excluded.policy_state,
         display_order=excluded.display_order,updated_at=excluded.updated_at`,
      [
        p.id,p.business_id,p.requirement_key,p.label,p.policy_state,p.display_order??0,
        p.is_system_type??1,p.created_at,p.updated_at
      ]
    );
  }

  private requirementItem(tx:DbTx,ch:RemoteChange){
    const p=ch.payload;
    return tx.run(
      `insert into tenancy_requirement_items
       (id,business_id,tenancy_id,policy_id,status,value_text,document_ref,provided_at,
        provided_by_user_id,created_at,updated_at)
       values (?,?,?,?,?,?,?,?,?,?,?)
       on conflict(id) do update set
         status=excluded.status,value_text=excluded.value_text,document_ref=excluded.document_ref,
         provided_at=excluded.provided_at,provided_by_user_id=excluded.provided_by_user_id,
         updated_at=excluded.updated_at`,
      [
        p.id,p.business_id,p.tenancy_id,p.policy_id,p.status,p.value_text??null,
        p.document_ref??null,p.provided_at??null,p.provided_by_user_id??null,p.created_at,p.updated_at
      ]
    );
  }

  private tenancy(tx:DbTx,ch:RemoteChange){
    const p=ch.payload;
    return tx.run(
      `insert into tenancies
       (id,business_id,lifecycle_state,planned_join_date,planned_move_out_date,ended_at,created_at,updated_at)
       values (?,?,?,?,?,?,?,?)
       on conflict(id) do update set
         lifecycle_state=excluded.lifecycle_state,
         planned_join_date=excluded.planned_join_date,
         planned_move_out_date=excluded.planned_move_out_date,
         ended_at=excluded.ended_at,
         updated_at=excluded.updated_at`,
      [
        p.id,p.business_id,p.lifecycle_state,p.planned_join_date??null,
        p.planned_move_out_date??null,p.ended_at??null,p.created_at,p.updated_at
      ]
    );
  }

  private occupancy(tx:DbTx,ch:RemoteChange){
    const p=ch.payload;
    return tx.run(
      `insert into occupancy_assignments
       (id,tenancy_id,capacity_id,assignment_state,start_at,end_at,created_at)
       values (?,?,?,?,?,?,?)
       on conflict(id) do update set
         capacity_id=excluded.capacity_id,
         assignment_state=excluded.assignment_state,
         start_at=excluded.start_at,
         end_at=excluded.end_at`,
      [
        p.id,p.tenancy_id,p.capacity_id,p.assignment_state,p.start_at??null,p.end_at??null,p.created_at
      ]
    );
  }

  private rentTerm(tx:DbTx,ch:RemoteChange){
    const p=ch.payload;
    return tx.run(
      `insert into rent_terms
       (id,tenancy_id,amount_minor,billing_frequency,billing_timing,due_day,grace_days,
        valid_from,valid_to,created_at)
       values (?,?,?,?,?,?,?,?,?,?)
       on conflict(id) do update set
         amount_minor=excluded.amount_minor,billing_timing=excluded.billing_timing,
         due_day=excluded.due_day,grace_days=excluded.grace_days,
         valid_from=excluded.valid_from,valid_to=excluded.valid_to`,
      [
        p.id,p.tenancy_id,p.amount_minor,p.billing_frequency,p.billing_timing,p.due_day,
        p.grace_days,p.valid_from,p.valid_to??null,p.created_at
      ]
    );
  }
}

/**
 * PullCoordinator integration:
 *
 * replace placeholder applyAppendOnly/applyMutableEntity calls with:
 *
 *   await appliers.apply(tx, change)
 *
 * only AFTER the coordinator's semantic conflict checks have passed.
 *
 * This separation keeps:
 *   merge policy in PullCoordinator
 *   SQL serialization in RemoteChangeAppliers
 */
