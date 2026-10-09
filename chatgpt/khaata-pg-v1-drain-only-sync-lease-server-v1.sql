-- Khaata PG / Hostel V1 — Drain-only Sync Lease Server v1
-- STATUS: PROPOSED IMPLEMENTATION CONTRACT. DO NOT APPLY WITHOUT REVIEW.
--
-- Product requirements preserved:
--   ENT-25: device keeps a last-verified entitlement snapshot.
--   ENT-26: offline grace length is server-configurable.
--   ENT-27: grace expiry is anchored to verified server time, not device wall clock.
--   ENT-29: after grace, future gated capability falls back.
--   ENT-30: already-legitimate outbound events must always be allowed to drain.
--
-- Security position for V1:
--   We use a server-issued signed/opaque lease identifier plus device-bound
--   operation provenance. This prevents simple client booleans from authorizing
--   drain. It does NOT claim perfect cryptographic proof of real-world event time
--   on a fully compromised/rooted device.
--
--   If the local monotonic clock continuity is lost (e.g. reboot) and the app
--   cannot safely reconstruct verified-server-relative time, future paid-only
--   writes should stop until verification returns. Already-created outbox rows
--   keep their recorded lease provenance and may still drain.

begin;

-- ============================================================================
-- 1. ENTITLEMENT LEASES
-- ============================================================================

create table if not exists public.entitlement_leases (
  id uuid primary key,
  account_user_id uuid not null,
  device_id uuid not null,
  issued_at_server timestamptz not null,
  verified_at_server timestamptz not null,
  grace_expires_at timestamptz not null,
  effective_entitlements text[] not null default '{}',
  config_version text,
  lease_state text not null default 'active'
    check (lease_state in ('active','superseded','revoked')),
  created_at timestamptz not null default now()
);

create index if not exists idx_entitlement_leases_account_device
  on public.entitlement_leases(account_user_id,device_id,verified_at_server desc);

comment on table public.entitlement_leases is
'Server-issued entitlement lease used to anchor offline grace and later drain-only validation.';

-- ============================================================================
-- 2. DEVICE REGISTRATION
-- ============================================================================

create table if not exists public.sync_devices (
  device_id uuid primary key,
  account_user_id uuid not null,
  public_key_fingerprint text,
  registered_at timestamptz not null default now(),
  last_seen_at timestamptz,
  device_state text not null default 'active'
    check (device_state in ('active','revoked'))
);

-- public_key_fingerprint is intentionally optional in this proposal.
-- A production native build may bind operations to a hardware/OS-backed device
-- signing key. The exact keystore implementation is platform-specific.

-- ============================================================================
-- 3. OUTBOUND PROVENANCE REGISTER
-- ============================================================================

create table if not exists public.sync_operation_provenance (
  operation_id uuid primary key,
  account_user_id uuid not null,
  business_id uuid not null references public.businesses(id) on delete restrict,
  device_id uuid not null,
  lease_id uuid not null references public.entitlement_leases(id) on delete restrict,
  required_entitlement text not null,
  local_sequence bigint not null check (local_sequence > 0),
  previous_operation_hash text,
  operation_hash text not null,
  effective_server_time_at_creation timestamptz not null,
  client_created_at timestamptz,
  first_received_at timestamptz not null default now(),
  drain_eligible boolean not null default false,
  validation_state text not null
    check (validation_state in ('accepted_normal','accepted_drain','rejected','conflict')),
  validation_note text
);

create unique index if not exists uq_sync_provenance_device_sequence
  on public.sync_operation_provenance(device_id,lease_id,local_sequence);

-- ============================================================================
-- 4. ISSUE / REFRESH LEASE
-- ============================================================================

