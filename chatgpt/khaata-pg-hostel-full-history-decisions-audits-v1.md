# Khaata — PG / Hostel Product History, Decision Log, Audits & Freeze Record
**Coverage:** Earliest PG/Hostel product discussions through the completion and freeze of Product Structure V1, including pre-UI decisions, structural checks, edge/corner-case reviews, issues found during prototyping, and final decisions.

> This document is a **comprehensive reconstructed decision/history log**, not a word-for-word transcript. It records the substance of the discussions and the decisions that were made from the available conversation/project context. Where a prototype or implementation issue was found, it is recorded explicitly. Where no product-model failure was found, that is also noted.

---

# 1. Original product direction before UI work

The earliest PG/Hostel discussions established that Khaata should **not begin as a dashboard-design exercise**.

The direction was:

- Build the PG vertical end-to-end first.
- Understand the actual business workflow before deciding visual presentation.
- Define:
  - setup,
  - rooms / beds,
  - tenants,
  - billing,
  - rent collection,
  - deposits,
  - expenses,
  - cash handling,
  - staff,
  - lifecycle,
  - exceptions,
  - and offline behavior.
- Only after the product structure is understood should dashboards, Home presentation, cards, charts, visual patterns, and component styling be explored.

The user explicitly rejected premature UI design and wanted product architecture first.

The working rule became:

> **First determine how the PG business actually works inside Khaata. Then design the UI around the frozen structure.**

---

# 2. Early product framing

Khaata was framed as a **small-business management system that adapts to the business type**, not merely a ledger.

For PG / Hostel, the product had to cover the full operating cycle:

- create business,
- define property capacity,
- add tenants,
- assign beds,
- collect rent,
- handle deposits,
- add charges,
- record expenses,
- manage staff,
- account for cash,
- handle move-outs,
- preserve history,
- and surface exceptions.

One account may own multiple businesses.

The business Home was eventually grounded in one question:

> **What needs my attention today?**

This principle later became the basis of Home, but it originated from the product-architecture discussion rather than from visual design.

---

# 3. Early room / property setup discussion

One of the first major structural decisions was how a PG owner should create rooms.

Two user behaviors were recognized:

1. An owner may want to set up the whole property before adding tenants.
2. An owner may want to start with tenants and create rooms only as needed.

The accepted solution was a hybrid:

- **Set up rooms now**
- **Add rooms as I add tenants**

Both must use the **same underlying property model**.

There is no separate “quick-mode” database and “complete-mode” database.

This was an important early decision because it prevented Khaata from forcing a complete property setup before the user could begin operating.

---

# 4. No floor-plan UI

An early idea of representing PG space visually was deliberately rejected.

PG V1 would use a hierarchy only:

**Block / Building (optional) → Floor (optional) → Room → Bed / capacity**

There is **no visual floor-plan editor** in V1.

The reason was structural simplicity:
- owners need operational capacity,
- not architectural drawing,
- and visual floor plans would add complexity without improving the core workflow.

---

# 5. Setup establishes capacity; onboarding establishes the agreement

A foundational distinction was established:

> **Property setup establishes capacity. Tenant onboarding establishes the commercial relationship.**

Therefore property setup should not require:
- rent,
- deposit,
- tenant terms,
- commercial amenities,
- or individual tenant pricing.

Those belong to the tenancy.

This prevented the room model from becoming overloaded with tenant-specific commercial data.

---

# 6. Progressive room creation

For the **Add rooms as I add tenants** path, the workflow was settled as:

1. Begin tenant onboarding.
2. Reach Room / Bed assignment.
3. If the required room or bed does not exist, create it inline.
4. Khaata creates a real property record.
5. Then the tenancy is assigned.

Important invariant:

> No temporary tenant-only room or fake bed record.

A room created during onboarding becomes part of the normal property hierarchy.

The owner should not have to leave onboarding to configure capacity elsewhere.

---

# 7. Large-property setup discussion

The property setup discussion expanded to support large hostels.

Three capacity-entry methods were accepted:

- Manual
- Bulk generation
- Spreadsheet import

Spreadsheet import was eventually finalized as:

