-- Khaata PG / Hostel V1 — Staff Access Enforcement SQLite v1
-- STATUS: PROPOSED IMPLEMENTATION MODEL.
--
-- Frozen product rules preserved:
-- * Owner-only operation is valid.
-- * Action permission states: Allowed / Needs approval / Not allowed.
-- * Visibility is separate from action permission.
-- * Approval does not execute the underlying action.
-- * Proceeding with missing tenant requirements is governed by Staff & Access.
-- * Removing/disabling staff preserves historical accountability.
--
-- Exact default role-template contents remain configurable and are NOT frozen here.

PRAGMA foreign_keys = ON;
BEGIN IMMEDIATE;

-- ---------------------------------------------------------------------------
-- ROLE DEFINITIONS
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS staff_roles (
  id TEXT PRIMARY KEY,
  business_id TEXT NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
  role_key TEXT NOT NULL,
  display_name TEXT NOT NULL,
  is_system_template INTEGER NOT NULL DEFAULT 0 CHECK (is_system_template IN (0,1)),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  archived_at TEXT,
  sync_status TEXT NOT NULL DEFAULT 'local'
    CHECK (sync_status IN ('local','pending','synced','conflict')),
  server_version INTEGER,
  last_synced_at TEXT,
  UNIQUE (business_id, role_key)
);

-- Suggested template keys:
-- owner
-- manager
-- caretaker_front_desk
-- accounts
-- custom:<uuid>
--
-- Do NOT add "worker" as a default PG role.

CREATE TABLE IF NOT EXISTS staff_role_action_permissions (
  id TEXT PRIMARY KEY,
  role_id TEXT NOT NULL REFERENCES staff_roles(id) ON DELETE RESTRICT,
  action_key TEXT NOT NULL,
  permission_state TEXT NOT NULL
    CHECK (permission_state IN ('allowed','needs_approval','not_allowed')),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  sync_status TEXT NOT NULL DEFAULT 'local'
    CHECK (sync_status IN ('local','pending','synced','conflict')),
  server_version INTEGER,
  last_synced_at TEXT,
  UNIQUE (role_id, action_key)
);

-- Important action keys used by current PG handlers:
-- add_tenant
-- confirm_joined
-- proceed_with_missing_requirements
-- record_payment
-- reverse_payment
-- add_expense
-- add_charge
-- transfer_room
-- plan_move_out
-- end_tenancy
-- apply_security_to_dues
-- refund_security
-- handover_cash
-- retire_capacity
-- manage_staff

CREATE TABLE IF NOT EXISTS staff_role_visibility (
  id TEXT PRIMARY KEY,
  role_id TEXT NOT NULL REFERENCES staff_roles(id) ON DELETE RESTRICT,
  visibility_key TEXT NOT NULL,
  is_visible INTEGER NOT NULL CHECK (is_visible IN (0,1)),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  sync_status TEXT NOT NULL DEFAULT 'local'
    CHECK (sync_status IN ('local','pending','synced','conflict')),
  server_version INTEGER,
  last_synced_at TEXT,
  UNIQUE (role_id, visibility_key)
);

-- Example visibility keys:
-- tenant_records
-- tenant_balances
-- tenant_sensitive_identity
-- expenses
-- rooms
-- staff_cash_custody
-- staff_access

CREATE TABLE IF NOT EXISTS staff_role_area_access (
  id TEXT PRIMARY KEY,
  role_id TEXT NOT NULL REFERENCES staff_roles(id) ON DELETE RESTRICT,
  area_key TEXT NOT NULL,
  access_level TEXT NOT NULL
    CHECK (access_level IN ('no_access','read_only','create_only','manage')),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  sync_status TEXT NOT NULL DEFAULT 'local'
    CHECK (sync_status IN ('local','pending','synced','conflict')),
  server_version INTEGER,
  last_synced_at TEXT,
  UNIQUE (role_id, area_key)
);

-- ---------------------------------------------------------------------------
-- MEMBERSHIP → ROLE + PROPERTY SCOPE
-- ---------------------------------------------------------------------------

ALTER TABLE staff_memberships ADD COLUMN role_id TEXT REFERENCES staff_roles(id);

