-- Khaata PG / Hostel V1 — Supabase Approval Orchestration v1
-- STATUS: PROPOSED IMPLEMENTATION MIGRATION. DO NOT APPLY WITHOUT REVIEW.
--
-- Server counterpart to local Approval Orchestration v1.
--
-- Core invariant:
--   request approval != approve/decline != execute protected action
--
-- Approval grants a one-use authorization. The protected typed domain RPC must
-- still execute separately and atomically consume that authorization.

begin;

-- ============================================================================
-- 1. APPROVAL REQUEST HARDENING
-- ============================================================================

alter table public.approval_requests
  add column if not exists request_key text,
  add column if not exists requested_by_user_id uuid,
  add column if not exists decided_by_user_id uuid;

create unique index if not exists uq_approval_request_key
  on public.approval_requests(business_id,request_key)
  where request_key is not null;

create index if not exists idx_approval_requests_pending
  on public.approval_requests(business_id,state,created_at);

-- Owner may not have a staff membership. Membership attribution is therefore
-- optional for decisions; user identity is canonical.
alter table public.approval_requests
  alter column decided_by_membership_id drop not null;

-- ============================================================================
-- 2. APPROVAL DECISION HISTORY
-- ============================================================================

create table if not exists public.approval_decision_events (
  id uuid primary key,
  business_id uuid not null references public.businesses(id) on delete restrict,
  approval_request_id uuid not null references public.approval_requests(id) on delete restrict,
  decision text not null check (decision in ('approved','declined')),
  decided_by_user_id uuid not null,
  decided_by_membership_id uuid references public.staff_memberships(id) on delete restrict,
  decided_at timestamptz not null,
  note text,
  created_at timestamptz not null default now()
);

create or replace function public.reject_approval_decision_mutation()
returns trigger
language plpgsql
as $$
begin
  raise exception 'approval_decision_events are append-only';
end;
$$;

drop trigger if exists approval_decision_no_update on public.approval_decision_events;
create trigger approval_decision_no_update
before update on public.approval_decision_events
for each row execute function public.reject_approval_decision_mutation();

drop trigger if exists approval_decision_no_delete on public.approval_decision_events;
create trigger approval_decision_no_delete
before delete on public.approval_decision_events
for each row execute function public.reject_approval_decision_mutation();

-- ============================================================================
-- 3. APPROVER AUTHORITY
-- ============================================================================

create or replace function public.can_approve_requests(p_business_id uuid)
returns boolean
language plpgsql
stable
security definer
set search_path=public
as $$
declare
  owner_id uuid;
  permission text;
begin
  select owner_user_id into owner_id
  from public.businesses
  where id=p_business_id;

  if owner_id=auth.uid() then
    return true;
  end if;

  if public.active_membership_id(p_business_id) is null then
    return false;
  end if;

  permission := public.current_action_permission(p_business_id,'approve_requests');

  -- Approving requests is itself an authority; it cannot recurse into
  -- "needs approval".
  return permission='allowed';
end;
$$;

-- ============================================================================
-- 4. CREATE / REUSE APPROVAL REQUEST
-- ============================================================================