- `.xlsx`
- `.csv`

with `.xlsx` as the primary downloadable template.

Suggested fields:

- Building / Block — optional
- Floor — optional
- Room
- Bed
- Capacity — optional

Import must follow:

1. Download template
2. Choose file
3. Preview
4. Validate
5. Show errors / duplicates
6. Confirm import

Selecting a file must never immediately commit data.

Both file formats use the same validation/import pipeline and result in the same property model.

---

# 8. Create PG / business basics

The Create PG flow was finalized as:

1. Business name
2. Business type
3. Location
4. Operational currency
5. Continue

A specific decision was made that **currency must be explicit**.

Location must not silently choose currency.

Operational currency belongs to the **business**, not an individual property.

PG V1 supports one operational/base currency per business.

It is used for:
- rent,
- security,
- charges,
- expenses,
- collections,
- statements,
- reports.

Multi-currency / FX transactions are outside PG V1.

---

# 9. Multi-step setup behavior

During setup prototyping, a structural UX convention was established.

Any genuine sequential setup flow must show:

- **Step X of Y**
- progress indication
- **Back**

Back must preserve previously entered values.

Progress must reflect the **actual selected branch**, not the number of screens in an internal review map.

This was introduced after recognizing that a review-map count and a real user flow are not the same thing.

---

# 10. Tenant onboarding discussion

The tenant onboarding flow was settled as:

1. Basics
2. Room / Bed
3. Money
4. Requirements
5. Review

Minimum viable tenant information:

- name
- phone
- room / bed
- agreed joining date

Saving the onboarding flow creates the real tenant/tenancy record.

The product should not end with a generic “success” page disconnected from the record.

---

# 11. Joining date / rent-start date

The joining / rent-start date became authoritative in the commercial agreement.

Changing it later must be:
- explicit,
- controlled,
- auditable.

Changing a date must not rewrite:
- payments,
- posted obligations,
- or agreed money history.

This became important later during Upcoming tenant and backdated-onboarding reviews.

---

# 12. Requirements policy

Requirements were initially explored as a tenant setup area and later refined.

Supported requirement types include:
- phone number,
- identity document,
- emergency contact,
- photo,
- address / basic details,
- other documents.

Each requirement uses:

- Required
- Optional
- Not collected

A critical business decision:

> Missing a required item does **not** block creating the tenant.

Instead:
- save the tenancy,
- mark **Setup incomplete**,
- surface follow-up operationally.

This supports real-world PG operation where a tenant may physically move in before all documents arrive.

---

# 13. Requirement approval rule moved to Staff & Access

During configuration review, one misplaced rule was detected:

“Owner approval for missing requirements” had initially been associated with Tenant Requirements.

This was corrected.

The requirement defines **what information is expected**.

The ability to proceed despite missing information is an **authority/permission question**.

Therefore it belongs under:

**Staff & Access**

This was a structural correction, not merely wording.

---

# 14. Core commercial model: Tenancy / Agreement

A major product-model decision was that the underlying commercial object should be the **Tenancy / Agreement**, not directly the person.

The model separates:

- occupant(s)
- responsible party
- payer
- deposit owner / source

The invariant became:

> **Occupancy = who stays**  
> **Tenancy = the commercial relationship**  
> **Responsibility = who owes**  
> **Payment = who paid**  
> **Deposit = whose funds are held**

Khaata must not silently infer these as the same person when they differ.

This allows:
- parent paying for student,
- employer paying for worker,
- group/company accommodation,
- deposit funded by someone else,
- future responsibility changes.

Responsible-party changes are effective-dated.

Deposit ownership is preserved.

---

# 15. Tenant lifecycle model

The main lifecycle was defined as:

**Upcoming → Active → Planned move-out → Moved out**

with an alternate path:

**Upcoming → Cancelled before joining**

The product must distinguish:
- future commitment,
- active occupancy,
- planned exit,
- completed exit,
- cancellation before joining.

This was deliberately not collapsed into a single “Active / Inactive” flag.

---

# 16. Room transfer

Room transfer must preserve history.

