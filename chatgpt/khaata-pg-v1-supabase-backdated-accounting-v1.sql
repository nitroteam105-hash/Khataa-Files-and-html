-- Khaata PG / Hostel V1 — Supabase Backdated Accounting + Statement v1
-- STATUS: PROPOSED IMPLEMENTATION MIGRATION. DO NOT APPLY WITHOUT REVIEW.
--
-- Server counterpart to the local Backdated Accounting + Tenant Statement build.
--
-- Guarantees:
-- * backdated accounting path is explicit
-- * opening balances are not fabricated payments/charges/deposits
-- * opening positions are immutable
-- * corrections append separately
-- * tenant statement distinguishes opening rows from Khaata-recorded activity
-- * security stays separate from rent/charge balance
-- * records participate in sync_change_feed atomically

begin;

-- ============================================================================
-- 1. SERVER TABLES
-- ============================================================================

create table if not exists public.tenancy_accounting_starts (
  id uuid primary key,
  business_id uuid not null references public.businesses(id) on delete restrict,
  tenancy_id uuid not null unique references public.tenancies(id) on delete restrict,
  accounting_path text not null
    check (accounting_path in ('bring_existing_history','start_from_date')),
  accounting_start_date date not null,
  created_at timestamptz not null default now(),
  created_by_user_id uuid
);

create table if not exists public.opening_financial_positions (
  id uuid primary key,
  business_id uuid not null references public.businesses(id) on delete restrict,
  tenancy_id uuid not null unique references public.tenancies(id) on delete restrict,
  accounting_start_id uuid not null unique
    references public.tenancy_accounting_starts(id) on delete restrict,
  effective_date date not null,
  opening_outstanding_minor bigint not null default 0
    check (opening_outstanding_minor >= 0),
  opening_tenant_credit_minor bigint not null default 0
    check (opening_tenant_credit_minor >= 0),
  opening_security_held_minor bigint not null default 0
    check (opening_security_held_minor >= 0),
  note text,
  created_at timestamptz not null default now(),
  created_by_user_id uuid
);

create table if not exists public.opening_position_corrections (
  id uuid primary key,
  opening_position_id uuid not null
    references public.opening_financial_positions(id) on delete restrict,
  correction_type text not null
    check (correction_type in ('outstanding','tenant_credit','security_held')),
  amount_delta_minor bigint not null check (amount_delta_minor <> 0),
  reason text not null check (length(trim(reason)) > 0),
  occurred_at timestamptz not null,
  created_at timestamptz not null default now(),
  created_by_user_id uuid
);

-- ============================================================================
-- 2. IMMUTABILITY
-- ============================================================================

create or replace function public.reject_opening_position_mutation()
returns trigger
language plpgsql
as $$
begin
  raise exception 'opening_financial_positions are immutable; append correction instead';
end;
$$;

drop trigger if exists opening_position_no_update on public.opening_financial_positions;
create trigger opening_position_no_update
before update on public.opening_financial_positions
for each row execute function public.reject_opening_position_mutation();

drop trigger if exists opening_position_no_delete on public.opening_financial_positions;
create trigger opening_position_no_delete
before delete on public.opening_financial_positions
for each row execute function public.reject_opening_position_mutation();

create or replace function public.reject_opening_correction_mutation()
returns trigger
language plpgsql
as $$
begin
  raise exception 'opening_position_corrections are append-only';
end;
$$;

drop trigger if exists opening_correction_no_update on public.opening_position_corrections;
create trigger opening_correction_no_update
before update on public.opening_position_corrections
for each row execute function public.reject_opening_correction_mutation();

drop trigger if exists opening_correction_no_delete on public.opening_position_corrections;
create trigger opening_correction_no_delete
before delete on public.opening_position_corrections
for each row execute function public.reject_opening_correction_mutation();

-- ============================================================================
-- 3. EFFECTIVE POSITION + STATEMENT VIEWS
-- ============================================================================

create or replace view public.v_opening_financial_position_effective as
select
  op.id as opening_position_id,
  op.business_id,
  op.tenancy_id,
  op.effective_date,
  op.opening_outstanding_minor
    + coalesce(sum(case when c.correction_type='outstanding'
      then c.amount_delta_minor else 0 end),0) as opening_outstanding_minor,
  op.opening_tenant_credit_minor
    + coalesce(sum(case when c.correction_type='tenant_credit'
      then c.amount_delta_minor else 0 end),0) as opening_tenant_credit_minor,
  op.opening_security_held_minor
    + coalesce(sum(case when c.correction_type='security_held'
      then c.amount_delta_minor else 0 end),0) as opening_security_held_minor
