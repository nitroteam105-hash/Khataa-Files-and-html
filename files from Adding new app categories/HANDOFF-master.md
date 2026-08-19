# Khaata — MASTER Handoff (read this first)

*Updated 2026-07-20. This is the top-level index for the whole project. It points to the deeper docs and gives a fresh chat the full picture in one read.*

---

## 0. What Khaata is
A local-first, multi-business management + billing app for small Indian business owners who today use notebooks or Excel. Zero transaction fees, positioned against apps like CoFee/Vyapar/KhataBook. **Android-first, global-ready.** Tiers (locked): **Free** (unlimited businesses, local-only, single device, no ads) · **Pro** (cloud sync, multi-device, backup, bill themes) · **Premium** (multi-user/staff, reports, priority). Stack: **React Native (Expo) + SQLite** (local, all tiers) + **Supabase** (paid sync/auth only).

All work so far is **single-file HTML mockups** (design + logic prototypes) plus **decision/handoff docs**, in `/mnt/user-data/outputs/`. Real code (React Native) is the next phase.

---

## 1. The core architecture — the Capability Model
**One question resolved everything:** business types are NOT separate engines. A business = **one billing mode + a bundle of independent capabilities, preset per business type, all owner-overridable.**

- **Two billing modes** (drive GST behaviour): **Mode 1 Subscription/recurring** · **Mode 2 Job-Service / counter-sale**.
- **Capabilities** (toggle per business, preset by type): agenda calendar, booking+overlap-check, recurring generation, stock, stages, per-unit, staff+attendance, documents, GST, categories, udhaar, variants/add-ons, sold-out, multi-unit… and more as needed.
- A "business type" (civil contractor, hardware shop, tiffin center) is just a **preset bundle** the owner adjusts.

**This is the whole thesis, and it's now validated across three very different businesses** (civil, retail, food) with no engine rewrites. Full record: **`DECISION-capability-model.md`** — the governing doc, read it second.

---

## 2. What's been built — by engine

### A. Civil / Construction (Mode 2 + job capabilities) — see `HANDOFF-civil-build.md`
A complete job/service vertical:
- `construction-setup.html` — role selector presets capabilities
- `documents-operational.html` — party/project docs, attach, expiry, delete-tiers
- `staff-attendance.html` — per-date attendance + weekly crew payout with advances
- `site-expenses.html` — category-driven expenses, budget bar, learn-a-material
- `money-in.html` — contractor client-billing vs owner project-funds (learn-a-source/stage)
- `stages-progress.html` — the tracker: simple-or-checklist stages, auto-derived status, site diary, ready-to-bill signal
- **Recommended next:** project dashboard (capstone, assembles the above).

### B. Retail / Counter billing (Mode 2 + sale capabilities) — see `HANDOFF-sale-engine.md`
A complete billing vertical:
- `shop-onboarding.html` — 3-tier depth (Simple/Standard/Complete), shop-type presets capabilities
- `item-onboarding.html` — add+edit one form; GST inclusive/exclusive, MRP/cost, barcode scan, multi-unit, learn-a-unit/category
- `items-list.html` — searchable catalogue, low-stock view, ± quick stock adjust, tap→edit
- `items-quick-add.html` — bulk row entry (batch defaults + per-row expand)
- `items-import.html` — CSV/Excel import (upload→map→preview→import)
- `shop-dashboard.html` — today's sales, attention strip (low-stock/udhaar), week trend, print/share sheet
- `monthly-statement.html` — shop summary (with GST-for-filing) + customer statement (udhaar, WhatsApp)
- **Bill generator** — built separately by Mr. T, to integrate.

### C. Food stall (Mode 2 + food capabilities) — a business TYPE on the SALE engine, see `HANDOFF-sale-engine.md` §4a
Proved the model travels — food reuses SALE billing/dashboard/statements unchanged:
- `food-item.html` — dish with variants + add-ons (no goods fields)
- `food-quick-add.html` — bulk menu setup
- Sold-out = a menu/billing action, NOT an onboarding field (operational state ≠ definition).

### D. Event/booking businesses (Mode 2 + booking capability) — earlier work, see `HANDOFF-event-calendar-groups.md`
Setup pages + calendar: `photographer-setup`, `makeup-artist-setup`, `catering-setup`, `tent-house-setup`, `bookings-calendar`, `booking-create`, `group-management`.