When a tenant changes room / bed:
- old occupancy history remains,
- new assignment begins,
- rent does not automatically change.

Any rent change must be explicit and effective-dated.

This prevents room movement from silently rewriting the commercial agreement.

---

# 17. Planned move-out

Planning a move-out does **not** end the tenancy.

The plan may be:
- changed,
- cancelled,
- extended.

The system distinguishes:
- planned move-out,
- physical vacate,
- bed release,
- financial tenancy end.

This prevents premature closure of money or occupancy history.

---

# 18. End tenancy instead of Delete / Block

Tenant lifecycle closure uses a definitive:

**End tenancy**

It must never be represented as:
- Delete
- Block

Former-tenant financial data survives.

Receivables do not disappear just because the tenant has moved out.

---

# 19. Exit settlement

Exit settlement was modeled as a process, not a single status toggle.

It includes:
- end date / notice,
- final dues,
- deposit settlement,
- close tenancy.

Physical vacancy and financial settlement can happen at different times.

A refund may remain pending after the tenant is already Former.

---

# 20. Deposit model

Deposit / security was explicitly separated into:

- amount agreed,
- actual payment(s),
- amount actually held,
- deposit owner / source,
- refund,
- application to dues.

A deposit payment is a real ledger event.

Security must **never automatically pay arrears**.

Applying security to dues requires an explicit action.

Pending refunds remain discoverable after tenancy end.

---

# 21. Billing model discussion

The billing model was designed around obligations, not merely payment records.

An active rent agreement automatically creates monthly obligations.

This must be deterministic and work offline.

PG V1 uses monthly calendar billing periods.

Business-level billing defaults include:

- Billing frequency: Monthly
- Billing timing: Prepaid / Postpaid
- Default due day
- Optional grace period

Prepaid / Postpaid was explicitly exposed because it affects when an obligation becomes due.

Due-day changes are prospective.

Historical settled periods are not rewritten.

---

# 22. Obligation / payment relationship

The financial model supports:

- one obligation → many payments
- one payment → many obligations
- excess payment → credit

Old dues remain distinct from current-month dues.

Khaata should not hide old arrears inside one opaque merged amount.

---

# 23. Payments and receipts

A real payment creates a real ledger event.

Receipts are immutable snapshots of payment events.

Posted history must not be directly rewritten.

If a payment is wrong:
- preserve the original,
- add a correction / reversal.

Chargebacks are payment reversal.

Refunds are separate money-out events.

This event-history principle became one of the strongest PG invariants.

---

# 24. Charges

Charges are distinct from:
- rent,
- payment,
- deposit.

They may be:
- recurring,
- variable,
- one-time.

Discounts / waivers / corrections are not payments.

A disputed charge may retain a dispute state without deleting the charge.

---

# 25. Tenant statement

The tenant statement was defined as a projection of the ledger / obligations.

It should show financial history without converting deposits into rent.

Security remains separate.

The statement can include:
- obligations,
- payments,
- credit,
- adjustments,
- opening balances,
- deposit activity.

Statement history is preserved after move-out.

---

# 26. Payment promises

Payment promises were tested in the final structural audit.

A promise records:
- promised amount,
- expected date,
- optional note.

It does **not**:
- change due date,
- change amount owed,
- count as payment,
- count toward Collected,
- create a ledger event.

If the expected date passes without sufficient payment:
- surface **Missed promise**.

A new promise preserves old promise history.

No separate Payment Promises module was needed.

---

# 27. Backdated onboarding / opening balances

One of the final audits examined owners adopting Khaata after tenants already exist.

Two valid paths were defined.

## Path A — Bring existing history
Reconstruct:
- rent obligations,
- payments,
- charges,
- deposit activity,
- relevant history.

## Path B — Start accounting from date
Create explicit opening figures for:
- Outstanding balance
- Security actually held
- Tenant credit

Opening figures must be labeled as opening balances.

They must not be represented as invented payments or charges.

Reports / statements distinguish opening balances from recorded Khaata activity.

This flow belongs inside Add Tenant → Money when a tenancy is backdated.

---

# 28. Expenses

The first operating-configuration prototype treated Expenses as a setup area.

