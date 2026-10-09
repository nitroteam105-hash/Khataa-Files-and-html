# Khaata — PG / Hostel Product Structure V1
**Status:** FROZEN  
**Scope:** Product architecture, business rules, workflows, hierarchy, states, navigation, and structural decisions for the PG / Hostel vertical.  
**Not frozen:** Visual design system, spacing, typography, colors, radii, shadows, animations, microcopy, implementation details, sync protocol internals, and future enhancements unless explicitly stated below.

---

## 1. Product framing

Khaata is a small-business management app that adapts to the chosen business type rather than behaving like a generic ledger.

For PG / Hostel businesses, the product is designed around the owner's operational question:

> **What needs my attention today?**

The product structure therefore prioritizes:
- operational exceptions,
- tenant lifecycle,
- room / bed capacity,
- collections and obligations,
- deposits and charges,
- cash accountability,
- staff permissions,
- and upcoming events.

A single Khaata account may own multiple businesses.

---

## 2. Core product principles

### 2.1 Operational-first, not dashboard-first
The main PG experience should not be a traditional analytics dashboard.

The Home screen surfaces:
- urgent exceptions,
- actionable work,
- upcoming operational events,
- and a small Business Pulse.

Routine successful states remain quiet.

### 2.2 Navigation vs actions
The product follows:

> **Navigation = where I want to go.**  
> **FAB = what I want to do.**

Persistent navigation:
- Home
- Tenants
- Collections
- More

A global FAB opens a compact labeled action menu:
- Add tenant
- Record payment
- Add expense
- Add charge

The order may change by context, but the action set remains stable.  
Example: Collections may place **Record payment** first.

### 2.3 Local-first operation
Core operational data lives locally on the device.

Three backup / sync choices:
1. **On this device only**
2. **Google Drive backup**
3. **Khaata Sync (Pro)**

The product must continue core work offline.

### 2.4 History over destructive editing
Important records are preserved.

The product avoids hard-delete for records that affect:
- tenancy,
- occupancy,
- payment,
- deposit,
- room / bed history,
- staff accountability,
- or reporting.

Corrections and reversals are separate events where appropriate.

---

# 3. Business creation

## 3.1 Create PG flow
The business creation flow is:

1. Business name
2. Business type
3. Location
4. Operational currency
5. Continue

### 3.2 Operational currency
Operational currency belongs to the **business**, not to an individual property.

V1 supports one operational / base currency per business.

The chosen currency is used for:
- rent,
- deposits,
- charges,
- expenses,
- collections,
- statements,
- reports.

Location does not silently determine currency.

PG V1 does not support FX or multi-currency transactions.

---

# 4. Initial setup UX

## 4.1 Multi-step setup convention
For genuine sequential setup / onboarding flows:

- show **Step X of Y**,
- show a progress bar,
- provide **Back**,
- preserve previous inputs when going back,
- and ensure progress reflects the actual chosen branch.

A review-map screen count must not be presented as setup progress.

## 4.2 Setup path
After creating the PG, the owner chooses:

- **Set up rooms now**
- **Add rooms as I add tenants**

One neutral **Continue** button is used.

Both options lead to the same underlying property model.

---

# 5. Property and capacity model

## 5.1 Hierarchy
The supported hierarchy is:

**Block / Building (optional) → Floor (optional) → Room → Bed / capacity**

There is no floor-plan UI in V1.

### 5.2 Structural modes
If the owner chooses to set up rooms now, the product can offer:

- Rooms only
- Floors & rooms
- Blocks / buildings, floors & rooms

The setup phase establishes capacity only.

It does **not** require:
- rent,
- deposit,
- amenities,
- or tenant commercial terms.

> **Setup establishes capacity. Tenant onboarding establishes the commercial relationship.**

## 5.3 Rooms and beds
Rooms created during tenant onboarding are real property hierarchy records.

They are not temporary tenant-only records.

## 5.4 Capacity setup methods
Large properties support:

- Manual entry
- Bulk generation
- Spreadsheet import

## 5.5 Spreadsheet import
V1 supports:
- `.xlsx`
- `.csv`

The primary downloadable template is `.xlsx`.

Suggested columns:
- Building / Block — optional
- Floor — optional
- Room
- Bed
- Capacity — optional if bed labels are not individually provided

If Capacity is provided, Khaata may generate bed records.

