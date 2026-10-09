# Khaata — PG / Hostel Versioned Decision Log

**Canonical version:** 1.0.0
**Canonicalization date:** 2026-10-05
**Status of Product Structure:** FROZEN

> This document restructures the previously reconstructed PG / Hostel product history and freeze record into atomic, versioned decisions. It is still not a word-for-word transcript. Meanings are preserved; the change is labeling, metadata, and organization.

---

# Changelog

| Date | Decision ID | What changed | What it was before |
|---|---|---|---|
| 2026-10-05 | PG-1–PG-202 | Assigned permanent decision IDs and per-decision metadata; restructured the frozen PG/Hostel history into atomic decision records. | Unversioned reconstructed narrative decision/history/freeze document. |

## Revision rule

- IDs are permanent. Never renumber, reuse, or delete an ID.
- Never silently overwrite a decision.
- Every future decision edit must have a changelog entry.
- When meaning changes, preserve the earlier wording/history and mark the prior version **Superseded** or **Revised** as appropriate; either keep the same ID with an explicit revision record or create a new ID that references the previous one.
- Any edit without a changelog entry is invalid.

---

# Decision index

- **PG-1** — Product architecture before visual design
- **PG-2** — Khaata is business-type adaptive, not a generic ledger
- **PG-3** — One account may own multiple businesses
- **PG-4** — Home is organized around operational attention
- **PG-5** — Two property setup paths
- **PG-6** — Both setup paths use one property model
- **PG-7** — No floor-plan editor in PG V1
- **PG-8** — Property capacity hierarchy
- **PG-9** — Property setup and tenancy setup are separate
- **PG-10** — Progressive room creation stays inside onboarding
- **PG-11** — Inline-created capacity is real capacity
- **PG-12** — Manual capacity entry
- **PG-13** — Bulk capacity generation
- **PG-14** — Spreadsheet import supports XLSX and CSV
- **PG-15** — XLSX is the primary template
- **PG-16** — Spreadsheet capacity columns
- **PG-17** — Spreadsheet import requires preview and validation
- **PG-18** — Choosing an import file never commits immediately
- **PG-19** — XLSX and CSV share one import pipeline
- **PG-20** — Create PG business fields
- **PG-21** — Operational currency is explicit
- **PG-22** — Operational currency belongs to the business
- **PG-23** — One operational currency per business in V1
- **PG-24** — Business currency is used across PG finance
- **PG-25** — No PG V1 multi-currency/FX transactions
- **PG-26** — Sequential setup shows real progress and Back
- **PG-27** — Tenant onboarding steps
- **PG-28** — Minimum tenant onboarding data
- **PG-29** — Saving onboarding creates the real record
- **PG-30** — Joining/rent-start date is authoritative
- **PG-31** — Joining-date changes are controlled and non-destructive
- **PG-32** — Tenant Money fields
- **PG-33** — Proration is suggested, not forced
- **PG-34** — Tenant requirement types
- **PG-35** — Requirement policy states
- **PG-36** — Missing required information does not block tenancy creation
- **PG-37** — Authority for missing requirements belongs in Staff & Access
- **PG-38** — Tenancy/Agreement is the commercial core object
- **PG-39** — Occupant, responsibility, payer, and deposit ownership are separate
- **PG-40** — Do not silently infer commercial roles as identical
- **PG-41** — Responsible-party changes are effective-dated
- **PG-42** — Deposit ownership is preserved
- **PG-43** — Company/group accommodation remains model-compatible
- **PG-44** — Tenant lifecycle states
- **PG-45** — Upcoming tenancy actions
- **PG-46** — Activation requires explicit Confirm joined
- **PG-47** — No-show is not a lifecycle state
- **PG-48** — No automatic cancellation/release/move for no-show
- **PG-49** — Past-due joining becomes attention
- **PG-50** — Room transfer preserves occupancy history
- **PG-51** — Room transfer does not silently change rent
- **PG-52** — Planned move-out does not end tenancy
- **PG-53** — Planned move-out can change, cancel, or extend
- **PG-54** — Physical vacate, financial end, and bed release are distinct
- **PG-55** — Use End tenancy, never Delete/Block
- **PG-56** — Former-tenant receivables survive move-out
- **PG-57** — Exit settlement is a process
- **PG-58** — Refund may remain pending after occupancy ends
- **PG-59** — Notice policy is configurable
- **PG-60** — Bed conflict is based on overlapping commitments
- **PG-61** — Bed conflicts surface in attention and assignment context
- **PG-62** — Conflict detail shows both commitments
- **PG-63** — Bed conflicts resolve only through legitimate underlying changes
- **PG-64** — Khaata may suggest beds but never auto-reassigns
- **PG-65** — Both conflicting records remain intact
- **PG-66** — No separate Reservations module in PG V1
- **PG-67** — PG billing frequency is monthly
- **PG-68** — Billing timing exposes Prepaid/Postpaid
- **PG-69** — Billing defaults include due day and optional grace
- **PG-70** — Rent obligations are generated automatically
- **PG-71** — Due and overdue respect grace
- **PG-72** — Obligations and payments support many-to-many allocation
- **PG-73** — Old dues remain distinct from current month
- **PG-74** — Due-day changes are prospective
- **PG-75** — Future obligations may be forecast
- **PG-76** — Payment is a real financial event
- **PG-77** — Digital payment proof may await verification
- **PG-78** — Receipts are immutable snapshots
- **PG-79** — Corrections/reversals preserve the original payment
- **PG-80** — Chargeback is a payment reversal
- **PG-81** — Refund is a separate money-out event
- **PG-82** — Collections screen structure
- **PG-83** — Collection obligation actions
- **PG-84** — Collections prioritizes Record payment in the FAB
- **PG-85** — Payment promise belongs to an outstanding obligation
- **PG-86** — Promise does not change accounting truth
- **PG-87** — Missed promise becomes attention
- **PG-88** — Partial payments remain normal payments under a promise
- **PG-89** — Promise history is preserved
- **PG-90** — Settled obligation closes the promise
- **PG-91** — No separate Payment Promises module
- **PG-92** — Security tracks agreed, paid, held, and ownership separately
- **PG-93** — Deposit receipts are real ledger transactions
- **PG-94** — Security never automatically settles arrears
- **PG-95** — Applying security to dues is explicit
- **PG-96** — Pending security refund remains discoverable
- **PG-97** — Charges are distinct from rent, payment, and deposit
- **PG-98** — Charges can be recurring, variable, or one-time
- **PG-99** — Discounts, waivers, and corrections are not payments
- **PG-100** — Charges may be disputed without erasure
- **PG-101** — Tax is modeled at charge level
- **PG-102** — Business owns jurisdictional finance context
- **PG-103** — No cross-currency aggregation without FX rules
- **PG-104** — Backdated tenancy offers two accounting-start paths
- **PG-105** — Bring existing history reconstructs relevant financial history
- **PG-106** — Start accounting from date uses explicit opening figures
- **PG-107** — Opening balances are labeled and not fabricated transactions
- **PG-108** — Backdated accounting choice belongs in Add Tenant → Money
- **PG-109** — Tenant Statement is a ledger projection with security separate
- **PG-110** — Statement preserves relevant financial history
- **PG-111** — Expenses are ready with defaults, not mandatory setup
- **PG-112** — Default PG expense categories
- **PG-113** — Business-paid vs staff-paid is selected per expense
- **PG-114** — Expense entry fields
- **PG-115** — Expense approval belongs primarily in Staff & Access
- **PG-116** — Recurring fixed expense creates an expected expense
- **PG-117** — Maintenance is an expense with property context
- **PG-118** — Tenant payment and physical cash custody are separate
- **PG-119** — Staff cash collection settles the tenant immediately
- **PG-120** — Cash handover is explicit
- **PG-121** — Staff-to-staff cash transfer may require two-sided confirmation
- **PG-122** — Cash discrepancy never reverses tenant payment truth
- **PG-123** — Cash discrepancy records expected and actual
- **PG-124** — Cash discrepancy resolution appends history
- **PG-125** — PG staff role templates
- **PG-126** — Owner-only operation is valid
- **PG-127** — Action permissions use three states
- **PG-128** — Visibility is separate from action permission
- **PG-129** — Role templates are customizable
- **PG-130** — Approval request does not execute the action
- **PG-131** — Proceeding with missing tenant requirements is a staff authority rule
- **PG-132** — Removing staff preserves historical accountability
- **PG-133** — Optional capabilities stay hidden unless enabled
- **PG-134** — Electricity policy options
- **PG-135** — Detailed electricity metering is deferred from initial setup
- **PG-136** — Food/Mess policy options
- **PG-137** — Food/Mess may use defaults and tenancy override
- **PG-138** — Parking policy options
- **PG-139** — Parking details belong to the tenancy when enabled
- **PG-140** — No parking-slot inventory in PG V1
- **PG-141** — Occupancy states are derived
- **PG-142** — Capacity lifecycle states are separate
- **PG-143** — Temporarily unavailable keeps the capacity record
- **PG-144** — Retirement is effective-dated and non-destructive
- **PG-145** — Capacity cannot be disabled while it invalidates a commitment
- **PG-146** — Retiring a room must expose effects on child beds
- **PG-147** — Home contains Needs attention, Coming up, and Business Pulse
- **PG-148** — Attention uses a decision-changing relevance rule
- **PG-149** — Urgent Home examples
- **PG-150** — Actionable Home examples
- **PG-151** — Upcoming Home examples
- **PG-152** — Context-dependent Home examples
- **PG-153** — Informational metrics do not automatically become attention
- **PG-154** — Routine successful states stay quiet
- **PG-155** — Related attention signals may collapse
- **PG-156** — Attention has no arbitrary dismiss/snooze/acknowledge layer
- **PG-157** — Coming Up is a rolling seven-day forecast
- **PG-158** — Routine Coming Up events aggregate; exceptions remain individual
- **PG-159** — Unresolved upcoming events transition into attention
- **PG-160** — No generic reminder-list system
- **PG-161** — Business Pulse money fields
- **PG-162** — Business Pulse occupancy fields
- **PG-163** — Business Pulse time semantics
- **PG-164** — Permanent Business Pulse excludes secondary analytics
- **PG-165** — Unknown capacity is not zero
- **PG-166** — Business Pulse tap behavior
- **PG-167** — Expanded Business Pulse stays concise
- **PG-168** — No Home cash-flow/chart in PG V1
- **PG-169** — Home attention cards can stack
- **PG-170** — Home stack supports future layers without adding fake PG cards
- **PG-171** — No circular totals on Home stack cards
- **PG-172** — Tenants screen lifecycle filters
- **PG-173** — Tenants screen avoids dashboard summaries
- **PG-174** — Tenant rows show identity, location, and exceptions only
- **PG-175** — Tenant Detail is the operational tenancy record
- **PG-176** — Reminders are manual Share reminder in V1
- **PG-177** — Collections and Tenant Detail serve different intents
- **PG-178** — More is configuration/secondary operations, not another dashboard
- **PG-179** — Backup/sync choice is shown during setup
- **PG-180** — On this device only behavior
- **PG-181** — Google Drive backup behavior
- **PG-182** — Khaata Sync (Pro) behavior
- **PG-183** — Free-to-Pro preserves existing local data
- **PG-184** — Offline IDs and concurrent events are conflict-safe
- **PG-185** — Permissions and offline access are separate
- **PG-186** — Stale-auth handling exists but exact sync protocol is deferred
- **PG-187** — No formal accounting period close in PG V1
- **PG-188** — Outstanding at or above security held is urgent
- **PG-189** — Former tenant financial follow-up remains available
- **PG-190** — Write-off is explicit and is not payment
- **PG-191** — Waiver/discount is an adjustment, not payment
- **PG-192** — Dispute status preserves the charge record
- **PG-193** — Approval request and execution are distinct
- **PG-194** — Historical capacity records are never hard-deleted
- **PG-195** — Persistent PG navigation
- **PG-196** — Global FAB action set
- **PG-197** — FAB priority may reorder by context without changing the action set
- **PG-198** — HR/workforce is outside the PG vertical scope
- **PG-199** — PG Home is not an analytics dashboard
- **PG-200** — PG / Hostel Product Structure V1 is frozen
- **PG-201** — Visual and implementation details remain unfrozen
- **PG-202** — Future structural changes require evidence or a deliberate V2 decision

