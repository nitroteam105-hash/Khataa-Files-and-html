# SPEC — Bill Generation, Record Keeping & GST Summary
**Status:** Decisions locked. No code written yet.
**Applies to:** all engines (SUB, APPT, EVENT, JOB, SALE) — billing is shared infrastructure, not engine-specific.
**Constant:** `APP_NAME` used throughout; final name pending trademark check.

---

## 0. Governing position

`APP_NAME` is a **ledger tool with a CA handoff**, not a compliance suite. It never files anything, never calls a government API, never computes input tax credit. The success condition is:

> The owner taps one button and hands their CA a file that needs no follow-up questions.

Consistent with existing out-of-scope decisions (TDS tracking, e-signing, e-way bill API).

### Two rules that govern every screen below

**GST words live on documents, not in the app.** The owner reads plain language; the printed bill and the CA export carry the legal terms. These are the same object named twice, deliberately.

| The owner sees | The document says |
|---|---|
| Customer returned something | Credit Note |
| Charged too little / extra work done | Debit Note |
| Took money before the work | Receipt Voucher |
| Where the work happens | Place of Supply |

**Every GST field is additive.** For an `unregistered` business, HSN, place of supply, tax columns, series pickers and receipt vouchers **do not exist** — not hidden, not disabled, not present-and-empty. A return simply reduces what's owed. Unregistered is the pre-selected default at onboarding, not one of three equal choices.

---

## 1. GST registration mode — the master switch

New onboarding field on **business**, three values. This drives document type, item fields, bill layout, and which summary screen exists. Not a boolean.

| Mode | Document issued | Item GST% | Summary screen |
|---|---|---|---|
| `unregistered` | Plain bill / cash memo | Hidden | **None** — screen not rendered |
| `composition` | **Bill of Supply** | Hidden | Turnover per quarter only |
| `regular` | Tax Invoice | Shown | Full rate-wise + export |

### Additional business fields
- `gstin` — required for `composition` and `regular`, absent for `unregistered`
- `state_code` — seller state, required whenever GST is on; drives IGST determination
- `composition_category` — only when mode is `composition`. Values and rates:
  - Trader — 1%
  - Manufacturer — 1%
  - Restaurant — 5%
  - Service provider (Sec 10(2A)) — 6%
- `turnover_bracket` — `upto_5cr` | `above_5cr`. Drives required HSN digit length (4 vs 6). Default `upto_5cr`.
- `filing_frequency` — `monthly` | `quarterly` (QRMP). Drives the period selector on the summary screen.
- `supply_type` — `goods` | `services` | `mixed`. Drives advance-tax behaviour (§6C) and the interstate registration warning (§5C). Defaulted from the engine, editable.

### Hotel is not one business type
"Hotel" means rooms, food, or both depending on the owner. Handled as capability flags on the business, consistent with the existing capability model — **not** as three separate business types:
- `has_rooms` — enables tariff slabs (§5B), folio billing (§6A), `supplier_location` place of supply
- `has_food` — enables menu items, restaurant rate, `supplier_location` place of supply

A standalone lodge sets rooms only; a standalone eatery sets food only; a hotel with a restaurant sets both. Both flags off is not a valid hotel.

### Mode-specific rules
- **Unregistered:** no tax columns anywhere. No GSTIN field on the customer form either. The GST summary route is not registered at all — not a locked/empty state.
- **Composition:** the bill **must** carry the declaration:
  > *"Composition taxable person, not eligible to collect tax on supplies."*
  This is a fixed, non-editable line on the Bill of Supply layout. Composition businesses cannot collect tax, so per-item GST% is hidden and all tax fields on the bill are zero.
- **Regular:** everything below applies in full.

Mode can be changed after onboarding (businesses do cross the threshold). Changing it does **not** rewrite historical bills — every bill keeps the document type it was issued under. Show a one-time confirmation explaining this.

---

## 2. Document types & numbering

### Document types
1. `tax_invoice` — regular mode only
2. `bill_of_supply` — composition mode only
3. `credit_note`
4. `debit_note`
5. `quotation`
6. `receipt_voucher`

### A business may run several series per doc type
Multiple series are legal so long as each is internally consecutive. A hotel with a restaurant, or a shop with three counters, needs this on day one.

