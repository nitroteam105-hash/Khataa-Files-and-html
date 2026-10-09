-- Khaata PG / Hostel V1 — Supabase Typed Domain RPCs v1
-- STATUS: PROPOSED IMPLEMENTATION MIGRATION. DO NOT APPLY WITHOUT REVIEW.
--
-- Builds on:
--   khaata-pg-v1-supabase-schema-proposal-v1.sql
--   khaata-pg-v1-supabase-rls-sync-server-v1.sql
--
-- High-risk operations implemented as typed server functions:
--   1. record payment
--   2. reverse payment
--   3. room transfer
--   4. apply security to dues
--   5. refund security
--   6. cash handover + discrepancy
--   7. end tenancy
--
-- Core rule:
--   The client sends final offline-generated IDs.
--   The server re-validates business invariants and permissions.
--   The same operation_id is idempotent.
--
-- IMPORTANT:
--   This migration does not finalize the cryptographic proof mechanism for
--   post-entitlement drain-only uploads. ENT-30 requires those uploads to drain;
--   exact anti-tamper proof remains an implementation/security choice.

begin;

-- ============================================================================
-- 1. SERVER APPROVAL AUTHORIZATIONS
-- ============================================================================

create table if not exists public.approval_authorizations (
  id uuid primary key default gen_random_uuid(),
  approval_request_id uuid not null unique
    references public.approval_requests(id) on delete restrict,
  business_id uuid not null references public.businesses(id) on delete restrict,
  action_type text not null,
  target_type text,
  target_id uuid,
  authorized_for_user_id uuid not null,
  approved_by_user_id uuid not null,
  approved_at timestamptz not null,
  consumed_at timestamptz,
  consumed_by_event_id uuid references public.domain_events(id) on delete restrict,
  expires_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists idx_approval_authorizations_available
  on public.approval_authorizations(
    business_id, authorized_for_user_id, action_type, consumed_at, expires_at
  );

-- ============================================================================
-- 2. COMMON HELPERS
-- ============================================================================

create or replace function public.pg_get_prior_sync_result(p_operation_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select result_payload
  from public.sync_operations
  where operation_id = p_operation_id
  limit 1;
$$;

create or replace function public.pg_register_sync_result(
  p_operation_id uuid,
  p_business_id uuid,
  p_device_id uuid,
  p_aggregate_type text,
  p_aggregate_id uuid,
  p_operation_type text,
  p_state text,
  p_result jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.sync_operations(
    operation_id,business_id,actor_user_id,device_id,aggregate_type,
    aggregate_id,operation_type,result_state,result_payload
  ) values (
    p_operation_id,p_business_id,auth.uid(),p_device_id,p_aggregate_type,
    p_aggregate_id,p_operation_type,p_state,p_result
  )
  on conflict (operation_id) do nothing;
end;
$$;

create or replace function public.pg_assert_action_authorized(
  p_business_id uuid,
  p_action_key text,
  p_target_type text default null,
  p_target_id uuid default null,
  p_approval_authorization_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  permission text;
  authz public.approval_authorizations%rowtype;
begin
  if not public.has_business_access(p_business_id) then
    raise exception 'BUSINESS_ACCESS_DENIED';
  end if;

  permission := public.current_action_permission(p_business_id,p_action_key);

  if permission='not_allowed' then
    raise exception 'ACTION_NOT_ALLOWED';
  end if;

  if permission='allowed' then
    return null;
  end if;

  if p_approval_authorization_id is null then
    raise exception 'APPROVAL_REQUIRED';
  end if;

  select * into authz
  from public.approval_authorizations
  where id=p_approval_authorization_id
    and business_id=p_business_id
    and authorized_for_user_id=auth.uid();

  if not found then raise exception 'APPROVAL_NOT_FOUND'; end if;
  if authz.action_type<>p_action_key then raise exception 'APPROVAL_WRONG_ACTION'; end if;
  if authz.consumed_at is not null then raise exception 'APPROVAL_ALREADY_USED'; end if;
  if authz.expires_at is not null and authz.expires_at<=now() then
    raise exception 'APPROVAL_EXPIRED';
  end if;
  if authz.target_type is not null and p_target_type is not null
     and authz.target_type<>p_target_type then
    raise exception 'APPROVAL_WRONG_TARGET';
  end if;
  if authz.target_id is not null and p_target_id is not null
     and authz.target_id<>p_target_id then
    raise exception 'APPROVAL_WRONG_TARGET';
  end if;

  return authz.id;
end;
$$;

create or replace function public.pg_consume_authorization(
  p_authorization_id uuid,
  p_domain_event_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_authorization_id is null then return; end if;

  update public.approval_authorizations
  set consumed_at=now(),
      consumed_by_event_id=p_domain_event_id
  where id=p_authorization_id
    and consumed_at is null;

  if not found then
    raise exception 'APPROVAL_ALREADY_USED_OR_MISSING';
  end if;
end;
$$;

create or replace function public.pg_append_domain_event(
  p_event_id uuid,
  p_business_id uuid,
  p_entity_type text,
  p_entity_id uuid,
  p_event_type text,
  p_occurred_at timestamptz,
  p_device_id uuid,
  p_payload jsonb
)
returns void
language sql
security definer
set search_path = public
as $$
  insert into public.domain_events(
    id,business_id,entity_type,entity_id,event_type,occurred_at,
    recorded_at,recorded_by_user_id,device_id,payload
  ) values (
    p_event_id,p_business_id,p_entity_type,p_entity_id,p_event_type,p_occurred_at,
    now(),auth.uid(),p_device_id,coalesce(p_payload,'{}'::jsonb)
  );
$$;

-- ============================================================================
-- 3. RECORD PAYMENT
-- ============================================================================

create or replace function public.pg_record_payment(
  p_operation_id uuid,
  p_business_id uuid,
  p_device_id uuid,
  p_payment_id uuid,
  p_receipt_id uuid,
  p_domain_event_id uuid,
  p_tenancy_id uuid,
  p_payer_party_id uuid,
  p_amount_minor bigint,
  p_payment_method text,
  p_occurred_at timestamptz,
  p_allocations jsonb,
  p_cash_custody_event_id uuid default null,
  p_cash_custodian_party_id uuid default null,
  p_approval_authorization_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  prior jsonb;
  authz_id uuid;
  alloc jsonb;
  total_allocated bigint := 0;
  obligation_row public.obligations%rowtype;
  result jsonb;
begin
  prior := public.pg_get_prior_sync_result(p_operation_id);
  if prior is not null then return prior; end if;

  authz_id := public.pg_assert_action_authorized(
    p_business_id,'record_payment','tenancy',p_tenancy_id,p_approval_authorization_id
  );

  if p_amount_minor<=0 then raise exception 'INVALID_AMOUNT'; end if;

  if not exists (
    select 1 from public.tenancies
    where id=p_tenancy_id and business_id=p_business_id
  ) then raise exception 'TENANCY_NOT_FOUND'; end if;

  for alloc in select * from jsonb_array_elements(coalesce(p_allocations,'[]'::jsonb))
  loop
    if (alloc->>'amount_minor')::bigint<=0 then raise exception 'INVALID_ALLOCATION'; end if;

    select * into obligation_row
    from public.obligations
    where id=(alloc->>'obligation_id')::uuid
      and tenancy_id=p_tenancy_id
      and business_id=p_business_id;

    if not found then raise exception 'OBLIGATION_NOT_FOUND'; end if;

    total_allocated := total_allocated + (alloc->>'amount_minor')::bigint;
  end loop;

  if total_allocated>p_amount_minor then
    raise exception 'OVER_ALLOCATED_PAYMENT';
  end if;

  insert into public.payment_events(
    id,business_id,tenancy_id,payer_party_id,event_type,amount_minor,
    payment_method,occurred_at,recorded_by_user_id,metadata,created_at
  ) values (
    p_payment_id,p_business_id,p_tenancy_id,p_payer_party_id,'payment',p_amount_minor,
    p_payment_method,p_occurred_at,auth.uid(),'{}'::jsonb,now()
  );

  for alloc in select * from jsonb_array_elements(coalesce(p_allocations,'[]'::jsonb))
  loop
    insert into public.payment_allocations(
      id,payment_event_id,obligation_id,amount_minor,allocation_effect,created_at
    ) values (
      (alloc->>'allocation_id')::uuid,
      p_payment_id,
      (alloc->>'obligation_id')::uuid,
      (alloc->>'amount_minor')::bigint,
      1,
      now()
    );
  end loop;

  insert into public.receipt_snapshots(
    id,payment_event_id,receipt_number,snapshot,issued_at,created_at
  ) values (
    p_receipt_id,p_payment_id,
    'SYNC-'||left(p_receipt_id::text,8),
    jsonb_build_object(
      'paymentId',p_payment_id,
      'tenancyId',p_tenancy_id,
      'amountMinor',p_amount_minor,
      'method',p_payment_method,
      'allocations',coalesce(p_allocations,'[]'::jsonb),
      'issuedAt',p_occurred_at
    ),
    p_occurred_at,now()
  );

  if p_cash_custody_event_id is not null then
    if p_cash_custodian_party_id is null then
      raise exception 'CASH_CUSTODIAN_REQUIRED';
    end if;

    insert into public.cash_custody_events(
      id,business_id,event_type,payment_event_id,to_party_id,amount_minor,
      occurred_at,recorded_by_user_id,created_at
    ) values (
      p_cash_custody_event_id,p_business_id,'collection_received',p_payment_id,
      p_cash_custodian_party_id,p_amount_minor,p_occurred_at,auth.uid(),now()
    );
  end if;

  perform public.pg_append_domain_event(
    p_domain_event_id,p_business_id,'payment',p_payment_id,'payment_recorded',
    p_occurred_at,p_device_id,
    jsonb_build_object(
      'tenancyId',p_tenancy_id,
      'amountMinor',p_amount_minor,
      'receiptId',p_receipt_id,
      'cashCustodyEventId',p_cash_custody_event_id
    )
  );

  perform public.pg_consume_authorization(authz_id,p_domain_event_id);

  result := jsonb_build_object(
    'state','accepted',
    'payment_id',p_payment_id,
    'receipt_id',p_receipt_id
  );

  perform public.pg_register_sync_result(
    p_operation_id,p_business_id,p_device_id,'payment_event',p_payment_id,
    'record_payment','accepted',result
  );
  return result;
end;
$$;

-- ============================================================================
-- 4. REVERSE PAYMENT
-- ============================================================================

create or replace function public.pg_reverse_payment(
  p_operation_id uuid,
  p_business_id uuid,
  p_device_id uuid,
  p_reversal_payment_id uuid,
  p_domain_event_id uuid,
  p_original_payment_id uuid,
  p_reason text,
  p_occurred_at timestamptz,
  p_allocation_reversal_ids jsonb,
  p_approval_authorization_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  prior jsonb;
  authz_id uuid;
  original public.payment_events%rowtype;
  a record;
  idx integer := 0;
  reversal_alloc_id uuid;
  result jsonb;
begin
  prior := public.pg_get_prior_sync_result(p_operation_id);
  if prior is not null then return prior; end if;

  authz_id := public.pg_assert_action_authorized(
    p_business_id,'reverse_payment','payment',p_original_payment_id,p_approval_authorization_id
  );

  if coalesce(trim(p_reason),'')='' then raise exception 'REASON_REQUIRED'; end if;

  select * into original
  from public.payment_events
  where id=p_original_payment_id
    and business_id=p_business_id
    and event_type='payment';

  if not found then raise exception 'ORIGINAL_PAYMENT_NOT_FOUND'; end if;

  if exists (
    select 1 from public.payment_events
    where original_payment_id=p_original_payment_id
      and event_type in ('reversal','chargeback')
  ) then raise exception 'PAYMENT_ALREADY_REVERSED'; end if;

  insert into public.payment_events(
    id,business_id,tenancy_id,event_type,original_payment_id,amount_minor,
    occurred_at,recorded_by_user_id,metadata,created_at
  ) values (
    p_reversal_payment_id,p_business_id,original.tenancy_id,'reversal',
    p_original_payment_id,original.amount_minor,p_occurred_at,auth.uid(),
    jsonb_build_object('reason',p_reason),now()
  );

  for a in
    select obligation_id,amount_minor
    from public.payment_allocations
    where payment_event_id=p_original_payment_id
      and allocation_effect=1
    order by id
  loop
    reversal_alloc_id := (p_allocation_reversal_ids->>idx)::uuid;
    if reversal_alloc_id is null then raise exception 'REVERSAL_ALLOCATION_ID_REQUIRED'; end if;

    insert into public.payment_allocations(
      id,payment_event_id,obligation_id,amount_minor,allocation_effect,created_at
    ) values (
      reversal_alloc_id,p_reversal_payment_id,a.obligation_id,a.amount_minor,-1,now()
    );
    idx := idx+1;
  end loop;

  perform public.pg_append_domain_event(
    p_domain_event_id,p_business_id,'payment',p_reversal_payment_id,'payment_reversed',
    p_occurred_at,p_device_id,
    jsonb_build_object('originalPaymentId',p_original_payment_id,'reason',p_reason)
  );

  perform public.pg_consume_authorization(authz_id,p_domain_event_id);

  result := jsonb_build_object(
    'state','accepted','reversal_payment_id',p_reversal_payment_id
  );

  perform public.pg_register_sync_result(
    p_operation_id,p_business_id,p_device_id,'payment_event',p_reversal_payment_id,
    'reverse_payment','accepted',result
  );
  return result;
end;
$$;

-- ============================================================================
-- 5. ROOM TRANSFER
-- ============================================================================

create or replace function public.pg_transfer_room(
  p_operation_id uuid,
  p_business_id uuid,
  p_device_id uuid,
  p_tenancy_id uuid,
  p_old_occupancy_id uuid,
  p_new_occupancy_id uuid,
  p_new_capacity_id uuid,
  p_domain_event_id uuid,
  p_effective_at timestamptz,
  p_approval_authorization_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  prior jsonb;
  authz_id uuid;
  result jsonb;
begin
  prior := public.pg_get_prior_sync_result(p_operation_id);
  if prior is not null then return prior; end if;

  authz_id := public.pg_assert_action_authorized(
    p_business_id,'transfer_room','tenancy',p_tenancy_id,p_approval_authorization_id
  );

  if not exists (
    select 1 from public.occupancy_assignments oa
    join public.tenancies t on t.id=oa.tenancy_id
    where oa.id=p_old_occupancy_id
      and oa.tenancy_id=p_tenancy_id
      and oa.assignment_state='active'
      and t.business_id=p_business_id
  ) then raise exception 'NO_ACTIVE_OCCUPANCY'; end if;

  if not exists (
    select 1 from public.property_nodes
    where id=p_new_capacity_id
      and business_id=p_business_id
      and node_type='bed'
      and lifecycle_state='available'
  ) then raise exception 'CAPACITY_UNAVAILABLE'; end if;

  if exists (
    select 1 from public.occupancy_assignments
    where capacity_id=p_new_capacity_id
      and assignment_state='active'
  ) then raise exception 'BED_CONFLICT'; end if;

  update public.occupancy_assignments
  set assignment_state='ended',end_at=p_effective_at
  where id=p_old_occupancy_id;

  insert into public.occupancy_assignments(
    id,tenancy_id,capacity_id,assignment_state,start_at,created_at
  ) values (
    p_new_occupancy_id,p_tenancy_id,p_new_capacity_id,'active',p_effective_at,now()
  );

  perform public.pg_append_domain_event(
    p_domain_event_id,p_business_id,'tenancy',p_tenancy_id,'room_transferred',
    p_effective_at,p_device_id,
    jsonb_build_object(
      'previousOccupancyAssignmentId',p_old_occupancy_id,
      'newOccupancyAssignmentId',p_new_occupancy_id,
      'newCapacityId',p_new_capacity_id
    )
  );

  -- Deliberately no rent_terms update.
  perform public.pg_consume_authorization(authz_id,p_domain_event_id);

  result := jsonb_build_object(
    'state','accepted','new_occupancy_id',p_new_occupancy_id
  );
  perform public.pg_register_sync_result(
    p_operation_id,p_business_id,p_device_id,'occupancy_assignment',p_new_occupancy_id,
    'transfer_room','accepted',result
  );
  return result;
end;
$$;

-- ============================================================================
-- 6. APPLY SECURITY TO DUES
-- ============================================================================

create or replace function public.pg_apply_security_to_dues(
  p_operation_id uuid,
  p_business_id uuid,
  p_device_id uuid,
  p_security_event_id uuid,
  p_domain_event_id uuid,
  p_tenancy_id uuid,
  p_obligation_id uuid,
  p_amount_minor bigint,
  p_reason text,
  p_occurred_at timestamptz,
  p_approval_authorization_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  prior jsonb;
  authz_id uuid;
  security_account_id uuid;
  held bigint;
  outstanding bigint;
  result jsonb;
begin
  prior := public.pg_get_prior_sync_result(p_operation_id);
  if prior is not null then return prior; end if;

  authz_id := public.pg_assert_action_authorized(
    p_business_id,'apply_security_to_dues','tenancy',p_tenancy_id,p_approval_authorization_id
  );

  if p_amount_minor<=0 then raise exception 'INVALID_AMOUNT'; end if;

  select sa.id,vsb.held_amount_minor
  into security_account_id,held
  from public.security_accounts sa
  join public.v_security_balances vsb on vsb.security_account_id=sa.id
  join public.tenancies t on t.id=sa.tenancy_id
  where sa.tenancy_id=p_tenancy_id and t.business_id=p_business_id;

  if security_account_id is null then raise exception 'SECURITY_ACCOUNT_NOT_FOUND'; end if;
  if held<p_amount_minor then raise exception 'INSUFFICIENT_SECURITY_HELD'; end if;

  select outstanding_minor into outstanding
  from public.v_obligation_balances
  where obligation_id=p_obligation_id and tenancy_id=p_tenancy_id;

  if outstanding is null or outstanding<=0 then raise exception 'NO_OUTSTANDING_DUE'; end if;
  if p_amount_minor>outstanding then raise exception 'SECURITY_OVER_APPLICATION'; end if;

  insert into public.security_events(
    id,security_account_id,event_type,amount_minor,obligation_id,occurred_at,reason,created_at
  ) values (
    p_security_event_id,security_account_id,'applied_to_dues',p_amount_minor,
    p_obligation_id,p_occurred_at,p_reason,now()
  );

  perform public.pg_append_domain_event(
    p_domain_event_id,p_business_id,'security',security_account_id,
    'security_applied_to_dues',p_occurred_at,p_device_id,
    jsonb_build_object(
      'securityEventId',p_security_event_id,
      'tenancyId',p_tenancy_id,
      'obligationId',p_obligation_id,
      'amountMinor',p_amount_minor
    )
  );

  perform public.pg_consume_authorization(authz_id,p_domain_event_id);

  result := jsonb_build_object('state','accepted','security_event_id',p_security_event_id);
  perform public.pg_register_sync_result(
    p_operation_id,p_business_id,p_device_id,'security_event',p_security_event_id,
    'apply_security_to_dues','accepted',result
  );
  return result;
end;
$$;

-- ============================================================================
-- 7. REFUND SECURITY
-- ============================================================================

create or replace function public.pg_refund_security(
  p_operation_id uuid,
  p_business_id uuid,
  p_device_id uuid,
  p_security_event_id uuid,
  p_domain_event_id uuid,
  p_tenancy_id uuid,
  p_amount_minor bigint,
  p_reason text,
  p_occurred_at timestamptz,
  p_approval_authorization_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  prior jsonb;
  authz_id uuid;
  security_account_id uuid;
  held bigint;
  result jsonb;
begin
  prior := public.pg_get_prior_sync_result(p_operation_id);
  if prior is not null then return prior; end if;

  authz_id := public.pg_assert_action_authorized(
    p_business_id,'refund_security','tenancy',p_tenancy_id,p_approval_authorization_id
  );

  if p_amount_minor<=0 then raise exception 'INVALID_AMOUNT'; end if;

  select sa.id,vsb.held_amount_minor
  into security_account_id,held
  from public.security_accounts sa
  join public.v_security_balances vsb on vsb.security_account_id=sa.id
  join public.tenancies t on t.id=sa.tenancy_id
  where sa.tenancy_id=p_tenancy_id and t.business_id=p_business_id;

  if security_account_id is null then raise exception 'SECURITY_ACCOUNT_NOT_FOUND'; end if;
  if held<p_amount_minor then raise exception 'INSUFFICIENT_SECURITY_HELD'; end if;

  insert into public.security_events(
    id,security_account_id,event_type,amount_minor,occurred_at,reason,created_at
  ) values (
    p_security_event_id,security_account_id,'refund',p_amount_minor,
    p_occurred_at,p_reason,now()
  );

  perform public.pg_append_domain_event(
    p_domain_event_id,p_business_id,'security',security_account_id,
    'security_refunded',p_occurred_at,p_device_id,
    jsonb_build_object(
      'securityEventId',p_security_event_id,
      'tenancyId',p_tenancy_id,
      'amountMinor',p_amount_minor
    )
  );

  perform public.pg_consume_authorization(authz_id,p_domain_event_id);

  result := jsonb_build_object('state','accepted','security_event_id',p_security_event_id);
  perform public.pg_register_sync_result(
    p_operation_id,p_business_id,p_device_id,'security_event',p_security_event_id,
    'refund_security','accepted',result
  );
  return result;
end;
$$;

-- ============================================================================
-- 8. CASH HANDOVER + DISCREPANCY
-- ============================================================================

create or replace function public.pg_handover_cash(
  p_operation_id uuid,
  p_business_id uuid,
  p_device_id uuid,
  p_handover_event_id uuid,
  p_discrepancy_event_id uuid,
  p_domain_event_id uuid,
  p_from_party_id uuid,
  p_to_party_id uuid,
  p_expected_amount_minor bigint,
  p_actual_amount_minor bigint,
  p_occurred_at timestamptz,
  p_approval_authorization_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  prior jsonb;
  authz_id uuid;
  difference bigint;
  result jsonb;
begin
  prior := public.pg_get_prior_sync_result(p_operation_id);
  if prior is not null then return prior; end if;

  authz_id := public.pg_assert_action_authorized(
    p_business_id,'handover_cash','party',p_from_party_id,p_approval_authorization_id
  );

  if p_expected_amount_minor<=0 or p_actual_amount_minor<0 then
    raise exception 'INVALID_HANDOVER_AMOUNT';
  end if;

  insert into public.cash_custody_events(
    id,business_id,event_type,from_party_id,to_party_id,amount_minor,
    occurred_at,recorded_by_user_id,created_at
  ) values (
    p_handover_event_id,p_business_id,'handover',p_from_party_id,p_to_party_id,
    p_actual_amount_minor,p_occurred_at,auth.uid(),now()
  );

  difference := p_expected_amount_minor-p_actual_amount_minor;

  if difference<>0 then
    if p_discrepancy_event_id is null then raise exception 'DISCREPANCY_EVENT_ID_REQUIRED'; end if;

    insert into public.cash_custody_events(
      id,business_id,event_type,from_party_id,to_party_id,amount_minor,
      related_event_id,occurred_at,reason,recorded_by_user_id,created_at
    ) values (
      p_discrepancy_event_id,p_business_id,'discrepancy',p_from_party_id,p_to_party_id,
      abs(difference),p_handover_event_id,p_occurred_at,
      case when difference>0 then 'short_handover' else 'excess_handover' end,
      auth.uid(),now()
    );
  end if;

  perform public.pg_append_domain_event(
    p_domain_event_id,p_business_id,'cash_custody',p_handover_event_id,
    'cash_handover_recorded',p_occurred_at,p_device_id,
    jsonb_build_object(
      'expectedAmountMinor',p_expected_amount_minor,
      'actualAmountMinor',p_actual_amount_minor,
      'discrepancyEventId',p_discrepancy_event_id
    )
  );

  perform public.pg_consume_authorization(authz_id,p_domain_event_id);

  result := jsonb_build_object(
    'state','accepted',
    'handover_event_id',p_handover_event_id,
    'discrepancy_event_id',p_discrepancy_event_id
  );
  perform public.pg_register_sync_result(
    p_operation_id,p_business_id,p_device_id,'cash_custody_event',p_handover_event_id,
    'handover_cash','accepted',result
  );
  return result;
end;
$$;

-- ============================================================================
-- 9. END TENANCY
-- ============================================================================

create or replace function public.pg_end_tenancy(
  p_operation_id uuid,
  p_business_id uuid,
  p_device_id uuid,
  p_tenancy_id uuid,
  p_domain_event_id uuid,
  p_ended_at timestamptz,
  p_approval_authorization_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  prior jsonb;
  authz_id uuid;
  current_state text;
  active_occupancy_id uuid;
  result jsonb;
begin
  prior := public.pg_get_prior_sync_result(p_operation_id);
  if prior is not null then return prior; end if;

  authz_id := public.pg_assert_action_authorized(
    p_business_id,'end_tenancy','tenancy',p_tenancy_id,p_approval_authorization_id
  );

  select lifecycle_state into current_state
  from public.tenancies
  where id=p_tenancy_id and business_id=p_business_id
  for update;

  if current_state is null then raise exception 'TENANCY_NOT_FOUND'; end if;
  if current_state not in ('active','planned_move_out') then
    raise exception 'INVALID_LIFECYCLE';
  end if;

  select id into active_occupancy_id
  from public.occupancy_assignments
  where tenancy_id=p_tenancy_id
    and assignment_state='active'
  limit 1
  for update;

  if active_occupancy_id is not null then
    update public.occupancy_assignments
    set assignment_state='ended',end_at=p_ended_at
    where id=active_occupancy_id;
  end if;

  update public.tenancies
  set lifecycle_state='moved_out',ended_at=p_ended_at,updated_at=now()
  where id=p_tenancy_id;

  perform public.pg_append_domain_event(
    p_domain_event_id,p_business_id,'tenancy',p_tenancy_id,'tenancy_ended',
    p_ended_at,p_device_id,
    jsonb_build_object('activeOccupancyId',active_occupancy_id)
  );

  perform public.pg_consume_authorization(authz_id,p_domain_event_id);

  -- Deliberately preserves obligations, payments, receipts, security and pending refunds.
  result := jsonb_build_object(
    'state','accepted',
    'tenancy_id',p_tenancy_id,
    'active_occupancy_id',active_occupancy_id
  );
  perform public.pg_register_sync_result(
    p_operation_id,p_business_id,p_device_id,'tenancy',p_tenancy_id,
    'end_tenancy','accepted',result
  );
  return result;
end;
$$;

-- ============================================================================
-- 10. DRAIN-ONLY SERVER CONTRACT — STORAGE SUPPORT
-- ============================================================================

create table if not exists public.sync_drain_epochs (
  id uuid primary key default gen_random_uuid(),
  account_user_id uuid not null,
  device_id uuid not null,
  entitlement_key text not null,
  verified_at timestamptz not null,
  grace_expires_at timestamptz not null,
  config_version text,
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists idx_sync_drain_epochs_device
  on public.sync_drain_epochs(account_user_id,device_id,entitlement_key,grace_expires_at);

comment on table public.sync_drain_epochs is
'Proposed server record of a previously verified entitlement/grace window. Exact cryptographic proof that an offline event was created within this window remains open.';

-- ENT-30 CONTRACT:
-- A production drain RPC must accept already-recorded outbound operations even
-- after cloud_sync is lost, when the server can verify that those operations
-- were legitimately created while entitled or within grace.
--
-- This migration deliberately DOES NOT accept a bare client boolean such as
-- "recorded_while_entitled=true"; that would not be trustworthy.
--
-- Next security decision required before production:
-- choose a verifiable device/epoch proof design (e.g. signed device epoch,
-- secure monotonic counter, or another authenticated mechanism) that works
-- offline and cannot be backdated by simply changing the device clock.

-- ============================================================================
-- 11. GRANTS
-- ============================================================================

revoke all on function public.pg_record_payment(
  uuid,uuid,uuid,uuid,uuid,uuid,uuid,uuid,bigint,text,timestamptz,jsonb,uuid,uuid,uuid
) from public;
grant execute on function public.pg_record_payment(
  uuid,uuid,uuid,uuid,uuid,uuid,uuid,uuid,bigint,text,timestamptz,jsonb,uuid,uuid,uuid
) to authenticated;

revoke all on function public.pg_reverse_payment(
  uuid,uuid,uuid,uuid,uuid,uuid,text,timestamptz,jsonb,uuid
) from public;
grant execute on function public.pg_reverse_payment(
  uuid,uuid,uuid,uuid,uuid,uuid,text,timestamptz,jsonb,uuid
) to authenticated;

revoke all on function public.pg_transfer_room(
  uuid,uuid,uuid,uuid,uuid,uuid,uuid,uuid,timestamptz,uuid
) from public;
grant execute on function public.pg_transfer_room(
  uuid,uuid,uuid,uuid,uuid,uuid,uuid,uuid,timestamptz,uuid
) to authenticated;

revoke all on function public.pg_apply_security_to_dues(
  uuid,uuid,uuid,uuid,uuid,uuid,uuid,bigint,text,timestamptz,uuid
) from public;
grant execute on function public.pg_apply_security_to_dues(
  uuid,uuid,uuid,uuid,uuid,uuid,uuid,bigint,text,timestamptz,uuid
) to authenticated;

revoke all on function public.pg_refund_security(
  uuid,uuid,uuid,uuid,uuid,uuid,bigint,text,timestamptz,uuid
) from public;
grant execute on function public.pg_refund_security(
  uuid,uuid,uuid,uuid,uuid,uuid,bigint,text,timestamptz,uuid
) to authenticated;

revoke all on function public.pg_handover_cash(
  uuid,uuid,uuid,uuid,uuid,uuid,uuid,uuid,bigint,bigint,timestamptz,uuid
) from public;
grant execute on function public.pg_handover_cash(
  uuid,uuid,uuid,uuid,uuid,uuid,uuid,uuid,bigint,bigint,timestamptz,uuid
) to authenticated;

revoke all on function public.pg_end_tenancy(
  uuid,uuid,uuid,uuid,uuid,timestamptz,uuid
) from public;
grant execute on function public.pg_end_tenancy(
  uuid,uuid,uuid,uuid,uuid,timestamptz,uuid
) to authenticated;

commit;