During review, this was simplified.

Final decision:

> Expenses are **not a mandatory setup step**.

Khaata starts with PG defaults:

- Utilities
- Repairs & Maintenance
- Supplies
- Staff
- Food / Mess
- Rent / Lease
- Other

Setup can show:

**Expenses — Ready with defaults**

with optional Configure.

Business-paid vs staff-paid is selected per expense.

Expense approval belongs mainly under Staff & Access.

Recurring fixed expenses create **expected expenses**, not already-paid expenses.

Maintenance in PG V1 is an expense with optional property context, not a ticketing system.

---

# 29. Cash receipt vs cash custody

A major real-world accounting distinction was made:

> Payment received from a tenant is not the same thing as physical cash being handed to the owner.

Example:
- tenant pays Ravi,
- tenant obligation becomes settled,
- receipt is valid,
- physical cash becomes **Cash with Ravi**.

This avoids making tenants look unpaid merely because staff still holds the cash.

---

# 30. Cash handover

Cash handover is a separate event.

It records transfer of custody.

Staff-to-staff transfer may be supported and can require confirmation.

Historical accountability must survive staff removal.

---

# 31. Cash discrepancy audit

A final corner-case audit tested:

Expected cash with Ravi = ₹12,500  
Actual handover = ₹12,000

The product must not change tenant payment records.

Instead:
- record expected amount,
- record actual amount,
- create a ₹500 discrepancy,
- preserve the original payments and handover.

The discrepancy remains in Needs attention until resolved.

Resolution may be:
- remaining cash handed over later,
- approved loss / adjustment,
- correction of a recording error.

Original history remains.

Invariant:

> **Tenant payment → cash custody → handover → discrepancy / resolution are separate events.**

---

# 32. Staff roles

V1 roles:

- Owner
- Manager
- Caretaker / Front desk
- Accounts

Owner-only use is valid.

Initial setup may therefore offer:

**Owner only — add staff later**

This avoids turning setup into an admin-console exercise.

---

# 33. Permission model

Permissions use:

- Allowed
- Needs approval
- Not allowed

Visibility is separate from action permission.

For example:
- someone may record a payment,
- but not see full financial reporting.

Role templates are provided but may be customized.

Unauthorized but approvable actions generate approval requests rather than pretending the action happened.

---

# 34. Staff removal

Removing a staff member must not erase:

- collections,
- cash custody,
- handovers,
- approvals,
- historical attribution.

Past accountability is immutable history.

---

# 35. Optional capabilities

Capabilities should stay hidden unless enabled.

PG V1 optional capabilities:

- Electricity
- Food / Mess
- Parking

---

# 36. Electricity

Policy options:

- Not managed in Khaata
- Included in rent
- Charged separately
- Included up to a limit

Detailed meter configuration is deferred and should not burden initial setup.

---

# 37. Food / Mess

Policy options:

- Not offered
- Included in rent
- Fixed recurring charge

Actual amount may use:
- business default,
- tenancy override.

---

# 38. Parking

Parking was added during configuration review.

Policy options:

- Not offered
- Included
- Fixed recurring charge
- One-time / ad-hoc charge

A tenancy may capture:
- whether parking is used,
- vehicle type,
- vehicle number,
- agreed parking charge.

Important V1 boundary:

> No parking-slot inventory / slot-capacity model.

A future slot such as P12 can be added later without changing the tenancy model.

---

# 39. Rooms & Beds operational states

Occupancy states are derived:

- Vacant
- Occupied
- Reserved
- Planned vacancy

These are different from capacity lifecycle states.

Capacity lifecycle states are:

- Available
- Temporarily unavailable
- Retired

---

# 40. Temporarily unavailable / retired audit

This was one of the final corner-case checks.

## Temporarily unavailable
Capacity still exists but cannot be assigned.

Possible metadata:
- reason
- available-from date

It remains visible and preserves history.

## Retired
Capacity is no longer active going forward.

Retirement is:
- effective-dated,
- history-preserving,
- not delete.

A room / bed cannot simply be retired or made unavailable if that would invalidate:
- current occupancy,
- future reservation.

