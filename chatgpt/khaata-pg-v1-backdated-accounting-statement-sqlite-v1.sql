-- Khaata PG / Hostel V1 — Backdated Accounting + Tenant Statement SQLite v1
-- STATUS: PROPOSED IMPLEMENTATION MIGRATION.
--
-- Frozen product rules:
-- * Backdated tenancy offers:
--     A) Bring existing history
--     B) Start accounting from date
-- * Path B records explicit opening:
--     Outstanding balance
--     Security actually held
--     Tenant credit
-- * Opening figures are NOT fabricated payments, charges or deposit receipts.
-- * Tenant statement distinguishes opening figures from Khaata-recorded activity.
-- * Security remains separate from rent / charge balance.
-- * Statement history survives move-out.

PRAGMA foreign_keys = ON;
BEGIN IMMEDIATE;

CREATE TABLE IF NOT EXISTS tenancy_accounting_starts (
  id TEXT PRIMARY KEY,
  business_id TEXT NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
  tenancy_id TEXT NOT NULL UNIQUE REFERENCES tenancies(id) ON DELETE RESTRICT,
  accounting_path TEXT NOT NULL
    CHECK (accounting_path IN ('bring_existing_history','start_from_date')),
  accounting_start_date TEXT NOT NULL,
  created_at TEXT NOT NULL,
  created_by_user_id TEXT
);

CREATE TABLE IF NOT EXISTS opening_financial_positions (
  id TEXT PRIMARY KEY,
  business_id TEXT NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
  tenancy_id TEXT NOT NULL UNIQUE REFERENCES tenancies(id) ON DELETE RESTRICT,
  accounting_start_id TEXT NOT NULL UNIQUE
    REFERENCES tenancy_accounting_starts(id) ON DELETE RESTRICT,
  effective_date TEXT NOT NULL,
  opening_outstanding_minor INTEGER NOT NULL DEFAULT 0
    CHECK (opening_outstanding_minor >= 0),
  opening_tenant_credit_minor INTEGER NOT NULL DEFAULT 0
    CHECK (opening_tenant_credit_minor >= 0),
  opening_security_held_minor INTEGER NOT NULL DEFAULT 0
    CHECK (opening_security_held_minor >= 0),
  note TEXT,
  created_at TEXT NOT NULL,
  created_by_user_id TEXT
);

-- Opening positions are snapshots of the starting point, not editable live totals.
CREATE TRIGGER IF NOT EXISTS trg_opening_financial_positions_no_update
BEFORE UPDATE ON opening_financial_positions
BEGIN
  SELECT RAISE(ABORT,'opening financial position is immutable; correct explicitly');
END;

CREATE TRIGGER IF NOT EXISTS trg_opening_financial_positions_no_delete
BEFORE DELETE ON opening_financial_positions
BEGIN
  SELECT RAISE(ABORT,'opening financial position is historical accounting truth');
END;

CREATE TABLE IF NOT EXISTS opening_position_corrections (
  id TEXT PRIMARY KEY,
  opening_position_id TEXT NOT NULL
    REFERENCES opening_financial_positions(id) ON DELETE RESTRICT,
  correction_type TEXT NOT NULL
    CHECK (correction_type IN ('outstanding','tenant_credit','security_held')),
  amount_delta_minor INTEGER NOT NULL CHECK (amount_delta_minor <> 0),
  reason TEXT NOT NULL CHECK (length(trim(reason)) > 0),
  occurred_at TEXT NOT NULL,
  created_at TEXT NOT NULL,
  created_by_user_id TEXT
);

CREATE TRIGGER IF NOT EXISTS trg_opening_position_corrections_no_update
BEFORE UPDATE ON opening_position_corrections
BEGIN
  SELECT RAISE(ABORT,'opening position corrections are append-only');
END;

CREATE TRIGGER IF NOT EXISTS trg_opening_position_corrections_no_delete
BEFORE DELETE ON opening_position_corrections
BEGIN
  SELECT RAISE(ABORT,'opening position corrections are append-only');
END;

-- Effective opening position after explicit corrections.
CREATE VIEW IF NOT EXISTS v_opening_financial_position_effective AS
SELECT
  op.id AS opening_position_id,
  op.business_id,
  op.tenancy_id,
  op.effective_date,
  op.opening_outstanding_minor
    + COALESCE(SUM(CASE WHEN c.correction_type='outstanding'
      THEN c.amount_delta_minor ELSE 0 END),0) AS opening_outstanding_minor,
  op.opening_tenant_credit_minor
    + COALESCE(SUM(CASE WHEN c.correction_type='tenant_credit'
      THEN c.amount_delta_minor ELSE 0 END),0) AS opening_tenant_credit_minor,
  op.opening_security_held_minor
    + COALESCE(SUM(CASE WHEN c.correction_type='security_held'
      THEN c.amount_delta_minor ELSE 0 END),0) AS opening_security_held_minor
FROM opening_financial_positions op
LEFT JOIN opening_position_corrections c
  ON c.opening_position_id=op.id
GROUP BY op.id;