from public.opening_financial_positions op
left join public.opening_position_corrections c
  on c.opening_position_id=op.id
group by op.id;

create or replace view public.v_tenancy_financial_position_v2 as
select
  t.id as tenancy_id,
  t.business_id,
  coalesce(vto.outstanding_minor,0) as khaata_outstanding_minor,
  coalesce(ofp.opening_outstanding_minor,0) as opening_outstanding_minor,
  coalesce(ofp.opening_tenant_credit_minor,0) as opening_credit_minor,
  greatest(
    coalesce(vto.outstanding_minor,0)
    + coalesce(ofp.opening_outstanding_minor,0)
    - coalesce(ofp.opening_tenant_credit_minor,0),
    0
  ) as net_outstanding_minor,
  greatest(
    coalesce(ofp.opening_tenant_credit_minor,0)
    - coalesce(vto.outstanding_minor,0)
    - coalesce(ofp.opening_outstanding_minor,0),
    0
  ) as available_credit_minor,
  coalesce(ofp.opening_security_held_minor,0) as opening_security_held_minor,
  coalesce(vsb.held_amount_minor,0) as khaata_security_held_minor,
  coalesce(ofp.opening_security_held_minor,0)
    + coalesce(vsb.held_amount_minor,0) as total_security_held_minor
from public.tenancies t
left join public.v_tenancy_outstanding vto on vto.tenancy_id=t.id
left join public.v_opening_financial_position_effective ofp on ofp.tenancy_id=t.id
left join public.security_accounts sa on sa.tenancy_id=t.id
left join public.v_security_balances vsb on vsb.security_account_id=sa.id;

-- ============================================================================
-- 4. TYPED RPC — START ACCOUNTING FROM DATE
-- ============================================================================

