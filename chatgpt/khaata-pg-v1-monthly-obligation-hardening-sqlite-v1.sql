-- Khaata PG / Hostel V1 — Monthly Obligation Hardening SQLite v1
-- STATUS: PROPOSED MIGRATION.

PRAGMA foreign_keys = ON;
BEGIN IMMEDIATE;

-- Preserve the canonical one-obligation-per-tenancy/month invariant.
CREATE UNIQUE INDEX IF NOT EXISTS uq_rent_obligation_tenancy_period
  ON obligations(tenancy_id,period_start)
  WHERE obligation_type='rent';

-- Deterministic key remains globally unique inside a business.
CREATE UNIQUE INDEX IF NOT EXISTS uq_rent_obligation_deterministic_key
  ON obligations(business_id,deterministic_key)
  WHERE deterministic_key IS NOT NULL;

-- Faster effective-term lookup.
CREATE INDEX IF NOT EXISTS idx_rent_terms_effective_lookup
  ON rent_terms(tenancy_id,valid_from,valid_to);

-- Helpful eligibility lookup.
CREATE INDEX IF NOT EXISTS idx_tenancies_billing_lifecycle
  ON tenancies(business_id,lifecycle_state,joined_at,ended_at);

-- Audit guard: a posted rent obligation is not silently repurposed into a
-- different period/amount. Corrections belong in adjustment/history flows.
CREATE TRIGGER IF NOT EXISTS trg_rent_obligation_core_no_update
BEFORE UPDATE OF tenancy_id,obligation_type,period_start,period_end,amount_minor,deterministic_key
ON obligations
WHEN OLD.obligation_type='rent'
BEGIN
  SELECT RAISE(ABORT,'posted rent obligation core is immutable; use explicit adjustment/correction');
END;

INSERT OR IGNORE INTO schema_migrations(version,name,applied_at)
VALUES (7,'monthly_obligation_hardening_v1',strftime('%Y-%m-%dT%H:%M:%fZ','now'));

COMMIT;