---

## 3. App-wide patterns locked (apply to every screen, every engine)
- **Pick-or-add-and-remember** — the standard for ANY list field. Pick from the list, or "+ Other" → type → "Save 'X' for next time?" → it's remembered. Used on: materials, charges, fund sources, payment stages, units, categories, shop types. Every new list field should use it.
- **Store events, derive summaries** — never store a summary you can compute. Per-date attendance (totals derived), dated advance entries (balance derived), dated site diary, payments as entries, one stock pool (box/loose derived).
- **Setup configures, never populates** — onboarding defines what a thing *is* (permanent); operational state (sold-out, stock levels, today's status) lives on working screens, set live. (This is why sold-out isn't an onboarding field.)
- **Snapshot at transaction time** — bills store their own copy of price/tax/unit at sale, so editing an item later never corrupts past bills. (Lets "edit anything" be safe.)
- **Archive-first deletes** — records with history (workers, projects, items) archive by default; true delete is double-confirmed and blocked if history exists. Delete-tiers on files: replace (no confirm) / remove (single) / delete-row (double, custom only).
- **Two independent states** — work-status separate from payment-status; never conflate "done" with "paid".
- **Capability-gating** — screens show more/less by capability; one screen serves the simple and the complex shop. No separate "lite" build.
- **Suggestions, not restrictions** — presets/defaults always editable; nothing forced.
- **One form, modes** — add/edit is one component with a mode flag, not two pages (avoids drift). Same for role/type-adaptive screens.

---

## 4. The document map (what to read)
1. **`HANDOFF-master.md`** — this file. The index.
2. **`DECISION-capability-model.md`** — the governing architecture. Every locked decision, with reasoning. §3a–3j cover mode/capabilities, documents, staff, expenses, money-in, stages, pick-or-add.
3. **`HANDOFF-civil-build.md`** — civil vertical, its screens, data flow, integration flags, next = project dashboard.
4. **`HANDOFF-sale-engine.md`** — retail + food, all screens, decisions, bill-generator specs, Phase-2 printer note, three item on-ramps.
5. **`HANDOFF-event-calendar-groups.md`** — event/booking setup + calendar.
6. Reference (market research, pre-decision, use with care): `Khaata-Business-Categories.md`, `Khaata-Screen-Matrix.md`, `HANDOFF-engine-model-PROPOSED.md` (superseded by the capability model).

---

## 5. Known integration seams (real-code work — mockups only show the shape)
- **Bill generator** (Mr. T's) must: snapshot price/tax at sale, scan-to-add with unknown-barcode quick-add, multi-unit at billing, bill-time discount, write back to stock/sales/GST/udhaar.
- **Staff model** — the three staff screens share the per-date/advance model only in concept; unify to one SQLite store in code.
- **One payments log** — per-worker + crew payouts, and all money-in, converge on one Money-Out/entries store.
- **Live joins** — owner "spent" (money-in ← expenses), labour auto-expense (← payout), customer statement (← udhaar ledger) are mocked; real = SQLite joins.
- **Learned lists** (units/categories/materials/sources/shop-types) persist per business in SQLite.
- **File parsing** (import) and **thermal Bluetooth printing** (ESC/POS) are native — Phase-2 hardware/real-code.

---

## 6. Suggested next steps (pick per appetite)
1. **Civil project dashboard** — quick capstone, assembles existing civil screens.
2. **Integrate the bill generator** + build bills-history and customer/udhaar screens (the last retail gaps).
3. **Begin real code** — React Native + SQLite; §5 is the build list; the mockups are the spec.
4. **More verticals** to further stress the model (PG/hostel, gym, clinic — Mode 1 subscription would exercise the parts these three didn't).

---

## 7. Design system (all mockups)
Green `#1f6f54`, parchment `#fbfbf9`, warm neutrals; Plus Jakarta Sans (headings) + Inter (body); single-file vanilla HTML/CSS/JS; ~480px mobile width; money-affecting actions confirm, neutral ones don't; capability demo-toggles in mockups stand in for what real setup provides.

**Bottom line:** the capability model is proven across civil, retail, and food. Two engines fully mocked, one bill generator to integrate, patterns locked, decisions recorded. Ready for the real-code phase whenever you are.