- Series carry a `name` and an `is_default` flag
- **Default is one series, and it is invisible** — no picker, no setup step, nothing to configure
- A second series is auto-created when `has_rooms && has_food`
- A staff member can be bound to a series in Team Access, so their bills always land in their counter's run
- The picker appears at issue **only** when more than one series exists

### Numbering rules (Rule 46(b))
- Consecutive, **unique within a financial year**, resets on **1 April**
- Max **16 characters**, alphanumeric plus `-` and `/` only
- Configurable prefix per series per business (e.g. `SPG/26-27/`)
- Suggested default pattern: `{PREFIX}{FY}-{0000}` — validate total length ≤ 16 and warn at setup if the prefix leaves too few digits

### No deletion, ever
Gaps in an invoice series are an audit red flag. Bills are **never** deleted — not soft-deleted, not archived out of the series. This is the one place the app-wide archive-first deletion pattern does **not** apply. A cancelled bill retains its number, is marked cancelled, and still appears in the series with a strikethrough.

`deleted_at` still exists on the table for schema consistency but must never be populated by any user-facing action.

---

## 3. Bill lifecycle & correction policy

Two document states only:

**`draft`** → freely editable, no number assigned yet, invisible to summaries and exports.
**`issued`** → number assigned. What can be changed depends on how far it has travelled.

Number assignment happens **at the moment of issue**, not at draft creation — otherwise abandoned drafts burn numbers and create gaps.

### A bill locks when it starts to matter

The never-edit rule exists because a filed invoice is matched by someone else — the buyer claims credit against it, and your GSTR-1 carries it. Where nothing is matching, the rule has nothing to protect. So the condition is stated once, and it yields strict behaviour exactly where strictness is warranted.

**Tier 1 — Edit freely.** Not shared, no payment recorded, period still open. Changes leave no trace because nothing has depended on the bill yet.

**Tier 2 — Amend with a trail.** Shared, or paid against, but the GST period is still open. This is the case a registered business hits most: an error spotted before the return goes in. Rather than force a credit note that misrepresents what happened, amend it properly:
- **Same number** — an amendment is not a new invoice
- `amendment_seq` increments; the bill displays and prints as *Amended*
- Reason required, stored
- Full before/after snapshot written to `bill_amendments`
- If already shared: *"Your customer has the old copy. Send the corrected one."*

**Tier 3 — Credit or debit note.** The period has been handed to the CA. Consistent with the period-lock decision this is **warn, not block** — the warning steers to a credit note, and proceeding flags the period as amended after handoff.

```
tier1 = shared_at IS NULL AND NOT has_payment AND period_open
tier3 = period_handed_to_ca
tier2 = everything else
```

Derived, never stored. An unregistered business has no periods, so it never reaches tier 3 — it edits freely until the bill is shared or paid, and amends with a trail after that.

**Team Access:** amendment sits behind the Can-Edit tier. A staff member silently altering an issued bill is an obvious fraud vector.

### Correcting an issued bill
| Situation | Action |
|---|---|
| Error caught before the return goes in | **Amend** — same number, trail kept |
| Wrong bill entirely, not yet acted on | **Cancel** — number retained, marked `cancelled`, never reused |
| Amount too high / goods returned | **Credit Note** against the original |
| Amount too low / undercharged | **Debit Note** against the original |

Cancel requires a reason (free text, stored). Cancel is already a split-out sensitive sub-page in Team Access ("Bills—Cancel") — that permission gates this action.

### Period lock — warn but allow
Owner can mark a period **"Given to CA"** on the summary screen. This does **not** block cancellation. Attempting to cancel a bill inside a marked period shows a hard warning:

> *This period was already given to your CA on {date}. Cancelling now means their filing won't match your records. A Credit Note is usually the safer correction.*

with buttons: **Make a Credit Note** (primary) / **Cancel Anyway** (secondary, destructive styling). If they proceed, the period is flagged `amended_after_handoff` and the summary screen shows a persistent banner listing what changed since handoff.

### Soft warning on credit note timing
Credit notes lose their tax effect after **30 November following the end of the financial year**. Show a non-blocking notice when creating a credit note against a bill older than that. Do not block — the note may still be needed for the customer ledger.

---

## 4. Data model

All money as **integer paise**. All GST rates as **basis points** (18% = `1800`) — never floats. All dates ISO 8601. UUID PKs. `business_id` on every table.