The relevant tenancy conflict must first be resolved.

Retiring a room with active beds must show the consequences explicitly.

No silent child-bed retirement.

---

# 41. Upcoming tenant final audit

One final structural audit focused on Upcoming tenants.

Supported actions:
- Change joining date
- Change room / bed
- Cancel before joining
- Confirm joined

Critical decision:

> Upcoming does **not** automatically become Active on the joining date.

Activation requires explicit confirmation that the tenant physically joined.

The calendar date can trigger attention but cannot assert occupancy truth.

---

# 42. No-show decision

No-show is not a lifecycle status.

Khaata must not:
- auto-cancel,
- auto-release the bed,
- auto-move the tenant.

If joining date passes unresolved:
- surface **Joining overdue / Confirm joining**.

Owner can:
- confirm joined,
- change joining date,
- cancel before joining.

This resolved the earlier open question around future tenants and missed joining dates.

---

# 43. Reservation / bed conflict audit

Another final audit tested legitimate overlapping commitments.

A conflict exists when:
- two tenancies overlap on one bed,
- an existing tenant extends,
- a future tenant is already assigned,
- a joining date moves into another commitment.

The conflict:
- surfaces in Needs attention,
- appears in assignment/edit context.

Resolution may:
- change room / bed,
- change joining date,
- change/cancel planned move-out,
- cancel upcoming tenancy.

Khaata may suggest alternatives.

Khaata must never silently reassign either tenant.

Both records remain intact until a real resolution occurs.

No separate Reservations module was required.

---

# 44. Home product model

After core operations were established, the Home structure was developed around the principle:

> Surface something when knowing it now can change what the owner should do.

## Urgent examples
- reservation conflict
- cash discrepancy
- outstanding ≥ security actually held

## Actionable examples
- overdue
- missed promise
- approval waiting
- refund pending
- handover confirmation
- unresolved due-to-join
- selected missing required information

## Upcoming examples
- move-out
- joining
- availability
- rent due soon

## Context-dependent examples
- cash with staff
- part-paid before due date / within grace

## Informational examples
- vacancy
- occupancy %
- collected
- expenses

Routine paid / settled states stay quiet.

---

# 45. Needs attention behavior

Needs attention is derived from actual product state.

There is no arbitrary generic:
- dismiss,
- snooze,
- acknowledge

unless a future use case specifically requires one.

Related signals should collapse where appropriate.

Routine repetition aggregates.

Exceptions break out individually.

---

# 46. Coming Up

Coming Up is a derived rolling **7-day forecast**.

Routine events may aggregate.

Exceptions remain individual.

If the time passes and the event is unresolved, it moves deterministically into Needs attention.

No generic reminder-list system is needed.

---

# 47. Business Pulse

Business Pulse was deliberately kept small.

Money:
- Collected
- Outstanding

Occupancy:
- Vacant beds
- Becoming vacant this month

The user specifically preferred:

**7 vacant beds**

rather than an occupancy-ratio presentation such as 43/50 occupied.

Money period:
- current calendar month

Occupancy:
- point-in-time

Unknown capacity must not be shown as zero.

---

# 48. Business Pulse exclusions

The following were deliberately excluded from permanent Home pulse:

- total deposits
- cash with staff
- expenses
- profit
- rates
- trends
- collection percentage
- progress bar
- charts

Collected tap → recent payments.

Outstanding tap → balances / due dates.

Vacant beds tap → available rooms / beds.

---

# 49. Home chart experiment — rejected

A Home cash-flow/chart experiment was tried during prototyping.

It was explicitly dropped.

Charts may be reconsidered later in:
- Collections,
- reporting,
- insights.

This was a product-direction correction discovered during UI exploration.

---

# 50. Home card stack direction

Needs attention and Coming Up became complete cards.

In stacked mode:
- cards physically overlap,
- rear top strip remains visible,
- tapping rear can bring it forward,
- swipe may shuffle.

Show all:
- full vertical cards.

Stack:
- overlapped cards.

Support up to four layers for future business types.

PG currently needs two.

This is a presentation decision, not a change to underlying product rules.

