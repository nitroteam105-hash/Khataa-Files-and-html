-- Khaata PG / Hostel V1 — Supabase Change Feed v1
-- STATUS: PROPOSED IMPLEMENTATION MIGRATION. DO NOT APPLY WITHOUT REVIEW.
--
-- Purpose:
--   Provide the missing server-side pull stream consumed by the mobile PullCoordinator.
--
-- Design:
--   * monotonically increasing BIGINT cursor
--   * business-scoped feed rows
--   * append-only server change envelope
--   * typed payload builders per domain entity
--   * client fetches "after cursor"
--   * cursor has no business meaning; it is transport ordering only
--
-- The feed does not replace domain_events. domain_events remain business/audit truth.
-- sync_change_feed is a transport projection optimized for device synchronization.

begin;

create table if not exists public.sync_change_feed (
  cursor_id bigint generated always as identity primary key,
  remote_event_id uuid not null unique,
  business_id uuid not null references public.businesses(id) on delete restrict,
  entity_type text not null,
  entity_id uuid not null,
  change_type text not null
    check (change_type in ('insert','update','append_event','retire')),
  server_version bigint,
  payload jsonb not null,
  occurred_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists idx_sync_change_feed_business_cursor
  on public.sync_change_feed(business_id,cursor_id);

comment on table public.sync_change_feed is
'Server-to-device synchronization transport stream. Cursor ordering is transport-only and does not replace domain event/audit semantics.';

-- ============================================================================
-- VERSION BUMP HELPER
-- ============================================================================

create or replace function public.bump_server_record_version(
  p_business_id uuid,
  p_entity_type text,
  p_entity_id uuid
)
returns bigint
language plpgsql
security definer
set search_path=public
as $$
declare
  new_version bigint;
begin
  insert into public.server_record_versions(
    business_id,entity_type,entity_id,version,updated_at
  ) values (
    p_business_id,p_entity_type,p_entity_id,1,now()
  )
  on conflict (entity_type,entity_id)
  do update set
    version=public.server_record_versions.version+1,
    business_id=excluded.business_id,
    updated_at=excluded.updated_at
  returning version into new_version;

  return new_version;
end;
$$;

-- ============================================================================
-- FEED APPEND HELPER
-- ============================================================================

create or replace function public.append_sync_change(
  p_remote_event_id uuid,
  p_business_id uuid,
  p_entity_type text,
  p_entity_id uuid,
  p_change_type text,
  p_payload jsonb,
  p_occurred_at timestamptz default null,
  p_server_version bigint default null
)
returns bigint
language plpgsql
security definer
set search_path=public
as $$
declare
  v bigint;
  c bigint;
begin
  v := coalesce(
    p_server_version,
    public.bump_server_record_version(p_business_id,p_entity_type,p_entity_id)
  );

  insert into public.sync_change_feed(
    remote_event_id,business_id,entity_type,entity_id,change_type,
    server_version,payload,occurred_at
  ) values (
    p_remote_event_id,p_business_id,p_entity_type,p_entity_id,p_change_type,
    v,p_payload,p_occurred_at
  )
  on conflict (remote_event_id) do nothing
  returning cursor_id into c;

  if c is null then
    select cursor_id into c
    from public.sync_change_feed
    where remote_event_id=p_remote_event_id;
  end if;

  return c;
end;
$$;

-- ============================================================================
-- TYPED PUBLISHERS
-- These are called by typed domain RPCs after the server mutation succeeds.
-- ============================================================================

create or replace function public.publish_payment_change(
  p_payment_id uuid,
  p_remote_event_id uuid
)
returns void
language plpgsql
security definer
set search_path=public
as $$
declare
  pe public.payment_events%rowtype;
  b uuid;
begin
  select * into pe from public.payment_events where id=p_payment_id;
  if not found then raise exception 'PAYMENT_NOT_FOUND'; end if;
  b := pe.business_id;

  perform public.append_sync_change(
    p_remote_event_id,b,'payment_event',pe.id,'append_event',
    jsonb_build_object(
      'id',pe.id,
      'business_id',pe.business_id,
      'tenancy_id',pe.tenancy_id,
      'payer_party_id',pe.payer_party_id,
      'event_type',pe.event_type,
      'original_payment_id',pe.original_payment_id,
      'amount_minor',pe.amount_minor,
      'payment_method',pe.payment_method,
      'occurred_at',pe.occurred_at,
      'recorded_by_user_id',pe.recorded_by_user_id,
      'metadata',pe.metadata,
      'created_at',pe.created_at
    ),
    pe.occurred_at
  );
end;
$$;

create or replace function public.publish_receipt_change(
  p_receipt_id uuid,
  p_business_id uuid,
  p_remote_event_id uuid
)
returns void
language plpgsql
security definer
set search_path=public
as $$
declare
  r public.receipt_snapshots%rowtype;
begin
  select * into r from public.receipt_snapshots where id=p_receipt_id;
  if not found then raise exception 'RECEIPT_NOT_FOUND'; end if;

  perform public.append_sync_change(
    p_remote_event_id,p_business_id,'receipt_snapshot',r.id,'append_event',
    jsonb_build_object(
      'id',r.id,
      'payment_event_id',r.payment_event_id,
      'receipt_number',r.receipt_number,
      'snapshot',r.snapshot,
      'issued_at',r.issued_at,
      'created_at',r.created_at
    ),
    r.issued_at
  );
end;
$$;

create or replace function public.publish_occupancy_change(
  p_business_id uuid,
  p_occupancy_id uuid,
  p_remote_event_id uuid,
  p_change_type text
)
returns void
language plpgsql
security definer
set search_path=public
as $$
declare
  o public.occupancy_assignments%rowtype;
begin
  select * into o from public.occupancy_assignments where id=p_occupancy_id;
  if not found then raise exception 'OCCUPANCY_NOT_FOUND'; end if;

  perform public.append_sync_change(
    p_remote_event_id,p_business_id,'occupancy_assignment',o.id,p_change_type,
    jsonb_build_object(
      'id',o.id,
      'tenancy_id',o.tenancy_id,
      'capacity_id',o.capacity_id,
      'assignment_state',o.assignment_state,
      'start_at',o.start_at,
      'end_at',o.end_at,
      'created_at',o.created_at
    ),
    coalesce(o.start_at,o.end_at,now())
  );
end;
$$;

create or replace function public.publish_tenancy_change(
  p_tenancy_id uuid,
  p_remote_event_id uuid,
  p_change_type text
)
returns void
language plpgsql
security definer
set search_path=public
as $$
declare
  t public.tenancies%rowtype;
begin
  select * into t from public.tenancies where id=p_tenancy_id;
  if not found then raise exception 'TENANCY_NOT_FOUND'; end if;

  perform public.append_sync_change(
    p_remote_event_id,t.business_id,'tenancy',t.id,p_change_type,
    to_jsonb(t),
    coalesce(t.ended_at,t.updated_at,t.created_at)
  );
end;
$$;

create or replace function public.publish_security_event_change(
  p_business_id uuid,
  p_security_event_id uuid,
  p_remote_event_id uuid
)
returns void
language plpgsql
security definer
set search_path=public
as $$
declare
  s public.security_events%rowtype;
begin
  select * into s from public.security_events where id=p_security_event_id;
  if not found then raise exception 'SECURITY_EVENT_NOT_FOUND'; end if;

  perform public.append_sync_change(
    p_remote_event_id,p_business_id,'security_event',s.id,'append_event',
    to_jsonb(s),s.occurred_at
  );
end;
$$;

create or replace function public.publish_cash_custody_change(
  p_event_id uuid,
  p_remote_event_id uuid
)
returns void
language plpgsql
security definer
set search_path=public
as $$
declare
  c public.cash_custody_events%rowtype;
begin
  select * into c from public.cash_custody_events where id=p_event_id;
  if not found then raise exception 'CASH_CUSTODY_EVENT_NOT_FOUND'; end if;

  perform public.append_sync_change(
    p_remote_event_id,c.business_id,'cash_custody_event',c.id,'append_event',
    to_jsonb(c),c.occurred_at
  );
end;
$$;

-- ============================================================================
-- FETCH RPC
-- ============================================================================

create or replace function public.pg_fetch_changes(
  p_business_id uuid,
  p_after_cursor bigint default 0,
  p_limit integer default 100
)
returns table (
  cursor_id bigint,
  remote_event_id uuid,
  business_id uuid,
  entity_type text,
  entity_id uuid,
  change_type text,
  server_version bigint,
  payload jsonb,
  occurred_at timestamptz,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path=public
as $$
begin
  if not public.has_business_access(p_business_id) then
    raise exception 'BUSINESS_ACCESS_DENIED';
  end if;

  if not public.has_entitlement('cloud_sync') then
    raise exception 'ENTITLEMENT_CLOUD_SYNC_REQUIRED';
  end if;

  return query
  select
    f.cursor_id,
    f.remote_event_id,
    f.business_id,
    f.entity_type,
    f.entity_id,
    f.change_type,
    f.server_version,
    f.payload,
    f.occurred_at,
    f.created_at
  from public.sync_change_feed f
  where f.business_id=p_business_id
    and f.cursor_id>coalesce(p_after_cursor,0)
  order by f.cursor_id asc
  limit greatest(1,least(coalesce(p_limit,100),500));
end;
$$;

revoke all on function public.pg_fetch_changes(uuid,bigint,integer) from public;
grant execute on function public.pg_fetch_changes(uuid,bigint,integer) to authenticated;

-- ============================================================================
-- PUBLISHING CONTRACT
-- ============================================================================
--
-- Typed domain RPCs must publish change-feed rows in the SAME server transaction
-- as the domain mutation. If publication fails, the RPC rolls back.
--
-- Suggested mapping:
--
-- pg_record_payment
--   payment_event
--   each payment_allocation
--   receipt_snapshot
--   optional cash_custody_event
--
-- pg_reverse_payment
--   reversal payment_event
--   each negative payment_allocation
--
-- pg_transfer_room
--   old occupancy_assignment update
--   new occupancy_assignment insert
--
-- pg_apply_security_to_dues
--   security_event
--
-- pg_refund_security
--   security_event
--
-- pg_handover_cash
--   handover cash_custody_event
--   optional discrepancy cash_custody_event
--
-- pg_end_tenancy
--   tenancy update
--   occupancy_assignment update
--
-- Domain/audit events may also be published if mobile history screens require them.
--
-- Do not rely on database-wide generic row triggers for every table because
-- Khaata requires typed payloads, deliberate event classes, and stable semantics.

commit;
