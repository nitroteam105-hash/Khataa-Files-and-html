-- Khaata PG / Hostel V1 — Supabase/Postgres schema proposal v1
-- STATUS: PROPOSED IMPLEMENTATION SCHEMA, NOT A FROZEN PRODUCT DECISION.
-- Basis: frozen PG V1 product semantics + current global entitlement rules.
-- Currency: monetary values are stored as integer minor units (e.g. paise), never float.
-- IDs: UUIDs are globally unique and may be generated offline by clients; DB defaults are a fallback.
-- History: lifecycle/financial history is append- or version-oriented. Avoid destructive rewrites.
-- Sync protocol, exact RLS policy, and jurisdiction-specific tax fields remain implementation decisions.

begin;

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- 1. SHARED BUSINESS SHELL
-- ---------------------------------------------------------------------------

create table if not exists public.businesses (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null,
  name text not null check (length(trim(name)) > 0),
  business_type text not null,
  location_text text,
  operational_currency char(3) not null,
  timezone text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  retired_at timestamptz
);

comment on table public.businesses is
'Shared Khaata business shell. One base operational currency per business.';

create index if not exists idx_businesses_owner
  on public.businesses(owner_user_id)
  where retired_at is null;


-- ---------------------------------------------------------------------------
-- 2. PROPERTY / CAPACITY
-- ---------------------------------------------------------------------------

create table if not exists public.property_nodes (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  parent_id uuid references public.property_nodes(id) on delete restrict,
  node_type text not null check (node_type in ('building','block','floor','room','bed')),
  label text not null check (length(trim(label)) > 0),
  lifecycle_state text not null default 'available'
    check (lifecycle_state in ('available','temporarily_unavailable','retired')),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  retired_at timestamptz
);

comment on table public.property_nodes is
'Hierarchical capacity records. Records with history are retired rather than hard-deleted.';

create index if not exists idx_property_nodes_business_parent
  on public.property_nodes(business_id, parent_id);

create index if not exists idx_property_nodes_business_type
  on public.property_nodes(business_id, node_type);


-- ---------------------------------------------------------------------------
-- 3. PARTIES + TENANCY COMMERCIAL ROLES
-- ---------------------------------------------------------------------------

create table if not exists public.parties (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  party_type text not null default 'person'
    check (party_type in ('person','organization')),
  display_name text not null check (length(trim(display_name)) > 0),
  phone text,
  email text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  archived_at timestamptz
);

create table if not exists public.tenancies (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  lifecycle_state text not null default 'upcoming'
    check (lifecycle_state in ('upcoming','active','planned_move_out','moved_out','cancelled_before_joining')),
  planned_join_date date,
  joined_at timestamptz,
  planned_move_out_date date,
  ended_at timestamptz,
  cancelled_at timestamptz,
  cancellation_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (
    (lifecycle_state <> 'active' or joined_at is not null)
    and
    (lifecycle_state <> 'cancelled_before_joining' or cancelled_at is not null)
  )
);

comment on table public.tenancies is
'Commercial tenancy/agreement lifecycle. No-show is not stored as a lifecycle state.';

create index if not exists idx_tenancies_business_state
  on public.tenancies(business_id, lifecycle_state);

create table if not exists public.tenancy_role_assignments (
  id uuid primary key default gen_random_uuid(),
  tenancy_id uuid not null references public.tenancies(id) on delete restrict,
  party_id uuid not null references public.parties(id) on delete restrict,
  role_type text not null
    check (role_type in ('occupant','responsible_party','payer','deposit_owner')),
  valid_from timestamptz not null,
  valid_to timestamptz,
  created_at timestamptz not null default now(),
  check (valid_to is null or valid_to > valid_from)
);

comment on table public.tenancy_role_assignments is
'Effective-dated commercial roles; Khaata must not silently assume occupant, payer, responsible party and deposit owner are identical.';

create index if not exists idx_tenancy_roles_tenancy_role
  on public.tenancy_role_assignments(tenancy_id, role_type, valid_from);


-- ---------------------------------------------------------------------------
-- 4. OCCUPANCY + RENT TERMS
-- ---------------------------------------------------------------------------

create table if not exists public.occupancy_assignments (
  id uuid primary key default gen_random_uuid(),
  tenancy_id uuid not null references public.tenancies(id) on delete restrict,
  capacity_id uuid not null references public.property_nodes(id) on delete restrict,
  assignment_state text not null default 'planned'
    check (assignment_state in ('planned','active','ended','cancelled')),
  start_at timestamptz,
  end_at timestamptz,
  created_at timestamptz not null default now(),
  check (end_at is null or start_at is null or end_at > start_at)
);