---

# Atomic decisions

## PG-1 — Product architecture before visual design

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

Define and freeze the PG/Hostel product architecture, workflows, business rules, states, hierarchy, navigation, and major operational behavior before visual/component design is treated as the primary workstream.

## PG-2 — Khaata is business-type adaptive, not a generic ledger

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

The PG/Hostel experience is part of a small-business management product that adapts to the selected business type rather than acting only as a generic ledger.

## PG-3 — One account may own multiple businesses

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

A single Khaata account may own multiple businesses.

## PG-4 — Home is organized around operational attention

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

The PG/Hostel business Home is organized around the question: “What needs my attention today?” rather than around a conventional analytics dashboard.

## PG-5 — Two property setup paths

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

After creating the PG, offer two setup paths: “Set up rooms now” and “Add rooms as I add tenants.”

## PG-6 — Both setup paths use one property model

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

The preconfigured-room path and progressive-room path must use the same underlying property/capacity model; there is no separate quick-mode database or alternate data model.

## PG-7 — No floor-plan editor in PG V1

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

PG V1 does not use a visual floor-plan editor.

## PG-8 — Property capacity hierarchy

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

The property hierarchy is Block / Building (optional) → Floor (optional) → Room → Bed / capacity.

## PG-9 — Property setup and tenancy setup are separate

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Property setup establishes physical capacity; tenant onboarding establishes the commercial relationship. Property setup does not require tenant-specific rent, deposit, tenancy terms, commercial amenities, or individual pricing.

