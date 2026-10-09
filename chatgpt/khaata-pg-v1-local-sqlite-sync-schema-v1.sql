-- Khaata PG / Hostel V1 — Local SQLite + Sync Schema v1
-- STATUS: PROPOSED IMPLEMENTATION SCHEMA, NOT A FROZEN PRODUCT DECISION.
--
-- Architecture:
--   UI / domain logic -> SQLite (operational source on device)
--                     -> sync_outbox
--                     -> Supabase/Postgres
--
-- Core rules:
--   * App writes SQLite first.
--   * Normal work must not depend on network availability.
--   * IDs are created on-device before sync.
--   * Financial/history-sensitive records are append-only.
--   * Sync preserves legitimate concurrent events and exposes conflicts.
--   * Tier names are not stored as feature gates; entitlement keys are.
--
-- Storage conventions:
--   * UUIDs are TEXT (client-generated; e.g. UUID/ULID-style string chosen by app).
--   * Monetary values are INTEGER minor units (paise/cents), never REAL.
--   * RFC3339 UTC timestamps are TEXT.
--   * Business-effective calendar dates are TEXT YYYY-MM-DD.
--   * JSON payloads are TEXT containing valid JSON.
--
-- NOTE:
-- Exact ID generator, sync transport, conflict resolver, and encryption-at-rest
-- mechanism remain implementation choices.

PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;
PRAGMA temp_store = MEMORY;

BEGIN IMMEDIATE;

