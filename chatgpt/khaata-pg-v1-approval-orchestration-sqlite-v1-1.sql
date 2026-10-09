-- Khaata PG / Hostel V1 — Approval Orchestration SQLite v1.1
-- STATUS: PROPOSED MIGRATION.
--
-- Fixes three implementation defects:
--   1) approval request created inside command transaction then rolled back
--   2) any active staff could approve
--   3) owner approval attribution relied on a staff membership that may not exist
--
-- Product invariant:
--   approval request != approval != execution

PRAGMA foreign_keys = ON;
BEGIN IMMEDIATE;

-- ---------------------------------------------------------------------------
-- 1. REQUEST IDEMPOTENCY + USER ATTRIBUTION
-- ---------------------------------------------------------------------------

ALTER TABLE approval_requests ADD COLUMN request_key TEXT;
ALTER TABLE approval_requests ADD COLUMN requested_by_user_id TEXT;
ALTER TABLE approval_requests ADD COLUMN decided_by_user_id TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS uq_approval_requests_request_key
  ON approval_requests(business_id,request_key)
  WHERE request_key IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_approval_requests_pending
  ON approval_requests(business_id,state,created_at);

-- Backfill requester user where possible.
UPDATE approval_requests
SET requested_by_user_id = (
  SELECT sm.user_id
  FROM staff_memberships sm
  WHERE sm.id=approval_requests.requested_by_membership_id
)
WHERE requested_by_user_id IS NULL
  AND requested_by_membership_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 2. AUTHORIZATION USER ATTRIBUTION
-- ---------------------------------------------------------------------------

ALTER TABLE approval_authorizations ADD COLUMN authorized_for_user_id TEXT;
ALTER TABLE approval_authorizations ADD COLUMN approved_by_user_id TEXT;
ALTER TABLE approval_authorizations ADD COLUMN approved_by_membership_id TEXT;

UPDATE approval_authorizations
SET authorized_for_user_id = (
  SELECT sm.user_id
  FROM staff_memberships sm
  WHERE sm.id=approval_authorizations.authorized_for_membership_id
)
WHERE authorized_for_user_id IS NULL
  AND authorized_for_membership_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 3. EXPLICIT APPROVER AUTHORITY
-- ---------------------------------------------------------------------------
--
-- "approve_requests" joins the normal three-state action permission model.
-- Owner fallback remains allowed even with no staff membership.
--
-- Do not seed all staff as Allowed here. Role-template defaults remain
-- configurable product data.

INSERT OR IGNORE INTO staff_role_action_permissions(
  role_id,action_key,permission_state,created_at
)
SELECT sr.id,'approve_requests','not_allowed',
       strftime('%Y-%m-%dT%H:%M:%fZ','now')
FROM staff_roles sr
WHERE NOT EXISTS (
  SELECT 1
  FROM staff_role_action_permissions p
  WHERE p.role_id=sr.id AND p.action_key='approve_requests'
);

-- ---------------------------------------------------------------------------
-- 4. APPROVAL AUDIT HISTORY
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS approval_decision_events (
  id TEXT PRIMARY KEY,
  business_id TEXT NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
  approval_request_id TEXT NOT NULL REFERENCES approval_requests(id) ON DELETE RESTRICT,
  decision TEXT NOT NULL CHECK (decision IN ('approved','declined')),
  decided_by_user_id TEXT NOT NULL,
  decided_by_membership_id TEXT REFERENCES staff_memberships(id) ON DELETE RESTRICT,
  decided_at TEXT NOT NULL,
  note TEXT,
  created_at TEXT NOT NULL
);

CREATE TRIGGER IF NOT EXISTS trg_approval_decision_events_no_update
BEFORE UPDATE ON approval_decision_events
BEGIN
  SELECT RAISE(ABORT,'approval decision history is append-only');
END;

CREATE TRIGGER IF NOT EXISTS trg_approval_decision_events_no_delete
BEFORE DELETE ON approval_decision_events
BEGIN
  SELECT RAISE(ABORT,'approval decision history is append-only');
END;

INSERT OR IGNORE INTO schema_migrations(version,name,applied_at)
VALUES (9,'approval_orchestration_v1_1',strftime('%Y-%m-%dT%H:%M:%fZ','now'));

COMMIT;