---

# 51. Tenants list decision

Main structure:

- Tenants
- Search
- Filters:
  - Active
  - Upcoming
  - Moving out
  - Former

Active is default.

Counts are useful.

No dashboard-like totals or charts belong above the list.

Tenant row priority:

1. Name
2. Room / Bed
3. Exception only if operationally relevant

Normal tenants do not need “All good”.

Do not show ₹0 everywhere.

---

# 52. Tenant Detail decision

Tenant Detail contains:
- identity
- room / bed
- lifecycle context
- outstanding
- Record payment
- Share reminder
- tenancy terms
- current month
- recent payments
- phone / requirements
- transfer room
- plan move-out
- edit agreement

It is operational, not decorative.

---

# 53. Collections structure

Collections contains:
- month / period
- Collected
- Outstanding
- Needs attention
- Due
- Paid
- All

Rows are obligation-oriented.

Action sheet:
- Record payment
- View statement
- Record promise

Collections FAB prioritizes Record payment.

---

# 54. More

More contains:
- configuration
- staff / access
- optional features
- secondary operating tools
- settings

It is not another dashboard.

---

# 55. Backup & Sync discussion

Three user-facing options were finalized:

1. **On this device only**
2. **Google Drive backup**
3. **Khaata Sync (Pro)**

The wording **On this device only** replaced “Local only”.

This was a deliberate user-facing language correction.

The setup should show all choices.

Default may be On this device only, but the choice should not be hidden because users must understand whether their data is backed up.

---

# 56. On this device only

Meaning:
- data remains on the device,
- local backup/export can be created,
- local backup can be restored.

Backup is not mandatory to operate.

The UI should communicate device-loss/reset risk if no exported backup exists.

---

# 57. Google Drive backup

Free/local-first path:
- automatic/manual Drive backup
- restore from backup

Core work remains local.

---

# 58. Khaata Sync (Pro)

Pro:
- local database remains usable offline,
- server sync occurs when connected,
- server-dependent information may show stale/connection state.

Free → Pro uploads existing local data.

---

# 59. Offline invariants

Important structural rules:

- globally unique offline-safe IDs
- preserve legitimate concurrent events
- conflicts are explicit
- do not silently overwrite
- permissions and offline access are separate
- stale auth windows may exist
- exact sync protocol deferred

No formal accounting-period close in PG V1.

---

# 60. Tax/global model

Tax is charge-level and jurisdiction-neutral.

Business owns:
- jurisdiction
- currency
- timezone
- tax registration

No cross-currency aggregation without explicit FX rules.

---

# 61. Outstanding ≥ security held rule

A specific attention rule was accepted:

> Outstanding amount ≥ security actually held

This can become urgent.

Use **security actually held**, not merely security agreed.

---

# 62. Former tenant follow-up

Former does not mean settled.

Former tenant records may continue to show:
- outstanding
- payments
- pending refund
- write-off
- statement

Financial responsibility survives move-out.

---

# 63. Write-off / waiver / dispute audit

Write-off:
- explicit
- reasoned
- not payment

Waiver / discount:
- adjustment
- not payment

Dispute:
- status on charge
- does not erase record

This preserved ledger integrity in edge cases.

---

# 64. Approval request audit

Staff who cannot execute an action may request approval when policy allows it.

Approval request does not mean the action already happened.

This preserved the distinction between:
- request,
- authority,
- execution.

---

# 65. Edge-flow review set

A dedicated edge-flow prototype/review covered:

1. Room Transfer
2. Payment Correction / Reversal
3. Security Refund
4. Dispute / Write-off
5. Approval Request
6. Former Tenant Follow-up

Results:

## Room Transfer
Passed after confirming:
- occupancy history preserved
- rent change separate

## Payment Correction / Reversal
Passed after confirming:
- original event retained
- reversal is a new event

## Security Refund
Passed after confirming:
- pending refund remains discoverable after occupancy end

## Dispute / Write-off
Passed after confirming:
- keep due / waive / write off remain distinct
- write-off requires reason
- write-off is not payment

