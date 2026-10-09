-- Khaata PG / Hostel V1 — Local SQLite + Sync Schema v1.1 Correction
-- STATUS: PROPOSED MIGRATION. REVIEW BEFORE APPLYING TO A REAL APP DB.
--
-- Fixes the v1 contradiction where immutable domain rows also contained mutable
-- sync_status/server_version/last_synced_at fields.
--
-- V1.1 rule:
--   business truth stays in domain tables.
--   transport/sync truth lives in:
--     sync_outbox
--     sync_entity_state
--     sync_checkpoints
--     applied_remote_events
--     sync_conflicts
--
-- Immutable domain rows are NEVER updated merely because the server ACKed them.

PRAGMA foreign_keys = ON;
BEGIN IMMEDIATE;

-- ---------------------------------------------------------------------------
-- 1. CENTRAL SYNC ENTITY STATE
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS sync_entity_state (
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  business_id TEXT,
  sync_status TEXT NOT NULL DEFAULT 'local'
    CHECK (sync_status IN ('local','pending','inflight','synced','error','conflict')),
  server_version INTEGER,
  server_updated_at TEXT,
  last_synced_at TEXT,
  last_error_code TEXT,
  last_remote_event_id TEXT,
  PRIMARY KEY(entity_type, entity_id)
);

CREATE INDEX IF NOT EXISTS idx_sync_entity_state_business_status
  ON sync_entity_state(business_id, sync_status);

-- ---------------------------------------------------------------------------
-- 2. ACK RECEIPTS
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS sync_ack_receipts (
  operation_id TEXT PRIMARY KEY,
  business_id TEXT,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  server_version INTEGER,
  server_updated_at TEXT,
  result_json TEXT NOT NULL DEFAULT '{}',
  acknowledged_at TEXT NOT NULL
);

-- ---------------------------------------------------------------------------
-- 3. IMMUTABILITY HARDENING
-- ---------------------------------------------------------------------------

CREATE TRIGGER IF NOT EXISTS trg_payment_allocations_no_update
BEFORE UPDATE ON payment_allocations
BEGIN
  SELECT RAISE(ABORT, 'payment_allocations are append-only');
END;

CREATE TRIGGER IF NOT EXISTS trg_payment_allocations_no_delete
BEFORE DELETE ON payment_allocations
BEGIN
  SELECT RAISE(ABORT, 'payment_allocations are append-only');
END;

CREATE TRIGGER IF NOT EXISTS trg_financial_adjustments_no_update
BEFORE UPDATE ON financial_adjustments
BEGIN
  SELECT RAISE(ABORT, 'financial_adjustments are append-only; append a correction instead');
END;

CREATE TRIGGER IF NOT EXISTS trg_financial_adjustments_no_delete
BEFORE DELETE ON financial_adjustments
BEGIN
  SELECT RAISE(ABORT, 'financial_adjustments are append-only');
END;

-- Existing immutable guards from v1 remain authoritative for:
-- payment_events
-- receipt_snapshots
-- security_events
-- cash_custody_events
-- domain_events

-- ---------------------------------------------------------------------------
-- 4. BACKFILL ENTITY STATE FROM LEGACY ROW METADATA
-- ---------------------------------------------------------------------------
--
-- During migration, copy legacy sync metadata out of domain rows before a future
-- table-rebuild removes those columns physically.
--
-- SQLite cannot DROP arbitrary columns safely on all target versions, so this
-- migration intentionally performs a compatibility backfill first. Application
-- code must stop reading/writing legacy sync columns immediately.
--
-- Immutable/history-sensitive entities:

INSERT OR IGNORE INTO sync_entity_state(
  entity_type,entity_id,business_id,sync_status,server_version,last_synced_at
)
SELECT 'payment_event',id,business_id,sync_status,server_version,last_synced_at
FROM payment_events;

INSERT OR IGNORE INTO sync_entity_state(
  entity_type,entity_id,business_id,sync_status,server_version,last_synced_at
)
SELECT
  'payment_allocation',pa.id,pe.business_id,pa.sync_status,pa.server_version,pa.last_synced_at
FROM payment_allocations pa
JOIN payment_events pe ON pe.id=pa.payment_event_id;