Import flow:
1. Download template
2. Choose file
3. Preview
4. Validate
5. Show errors / duplicates
6. Confirm import

Choosing a file never commits data immediately.

Both `.xlsx` and `.csv` use the same validation and import pipeline.

---

# 6. Progressive room creation during tenant onboarding

If the owner chose **Add rooms as I add tenants**, tenant onboarding still starts with the tenant.

The owner does not need to leave onboarding to create structure.

During Room / Bed assignment:
- select an existing room / bed, or
- create the needed room / bed inline.

Underlying data order:
1. create the real room / bed record,
2. then assign the tenancy.

Do not create fake or temporary room records.

---

# 7. Tenant onboarding

## 7.1 Main flow
Tenant onboarding is:

1. Basics
2. Room / Bed
3. Money
4. Requirements
5. Review

## 7.2 Minimum required information
Minimum onboarding data:
- tenant name
- phone
- room / bed
- agreed joining date

Saving creates a tenant / tenancy record directly rather than a generic success screen.

## 7.3 Joining date
The joining / rent-start date is authoritative for the agreement.

Changing it later:
- must be explicit,
- must preserve history,
- and must not rewrite prior payments or agreed financial events.

## 7.4 Money step
Tenant Money can include:
- monthly rent
- due day
- security amount
- joining date

Proration may be suggested, not forced.

## 7.5 Requirements step
Missing a configured required item does **not** block saving the tenancy.

Instead:
- tenancy is saved,
- status can show **Setup incomplete**,
- and follow-up can surface operationally.

---

# 8. Tenancy as the core commercial object

The underlying commercial object is the **Tenancy / Agreement**, not merely the person.

The model separates:

- occupant(s),
- responsible party,
- payer,
- deposit owner / source.

Key invariant:

> **Occupancy = who stays**  
> **Tenancy = the commercial relationship**  
> **Responsibility = who owes**  
> **Payment = who paid**  
> **Deposit = whose funds are held**

These must not be silently inferred when they differ.

Company / group accommodation is allowed as an optional future-capable structure.

Responsible-party changes are effective-dated.

Deposit ownership is preserved.

---

# 9. Tenant lifecycle

Main lifecycle:

**Upcoming → Active → Planned move-out → Moved out**

Alternative pre-join outcome:

**Upcoming → Cancelled before joining**

## 9.1 Upcoming tenants
Upcoming tenants use the same tenancy record model.

Supported actions:
- Change joining date
- Change room / bed
- Cancel before joining
- Confirm joined

## 9.2 Activation rule
An Upcoming tenant becomes **Active only by explicit confirmation** when the tenant physically joins.

The system must not automatically mark someone Active at midnight on the joining date.

The date may trigger attention, but not occupancy truth.

## 9.3 No-show
No-show is **not** a lifecycle state.

Khaata must:
- not auto-cancel,
- not auto-release the bed,
- not auto-move the tenant.

If the joining date passes unresolved, surface a Needs attention item such as:
- Joining overdue
- Confirm joining

The owner may then:
- confirm joined,
- change joining date,
- or cancel before joining.

## 9.4 Room transfer
Room transfer preserves occupancy history.

A transfer does not automatically change rent.

Any rent change must be explicit and effective-dated.

## 9.5 Planned move-out
Planning move-out does not end the tenancy.

The plan can be:
- changed,
- cancelled,
- or extended.

## 9.6 Tenancy end
The product separates:
- physical vacate,
- financial tenancy end,
- bed release.

The owner uses a definitive **End tenancy** action.

Do not use Delete or Block for lifecycle closure.

## 9.7 Former tenant receivables
Money owed survives tenancy end.

Former tenants may still have:
- outstanding dues,
- refund pending,
- write-offs,
- payment follow-up.

---

# 10. Exit settlement

Exit settlement includes:

- end date / notice handling,
- final dues,
- deposit settlement,
- tenancy close.

A tenant can become former while a security refund is still pending.

Pending refund remains discoverable after occupancy ends.

Security is never automatically applied to arrears.

Applying security to dues must be an explicit action.

---

# 11. Notice and move-out rules

Notice policy is configurable.

Warnings may be shown when notice rules are not satisfied.

Authorized users may override when business policy permits.

Changing or cancelling a planned move-out must preserve the occupancy timeline.

---

# 12. Reservation and bed-conflict handling

A conflict exists when two legitimate occupancy commitments overlap for the same bed.