create or replace function public.pg_set_opening_financial_position(
  p_operation_id uuid,
  p_business_id uuid,
  p_device_id uuid,
  p_accounting_start_id uuid,
  p_opening_position_id uuid,
  p_domain_event_id uuid,
  p_tenancy_id uuid,
  p_accounting_start_date date,
  p_opening_outstanding_minor bigint,
  p_opening_tenant_credit_minor bigint,
  p_opening_security_held_minor bigint,
  p_note text default null,
  p_approval_authorization_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  prior jsonb;
  authz_id uuid;
  result jsonb;
begin
  prior := public.pg_get_prior_sync_result(p_operation_id);
  if prior is not null then return prior; end if;

  authz_id := public.pg_assert_action_authorized(
    p_business_id,
    'set_opening_balance',
    'tenancy',
    p_tenancy_id,
    p_approval_authorization_id
  );

  if p_opening_outstanding_minor < 0
     or p_opening_tenant_credit_minor < 0
     or p_opening_security_held_minor < 0 then
    raise exception 'INVALID_OPENING_AMOUNT';
  end if;

  if not exists (
    select 1 from public.tenancies
    where id=p_tenancy_id and business_id=p_business_id
  ) then
    raise exception 'TENANCY_NOT_FOUND';
  end if;

  if exists (
    select 1 from public.tenancy_accounting_starts
    where tenancy_id=p_tenancy_id
  ) then
    raise exception 'ACCOUNTING_START_ALREADY_SET';
  end if;

  insert into public.tenancy_accounting_starts(
    id,business_id,tenancy_id,accounting_path,accounting_start_date,
    created_at,created_by_user_id
  ) values (
    p_accounting_start_id,p_business_id,p_tenancy_id,'start_from_date',
    p_accounting_start_date,now(),auth.uid()
  );

  insert into public.opening_financial_positions(
    id,business_id,tenancy_id,accounting_start_id,effective_date,
    opening_outstanding_minor,opening_tenant_credit_minor,
    opening_security_held_minor,note,created_at,created_by_user_id
  ) values (
    p_opening_position_id,p_business_id,p_tenancy_id,p_accounting_start_id,
    p_accounting_start_date,p_opening_outstanding_minor,
    p_opening_tenant_credit_minor,p_opening_security_held_minor,
    p_note,now(),auth.uid()
  );

  perform public.pg_append_domain_event(
    p_domain_event_id,p_business_id,'opening_financial_position',
    p_opening_position_id,'opening_financial_position_set',
    p_accounting_start_date::timestamptz,p_device_id,
    jsonb_build_object(
      'tenancyId',p_tenancy_id,
      'accountingStartDate',p_accounting_start_date,
      'openingOutstandingMinor',p_opening_outstanding_minor,
      'openingTenantCreditMinor',p_opening_tenant_credit_minor,
      'openingSecurityHeldMinor',p_opening_security_held_minor
    )
  );

  perform public.pg_consume_authorization(authz_id,p_domain_event_id);

  result := jsonb_build_object(
    'state','accepted',
    'accounting_start_id',p_accounting_start_id,
    'opening_position_id',p_opening_position_id
  );

  perform public.pg_register_sync_result(
    p_operation_id,p_business_id,p_device_id,'opening_financial_position',
    p_opening_position_id,'set_opening_balance','accepted',result
  );

  return result;
end;
$$;

-- ============================================================================
-- 5. TYPED RPC — BRING EXISTING HISTORY PATH
-- ============================================================================

create or replace function public.pg_choose_existing_history_path(
  p_operation_id uuid,
  p_business_id uuid,
  p_device_id uuid,
  p_accounting_start_id uuid,
  p_tenancy_id uuid,
  p_historical_start_date date,
  p_approval_authorization_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  prior jsonb;
  authz_id uuid;
  result jsonb;
begin
  prior := public.pg_get_prior_sync_result(p_operation_id);
  if prior is not null then return prior; end if;

  authz_id := public.pg_assert_action_authorized(
    p_business_id,'set_opening_balance','tenancy',p_tenancy_id,
    p_approval_authorization_id
  );

  if not exists (
    select 1 from public.tenancies
    where id=p_tenancy_id and business_id=p_business_id
  ) then raise exception 'TENANCY_NOT_FOUND'; end if;

  if exists (
    select 1 from public.tenancy_accounting_starts
    where tenancy_id=p_tenancy_id
  ) then raise exception 'ACCOUNTING_START_ALREADY_SET'; end if;

  insert into public.tenancy_accounting_starts(
    id,business_id,tenancy_id,accounting_path,accounting_start_date,
    created_at,created_by_user_id
  ) values (
    p_accounting_start_id,p_business_id,p_tenancy_id,'bring_existing_history',
    p_historical_start_date,now(),auth.uid()
  );

  result := jsonb_build_object(
    'state','accepted','accounting_start_id',p_accounting_start_id
  );

  perform public.pg_register_sync_result(
    p_operation_id,p_business_id,p_device_id,'tenancy_accounting_start',
    p_accounting_start_id,'choose_existing_history','accepted',result
  );

  perform public.pg_consume_authorization(authz_id,null);

  return result;
end;
$$;

-- ============================================================================
-- 6. TYPED RPC — CORRECT OPENING POSITION
-- ============================================================================

create or replace function public.pg_correct_opening_financial_position(
  p_operation_id uuid,
  p_business_id uuid,
  p_device_id uuid,
  p_correction_id uuid,
  p_domain_event_id uuid,
  p_opening_position_id uuid,
  p_correction_type text,
  p_amount_delta_minor bigint,
  p_reason text,
  p_occurred_at timestamptz,
  p_approval_authorization_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  prior jsonb;
  authz_id uuid;
  tenancy_id_v uuid;
  result jsonb;
begin
  prior := public.pg_get_prior_sync_result(p_operation_id);
  if prior is not null then return prior; end if;

  select tenancy_id into tenancy_id_v
  from public.opening_financial_positions
  where id=p_opening_position_id
    and business_id=p_business_id;

  if tenancy_id_v is null then raise exception 'OPENING_POSITION_NOT_FOUND'; end if;

  authz_id := public.pg_assert_action_authorized(
    p_business_id,'correct_opening_balance','tenancy',tenancy_id_v,
    p_approval_authorization_id
  );

  if p_correction_type not in ('outstanding','tenant_credit','security_held') then
    raise exception 'INVALID_CORRECTION_TYPE';
  end if;
  if p_amount_delta_minor=0 then raise exception 'INVALID_CORRECTION_DELTA'; end if;
  if coalesce(trim(p_reason),'')='' then raise exception 'REASON_REQUIRED'; end if;

  insert into public.opening_position_corrections(
    id,opening_position_id,correction_type,amount_delta_minor,
    reason,occurred_at,created_at,created_by_user_id
  ) values (
    p_correction_id,p_opening_position_id,p_correction_type,p_amount_delta_minor,
    p_reason,p_occurred_at,now(),auth.uid()
  );

  perform public.pg_append_domain_event(
    p_domain_event_id,p_business_id,'opening_position_correction',
    p_correction_id,'opening_financial_position_corrected',
    p_occurred_at,p_device_id,
    jsonb_build_object(
      'openingPositionId',p_opening_position_id,
      'tenancyId',tenancy_id_v,
      'correctionType',p_correction_type,
      'amountDeltaMinor',p_amount_delta_minor,
      'reason',p_reason
    )
  );

  perform public.pg_consume_authorization(authz_id,p_domain_event_id);

  result := jsonb_build_object(
    'state','accepted','correction_id',p_correction_id
  );

  perform public.pg_register_sync_result(
    p_operation_id,p_business_id,p_device_id,'opening_position_correction',
    p_correction_id,'correct_opening_balance','accepted',result
  );

  return result;
end;
$$;

-- ============================================================================
-- 7. CHANGE-FEED PUBLICATION
-- ============================================================================

create or replace function public.trg_publish_tenancy_accounting_start()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
begin
  perform public.append_sync_change(
    gen_random_uuid(),new.business_id,'tenancy_accounting_start',new.id,'insert',
    to_jsonb(new),new.created_at
  );
  return new;
end;
$$;

drop trigger if exists publish_tenancy_accounting_start_to_feed
on public.tenancy_accounting_starts;
create trigger publish_tenancy_accounting_start_to_feed
after insert on public.tenancy_accounting_starts
for each row execute function public.trg_publish_tenancy_accounting_start();

create or replace function public.trg_publish_opening_financial_position()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
begin
  perform public.append_sync_change(
    gen_random_uuid(),new.business_id,'opening_financial_position',new.id,'append_event',
    to_jsonb(new),new.effective_date::timestamptz
  );
  return new;
end;
$$;

drop trigger if exists publish_opening_financial_position_to_feed
on public.opening_financial_positions;
create trigger publish_opening_financial_position_to_feed
after insert on public.opening_financial_positions
for each row execute function public.trg_publish_opening_financial_position();

create or replace function public.trg_publish_opening_position_correction()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
declare
  b uuid;
begin
  select business_id into b
  from public.opening_financial_positions
  where id=new.opening_position_id;

  if b is null then raise exception 'OPENING_POSITION_BUSINESS_NOT_FOUND'; end if;

  perform public.append_sync_change(
    gen_random_uuid(),b,'opening_position_correction',new.id,'append_event',
    to_jsonb(new),new.occurred_at
  );
  return new;
end;
$$;

drop trigger if exists publish_opening_position_correction_to_feed
on public.opening_position_corrections;
create trigger publish_opening_position_correction_to_feed
after insert on public.opening_position_corrections
for each row execute function public.trg_publish_opening_position_correction();

-- ============================================================================
-- 8. RLS
-- ============================================================================

alter table public.tenancy_accounting_starts enable row level security;
alter table public.opening_financial_positions enable row level security;
alter table public.opening_position_corrections enable row level security;

drop policy if exists accounting_start_read on public.tenancy_accounting_starts;
create policy accounting_start_read on public.tenancy_accounting_starts
for select using (
  public.has_business_access(business_id)
  and public.has_visibility(business_id,'tenant_balances')
);

drop policy if exists opening_position_read on public.opening_financial_positions;
create policy opening_position_read on public.opening_financial_positions
for select using (
  public.has_business_access(business_id)
  and public.has_visibility(business_id,'tenant_balances')
);

drop policy if exists opening_correction_read on public.opening_position_corrections;
create policy opening_correction_read on public.opening_position_corrections
for select using (
  exists (
    select 1
    from public.opening_financial_positions op
    where op.id=opening_position_id
      and public.has_business_access(op.business_id)
      and public.has_visibility(op.business_id,'tenant_balances')
  )
);

-- No broad direct client INSERT/UPDATE policies.
-- Writes flow through the typed RPCs above.

-- ============================================================================
-- 9. GRANTS
-- ============================================================================

revoke all on function public.pg_set_opening_financial_position(
  uuid,uuid,uuid,uuid,uuid,uuid,uuid,date,bigint,bigint,bigint,text,uuid
) from public;
grant execute on function public.pg_set_opening_financial_position(
  uuid,uuid,uuid,uuid,uuid,uuid,uuid,date,bigint,bigint,bigint,text,uuid
) to authenticated;

revoke all on function public.pg_choose_existing_history_path(
  uuid,uuid,uuid,uuid,uuid,date,uuid
) from public;
grant execute on function public.pg_choose_existing_history_path(
  uuid,uuid,uuid,uuid,uuid,date,uuid
) to authenticated;

revoke all on function public.pg_correct_opening_financial_position(
  uuid,uuid,uuid,uuid,uuid,uuid,text,bigint,text,timestamptz,uuid
) from public;
grant execute on function public.pg_correct_opening_financial_position(
  uuid,uuid,uuid,uuid,uuid,uuid,text,bigint,text,timestamptz,uuid
) to authenticated;

commit;
