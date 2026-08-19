# Khaata — Decision Record: The Capability Model

**Status: ✅ DECIDED by Mr. T. This supersedes the "5-engine" proposal and the "EVENT as separate engine" assumption from prior sessions.**
**Decision date:** 2026-07-20 (session with Claude).
**Answers:** Open Question 1 (does EVENT stay a separate engine?) — resolved. Open Question 2 (do EVENT/SALE merge?) — dissolved (no longer applies).

This is a full record, not a summary. It captures the reasoning, the model, the per-business mapping, what changes, what doesn't, and what to build against.

---

## 1. The Question That Started It

Prior sessions proposed organising business types into "engines" — first two (Mode 1 subscription / Mode 2 job-service, already locked and driving GST defaults), then a proposed five (SUB / APPT / EVENT / JOB / SALE). The EVENT mockups (photographer, makeup, catering, tent house) were built on the assumption that "EVENT" is a real, separate engine.

Open Question 1 was: **does EVENT stay a separate engine, or fold back into the two-mode model?**

## 2. The Insight That Answered It (Mr. T's)

The calendar is not one feature. It is **two different behaviours** that happen to share a grid:

**(a) Blocking calendar** — the service is delivered *on* the date, so two commitments on one date is a **conflict**. The calendar's job is a **quick availability check before confirming** a booking.
- Examples: photographer, makeup artist, tent house, banquet, catering (on the event day).

**(b) Highlighting calendar (agenda / notes)** — a date merely *carries* information: a payment due, an expense made, an ad to be distributed, a reminder, a free-text note. **Overlap is meaningless** — many things can share one day and that's fine. The calendar's job is simply **"don't forget."**
- Examples: newspaper agency (ad-drop dates, collection days), rent collection (5th = collection day, electricity bill entered), and in truth *every* business (payments received, expenses made, notes).

**Therefore:** the calendar is **not** what makes EVENT special. It is a feature that spans all business types, distinguished only by whether an **overlap-check** is switched on. EVENT does not need to be a separate engine to have a calendar — because everyone can have a calendar.

Mr. T's own words captured the general form: *"maybe calendar may also have a note?"* — yes. The highlighting calendar **is** a notes-and-events calendar, and that is precisely what makes it useful to the ~80% of businesses that never take a date-committed booking.

## 3. The Decision

**Fold EVENT in. Do NOT make it a separate engine.**

The architecture is:

### 3a. Two billing modes stay (unchanged, still load-bearing)
- **Mode 1 (Subscription):** GST off by default. Fee-plan / recurring-billing oriented.
- **Mode 2 (Job / Service):** GST on by default. Per-job / per-bill oriented.

These continue to drive the bill shape and the GST default exactly as already locked. Nothing here changes.

### 3b. "Engines" are demoted to **capability presets**
There are no separate engines. Instead there is a set of **capabilities** that any business can switch on or off. A "business type" (Gym, Newspaper, Photographer, Tent House…) is simply a **preset = one mode + a bundle of pre-selected capabilities**. The owner can override any capability afterward.

This is the same **feature-toggle pattern from the competitor's Section 16** (which Mr. T already liked) — with the Khaata improvement noted in an earlier session: **the business-type preset does the toggling for you**, rather than making the user hunt through switches.

### 3c. The capability list (initial)
Each is an independent on/off, defaulted by the business-type preset:

| Capability | What it adds | Default-on for |
|---|---|---|
| **Agenda calendar** | Dates carry payments / expenses / reminders / free-text notes. No overlap logic. | Available to ALL; on where useful |
| **Booking + overlap-check** | Dates hold a committed service; confirming checks for clashes. Advance/balance, date-block. | Date-committed services only |
| **Recurring generation** | Auto-raise bills on a cycle from a fee plan. | Subscription businesses |
| **Stock / inventory** | Quantity-owned, availability, stock depletion. | Retail + rental |
| **Stages / milestones** | Multi-step job progress. | Contractor / project work |
| **Per-plate / per-unit pricing** | Headcount- or quantity-driven totals. | Catering, rentals |
| **Staff + attendance + payout** | People module. | Businesses with employees |

### 3f. Staff, attendance & payout — data model (locked 2026-07-20)
Three staff screens exist (`onboard-staff.html`, `my-staff.html`, `staff-attendance.html`). They were built separately and stored data inconsistently; this reconciles them. **The governing principle: store the events, derive the summaries.** (Same principle as the payments log and the documents checklist.)