Examples:
- current tenant extends move-out,
- upcoming tenant is already assigned the same bed,
- joining date changes into another commitment.

The conflict:
- surfaces in Needs attention,
- also appears in the assignment / edit context.

Conflict detail shows:
- both relevant tenancies,
- occupancy state,
- important dates,
- room / bed.

Valid resolutions include:
- change one tenant's room / bed,
- change upcoming joining date,
- change / cancel planned move-out,
- cancel the upcoming tenancy.

Khaata may suggest available beds.

Khaata must **never automatically reassign** a tenant.

Both tenancy records remain intact until the underlying conflict is resolved.

There is no separate Reservations module in PG V1.

---

# 13. Billing model

## 13.1 Billing rules
PG V1 exposes:

- Billing frequency: **Monthly**
- Billing timing: **Prepaid / Postpaid**
- Default due day
- Optional grace period

These are business defaults.

Individual tenancy terms remain per agreement.

## 13.2 Automatic obligations
An active rent agreement automatically creates monthly rent obligations.

Obligation creation must be:
- deterministic,
- local/offline-capable,
- not dependent on manual generation.

## 13.3 Billing period
PG V1 uses monthly calendar billing periods.

## 13.4 Due vs overdue
Due and overdue respect the configured grace period.

## 13.5 Due-day changes
Due-day changes are prospective.

They do not rewrite settled historical periods.

## 13.6 Billing timing
Prepaid vs Postpaid is structurally exposed because it changes when obligations become due.

## 13.7 Future obligations
Future obligations may be forecastable.

---

# 14. Rent obligations and balances

The financial model supports:

- one obligation → many payments,
- one payment → many obligations,
- excess payment → tenant credit.

Old dues remain distinct from the current month.

Do not merge old arrears into a single opaque number.

---

# 15. Payments

A payment is a real financial event.

Payment entry may include:
- payer,
- amount,
- mode,
- date,
- allocation,
- proof where relevant.

Digital proof may remain awaiting verification where applicable.

## 15.1 Receipts
Receipts are immutable snapshots of real payment events.

Editing historical receipt truth directly is not allowed.

## 15.2 Reversal / correction
If a posted payment is wrong:
- preserve the original event,
- create a correction / reversal event.

Chargebacks are handled as payment reversal.

Refunds are separate money-out events.

---

# 16. Collections

## 16.1 Main Collections structure
Collections includes:

- Month selector / period context
- Collected
- Outstanding
- Needs attention
- Due
- Paid
- All

Rows represent obligations / collection state rather than generic transactions only.

## 16.2 Collection actions
From an obligation, key actions include:
- Record payment
- View statement
- Record promise

The Collections FAB prioritizes **Record payment**.

---

# 17. Payment promises

A payment promise belongs to an outstanding obligation.

It records:
- promised amount,
- expected payment date,
- optional note.

A promise does **not**:
- change the original due date,
- change the obligation amount,
- count as payment,
- count toward Collected,
- create a ledger transaction.

Before the promise date, Collections may show the promise context.

If the date passes without sufficient payment, surface **Missed promise** in Needs attention.

Partial payments remain real payments and reduce the actual obligation normally.

A new promise preserves prior promise history rather than overwriting it.

When the obligation is fully settled, the promise is effectively closed / fulfilled.

No separate Payment Promises module is needed.

---

# 18. Security deposit

The product separates:

- security amount agreed,
- security actually held,
- actual deposit payment events,
- deposit owner / source.

Deposit receipts are real ledger transactions.

Security must never automatically settle arrears.

If security is applied to dues, the user performs an explicit **Apply security to dues** action.

Refunds are explicit money-out events.

Pending refunds remain operationally visible after move-out.

---

# 19. Charges

Charges are distinct from:
- rent,
- payment,
- deposit.

Charges can be:
- recurring,
- variable,
- one-time.

Discounts, waivers, and corrections are separate from payment.

A disputed charge can have a dispute status.

---

# 20. Tax model

Tax is modeled at the **charge level** in a jurisdiction-neutral way.

The business owns:
- jurisdiction,
- currency,
- timezone,
- tax registration.

PG V1 does not aggregate across currencies without explicit FX rules.

---

# 21. Backdated onboarding and opening balances

When a tenant already existed before Khaata accounting begins, the owner chooses how to start.