create or replace function public.pg_request_approval(
  p_operation_id uuid,
  p_business_id uuid,
  p_device_id uuid,
  p_approval_request_id uuid,
  p_request_key text,
  p_action_type text,
  p_target_type text default null,
  p_target_id uuid default null,
  p_request_payload jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  prior jsonb;
  existing public.approval_requests%rowtype;
  membership_id uuid;
  permission text;
  result jsonb;
begin
  prior := public.pg_get_prior_sync_result(p_operation_id);
  if prior is not null then return prior; end if;

  if not public.has_business_access(p_business_id) then
    raise exception 'BUSINESS_ACCESS_DENIED';
  end if;

  permission := public.current_action_permission(p_business_id,p_action_type);

  if permission='not_allowed' then
    raise exception 'ACTION_NOT_ALLOWED';
  end if;

  if permission='allowed' then
    raise exception 'APPROVAL_NOT_REQUIRED';
  end if;

  if coalesce(trim(p_request_key),'')='' then
    raise exception 'REQUEST_KEY_REQUIRED';
  end if;

  select * into existing
  from public.approval_requests
  where business_id=p_business_id
    and request_key=p_request_key;

  if found then
    result := jsonb_build_object(
      'state','approval_required',
      'approval_request_id',existing.id,
      'request_state',existing.state
    );

    perform public.pg_register_sync_result(
      p_operation_id,p_business_id,p_device_id,'approval_request',existing.id,
      'request_approval','accepted',result
    );

    return result;
  end if;

  membership_id := public.active_membership_id(p_business_id);

  insert into public.approval_requests(
    id,business_id,requested_by_membership_id,requested_by_user_id,
    action_type,target_type,target_id,request_payload,state,request_key,created_at
  ) values (
    p_approval_request_id,p_business_id,membership_id,auth.uid(),
    p_action_type,p_target_type,p_target_id,coalesce(p_request_payload,'{}'::jsonb),
    'pending',p_request_key,now()
  );

  result := jsonb_build_object(
    'state','approval_required',
    'approval_request_id',p_approval_request_id,
    'request_state','pending'
  );

  perform public.pg_register_sync_result(
    p_operation_id,p_business_id,p_device_id,'approval_request',p_approval_request_id,
    'request_approval','accepted',result
  );

  return result;
end;
$$;

-- ============================================================================
-- 5. APPROVE
-- ============================================================================

create or replace function public.pg_approve_request(
  p_operation_id uuid,
  p_business_id uuid,
  p_device_id uuid,
  p_approval_request_id uuid,
  p_authorization_id uuid,
  p_decision_event_id uuid,
  p_expires_at timestamptz default null,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  prior jsonb;
  req public.approval_requests%rowtype;
  approver_membership uuid;
  result jsonb;
begin
  prior := public.pg_get_prior_sync_result(p_operation_id);
  if prior is not null then return prior; end if;

  if not public.can_approve_requests(p_business_id) then
    raise exception 'NOT_APPROVER';
  end if;

  select * into req
  from public.approval_requests
  where id=p_approval_request_id
    and business_id=p_business_id
  for update;

  if not found then raise exception 'APPROVAL_REQUEST_NOT_FOUND'; end if;
  if req.state<>'pending' then raise exception 'APPROVAL_NOT_PENDING'; end if;

  approver_membership := public.active_membership_id(p_business_id);

  update public.approval_requests
  set state='approved',
      decided_by_user_id=auth.uid(),
      decided_by_membership_id=approver_membership,
      decided_at=now()
  where id=p_approval_request_id;

  insert into public.approval_authorizations(
    id,approval_request_id,business_id,action_type,target_type,target_id,
    authorized_for_user_id,approved_by_user_id,approved_at,expires_at,created_at
  ) values (
    p_authorization_id,p_approval_request_id,p_business_id,req.action_type,
    req.target_type,req.target_id,req.requested_by_user_id,auth.uid(),now(),
    p_expires_at,now()
  );

  insert into public.approval_decision_events(
    id,business_id,approval_request_id,decision,decided_by_user_id,
    decided_by_membership_id,decided_at,note
  ) values (
    p_decision_event_id,p_business_id,p_approval_request_id,'approved',auth.uid(),
    approver_membership,now(),p_note
  );

  result := jsonb_build_object(
    'state','approved',
    'approval_request_id',p_approval_request_id,
    'authorization_id',p_authorization_id
  );

  perform public.pg_register_sync_result(
    p_operation_id,p_business_id,p_device_id,'approval_request',p_approval_request_id,
    'approve_request','accepted',result
  );

  return result;
end;
$$;

-- ============================================================================
-- 6. DECLINE
-- ============================================================================

create or replace function public.pg_decline_request(
  p_operation_id uuid,
  p_business_id uuid,
  p_device_id uuid,
  p_approval_request_id uuid,
  p_decision_event_id uuid,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  prior jsonb;
  req public.approval_requests%rowtype;
  approver_membership uuid;
  result jsonb;
begin
  prior := public.pg_get_prior_sync_result(p_operation_id);
  if prior is not null then return prior; end if;

  if not public.can_approve_requests(p_business_id) then
    raise exception 'NOT_APPROVER';
  end if;

  select * into req
  from public.approval_requests
  where id=p_approval_request_id
    and business_id=p_business_id
  for update;

  if not found then raise exception 'APPROVAL_REQUEST_NOT_FOUND'; end if;
  if req.state<>'pending' then raise exception 'APPROVAL_NOT_PENDING'; end if;

  approver_membership := public.active_membership_id(p_business_id);

  update public.approval_requests
  set state='declined',
      decided_by_user_id=auth.uid(),
      decided_by_membership_id=approver_membership,
      decided_at=now()
  where id=p_approval_request_id;

  insert into public.approval_decision_events(
    id,business_id,approval_request_id,decision,decided_by_user_id,
    decided_by_membership_id,decided_at,note
  ) values (
    p_decision_event_id,p_business_id,p_approval_request_id,'declined',auth.uid(),
    approver_membership,now(),p_note
  );

  result := jsonb_build_object(
    'state','declined',
    'approval_request_id',p_approval_request_id
  );

  perform public.pg_register_sync_result(
    p_operation_id,p_business_id,p_device_id,'approval_request',p_approval_request_id,
    'decline_request','accepted',result
  );

  return result;
end;
$$;

-- ============================================================================
-- 7. CHANGE FEED
-- ============================================================================

create or replace function public.trg_publish_approval_request()
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
    gen_random_uuid(),new.business_id,'approval_request',new.id,ch,
    jsonb_build_object(
      'id',new.id,
      'business_id',new.business_id,
      'requested_by_membership_id',new.requested_by_membership_id,
      'requested_by_user_id',new.requested_by_user_id,
      'action_type',new.action_type,
      'target_type',new.target_type,
      'target_id',new.target_id,
      'request_payload',new.request_payload,
      'state',new.state,
      'request_key',new.request_key,
      'decided_by_membership_id',new.decided_by_membership_id,
      'decided_by_user_id',new.decided_by_user_id,
      'decided_at',new.decided_at,
      'created_at',new.created_at
    ),
    coalesce(new.decided_at,new.created_at)
  );
  return new;
end;
$$;

drop trigger if exists publish_approval_request_to_feed on public.approval_requests;
create trigger publish_approval_request_to_feed
after insert or update on public.approval_requests
for each row execute function public.trg_publish_approval_request();

create or replace function public.trg_publish_approval_authorization()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
begin
  perform public.append_sync_change(
    gen_random_uuid(),new.business_id,'approval_authorization',new.id,
    case when tg_op='INSERT' then 'insert' else 'update' end,
    to_jsonb(new),coalesce(new.consumed_at,new.approved_at,new.created_at)
  );
  return new;
end;
$$;

drop trigger if exists publish_approval_authorization_to_feed on public.approval_authorizations;
create trigger publish_approval_authorization_to_feed
after insert or update on public.approval_authorizations
for each row execute function public.trg_publish_approval_authorization();

create or replace function public.trg_publish_approval_decision_event()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
begin
  perform public.append_sync_change(
    gen_random_uuid(),new.business_id,'approval_decision_event',new.id,'append_event',
    to_jsonb(new),new.decided_at
  );
  return new;
end;
$$;

drop trigger if exists publish_approval_decision_to_feed on public.approval_decision_events;
create trigger publish_approval_decision_to_feed
after insert on public.approval_decision_events
for each row execute function public.trg_publish_approval_decision_event();

-- ============================================================================
-- 8. RLS / DIRECT ACCESS
-- ============================================================================

alter table public.approval_decision_events enable row level security;

drop policy if exists approval_decision_read on public.approval_decision_events;
create policy approval_decision_read on public.approval_decision_events
for select using (public.has_business_access(business_id));

-- Keep writes behind typed RPCs.
revoke insert,update,delete on public.approval_decision_events from authenticated;
revoke insert,update,delete on public.approval_authorizations from authenticated;

-- ============================================================================
-- 9. GRANTS
-- ============================================================================

revoke all on function public.pg_request_approval(
  uuid,uuid,uuid,uuid,text,text,text,uuid,jsonb
) from public;
grant execute on function public.pg_request_approval(
  uuid,uuid,uuid,uuid,text,text,text,uuid,jsonb
) to authenticated;

revoke all on function public.pg_approve_request(
  uuid,uuid,uuid,uuid,uuid,uuid,timestamptz,text
) from public;
grant execute on function public.pg_approve_request(
  uuid,uuid,uuid,uuid,uuid,uuid,timestamptz,text
) to authenticated;

revoke all on function public.pg_decline_request(
  uuid,uuid,uuid,uuid,uuid,text
) from public;
grant execute on function public.pg_decline_request(
  uuid,uuid,uuid,uuid,uuid,text
) to authenticated;

commit;