comment on table public.occupancy_assignments is
'Room/bed assignment history. Transfers append new assignments; prior occupancy remains.';

create index if not exists idx_occupancy_tenancy
  on public.occupancy_assignments(tenancy_id, start_at);

create index if not exists idx_occupancy_capacity
  on public.occupancy_assignments(capacity_id, assignment_state, start_at);

create unique index if not exists uq_one_active_assignment_per_tenancy
  on public.occupancy_assignments(tenancy_id)
  where assignment_state = 'active';

create unique index if not exists uq_one_active_tenancy_per_capacity
  on public.occupancy_assignments(capacity_id)
  where assignment_state = 'active';

create table if not exists public.rent_terms (
  id uuid primary key default gen_random_uuid(),
  tenancy_id uuid not null references public.tenancies(id) on delete restrict,
  amount_minor bigint not null check (amount_minor >= 0),
  billing_frequency text not null default 'monthly'
    check (billing_frequency = 'monthly'),
  billing_timing text not null
    check (billing_timing in ('prepaid','postpaid')),
  due_day smallint not null check (due_day between 1 and 31),
  grace_days smallint not null default 0 check (grace_days between 0 and 90),
  valid_from date not null,
  valid_to date,
  created_at timestamptz not null default now(),
  check (valid_to is null or valid_to >= valid_from)
);

comment on table public.rent_terms is
'Effective-dated commercial rent terms. A room transfer does not mutate this table unless rent changes explicitly.';

create index if not exists idx_rent_terms_tenancy_validity
  on public.rent_terms(tenancy_id, valid_from);


-- ---------------------------------------------------------------------------
-- 5. OBLIGATIONS / CHARGES / ADJUSTMENTS
-- ---------------------------------------------------------------------------