## PG-10 — Progressive room creation stays inside onboarding

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

When using “Add rooms as I add tenants,” a missing room or bed can be created inline during Room / Bed assignment without forcing the owner to leave tenant onboarding.

## PG-11 — Inline-created capacity is real capacity

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

A room or bed created during tenant onboarding becomes a normal property hierarchy record. The system must not create temporary tenant-only rooms or fake bed records; the real capacity record is created before the tenancy assignment.

## PG-12 — Manual capacity entry

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Property capacity setup supports manual entry.

## PG-13 — Bulk capacity generation

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Property capacity setup supports bulk generation.

## PG-14 — Spreadsheet import supports XLSX and CSV

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

Property capacity import supports both .xlsx and .csv files in V1.

## PG-15 — XLSX is the primary template

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

The default downloadable spreadsheet template is .xlsx.

## PG-16 — Spreadsheet capacity columns

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

The simple spreadsheet structure may contain Building / Block (optional), Floor (optional), Room, Bed, and optional Capacity when individual bed labels are not provided.

## PG-17 — Spreadsheet import requires preview and validation

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Spreadsheet import follows Download template → Choose file → Preview → Validate → Show errors/duplicates → Confirm import.

## PG-18 — Choosing an import file never commits immediately

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Selecting a spreadsheet file must not itself create or commit capacity records.

## PG-19 — XLSX and CSV share one import pipeline

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Both .xlsx and .csv use the same validation/import pipeline and create the same underlying property model.

## PG-20 — Create PG business fields

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

The Create PG flow captures Business name → Business type → Location → Operational currency → Continue.

## PG-21 — Operational currency is explicit

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

Operational currency must be explicitly chosen and must not be silently inferred from location.

## PG-22 — Operational currency belongs to the business

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

The operational/base currency belongs to the business, not to an individual property record.

## PG-23 — One operational currency per business in V1

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

PG V1 supports one operational/base currency per business.

## PG-24 — Business currency is used across PG finance

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

Rent, security, charges, expenses, collections, statements, and reports use the business operational currency.

## PG-25 — No PG V1 multi-currency/FX transactions

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

PG V1 does not support multi-currency/FX transaction accounting.

## PG-26 — Sequential setup shows real progress and Back

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

Genuine sequential setup/onboarding flows show Step X of Y, a progress indicator, and Back; Back preserves prior selections/entries; progress reflects the actual selected branch rather than an internal review-map screen count.

## PG-27 — Tenant onboarding steps

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Tenant onboarding is Basics → Room / Bed → Money → Requirements → Review.

## PG-28 — Minimum tenant onboarding data

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

The minimum tenant onboarding information is tenant name, phone, room/bed, and agreed joining date.

## PG-29 — Saving onboarding creates the real record

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Completing tenant onboarding saves the tenant/tenancy record directly rather than ending on a detached generic success page.

## PG-30 — Joining/rent-start date is authoritative

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

The agreed joining/rent-start date is authoritative for the tenancy agreement.

## PG-31 — Joining-date changes are controlled and non-destructive

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Changes to the joining/rent-start date are explicit and auditable and must not silently rewrite prior payments, posted obligations, or agreed financial history.

## PG-32 — Tenant Money fields

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

The Money step may capture monthly rent, due day, security amount, and joining date.

## PG-33 — Proration is suggested, not forced

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Proration may be suggested where relevant but is not forced automatically.

## PG-34 — Tenant requirement types

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Tenant requirements may include phone number, identity document, emergency contact, photo, address/basic details, and other documents.

## PG-35 — Requirement policy states

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

Each configured tenant requirement uses Required, Optional, or Not collected.

## PG-36 — Missing required information does not block tenancy creation

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

A missing configured required item does not prevent saving the tenant/tenancy; the record may be marked Setup incomplete and followed up operationally.

## PG-37 — Authority for missing requirements belongs in Staff & Access

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

The authority to proceed when required tenant information is missing is a staff permission/approval rule under Staff & Access, not part of the Tenant Requirements policy itself.

## PG-38 — Tenancy/Agreement is the commercial core object

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

The underlying commercial object is the Tenancy / Agreement rather than directly the person.

## PG-39 — Occupant, responsibility, payer, and deposit ownership are separate

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

The data model separates occupant(s), responsible party, payer, and deposit owner/source.

## PG-40 — Do not silently infer commercial roles as identical

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

When occupant, responsible party, payer, or deposit owner differ, Khaata must not silently infer that they are the same person.

## PG-41 — Responsible-party changes are effective-dated

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Changes to the responsible party are effective-dated so historical responsibility remains preserved.

## PG-42 — Deposit ownership is preserved

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Deposit ownership/source remains preserved through tenancy changes and settlement.

## PG-43 — Company/group accommodation remains model-compatible

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

The tenancy model may support company/group accommodation without collapsing occupancy, responsibility, payment, and deposit ownership into one identity.

## PG-44 — Tenant lifecycle states

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

The principal lifecycle is Upcoming → Active → Planned move-out → Moved out, with Upcoming → Cancelled before joining as a distinct alternative path.

## PG-45 — Upcoming tenancy actions

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

An Upcoming tenancy supports changing joining date, changing room/bed, cancelling before joining, and confirming joined.

## PG-46 — Activation requires explicit Confirm joined

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

An Upcoming tenancy becomes Active only through explicit confirmation that the tenant physically joined; the system does not auto-activate at midnight on the joining date.

## PG-47 — No-show is not a lifecycle state

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

No-show is not stored as a separate tenancy lifecycle state.