## 21.1 Path A — Bring existing history
Enter / import relevant previous:
- rent obligations,
- payments,
- charges,
- deposit activity,
- other relevant history.

Khaata reconstructs accounting from the chosen historical start.

## 21.2 Path B — Start accounting from date
Do not force reconstruction of old transactions.

Instead create explicit opening figures for:
- Outstanding balance
- Security actually held
- Tenant credit

Opening figures must be clearly identified as **opening balances**.

They must not be disguised as fabricated historical payments or charges.

Reports and statements distinguish opening balances from events actually recorded in Khaata.

This branch belongs inside Add Tenant → Money when the tenancy is backdated.

---

# 22. Tenant statement

Tenant Statement is a projection of the ledger / obligation history.

Security is shown separately from rent / charge balances.

The statement should preserve:
- historical obligations,
- real payments,
- credits,
- adjustments,
- security,
- opening balances where applicable.

---

# 23. Expenses

## 23.1 Setup behavior
Expenses are **not mandatory initial setup**.

Khaata starts with sensible PG defaults.

Default categories:
- Utilities
- Repairs & Maintenance
- Supplies
- Staff
- Food / Mess
- Rent / Lease
- Other

Setup may show:

**Expenses — Ready with defaults**

with optional Configure.

## 23.2 Expense entry
Core expense fields:
- amount,
- category,
- date,
- payment mode.

Optional:
- note,
- vendor,
- receipt.

## 23.3 Business-paid vs staff-paid
This is chosen per expense.

A staff-paid expense creates reimbursement accountability.

It is not treated as business cash already spent unless appropriate to the accounting event.

## 23.4 Approval / proof
Approval policy primarily belongs under Staff & Access.

Receipt / proof expectations may be configurable.

## 23.5 Recurring expense
A recurring fixed expense creates an expected expense.

It does not mark the expense as already paid.

## 23.6 Maintenance
PG V1 maintenance is represented as an expense with optional property context.

There is no maintenance-ticket system in V1.

---

# 24. Cash custody

Payment receipt and physical cash custody are separate concepts.

Example:
A tenant pays cash to Ravi.

Immediately:
- the tenant's rent is settled according to the payment,
- the payment receipt is valid,
- custody records **Cash with Ravi**.

The tenant must not become unpaid merely because staff still holds the physical cash.

---

# 25. Cash handover

A cash handover is explicit.

It records transfer of physical cash custody.

Staff-to-staff transfer may be supported and can require two-sided confirmation.

Removing staff never erases their historical custody accountability.

---

# 26. Cash discrepancy resolution

At handover, Khaata compares:

- expected amount,
- actual amount received.

If different:
- record the actual handover,
- create a **Cash discrepancy**,
- preserve the tenant payments.

The discrepancy remains in Needs attention until resolved.

Possible resolution paths include:
- remaining cash later handed over,
- approved adjustment / loss,
- recording error corrected through the appropriate correction flow.

The original handover is preserved.

Resolution is added as new history.

Key invariant:

> **Tenant payment → cash custody → handover → discrepancy / resolution are separate events.**

---

# 27. Staff & access

## 27.1 Roles
V1 role templates:

- Owner
- Manager
- Caretaker / Front desk
- Accounts

The owner can use the product alone.

Initial setup can therefore offer:

**Owner only — add staff later**

## 27.2 Permission levels
Action permissions use:

- Allowed
- Needs approval
- Not allowed

## 27.3 Visibility is separate
Visibility is not the same as action permission.

A staff member may be permitted to perform an action without seeing all business financial data.

## 27.4 Role templates
Khaata provides sensible role templates.

Owner may customize them.

## 27.5 Approval behavior
Owner defines policy.

Staff:
- applies policy,
- performs authorized overrides when allowed,
- requests approval when unauthorized.

## 27.6 Missing tenant requirements
Authority to proceed when required tenant information is missing belongs in Staff & Access.

It does not belong in the Tenant Requirements configuration itself.

## 27.7 Cash accountability
If staff can collect cash, custody can be tracked against that staff member.

Historical accountability survives staff removal.

---

# 28. Tenant requirements configuration

Requirements define onboarding policy rather than tenant data itself.

Supported requirement types may include:
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

Missing a required item does not block tenant creation.

Instead:
- save the tenancy,
- mark Setup incomplete,
- surface follow-up where relevant.

Documents can be tied to requirements.

---

# 29. Optional capabilities