- **Attendance is per-date and is the single source of truth:** `att:{'2026-06-24':'P'}` (P/A/H/L per day). Monthly totals, weekly totals, and "days worked" are **always derived by counting** — never stored as standalone numbers. (`my-staff.html`'s old `att:{present:24,leave:2}` summary becomes a computed value.)
- **Advances (peshgi) are dated entries, balance is derived:** `adv:[{date,amount,note}]` and `ded:[{date,amount}]`; `balance = sum(adv) − sum(ded)`. (`my-staff.html`'s old single `s.advance` number becomes the derived balance.) This preserves history — when each advance was taken, when deducted — which a running number can't.
- **Two attendance modes** (already in `staff-attendance.html`, kept): `daily` (mark each day, wage = present-units × rate) vs `leave-only` (salaried, assumed present, only log leave; salary − unpaid-leave deduction). Preset by pay type, overridable per worker.

**Payout — two paths, both must write to the same Money Out / payments log:**
1. **Per-worker payout** — already built in `my-staff.html` (wages/salary, advance deduct with "how much" control, carry-forward, new-advance mode, Cash/UPI/Bank, UPI pre-fill, payment log).
2. **Weekly crew payout** — added to `staff-attendance.html` as a Payout tab. Pulls present-days from attendance (no re-typing), computes payable per worker, per-worker advance control (**Full / Part / Skip** — user chooses per worker), skip-worker toggle, one-pass confirm. Carry-forward when advance exceeds payable.

**Advance-in-crew-payout rule:** user decides per worker (Full deduct / Part / Skip), not a global setting — a thekedar settles some men's peshgi and lets others carry forward in the same run.
The Documents capability (existing Google Drive / BYOS vault) works in **two stages** and against **two anchors**. This is now the intended pattern for Documents across *all* business types, not just construction:

**Two stages:**
1. **Setup stage** — the owner defines a *checklist of expected document names* only. No files are uploaded here (respects "setup configures, never populates"). Toggle + checklist only.
2. **Operational stage** — a separate per-record screen shows each checklist item as *missing* or *attached ✓*, and is where the actual file gets attached to Drive. **This operational screen is not yet built.**

**Two anchors:**
- **Party documents** attach to a *person/entity* and follow them across jobs (a contractor's licence, a thekedar's ID, worker ID proofs). Survive beyond any single project.
- **Project/site documents** attach to *one project* and close out with it (sanctioned plan, soil test, drawings, municipal approval).

The party-document checklist should **adapt to context** (in construction it adapts to the owner's role; elsewhere it adapts to the party type — patient vs facility, tenant vs property). Demonstrated in `construction-setup.html`. Candidate to generalise: clinic (patient ID vs facility licence), PG (tenant ID + agreement vs property papers) fit the same party-vs-project split.

(This list will grow; the point is the *shape*, not completeness.)

### 3d. The calendar specifically
One calendar feature, with a **mode switch per business**:

- **Overlap-check ON** → blocking calendar. Booking businesses. "Is this date free?" warning before confirm. (Soft warning, not a hard block — matches the Timetable double-booking pattern already established.)
- **Overlap-check OFF** → agenda/highlighting calendar. Dates highlight notes, payments due, expenses, reminders. Many items per day is normal.

The agenda calendar is the **base**; overlap-check is a **flag booking businesses add on top**. Same grid, same code, one boolean.

### 3g. Site expenses — category-driven entry (built 2026-07-20)
`site-expenses.html` — single-project screen. Budget bar splits spend into Material / Labour / Charges (stacked, colour-coded); shows only if Budget capability on. **Category drives the input:** material = quantity × rate (per-material default units + rates, editable, amount overridable); charges = flat amount; labour = either **auto** (pulled read-only from a recorded crew payout — no double-count) or **manual** (casual one-off worker). Labour tags in the list distinguish auto ("from payout") vs manual.

### 3h. Money in — role-adaptive (built 2026-07-20)
`money-in.html` — same screen, two framings driven by business role:
- **Contractor → Client Billing:** quote / received / balance; **stage payment schedule** (each stage expected vs received, Due/Part/Paid); payments tie to a stage OR go **on-account** (untagged, for round-number client payments).
- **Owner → Project Funds:** funds put in − spent (from expenses) = **available to spend**; smart low-balance nudge (green/amber/red). Answers "do I still have money to build," not "has the client paid."

### 3i. Stages / progress tracker (built 2026-07-20) — the tracking hub
`stages-progress.html`. **Two independent facts per stage:** work-status (Not started / In progress / Complete) is SEPARATE from payment-status. Work is set here; **payment is a read-only reflection** of money-in (paying happens on the money screen, never faked here).

**Each stage is simple OR checklist — owner chooses per stage, convertible both ways:**
- **Simple:** one story, direct work-status selector, own site diary.
- **Checklist:** has sub-tasks; work-status **auto-derived** (none done=Not started, some=In progress, all=Complete). Sub-tasks come with **suggested starters per stage** (editable). 

**Notes/attachments:** a **dated site diary** (log, not single note) + combined photo/doc bucket, living on sub-tasks when they exist, else on the stage. **Ready-to-bill cross-signal:** work Complete but not fully Paid → flags + totals "ready to collect," nudging back to money-in. Progress hero is weighted by stage amount; surfaces "current stage" for the future dashboard.

### 3j. "Pick-or-add-and-remember" — app-wide standard for list fields (locked 2026-07-20)
Any picker where the user might need a value not in the list gets a "+ Other / + New…" option → type a name → on save, if new, **ask "Save 'X' for next time?"** → adds to that list. Materials remember unit + rate; sources/stages/charges remember the name (stages also capture expected amount). Case-insensitive dedupe. **Every future list field should use this pattern** rather than re-deciding. The material-with-rate variant is the seed of the long-flagged **reusable item/price catalogue**.

## 4. Q2 Dissolved

Open Question 2 was "do EVENT and SALE merge?" — driven by tent house being a booking business that also carries stock.

**This question no longer applies.** With no separate engines, tent house is simply: **Mode 2 + booking/overlap-check + stock + per-unit pricing** — three independent capabilities that happen to coexist on one business. There is nothing to "merge" because there were never separate engines to reconcile. The tent-house awkwardness was an artifact of the engine framing, and the engine framing is gone.

## 5. How the Three Worked Examples Map

| Business | Mode | Agenda calendar | Overlap-check | Other capabilities |
|---|---|---|---|---|
| **Photographer** | Mode 2 | on | **ON** (blocking) | booking, advance/balance |
| **Newspaper agency** | Mode 1 | on (highlight ad-drops, collection days, notes) | **OFF** | recurring generation |
| **Rent collection** | Mode 1 | optional (off, or "5th = collection", "bill entered") | **OFF** (never blocks) | recurring generation |
| **Tent house** | Mode 2 | on | **ON** | booking, stock, per-unit pricing, deposit |
| **Catering** | Mode 2 | on | **ON** | booking, per-plate pricing, guest-count |
| **Gym / Coaching** | Mode 1 | optional | OFF | recurring generation, staff, attendance |

## 6. What This Costs (Almost Nothing) — Nothing Is Thrown Away

Every mockup already built survives intact; only the *framing* changes:

- **`bookings-calendar.html`** → becomes the **agenda calendar** base. Its cross-business view, money strip, and scope selector are all still correct.
- **The conflict warning in `booking-create.html`** → becomes the **overlap-check** capability (a flag), not a property of a walled-off engine.
- **The four EVENT setup pages** (photographer, makeup, catering, tent house) → still valid. They're now "Mode 2 presets with the booking capability on," not "EVENT-engine businesses." Their tabs (packages, advance, add-ons, stock, per-plate) are exactly the capability bundles above.
- **Advance / balance / date-block / per-plate / per-item** → all still exist, all still work. They're capabilities, triggered by a preset instead of an engine tag.

The booking wizard, the calendar, the group management — none of it is invalidated. The decision is a **re-labelling that simplifies**, not a rebuild.

## 7. New Idea Captured: Calendar Notes

Mr. T's "calendar may also have a note" is now a **first-class part of the agenda calendar**, not an afterthought. The agenda calendar holds, per date:
- Payments received / due
- Expenses made
- Reminders
- **Free-text notes** (e.g. "ad drop — route 4", "collect from Sharma", "electricity bill ₹2,400")

This is what makes the calendar valuable to non-booking businesses (the majority). It is the general form of the whole feature: a booking is just a note that also blocks the date.

## 8. What Changes in the Roadmap

- The "5-engine" model in `Khaata-Business-Categories.md` and `Khaata-Screen-Matrix.md` is now **reference-only market research**, not architecture. The archetype tags are still a useful way to *think about* businesses, but they are not code structures. Do not build "engines."
- Build **capabilities** instead, each independently, each switchable.
- The business-type picker + feature-toggle screen (previously flagged as a GAP) is now **more important**, because it is the mechanism that turns capabilities into presets. It should be specced early.

## 9. What Does NOT Change

- Two billing modes (Mode 1 / Mode 2) and their GST defaults — unchanged.
- Migration 001 schema — unchanged. (A capability is a per-business setting/flag, not a new table structure. Worth confirming the businesses/settings tables can hold a capability set, but no structural change is implied.)
- Tier structure (Free / Pro / Premium) — unchanged.
- All existing 43 prior artifacts + this session's 7 mockups — all still valid.
- Local-first freemium split, global-ready defaults, all locked principles — unchanged.

## 10. Still Open / To Decide Later (NOT blocking)

- **Exact capability list** — Section 3c is a starting set, not final. Expect additions (documents, quotations, etc. may become capabilities too).
- **Where the capability toggles live in the UI** — inside Business Settings, presumably, grouped sensibly. Needs a screen.
- **Calendar note types** — how structured vs free-text; whether notes can carry an amount that feeds the ledger. Design decision for when the agenda calendar is built for real.
- **Whether "overlap-check" is one flag or per-resource** — tent house overlaps on *stock quantity*, photographer overlaps on *the whole day*. May need the check to be aware of what's being blocked (a day vs a countable resource). Flagged for the booking build.
- **Does agenda calendar default on or off** for a brand-new business — probably off, opt-in, to keep onboarding clean (consistent with "onboarding configures, never populates").
- **Operational document screen built** (`documents-operational.html`). Hub (parties + projects, each with attached/total + expiry flags) → per-record checklist. Each doc row: status (Missing / Attached / Expiring soon / Expired), expiry captured on attach for expiring types, and a ⋯ menu. **Delete tiers locked here:** Replace file = no confirm (fixes wrong-file-right-row); Remove file = single confirm, row returns to Missing (recoverable); Delete document row = double confirm AND only offered on user-added custom docs (standard checklist slots can't be deleted). Add-document flow captures name + optional attach + optional expiry in one sheet. Summary pills double as tap-to-filter. Attach is mocked (no real Drive call yet).

- **Record-level delete (labourer / project / party) — Archive-first pattern (locked, not yet built):** Deleting a whole record that carries history (a worker with attendance/wages, a project with costs/payments) defaults to **Archive** (hide from active lists, keep all records). True **Delete** is double-confirmed and **blocked if money/attendance history exists** — consistent with the locked staff-offboarding rule (settle dues → deactivate, never hard-delete history). This does NOT live on the documents screen; it belongs on the record's own screen (worker → staff/attendance screen, project → project screen). To be built there.

- **Staff screens share the §3f model only in concept, not in code.** Per-date attendance + advance-entry model is demonstrated inside `staff-attendance.html`, but `my-staff.html` and `onboard-staff.html` still carry older shapes. Making all three read/write ONE per-date attendance store and ONE advance-entry store is a real-code/SQLite task; an HTML mockup can only show the shape.
- **Two payout paths must converge on one payments log.** Per-worker payout (`my-staff.html`) and weekly crew payout (`staff-attendance.html`) should both write the same Money Out / payments entries. Currently each mocks separately. This is where the long-standing "Record Payment accepts any amount" item actually gets implemented.

## 11. Instruction for Build / Next Chat

- Treat this document as **decided**. EVENT is not an engine. Build capabilities, not engines.
- It is now safe to reference this decision when updating `BUILD-ORDER.md` and `CLAUDE.md` — but make those edits deliberately and show Mr. T, per the standing rule that architectural changes need explicit approval before proceeding. This document *is* that approval for the capability model itself; the roadmap-file edits that follow from it should still be surfaced.
- The EVENT mockups can now proceed toward real code **as Mode-2-with-booking-capability**, once payment recording and the bill flow (the engine-independent money-movement gaps) are in place.

---

**One-line version for the top of CLAUDE.md:** *No separate engines. Two billing modes (1/2) + independent capability toggles preset per business type. Calendar is one feature with an overlap-check switch: ON = booking/blocking, OFF = agenda/notes. Available to all businesses.*
