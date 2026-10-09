-- Khaata PG / Hostel V1 — Local SQLite Read-Model Views v1
-- STATUS: PROPOSED IMPLEMENTATION READ MODEL.
-- Purpose: derive UI-facing projections from SQLite domain truth.
-- No Home reminder/task table is introduced; attention is derived from underlying state.

PRAGMA foreign_keys = ON;

-- ---------------------------------------------------------------------------
-- Tenant row projection
-- ---------------------------------------------------------------------------

CREATE VIEW IF NOT EXISTS v_tenant_rows AS
SELECT
  t.id AS tenancy_id,
  t.business_id,
  t.lifecycle_state,
  p.display_name AS tenant_name,
  pn.label AS bed_label,
  parent_room.label AS room_label,
  COALESCE(vto.outstanding_minor, 0) AS outstanding_minor,
  t.planned_join_date,
  t.planned_move_out_date,
  t.ended_at
FROM tenancies t
LEFT JOIN tenancy_role_assignments tra
  ON tra.tenancy_id = t.id
 AND tra.role_type = 'occupant'
 AND tra.valid_to IS NULL
LEFT JOIN parties p ON p.id = tra.party_id
LEFT JOIN occupancy_assignments oa
  ON oa.tenancy_id = t.id
 AND oa.assignment_state IN ('planned','active')
LEFT JOIN property_nodes pn ON pn.id = oa.capacity_id
LEFT JOIN property_nodes parent_room ON parent_room.id = pn.parent_id
LEFT JOIN v_tenancy_outstanding vto ON vto.tenancy_id = t.id;

-- ---------------------------------------------------------------------------
-- Current-month collections
-- ---------------------------------------------------------------------------

CREATE VIEW IF NOT EXISTS v_current_month_collections AS
SELECT
  o.business_id,
  o.tenancy_id,
  o.id AS obligation_id,
  o.period_start,
  o.period_end,
  o.due_date,
  o.amount_minor,
  v.outstanding_minor,
  (o.amount_minor - v.outstanding_minor) AS settled_minor
FROM obligations o
JOIN v_obligation_balances v ON v.obligation_id = o.id
WHERE o.period_start = date('now','start of month')
  AND o.obligation_type = 'rent';

-- ---------------------------------------------------------------------------
-- Business Pulse
-- Current month money; point-in-time occupancy.
-- ---------------------------------------------------------------------------

CREATE VIEW IF NOT EXISTS v_business_pulse AS
WITH month_money AS (
  SELECT
    b.id AS business_id,
    COALESCE(SUM(CASE
      WHEN substr(pe.occurred_at,1,7) = strftime('%Y-%m','now')
       AND pe.event_type = 'payment'
      THEN pe.amount_minor ELSE 0 END),0) AS collected_minor
  FROM businesses b
  LEFT JOIN payment_events pe ON pe.business_id = b.id
  GROUP BY b.id
),
outstanding AS (
  SELECT
    t.business_id,
    COALESCE(SUM(vto.outstanding_minor),0) AS outstanding_minor
  FROM tenancies t
  LEFT JOIN v_tenancy_outstanding vto ON vto.tenancy_id = t.id
  GROUP BY t.business_id
),
capacity AS (
  SELECT
    pn.business_id,
    SUM(CASE WHEN pn.node_type='bed' AND pn.lifecycle_state='available' THEN 1 ELSE 0 END) AS known_beds,
    SUM(CASE
      WHEN pn.node_type='bed'
       AND pn.lifecycle_state='available'
       AND NOT EXISTS (
         SELECT 1 FROM occupancy_assignments oa
         WHERE oa.capacity_id = pn.id
           AND oa.assignment_state IN ('planned','active')
       )
      THEN 1 ELSE 0 END) AS vacant_beds
  FROM property_nodes pn
  GROUP BY pn.business_id
),
becoming_vacant AS (
  SELECT
    t.business_id,
    COUNT(*) AS becoming_vacant_this_month
  FROM tenancies t
  WHERE t.lifecycle_state='planned_move_out'
    AND substr(t.planned_move_out_date,1,7)=strftime('%Y-%m','now')
  GROUP BY t.business_id
)
SELECT
  b.id AS business_id,
  mm.collected_minor,
  COALESCE(o.outstanding_minor,0) AS outstanding_minor,
  CASE WHEN COALESCE(c.known_beds,0)=0 THEN NULL ELSE c.vacant_beds END AS vacant_beds,
  COALESCE(bv.becoming_vacant_this_month,0) AS becoming_vacant_this_month
FROM businesses b
LEFT JOIN month_money mm ON mm.business_id=b.id
LEFT JOIN outstanding o ON o.business_id=b.id
LEFT JOIN capacity c ON c.business_id=b.id
LEFT JOIN becoming_vacant bv ON bv.business_id=b.id;