### `bills`
```
id                      uuid pk
business_id             uuid
doc_type                text   -- tax_invoice | bill_of_supply | credit_note
                               -- | debit_note | quotation | receipt_voucher
series_id               uuid   -- fk bill_number_series
number                  text   -- null while draft
financial_year          text   -- '2026-27'
status                  text   -- draft | issued | cancelled
                               -- quotations also: sent | accepted | declined
                               -- | expired | converted
issue_date              text
cancelled_at            text
cancel_reason           text
against_bill_id         uuid   -- credit/debit notes only

-- quotation fields
valid_until             text   -- quotations only
revision                int    -- 1, 2, 3... same number, suffixed
from_quote_id           uuid   -- set on bills converted from a quote

-- advance fields
advance_adjusted_paise  int    -- advances applied against this bill
adjusts_receipt_ids     text   -- json array of receipt_voucher bill ids

draft_label             text   -- long-lived drafts: 'Room 204 — Sharma'
shared_at               text   -- first print / WhatsApp / PDF; drives the lock tier
amendment_seq           int    -- 0 = never amended
created_by              uuid   -- fk users; never null
created_by_name_snap    text   -- 'Ravi' stays on the bill after Ravi leaves
issued_by               uuid   -- may differ: staff drafts, owner issues
cancelled_by            uuid
device_id               text   -- which till/counter it came from
job_id                  uuid   -- nullable; null for counter/SALE bills
milestone_id            uuid   -- which milestone this bill raises
pos_rule_applied        text   -- frozen at issue: which rule decided the tax

customer_id             uuid   -- nullable (walk-in)
cust_name_snap          text
cust_mobile_snap        text
cust_gstin_snap         text
cust_address_snap       text
cust_state_code_snap    text
place_of_supply_state   text

layout                  text   -- classic | retail | subscription | shipment | tally
is_igst                 int    -- derived at issue, then frozen

subtotal_paise          int    -- sum of line taxable values
discount_paise          int    -- bill-level only
freight_paise           int
packing_paise           int
cgst_paise              int
sgst_paise              int
igst_paise              int
cess_paise              int
round_off_paise         int    -- signed, ±99 max
grand_total_paise       int

previous_balance_paise  int    -- subscription layout
notes                   text
ref_fields              text   -- json blob: tally/shipment reference fields
created_at, updated_at, deleted_at
```

### `bill_lines`
```
id                  uuid pk
bill_id             uuid
business_id         uuid
sort_order          int
item_id             uuid   -- nullable; free-text lines allowed
description_snap    text
hsn_snap            text   -- nullable
unit_snap           text
qty                 numeric
rate_paise          int
gst_rate_bp         int
taxable_paise       int
cgst_paise          int
sgst_paise          int
igst_paise          int
cess_paise          int
line_total_paise    int
```

Every `_snap` field is written at issue time and never updated — protects history when the item master is later edited. Extends the existing "bills snapshot price/tax/unit at sale time" rule to cover HSN, unit and description.

### `bill_number_series`
```
id, business_id, doc_type, financial_year,
name, is_default, prefix, next_number, created_at
```
Unique index on `(business_id, doc_type, financial_year, name)`.

### `job_milestones`
One mechanism for every "bill for the part that's due" pattern — percentage, line subset, or scheduled installment.
```
id, business_id, job_id, seq, name,
basis          -- pct | amount | lines
pct_bp         -- basis points of job value
amount_paise
line_ids       -- json array
due_date       -- optional, for scheduled installments
status         -- pending | ready | invoiced
bill_id        -- set when invoiced
created_at, updated_at, deleted_at
```

Every existing billing pattern collapses into this one shape:
- *50% advance, 50% on completion* → two `pct` milestones
- *Board now, installation next month* → two `lines` milestones
- *Foundation / slab / plaster* → three `pct` or `amount` milestones tied to civil stages
- *Monthly installments* → `amount` milestones with due dates
- *Bill it all at once* → one auto-created milestone, **never shown to the owner**

**Guard:** milestones must sum to exactly the job value. `pct` rounding uses the largest-remainder method, and the final milestone absorbs any drift, so a job always bills to its contract value to the paise.

Civil's existing stage billing points at this table rather than keeping its own.

