-- Khaata PG / Hostel V1 — Local Sync Outbox Provenance v2
-- STATUS: PROPOSED SQLITE MIGRATION.
--
-- Adds the device-side metadata required to connect:
--   local-first commands
--   → entitlement lease provenance
--   → normal/drain-only sync
--   → typed Supabase RPCs
--
-- This extends, rather than replaces, sync_outbox.

PRAGMA foreign_keys = ON;
BEGIN IMMEDIATE;

ALTER TABLE sync_outbox ADD COLUMN required_entitlement TEXT;
ALTER TABLE sync_outbox ADD COLUMN lease_id TEXT;
ALTER TABLE sync_outbox ADD COLUMN local_sequence INTEGER;
ALTER TABLE sync_outbox ADD COLUMN previous_operation_hash TEXT;
ALTER TABLE sync_outbox ADD COLUMN operation_hash TEXT;
ALTER TABLE sync_outbox ADD COLUMN effective_server_time_at_creation TEXT;
ALTER TABLE sync_outbox ADD COLUMN client_created_at TEXT;
ALTER TABLE sync_outbox ADD COLUMN rpc_name TEXT;
ALTER TABLE sync_outbox ADD COLUMN rpc_args_json TEXT;
ALTER TABLE sync_outbox ADD COLUMN server_result_json TEXT;
ALTER TABLE sync_outbox ADD COLUMN acknowledged_at TEXT;
ALTER TABLE sync_outbox ADD COLUMN conflict_id TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS uq_sync_outbox_lease_sequence
  ON sync_outbox(lease_id,local_sequence)
  WHERE lease_id IS NOT NULL AND local_sequence IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_sync_outbox_state_created
  ON sync_outbox(state,created_at);

CREATE INDEX IF NOT EXISTS idx_sync_outbox_required_entitlement
  ON sync_outbox(required_entitlement,state);

CREATE TABLE IF NOT EXISTS sync_runtime_state (
  id INTEGER PRIMARY KEY CHECK (id=1),
  mode TEXT NOT NULL DEFAULT 'offline'
    CHECK (mode IN ('normal','offline','drain_only','conflict')),
  current_lease_id TEXT,
  pending_count INTEGER NOT NULL DEFAULT 0,
  conflict_count INTEGER NOT NULL DEFAULT 0,
  last_attempt_at TEXT,
  last_success_at TEXT,
  last_error TEXT,
  updated_at TEXT NOT NULL
);

INSERT OR IGNORE INTO sync_runtime_state(
  id,mode,pending_count,conflict_count,updated_at
) VALUES (
  1,'offline',0,0,strftime('%Y-%m-%dT%H:%M:%fZ','now')
);

CREATE TABLE IF NOT EXISTS sync_rpc_receipts (
  operation_id TEXT PRIMARY KEY,
  rpc_name TEXT NOT NULL,
  result_state TEXT NOT NULL,
  result_json TEXT NOT NULL,
  received_at TEXT NOT NULL
);

INSERT OR IGNORE INTO schema_migrations(version,name,applied_at)
VALUES (4,'sync_outbox_provenance_v2',strftime('%Y-%m-%dT%H:%M:%fZ','now'));

COMMIT;