INSERT OR IGNORE INTO sync_entity_state(
  entity_type,entity_id,business_id,sync_status,server_version,last_synced_at
)
SELECT
  'receipt_snapshot',rs.id,pe.business_id,rs.sync_status,rs.server_version,rs.last_synced_at
FROM receipt_snapshots rs
JOIN payment_events pe ON pe.id=rs.payment_event_id;

INSERT OR IGNORE INTO sync_entity_state(
  entity_type,entity_id,business_id,sync_status,server_version,last_synced_at
)
SELECT
  'security_event',se.id,t.business_id,se.sync_status,se.server_version,se.last_synced_at
FROM security_events se
JOIN security_accounts sa ON sa.id=se.security_account_id
JOIN tenancies t ON t.id=sa.tenancy_id;

INSERT OR IGNORE INTO sync_entity_state(
  entity_type,entity_id,business_id,sync_status,server_version,last_synced_at
)
SELECT
  'cash_custody_event',id,business_id,sync_status,server_version,last_synced_at
FROM cash_custody_events;

INSERT OR IGNORE INTO sync_entity_state(
  entity_type,entity_id,business_id,sync_status,server_version,last_synced_at
)
SELECT
  'domain_event',id,business_id,sync_status,server_version,last_synced_at
FROM domain_events;

INSERT OR IGNORE INTO sync_entity_state(
  entity_type,entity_id,business_id,sync_status,server_version,last_synced_at
)
SELECT
  'financial_adjustment',id,business_id,sync_status,server_version,last_synced_at
FROM financial_adjustments;

-- Mutable entities can be backfilled too; centralizing them avoids two competing
-- sources of sync metadata.

INSERT OR IGNORE INTO sync_entity_state(
  entity_type,entity_id,business_id,sync_status,server_version,last_synced_at
)
SELECT 'tenancy',id,business_id,sync_status,server_version,last_synced_at FROM tenancies;

INSERT OR IGNORE INTO sync_entity_state(
  entity_type,entity_id,business_id,sync_status,server_version,last_synced_at
)
SELECT
  'occupancy_assignment',oa.id,t.business_id,oa.sync_status,oa.server_version,oa.last_synced_at
FROM occupancy_assignments oa
JOIN tenancies t ON t.id=oa.tenancy_id;

INSERT OR IGNORE INTO sync_entity_state(
  entity_type,entity_id,business_id,sync_status,server_version,last_synced_at
)
SELECT 'obligation',id,business_id,sync_status,server_version,last_synced_at FROM obligations;

INSERT OR IGNORE INTO sync_entity_state(
  entity_type,entity_id,business_id,sync_status,server_version,last_synced_at
)
SELECT 'expense',id,business_id,sync_status,server_version,last_synced_at FROM expenses;

-- ---------------------------------------------------------------------------
-- 5. APPLICATION CONTRACT AFTER MIGRATION
-- ---------------------------------------------------------------------------
--
-- Local command:
--   INSERT/UPDATE domain truth
--   INSERT sync_outbox
--   UPSERT sync_entity_state(...,'pending')
--   COMMIT
--
-- Push starts:
--   sync_outbox.state='sending'
--   sync_entity_state.sync_status='inflight'
--
-- ACK:
--   sync_outbox.state='acknowledged'
--   UPSERT sync_entity_state(...,'synced',server_version,...)
--   INSERT OR REPLACE sync_ack_receipts(...)
--   DO NOT UPDATE immutable domain row
--
-- Transient failure:
--   outbox='failed'
--   entity_state='error'
--   domain truth unchanged
--
-- Conflict:
--   outbox='blocked'
--   entity_state='conflict'
--   sync_conflicts stores local+remote snapshots
--   domain truth remains preserved
--
-- PULL:
--   append/update domain row according to merge policy
--   UPSERT sync_entity_state with server version
--   never mutate immutable row solely for bookkeeping

INSERT OR IGNORE INTO schema_migrations(version,name,applied_at)
VALUES (6,'local_sync_metadata_v1_1',strftime('%Y-%m-%dT%H:%M:%fZ','now'));

COMMIT;