## PG-48 — No automatic cancellation/release/move for no-show

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

When the joining date passes without confirmation, Khaata must not automatically cancel the tenancy, release the bed, or move the tenant.

## PG-49 — Past-due joining becomes attention

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

An unresolved joining date that has passed surfaces as an attention item such as Joining overdue / Confirm joining, after which the owner can confirm joining, change the date, or cancel before joining.

## PG-50 — Room transfer preserves occupancy history

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

A room/bed transfer preserves the previous occupancy history rather than overwriting it.

## PG-51 — Room transfer does not silently change rent

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

A room/bed transfer does not automatically change rent; any rent change is explicit and effective-dated.

## PG-52 — Planned move-out does not end tenancy

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Planning a move-out does not itself end the tenancy.

## PG-53 — Planned move-out can change, cancel, or extend

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

A planned move-out may be changed, cancelled, or extended.

## PG-54 — Physical vacate, financial end, and bed release are distinct

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Physical vacancy, financial tenancy end, and bed release are separate concepts/events and are not forced to occur simultaneously.

## PG-55 — Use End tenancy, never Delete/Block

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

The definitive lifecycle action is End tenancy; Delete or Block are not used to represent tenancy closure.

## PG-56 — Former-tenant receivables survive move-out

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Outstanding receivables and other financial follow-up remain after the tenant becomes Former.

## PG-57 — Exit settlement is a process

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Exit settlement handles end date/notice, final dues, deposit settlement, and tenancy closure as a process rather than as a single destructive status change.

## PG-58 — Refund may remain pending after occupancy ends

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

A tenant may be Former while a security refund remains pending; the pending refund remains discoverable.

## PG-59 — Notice policy is configurable

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Notice rules are configurable; the system may warn when rules are not satisfied and authorized users may override according to policy.

## PG-60 — Bed conflict is based on overlapping commitments

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

A reservation/bed conflict exists when two legitimate occupancy commitments overlap for the same bed, including conflicts created by move-out extensions or joining-date changes.

## PG-61 — Bed conflicts surface in attention and assignment context

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

An unresolved bed conflict surfaces prominently in Needs attention and in the relevant assignment/edit context.

## PG-62 — Conflict detail shows both commitments

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Conflict resolution shows both affected tenancy commitments, their relevant dates, and lifecycle/occupancy context.

## PG-63 — Bed conflicts resolve only through legitimate underlying changes

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Valid conflict resolutions include changing a tenant’s room/bed, changing an upcoming joining date, changing/cancelling a planned move-out, or cancelling the upcoming tenancy.

## PG-64 — Khaata may suggest beds but never auto-reassigns

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Khaata may suggest available beds during conflict resolution but must never silently or automatically move/reassign a tenant.

## PG-65 — Both conflicting records remain intact

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Both tenancy records remain intact while a bed conflict is unresolved; ambiguity must not be resolved by overwriting one commitment.

## PG-66 — No separate Reservations module in PG V1

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

PG V1 does not require a separate Reservations module; bed conflicts are handled through attention and existing tenancy actions.

## PG-67 — PG billing frequency is monthly

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

PG V1 uses Monthly billing frequency with monthly calendar billing periods.

## PG-68 — Billing timing exposes Prepaid/Postpaid

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

Billing timing is explicitly configurable as Prepaid or Postpaid because it changes when rent obligations become due.

## PG-69 — Billing defaults include due day and optional grace

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

Business billing defaults include a default due day and an optional grace period.

## PG-70 — Rent obligations are generated automatically

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

An active rent agreement automatically generates monthly rent obligations deterministically and offline; owners do not manually generate routine monthly obligations.

## PG-71 — Due and overdue respect grace

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Due versus overdue state respects the configured grace period.

## PG-72 — Obligations and payments support many-to-many allocation

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

One obligation may be settled by many payments; one payment may be allocated to many obligations; excess payment becomes tenant credit.

## PG-73 — Old dues remain distinct from current month

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Old arrears are not silently merged into the current month’s obligation.

## PG-74 — Due-day changes are prospective

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Changing the due day affects future periods and does not rewrite settled historical periods.

## PG-75 — Future obligations may be forecast

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Future obligations may be derived/forecast where useful.

## PG-76 — Payment is a real financial event

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

A recorded payment is a real financial event and may capture payer, amount, mode, date, allocation, and proof where relevant.

## PG-77 — Digital payment proof may await verification

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

A digital payment/proof may remain in an awaiting-verification state where applicable.

## PG-78 — Receipts are immutable snapshots

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Payment receipts are immutable snapshots of the actual payment event.

## PG-79 — Corrections/reversals preserve the original payment

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Errors in posted payments are handled by adding correction/reversal events rather than rewriting or deleting the original event.

## PG-80 — Chargeback is a payment reversal

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

A chargeback is represented as a payment reversal, not as silent deletion of the original payment.

## PG-81 — Refund is a separate money-out event

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

A refund is a new money-out event and is not represented by rewriting the original receipt/payment.

## PG-82 — Collections screen structure

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Collections provides period/month context and views for Collected, Outstanding, Needs attention, Due, Paid, and All.

## PG-83 — Collection obligation actions

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

From an obligation, primary actions include Record payment, View statement, and Record promise.

## PG-84 — Collections prioritizes Record payment in the FAB

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

On Collections, the global action menu may reorder its stable action set so Record payment is first.

## PG-85 — Payment promise belongs to an outstanding obligation

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

A payment promise attaches to an outstanding obligation and records promised amount, expected payment date, and optional note.

## PG-86 — Promise does not change accounting truth

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

A payment promise does not change the original due date, amount owed, overdue truth, ledger balance, or Collected amount and does not create a payment transaction.

## PG-87 — Missed promise becomes attention

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

If the promised date passes without sufficient payment, the item can surface as Missed promise in Needs attention.

## PG-88 — Partial payments remain normal payments under a promise

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

A partial payment is recorded and allocated normally even when a promise exists; the promise remains relevant to any remaining promised amount.

## PG-89 — Promise history is preserved

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

A new promise does not overwrite the previous promise; prior promises remain in history.

## PG-90 — Settled obligation closes the promise

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

When the relevant obligation is fully settled, its outstanding promise is effectively fulfilled/closed.

## PG-91 — No separate Payment Promises module

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

PG V1 does not require a separate Payment Promises module; Record promise remains an obligation action.

## PG-92 — Security tracks agreed, paid, held, and ownership separately

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

The security model distinguishes security agreed, actual deposit payment events, security actually held, and deposit owner/source.