## Approval Request
Passed after confirming:
- staff can request action without already having execution permission

## Former Tenant Follow-up
Passed after confirming:
- old dues remain after Former

No unresolved model failure remained from this edge-flow review.

---

# 66. Final structural audit set

Before freezing V1, six remaining areas were explicitly audited:

1. Upcoming tenant changes / cancellation / no-show
2. Reservation / bed conflicts
3. Payment promises
4. Backdated onboarding / opening balances
5. Cash discrepancies
6. Temporarily unavailable / retired beds

All six were resolved without requiring a new top-level module.

The final audit concluded the PG structure was ready to freeze.

---

# 67. Failures / issues found during product review

There were **no unresolved core product-model failures** at freeze.

However, several issues were found during the process and corrected.

## 67.1 Missing explicit Upcoming activation rule
Problem:
- Date-based activation could incorrectly claim physical occupancy.

Resolution:
- explicit **Confirm joined**
- no automatic Active transition

## 67.2 No-show ambiguity
Problem:
- unclear whether a missed joining date should release the bed or cancel the tenant.

Resolution:
- no-show is not a lifecycle status
- no auto-cancel
- no auto-release
- surface Joining overdue

## 67.3 Missing reservation-conflict handling
Problem:
- two legitimate commitments could overlap.

Resolution:
- explicit conflict state
- preserve both records
- no automatic reassignment
- owner resolves underlying commitment

## 67.4 Requirements approval was in the wrong configuration area
Problem:
- approval authority had been mixed into requirement policy.

Resolution:
- requirement policy remains Required / Optional / Not collected
- approval authority moved to Staff & Access

## 67.5 Expense setup was too heavy
Problem:
- Expenses had been treated as a mandatory configuration step.

Resolution:
- defaults provided
- setup optional
- “Ready with defaults”

## 67.6 Backup wording
Problem:
- “Local only” was less clear.

Resolution:
- replaced with **On this device only**

## 67.7 Spreadsheet import scope evolved
Earlier prototype:
- CSV-oriented wording

Final decision:
- `.xlsx` + `.csv`
- Excel template primary

Therefore some earlier setup prototype text became structurally stale.

## 67.8 Operating Configuration V1 became stale
After review, V1 no longer reflected:
- requirement-policy simplification
- expense simplification
- Parking
- On this device only
- updated Staff & Access

Resolution:
- Operating Configuration V2 produced.

## 67.9 Home chart direction failed product-fit review
A chart/cash-flow experiment was tried.

Resolution:
- explicitly removed from Home
- future charts deferred to Collections/insights

## 67.10 Multi-file Android review hub failed
A review hub that depended on local sibling HTML links did not work reliably in Android Chrome.

Resolution:
- use one self-contained HTML for multi-screen review prototypes.

This was an implementation/prototyping failure, not a product-model failure.

---

# 68. Prototype / review methodology

The preferred review method became:

**Keep / Change / Missing**

Only build V2 where something actually needs changing.

The user explicitly preferred:
- concrete prototypes,
- no repeated conceptual preambles,
- no premature visual polish,
- self-contained HTML,
- structural evaluation first.

---

# 69. Important prototype implementation convention discovered

For multi-screen local prototypes:

> Prefer one self-contained HTML with multiple JS views.

Reason:
- Android Chrome failed with relative links to sibling local HTML files.

This convention should be preserved for future review builds.

---

# 70. Accepted operational artifacts during structural work

Accepted/current structural prototypes included:

- `khaata-pg-tenants-v2.html`
- `khaata-pg-tenant-detail-v1.html`
- `khaata-pg-add-tenant-v1.html`
- `khaata-pg-collections-v1.html`
- `khaata-pg-v1-review-hub-self-contained.html`
- `khaata-pg-v1-product-flow-map.html`
- `khaata-pg-v1-edge-flows.html`
- `khaata-pg-setup-v1-interactive.html`
- `khaata-pg-operating-configuration-v2.html`

Earlier prototypes may contain superseded wording.

The frozen specification wins over older prototype text when they conflict.

---

# 71. Final PG navigation freeze

Persistent navigation:

**Home · Tenants · Collections · More**

