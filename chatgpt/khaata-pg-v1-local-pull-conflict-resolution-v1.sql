-- Khaata PG / Hostel V1 — Local Pull + Conflict Resolution v1
PRAGMA foreign_keys = ON;
BEGIN IMMEDIATE;

CREATE TABLE IF NOT EXISTS sync_entity_state (
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  business_id TEXT,
  server_version INTEGER,
  sync_status TEXT NOT NULL DEFAULT 'local'
    CHECK (sync_status IN ('local','pending','synced','conflict')),
  last_synced_at TEXT,
  last_remote_event_id TEXT,
  PRIMARY KEY (entity_type,entity_id)
);

CREATE TABLE IF NOT EXISTS remote_change_inbox (
  remote_event_id TEXT PRIMARY KEY,
  business_id TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  change_type TEXT NOT NULL,
  server_version INTEGER,
  payload_json TEXT NOT NULL,
  occurred_at TEXT,
  received_at TEXT NOT NULL,
  apply_state TEXT NOT NULL DEFAULT 'pending'
    CHECK (apply_state IN ('pending','applied','conflict','ignored')),
  apply_error TEXT
);

CREATE TABLE IF NOT EXISTS sync_conflict_resolutions (
  id TEXT PRIMARY KEY,
  conflict_id TEXT NOT NULL REFERENCES sync_conflicts(id) ON DELETE RESTRICT,
  resolution_type TEXT NOT NULL
    CHECK (resolution_type IN ('apply_remote','keep_local_and_repush','merged_by_domain_action')),
  resolution_payload_json TEXT NOT NULL DEFAULT '{}',
  resolved_by_user_id TEXT,
  resolved_at TEXT NOT NULL,
  resulting_outbox_id TEXT,
  created_at TEXT NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_sync_conflict_one_resolution
  ON sync_conflict_resolutions(conflict_id);

ALTER TABLE sync_conflicts ADD COLUMN local_version INTEGER;
ALTER TABLE sync_conflicts ADD COLUMN remote_version INTEGER;
ALTER TABLE sync_conflicts ADD COLUMN local_event_id TEXT;
ALTER TABLE sync_conflicts ADD COLUMN remote_event_id TEXT;

INSERT OR IGNORE INTO schema_migrations(version,name,applied_at)
VALUES (5,'pull_conflict_resolution_v1',strftime('%Y-%m-%dT%H:%M:%fZ','now'));

COMMIT;
