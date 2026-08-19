# HANDOFF — Committee/Chit + Lending

**Status:** Decisions locked. Mockups built. Nothing implemented.
**Prerequisite:** Do not start this before M3 (expo-router + New Bill screen) is verified on a physical device, and before offline bill numbering across staff devices is resolved.

---

## 1. Scope of this session

Three business-type candidates were assessed. Two accepted, one rejected.

| Candidate | Verdict | Engine |
|---|---|---|
| Committee / chit group | **Accepted** | SUB + per-period amount override |
| Gold chit / jeweller savings scheme | **Rejected** | — |
| Moneylending (owner-side record-keeping) | **Accepted, deferred build** | New screens, reuses `customers` |

---

## 2. Committee / chit group

### Verdict
Fits SUB with one extension. Buildable at low cost.

### Required extension
SUB currently assumes a fixed recurring amount. Committee groups need a **per-period announced amount** — the organiser declares "this month everyone pays ₹4,200" and the app records it. The same extension serves society maintenance with extra levies and tuition with exam fees.

### Data model
- `chit_group` — name, total value, ticket count, duration, start month, payout method stored as a **label only** (lottery / auction / fixed order)
- `chit_member` — FK to `customers`, plus `ticket_share` (1 or 0.5, supports multiple tickets)
- `chit_period` — one row per month; holds the announced due amount and the payout recipient
- Events: `contribution_due_set`, `contribution_received`, `payout_recorded`

Derived, never stored: who has paid, who is pending, running total collected, who has already taken their pot.

### Hard constraint
The app **never computes** auction discounts, dividends, or foreman commission. If the organiser wants the winning bid recorded, it is a note on the period, not an input to any calculation. This is a ledger, not regulated chit software.

### Money-recovery hook
The highest-value derived flag in the group: **members who have received their payout and are now behind on contributions** (`prizedMonth && (unpaid || arrears > 0)`). Fixed member list, known monthly deadline, binary paid/unpaid — no new data infrastructure required.

### Regulatory note
Chit funds are governed by the Chit Funds Act, 1982 (amended 2019). Registered chits require state Registrar sanction. Target users mostly run unregistered informal committees. Position the feature as group contribution tracking; avoid chit-fund vocabulary in store-facing copy. Confirm with a CA before public launch.

### Mockup
`chit-group-mockup.html` — group detail screen. Hero with announced amount and collection progress, at-risk alert banner, member list with filters (All / Pending / Owes after payout / Already received), months history tab. Tapping a member toggles paid state; all totals re-derive.

---

## 3. Gold chit — rejected

Three reasons, in order of weight:

1. **Non-rupee unit of account.** Customer balances accrue in grams, credited at the gold rate on each installment date. Requires a daily rate table, per-installment gram credits, running gram balance, and karat handling. The ledger stores integer paise throughout.
2. **Closes into a sale, not a payment.** At maturity the customer receives jewellery — making charges, wastage, old-gold adjustment, HUID/hallmark fields. That is jewellery billing, which is out of scope. We would own the boring half of the workflow.
3. **Rupee-only variants need nothing.** "Pay 10 months, get a bonus month" is already SUB with zero changes, so it does not justify a business type.

### General rule extracted
**If a liability is denominated in anything other than rupees, it is not a SUB case.** Also rules out grain/seed advances for contractors and hour-banks for coaches.

---

## 4. Moneylending — accepted, build deferred

### Position
Khaata is a record-keeper for the lender's own book. The borrower never installs anything. This is the same posture as Excel or existing shopkeeper udhaar-ledger apps, and is not the category Google Play's personal-loan policy targets (that policy addresses apps where the borrower is the user).

### Non-negotiable constraints
1. **Owner-side reminders only.** The app drafts a message; the owner sends it from their own WhatsApp via the share sheet. Never auto-send, in any tier.
2. **No loan agreements, no legal notices, no receipts that read as instruments.** Recording a debt is book-keeping; producing the instrument is a different product with a different liability profile.
3. **Store listing hygiene.** Category Business, not Finance. No "loan", "lending", "EMI", "instant" in title, short description, or screenshots. Frame as dues and udhaar tracking.
4. **Discovery.** Moneylending is *not* in the visible business-type list. It is reachable only via the add-your-own flow in onboarding.
5. State Money-Lenders Act licensing is the user's obligation, not ours. Expect reluctance around cloud sync from this segment — acceptable, since Free tier is local-only.

### Interest model — LOCKED

**Three modes at launch:**
- `rate` — per hundred per month (the way the trade speaks: ₹2 per hundred)
- `flat` — fixed rupees per month, no rate ever stated
- `none` — family and staff loans