Global FAB:
- Add tenant
- Record payment
- Add expense
- Add charge

Rule:

> **Navigation = where I want to go. FAB = what I want to do.**

---

# 72. Final scope boundaries

Explicit non-goals / deferred items:

- floor-plan editor
- parking-slot inventory
- maintenance ticketing
- generic messaging system
- full HR/workforce system
- multi-currency transactions
- automatic no-show cancellation
- automatic bed reassignment
- generic reminder/task list
- destructive financial-history editing
- hard-delete historical tenancy/capacity
- Home analytics dashboard
- Home cash-flow chart
- formal accounting period close

---

# 73. Product Structure V1 freeze conclusion

After:
- initial end-to-end modeling,
- operational prototype review,
- configuration review,
- edge-flow review,
- final six-area structural audit,
- and corrections to stale or misplaced decisions,

the conclusion was:

# **PG / Hostel Product Structure V1 — FROZEN**

Meaning:
- product hierarchy is frozen,
- major workflows are frozen,
- lifecycle rules are frozen,
- core business invariants are frozen,
- navigation is frozen,
- edge-case behavior is structurally covered.

The freeze does **not** freeze:
- visual design,
- component styling,
- colors,
- typography,
- exact spacing,
- radii,
- shadows,
- animations,
- validation wording,
- implementation internals,
- exact sync protocol,
- later insights/reporting.

A future structural change should only be made if:
- usability testing exposes a real workflow failure,
- implementation exposes a model contradiction,
- real PG usage exposes a missing core case,
- or a deliberate V2 decision is made.

---

# 74. Final canonical decisions summary

The complete PG V1 system is based on these core decisions:

- One business may contain PG property structure.
- One base operational currency per business.
- Property setup and tenancy commercial setup are separate.
- Rooms may be preconfigured or created progressively.
- Hierarchy is Building/Block → Floor → Room → Bed/capacity.
- Tenancy/Agreement is the commercial core object.
- Occupancy, responsibility, payment, and deposit ownership are distinct.
- Future tenants remain Upcoming until explicitly confirmed joined.
- No-show never auto-cancels or releases a bed.
- Room movement preserves history.
- Move-out planning and tenancy end are separate.
- Former tenant balances survive move-out.
- Monthly obligations are generated automatically and deterministically.
- Payments, charges, deposits, waivers, write-offs, refunds, reversals, promises, and opening balances remain distinct.
- Receipts are immutable snapshots.
- Security never silently settles arrears.
- Cash payment and physical cash custody are separate.
- Staff custody and handover preserve accountability.
- Cash discrepancy never makes a tenant unpaid.
- Staff actions use Allowed / Needs approval / Not allowed.
- Visibility is separate from permission.
- Requirements may remain incomplete without blocking occupancy.
- Electricity, Food/Mess, and Parking are optional capabilities.
- Parking-slot inventory is not V1.
- Capacity can be Available, Temporarily unavailable, or Retired.
- Reservation conflicts remain explicit until owner resolves them.
- Home surfaces exceptions and upcoming work, not dashboard clutter.
- Business Pulse stays small.
- Charts are not part of PG Home V1.
- Persistent navigation is Home · Tenants · Collections · More.
- FAB is Add tenant · Record payment · Add expense · Add charge.
- Backup choices are On this device only · Google Drive backup · Khaata Sync (Pro).
- Core work remains local/offline-capable.
- History is preserved rather than destructively rewritten.

---

# 75. Record of whether any final audit failed

**Final result:** No unresolved structural failure remained at freeze.

The audits did uncover missing rules and stale prototype assumptions, but each was resolved before freeze.

The most important discovered issues were:
- Upcoming activation ambiguity
- no-show ambiguity
- reservation conflict behavior
- misplaced requirements approval logic
- overly heavy Expenses setup
- stale CSV-only import wording
- stale operating-configuration prototype
- Home chart direction not fitting the product
- Android multi-file local-link prototype failure

All were resolved or explicitly deferred before Product Structure V1 was declared frozen.

---

**End of reconstructed PG / Hostel conversation history and freeze record.**
