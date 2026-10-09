-- Khaata PG / Hostel V1 — Change Feed Integration v1
-- STATUS: PROPOSED IMPLEMENTATION MIGRATION. DO NOT APPLY WITHOUT REVIEW.
--
-- Connects existing typed domain writes to sync_change_feed.
--
-- Integration choice:
--   use narrow, typed table triggers for the domain rows that participate in
--   cross-device sync. These are NOT generic "serialize any row" triggers.
--   Each trigger explicitly constructs the transport payload for one entity type.
--
-- Why this integration form:
--   * publication is in the SAME PostgreSQL transaction as the domain mutation
--   * no typed RPC can accidentally forget to publish a dependent row
--   * direct internal/server mutations of these tables also become visible
--   * feed semantics stay explicit and reviewable
--
-- Domain/audit truth remains in domain tables/domain_events.
-- sync_change_feed remains transport-only.

begin;

-- ============================================================================
-- 1. PAYMENT EVENT — INSERT ONLY
-- ============================================================================

create or replace function public.trg_publish_payment_event()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
begin
  perform public.append_sync_change(
    gen_random_uuid(),
    new.business_id,
    'payment_event',
    new.id,
    'append_event',
    jsonb_build_object(
      'id',new.id,
      'business_id',new.business_id,
      'tenancy_id',new.tenancy_id,
      'payer_party_id',new.payer_party_id,
      'event_type',new.event_type,
      'original_payment_id',new.original_payment_id,
      'amount_minor',new.amount_minor,
      'payment_method',new.payment_method,
      'occurred_at',new.occurred_at,
      'recorded_by_user_id',new.recorded_by_user_id,
      'metadata',new.metadata,
      'created_at',new.created_at
    ),
    new.occurred_at
  );
  return new;
end;
$$;

drop trigger if exists publish_payment_event_to_sync_feed on public.payment_events;
create trigger publish_payment_event_to_sync_feed
after insert on public.payment_events
for each row execute function public.trg_publish_payment_event();

-- ============================================================================
-- 2. PAYMENT ALLOCATION — INSERT ONLY
-- Derive business from payment event.
-- ============================================================================

create or replace function public.trg_publish_payment_allocation()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
declare
  b uuid;
  occurred timestamptz;
begin
  select pe.business_id,pe.occurred_at into b,occurred
  from public.payment_events pe
  where pe.id=new.payment_event_id;

  if b is null then raise exception 'PAYMENT_BUSINESS_NOT_FOUND'; end if;

  perform public.append_sync_change(
    gen_random_uuid(),
    b,
    'payment_allocation',
    new.id,
    'append_event',
    jsonb_build_object(
      'id',new.id,
      'payment_event_id',new.payment_event_id,
      'obligation_id',new.obligation_id,
      'amount_minor',new.amount_minor,
      'allocation_effect',new.allocation_effect,
      'created_at',new.created_at
    ),
    occurred
  );
  return new;
end;
$$;

drop trigger if exists publish_payment_allocation_to_sync_feed on public.payment_allocations;
create trigger publish_payment_allocation_to_sync_feed
after insert on public.payment_allocations
for each row execute function public.trg_publish_payment_allocation();

-- ============================================================================
-- 3. RECEIPT SNAPSHOT — INSERT ONLY
-- Derive business through payment event.
-- ============================================================================

create or replace function public.trg_publish_receipt_snapshot()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
declare
  b uuid;
begin
  select pe.business_id into b
  from public.payment_events pe
  where pe.id=new.payment_event_id;

  if b is null then raise exception 'RECEIPT_BUSINESS_NOT_FOUND'; end if;

  perform public.append_sync_change(
    gen_random_uuid(),
    b,
    'receipt_snapshot',
    new.id,
    'append_event',
    jsonb_build_object(
      'id',new.id,
      'payment_event_id',new.payment_event_id,
      'receipt_number',new.receipt_number,
      'snapshot',new.snapshot,
      'issued_at',new.issued_at,
      'created_at',new.created_at
    ),
    new.issued_at
  );
  return new;
end;
$$;

drop trigger if exists publish_receipt_snapshot_to_sync_feed on public.receipt_snapshots;
create trigger publish_receipt_snapshot_to_sync_feed
after insert on public.receipt_snapshots
for each row execute function public.trg_publish_receipt_snapshot();

-- ============================================================================
-- 4. SECURITY EVENT — INSERT ONLY
-- Derive business through account → tenancy.
-- ============================================================================

create or replace function public.trg_publish_security_event()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
declare
  b uuid;
begin
  select t.business_id into b
  from public.security_accounts sa
  join public.tenancies t on t.id=sa.tenancy_id
  where sa.id=new.security_account_id;

  if b is null then raise exception 'SECURITY_BUSINESS_NOT_FOUND'; end if;

  perform public.append_sync_change(
    gen_random_uuid(),
    b,
    'security_event',
    new.id,
    'append_event',
    to_jsonb(new),
    new.occurred_at
  );
  return new;
end;
$$;

drop trigger if exists publish_security_event_to_sync_feed on public.security_events;
create trigger publish_security_event_to_sync_feed
after insert on public.security_events
for each row execute function public.trg_publish_security_event();

-- ============================================================================
-- 5. CASH CUSTODY — INSERT ONLY
-- ============================================================================

create or replace function public.trg_publish_cash_custody_event()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
begin
  perform public.append_sync_change(
    gen_random_uuid(),
    new.business_id,
    'cash_custody_event',
    new.id,
    'append_event',
    to_jsonb(new),
    new.occurred_at
  );
  return new;
end;
$$;