-- Live receivable position.
-- Security is intentionally excluded from net receivable.
CREATE VIEW IF NOT EXISTS v_tenancy_financial_position AS
SELECT
  t.id AS tenancy_id,
  t.business_id,
  COALESCE(vto.outstanding_minor,0) AS khaata_outstanding_minor,
  COALESCE(ofp.opening_outstanding_minor,0) AS opening_outstanding_minor,
  COALESCE(ofp.opening_tenant_credit_minor,0) AS opening_credit_minor,
  MAX(
    COALESCE(vto.outstanding_minor,0)
    + COALESCE(ofp.opening_outstanding_minor,0)
    - COALESCE(ofp.opening_tenant_credit_minor,0),
    0
  ) AS net_outstanding_minor,
  MAX(
    COALESCE(ofp.opening_tenant_credit_minor,0)
    - COALESCE(vto.outstanding_minor,0)
    - COALESCE(ofp.opening_outstanding_minor,0),
    0
  ) AS available_credit_minor,
  COALESCE(ofp.opening_security_held_minor,0) AS opening_security_held_minor,
  COALESCE(vsb.held_amount_minor,0) AS khaata_security_held_minor,
  COALESCE(ofp.opening_security_held_minor,0)
    + COALESCE(vsb.held_amount_minor,0) AS total_security_held_minor
FROM tenancies t
LEFT JOIN v_tenancy_outstanding vto ON vto.tenancy_id=t.id
LEFT JOIN v_opening_financial_position_effective ofp ON ofp.tenancy_id=t.id
LEFT JOIN security_accounts sa ON sa.tenancy_id=t.id
LEFT JOIN v_security_balances vsb ON vsb.security_account_id=sa.id;

-- Statement transport projection.
-- Opening rows are explicitly typed and remain distinct from real payments/events.
CREATE VIEW IF NOT EXISTS v_tenant_statement_entries AS

SELECT
  op.tenancy_id,
  op.business_id,
  'opening_outstanding' AS entry_type,
  op.id AS entry_id,
  op.effective_date || 'T00:00:00Z' AS occurred_at,
  op.opening_outstanding_minor AS debit_minor,
  0 AS credit_minor,
  'Opening outstanding balance' AS label,
  1 AS is_opening
FROM v_opening_financial_position_effective op
WHERE op.opening_outstanding_minor > 0

UNION ALL

SELECT
  op.tenancy_id,
  op.business_id,
  'opening_credit',
  op.id,
  op.effective_date || 'T00:00:00Z',
  0,
  op.opening_tenant_credit_minor,
  'Opening tenant credit',
  1
FROM v_opening_financial_position_effective op
WHERE op.opening_tenant_credit_minor > 0

UNION ALL

SELECT
  o.tenancy_id,
  o.business_id,
  CASE WHEN o.obligation_type='rent' THEN 'rent_obligation' ELSE 'charge_obligation' END,
  o.id,
  COALESCE(o.due_date,o.created_at),
  o.amount_minor,
  0,
  CASE WHEN o.obligation_type='rent' THEN 'Rent due' ELSE 'Charge due' END,
  0
FROM obligations o
WHERE o.obligation_type IN ('rent','charge','opening_balance')

UNION ALL

SELECT
  pe.tenancy_id,
  pe.business_id,
  CASE WHEN pe.event_type='payment' THEN 'payment' ELSE 'payment_reversal' END,
  pe.id,
  pe.occurred_at,
  CASE WHEN pe.event_type IN ('reversal','chargeback') THEN pe.amount_minor ELSE 0 END,
  CASE WHEN pe.event_type='payment' THEN pe.amount_minor ELSE 0 END,
  CASE WHEN pe.event_type='payment' THEN 'Payment received' ELSE 'Payment reversal' END,
  0
FROM payment_events pe

UNION ALL

SELECT
  fa.tenancy_id,
  fa.business_id,
  'adjustment',
  fa.id,
  fa.occurred_at,
  0,
  fa.amount_minor,
  fa.adjustment_type,
  0
FROM financial_adjustments fa;

-- Security statement is kept separate from the rent/charge statement.
CREATE VIEW IF NOT EXISTS v_tenant_security_statement AS

SELECT
  op.tenancy_id,
  op.business_id,
  'opening_security_held' AS entry_type,
  op.id AS entry_id,
  op.effective_date || 'T00:00:00Z' AS occurred_at,
  op.opening_security_held_minor AS amount_minor,
  'Opening security actually held' AS label,
  1 AS is_opening
FROM v_opening_financial_position_effective op
WHERE op.opening_security_held_minor > 0

UNION ALL

SELECT
  sa.tenancy_id,
  t.business_id,
  se.event_type,
  se.id,
  se.occurred_at,
  se.amount_minor,
  CASE se.event_type
    WHEN 'deposit_received' THEN 'Security received'
    WHEN 'applied_to_dues' THEN 'Security applied to dues'
    WHEN 'refund' THEN 'Security refunded'
    ELSE 'Security correction'
  END,
  0
FROM security_events se
JOIN security_accounts sa ON sa.id=se.security_account_id
JOIN tenancies t ON t.id=sa.tenancy_id;

INSERT OR IGNORE INTO schema_migrations(version,name,applied_at)
VALUES (8,'backdated_accounting_statement_v1',strftime('%Y-%m-%dT%H:%M:%fZ','now'));

COMMIT;
