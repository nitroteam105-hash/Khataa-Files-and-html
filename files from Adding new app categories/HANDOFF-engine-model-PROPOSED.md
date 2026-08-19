# Khaata — Session Handoff: Business Category Map & Engine Model

**Status: ⚠️ PROPOSED — NOT LOCKED. Requires Mr. T's explicit approval before any build work.**
**Session type:** Brainstorm / analysis only. No code written. No specs superseded.

---

## What This Session Produced

Two reference files:

| File | Contents |
|---|---|
| `Khaata-Business-Categories.md` | ~200 Indian small businesses, individually listed (not grouped), each mapped to an engine + rated ★/★★/★★★ for opportunity |
| `Khaata-Screen-Matrix.md` | Every screen × 5 engines, with core/optional/off per engine — **contains errors, see correction below** |

---

## ⚠️ Correction — Read Before Trusting the Screen Matrix

The screen matrix was produced **before** this chat had sight of `HANDOFF-paste-in-new-chat.md` and the 43 existing artifacts. Several items marked **GAP** are already built and phone-tested.

**Wrongly marked as GAP — these already exist:**

| Flagged as missing | Actually exists as |
|---|---|
| Business type picker | `onboarding-flow.html` — with ⓘ info popups for all ~14 types |
| Business switcher | Home dashboard + side drawer, with Done/Pending per business |
| Bill generator | `bill-input.html` + `bill-theme.html` — 5 themes, GST grouping, amount-in-words, all tested |
| Send / share (WhatsApp) | `vasooli-list.html` — working preview with type-specific wording + UPI link |
| Staff salary payout | Page #17 Staff payments/advances |
| Staff advance | Same — #17 |
| Reminders | Page #10, WhatsApp click-to-send |
| Document vault | Page #11, Drive/BYOS — fully specced incl. Secure Showcase |
| App settings | Business Settings ⭐ — specced in depth |
| Login / auth | Page #2, Login/OTP |
| Feature toggle | Partially — depth presets (Simple/Standard/Detailed) already do this job |