Optional capabilities stay hidden from operational flows unless enabled.

V1 optional PG capabilities:

- Electricity
- Food / Mess
- Parking

---

# 30. Electricity

Initial policy choices:

- Not managed in Khaata
- Included in rent
- Charged separately
- Included up to a limit

If charged separately, detailed meter / reading setup may happen later.

Do not burden initial setup with deep metering configuration.

---

# 31. Food / Mess

Initial policy choices:

- Not offered
- Included in rent
- Fixed recurring charge

Actual charge may use:
- business default,
- tenancy override.

---

# 32. Parking

Parking is an optional PG capability.

Initial policy choices:

- Not offered
- Included
- Fixed recurring charge
- One-time / ad-hoc charge

If enabled, a tenancy may capture:
- whether the tenant has parking,
- vehicle type,
- vehicle number,
- agreed parking charge where relevant.

PG V1 explicitly does **not** include parking-slot inventory / capacity management.

A future slot model such as “P12” can be added later without changing the tenancy model.

---

# 33. Rooms & Beds operational model

Room / bed occupancy states are derived from tenancy commitments.

Derived occupancy states:
- Vacant
- Occupied
- Reserved
- Planned vacancy

These differ from capacity lifecycle states.

---

# 34. Capacity lifecycle

Capacity availability / lifecycle states:

- Available
- Temporarily unavailable
- Retired

These are separate from occupancy.

## 34.1 Temporarily unavailable
Used when a real bed / room exists but cannot currently be assigned.

Examples:
- repair,
- renovation,
- operational block.

Can include:
- optional reason,
- optional available-from date.

Temporarily unavailable capacity:
- remains visible,
- is excluded from assignable capacity,
- preserves history.

## 34.2 Retire bed / room
Retirement means capacity is no longer part of the property going forward.

Retirement is:
- effective-dated,
- history-preserving,
- not hard-delete.

Existing historical tenancy / occupancy / financial context remains intact.

## 34.3 Safeguard
A bed / room cannot simply become unavailable or retired if doing so invalidates:
- a current occupancy,
- a future reservation / commitment.

The affected tenancy must be resolved first.

Retiring a room that contains active beds must show the consequence explicitly.

Do not silently retire child beds.

---

# 35. Home structure

Home answers:

> **What needs my attention today?**

It is not a broad metrics dashboard.

The main Home structure consists of:

- Needs attention
- Coming up
- Business Pulse

---

# 36. Needs attention

A signal appears when knowing it now can change what the owner should do.

## 36.1 Urgent
Examples:
- reservation conflict,
- cash discrepancy,
- outstanding ≥ security actually held.

## 36.2 Actionable
Examples:
- overdue,
- missed payment promise,
- approval waiting,
- refund pending,
- cash handover confirmation,
- unresolved due-to-join tenant,
- selective missing required information.

## 36.3 Upcoming / time-sensitive
Examples:
- move-out,
- joining,
- availability,
- rents due soon.

## 36.4 Context-dependent
Examples:
- cash with staff,
- part-paid before due date / within grace.

## 36.5 Informational only
Examples:
- vacancy,
- occupancy percentage,
- collected,
- expenses.

These do not automatically belong in Needs attention.

## 36.6 Quiet successful states
Do not show routine “Paid / settled / all good” items.

## 36.7 Related signals
Collapse related signals where possible.

## 36.8 No arbitrary dismiss system
Attention is derived from underlying state.

Do not add generic:
- dismiss,
- snooze,
- acknowledge

unless a later use case explicitly requires it.

---

# 37. Coming Up

Coming Up is a derived rolling **7-day forecast**.

Routine upcoming events may aggregate.

Exceptions remain individual.

If an upcoming item becomes overdue / unresolved, it transitions deterministically into Needs attention.

There is no generic reminder-list system in PG V1.

---

# 38. Business Pulse

Business Pulse is intentionally small.

## 38.1 Money
Show:
- Collected
- Outstanding

Money period = current calendar month.

## 38.2 Occupancy
Prefer:
- **Vacant beds**
- **Becoming vacant this month**

Example:
- 7 vacant beds
- 4 becoming vacant this month

Occupancy is point-in-time.

## 38.3 Explicitly excluded from permanent pulse
Do not permanently show:
- total deposits,
- cash with staff,
- expenses,
- profit,
- rates,
- trends,
- charts,
- collection percentage,
- progress bars.

