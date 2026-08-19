# Khaata — Session Handoff: EVENT Engine, Bookings Calendar & Groups

**Paste into a new chat to continue. Read `HANDOFF-engine-model-PROPOSED.md` first if available — it has the full engine-model context this session builds on.**

**Session type:** MVP page mockups (HTML prototypes). No production code, no schema changes, no BUILD-ORDER edits.
**Status of engine model:** ⚠️ STILL PROPOSED, not locked. Everything below is "shape to react to," not approved architecture.

---

## What This Session Produced

Seven HTML mockups, all in the established design system (green `#1f6f54`, parchment `#fbfbf9`, Plus Jakarta Sans + Inter, single-file, tabbed setup, setup-configures-never-populates, suggestions-not-restrictions).

### EVENT-engine business setup pages (the gap identified last session — 0 of 43 prior artifacts covered EVENT)

| File | What it demonstrates about the engine |
|---|---|
| `photographer-setup.html` | The clean EVENT case. Tabs: Packages / Booking & Advance / Add-ons / Client Intake. Advance %, date-blocking, multi-day events, delivery-timeline tracking (deliverable lags the event). |
| `makeup-artist-setup.html` | Same spine + **time-slot** blocking (bridal morning, not just a date), on-location travel charge, trial session (free / paid / adjust-in-final-bill), buffer between bookings. |
| `catering-setup.html` | Pricing model **flips to per-plate × guest count**. Min guests, final-count lock, minimum-guarantee billing, live min-booking calculator in the package sheet. |
| `tent-house-setup.html` | The outlier: **EVENT + inventory**. Quantity-owned per item, per-day rate, availability-by-date check, returnable security deposit. This is where EVENT and SALE overlap. |

Common EVENT DNA across all four: booking date (not recurring) · advance at booking · balance on event day · date-blocking to prevent double-booking.

### Cross-business operational screens

| File | What it is |
|---|---|
| `bookings-calendar.html` | **The main deliverable.** Cross-business bookings calendar. Month grid (colour-dot per business) + Upcoming list, money strip (count / collected / balance due), tap-day detail with advance/balance/status per booking. Multi-day bookings block their whole range. Scaled to **8 businesses** to prove the selector. |
| `group-management.html` | Create / rename / edit-members / reorder (drag) / delete business groups. Delete confirm explicitly reassures that member businesses are untouched. Save disabled until name + ≥2 members. |
| `booking-create.html` | **The flow that closes the loop.** 4-step wizard (Client / Date / Package / Payment) that pulls packages + advance defaults from the setup pages and produces a booking the calendar would show. Business picker top-right switches config live. Step 3 adapts to all three EVENT pricing models: flat (photo/makeup), per-plate + guest count (catering), per-item × days vs stock (tent). Step 2 runs the live date-conflict check against existing bookings (soft warning, not a block — matches Timetable pattern). Step 4 pre-fills advance at the business's default %, shows balance + returnable deposit, ends on a confirm/success screen. |

---

## The Two Design Decisions Made This Session

### 1. Multi-business calendar scope — one page, three intents (NOT three pages)

Mr. T proposed three separate calendar pages: (1) all businesses, (2) individual business via dropdown, (3) saved group. **Judgment given and accepted: these are three *intents* on one page, not three pages** — the grid, data, and money math are identical; only the filter differs. Three pages = triple maintenance for 95% shared code.