create table if not exists public.charges (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  tenancy_id uuid not null references public.tenancies(id) on delete restrict,
  charge_type text not null
    check (charge_type in ('recurring','variable','one_time')),
  category text not null,
  description text,
  amount_minor bigint not null check (amount_minor >= 0),
  effective_date date not null,
  dispute_state text not null default 'none'
    check (dispute_state in ('none','disputed','resolved')),
  tax_context jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

comment on table public.charges is
'Charges are distinct from rent, payment and deposit. Tax is modeled at charge level; exact jurisdictional schema remains open.';

create table if not exists public.obligations (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  tenancy_id uuid not null references public.tenancies(id) on delete restrict,
  obligation_type text not null
    check (obligation_type in ('rent','charge','opening_balance')),
  source_charge_id uuid references public.charges(id) on delete restrict,
  period_start date,
  period_end date,
  due_date date,
  amount_minor bigint not null check (amount_minor >= 0),
  deterministic_key text,
  created_at timestamptz not null default now(),
  check (
    (obligation_type = 'charge' and source_charge_id is not null)
    or
    (obligation_type <> 'charge')
  )
);

comment on table public.obligations is
'Amounts due. Monthly rent obligations are deterministic and idempotent; old dues remain separate from current dues.';

create unique index if not exists uq_obligation_deterministic_key
  on public.obligations(business_id, deterministic_key)
  where deterministic_key is not null;

create index if not exists idx_obligations_tenancy_due
  on public.obligations(tenancy_id, due_date);

create table if not exists public.financial_adjustments (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  tenancy_id uuid not null references public.tenancies(id) on delete restrict,
  obligation_id uuid references public.obligations(id) on delete restrict,
  charge_id uuid references public.charges(id) on delete restrict,
  adjustment_type text not null
    check (adjustment_type in ('waiver','discount','write_off','correction')),
  amount_minor bigint not null check (amount_minor > 0),
  reason text not null check (length(trim(reason)) > 0),
  occurred_at timestamptz not null,
  created_at timestamptz not null default now(),
  check (obligation_id is not null or charge_id is not null)
);

comment on table public.financial_adjustments is
'Non-payment financial adjustments. Write-off/waiver/discount/correction never masquerade as payment.';


-- ---------------------------------------------------------------------------
-- 6. PAYMENTS / ALLOCATIONS / RECEIPTS
-- ---------------------------------------------------------------------------

create table if not exists public.payment_events (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  tenancy_id uuid not null references public.tenancies(id) on delete restrict,
  payer_party_id uuid references public.parties(id) on delete restrict,
  event_type text not null
    check (event_type in ('payment','reversal','chargeback')),
  original_payment_id uuid references public.payment_events(id) on delete restrict,
  amount_minor bigint not null check (amount_minor > 0),
  payment_method text,
  occurred_at timestamptz not null,
  recorded_by_user_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  check (
    (event_type = 'payment' and original_payment_id is null)
    or
    (event_type in ('reversal','chargeback') and original_payment_id is not null)
  )
);

comment on table public.payment_events is
'Append-only payment history. Original payment rows are preserved; reversal/chargeback references the original.';

create index if not exists idx_payment_events_tenancy_time
  on public.payment_events(tenancy_id, occurred_at);

create table if not exists public.payment_allocations (
  id uuid primary key default gen_random_uuid(),
  payment_event_id uuid not null references public.payment_events(id) on delete restrict,
  obligation_id uuid not null references public.obligations(id) on delete restrict,
  amount_minor bigint not null check (amount_minor > 0),
  allocation_effect smallint not null default 1
    check (allocation_effect in (-1,1)),
  created_at timestamptz not null default now()
);

comment on table public.payment_allocations is
'Many-to-many payment allocation. allocation_effect=-1 is used only for reversal/correction impact; original allocation rows remain.';

create index if not exists idx_payment_allocations_obligation
  on public.payment_allocations(obligation_id);

create index if not exists idx_payment_allocations_payment
  on public.payment_allocations(payment_event_id);

create table if not exists public.receipt_snapshots (
  id uuid primary key default gen_random_uuid(),
  payment_event_id uuid not null unique references public.payment_events(id) on delete restrict,
  receipt_number text not null,
  snapshot jsonb not null,
  issued_at timestamptz not null,
  created_at timestamptz not null default now()
);

comment on table public.receipt_snapshots is
'Immutable receipt payload captured at payment time. Application code must never regenerate old receipts from mutable live data.';


-- ---------------------------------------------------------------------------
-- 7. SECURITY / DEPOSIT
-- ---------------------------------------------------------------------------

create table if not exists public.security_accounts (
  id uuid primary key default gen_random_uuid(),
  tenancy_id uuid not null unique references public.tenancies(id) on delete restrict,
  agreed_amount_minor bigint not null default 0 check (agreed_amount_minor >= 0),
  deposit_owner_party_id uuid references public.parties(id) on delete restrict,
  created_at timestamptz not null default now()
);

create table if not exists public.security_events (
  id uuid primary key default gen_random_uuid(),
  security_account_id uuid not null references public.security_accounts(id) on delete restrict,
  event_type text not null
    check (event_type in ('deposit_received','applied_to_dues','refund','correction')),
  amount_minor bigint not null check (amount_minor > 0),
  obligation_id uuid references public.obligations(id) on delete restrict,
  payment_event_id uuid references public.payment_events(id) on delete restrict,
  occurred_at timestamptz not null,
  reason text,
  created_at timestamptz not null default now(),
  check (
    (event_type = 'applied_to_dues' and obligation_id is not null)
    or
    (event_type <> 'applied_to_dues')
  )
);

comment on table public.security_events is
'Deposit/security event history. Security application to dues is always explicit.';


-- ---------------------------------------------------------------------------
-- 8. PAYMENT PROMISES
-- ---------------------------------------------------------------------------

create table if not exists public.payment_promises (
  id uuid primary key default gen_random_uuid(),
  tenancy_id uuid not null references public.tenancies(id) on delete restrict,
  obligation_id uuid references public.obligations(id) on delete restrict,
  promised_amount_minor bigint not null check (promised_amount_minor > 0),
  promised_date date not null,
  recorded_by_user_id uuid,
  created_at timestamptz not null default now(),
  superseded_by_id uuid references public.payment_promises(id) on delete restrict
);

comment on table public.payment_promises is
'Promise-to-pay record only. It has no ledger effect and prior promise history is preserved.';


-- ---------------------------------------------------------------------------
-- 9. EXPENSES / REIMBURSEMENT
-- ---------------------------------------------------------------------------

create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  amount_minor bigint not null check (amount_minor > 0),
  category text not null,
  paid_by_type text not null
    check (paid_by_type in ('business','staff')),
  paid_by_party_id uuid references public.parties(id) on delete restrict,
  payment_method text,
  expense_date date not null,
  vendor text,
  property_context_id uuid references public.property_nodes(id) on delete restrict,
  reimbursement_state text not null default 'not_applicable'
    check (reimbursement_state in ('not_applicable','owed','settled','waived')),
  created_at timestamptz not null default now(),
  check (
    (paid_by_type = 'staff' and paid_by_party_id is not null and reimbursement_state <> 'not_applicable')
    or
    (paid_by_type = 'business' and reimbursement_state = 'not_applicable')
  )
);