## PG-93 — Deposit receipts are real ledger transactions

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Actual deposit payments create real financial/ledger events and receipts.

## PG-94 — Security never automatically settles arrears

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Security actually held must never be automatically applied to outstanding rent/charges.

## PG-95 — Applying security to dues is explicit

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Using security to settle dues requires an explicit Apply security to dues action.

## PG-96 — Pending security refund remains discoverable

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

A pending security refund remains visible/discoverable after occupancy ends.

## PG-97 — Charges are distinct from rent, payment, and deposit

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Charges are separate financial concepts from rent obligations, payments, and security deposits.

## PG-98 — Charges can be recurring, variable, or one-time

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

PG charges may be recurring, variable, or one-time.

## PG-99 — Discounts, waivers, and corrections are not payments

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Discounts, waivers, and corrections remain separate adjustment concepts and are not recorded as payments.

## PG-100 — Charges may be disputed without erasure

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

A charge may have a disputed state; dispute status does not erase the underlying financial record.

## PG-101 — Tax is modeled at charge level

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Tax is modeled at the charge level in a jurisdiction-neutral way.

## PG-102 — Business owns jurisdictional finance context

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

The business owns jurisdiction, operational currency, timezone, and tax-registration context.

## PG-103 — No cross-currency aggregation without FX rules

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Khaata does not aggregate balances across currencies without explicit FX rules.

## PG-104 — Backdated tenancy offers two accounting-start paths

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

When onboarding an already-running tenancy, Khaata offers either Bring existing history or Start accounting from a chosen date.

## PG-105 — Bring existing history reconstructs relevant financial history

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

The Bring existing history path may capture/import past rent obligations, payments, charges, deposit activity, and other relevant history from the chosen start.

## PG-106 — Start accounting from date uses explicit opening figures

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

The Start accounting from date path uses explicit opening Outstanding balance, Security actually held, and Tenant credit rather than forcing reconstruction of all prior transactions.

## PG-107 — Opening balances are labeled and not fabricated transactions

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Opening figures are explicitly identified as opening balances and are not disguised as invented payments or charges; statements/reports distinguish them from events actually recorded in Khaata.

## PG-108 — Backdated accounting choice belongs in Add Tenant → Money

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

The backdated-accounting branch appears inside Add Tenant → Money when the tenancy is detected as backdated.

## PG-109 — Tenant Statement is a ledger projection with security separate

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Tenant Statement is a projection of obligations/ledger history and presents security separately from rent/charge balances.

## PG-110 — Statement preserves relevant financial history

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Tenant Statement can include obligations, payments, credits, adjustments, security, and opening balances and remains useful after move-out.

## PG-111 — Expenses are ready with defaults, not mandatory setup

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

Expense configuration is not a mandatory initial setup step; Khaata starts ready with sensible PG defaults and may offer optional Configure.

## PG-112 — Default PG expense categories

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

Default expense categories are Utilities, Repairs & Maintenance, Supplies, Staff, Food / Mess, Rent / Lease, and Other.

## PG-113 — Business-paid vs staff-paid is selected per expense

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

Whether an expense was business-paid or staff-paid is chosen on the expense itself rather than as a one-time setup choice.

## PG-114 — Expense entry fields

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Core expense fields are amount, category, date, and payment mode; optional fields may include note, vendor, and receipt.

## PG-115 — Expense approval belongs primarily in Staff & Access

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

Expense approval authority belongs primarily under Staff & Access; receipt/proof expectations may be configured separately.

## PG-116 — Recurring fixed expense creates an expected expense

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

A recurring fixed expense creates an expected expense and does not mark that expense as already paid.

## PG-117 — Maintenance is an expense with property context

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

PG V1 represents maintenance as an expense with optional property context rather than as a maintenance-ticket system.

## PG-118 — Tenant payment and physical cash custody are separate

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Receiving a tenant payment and possessing the corresponding physical cash are separate concepts/events.

## PG-119 — Staff cash collection settles the tenant immediately

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

When staff collects a valid cash payment, the tenant obligation is settled according to that payment immediately while physical custody is recorded as Cash with the relevant staff member.

## PG-120 — Cash handover is explicit

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Physical cash handover is an explicit custody-transfer event.

## PG-121 — Staff-to-staff cash transfer may require two-sided confirmation

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Cash may transfer between staff members and the flow may require confirmation by both sides.

## PG-122 — Cash discrepancy never reverses tenant payment truth

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

A cash shortage or handover discrepancy must not make a tenant appear unpaid or invalidate the tenant’s receipt.

## PG-123 — Cash discrepancy records expected and actual

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

At handover, Khaata records expected cash, actual cash received, and any resulting discrepancy; the discrepancy remains in Needs attention until resolved.

## PG-124 — Cash discrepancy resolution appends history

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

A discrepancy is resolved through an additional event such as remaining cash handed over, an approved adjustment/loss, or a recording-error correction; the original handover remains preserved.

## PG-125 — PG staff role templates

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

PG V1 provides Owner, Manager, Caretaker / Front desk, and Accounts role templates.

## PG-126 — Owner-only operation is valid

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

The PG can operate with the owner alone; initial setup may offer Owner only — add staff later.

## PG-127 — Action permissions use three states

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Action permissions use Allowed, Needs approval, and Not allowed.

## PG-128 — Visibility is separate from action permission

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

What a staff member can see is modeled separately from what actions they can perform.

## PG-129 — Role templates are customizable

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Khaata provides sensible role templates that the owner can review and customize.

## PG-130 — Approval request does not execute the action

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

When policy allows escalation, unauthorized staff may request approval; requesting/approving does not imply that the underlying action already occurred until it is actually authorized/executed.

## PG-131 — Proceeding with missing tenant requirements is a staff authority rule

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

Whether staff can proceed when tenant requirements are missing is governed through Staff & Access permissions/approval.

## PG-132 — Removing staff preserves historical accountability

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Removing or disabling a staff member does not erase their historical collections, custody, handovers, approvals, or attribution.

## PG-133 — Optional capabilities stay hidden unless enabled

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Optional PG capabilities remain hidden from normal operational flows unless the business enables them.

## PG-134 — Electricity policy options

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

Electricity configuration offers Not managed in Khaata, Included in rent, Charged separately, and Included up to a limit.

## PG-135 — Detailed electricity metering is deferred from initial setup

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

If electricity is separately charged, detailed meter/reading setup can occur later rather than burdening initial setup.

## PG-136 — Food/Mess policy options

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