Resolved as **one calendar with a scalable scope selector** (a button that opens a bottom sheet):
- **All businesses** — bird's-eye
- **Tap one business** — isolates to only it (this was Mr. T's friction point: with 7+ businesses, unselecting all-but-one via chips is tedious; the fix is tap-to-focus, not toggle)
- **Tap a saved group** — that bundle
- **Checkboxes + Apply** — ad-hoc multi-select; 2+ checked surfaces "Save as group"

The old chip-row (from the earlier calendar draft) was **replaced** because chips break down past ~4 businesses. Sheet has a search box for scale.

### 2. Groups are a genuinely new concept worth building
No competitor bundles businesses. A wedding-services owner (Photo + Makeup + Mehendi) wants them viewed as one unit. Seeded two demo groups: "Wedding Core" and "Décor & Setup." Group management is its own screen (`group-management.html`).

---

## Demo Data (consistent across calendar + groups)

8 businesses, all EVENT-type, representing one owner's wedding-services empire:
`photo` Aperture Photography · `makeup` Glow Makeup Studio · `mehendi` Henna by Ritu · `catering` Annapurna Catering · `tent` Sharma Tent House · `decor` Bloom Décor · `dj` BeatBox DJ & Sound · `cakes` Sugar Lane Cakes

Bookings seeded across Jul / Aug / Nov 2026. **The Nov 20–23 Reddy wedding is the stress test** — Photo, Makeup, Mehendi, Catering all overlap one weekend. Toggle scope to "Wedding Core" and jump to November to see the group view separate them from the rest.

TODAY is pinned to **2026-07-19** (matches the session date), seeded with a live bridal booking so the calendar opens non-empty.

---

## Known Gaps / Deliberately Incomplete (MVP-level)

These are prototypes to react to, not finished features:

- **Group management uses in-memory state only** — no persistence (matches all prior HTML mockups; real version = SQLite).
- **Calendar's "Save as group"** uses a browser `prompt()` as a stand-in. The proper create flow lives in `group-management.html`. In production these share one component.
- **Drag-reorder** in group management uses native HTML5 drag — works on desktop; touch-drag on real devices may need a JS library (or long-press reorder) when built for real. Flag for phone testing.
- **Booking wizard is display-only on confirm.** `booking-create.html` shows a success screen but does NOT actually write to the calendar's booking data — the two files share no state (all mockups are in-memory). Wiring create → calendar is production work.
- **Booking → Bill Generation not integrated (Mr. T flagged this explicitly).** The wizard produces total / advance / balance, which is exactly the input a bill/receipt needs. Natural next connection: confirming a booking (or collecting the balance) should be able to generate a bill using the existing `bill-input.html` + `bill-theme.html` engine — likely the EVENT/Classic-Professional or a booking-specific theme. Deferred for now, but it's the obvious seam. This mirrors the already-noted gap of "auto-generate bill from Fee Plans → Vasooli" on the SUB side — same pattern, EVENT side.
- **Conflict check is a soft warning, not a hard block** — deliberate, matches the Timetable double-booking pattern. If a hard block is ever wanted (e.g. tent stock genuinely exhausted), that's a per-business rule decision.

---

## Open Questions Carried Forward

1. **Does EVENT stay a separate engine, or does it fold into the 2-mode (Mode 1/Mode 2) model already locked?** Unresolved from prior session. This session assumed EVENT exists, to build the pages — that assumption is NOT a decision.
2. **Do EVENT and SALE merge?** `tent-house-setup.html` is EVENT wearing SALE's inventory costume. Whether they're one engine or two is a real architecture fork — decide before building tent house for real.
3. **Calendar week-start** is Sunday. Mr. T may prefer Monday. Trivial change.
4. **Business colour identity** — colour is currently the only per-business marker on calendar dots. At 8 businesses colours start crowding; may want initials on dots. Raised, not resolved.
5. **Scalable selector pattern** (sheet + search) may want to become the standard multi-business picker app-wide, not just on the calendar — worth considering when the dashboard multi-business views get built.

---

## Unchanged / Still True From Prior Sessions

- Tier structure (Free / Pro / Premium) — untouched
- Migration 001 schema — untouched
- All 43 prior artifacts — still valid, none superseded
- Phase 0 done; Phase 1 M2 bug fixes still pending phone retest
- "Khaata" naming risk — still deferred (Khatabook remains the concerning match)
- All prior open items still open (Gym/Yoga "Trainer: Priya" hardcode needing Timetable cleanup; "By Area" split method; GST-per-property-type; TDS scope decision; lease renewal reminder design; Amenities-by-Scale suggestions)

---

## Suggested Next Steps (Mr. T's call)

Continuing MVP pages (his stated mode), candidates:
- Booking creation / intake flow for EVENT (the advance + date-block + balance entry screen the calendar implies)
- Operational screens for the other engines not yet done
- Or resume the confirmed engine-independent gaps from the prior handoff: auto-generate bill from Fee Plans → Vasooli; end-to-end bill flow; partial-payment recording

**Before any of this becomes real code:** the engine-model decision (Q1) and the EVENT/SALE merge question (Q2) need Mr. T's explicit sign-off. Do not update BUILD-ORDER.md, CLAUDE.md, or the Addendum on the strength of these mockups.

---

## For The Next Chat

All this session's files are in the outputs directory:
`photographer-setup.html`, `makeup-artist-setup.html`, `catering-setup.html`, `tent-house-setup.html`, `bookings-calendar.html`, `group-management.html`, `booking-create.html`.

The engine model is **proposed, not approved**. These mockups demonstrate its shape so Mr. T can decide — they are not a commitment to build it. Keep responses token-lean; ask multiple-choice before generating anything significant; real phone testing is the verification gate.