comment on table public.expenses is
'Business-paid and staff-paid expenses are distinct. Staff-paid creates reimbursement accountability.';


-- ---------------------------------------------------------------------------
-- 10. CASH CUSTODY / HANDOVER / DISCREPANCY
-- ---------------------------------------------------------------------------

create table if not exists public.cash_custody_events (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  event_type text not null
    check (event_type in ('collection_received','transfer','handover','discrepancy','resolution')),
  payment_event_id uuid references public.payment_events(id) on delete restrict,
  from_party_id uuid references public.parties(id) on delete restrict,
  to_party_id uuid references public.parties(id) on delete restrict,
  amount_minor bigint not null check (amount_minor > 0),
  related_event_id uuid references public.cash_custody_events(id) on delete restrict,
  occurred_at timestamptz not null,
  reason text,
  recorded_by_user_id uuid,
  created_at timestamptz not null default now()
);

comment on table public.cash_custody_events is
'Physical cash custody/accountability. Tenant payment settlement must never be reversed merely because handover is pending or discrepant.';

create index if not exists idx_cash_custody_business_time
  on public.cash_custody_events(business_id, occurred_at);


-- ---------------------------------------------------------------------------
-- 11. STAFF / PERMISSIONS / APPROVALS
-- ---------------------------------------------------------------------------

create table if not exists public.staff_memberships (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  user_id uuid not null,
  party_id uuid references public.parties(id) on delete restrict,
  role_name text not null,
  membership_state text not null default 'active'
    check (membership_state in ('invited','active','disabled')),
  created_at timestamptz not null default now(),
  disabled_at timestamptz,
  unique (business_id, user_id)
);

create table if not exists public.staff_permission_snapshots (
  id uuid primary key default gen_random_uuid(),
  membership_id uuid not null references public.staff_memberships(id) on delete restrict,
  effective_from timestamptz not null,
  effective_to timestamptz,
  action_permissions jsonb not null default '{}'::jsonb,
  visibility jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  check (effective_to is null or effective_to > effective_from)
);

comment on table public.staff_permission_snapshots is
'Permission and visibility are stored separately. Action values are Allowed / Needs approval / Not allowed.';

create table if not exists public.approval_requests (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  requested_by_membership_id uuid not null references public.staff_memberships(id) on delete restrict,
  action_type text not null,
  target_type text,
  target_id uuid,
  request_payload jsonb not null default '{}'::jsonb,
  state text not null default 'pending'
    check (state in ('pending','approved','declined','expired','cancelled')),
  decided_by_membership_id uuid references public.staff_memberships(id) on delete restrict,
  decided_at timestamptz,
  created_at timestamptz not null default now()
);

comment on table public.approval_requests is
'Approval is authority, not execution. The approved action still creates its own explicit domain event.';


-- ---------------------------------------------------------------------------
-- 12. DOMAIN EVENT / SYNC AUDIT ENVELOPE
-- ---------------------------------------------------------------------------

create table if not exists public.domain_events (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  entity_type text not null,
  entity_id uuid not null,
  event_type text not null,
  occurred_at timestamptz not null,
  recorded_at timestamptz not null default now(),
  recorded_by_user_id uuid,
  device_id uuid,
  causation_id uuid references public.domain_events(id) on delete restrict,
  correlation_id uuid,
  payload jsonb not null default '{}'::jsonb
);

comment on table public.domain_events is
'Proposed append-only audit/sync envelope. Exact sync protocol is not frozen, but legitimate concurrent events must be preserved and conflicts exposed.';

create index if not exists idx_domain_events_business_recorded
  on public.domain_events(business_id, recorded_at);

create index if not exists idx_domain_events_entity
  on public.domain_events(entity_type, entity_id, occurred_at);


-- ---------------------------------------------------------------------------
-- 13. PROJECTION VIEWS
-- ---------------------------------------------------------------------------