Food/Mess configuration offers Not offered, Included in rent, and Fixed recurring charge.

## PG-137 — Food/Mess may use defaults and tenancy override

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

A food/mess charge may use a business default and/or a tenancy-specific override.

## PG-138 — Parking policy options

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

Parking configuration offers Not offered, Included, Fixed recurring charge, and One-time / ad-hoc charge.

## PG-139 — Parking details belong to the tenancy when enabled

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

When parking is enabled, the tenancy may capture whether parking applies, vehicle type/number, and an agreed parking charge where relevant.

## PG-140 — No parking-slot inventory in PG V1

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

PG V1 does not include parking-slot inventory/capacity management; a future slot model may be added later without changing the tenancy model.

## PG-141 — Occupancy states are derived

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Room/bed occupancy states are derived as Vacant, Occupied, Reserved, and Planned vacancy.

## PG-142 — Capacity lifecycle states are separate

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Capacity availability/lifecycle is separate from occupancy and uses Available, Temporarily unavailable, and Retired.

## PG-143 — Temporarily unavailable keeps the capacity record

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Temporarily unavailable means the real room/bed still exists but cannot currently be assigned; it may carry a reason and available-from date, remains visible, is excluded from assignable capacity, and preserves history.

## PG-144 — Retirement is effective-dated and non-destructive

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Retiring a room/bed means it is no longer active going forward; retirement is effective-dated, preserves historical context, and is not hard-delete.

## PG-145 — Capacity cannot be disabled while it invalidates a commitment

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

A room/bed cannot simply be made unavailable or retired when doing so would invalidate a current occupancy or future commitment; the affected tenancy/reservation conflict must be resolved first.

## PG-146 — Retiring a room must expose effects on child beds

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

When retiring a room containing active beds, Khaata must show the consequence explicitly rather than silently retiring all child beds.

## PG-147 — Home contains Needs attention, Coming up, and Business Pulse

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

The PG Home structure consists of Needs attention, Coming up, and Business Pulse.

## PG-148 — Attention uses a decision-changing relevance rule

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

A signal belongs in operational attention when knowing it now can change what the owner should do.

## PG-149 — Urgent Home examples

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Urgent attention includes cases such as reservation conflict, cash discrepancy, and outstanding amount greater than or equal to security actually held.

## PG-150 — Actionable Home examples

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Actionable attention includes cases such as overdue dues, missed payment promise, approval waiting, refund pending, handover confirmation, unresolved due-to-join tenant, and selected missing required information.

## PG-151 — Upcoming Home examples

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Upcoming operational signals include move-out, joining, availability changes, and rent due soon.

## PG-152 — Context-dependent Home examples

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Context-dependent signals may include cash with staff and part-paid amounts before the due date or within grace.

## PG-153 — Informational metrics do not automatically become attention

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Informational items such as vacancy, occupancy percentage, collected amount, and expenses do not automatically belong in Needs attention.

## PG-154 — Routine successful states stay quiet

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Routine paid/settled/all-good states are not surfaced as attention items.

## PG-155 — Related attention signals may collapse

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Related operational signals should be collapsed/aggregated where doing so avoids duplicate noise.

## PG-156 — Attention has no arbitrary dismiss/snooze/acknowledge layer

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Needs attention is derived from underlying state and does not introduce generic Dismiss, Snooze, or Acknowledge actions unless a later use case explicitly requires them.

## PG-157 — Coming Up is a rolling seven-day forecast

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Coming Up is a derived rolling 7-day forecast of near-term operational events.

## PG-158 — Routine Coming Up events aggregate; exceptions remain individual

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Routine repeated upcoming events may aggregate, while exceptions remain individually visible.

## PG-159 — Unresolved upcoming events transition into attention

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

When an upcoming event passes its relevant date unresolved, it transitions deterministically into Needs attention where appropriate.

## PG-160 — No generic reminder-list system

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

PG V1 does not add a generic reminder/task-list system for these operational events.

## PG-161 — Business Pulse money fields

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Business Pulse includes Collected and Outstanding.

## PG-162 — Business Pulse occupancy fields

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

Business Pulse prefers Vacant beds and Becoming vacant this month rather than an occupancy-ratio presentation.

## PG-163 — Business Pulse time semantics

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Money in Business Pulse uses the current calendar month, while occupancy is point-in-time.

## PG-164 — Permanent Business Pulse excludes secondary analytics

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Permanent Business Pulse excludes total deposits, cash with staff, expenses, profit, rates, trends, collection percentage/progress bars, and charts.

## PG-165 — Unknown capacity is not zero

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

If capacity is unknown, Khaata must not present it as zero.

## PG-166 — Business Pulse tap behavior

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Collected can open recent payments; Outstanding can open balances/due dates; Vacant beds can open available rooms/beds.

## PG-167 — Expanded Business Pulse stays concise

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Expanded Business Pulse uses concise aligned rows rather than prose-heavy explanation.

## PG-168 — No Home cash-flow/chart in PG V1

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

The Home cash-flow/chart experiment is not part of PG V1; charts may be reconsidered later in Collections, reporting, or insights.

## PG-169 — Home attention cards can stack

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

Needs attention and Coming up are complete cards that may be shown in a physical stack; rear cards remain partially visible, can be brought forward, and the same cards can also be shown vertically via Show all.

## PG-170 — Home stack supports future layers without adding fake PG cards

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

The stack may support up to four visible layers for future business types, while PG uses only its real available cards.

## PG-171 — No circular totals on Home stack cards

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

The Home stack does not require circular total/count indicators.

## PG-172 — Tenants screen lifecycle filters

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

The Tenants screen provides search and lifecycle filters Active, Upcoming, Moving out, and Former, with Active as the default.

## PG-173 — Tenants screen avoids dashboard summaries

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

The Tenants screen does not add totals, charts, or collection-summary cards above the list.

## PG-174 — Tenant rows show identity, location, and exceptions only

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

Tenant rows prioritize name, room/bed, and only an operationally relevant third line such as overdue; normal rows do not show “All good” or a zero balance.

## PG-175 — Tenant Detail is the operational tenancy record

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Tenant Detail contains identity, room/bed, lifecycle context, outstanding, Record payment, Share reminder, tenancy terms, current month, recent payments, phone/requirements, transfer room, plan move-out, and edit agreement.

## PG-176 — Reminders are manual Share reminder in V1

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

PG V1 uses a manual Share reminder action rather than a built-in generic messaging system.

## PG-177 — Collections and Tenant Detail serve different intents

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Collections is obligation-first while Tenant Detail is tenancy-first; both may reach the same financial data without being the same screen model.

