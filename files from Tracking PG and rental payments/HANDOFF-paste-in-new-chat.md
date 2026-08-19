# Ledgr — Handoff (paste into a new chat to continue)

I'm building **Ledgr** (placeholder name) — a simple "digital diary" app for small Indian business owners to track people, money in/out, bills, quotes/invoices, staff, and documents. I'm continuing from an earlier chat that got too long/token-heavy. Full detail is saved in my project files (see list below); the key context is here.

## Me
- Non-native English speaker, India, mobile-first, cost-conscious.
- **Total beginner at coding BUT I know/write SQL.**
- I prefer to **discuss & decide before you build**, and I like being asked quick multiple-choice questions.
- Build style: single-file vanilla HTML/CSS/JS prototypes, green accent #1f6f54, syntax-checked + tested before delivery. **Keep responses and builds token-lean.**

## The product (core thesis)
Simple diary for any small business. **Record-keeper, NOT money-mover** (never holds money → cheap, no licensing; UPI = owner's own). Two modes:
- **Mode 1 — Recurring/subscription** (PG, hostel, gym, coaching, tiffin, parking) — 8 add-person flows BUILT.
- **Mode 2 — Job/service** [SHARPEST WEDGE] (welding, sign-board, carpentry): client → quote → invoice → payment. Quote/invoice tool BUILT.

## Key decisions locked
- **Stack:** React Native (Expo) + Supabase. Cheap, AI-friendly, fits my SQL background.
- **Data architecture:** local-first (SQLite on phone) = free tier; **cloud sync/backup/multi-device = paid tier** (₹199–699). Free users cost ~₹0. Google Drive (BYOS) = document files only.
- **Build plan:** solo "build-and-test" with **Codex builds + Claude reviews**. Thin MVP (job/service wedge) ~2–3 months.
- **Payments:** stay record-keeper, no gateway. Explore UPI-notification-capture later. Gateway = future premium only.
- **GST bill (noted, not fully built):** item-level GST (toggle like discount, per-item rates + rate-wise summary); IGST = automatic by buyer state; e-way bill = RECORD details only (not generate). Build simple bill first; layer GST detail as B2B demand proves out.
- **Staff:** onboarding has 3 depth presets (Simple/Standard/Detailed), multi-ID, worker types. My Staff = rich tabbed profile (payments/advance/UPI/docs/attendance). Attendance = 3 modes per worker (Off / Daily / Leave-only), auto-defaulted by pay type; paid/unpaid leave; confirm popups only on money-affecting actions (Absent, Unpaid leave).
- **Competitor:** CoFee (cofee.life) — fee-collection app, ₹1,199/mo + transaction fees. My edge: 6× cheaper, zero transaction fees, plus Mode 2 (job/service) which they don't touch. GTM: target the unserved (notebook/Excel owners) first; approach CoFee's price-sensitive users post-MVP.

## Built so far (~55%) — files in project outputs
Screens: landing-page, business-type-selector, home-dashboard, money-in-out, ledger-mvp, bill-generator, scan-to-confirm, people-section, setup-flow-mvp, building-configurator, interview-recorder, owner-survey. Add-person flows: PG, hostel(working+student), co-living, flat, gym, coaching, tiffin, parking. Mode 2: job-quote-invoice. Staff: onboard-staff, my-staff, staff-attendance. Reports: app-structure-status, cost-model. Docs: PG-App-Brainstorm (master), Tech-Stack-and-Roadmap, Learning-Companion-Prompt, + earlier strategy maps.

## Biggest pending items
1. ⭐ **Business Settings** (control center — plans/prices, rooms/beds labels, batches, required docs, tax/GSTIN, bank, T&C, parking mode, staff-field presets). Highest-value gap.
2. **Customer/client list** (saved B2C+B2B, reused in billing).
3. **Quote pipeline** (list, status, follow-up, convert-to-invoice, win-rate).
4. **Owner sign-up** (phone+OTP), **receipt/confirmation** screen.
5. Item-level GST on bill; per-business daily screen; reports; GST summary.

## Real-world next step
Get 10–15 owner reviews (survey ready) from warm leads (sign-board, welder) → then build thin MVP wedge with Codex+Claude.

**To continue:** tell me which pending item to work on, or ask me to review/refine an existing file. Keep it token-lean. Ask me quick multiple-choice questions before building.