create or replace view public.v_obligation_balances as
select
  o.id as obligation_id,
  o.business_id,
  o.tenancy_id,
  o.amount_minor,
  coalesce(sum(pa.amount_minor * pa.allocation_effect), 0)::bigint as net_allocated_minor,
  coalesce((
    select sum(fa.amount_minor)
    from public.financial_adjustments fa
    where fa.obligation_id = o.id
      and fa.adjustment_type in ('waiver','discount','write_off')
  ), 0)::bigint as net_adjustment_minor,
  coalesce((
    select sum(se.amount_minor)
    from public.security_events se
    where se.obligation_id = o.id
      and se.event_type = 'applied_to_dues'
  ), 0)::bigint as security_applied_minor,
  greatest(
    o.amount_minor
    - coalesce(sum(pa.amount_minor * pa.allocation_effect), 0)
    - coalesce((
        select sum(fa.amount_minor)
        from public.financial_adjustments fa
        where fa.obligation_id = o.id
          and fa.adjustment_type in ('waiver','discount','write_off')
      ), 0)
    - coalesce((
        select sum(se.amount_minor)
        from public.security_events se
        where se.obligation_id = o.id
          and se.event_type = 'applied_to_dues'
      ), 0),
    0
  )::bigint as outstanding_minor
from public.obligations o
left join public.payment_allocations pa on pa.obligation_id = o.id
group by o.id;

create or replace view public.v_security_balances as
select
  sa.id as security_account_id,
  sa.tenancy_id,
  sa.agreed_amount_minor,
  coalesce(sum(
    case se.event_type
      when 'deposit_received' then se.amount_minor
      when 'refund' then -se.amount_minor
      when 'applied_to_dues' then -se.amount_minor
      when 'correction' then se.amount_minor
      else 0
    end
  ),0)::bigint as held_amount_minor
from public.security_accounts sa
left join public.security_events se on se.security_account_id = sa.id
group by sa.id;

create or replace view public.v_tenancy_outstanding as
select
  t.id as tenancy_id,
  t.business_id,
  coalesce(sum(v.outstanding_minor), 0)::bigint as outstanding_minor
from public.tenancies t
left join public.v_obligation_balances v on v.tenancy_id = t.id
group by t.id;


-- ---------------------------------------------------------------------------
-- 14. PROPOSED GUARD TRIGGERS
-- ---------------------------------------------------------------------------

create or replace function public.prevent_update_delete_immutable_finance()
returns trigger
language plpgsql
as $$
begin
  raise exception '% is immutable; append a correction/reversal event instead', tg_table_name;
end;
$$;

drop trigger if exists trg_payment_events_immutable on public.payment_events;
create trigger trg_payment_events_immutable
before update or delete on public.payment_events
for each row execute function public.prevent_update_delete_immutable_finance();

drop trigger if exists trg_receipt_snapshots_immutable on public.receipt_snapshots;
create trigger trg_receipt_snapshots_immutable
before update or delete on public.receipt_snapshots
for each row execute function public.prevent_update_delete_immutable_finance();

drop trigger if exists trg_security_events_immutable on public.security_events;
create trigger trg_security_events_immutable
before update or delete on public.security_events
for each row execute function public.prevent_update_delete_immutable_finance();

drop trigger if exists trg_cash_custody_events_immutable on public.cash_custody_events;
create trigger trg_cash_custody_events_immutable
before update or delete on public.cash_custody_events
for each row execute function public.prevent_update_delete_immutable_finance();

drop trigger if exists trg_domain_events_immutable on public.domain_events;
create trigger trg_domain_events_immutable
before update or delete on public.domain_events
for each row execute function public.prevent_update_delete_immutable_finance();


-- ---------------------------------------------------------------------------
-- 15. RLS PLACEHOLDER
-- ---------------------------------------------------------------------------
-- RLS is intentionally not finalized here because the shared account/business
-- membership model and exact Supabase auth policy have not been frozen in the
-- cited PG product sources.
--
-- Recommended production rule:
--   1) enable RLS on every business-scoped table;
--   2) resolve access through business membership;
--   3) evaluate action permission separately from data visibility;
--   4) do not encode tier names in RLS; entitlements are separate capability gates.
--
-- Example (DO NOT APPLY AS FINAL POLICY):
-- alter table public.businesses enable row level security;


-- ---------------------------------------------------------------------------
-- 16. MIGRATION ORDER SUMMARY
-- ---------------------------------------------------------------------------
-- 001 businesses
-- 002 property_nodes, parties
-- 003 tenancies, tenancy_role_assignments, occupancy_assignments, rent_terms
-- 004 charges, obligations, financial_adjustments
-- 005 payment_events, payment_allocations, receipt_snapshots
-- 006 security_accounts, security_events, payment_promises
-- 007 expenses, cash_custody_events
-- 008 staff_memberships, staff_permission_snapshots, approval_requests
-- 009 domain_events
-- 010 projection views
-- 011 immutability triggers
-- 012 RLS after shared account/membership model is approved

commit;