## PG-178 — More is configuration/secondary operations, not another dashboard

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

More contains configuration, staff/access, optional features, settings, and secondary operational tools rather than acting as another dashboard.

## PG-179 — Backup/sync choice is shown during setup

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

Setup shows the backup/sync choice rather than silently hiding it; On this device only may be selected by default while all options remain visible.

## PG-180 — On this device only behavior

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

On this device only keeps data on the device, allows local backup/export and restore, does not require backup to operate, and should communicate device-loss/reset risk when no exported backup exists.

## PG-181 — Google Drive backup behavior

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Google Drive backup keeps core work local-first and supports automatic/manual Drive backup and restore.

## PG-182 — Khaata Sync (Pro) behavior

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Khaata Sync (Pro) keeps the local database operational offline and syncs with the server when connected; server-dependent information may show stale/connection state.

## PG-183 — Free-to-Pro preserves existing local data

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

When moving from Free to Pro, existing local data can be uploaded/synced rather than requiring the business to start again.

## PG-184 — Offline IDs and concurrent events are conflict-safe

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Core records use globally unique offline-safe IDs; legitimate concurrent events are preserved; conflicts are surfaced explicitly rather than silently overwritten.

## PG-185 — Permissions and offline access are separate

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

A user’s action permissions and their ability to access already-cached data offline are separate concerns.

## PG-186 — Stale-auth handling exists but exact sync protocol is deferred

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

The product may use stale authentication windows and stale/connection states, while the exact synchronization/conflict protocol remains an implementation decision outside the PG V1 structural freeze.

## PG-187 — No formal accounting period close in PG V1

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

PG V1 does not introduce a formal accounting-period close.

## PG-188 — Outstanding at or above security held is urgent

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

An outstanding balance greater than or equal to security actually held is a high-priority/urgent condition; the comparison uses security actually held, not merely security agreed.

## PG-189 — Former tenant financial follow-up remains available

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Former tenant records may continue to show outstanding balances, payments, pending refunds, write-off actions, and statements.

## PG-190 — Write-off is explicit and is not payment

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

A write-off is a distinct explicit action, should carry a reason, and is not recorded as a payment.

## PG-191 — Waiver/discount is an adjustment, not payment

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Waivers and discounts are adjustment concepts and are not recorded as payments.

## PG-192 — Dispute status preserves the charge record

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Marking a charge disputed does not erase the financial record.

## PG-193 — Approval request and execution are distinct

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

An approval request represents a request for authority and does not mean the underlying action has already been executed.

## PG-194 — Historical capacity records are never hard-deleted

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Rooms, beds, buildings/blocks, floors, and other capacity entities with history are not hard-deleted; future UI may use retire/archive semantics where appropriate.

## PG-195 — Persistent PG navigation

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

Persistent PG navigation is Home · Tenants · Collections · More.

## PG-196 — Global FAB action set

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

The global FAB action menu contains Add tenant · Record payment · Add expense · Add charge.

## PG-197 — FAB priority may reorder by context without changing the action set

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

Context may reorder which FAB action appears first, but it does not redefine the stable PG action set.

## PG-198 — HR/workforce is outside the PG vertical scope

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

Full HR/workforce management beyond PG staff access is a separate shared-product discussion and is not part of PG V1.

## PG-199 — PG Home is not an analytics dashboard

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

PG Home does not become a broad analytics dashboard; operational attention and the small Business Pulse remain the structural model.

## PG-200 — PG / Hostel Product Structure V1 is frozen

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

The product hierarchy, major workflows, lifecycle rules, core business invariants, navigation, setup/configuration structure, and audited edge-case behavior are frozen as PG / Hostel Product Structure V1.

## PG-201 — Visual and implementation details remain unfrozen

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Owner

The structural freeze does not freeze visual styling, components, colors, typography, spacing, radii, shadows, animation, validation wording, implementation internals, exact sync protocol, performance, accessibility, or later reporting/insights.

## PG-202 — Future structural changes require evidence or a deliberate V2 decision

**Status:** Active  
**Last updated:** 2026-10-05  
**Source:** Unverified

A future structural change should be made only when usability testing reveals a genuine workflow failure, implementation exposes a model contradiction, real PG usage exposes a missing core case, or a deliberate V2 product decision is made.

---

# Historical evolution and review record

These notes preserve the history around the decisions above. They are not additional active decisions unless they point to a PG ID.

## A. Pre-UI product direction

The PG/Hostel work began by deliberately postponing visual-system work until the business workflow had been understood. The working process was to map setup, capacity, tenancy, money, expenses, staff, cash accountability, lifecycle, exceptions, and offline behavior first. This historical direction is represented primarily by PG-1 through PG-4.

## B. Review method

The product review method became **Keep / Change / Missing**. V2 prototypes were to be created only where something actually required a structural change. The user preferred concrete prototypes over repeated conceptual preambles and preferred structural evaluation before visual polish.

## C. Edge-flow review

A dedicated edge-flow review tested six flows:

1. **Room Transfer** — passed after confirming that occupancy history remains preserved and rent changes are separate. Relevant decisions: PG-49, PG-50.
2. **Payment Correction / Reversal** — passed after confirming that the original payment remains and the correction/reversal is a new event. Relevant decisions: PG-78 through PG-80.
3. **Security Refund** — passed after confirming that a pending refund remains discoverable after occupancy ends. Relevant decisions: PG-57, PG-95.
4. **Dispute / Write-off** — passed after confirming that keep due / waive / write off remain distinct, a write-off is not a payment, and the financial record is not erased. Relevant decisions are the active charge-adjustment, write-off, waiver/discount, and dispute records in the atomic decision section above. The canonical authority is those PG records, not the former narrative numbering.
5. **Approval Request** — passed after confirming that staff can request approval without the action already having occurred. Relevant decision: the Approval Request decision above.
6. **Former Tenant Follow-up** — passed after confirming that old dues remain after the tenant becomes Former. Relevant decisions: PG-55 and the Former Tenant Follow-up decision above.

> Note: the historical source document used prose rather than stable IDs, so this appendix intentionally describes review outcomes at a high level. The atomic decision section above is canonical.

## D. Final six-area structural audit

Immediately before freeze, six remaining areas were explicitly checked:

1. Upcoming tenant changes / cancellation / no-show
2. Reservation / bed conflicts
3. Payment promises
4. Backdated onboarding / opening balances
5. Cash discrepancies
6. Temporarily unavailable / retired rooms or beds