## 38.4 Unknown capacity
Unknown capacity must not display as zero.

## 38.5 Pulse interactions
Collected tap:
- quick recent payments.

Outstanding tap:
- quick balances / due dates.

Vacant beds tap:
- available rooms / beds.

## 38.6 Expanded pulse
Use concise aligned rows.

Do not convert it into prose-heavy explanation.

## 38.7 Charts
The Home cash-flow / chart experiment was explicitly dropped.

Charts may be reconsidered later in:
- Collections,
- reporting,
- insights.

---

# 39. Home card stack behavior

Needs attention and Coming up use complete cards.

They are not internally collapsed.

Stacked mode:
- physically overlaps full cards,
- rear card leaves its top strip visible,
- tapping rear brings it front,
- swipe can shuffle.

Show all:
- lays full cards vertically.

Stack cards:
- restores overlap.

Support up to four visible layers for future business types.

PG currently uses two real cards.

Visual depth is intentionally restrained.

No circular count totals are needed.

---

# 40. Tenants main screen

Tenants screen:

- Title: Tenants
- Search
- Lifecycle filters:
  - Active
  - Upcoming
  - Moving out
  - Former
- rows appear immediately.

Default filter:
- Active

Counts are useful.

Do not add:
- broad totals,
- charts,
- collection-summary cards.

## 40.1 Tenant row
Example structure:

**Rohan Mehta**  
Room 203 · Bed B  
`₹4,500 overdue`

Priority:
1. tenant name
2. room / bed
3. operational exception only if relevant

A normal tenant does not need an “All good” line.

Do not show ₹0 / zero-balance text on every row.

---

# 41. Tenant Detail

Tenant Detail includes:

- identity,
- room / bed,
- active since / lifecycle context,
- Outstanding,
- Record payment,
- Share reminder,
- tenancy terms,
- current month,
- recent payments,
- phone / requirements,
- transfer room,
- plan move-out,
- edit agreement.

It serves as the tenant operational record rather than a decorative profile page.

---

# 42. Manual reminder behavior

PG V1 does not include a messaging platform.

Reminder behavior is manual:

**Share reminder**

No generic automated messaging system is required for V1.

---

# 43. Collections vs tenant detail

Collections is obligation-first.

Tenant Detail is tenancy-first.

Both may reach the same financial data, but serve different user intent.

---

# 44. More

More is the home for:
- configuration,
- staff / access,
- settings,
- optional features,
- secondary operational tools.

More is **not another dashboard**.

---

# 45. Backup & Sync

The setup screen shows the backup / sync choice rather than silently hiding it.

Default selection may be **On this device only**, but the user sees all options.

## 45.1 On this device only
- local data remains on the device,
- owner may create / export a local backup file,
- owner may restore from one.

Backup is not mandatory to operate.

The product should clearly communicate device-loss / reset risk if no exported backup exists.

## 45.2 Google Drive backup
- local-first operation,
- automatic / manual Drive backup,
- restore from available backup.

## 45.3 Khaata Sync (Pro)
- local database remains operational offline,
- server sync occurs when connected,
- server-dependent views can show stale / connection state.

Free → Pro must be able to upload existing local data.

---

# 46. Offline and sync invariants

V1 structural invariants:

- globally unique offline-safe IDs,
- preserve legitimate concurrent events,
- expose conflicts rather than silently overwrite,
- permissions and offline access are separate concepts,
- stale authentication windows may exist,
- exact sync protocol is deferred.

There is no formal accounting-period close in PG V1.

---

# 47. Permissions vs offline access

A staff member's ability to perform an action and their ability to access already-cached data offline are different concerns.

The product should not collapse these into one rule.

Exact stale-auth / sync mechanics are implementation work, not frozen UI detail.

---

# 48. Outstanding vs security attention rule

A tenancy becomes high-priority when:

> **Outstanding amount ≥ security actually held**

Use **security actually held**, not merely security agreed.

This may surface as urgent attention.

---

# 49. Former tenant follow-up

Former does not imply financially settled.

Former tenant detail may continue to show:
- outstanding balance,
- payments,
- refund pending,
- write-off actions,
- statement history.

Receivables survive the occupancy lifecycle.

---

# 50. Write-off, waiver, dispute

## 50.1 Write-off
Write-off is explicit.

It requires a reason / recorded action.

It is not a payment.