drop trigger if exists publish_cash_custody_to_sync_feed on public.cash_custody_events;
create trigger publish_cash_custody_to_sync_feed
after insert on public.cash_custody_events
for each row execute function public.trg_publish_cash_custody_event();

-- ============================================================================
-- 6. OCCUPANCY — INSERT + UPDATE
-- Business derives through tenancy.
-- ============================================================================

create or replace function public.trg_publish_occupancy_assignment()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
declare
  b uuid;
  ch text;
begin
  select t.business_id into b
  from public.tenancies t
  where t.id=new.tenancy_id;

  if b is null then raise exception 'OCCUPANCY_BUSINESS_NOT_FOUND'; end if;
  ch := case when tg_op='INSERT' then 'insert' else 'update' end;

  perform public.append_sync_change(
    gen_random_uuid(),
    b,
    'occupancy_assignment',
    new.id,
    ch,
    jsonb_build_object(
      'id',new.id,
      'tenancy_id',new.tenancy_id,
      'capacity_id',new.capacity_id,
      'assignment_state',new.assignment_state,
      'start_at',new.start_at,
      'end_at',new.end_at,
      'created_at',new.created_at
    ),
    coalesce(new.start_at,new.end_at,now())
  );
  return new;
end;
$$;

drop trigger if exists publish_occupancy_to_sync_feed on public.occupancy_assignments;
create trigger publish_occupancy_to_sync_feed
after insert or update on public.occupancy_assignments
for each row execute function public.trg_publish_occupancy_assignment();

-- ============================================================================
-- 7. TENANCY — INSERT + UPDATE
-- ============================================================================

create or replace function public.trg_publish_tenancy()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
declare
  ch text;
begin
  ch := case when tg_op='INSERT' then 'insert' else 'update' end;

  perform public.append_sync_change(
    gen_random_uuid(),
    new.business_id,
    'tenancy',
    new.id,
    ch,
    to_jsonb(new),
    coalesce(new.ended_at,new.updated_at,new.created_at)
  );
  return new;
end;
$$;

drop trigger if exists publish_tenancy_to_sync_feed on public.tenancies;
create trigger publish_tenancy_to_sync_feed
after insert or update on public.tenancies
for each row execute function public.trg_publish_tenancy();

-- ============================================================================
-- 8. RENT TERM — INSERT + UPDATE
-- ============================================================================

create or replace function public.trg_publish_rent_term()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
declare
  b uuid;
  ch text;
begin
  select t.business_id into b from public.tenancies t where t.id=new.tenancy_id;
  if b is null then raise exception 'RENT_TERM_BUSINESS_NOT_FOUND'; end if;

  ch := case when tg_op='INSERT' then 'insert' else 'update' end;

  perform public.append_sync_change(
    gen_random_uuid(),
    b,
    'rent_term',
    new.id,
    ch,
    to_jsonb(new),
    now()
  );
  return new;
end;
$$;

drop trigger if exists publish_rent_term_to_sync_feed on public.rent_terms;
create trigger publish_rent_term_to_sync_feed
after insert or update on public.rent_terms
for each row execute function public.trg_publish_rent_term();

-- ============================================================================
-- 9. DOMAIN EVENTS — INSERT ONLY
-- Optional but useful for remote audit/history surfaces.
-- ============================================================================

create or replace function public.trg_publish_domain_event()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
begin
  perform public.append_sync_change(
    gen_random_uuid(),
    new.business_id,
    'domain_event',
    new.id,
    'append_event',
    jsonb_build_object(
      'id',new.id,
      'business_id',new.business_id,
      'entity_type',new.entity_type,
      'entity_id',new.entity_id,
      'event_type',new.event_type,
      'occurred_at',new.occurred_at,
      'recorded_at',new.recorded_at,
      'recorded_by_user_id',new.recorded_by_user_id,
      'device_id',new.device_id,
      'payload',new.payload
    ),
    new.occurred_at
  );
  return new;
end;
$$;

drop trigger if exists publish_domain_event_to_sync_feed on public.domain_events;
create trigger publish_domain_event_to_sync_feed
after insert on public.domain_events
for each row execute function public.trg_publish_domain_event();

-- ============================================================================
-- 10. IMMUTABILITY HARDENING FOR PAYMENT ALLOCATIONS
-- The original schema intended allocation effects to be append-only.
-- ============================================================================

create or replace function public.reject_payment_allocation_mutation()
returns trigger
language plpgsql
as $$
begin
  raise exception 'payment_allocations are append-only';
end;
$$;

drop trigger if exists immutable_payment_allocations_update on public.payment_allocations;
create trigger immutable_payment_allocations_update
before update on public.payment_allocations
for each row execute function public.reject_payment_allocation_mutation();

drop trigger if exists immutable_payment_allocations_delete on public.payment_allocations;
create trigger immutable_payment_allocations_delete
before delete on public.payment_allocations
for each row execute function public.reject_payment_allocation_mutation();

-- ============================================================================
-- 11. GUARANTEE
-- ============================================================================
--
-- Existing typed RPCs now publish automatically because the feed append occurs
-- from the same table mutations they perform.
--
-- Examples:
--   pg_record_payment:
--     payment insert       -> payment_event feed
--     allocation inserts   -> payment_allocation feed rows
--     receipt insert       -> receipt feed
--     optional custody     -> custody feed
--     domain event insert  -> audit feed
--
--   pg_transfer_room:
--     old occupancy update -> occupancy update feed
--     new occupancy insert -> occupancy insert feed
--
--   pg_end_tenancy:
--     occupancy update     -> occupancy feed
--     tenancy update       -> tenancy feed
--     domain event         -> audit feed
--
-- If any feed trigger fails, PostgreSQL aborts the same transaction, so a
-- committed domain mutation cannot silently become invisible to other devices.

commit;