CREATE TABLE IF NOT EXISTS staff_property_scopes (
  id TEXT PRIMARY KEY,
  membership_id TEXT NOT NULL REFERENCES staff_memberships(id) ON DELETE RESTRICT,
  business_id TEXT NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
  access_state TEXT NOT NULL DEFAULT 'allowed'
    CHECK (access_state IN ('allowed','blocked')),
  valid_from TEXT NOT NULL,
  valid_to TEXT,
  created_at TEXT NOT NULL,
  sync_status TEXT NOT NULL DEFAULT 'local'
    CHECK (sync_status IN ('local','pending','synced','conflict')),
  server_version INTEGER,
  last_synced_at TEXT,
  CHECK (valid_to IS NULL OR valid_to > valid_from)
);

CREATE INDEX IF NOT EXISTS idx_staff_scope_membership_business
  ON staff_property_scopes(membership_id,business_id,valid_from);

-- ---------------------------------------------------------------------------
-- APPROVAL AUTHORITY / EXECUTION TOKENS
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS approval_authorizations (
  id TEXT PRIMARY KEY,
  approval_request_id TEXT NOT NULL UNIQUE REFERENCES approval_requests(id) ON DELETE RESTRICT,
  business_id TEXT NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
  action_type TEXT NOT NULL,
  target_type TEXT,
  target_id TEXT,
  authorized_for_membership_id TEXT NOT NULL REFERENCES staff_memberships(id) ON DELETE RESTRICT,
  approved_by_membership_id TEXT NOT NULL REFERENCES staff_memberships(id) ON DELETE RESTRICT,
  approved_at TEXT NOT NULL,
  consumed_at TEXT,
  consumed_by_event_id TEXT REFERENCES domain_events(id) ON DELETE RESTRICT,
  expires_at TEXT,
  created_at TEXT NOT NULL,
  sync_status TEXT NOT NULL DEFAULT 'local'
    CHECK (sync_status IN ('local','pending','synced','conflict')),
  server_version INTEGER,
  last_synced_at TEXT
);

-- An authorization is permission to execute once; it is NOT proof execution occurred.
-- Command handlers consume it only inside the same transaction as the actual domain mutation.

CREATE INDEX IF NOT EXISTS idx_approval_authorizations_unconsumed
  ON approval_authorizations(authorized_for_membership_id,action_type,consumed_at,expires_at);

-- ---------------------------------------------------------------------------
-- ACCESS HISTORY
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS staff_access_events (
  id TEXT PRIMARY KEY,
  business_id TEXT NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
  membership_id TEXT REFERENCES staff_memberships(id) ON DELETE RESTRICT,
  event_type TEXT NOT NULL,
  occurred_at TEXT NOT NULL,
  actor_user_id TEXT,
  payload_json TEXT NOT NULL DEFAULT '{}',
  created_at TEXT NOT NULL,
  sync_status TEXT NOT NULL DEFAULT 'local'
    CHECK (sync_status IN ('local','pending','synced','conflict')),
  server_version INTEGER,
  last_synced_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_staff_access_events_membership_time
  ON staff_access_events(membership_id,occurred_at);

-- ---------------------------------------------------------------------------
-- EFFECTIVE ACCESS PROJECTION
-- ---------------------------------------------------------------------------

DROP VIEW IF EXISTS v_effective_staff_actions;
CREATE VIEW v_effective_staff_actions AS
SELECT
  sm.id AS membership_id,
  sm.business_id,
  sm.user_id,
  sm.membership_state,
  sr.id AS role_id,
  sr.role_key,
  sap.action_key,
  sap.permission_state
FROM staff_memberships sm
JOIN staff_roles sr ON sr.id=sm.role_id
JOIN staff_role_action_permissions sap ON sap.role_id=sr.id
WHERE sm.membership_state='active'
  AND sr.archived_at IS NULL;

DROP VIEW IF EXISTS v_effective_staff_visibility;
CREATE VIEW v_effective_staff_visibility AS
SELECT
  sm.id AS membership_id,
  sm.business_id,
  sm.user_id,
  srv.visibility_key,
  srv.is_visible
FROM staff_memberships sm
JOIN staff_roles sr ON sr.id=sm.role_id
JOIN staff_role_visibility srv ON srv.role_id=sr.id
WHERE sm.membership_state='active'
  AND sr.archived_at IS NULL;

INSERT OR IGNORE INTO schema_migrations(version,name,applied_at)
VALUES (3,'staff_access_enforcement_v1',strftime('%Y-%m-%dT%H:%M:%fZ','now'));

COMMIT;
