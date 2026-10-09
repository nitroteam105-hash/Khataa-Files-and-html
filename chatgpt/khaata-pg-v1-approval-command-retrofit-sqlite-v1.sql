-- Khaata PG / Hostel V1 — Approval Command Retrofit SQLite v1
-- STATUS: PROPOSED MIGRATION.
--
-- Purpose:
--   Finish wiring the corrected approval model into command execution.
--
-- Core invariant:
--   request approval != approve request != execute business action.
--
-- Important:
--   This migration assumes the earlier approval tables exist.
--   Apply only once through the app migration runner.

PRAGMA foreign_keys = ON;
BEGIN IMMEDIATE;

ALTER TABLE approval_requests ADD COLUMN request_key TEXT;
ALTER TABLE approval_requests ADD COLUMN requested_by_user_id TEXT;
ALTER TABLE approval_requests ADD COLUMN decided_by_user_id TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS uq_approval_requests_pending_request_key
  ON approval_requests(request_key)
  WHERE request_key IS NOT NULL AND state='pending';

-- Owner approval attribution must not be faked through another staff membership.
ALTER TABLE approval_authorizations ADD COLUMN authorized_for_user_id TEXT;
ALTER TABLE approval_authorizations ADD COLUMN approved_by_user_id TEXT;
ALTER TABLE approval_authorizations ADD COLUMN approved_by_membership_id TEXT;
ALTER TABLE approval_authorizations ADD COLUMN action_type TEXT;
ALTER TABLE approval_authorizations ADD COLUMN target_type TEXT;
ALTER TABLE approval_authorizations ADD COLUMN target_id TEXT;

CREATE INDEX IF NOT EXISTS idx_approval_authorizations_actor_action
  ON approval_authorizations(
    business_id,authorized_for_user_id,action_type,consumed_at
  );

-- Explicit authority to approve requests.
-- Existing role/action table is reused rather than creating a separate approver role.
INSERT OR IGNORE INTO staff_role_action_permissions(
  role_id,action_key,permission_state
)
SELECT id,'approve_requests','not_allowed'
FROM staff_roles;

-- Approval bookkeeping should use centralized sync state, not domain-row sync flags.
-- Existing legacy sync columns may remain physically present for compatibility,
-- but new code must not rely on them.

INSERT OR IGNORE INTO schema_migrations(version,name,applied_at)
VALUES (9,'approval_command_retrofit_v1',strftime('%Y-%m-%dT%H:%M:%fZ','now'));

COMMIT;