Stored as `interest_mode` + `rate_bps_monthly` **or** `flat_paise`. Basis points, never floating point. ₹1.50 per hundred = 150 bps monthly.

Deferred to a later phase: `fixed_total` — give ₹50,000, get ₹60,000 back on a date, no rate stated. Cheapest mode to build (nothing posts monthly).

**Interest is proposed, not charged.** The app surfaces "₹1,000 due for August" with three actions — Post / Change / Skip month. Nothing enters the ledger until the lender confirms. Skip is a recorded choice, not a missing row.

**Amount recomputes on the current principal balance**, using the opening balance of the month. Mid-month principal repayments do not pro-rate by default; the amount stays editable so the lender's own practice wins.

**No compounding.** Unpaid interest never rolls into principal automatically. If a lender does this, they record a manual top-up. There is no switch for it. Several state Money-Lenders Acts restrict compounding.

**No penal interest in v1.** Adds a second rate and a second clock. Defer.

### Principal
**Derived from events, never a stored field.** Sources: `loan_given`, `top_up_given`, `principal_repaid`. Principal moves in interest-only lending — borrowers part-pay the middle of a loan and keep paying interest on the remainder.

Consequence: monthly interest cannot be fixed at loan creation. Every posted interest event **snapshots** the principal, rate, and mode it was computed on — same reasoning as bills snapshotting price/tax/unit. Terms changes create a new version rather than editing the old.

### Payment allocation
- **Interest first, oldest month first**, with a per-payment override (Interest first / Principal first)
- Excess beyond total outstanding sits as **advance on account**, not a silent principal reduction

### Structure
- **Loans are their own records.** A borrower can hold multiple concurrent loans; the borrower page rolls up across them. This is a schema decision — cheap now, expensive later.
- **Closure has three outcomes:** cleared, settled short (a waiver event recording what was forgiven), written off. Without the waiver event lenders will fudge figures to close a loan, and the ledger stops being true.

### Repayment basis options (recorded, not calculated)
- Interest only — interest monthly, principal on demand
- Equal instalments — lender enters the instalment amount **and** the count; the app reports the total and how much more it is than the principal. It does **not** derive an instalment from the rate.
- One-time return
- Daily collection — per-day amount and day count

This distinction matters: recording an agreement keeps us describing, not issuing.

### Borrower onboarding
Reuses `customers` — no separate borrower table. The picker shows loan history inline ("Cleared 2 loans, paid on time" / "Loan running, ₹50,000 outstanding"), which is free context at exactly the right moment.

Four steps: who is borrowing → amount and terms → security and guarantor → review.

**Security gets its own step**, not a row in an edit form. For this business it is the single field that most determines recovery. "Nothing held" is a real choice and flags the loan as unsecured on review. Guarantor is a note only — it creates no claim.

Uses pick-or-add-and-remember for rate presets, security type, and repayment basis.

### Mockups
- `borrower-onboarding-v2-mockup.html` — four-step new borrower + loan flow, three interest modes
- `loan-detail-v2-mockup.html` — loan detail with propose-and-confirm posting, event ledger with snapshots, repayment sheet showing live allocation and the recomputed next-month interest

Demonstration path in the loan detail mockup: record ₹10,000 with Principal first → principal drops ₹50,000 → ₹40,000 → the August proposal changes from ₹1,000 to ₹800.

---

## 5. Open questions

1. **Flat mode after a principal repayment.** ₹1,000 a month on ₹50,000 stays ₹1,000 on ₹40,000 unless renegotiated. Correct behaviour, but the proposal card should nudge when principal has moved and the flat amount has not. Design the nudge.
2. **Reducing-balance loans** — reuse the loan detail screen or a separate one? Answer before build.
3. **Borrower picker context line.** If a person is simultaneously a committee member, a bill customer, and a borrower, the row carries too much. Need a rule for which single fact wins.
4. **Onboarding Skip on business-type step.** Currently applies defaults, which can land a user in SALE screens that do not fit. Alternative: make type mandatory and drop Skip.
5. **Interest posting trigger.** Proposals appear on screen; decide whether anything is generated in the background or purely on open. Local-first suggests on open.

---

## 6. Design language reminder

All mockups follow Modern Ledger: `#f4f3ee` parchment family, forest green `#1f6f54` used sparingly, ochre for attention/in-progress, muted terracotta for danger, layered soft shadows with inset top highlight, 16–20px card radius, SVG grain filter, Plus Jakarta Sans for headings and hero numbers, Inter for body and tabular ₹ figures, `en-IN` digit grouping, `prefers-reduced-motion` respected.

Money as integer paise. UUID primary keys. ISO 8601 dates. Soft deletes with `deleted_at`.
