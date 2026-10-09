-- Khaata PG / Hostel V1 — Supabase RLS + Sync Server Contract v1
-- STATUS: PROPOSED IMPLEMENTATION MIGRATION. DO NOT APPLY WITHOUT REVIEW.
--
-- Goals:
--   * Server never trusts client-side AccessGate/visibility alone.
--   * Owner-only operation remains valid.
--   * Active staff membership controls business access.
--   * Action permission and visibility remain separate.
--   * Sync retries are idempotent.
--   * Direct table RLS protects row scope.
--   * Sensitive field visibility is served through safe RPC/views rather than
--     pretending row-level security can redact individual columns.
--   * Feature gates use entitlement keys, never tier-name checks.
--
-- Assumptions:
--   * auth.uid() identifies the authenticated Khaata account.
--   * public.businesses.owner_user_id and public.staff_memberships.user_id are UUID.
--   * Staff role normalization from the local Staff Access build is added server-side.
--   * Exact subscription/billing provider schema remains outside this PG migration.

begin;

-- ============================================================================
-- 1. SERVER STAFF ROLE NORMALIZATION
-- ============================================================================

create table if not exists public.staff_roles (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  role_key text not null,
  display_name text not null,
  is_system_template boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz,
  unique (business_id, role_key)
);

create table if not exists public.staff_role_action_permissions (
  id uuid primary key default gen_random_uuid(),
  role_id uuid not null references public.staff_roles(id) on delete restrict,
  action_key text not null,
  permission_state text not null
    check (permission_state in ('allowed','needs_approval','not_allowed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (role_id, action_key)
);

create table if not exists public.staff_role_visibility (
  id uuid primary key default gen_random_uuid(),
  role_id uuid not null references public.staff_roles(id) on delete restrict,
  visibility_key text not null,
  is_visible boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (role_id, visibility_key)
);

alter table public.staff_memberships
  add column if not exists role_id uuid references public.staff_roles(id);

-- ============================================================================
-- 2. ENTITLEMENT SNAPSHOT / SERVER CONFIG BOUNDARY
-- ============================================================================

create table if not exists public.entitlement_registry (
  entitlement_key text primary key,
  display_name text not null,
  description text,
  requires text[] not null default '{}',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.account_entitlement_snapshots (
  account_user_id uuid primary key,
  effective_entitlements text[] not null default '{}',
  verified_at timestamptz not null,
  config_version text,
  source text
);

comment on table public.account_entitlement_snapshots is
'Server-computed effective entitlement snapshot. Feature code checks keys, never Free/Pro/Premium names.';

-- No tier-name logic appears in RLS or RPC below.

-- ============================================================================
-- 3. ACCESS HELPER FUNCTIONS
-- ============================================================================

create or replace function public.is_business_owner(p_business_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.businesses b
    where b.id = p_business_id
      and b.owner_user_id = auth.uid()
      and b.retired_at is null
  );
$$;

create or replace function public.active_membership_id(p_business_id uuid)
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select sm.id
  from public.staff_memberships sm
  where sm.business_id = p_business_id
    and sm.user_id = auth.uid()
    and sm.membership_state = 'active'
  limit 1;
$$;

create or replace function public.has_business_access(p_business_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    public.is_business_owner(p_business_id)
    or public.active_membership_id(p_business_id) is not null;
$$;

create or replace function public.current_action_permission(
  p_business_id uuid,
  p_action_key text
)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select case
    when public.is_business_owner(p_business_id) then 'allowed'
    else coalesce((
      select sap.permission_state
      from public.staff_memberships sm
      join public.staff_roles sr on sr.id = sm.role_id
      join public.staff_role_action_permissions sap on sap.role_id = sr.id
      where sm.business_id = p_business_id
        and sm.user_id = auth.uid()
        and sm.membership_state = 'active'
        and sr.archived_at is null
        and sap.action_key = p_action_key
      limit 1
    ), 'not_allowed')
  end;
$$;

create or replace function public.has_visibility(
  p_business_id uuid,
  p_visibility_key text
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select case
    when public.is_business_owner(p_business_id) then true
    else coalesce((
      select srv.is_visible
      from public.staff_memberships sm
      join public.staff_roles sr on sr.id = sm.role_id
      join public.staff_role_visibility srv on srv.role_id = sr.id
      where sm.business_id = p_business_id
        and sm.user_id = auth.uid()
        and sm.membership_state = 'active'
        and sr.archived_at is null
        and srv.visibility_key = p_visibility_key
      limit 1
    ), false)
  end;
$$;

create or replace function public.has_entitlement(p_entitlement_key text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.account_entitlement_snapshots aes
    where aes.account_user_id = auth.uid()
      and p_entitlement_key = any(aes.effective_entitlements)
  );
$$;

-- ============================================================================
-- 4. SYNC IDEMPOTENCY
-- ============================================================================

create table if not exists public.sync_operations (
  operation_id uuid primary key,
  business_id uuid not null references public.businesses(id) on delete restrict,
  actor_user_id uuid not null,
  device_id uuid,
  aggregate_type text not null,
  aggregate_id uuid not null,
  operation_type text not null,
  received_at timestamptz not null default now(),
  result_state text not null
    check (result_state in ('accepted','rejected','conflict')),
  result_payload jsonb not null default '{}'::jsonb
);

create index if not exists idx_sync_operations_business_received
  on public.sync_operations(business_id, received_at);

comment on table public.sync_operations is
'Idempotency register for client outbox operations. Retrying the same operation_id returns the prior result.';

-- ============================================================================
-- 5. SERVER VERSION / CONFLICT METADATA
-- ============================================================================

create table if not exists public.server_record_versions (
  business_id uuid not null references public.businesses(id) on delete restrict,
  entity_type text not null,
  entity_id uuid not null,
  version bigint not null default 1,
  updated_at timestamptz not null default now(),
  primary key (entity_type, entity_id)
);

create table if not exists public.server_sync_conflicts (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  actor_user_id uuid,
  device_id uuid,
  entity_type text not null,
  entity_id uuid not null,
  conflict_type text not null,
  client_payload jsonb,
  server_payload jsonb,
  detected_at timestamptz not null default now(),
  resolution_state text not null default 'open'
    check (resolution_state in ('open','resolved_local','resolved_remote','resolved_merged','dismissed')),
  resolved_at timestamptz
);

-- ============================================================================
-- 6. RLS HELPERS / BUSINESS-SCOPED ROW SECURITY
-- ============================================================================

alter table public.businesses enable row level security;
alter table public.property_nodes enable row level security;
alter table public.parties enable row level security;
alter table public.tenancies enable row level security;
alter table public.charges enable row level security;
alter table public.obligations enable row level security;
alter table public.payment_events enable row level security;
alter table public.expenses enable row level security;
alter table public.cash_custody_events enable row level security;
alter table public.staff_memberships enable row level security;
alter table public.staff_roles enable row level security;
alter table public.staff_role_action_permissions enable row level security;
alter table public.staff_role_visibility enable row level security;
alter table public.approval_requests enable row level security;
alter table public.domain_events enable row level security;
alter table public.sync_operations enable row level security;
alter table public.server_sync_conflicts enable row level security;

drop policy if exists business_read on public.businesses;
create policy business_read on public.businesses
for select
using (public.has_business_access(id));

drop policy if exists business_owner_update on public.businesses;
create policy business_owner_update on public.businesses
for update
using (public.is_business_owner(id))
with check (public.is_business_owner(id));

-- Generic row-scope policies. These permit row presence; field-level visibility
-- is handled via safe views/RPC below.

drop policy if exists property_read on public.property_nodes;
create policy property_read on public.property_nodes
for select using (
  public.has_business_access(business_id)
  and public.has_visibility(business_id,'rooms')
);

drop policy if exists parties_read on public.parties;
create policy parties_read on public.parties
for select using (
  public.has_business_access(business_id)
  and public.has_visibility(business_id,'tenant_records')
);

drop policy if exists tenancies_read on public.tenancies;
create policy tenancies_read on public.tenancies
for select using (
  public.has_business_access(business_id)
  and public.has_visibility(business_id,'tenant_records')
);

drop policy if exists charges_read on public.charges;
create policy charges_read on public.charges
for select using (
  public.has_business_access(business_id)
  and public.has_visibility(business_id,'tenant_balances')
);

drop policy if exists obligations_read on public.obligations;
create policy obligations_read on public.obligations
for select using (
  public.has_business_access(business_id)
  and public.has_visibility(business_id,'tenant_balances')
);

drop policy if exists payments_read on public.payment_events;
create policy payments_read on public.payment_events
for select using (
  public.has_business_access(business_id)
  and public.has_visibility(business_id,'tenant_balances')
);

drop policy if exists expenses_read on public.expenses;
create policy expenses_read on public.expenses
for select using (
  public.has_business_access(business_id)
  and public.has_visibility(business_id,'expenses')
);

drop policy if exists custody_read on public.cash_custody_events;
create policy custody_read on public.cash_custody_events
for select using (
  public.has_business_access(business_id)
  and public.has_visibility(business_id,'staff_cash_custody')
);

drop policy if exists staff_memberships_read on public.staff_memberships;
create policy staff_memberships_read on public.staff_memberships
for select using (
  public.has_business_access(business_id)
  and public.has_visibility(business_id,'staff_access')
);

drop policy if exists approvals_read on public.approval_requests;
create policy approvals_read on public.approval_requests
for select using (
  public.has_business_access(business_id)
);

drop policy if exists domain_events_read on public.domain_events;
create policy domain_events_read on public.domain_events
for select using (
  public.has_business_access(business_id)
);

-- Direct client INSERT/UPDATE policies are deliberately NOT broadly granted
-- for financial/history-sensitive tables. Sync should use controlled RPCs.

-- ============================================================================
-- 7. SAFE READ RPC FOR TENANT SUMMARY
-- ============================================================================

create or replace function public.pg_tenant_summary(p_business_id uuid)
returns table (
  tenancy_id uuid,
  display_name text,
  lifecycle_state text,
  room_bed text,
  outstanding_minor bigint,
  phone text
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  can_records boolean;
  can_rooms boolean;
  can_balances boolean;
  can_sensitive boolean;
begin
  if not public.has_business_access(p_business_id) then
    raise exception 'BUSINESS_ACCESS_DENIED';
  end if;

  can_records := public.has_visibility(p_business_id,'tenant_records');
  if not can_records then
    raise exception 'TENANT_RECORDS_HIDDEN';
  end if;

  can_rooms := public.has_visibility(p_business_id,'rooms');
  can_balances := public.has_visibility(p_business_id,'tenant_balances');
  can_sensitive := public.has_visibility(p_business_id,'tenant_sensitive_identity');

  return query
  select
    t.id,
    p.display_name,
    t.lifecycle_state,
    case when can_rooms then pn.label else null end,
    case when can_balances then coalesce(vto.outstanding_minor,0) else null end,
    case when can_sensitive then p.phone else null end
  from public.tenancies t
  left join public.tenancy_role_assignments tra
    on tra.tenancy_id=t.id
   and tra.role_type='occupant'
   and tra.valid_to is null
  left join public.parties p on p.id=tra.party_id
  left join public.occupancy_assignments oa
    on oa.tenancy_id=t.id
   and oa.assignment_state in ('planned','active')
  left join public.property_nodes pn on pn.id=oa.capacity_id
  left join public.v_tenancy_outstanding vto on vto.tenancy_id=t.id
  where t.business_id=p_business_id;
end;
$$;

revoke all on function public.pg_tenant_summary(uuid) from public;
grant execute on function public.pg_tenant_summary(uuid) to authenticated;

-- ============================================================================
-- 8. SYNC RPC: IDEMPOTENCY + ACCESS + ENTITLEMENT ENVELOPE
-- ============================================================================

create or replace function public.pg_sync_accept_operation(
  p_operation_id uuid,
  p_business_id uuid,
  p_device_id uuid,
  p_aggregate_type text,
  p_aggregate_id uuid,
  p_operation_type text,
  p_action_key text,
  p_payload jsonb,
  p_client_base_version bigint default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  prior public.sync_operations%rowtype;
  permission text;
  current_version bigint;
  result jsonb;
begin
  -- Retry safety.
  select * into prior
  from public.sync_operations
  where operation_id=p_operation_id;

  if found then
    return prior.result_payload;
  end if;

  if not public.has_business_access(p_business_id) then
    raise exception 'BUSINESS_ACCESS_DENIED';
  end if;

  -- Cloud sync is capability-gated by entitlement key, not plan/tier name.
  if not public.has_entitlement('cloud_sync') then
    raise exception 'ENTITLEMENT_CLOUD_SYNC_REQUIRED';
  end if;

  permission := public.current_action_permission(p_business_id,p_action_key);

  -- Owner returns allowed. Staff policy may require an approval-aware dedicated
  -- execution RPC; generic sync is not allowed to bypass "needs approval".
  if permission='not_allowed' then
    raise exception 'ACTION_NOT_ALLOWED';
  elsif permission='needs_approval' then
    raise exception 'APPROVAL_REQUIRED';
  end if;

  select version into current_version
  from public.server_record_versions
  where entity_type=p_aggregate_type
    and entity_id=p_aggregate_id;

  if p_client_base_version is not null
     and current_version is not null
     and p_client_base_version <> current_version then

    insert into public.server_sync_conflicts(
      business_id,actor_user_id,device_id,entity_type,entity_id,
      conflict_type,client_payload,server_payload
    ) values (
      p_business_id,auth.uid(),p_device_id,p_aggregate_type,p_aggregate_id,
      'stale_base_version',p_payload,
      jsonb_build_object('server_version',current_version)
    );

    result := jsonb_build_object(
      'state','conflict',
      'operation_id',p_operation_id,
      'server_version',current_version
    );

    insert into public.sync_operations(
      operation_id,business_id,actor_user_id,device_id,aggregate_type,
      aggregate_id,operation_type,result_state,result_payload
    ) values (
      p_operation_id,p_business_id,auth.uid(),p_device_id,p_aggregate_type,
      p_aggregate_id,p_operation_type,'conflict',result
    );

    return result;
  end if;

  -- IMPORTANT:
  -- This envelope deliberately does NOT dynamically execute arbitrary SQL from
  -- aggregate_type/payload. Production must route each accepted operation to a
  -- typed domain RPC (record_payment, transfer_room, etc.) with server-side
  -- invariant validation.
  result := jsonb_build_object(
    'state','accepted_for_domain_dispatch',
    'operation_id',p_operation_id,
    'aggregate_type',p_aggregate_type,
    'aggregate_id',p_aggregate_id
  );

  insert into public.sync_operations(
    operation_id,business_id,actor_user_id,device_id,aggregate_type,
    aggregate_id,operation_type,result_state,result_payload
  ) values (
    p_operation_id,p_business_id,auth.uid(),p_device_id,p_aggregate_type,
    p_aggregate_id,p_operation_type,'accepted',result
  );

  return result;
end;
$$;

revoke all on function public.pg_sync_accept_operation(
  uuid,uuid,uuid,text,uuid,text,text,jsonb,bigint
) from public;
grant execute on function public.pg_sync_accept_operation(
  uuid,uuid,uuid,text,uuid,text,text,jsonb,bigint
) to authenticated;

-- ============================================================================
-- 9. IMPORTANT PRODUCTION RULES
-- ============================================================================
--
-- 1) Do NOT expose service-role credentials to the mobile app.
-- 2) Do NOT let clients bypass typed domain RPC validation through generic table writes.
-- 3) Row-level policies protect business scope; sensitive field visibility should
--    use safe views/RPC or carefully restricted column privileges.
-- 4) Financial/history-sensitive records remain append-only server-side too.
-- 5) "needs_approval" must route through approval authorization, never silently
--    degrade to Allowed during sync.
-- 6) Entitlement checks use stable keys such as cloud_sync/multi_user/role_permissions.
-- 7) Server-side tier mapping/config remains outside feature code.
-- 8) Already-legitimate queued outbound work after entitlement loss requires a
--    dedicated drain authorization rule; do not simply delete/reject historical truth.
--
-- The exact drain credential/token design remains open and should be added before
-- production sync rollout.

commit;