-- ---------------------------------------------------------------------------
-- Needs-attention candidates
-- This intentionally derives only states represented by the current schema.
-- Missing-requirement logic is not invented here because requirements tables
-- are not yet defined in the local schema.
-- ---------------------------------------------------------------------------

CREATE VIEW IF NOT EXISTS v_attention_candidates AS

-- Joining overdue
SELECT
  t.business_id,
  'joining_overdue' AS attention_type,
  'actionable' AS severity,
  t.id AS entity_id,
  'tenancy' AS entity_type,
  t.planned_join_date AS relevant_date,
  NULL AS amount_minor
FROM tenancies t
WHERE t.lifecycle_state='upcoming'
  AND t.planned_join_date IS NOT NULL
  AND t.planned_join_date < date('now')

UNION ALL

-- Overdue obligation
SELECT
  o.business_id,
  'overdue_due' AS attention_type,
  'actionable' AS severity,
  o.id AS entity_id,
  'obligation' AS entity_type,
  o.due_date AS relevant_date,
  v.outstanding_minor AS amount_minor
FROM obligations o
JOIN v_obligation_balances v ON v.obligation_id=o.id
WHERE v.outstanding_minor > 0
  AND o.due_date IS NOT NULL
  AND o.due_date < date('now')

UNION ALL

-- Approval waiting
SELECT
  ar.business_id,
  'approval_waiting' AS attention_type,
  'actionable' AS severity,
  ar.id AS entity_id,
  'approval_request' AS entity_type,
  substr(ar.created_at,1,10) AS relevant_date,
  NULL AS amount_minor
FROM approval_requests ar
WHERE ar.state='pending'

UNION ALL

-- Cash discrepancy
SELECT
  c.business_id,
  'cash_discrepancy' AS attention_type,
  'urgent' AS severity,
  c.id AS entity_id,
  'cash_custody_event' AS entity_type,
  substr(c.occurred_at,1,10) AS relevant_date,
  c.amount_minor AS amount_minor
FROM cash_custody_events c
WHERE c.event_type='discrepancy'
  AND NOT EXISTS (
    SELECT 1 FROM cash_custody_events r
    WHERE r.related_event_id=c.id AND r.event_type='resolution'
  )

UNION ALL

-- Outstanding >= security actually held
SELECT
  t.business_id,
  'outstanding_at_or_above_security' AS attention_type,
  'urgent' AS severity,
  t.id AS entity_id,
  'tenancy' AS entity_type,
  NULL AS relevant_date,
  vto.outstanding_minor AS amount_minor
FROM tenancies t
JOIN v_tenancy_outstanding vto ON vto.tenancy_id=t.id
LEFT JOIN security_accounts sa ON sa.tenancy_id=t.id
LEFT JOIN v_security_balances vsb ON vsb.security_account_id=sa.id
WHERE vto.outstanding_minor > 0
  AND vto.outstanding_minor >= COALESCE(vsb.held_amount_minor,0);

-- ---------------------------------------------------------------------------
-- Coming Up: rolling 7-day forecast
-- ---------------------------------------------------------------------------

CREATE VIEW IF NOT EXISTS v_coming_up AS
SELECT
  t.business_id,
  'joining' AS item_type,
  t.id AS entity_id,
  'tenancy' AS entity_type,
  t.planned_join_date AS event_date
FROM tenancies t
WHERE t.lifecycle_state='upcoming'
  AND t.planned_join_date BETWEEN date('now') AND date('now','+7 day')

UNION ALL

SELECT
  t.business_id,
  'move_out' AS item_type,
  t.id AS entity_id,
  'tenancy' AS entity_type,
  t.planned_move_out_date AS event_date
FROM tenancies t
WHERE t.lifecycle_state='planned_move_out'
  AND t.planned_move_out_date BETWEEN date('now') AND date('now','+7 day')

UNION ALL

SELECT
  o.business_id,
  'rent_due' AS item_type,
  o.id AS entity_id,
  'obligation' AS entity_type,
  o.due_date AS event_date
FROM obligations o
JOIN v_obligation_balances v ON v.obligation_id=o.id
WHERE v.outstanding_minor > 0
  AND o.due_date BETWEEN date('now') AND date('now','+7 day');

-- ---------------------------------------------------------------------------
-- Recent payments / tenant detail helpers
-- ---------------------------------------------------------------------------

CREATE VIEW IF NOT EXISTS v_recent_payments AS
SELECT
  pe.id AS payment_id,
  pe.business_id,
  pe.tenancy_id,
  pe.amount_minor,
  pe.payment_method,
  pe.occurred_at,
  pe.event_type
FROM payment_events pe
ORDER BY pe.occurred_at DESC;