### `bill_amendments`
```
id, business_id, bill_id, seq, amended_at, amended_by,
reason, before_snapshot (json), after_snapshot (json)
```
Written on every tier-2 amendment. This is the trail that makes in-place correction defensible — the original figures are never lost, only superseded.

### `gst_periods`
```
id, business_id, period_start, period_end, frequency,
handed_to_ca_at, amended_after_handoff, created_at
```

### Item master addition
```
hsn_code  text  -- nullable, optional
```

---

## 4A. Who did what — actor attribution

Multi-user access is a Premium feature, but **actor columns go on every table from day one**, exactly as `business_id` does. A shop that adds its first staff member two years in must not trigger a migration that back-fills `created_by` across thousands of historical bills — there is no correct value to back-fill with.

### `users`
```
id                 uuid pk       -- generated locally, stable across sync
business_ids       text          -- json array; a user may span businesses
name, phone
role               text          -- owner | staff
supabase_user_id   text          -- null until cloud sync is switched on
series_id          uuid          -- optional counter binding (§2)
active             int
created_at, updated_at, deleted_at
```

**Free tier still has a users row.** One implicit owner, auto-created at onboarding, never shown in the UI. `created_by` always points somewhere; the schema is identical in every tier. Upgrading to Premium adds users — it does not change shape.

### Actor columns required
| Table | Columns |
|---|---|
| `bills` | `created_by`, `issued_by`, `cancelled_by`, `device_id` |
| `bill_amendments` | `amended_by` |
| payments | `recorded_by` — the highest-value one; see below |
| `job_milestones` | `marked_ready_by`, `invoiced_by` |
| `gst_periods` | `handed_to_ca_by` |

**Name snapshots.** Store `created_by_name_snap` alongside the FK, per the existing snapshot rule. A bill should still read *"Made by Ravi"* after Ravi leaves and his record is archived.

### Why payments matter more than bills

Attribution on a bill is mostly audit. Attribution on a **cash payment** is the feature. *"Ravi collected ₹12,400 in cash today"* is an end-of-shift reconciliation an owner can actually act on, and it's the single thing a notebook cannot do once there's more than one person at the counter. Worth surfacing as a screen, not just a column.

### An unexpected benefit for cloud sync

The lock tiers (§3) shrink the sync conflict surface almost to nothing. An issued bill never mutates — amendments are **append-only rows** in `bill_amendments`, not edits to the bill. So the only genuinely mutable records are drafts, where last-write-wins is acceptable. Two people cannot silently overwrite each other's issued invoices, because issued invoices aren't writable.

This is worth holding onto when cloud sync design starts.

### Permission interaction
Building on the existing View / Can-Edit model plus split sensitive sub-pages:
- Create a bill → Can-Edit
- **Amend** an issued bill → Can-Edit, and always logged with the actor
- **Cancel** → the existing split "Bills—Cancel" sub-page
- **GST export** → the split "GST—Export" sub-page
- Record a payment → Can-Edit; viewing *other people's* collections is owner-only

---

## 5. Calculation rules

**Order of operations:**
1. Line taxable value = `qty × rate` − line discount
2. Bill-level discount apportioned across lines by taxable value using the **largest-remainder method** (same as dairy credits and flat expense splitting) — so the parts sum exactly to the whole
3. Tax computed **per line**, rounded to paise, half-up
4. Line taxes summed to bill totals — never compute tax on the bill subtotal
5. Freight and packing added post-tax (shipment layout)
6. Round-off to nearest rupee, stored in `round_off_paise` as a signed value so totals always reconcile

**CGST/SGST vs IGST:** compare `business.state_code` against `place_of_supply_state`. Same → CGST + SGST, each at half the rate. Different → IGST at the full rate. Determined at issue and frozen in `is_igst` — later edits to a customer's address must not silently restate an issued bill.

---

## 5A. Place of supply — three rules, not one

The earlier "compare seller state to buyer state" rule is **wrong for a large share of our users**. An out-of-state guest at a hotel still pays CGST+SGST, because accommodation is taxed where the property sits. Applying the naive rule would produce silently incorrect tax on every such bill.

New field `pos_rule` on the **item**, defaulted per engine, overridable:

| Rule | Place of supply is | Typical users |
|---|---|---|
| `customer_state` | The customer's state (fall back to seller's own for walk-in B2C) | **Default.** Supermarket, oil, all goods |
| `supplier_location` | Always the seller's own state, regardless of customer | Hotel rooms, restaurant, salon, gym, any service performed on the seller's premises |
| `property_location` | The site address entered on the bill | Signboard installation, civil works, anything fixed to immovable property |

**Engine defaults:** SALE → `customer_state`. APPT / EVENT → `supplier_location`. JOB → `property_location`. SUB → `customer_state`.

`property_location` is the case that's neither party's home state — a Karnataka signboard firm installing in Tamil Nadu for a Maharashtra-registered client charges IGST on Tamil Nadu as the place of supply. The site address already exists in the civil/construction screens; reuse it.

**Mixed bills are usually not mixed.** Design, fabrication and installation sold together as one signboard is a **composite supply** — naturally bundled, taxed as the principal supply, one place of supply for the whole invoice.

So `pos_rule` resolves at the **bill level**, from the principal line (highest taxable value), not per line. Where lines disagree, show a quiet note — *"Taxed as one supply, following the signboard installation"* — and offer **Split into two bills** as a one-tap action. Never block. Only block when the owner has explicitly marked lines as separate supplies.

**Transparency:** whenever the rule is not `customer_state`, show a one-line explainer under the tax block — *"Charged as CGST+SGST because the stay is in Karnataka."* Owners get asked this by customers and need an answer.

`pos_rule_applied` is frozen on the bill at issue.

---

## 5B. Rate resolution — the item holds a default, not the truth

Room tariff is slab-based: the rate depends on the nightly value, so the same room crosses slabs between off-season and peak. GST% therefore **cannot** be a fixed property of the item.

New field `rate_source` on the item:
- `fixed` — single rate. **Default**, covers almost everything.
- `slab` — resolved at bill time from the per-unit value

### `rate_slabs`
```
id, business_id, item_id (nullable = business-wide),
upto_paise (null = no upper bound), gst_rate_bp, sort_order
```

Resolution uses the **per-unit rate**, not the line total — a three-night stay doesn't push a room into a higher slab. Resolved rate displays inline on the bill line with a tap-to-explain. Once issued it's frozen in `bill_lines.gst_rate_bp` like any other rate.

**All slab boundaries and rates are data, never code.** The rate structure has been revised recently enough that every specific figure in this spec must be verified at build time and stored as editable config.

---

## 5C. Interstate registration warning

Interstate supply of **goods** requires GST registration regardless of turnover. When an `unregistered` business with `supply_type` of goods or mixed records a sale where the place of supply differs from its own state, show a non-blocking notice:

> *Selling goods to another state usually requires GST registration, whatever your turnover. Worth checking with your CA.*

Non-blocking, dismissible, shown at most once per month. Relevant to the oil business the moment it takes its first out-of-state order.

---

**Place of supply default:** per §5A. Always editable on the bill.

**0% / exempt / nil-rated:** all handled as `gst_rate_bp = 0` in v1. The GSTR-1 distinction between nil-rated, exempt, and non-GST supplies is deliberately not modelled — noted as a known simplification for the CA to adjust.

---

## 5D. Registration threshold nudge

An unregistered business that crosses the turnover threshold must register within 30 days. They are the least likely of all users to be watching for it — that's what makes them unregistered. This and §5C are the **only** two GST things an unregistered user ever sees.

**What gets counted.** The threshold applies to **aggregate turnover at PAN level** — the person's total across every business, not one business alone. So the check sums all of the owner's businesses. The screen shows **both**: the per-business figure they recognise, and the combined figure that actually decides it.

**Trigger.** A simple level check at a configurable percentage of the threshold — starting point 80%, adjustable. No run-rate projection in v1.

**Guards.**
- Doesn't fire below ~6 months of recorded history; a local-first app has no earlier data to reason from
- Fires once, dismissible, never repeats
- Wording **suggests, never asserts** — aggregate turnover includes exempt and export supplies, so recorded sales are a proxy, not the real figure

> *Your sales across all your businesses are getting close to the point where GST registration becomes compulsory. Worth a word with a CA.*

**Thresholds are config, and are not a single number.** ₹40L applies only to a supplier dealing **exclusively in goods**; adding any service drops it to ₹20L, and special-category states are lower again. Verify all figures at build time.

---

## 6. HSN handling — optional, never blocking