## 50.2 Waiver / discount
Waiver and discount are adjustment concepts.

They are separate from payment.

## 50.3 Dispute
A charge may be marked disputed.

Dispute state does not erase the financial record.

---

# 51. Approval requests

If staff lacks execution permission but policy allows escalation, the staff member can request approval.

Approval does not mean the unauthorized action already happened.

The approving user performs / authorizes the actual action according to policy.

---

# 52. Cash collection and staff removal

Removing or disabling a staff account must not erase:
- collections,
- handovers,
- cash custody,
- approvals,
- historical accountability.

Historical records remain attributed to the person / role context that existed at the time.

---

# 53. Property record deletion policy

Capacity entities that have history are not hard-deleted.

This includes:
- rooms,
- beds,
- buildings / blocks,
- floors where relevant.

Future UI may use archive / retire semantics where needed.

---

# 54. Scope boundaries / explicit non-goals for PG V1

The following are intentionally not part of PG V1 structure unless added later:

- floor-plan editor,
- parking-slot inventory,
- maintenance ticketing system,
- generic messaging system,
- full HR / workforce system,
- multi-currency transaction accounting,
- automatic tenant no-show cancellation,
- automatic bed reassignment,
- arbitrary reminder / task lists,
- destructive rewriting of posted financial history,
- hard-delete of historical tenancy / capacity records,
- Home analytics dashboard,
- Home cash-flow chart,
- formal accounting period close.

HR / workforce beyond PG staff access is a separate shared-product discussion.

---

# 55. Frozen top-level navigation

Final persistent PG navigation:

**Home · Tenants · Collections · More**

Global FAB:
- Add tenant
- Record payment
- Add expense
- Add charge

Context may reorder priority but does not redefine the main action set.

---

# 56. Structurally accepted primary flows

The following flows are covered by PG / Hostel Product Structure V1:

- Create PG
- Property / capacity setup
- Progressive room creation
- Manual / bulk / spreadsheet capacity setup
- Tenant onboarding
- Tenant requirements
- Tenant detail
- Upcoming tenant handling
- Confirm joined
- Change joining date
- Cancel before joining
- Room transfer
- Planned move-out
- End tenancy
- Exit settlement
- Pending refund
- Rent obligations
- Collections
- Record payment
- Receipt
- Tenant statement
- Payment promise
- Add charge
- Add expense
- Security handling
- Payment reversal / correction
- Dispute / waiver / write-off
- Cash custody
- Cash handover
- Cash discrepancy resolution
- Rooms & Beds operational view
- Reservation / bed conflict resolution
- Temporarily unavailable capacity
- Retire room / bed
- Staff & permissions
- Approval request
- Former tenant follow-up
- Billing settings
- Optional capability settings
- Backup & Sync
- More

---

# 57. Freeze statement

**PG / Hostel Product Structure V1 is FROZEN.**

This means the structural product decisions above are the baseline for future design and implementation.

Future work should not casually restructure the PG vertical.

A structural change should require one of:
- usability testing reveals a genuine workflow failure,
- implementation exposes a model contradiction,
- real business use shows a missing core case,
- a deliberate V2 product decision is made.

The freeze does **not** prevent refinement of:
- UI components,
- visual styling,
- spacing,
- typography,
- responsive behavior,
- microcopy,
- animations,
- exact validation language,
- implementation architecture,
- sync protocol internals,
- performance,
- accessibility,
- later reporting / insights,
- future PG capabilities.

---

# 58. Current prototype references

Accepted / current structural prototypes from the V1 process include:

- `khaata-pg-tenants-v2.html`
- `khaata-pg-tenant-detail-v1.html`
- `khaata-pg-add-tenant-v1.html`
- `khaata-pg-collections-v1.html`
- `khaata-pg-v1-review-hub-self-contained.html`
- `khaata-pg-v1-product-flow-map.html`
- `khaata-pg-v1-edge-flows.html`
- `khaata-pg-setup-v1-interactive.html`
- `khaata-pg-operating-configuration-v2.html`

Earlier prototypes may contain superseded wording or configuration choices and should not override this specification.

---

# 59. Canonical decision hierarchy

If a prototype conflicts with this document:

> **This Product Structure V1 specification wins for structural decisions.**

If a future design-system artifact conflicts only on visual treatment, the visual design system governs the visual layer without changing the frozen business structure.

---

**End of Khaata — PG / Hostel Product Structure V1**