All six were resolved without requiring a new top-level module. No unresolved core product-model failure remained at freeze.

## E. Issues/failures found and resolved before freeze

### E1. Upcoming activation ambiguity
An automatic date-based transition could falsely claim physical occupancy. The resolution was explicit **Confirm joined** and no automatic activation. See the Upcoming activation decisions.

### E2. No-show ambiguity
It was unclear whether a missed joining date should cancel a tenancy or release the bed. The final rule is: no-show is not a lifecycle state; do not auto-cancel, auto-release, or auto-move; surface a joining-overdue attention item.

### E3. Reservation/bed-conflict gap
Overlapping legitimate commitments needed explicit behavior. The resolution was to preserve both records, surface the conflict, offer legitimate underlying changes, and never auto-reassign.

### E4. Requirements approval was in the wrong place
Approval authority for proceeding with missing requirements was initially mixed into Tenant Requirements. It was moved to Staff & Access because it is an authority rule, while requirement configuration remains Required / Optional / Not collected.

### E5. Expense setup was too heavy
Expenses had been treated as a mandatory setup concern. The final structure uses sensible defaults with optional configuration.

### E6. Backup wording
The wording “Local only” was replaced with **On this device only**.

### E7. Spreadsheet import scope changed
An earlier prototype used CSV-oriented wording. The final decision supports **.xlsx + .csv**, with .xlsx as the primary template. Earlier CSV-only prototype copy is stale.

### E8. Operating Configuration V1 became stale
The earlier configuration prototype no longer reflected the final Requirements, Expenses, Parking, Staff & Access, and Backup/Sync decisions. A V2 prototype was created to reflect the accepted structure.

### E9. Home chart direction did not survive review
A Home cash-flow/chart experiment was tried and explicitly dropped. Charts were deferred to Collections/reporting/insights.

### E10. Android local multi-file review hub failure
A review hub that depended on sibling local HTML links did not work reliably in Android Chrome. The prototype convention became: prefer one self-contained HTML with multiple JS views for multi-screen local reviews. This was an implementation/prototyping failure, not a product-model failure.

## F. Freeze result

**No unresolved structural failure remained at freeze.** The audits did identify missing rules, misplaced configuration, stale prototype assumptions, and one prototype-navigation failure, but all product-structure issues were resolved or explicitly deferred before the PG / Hostel Product Structure V1 freeze.

---

# Prototype/reference record

Structural prototypes accepted/current during the V1 process included:

- `khaata-pg-tenants-v2.html`
- `khaata-pg-tenant-detail-v1.html`
- `khaata-pg-add-tenant-v1.html`
- `khaata-pg-collections-v1.html`
- `khaata-pg-v1-review-hub-self-contained.html`
- `khaata-pg-v1-product-flow-map.html`
- `khaata-pg-v1-edge-flows.html`
- `khaata-pg-setup-v1-interactive.html`
- `khaata-pg-operating-configuration-v2.html`

Earlier prototypes may contain superseded wording. The active PG decision records in this document are canonical for structural decisions.

---

# Ambiguous atomic splits requiring owner review

The following areas could reasonably be split differently without changing meaning. They are flagged so the owner can decide whether any IDs should be subdivided **before these IDs are used externally**:

1. **PG-9 — Property setup and tenancy setup are separate.** This contains both the positive boundary (“setup establishes capacity / onboarding establishes the commercial relationship”) and the exclusion of tenant-specific commercial fields from capacity setup. These could be two atomic decisions.
2. **PG-11 — Inline-created capacity is real capacity.** This combines two closely related invariants: no temporary tenant-only capacity, and creation of the capacity record before assignment.
3. **PG-26 — Sequential setup shows real progress and Back.** This combines Step X of Y, progress bar, Back, state preservation, and branch-aware progress. They were treated as one setup-flow convention, but could be split.
4. **PG-38 / PG-39 — Commercial-role separation.** The role separation and the prohibition on silently inferring identities are conceptually distinct but tightly coupled; the current log already splits them, yet further separation by occupant/responsible party/payer/deposit owner is possible.
5. **PG-53 — Physical vacate, financial end, and bed release are distinct.** This is one three-part invariant. It could be split into pairwise decisions, but that would be more verbose without changing the model.
6. **PG-69 — Automatic obligation generation.** This combines automatic generation, deterministic generation, and offline capability. These could be three technical/behavioral decisions.
7. **PG-71 — Obligation/payment allocation.** One-obligation-to-many-payments, one-payment-to-many-obligations, and excess-to-credit are three atomic accounting rules currently grouped because they define one allocation model.
8. **PG-91 — Security tracks agreed, paid, held, and ownership separately.** This is a multi-part deposit invariant and could be split into separate IDs for each dimension.
9. **PG-117 / PG-118 — Payment vs cash custody.** The conceptual split and the “staff collection settles the tenant immediately” consequence are separate IDs, but some teams may prefer one combined cash-custody invariant.
10. **PG-126 / PG-127 — Staff permissions vs visibility.** These are already split, but the role-template behavior in PG-128 could also be decomposed into “templates exist” and “owner can customize.”
11. **PG-142 — Temporarily unavailable.** This currently combines semantic meaning, optional metadata, visibility, assignment exclusion, and history preservation.
12. **PG-146–PG-155 — Home attention model.** There is a general inclusion rule plus example classes and noise-suppression rules. The examples may be better treated as policy examples rather than independent long-term decisions if the team expects those examples to evolve.
13. **PG-160–PG-166 — Business Pulse.** Fields, time semantics, excluded analytics, unknown-capacity behavior, tap destinations, and expanded presentation are separate decisions, but the boundary between structural product rule and UI presentation is somewhat mixed.
14. **PG-168–PG-170 — Home stack.** These are more presentation-oriented than the rest of the structural log. They were retained because the source freeze record treated them as accepted behavior.
15. **PG-178–PG-181 — Backup & Sync.** There is a product-policy decision to show the choice during setup and separate behavioral decisions for each storage/sync option. The current split follows that distinction.
16. **PG-183–PG-185 — Offline/sync invariants.** Unique IDs, concurrent-event preservation, explicit conflicts, offline permissions, stale auth, and sync-protocol deferral could be decomposed more finely if implementation teams will reference them independently.

---

# Canonical authority rule

For PG / Hostel structural questions, the active PG decision records in this file are the canonical V1 source. Historical narrative and older prototypes provide context but do not override an Active PG decision.

**End of Khaata — PG / Hostel Versioned Decision Log v1.0.0**