create or replace function public.issue_entitlement_lease(
  p_device_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  entitlement_row public.account_entitlement_snapshots%rowtype;
  lease_id uuid := gen_random_uuid();
  grace_interval interval;
  grace_days integer := 14; -- fallback only; production reads server config.
  result jsonb;
begin
  select * into entitlement_row
  from public.account_entitlement_snapshots
  where account_user_id=auth.uid();

  if not found then
    raise exception 'ENTITLEMENT_SNAPSHOT_NOT_FOUND';
  end if;

  insert into public.sync_devices(device_id,account_user_id,last_seen_at)
  values (p_device_id,auth.uid(),now())
  on conflict (device_id) do update
    set last_seen_at=excluded.last_seen_at
    where public.sync_devices.account_user_id=auth.uid();

  grace_interval := make_interval(days=>grace_days);

  update public.entitlement_leases
  set lease_state='superseded'
  where account_user_id=auth.uid()
    and device_id=p_device_id
    and lease_state='active';

  insert into public.entitlement_leases(
    id,account_user_id,device_id,issued_at_server,verified_at_server,
    grace_expires_at,effective_entitlements,config_version
  ) values (
    lease_id,auth.uid(),p_device_id,now(),now(),
    now()+grace_interval,
    entitlement_row.effective_entitlements,
    entitlement_row.config_version
  );

  result := jsonb_build_object(
    'lease_id',lease_id,
    'device_id',p_device_id,
    'verified_server_time',now(),
    'grace_expires_at',now()+grace_interval,
    'effective_entitlements',to_jsonb(entitlement_row.effective_entitlements),
    'config_version',entitlement_row.config_version
  );

  return result;
end;
$$;

-- ============================================================================
-- 5. VALIDATE NORMAL OR DRAIN-ONLY OPERATION
-- ============================================================================

create or replace function public.validate_sync_operation_lease(
  p_operation_id uuid,
  p_business_id uuid,
  p_device_id uuid,
  p_lease_id uuid,
  p_required_entitlement text,
  p_local_sequence bigint,
  p_previous_operation_hash text,
  p_operation_hash text,
  p_effective_server_time_at_creation timestamptz,
  p_client_created_at timestamptz default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  lease public.entitlement_leases%rowtype;
  prior public.sync_operation_provenance%rowtype;
  normal_entitled boolean;
  lease_entitled boolean;
  within_grace boolean;
  expected_prev text;
  accepted_state text;
  is_drain boolean := false;
  result jsonb;
begin
  select * into prior
  from public.sync_operation_provenance
  where operation_id=p_operation_id;

  if found then
    return jsonb_build_object(
      'state',prior.validation_state,
      'drain_eligible',prior.drain_eligible,
      'operation_id',prior.operation_id
    );
  end if;

  if not public.has_business_access(p_business_id) then
    raise exception 'BUSINESS_ACCESS_DENIED';
  end if;

  select * into lease
  from public.entitlement_leases
  where id=p_lease_id
    and account_user_id=auth.uid()
    and device_id=p_device_id;

  if not found then
    raise exception 'LEASE_NOT_FOUND';
  end if;

  if exists (
    select 1 from public.sync_devices d
    where d.device_id=p_device_id
      and d.account_user_id=auth.uid()
      and d.device_state='revoked'
  ) then
    raise exception 'DEVICE_REVOKED';
  end if;

  lease_entitled := p_required_entitlement = any(lease.effective_entitlements);

  if not lease_entitled then
    raise exception 'LEASE_DID_NOT_INCLUDE_ENTITLEMENT';
  end if;

  if p_effective_server_time_at_creation < lease.verified_at_server then
    raise exception 'OPERATION_TIME_BEFORE_LEASE';
  end if;

  within_grace := p_effective_server_time_at_creation <= lease.grace_expires_at;
  if not within_grace then
    raise exception 'OPERATION_CREATED_AFTER_GRACE';
  end if;

  -- Optional append-chain continuity. This catches accidental/casual tampering
  -- and missing outbox operations. It is not presented as secure proof against
  -- a fully compromised device.
  select operation_hash into expected_prev
  from public.sync_operation_provenance
  where device_id=p_device_id
    and lease_id=p_lease_id
    and local_sequence=p_local_sequence-1;

  if p_local_sequence>1 and expected_prev is not null
     and p_previous_operation_hash is distinct from expected_prev then
    raise exception 'OUTBOX_HASH_CHAIN_MISMATCH';
  end if;

  normal_entitled := public.has_entitlement(p_required_entitlement);

  if normal_entitled then
    accepted_state := 'accepted_normal';
  else
    -- ENT-30: current entitlement is gone, but the lease proves this device had
    -- the entitlement and the operation claims a creation point within the lease
    -- grace window. It may drain; no future gated capability is restored.
    accepted_state := 'accepted_drain';
    is_drain := true;
  end if;

  insert into public.sync_operation_provenance(
    operation_id,account_user_id,business_id,device_id,lease_id,
    required_entitlement,local_sequence,previous_operation_hash,operation_hash,
    effective_server_time_at_creation,client_created_at,drain_eligible,
    validation_state,validation_note
  ) values (
    p_operation_id,auth.uid(),p_business_id,p_device_id,p_lease_id,
    p_required_entitlement,p_local_sequence,p_previous_operation_hash,p_operation_hash,
    p_effective_server_time_at_creation,p_client_created_at,is_drain,
    accepted_state,
    case when is_drain then 'ENT-30 drain-only acceptance' else 'normal entitlement acceptance' end
  );

  result := jsonb_build_object(
    'state',accepted_state,
    'drain_only',is_drain,
    'operation_id',p_operation_id,
    'lease_id',p_lease_id
  );

  return result;
end;
$$;

-- ============================================================================
-- 6. PRODUCTION LIMITATIONS / NON-CLAIMS
-- ============================================================================
--
-- This design deliberately does NOT trust:
--   * device wall-clock alone,
--   * a boolean "recorded_while_entitled",
--   * client tier names,
--   * client-side entitlement calculation.
--
-- The mobile app derives effective server-relative time as:
--
--   verified_server_time + elapsed_monotonic_since_verification
--
-- If monotonic continuity becomes unreliable, future paid-only offline writes
-- must stop until the server is reached again.
--
-- IMPORTANT THREAT-MODEL LIMIT:
-- A rooted/fully compromised client may still forge its local sequence/time
-- inputs before submitting them. Hardware-backed signing can raise the bar but
-- cannot universally prove human-world event time on commodity phones.
--
-- Therefore:
--   * This V1 lease is adequate for correctness + casual clock-tampering defense.
--   * It is NOT represented as high-assurance forensic timestamping.
--   * Server domain invariants, idempotency, account/device revocation and audit
--     history remain mandatory even for drain-only uploads.
--
-- ENT-30 remains a product guarantee: do not strand already-recorded legitimate
-- outbound events merely because current entitlement is absent.

revoke all on function public.issue_entitlement_lease(uuid) from public;
grant execute on function public.issue_entitlement_lease(uuid) to authenticated;

revoke all on function public.validate_sync_operation_lease(
  uuid,uuid,uuid,uuid,text,bigint,text,text,timestamptz,timestamptz
) from public;
grant execute on function public.validate_sync_operation_lease(
  uuid,uuid,uuid,uuid,text,bigint,text,text,timestamptz,timestamptz
) to authenticated;

commit;