- Lives on the item master, snapshots to the bill line at issue
- **Never blocks a bill.** No validation gate, no red field, no modal.
- Required digit length derived from `turnover_bracket`: 4 digits at or below ₹5cr, 6 above. Validate length only if a value is entered.
- Lines without HSN roll into an **"Unclassified"** bucket in the HSN summary
- The nudge lives on the **export screen only**, as a count with a shortcut:
  > *12 items have no HSN code — your CA may ask for these.* → **Add codes**
- Bulk-fill screen: list of distinct items used in the period that lack an HSN, one field each, save all at once. Filling it updates the item master going forward but **does not** rewrite already-issued bills.

**The bulk-fill screen does not scale.** A supermarket carries thousands of SKUs; hand-typing HSN codes one field at a time is not a real workflow. The primary path for high-SKU businesses is the **existing CSV/Excel item import** — add HSN as a mappable column in the auto-column-mapping step. Bulk-fill remains the path for small catalogues and for cleaning up stragglers. If more than ~50 items are missing HSN, the export screen should route to CSV import instead of bulk-fill.

---

## 6A. Long-lived drafts (folio billing)

A hotel stay accumulates charges over several days and bills once at checkout. The existing draft/issued model already supports this — a draft is editable and carries no number — but it assumes drafts are short-lived.

Additions:
- `draft_label` on the bill, so an open folio is identifiable as *"Room 204 — Sharma"* rather than an untitled draft
- Open drafts get their own list, searchable by label, surfaced on the dashboard when `has_rooms` is on
- Drafts never appear in GST summaries or exports, and never consume a number
- Warn on drafts older than a configurable age (default 30 days) — an abandoned folio is usually a mistake, occasionally an unbilled stay

---

## 6B. Quotations

Signboard, civil and most JOB-engine work runs quote → approval → invoice. A quote is not a bill: **no GST liability, no tax invoice number, never in any summary or export.**

Per "extend don't multiply," quotations live in the **same `bills` table** as `doc_type = 'quotation'` rather than in parallel tables — the structure is otherwise identical. The safety mechanism is a single named constant:

```
GST_DOC_TYPES = [tax_invoice, bill_of_supply, credit_note, debit_note, receipt_voucher]
```

Every GST summary and export query filters on it. Quotations and drafts can never leak in through a forgotten `WHERE` clause because there is exactly one place that list is defined.

### Quote behaviour
- Own numbering series (`QT/` prefix). The 16-character and financial-year rules are legal requirements for invoices only, but reuse the same mechanism for consistency.
- `valid_until` date, with automatic `expired` status past it
- Status: `draft` → `sent` → `accepted` / `declined` / `expired` / `converted`
- **Revisions keep the number** and increment `revision` — `QT/26-27/0042 r2`. A revised quote is not a new quote; the customer is negotiating one thing.

### An accepted quote creates the job
Acceptance is what turns a price into work. On acceptance:
- A **job** is created, with the quote's total as its contract value
- A **billing plan** is set — either one milestone for the whole amount (default, invisible) or several
- Every document that follows — advances, milestone invoices, credit notes — carries the same `job_id`

This is what makes *"how much is left on the Ashwin Motors job?"* answerable. It's the most common question a signboard or civil owner asks, and without `job_id` it has no answer at all.

### Converting to an invoice
- **Raise a milestone**, not a subset of lines. The milestone defines what's billed — a percentage, a set of lines, or a fixed amount.
- Prices may have moved since the quote. Prompt: **use quoted prices** (default) or **use current prices** — never silently re-price, and never silently honour a stale quote.
- The job stays open until every milestone is invoiced or the owner closes it

### Quotes are a Vasooli input
Unanswered quotes are already part of the money-recovery framing. A `sent` quote with no response past a threshold belongs in the follow-up list alongside unpaid bills — it's the same product promise, one step earlier in the cycle.

---

## 6C. Advances

**Where these live.** Credit notes, debit notes and receipt vouchers are **actions on a bill**, not a top-level destination. The owner opens the Suresh Traders bill and taps *Customer returned something*; the app decides it's a credit note, picks the series, mirrors the original rates and prints it correctly. An adjustments list still exists under Records for anyone who thinks in documents — it just isn't the front door.

The signboard business takes money before work starts. Under GST the treatment splits on what's being supplied:

- **Goods** — no tax on the advance. It's a plain money-in event against the customer ledger.
- **Services** (including works contract, which is a service) — tax is due when the advance is received, then adjusted against the final invoice.

### Behaviour by `supply_type`
- `goods` → advances are ordinary money-in events. **No receipt voucher, no tax, no extra UI.** DMart and the oil business never see any of this.
- `services` / `mixed` → prompt on receiving an advance: *"Is this against a taxable service?"* If yes, generate a **Receipt Voucher** (`doc_type = 'receipt_voucher'`, own series) carrying rate-wise tax.

### Adjustment
On the final invoice, advances applied appear as an **Advance adjusted** line reducing the amount payable, with `advance_adjusted_paise` and `adjusts_receipt_ids` recorded. The tax already paid on the advance is not charged twice.

The summary must report **advances received** and **advances adjusted** as separate blocks — netting them hides exactly what the CA needs to see.

### Deliberately not built
Refund vouchers for unadjusted advances, and advance adjustment across financial years. Both are rare at this scale and genuinely intricate. Flag them in the export's Data Issues sheet if an advance sits unadjusted past period end, and let the CA handle it.

**This is the heaviest thing in the spec relative to how many users need it.** It only applies to registered service businesses taking money upfront. Keeping it fully invisible for `supply_type = goods` is not an optimisation — it's the thing that stops a shopkeeper meeting tax machinery they'll never need.

---

## 7. GST Summary screen

Route exists only for `composition` and `regular`. Entry point sits inside monthly statements (replacing the current stub).

### Composition mode
Deliberately minimal — a CMP-08 aid.
- Quarter selector
- **Total turnover** for the quarter (hero number)
- **Estimated tax @ {rate}% = ₹X** — labelled *Estimate*, with a one-line caption: *Your CA will confirm the final figure.*
- Bill count, and count of cancelled bills
- Export button

### Regular mode
Period selector: month, or quarter when `filing_frequency = quarterly`.

**Blocks, in order:**
1. **Hero** — total taxable value, total tax, bill count
2. **Rate-wise table** — Rate | Taxable | CGST | SGST | IGST | Total. One row per distinct rate, plus a totals row
3. **B2B vs B2C split** — B2B = customer has a GSTIN. Counts and values only; the detail lives in the export
4. **Credit / Debit Notes** — separate block, shown as negative/positive adjustments, never netted into the main table
5. **Advances received** — rate-wise, tax due on receipt. Hidden entirely when `supply_type = goods`
6. **Advances adjusted** — rate-wise, against invoices in this period. Never netted against block 5
7. **Document series** — per series: from number, to number, total issued, cancelled count. This is Table 13 of GSTR-1 and CAs ask for it every time
8. **HSN summary** — grouped by HSN where present, with the Unclassified bucket
9. **Data issues** — missing GSTIN on B2B-looking customers, missing HSN, bills with no place of supply, unadjusted advances past period end. Each row taps through to fix
10. **Given to CA** toggle + export button

Cancelled bills are excluded from all value totals but **always shown in the document series block** — that's the whole point of retaining their numbers.

### Performance — the summary must not be derived live at scale

A supermarket does thousands of bills a month. Aggregating ~100k `bill_lines` on phone SQLite every time the screen opens will not hold up.

Resolution: a **cache, not a second source of truth.**

```
gst_period_rollup
  id, business_id, period_start, period_end,
  bucket        -- b2b | b2c | cdn | advance_received | advance_adjusted
  gst_rate_bp, taxable_paise, cgst_paise, sgst_paise, igst_paise, cess_paise,
  computed_at, stale int
```

- Marked `stale` whenever a bill in that period is issued or cancelled
- Recomputed on screen open if stale, otherwise read straight from cache
- **Fully derivable from `bills` + `bill_lines` at any time.** Droppable and rebuildable, never synced, never exported from. This keeps "store events, derive summaries" intact — the rollup is a materialised read, not a record.
- Exports always recompute from source rather than reading the cache. An export is worth the extra second.

**Required indexes:** `bills(business_id, status, issue_date)`, `bills(business_id, doc_type, financial_year)`, `bill_lines(bill_id)`, `bill_lines(business_id, gst_rate_bp)`.

---

## 8. CA export — multi-sheet Excel

One `.xlsx` file, named `{Business}-GST-{Period}.xlsx`. Sheets:

| Sheet | Contents |
|---|---|
| **Summary** | Business name, GSTIN, mode, period, rate-wise totals, grand totals |
| **B2B** | Invoice-wise: GSTIN, customer, invoice no., date, place of supply, reverse charge (always N), invoice value, rate, taxable, CGST, SGST, IGST, cess |
| **B2C Large** | Inter-state B2C above the threshold, invoice-wise. **Threshold stored as a config constant, not hardcoded** — it has changed and will change again. Flag for verification against current rules before launch. |
| **B2C Small** | Consolidated by place of supply and rate |
| **Credit-Debit Notes** | Note no., date, original invoice no. and date, type, rate-wise values |
| **HSN Summary** | HSN, description, UQC, total quantity, taxable value, tax amounts. Unclassified rows last |
| **Document Series** | Series, from, to, total, cancelled |
| **All Bills** | Flat dump of every bill in the period including cancelled, for reconciliation |
| **Amendments** | Bills corrected after issue: number, what changed, before and after values, reason, date. GSTR-1 has its own amendment tables, and a CA cannot reconcile a silently changed figure |
| **Data Issues** | Every gap flagged on screen, so the CA sees them too |

Column headers use the exact GSTR-1 terminology CAs recognise, not app-internal names.

**Tally XML export is Phase 2** — deferred, not dropped. The Tally reference fields already captured on the bill form are the groundwork. GST portal JSON is **rejected outright**: version-locked, brittle, and it implies a filing capability the app deliberately doesn't have.

---

## 9. Interaction with existing systems

- **Vasooli / money recovery:** issuing a bill creates a receivable event. Payments are separate dated events. Payment status (`unpaid` / `partial` / `paid`) is **always derived, never stored** — consistent with "store events, derive summaries." Document status and payment status stay independent, per the two-state rule.

### The follow-up list is one view with exactly three sources

| Source | The ask |
|---|---|
| Issued bills unpaid or part-paid past terms | Chase the payment |
| Sent quotes with no reply past threshold | Chase the decision |
| **Completed milestones never invoiced** | Raise the bill |

The third is the strongest of the three and only exists once jobs and milestones do. Work finished and never billed is pure leakage — invisible in a notebook, and the kind of find that pays for the subscription on its own.

**Advances are not a follow-up source.** An unadjusted advance is money *you hold* and owe work against — the opposite of something to chase. It gets a separate, quieter tile — *"₹57,400 held against work not yet done"* — and a flag in the export's Data Issues sheet.

Implemented as **one derived view** (`type, party, job, amount, age, suggested_action`). Every screen's hero is a filter over that view, never its own calculation.
- **Team Access:** "Bills—Cancel" already exists as a split sensitive sub-page. Add **"GST—Export"** as a second one; turnover data is exactly the kind of thing a shop assistant shouldn't be able to email out.
- **Bill layouts:** all five existing layouts remain. Bill of Supply is a **constraint on** the chosen layout (tax columns hidden, declaration added), not a sixth layout.
- **Pick-or-add-and-remember** applies to HSN codes like every other list field.

---

## 10. Explicitly out of scope

Input tax credit, purchase-side GST, and GSTR-2B reconciliation — ITC is determined by what suppliers filed, not by the owner's own records, so an app-computed figure would confidently contradict the portal. Purchases will be captured later as expense records with optional GST fields, for profit tracking, with the tax total falling out as a by-product.

Also out: e-invoicing / IRN (applies above ₹5cr turnover — above our user base), exports and SEZ supplies, reverse charge, amended-invoice tables, TDS, e-signing, any government API call.

---

## 11. Open items

Everything below is a figure that has changed before and will change again. **None of it belongs in code.** All of it is editable config, verified at build time.

- [ ] B2C Large inter-state threshold
- [ ] Composition scheme rates per category
- [ ] Room tariff slab boundaries and rates
- [ ] Restaurant rate, standalone vs within a hotel above the tariff threshold
- [ ] Works contract rate
- [ ] HSN digit requirement by turnover bracket
- [ ] Default invoice prefix pattern per business type — note a high-volume shop needs 6 digits, which leaves very little room inside the 16-character limit. Warn at setup.
- [ ] Tally XML export — Phase 2 scoping
- [ ] Quote follow-up threshold for Vasooli (how many days of silence before a sent quote surfaces)