**Also missed entirely:** Scan-to-confirm engine (page #13).

**Genuine gaps that survive the correction:**

| Gap | Evidence it's real |
|---|---|
| **Recurring bill auto-generate** | Mr. T's own open-items list: *"connecting bills to Fee Plans/Vasooli (auto-generate a bill from a pending due)"* |
| **End-to-end bill flow** | Own open-items list: *"select customer → items → GST → generate → share"* with theme wired in |
| **Payment recording detail** | Handoff §23: *"the Record Payment flow itself must accept any amount... confirm/test when the Money/Payments recording screen is eventually built in detail"* |
| **Reusable app-wide price book** | Fee Plans and per-business rate lists exist; a cross-business reusable item library does not. May be unnecessary — Fee Plans may already cover it. **Open question.** |
| **Aging report** | Reports/summary listed but not detailed. Vasooli = today's call list; aging = the 0–30/31–60/61–90/90+ pattern behind it. Same query, different render. |
| **`EVENT` engine** | Zero of 43 artifacts. No photographer / makeup / banquet / catering spec exists. |

---

## The Actual Finding

**Mr. T already made this decision.** The business-type info popups (handoff §6) assign every type to **Mode 1 (subscription)** or **Mode 2 (job/service)**. A two-engine model already exists and is already load-bearing — it drives the GST default (§2: Mode 2 → GST on, Mode 1 → GST off).

The proposal is therefore **not new architecture**. It is: *should Mode 1 / Mode 2 become five?*

**The existing artifacts already instantiate four engines without naming them:**

| Engine | Already built as | Artifacts |
|---|---|---|
| `SUB` | Fee Plans + billing cycles | `gym-yoga-setup`, `coaching-setup`, `dairy-setup`, `newspaper-setup`, `parking-setup` |
| `APPT` | Per-visit fees + Appointments toggle | `clinic-setup` |
| `SALE` | Retail rate lists, walk-in hourly | `dairy-setup` (retail mode), `parking-setup` (walk-in) |
| `JOB` | Mr. T's own paused framing: *"may later collapse into one generic Job/Service business type"* | none yet — but the framing is his |
| `EVENT` | — | **none** |

Corroborating signal: `bill-theme.html`'s five themes (Subscription / Retail / Classic Professional / Shipment / Tally) were arrived at independently and map closely onto the same split.

**Reading:** the five engines are a *description* of work already done, not a redirection of it. `EVENT` is the only genuinely new build.

---

## Compatibility With Locked Principles

| Locked principle | Conflict? |
|---|---|
| *"Business-type setup is modular, not shared — own module on shared Base Profile"* (§275) | **No.** Engines sit between Base Profile and the type module. Type modules stay modular. |
| Mode 1 / Mode 2 drives GST default (§2) | **No.** `SUB` inherits Mode 1's default; `APPT`/`EVENT`/`JOB`/`SALE` inherit Mode 2's. Nothing breaks. |
| *"Onboarding configures, never populates"* (§274) | **No.** Orthogonal. |
| Permission granularity via page-splitting (§278) | **No.** Orthogonal. |
| Migration 001 schema | **No.** No schema change implied. An engine is a business-type attribute, not a table. |
| Depth presets (Simple/Standard/Detailed) | **No.** Depth = how much detail. Engine = which screens. Independent dimensions — same pattern as Scale vs Property Type in §24. |

**No locked decision is contradicted.** This is additive.

---

## What Mr. T Needs To Decide

**Decision 1 — Does Mode 1 / Mode 2 become five engines?**
- **Yes** → engines get named, business types get tagged, `EVENT` gets specced
- **No** → keep 2 modes, treat the ~200-business map as a pure market-research reference and nothing more
- **Partial** → keep 2 modes for GST logic, use 5 engines only as internal vocabulary for build sequencing

**Decision 2 — Is `EVENT` in scope?**
Photographer, makeup artist, tent house, catering, banquet. Distinct need: advance taken months before the event, balance due on the day, date-blocking to prevent double-booking. Nothing in the 43 artifacts covers this. Rated ★★★ in the category map. Genuinely new build.

**Decision 3 — Does the reusable price book exist, or do Fee Plans already cover it?**
Needs Mr. T's read — he knows what the rate lists actually do.

---

## Explicitly Unchanged By This Session

- Tier structure (Free / Pro / Premium) — untouched
- Migration 001 schema — untouched
- Phase 0 / Phase 1 status — untouched; M2 bug fixes still pending phone retest
- All 43 artifacts — still valid, none superseded
- All open items from the prior handoff — still open, including: Gym/Yoga mockup still showing hardcoded "Trainer: Priya" (needs the Timetable cleanup applied), "By Area" split method, GST-per-property-type defaults, TDS scope decision, lease renewal reminder design, Amenities-by-Scale suggestions
- Khaata naming risk — still deferred, still unresolved (Khatabook remains the concerning match)

---

## If Decision 1 Is "Yes" — Suggested Order

1. Name the engines; tag every existing business type with one
2. Verify the tagging against the 5 existing bill themes — if a type's engine and its natural theme disagree, the tagging is wrong
3. Close the confirmed gaps first (auto-generate from Fee Plans → Vasooli; end-to-end bill flow; payment recording detail) — these are Mr. T's own open items and are engine-independent, so they're safe to build either way
4. Spec `EVENT` last — it's the only true new build

**Note step 3.** Those three gaps are worth building regardless of how Decision 1 goes. If Mr. T wants to sleep on the engine question, that work is not blocked.

---

## For The Next Chat

If this handoff is being pasted into a fresh session: the engine model is **proposed, not approved**. Do not build against it. Do not update `BUILD-ORDER.md`, `CLAUDE.md`, or `Build-Addendum-Schema-and-Foundations.md` on the strength of this document. Ask Mr. T for a decision on the three questions above first.

The two reference files are safe to read as market research regardless of the decision — but treat the screen matrix's GAP column as unreliable and use the correction table in this document instead.