-- ---------------------------------------------------------------------------
-- 0. LOCAL DATABASE / DEVICE METADATA
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS schema_migrations (
  version INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  applied_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS device_state (
  device_id TEXT PRIMARY KEY,
  install_id TEXT NOT NULL,
  created_at TEXT NOT NULL,
  last_opened_at TEXT NOT NULL,
  app_version TEXT,
  db_schema_version INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS local_settings (
  key TEXT PRIMARY KEY,
  value_json TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS entitlement_snapshot (
  id TEXT PRIMARY KEY,
  account_id TEXT,
  subscription_id TEXT,
  effective_entitlements_json TEXT NOT NULL,
  verified_server_time TEXT,
  grace_expires_at TEXT,
  config_version TEXT,
  verified_at_local TEXT NOT NULL
);

-- ---------------------------------------------------------------------------
-- 1. SHARED BUSINESS SHELL
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS businesses (
  id TEXT PRIMARY KEY,
  owner_user_id TEXT NOT NULL,
  name TEXT NOT NULL CHECK (length(trim(name)) > 0),
  business_type TEXT NOT NULL,
  location_text TEXT,
  operational_currency TEXT NOT NULL CHECK (length(operational_currency) = 3),
  timezone TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  retired_at TEXT,

  sync_status TEXT NOT NULL DEFAULT 'local'
    CHECK (sync_status IN ('local','pending','synced','conflict')),
  server_version INTEGER,
  last_synced_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_businesses_owner
  ON businesses(owner_user_id);

-- ---------------------------------------------------------------------------
-- 2. PROPERTY / CAPACITY
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS property_nodes (
  id TEXT PRIMARY KEY,
  business_id TEXT NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
  parent_id TEXT REFERENCES property_nodes(id) ON DELETE RESTRICT,
  node_type TEXT NOT NULL
    CHECK (node_type IN ('building','block','floor','room','bed')),
  label TEXT NOT NULL CHECK (length(trim(label)) > 0),
  lifecycle_state TEXT NOT NULL DEFAULT 'available'
    CHECK (lifecycle_state IN ('available','temporarily_unavailable','retired')),
  metadata_json TEXT NOT NULL DEFAULT '{}',
  created_at TEXT NOT NULL,
  retired_at TEXT,

  sync_status TEXT NOT NULL DEFAULT 'local'
    CHECK (sync_status IN ('local','pending','synced','conflict')),
  server_version INTEGER,
  last_synced_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_property_nodes_business_parent
  ON property_nodes(business_id, parent_id);

CREATE INDEX IF NOT EXISTS idx_property_nodes_business_type
  ON property_nodes(business_id, node_type);

-- ---------------------------------------------------------------------------
-- 3. PARTIES + TENANCY
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS parties (
  id TEXT PRIMARY KEY,
  business_id TEXT NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
  party_type TEXT NOT NULL DEFAULT 'person'
    CHECK (party_type IN ('person','organization')),
  display_name TEXT NOT NULL CHECK (length(trim(display_name)) > 0),
  phone TEXT,
  email TEXT,
  metadata_json TEXT NOT NULL DEFAULT '{}',
  created_at TEXT NOT NULL,
  archived_at TEXT,

  sync_status TEXT NOT NULL DEFAULT 'local'
    CHECK (sync_status IN ('local','pending','synced','conflict')),
  server_version INTEGER,
  last_synced_at TEXT
);

CREATE TABLE IF NOT EXISTS tenancies (
  id TEXT PRIMARY KEY,
  business_id TEXT NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
  lifecycle_state TEXT NOT NULL DEFAULT 'upcoming'
    CHECK (lifecycle_state IN ('upcoming','active','planned_move_out','moved_out','cancelled_before_joining')),
  planned_join_date TEXT,
  joined_at TEXT,
  planned_move_out_date TEXT,
  ended_at TEXT,
  cancelled_at TEXT,
  cancellation_reason TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,

  sync_status TEXT NOT NULL DEFAULT 'local'
    CHECK (sync_status IN ('local','pending','synced','conflict')),
  server_version INTEGER,
  last_synced_at TEXT,

  CHECK (
    (lifecycle_state <> 'active' OR joined_at IS NOT NULL)
    AND
    (lifecycle_state <> 'cancelled_before_joining' OR cancelled_at IS NOT NULL)
  )
);

CREATE INDEX IF NOT EXISTS idx_tenancies_business_state
  ON tenancies(business_id, lifecycle_state);

CREATE TABLE IF NOT EXISTS tenancy_role_assignments (
  id TEXT PRIMARY KEY,
  tenancy_id TEXT NOT NULL REFERENCES tenancies(id) ON DELETE RESTRICT,
  party_id TEXT NOT NULL REFERENCES parties(id) ON DELETE RESTRICT,
  role_type TEXT NOT NULL
    CHECK (role_type IN ('occupant','responsible_party','payer','deposit_owner')),
  valid_from TEXT NOT NULL,
  valid_to TEXT,
  created_at TEXT NOT NULL,

  sync_status TEXT NOT NULL DEFAULT 'local'
    CHECK (sync_status IN ('local','pending','synced','conflict')),
  server_version INTEGER,
  last_synced_at TEXT,

  CHECK (valid_to IS NULL OR valid_to > valid_from)
);

CREATE INDEX IF NOT EXISTS idx_tenancy_roles_tenancy_role
  ON tenancy_role_assignments(tenancy_id, role_type, valid_from);

-- ---------------------------------------------------------------------------
-- 4. OCCUPANCY + RENT TERMS
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS occupancy_assignments (
  id TEXT PRIMARY KEY,
  tenancy_id TEXT NOT NULL REFERENCES tenancies(id) ON DELETE RESTRICT,
  capacity_id TEXT NOT NULL REFERENCES property_nodes(id) ON DELETE RESTRICT,
  assignment_state TEXT NOT NULL DEFAULT 'planned'
    CHECK (assignment_state IN ('planned','active','ended','cancelled')),
  start_at TEXT,
  end_at TEXT,
  created_at TEXT NOT NULL,

  sync_status TEXT NOT NULL DEFAULT 'local'
    CHECK (sync_status IN ('local','pending','synced','conflict')),
  server_version INTEGER,
  last_synced_at TEXT,

  CHECK (end_at IS NULL OR start_at IS NULL OR end_at > start_at)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_local_one_active_assignment_per_tenancy
  ON occupancy_assignments(tenancy_id)
  WHERE assignment_state = 'active';

CREATE UNIQUE INDEX IF NOT EXISTS uq_local_one_active_tenancy_per_capacity
  ON occupancy_assignments(capacity_id)
  WHERE assignment_state = 'active';

CREATE INDEX IF NOT EXISTS idx_occupancy_capacity
  ON occupancy_assignments(capacity_id, assignment_state, start_at);

CREATE TABLE IF NOT EXISTS rent_terms (
  id TEXT PRIMARY KEY,
  tenancy_id TEXT NOT NULL REFERENCES tenancies(id) ON DELETE RESTRICT,
  amount_minor INTEGER NOT NULL CHECK (amount_minor >= 0),
  billing_frequency TEXT NOT NULL DEFAULT 'monthly'
    CHECK (billing_frequency = 'monthly'),
  billing_timing TEXT NOT NULL
    CHECK (billing_timing IN ('prepaid','postpaid')),
  due_day INTEGER NOT NULL CHECK (due_day BETWEEN 1 AND 31),
  grace_days INTEGER NOT NULL DEFAULT 0 CHECK (grace_days BETWEEN 0 AND 90),
  valid_from TEXT NOT NULL,
  valid_to TEXT,
  created_at TEXT NOT NULL,

  sync_status TEXT NOT NULL DEFAULT 'local'
    CHECK (sync_status IN ('local','pending','synced','conflict')),
  server_version INTEGER,
  last_synced_at TEXT,

  CHECK (valid_to IS NULL OR valid_to >= valid_from)
);

CREATE INDEX IF NOT EXISTS idx_rent_terms_tenancy_validity
  ON rent_terms(tenancy_id, valid_from);

-- ---------------------------------------------------------------------------
-- 5. CHARGES / OBLIGATIONS / ADJUSTMENTS
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS charges (
  id TEXT PRIMARY KEY,
  business_id TEXT NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
  tenancy_id TEXT NOT NULL REFERENCES tenancies(id) ON DELETE RESTRICT,
  charge_type TEXT NOT NULL
    CHECK (charge_type IN ('recurring','variable','one_time')),
  category TEXT NOT NULL,
  description TEXT,
  amount_minor INTEGER NOT NULL CHECK (amount_minor >= 0),
  effective_date TEXT NOT NULL,
  dispute_state TEXT NOT NULL DEFAULT 'none'
    CHECK (dispute_state IN ('none','disputed','resolved')),
  tax_context_json TEXT NOT NULL DEFAULT '{}',
  created_at TEXT NOT NULL,

  sync_status TEXT NOT NULL DEFAULT 'local'
    CHECK (sync_status IN ('local','pending','synced','conflict')),
  server_version INTEGER,
  last_synced_at TEXT
);

CREATE TABLE IF NOT EXISTS obligations (
  id TEXT PRIMARY KEY,
  business_id TEXT NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
  tenancy_id TEXT NOT NULL REFERENCES tenancies(id) ON DELETE RESTRICT,
  obligation_type TEXT NOT NULL
    CHECK (obligation_type IN ('rent','charge','opening_balance')),
  source_charge_id TEXT REFERENCES charges(id) ON DELETE RESTRICT,
  period_start TEXT,
  period_end TEXT,
  due_date TEXT,
  amount_minor INTEGER NOT NULL CHECK (amount_minor >= 0),
  deterministic_key TEXT,
  created_at TEXT NOT NULL,

  sync_status TEXT NOT NULL DEFAULT 'local'
    CHECK (sync_status IN ('local','pending','synced','conflict')),
  server_version INTEGER,
  last_synced_at TEXT,

  CHECK (
    (obligation_type = 'charge' AND source_charge_id IS NOT NULL)
    OR
    (obligation_type <> 'charge')
  )
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_local_obligation_deterministic_key
  ON obligations(business_id, deterministic_key)
  WHERE deterministic_key IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_obligations_tenancy_due
  ON obligations(tenancy_id, due_date);

CREATE TABLE IF NOT EXISTS financial_adjustments (
  id TEXT PRIMARY KEY,
  business_id TEXT NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
  tenancy_id TEXT NOT NULL REFERENCES tenancies(id) ON DELETE RESTRICT,
  obligation_id TEXT REFERENCES obligations(id) ON DELETE RESTRICT,
  charge_id TEXT REFERENCES charges(id) ON DELETE RESTRICT,
  adjustment_type TEXT NOT NULL
    CHECK (adjustment_type IN ('waiver','discount','write_off','correction')),
  amount_minor INTEGER NOT NULL CHECK (amount_minor > 0),
  reason TEXT NOT NULL CHECK (length(trim(reason)) > 0),
  occurred_at TEXT NOT NULL,
  created_at TEXT NOT NULL,

  sync_status TEXT NOT NULL DEFAULT 'local'
    CHECK (sync_status IN ('local','pending','synced','conflict')),
  server_version INTEGER,
  last_synced_at TEXT,

  CHECK (obligation_id IS NOT NULL OR charge_id IS NOT NULL)
);

-- ---------------------------------------------------------------------------
-- 6. PAYMENTS / ALLOCATIONS / RECEIPTS
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS payment_events (
  id TEXT PRIMARY KEY,
  business_id TEXT NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
  tenancy_id TEXT NOT NULL REFERENCES tenancies(id) ON DELETE RESTRICT,
  payer_party_id TEXT REFERENCES parties(id) ON DELETE RESTRICT,
  event_type TEXT NOT NULL
    CHECK (event_type IN ('payment','reversal','chargeback')),
  original_payment_id TEXT REFERENCES payment_events(id) ON DELETE RESTRICT,
  amount_minor INTEGER NOT NULL CHECK (amount_minor > 0),
  payment_method TEXT,
  occurred_at TEXT NOT NULL,
  recorded_by_user_id TEXT,
  metadata_json TEXT NOT NULL DEFAULT '{}',
  created_at TEXT NOT NULL,

  sync_status TEXT NOT NULL DEFAULT 'local'
    CHECK (sync_status IN ('local','pending','synced','conflict')),
  server_version INTEGER,
  last_synced_at TEXT,

  CHECK (
    (event_type = 'payment' AND original_payment_id IS NULL)
    OR
    (event_type IN ('reversal','chargeback') AND original_payment_id IS NOT NULL)
  )
);

CREATE INDEX IF NOT EXISTS idx_payment_events_tenancy_time
  ON payment_events(tenancy_id, occurred_at);

CREATE TABLE IF NOT EXISTS payment_allocations (
  id TEXT PRIMARY KEY,
  payment_event_id TEXT NOT NULL REFERENCES payment_events(id) ON DELETE RESTRICT,
  obligation_id TEXT NOT NULL REFERENCES obligations(id) ON DELETE RESTRICT,
  amount_minor INTEGER NOT NULL CHECK (amount_minor > 0),
  allocation_effect INTEGER NOT NULL DEFAULT 1
    CHECK (allocation_effect IN (-1,1)),
  created_at TEXT NOT NULL,

  sync_status TEXT NOT NULL DEFAULT 'local'
    CHECK (sync_status IN ('local','pending','synced','conflict')),
  server_version INTEGER,
  last_synced_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_payment_allocations_obligation
  ON payment_allocations(obligation_id);

CREATE TABLE IF NOT EXISTS receipt_snapshots (
  id TEXT PRIMARY KEY,
  payment_event_id TEXT NOT NULL UNIQUE REFERENCES payment_events(id) ON DELETE RESTRICT,
  receipt_number TEXT NOT NULL,
  snapshot_json TEXT NOT NULL,
  issued_at TEXT NOT NULL,
  created_at TEXT NOT NULL,

  sync_status TEXT NOT NULL DEFAULT 'local'
    CHECK (sync_status IN ('local','pending','synced','conflict')),
  server_version INTEGER,
  last_synced_at TEXT
);

-- ---------------------------------------------------------------------------
-- 7. SECURITY
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS security_accounts (
  id TEXT PRIMARY KEY,
  tenancy_id TEXT NOT NULL UNIQUE REFERENCES tenancies(id) ON DELETE RESTRICT,
  agreed_amount_minor INTEGER NOT NULL DEFAULT 0 CHECK (agreed_amount_minor >= 0),
  deposit_owner_party_id TEXT REFERENCES parties(id) ON DELETE RESTRICT,
  created_at TEXT NOT NULL,

  sync_status TEXT NOT NULL DEFAULT 'local'
    CHECK (sync_status IN ('local','pending','synced','conflict')),
  server_version INTEGER,
  last_synced_at TEXT
);

CREATE TABLE IF NOT EXISTS security_events (
  id TEXT PRIMARY KEY,
  security_account_id TEXT NOT NULL REFERENCES security_accounts(id) ON DELETE RESTRICT,
  event_type TEXT NOT NULL
    CHECK (event_type IN ('deposit_received','applied_to_dues','refund','correction')),
  amount_minor INTEGER NOT NULL CHECK (amount_minor > 0),
  obligation_id TEXT REFERENCES obligations(id) ON DELETE RESTRICT,
  payment_event_id TEXT REFERENCES payment_events(id) ON DELETE RESTRICT,
  occurred_at TEXT NOT NULL,
  reason TEXT,
  created_at TEXT NOT NULL,

  sync_status TEXT NOT NULL DEFAULT 'local'
    CHECK (sync_status IN ('local','pending','synced','conflict')),
  server_version INTEGER,
  last_synced_at TEXT,

  CHECK (
    (event_type = 'applied_to_dues' AND obligation_id IS NOT NULL)
    OR
    (event_type <> 'applied_to_dues')
  )
);

-- ---------------------------------------------------------------------------
-- 8. PROMISES
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS payment_promises (
  id TEXT PRIMARY KEY,
  tenancy_id TEXT NOT NULL REFERENCES tenancies(id) ON DELETE RESTRICT,
  obligation_id TEXT REFERENCES obligations(id) ON DELETE RESTRICT,
  promised_amount_minor INTEGER NOT NULL CHECK (promised_amount_minor > 0),
  promised_date TEXT NOT NULL,
  recorded_by_user_id TEXT,
  created_at TEXT NOT NULL,
  superseded_by_id TEXT REFERENCES payment_promises(id) ON DELETE RESTRICT,

  sync_status TEXT NOT NULL DEFAULT 'local'
    CHECK (sync_status IN ('local','pending','synced','conflict')),
  server_version INTEGER,
  last_synced_at TEXT
);

-- ---------------------------------------------------------------------------
-- 9. EXPENSES
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS expenses (
  id TEXT PRIMARY KEY,
  business_id TEXT NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
  amount_minor INTEGER NOT NULL CHECK (amount_minor > 0),
  category TEXT NOT NULL,
  paid_by_type TEXT NOT NULL
    CHECK (paid_by_type IN ('business','staff')),
  paid_by_party_id TEXT REFERENCES parties(id) ON DELETE RESTRICT,
  payment_method TEXT,
  expense_date TEXT NOT NULL,
  vendor TEXT,
  property_context_id TEXT REFERENCES property_nodes(id) ON DELETE RESTRICT,
  reimbursement_state TEXT NOT NULL DEFAULT 'not_applicable'
    CHECK (reimbursement_state IN ('not_applicable','owed','settled','waived')),
  created_at TEXT NOT NULL,

  sync_status TEXT NOT NULL DEFAULT 'local'
    CHECK (sync_status IN ('local','pending','synced','conflict')),
  server_version INTEGER,
  last_synced_at TEXT,

  CHECK (
    (paid_by_type = 'staff' AND paid_by_party_id IS NOT NULL AND reimbursement_state <> 'not_applicable')
    OR
    (paid_by_type = 'business' AND reimbursement_state = 'not_applicable')
  )
);

-- ---------------------------------------------------------------------------
-- 10. CASH CUSTODY
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS cash_custody_events (
  id TEXT PRIMARY KEY,
  business_id TEXT NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
  event_type TEXT NOT NULL
    CHECK (event_type IN ('collection_received','transfer','handover','discrepancy','resolution')),
  payment_event_id TEXT REFERENCES payment_events(id) ON DELETE RESTRICT,
  from_party_id TEXT REFERENCES parties(id) ON DELETE RESTRICT,
  to_party_id TEXT REFERENCES parties(id) ON DELETE RESTRICT,
  amount_minor INTEGER NOT NULL CHECK (amount_minor > 0),
  related_event_id TEXT REFERENCES cash_custody_events(id) ON DELETE RESTRICT,
  occurred_at TEXT NOT NULL,
  reason TEXT,
  recorded_by_user_id TEXT,
  created_at TEXT NOT NULL,

  sync_status TEXT NOT NULL DEFAULT 'local'
    CHECK (sync_status IN ('local','pending','synced','conflict')),
  server_version INTEGER,
  last_synced_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_cash_custody_business_time
  ON cash_custody_events(business_id, occurred_at);

-- ---------------------------------------------------------------------------
-- 11. STAFF / ACCESS / APPROVALS
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS staff_memberships (
  id TEXT PRIMARY KEY,
  business_id TEXT NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
  user_id TEXT NOT NULL,
  party_id TEXT REFERENCES parties(id) ON DELETE RESTRICT,
  role_name TEXT NOT NULL,
  membership_state TEXT NOT NULL DEFAULT 'active'
    CHECK (membership_state IN ('invited','active','disabled')),
  created_at TEXT NOT NULL,
  disabled_at TEXT,

  sync_status TEXT NOT NULL DEFAULT 'local'
    CHECK (sync_status IN ('local','pending','synced','conflict')),
  server_version INTEGER,
  last_synced_at TEXT,

  UNIQUE (business_id, user_id)
);

CREATE TABLE IF NOT EXISTS staff_permission_snapshots (
  id TEXT PRIMARY KEY,
  membership_id TEXT NOT NULL REFERENCES staff_memberships(id) ON DELETE RESTRICT,
  effective_from TEXT NOT NULL,
  effective_to TEXT,
  action_permissions_json TEXT NOT NULL DEFAULT '{}',
  visibility_json TEXT NOT NULL DEFAULT '{}',
  created_at TEXT NOT NULL,

  sync_status TEXT NOT NULL DEFAULT 'local'
    CHECK (sync_status IN ('local','pending','synced','conflict')),
  server_version INTEGER,
  last_synced_at TEXT,

  CHECK (effective_to IS NULL OR effective_to > effective_from)
);

CREATE TABLE IF NOT EXISTS approval_requests (
  id TEXT PRIMARY KEY,
  business_id TEXT NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
  requested_by_membership_id TEXT NOT NULL REFERENCES staff_memberships(id) ON DELETE RESTRICT,
  action_type TEXT NOT NULL,
  target_type TEXT,
  target_id TEXT,
  request_payload_json TEXT NOT NULL DEFAULT '{}',
  state TEXT NOT NULL DEFAULT 'pending'
    CHECK (state IN ('pending','approved','declined','expired','cancelled')),
  decided_by_membership_id TEXT REFERENCES staff_memberships(id) ON DELETE RESTRICT,
  decided_at TEXT,
  created_at TEXT NOT NULL,

  sync_status TEXT NOT NULL DEFAULT 'local'
    CHECK (sync_status IN ('local','pending','synced','conflict')),
  server_version INTEGER,
  last_synced_at TEXT
);

-- ---------------------------------------------------------------------------
-- 12. DOMAIN EVENTS
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS domain_events (
  id TEXT PRIMARY KEY,
  business_id TEXT NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  occurred_at TEXT NOT NULL,
  recorded_at TEXT NOT NULL,
  recorded_by_user_id TEXT,
  device_id TEXT,
  causation_id TEXT REFERENCES domain_events(id) ON DELETE RESTRICT,
  correlation_id TEXT,
  payload_json TEXT NOT NULL DEFAULT '{}',

  sync_status TEXT NOT NULL DEFAULT 'local'
    CHECK (sync_status IN ('local','pending','synced','conflict')),
  server_version INTEGER,
  last_synced_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_domain_events_business_recorded
  ON domain_events(business_id, recorded_at);

CREATE INDEX IF NOT EXISTS idx_domain_events_entity
  ON domain_events(entity_type, entity_id, occurred_at);

-- ---------------------------------------------------------------------------
-- 13. LOCAL SYNC INFRASTRUCTURE
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS sync_outbox (
  id TEXT PRIMARY KEY,
  business_id TEXT,
  aggregate_type TEXT NOT NULL,
  aggregate_id TEXT NOT NULL,
  operation TEXT NOT NULL
    CHECK (operation IN ('insert','update','append_event','retire')),
  payload_json TEXT NOT NULL,
  dependency_ids_json TEXT NOT NULL DEFAULT '[]',
  created_at TEXT NOT NULL,
  next_attempt_at TEXT,
  attempt_count INTEGER NOT NULL DEFAULT 0,
  last_error TEXT,
  state TEXT NOT NULL DEFAULT 'pending'
    CHECK (state IN ('pending','sending','acknowledged','failed','blocked'))
);

CREATE INDEX IF NOT EXISTS idx_sync_outbox_pending
  ON sync_outbox(state, next_attempt_at, created_at);

CREATE TABLE IF NOT EXISTS sync_checkpoints (
  business_id TEXT PRIMARY KEY,
  server_cursor TEXT,
  last_pull_at TEXT,
  last_push_at TEXT,
  last_success_at TEXT,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS applied_remote_events (
  remote_event_id TEXT PRIMARY KEY,
  business_id TEXT,
  applied_at TEXT NOT NULL,
  server_cursor TEXT
);

CREATE TABLE IF NOT EXISTS sync_conflicts (
  id TEXT PRIMARY KEY,
  business_id TEXT,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  conflict_type TEXT NOT NULL,
  local_snapshot_json TEXT,
  remote_snapshot_json TEXT,
  local_version INTEGER,
  remote_version INTEGER,
  detected_at TEXT NOT NULL,
  resolution_state TEXT NOT NULL DEFAULT 'open'
    CHECK (resolution_state IN ('open','resolved_local','resolved_remote','resolved_merged','dismissed')),
  resolved_at TEXT,
  resolution_note TEXT
);

CREATE INDEX IF NOT EXISTS idx_sync_conflicts_open
  ON sync_conflicts(business_id, resolution_state, detected_at);

CREATE TABLE IF NOT EXISTS sync_lock (
  lock_name TEXT PRIMARY KEY,
  owner_token TEXT,
  acquired_at TEXT,
  expires_at TEXT
);

-- ---------------------------------------------------------------------------
-- 14. LOCAL PROJECTIONS
-- ---------------------------------------------------------------------------

CREATE VIEW IF NOT EXISTS v_obligation_balances AS
SELECT
  o.id AS obligation_id,
  o.business_id,
  o.tenancy_id,
  o.amount_minor,
  COALESCE(SUM(pa.amount_minor * pa.allocation_effect), 0) AS net_allocated_minor,
  COALESCE((
    SELECT SUM(fa.amount_minor)
    FROM financial_adjustments fa
    WHERE fa.obligation_id = o.id
      AND fa.adjustment_type IN ('waiver','discount','write_off')
  ),0) AS net_adjustment_minor,
  COALESCE((
    SELECT SUM(se.amount_minor)
    FROM security_events se
    WHERE se.obligation_id = o.id
      AND se.event_type = 'applied_to_dues'
  ),0) AS security_applied_minor,
  MAX(
    o.amount_minor
    - COALESCE(SUM(pa.amount_minor * pa.allocation_effect), 0)
    - COALESCE((
        SELECT SUM(fa.amount_minor)
        FROM financial_adjustments fa
        WHERE fa.obligation_id = o.id
          AND fa.adjustment_type IN ('waiver','discount','write_off')
      ),0)
    - COALESCE((
        SELECT SUM(se.amount_minor)
        FROM security_events se
        WHERE se.obligation_id = o.id
          AND se.event_type = 'applied_to_dues'
      ),0),
    0
  ) AS outstanding_minor
FROM obligations o
LEFT JOIN payment_allocations pa ON pa.obligation_id = o.id
GROUP BY o.id;

CREATE VIEW IF NOT EXISTS v_security_balances AS
SELECT
  sa.id AS security_account_id,
  sa.tenancy_id,
  sa.agreed_amount_minor,
  COALESCE(SUM(
    CASE se.event_type
      WHEN 'deposit_received' THEN se.amount_minor
      WHEN 'refund' THEN -se.amount_minor
      WHEN 'applied_to_dues' THEN -se.amount_minor
      WHEN 'correction' THEN se.amount_minor
      ELSE 0
    END
  ),0) AS held_amount_minor
FROM security_accounts sa
LEFT JOIN security_events se ON se.security_account_id = sa.id
GROUP BY sa.id;

CREATE VIEW IF NOT EXISTS v_tenancy_outstanding AS
SELECT
  t.id AS tenancy_id,
  t.business_id,
  COALESCE(SUM(v.outstanding_minor),0) AS outstanding_minor
FROM tenancies t
LEFT JOIN v_obligation_balances v ON v.tenancy_id = t.id
GROUP BY t.id;

-- ---------------------------------------------------------------------------
-- 15. IMMUTABILITY GUARDS
-- ---------------------------------------------------------------------------

CREATE TRIGGER IF NOT EXISTS trg_payment_events_no_update
BEFORE UPDATE ON payment_events
BEGIN
  SELECT RAISE(ABORT, 'payment_events are immutable; append correction/reversal instead');
END;

CREATE TRIGGER IF NOT EXISTS trg_payment_events_no_delete
BEFORE DELETE ON payment_events
BEGIN
  SELECT RAISE(ABORT, 'payment_events are immutable; append correction/reversal instead');
END;

CREATE TRIGGER IF NOT EXISTS trg_receipt_snapshots_no_update
BEFORE UPDATE ON receipt_snapshots
BEGIN
  SELECT RAISE(ABORT, 'receipt_snapshots are immutable');
END;

CREATE TRIGGER IF NOT EXISTS trg_receipt_snapshots_no_delete
BEFORE DELETE ON receipt_snapshots
BEGIN
  SELECT RAISE(ABORT, 'receipt_snapshots are immutable');
END;

CREATE TRIGGER IF NOT EXISTS trg_security_events_no_update
BEFORE UPDATE ON security_events
BEGIN
  SELECT RAISE(ABORT, 'security_events are immutable; append correction instead');
END;

CREATE TRIGGER IF NOT EXISTS trg_security_events_no_delete
BEFORE DELETE ON security_events
BEGIN
  SELECT RAISE(ABORT, 'security_events are immutable');
END;

CREATE TRIGGER IF NOT EXISTS trg_cash_custody_events_no_update
BEFORE UPDATE ON cash_custody_events
BEGIN
  SELECT RAISE(ABORT, 'cash_custody_events are immutable; append resolution/correction instead');
END;

CREATE TRIGGER IF NOT EXISTS trg_cash_custody_events_no_delete
BEFORE DELETE ON cash_custody_events
BEGIN
  SELECT RAISE(ABORT, 'cash_custody_events are immutable');
END;

CREATE TRIGGER IF NOT EXISTS trg_domain_events_no_update
BEFORE UPDATE ON domain_events
BEGIN
  SELECT RAISE(ABORT, 'domain_events are immutable');
END;

CREATE TRIGGER IF NOT EXISTS trg_domain_events_no_delete
BEFORE DELETE ON domain_events
BEGIN
  SELECT RAISE(ABORT, 'domain_events are immutable');
END;

-- ---------------------------------------------------------------------------
-- 16. ATOMIC WRITE RECIPES (APPLICATION CONTRACT)
-- ---------------------------------------------------------------------------
-- Record payment must happen in ONE SQLite transaction:
--
-- BEGIN IMMEDIATE;
--   INSERT payment_events(...);
--   INSERT payment_allocations(...); -- one or more
--   INSERT receipt_snapshots(...);
--   INSERT cash_custody_events(...); -- when staff receives physical cash
--   INSERT domain_events(...);
--   INSERT sync_outbox(...);         -- every server-bound mutation/event
-- COMMIT;
--
-- UI may show Paid immediately after COMMIT. Network is not required.
--
-- Room transfer must happen in ONE transaction:
--   end old occupancy_assignment
--   create new occupancy_assignment
--   append domain event(s)
--   queue outbox
--   do NOT modify rent_terms unless rent changes explicitly.
--
-- Apply security must happen in ONE transaction:
--   insert security_events(event_type='applied_to_dues')
--   append domain event
--   queue outbox
--   never auto-create this event from an outstanding balance.
--
-- ---------------------------------------------------------------------------
-- 17. PUSH / PULL SYNC CONTRACT
-- ---------------------------------------------------------------------------
-- PUSH:
--   1) select pending outbox rows in created_at order;
--   2) preserve dependency ordering (parent before child where necessary);
--   3) send idempotently using client-generated IDs;
--   4) on ACK: mark outbox acknowledged + domain row synced/server_version;
--   5) on conflict: mark domain row conflict + create sync_conflicts row;
--   6) do not delete domain history after successful sync.
--
-- PULL:
--   1) fetch server changes since sync_checkpoints.server_cursor;
--   2) ignore already-applied remote event IDs;
--   3) apply each remote batch inside one SQLite transaction;
--   4) preserve concurrent history-sensitive events;
--   5) create sync_conflicts when automatic merge would destroy meaning;
--   6) advance checkpoint only after successful local commit.
--
-- NEVER use blind last-write-wins for:
--   payment_events
--   payment_allocations
--   receipt_snapshots
--   security_events
--   cash_custody_events
--   domain_events
--   occupancy history
--   effective-dated commercial-role history
--
-- ---------------------------------------------------------------------------
-- 18. MAPPING TO SUPABASE
-- ---------------------------------------------------------------------------
-- Core domain tables intentionally mirror the proposed Postgres schema closely.
-- Local-only tables:
--   schema_migrations
--   device_state
--   local_settings
--   entitlement_snapshot
--   sync_outbox
--   sync_checkpoints
--   applied_remote_events
--   sync_conflicts
--   sync_lock
--
-- SQLite-only sync columns on domain rows:
--   sync_status
--   server_version
--   last_synced_at
--
-- These device-local columns should NOT be uploaded as domain business data.

INSERT OR IGNORE INTO schema_migrations(version, name, applied_at)
VALUES (1, 'pg_v1_local_sqlite_sync_schema', strftime('%Y-%m-%dT%H:%M:%fZ','now'));

COMMIT;
