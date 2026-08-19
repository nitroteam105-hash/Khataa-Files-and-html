# Khaata — Civil / Construction Build · Session Handoff

*Written 2026-07-20. Hand this + `DECISION-capability-model.md` to a fresh chat to continue.*

---

## 1. What this session did
Built the **civil / construction vertical** end-to-end as single-file HTML mockups, plus locked several app-wide patterns. The civil business is now functionally complete for the money + people + progress loop. All files are in `/mnt/user-data/outputs/`.

The governing architecture is in **`DECISION-capability-model.md`** — read that first. This handoff covers what was built *this session* and how the pieces connect.

---

## 2. Screens built (all in outputs/, all single-file vanilla HTML/CSS/JS)

| File | What it is | Key behaviours |
|---|---|---|
| `construction-setup.html` | Business setup, first page built natively on the capability model | Role selector (Civil contractor / Owner-builder / Owner+labour / Hands-off) **presets** capability toggles (quote, budget, material, labour, stages, payout, documents); tabs adapt to off-states |
| `documents-operational.html` | Documents capability, operational stage | Hub (parties + projects, attached/total + expiry flags) → per-record checklist. Status: Missing/Attached/Expiring/Expired. Add-doc captures name+attach+expiry in one sheet. Pills = tap-filters. **Delete tiers** (see §4). Attach mocked. |
| `staff-attendance.html` | Attendance + weekly crew payout | Today / This month / **Payout** tabs. Per-date attendance (source of truth); daily-wage vs salaried-leave modes; crew payout pulls days from attendance, per-worker advance control (Full/Part/Skip), one-pass confirm |
| `site-expenses.html` | Single-project expense screen | Budget bar (Material/Labour/Charges stacked); category-driven entry (material=qty×rate, charges=flat, labour=auto-from-payout OR manual); **learn-a-material** and **learn-a-charge** |
| `money-in.html` | Role-adaptive money intake | **Contractor** = client billing (quote/received/balance, stage schedule + on-account); **Owner** = project funds (funds-in − spent = available, low-balance nudge). **learn-a-source** (owner) and **learn-a-stage** (contractor) |
| `stages-progress.html` | Stages / progress tracker (the tracking hub) | Per-stage **simple OR checklist**; checklist status **auto-derived** from sub-tasks; suggested starter sub-tasks per stage; **dated site diary** + combined photo/doc attachments on sub-tasks (fallback to stage); payment shown read-only; **ready-to-bill** cross-signal |

---

## 3. How the civil screens connect (the data flow)
```
construction-setup (role → capabilities)
        │
        ├── documents-operational   (parties + projects)
        ├── staff-attendance ──payout──┐
        │                              ▼
        ├── site-expenses  ◄── labour auto-pulled from payout
        │        │ (spend total)
        │        ▼
        ├── money-in (owner: funds − spend = available)
        │   money-in (contractor: stage payment schedule)
        │        │ (received per stage)
        │        ▼
        └── stages-progress ◄── payment status reflected (read-only)
                 │ (work complete but unpaid)
                 └──► "ready to bill" nudges back to money-in
```
The loop: **attendance → payout → expense (labour) → budget**, and separately **stage work-status ↔ money-in payment**. Stages is where progress + payment meet.

---

## 4. Patterns locked this session (app-wide, not civil-only)

**"Pick-or-add-and-remember" — now the app-wide standard for list fields.**
Appears on: materials + charges (site-expenses), fund sources (money-in owner), payment stages (money-in contractor). Behaviour: a "+ Other / + New…" option → type a name → on save, if new, **ask "Save 'X' for next time?"** → adds to that list (with unit+rate for materials). Case-insensitive dedupe. **Every future list field should use this.** The material-with-rate version is the seed of the long-flagged **reusable item/price catalogue**.

**Delete tiers (documents):** Replace file = no confirm (fixes wrong-file-right-row); Remove file = single confirm (recoverable); Delete row = double confirm AND only on user-added custom docs (standard checklist slots can't be deleted).

**Record-level delete (worker / project / party):** Archive-first — hide from active lists, keep records; true Delete double-confirmed and **blocked if money/attendance history exists**. Lives on the record's own screen, NOT documents. Not yet built.

**Store events, derive summaries** — reaffirmed everywhere: attendance per-date (totals derived), advances as dated entries (balance derived), site diary as dated log, payments as entries. No stored summary numbers.

**Two-state stages:** work-status (Not started/In progress/Complete) is SEPARATE from payment-status. Work is set here (or derived from sub-tasks); payment is a read-only reflection of money-in. Never conflate "built" with "paid".

**Simple-or-checklist per stage:** owner chooses per stage. Checklist status auto-derives from sub-tasks; simple is a direct selector. Convertible both ways; notes/attachments live on sub-tasks when present, else on the stage.

---

## 5. Integration flags (real-code / SQLite work — mockups only show the shape)
These are the seams a fresh chat must know are NOT actually wired:

1. **Staff model unification.** `staff-attendance.html` demonstrates the per-date attendance + advance-entry model, but `my-staff.html` and `onboard-staff.html` (uploaded, older) still carry their own shapes. All three must share ONE attendance store + ONE advance store in SQLite.
2. **One payments log.** Per-worker payout (`my-staff.html`) and crew payout (`staff-attendance.html`) must both write the SAME Money-Out entries. This is where "Record Payment accepts any amount" lands.
3. **Labour auto-expense.** The "from payout" labour line in `site-expenses.html` is mocked; real sync = payout writing an expense entry.
4. **Owner "spent" figure.** `money-in.html` owner view hardcodes the ₹ spent; real = live join to expenses.
5. **Contractor quote & stage payments.** `money-in.html` quote and per-stage received are seeded; real = from setup/quote capability, and stage payment status feeds `stages-progress.html`.
6. **Learned lists + attachments** are in-memory; persist per business in SQLite. Attach (documents, diary photos) is fully mocked — no real Drive/BYOS call.

---

## 6. Still open / next steps (none blocking)

**► NEXT TASK (agreed): Project dashboard.** The civil capstone — one home screen for a single project that assembles what the other screens already produce. Suggested contents, in priority order:
- **Money health strip** — for contractor: quoted / received / balance; for owner: funds in − spent = available. (Role-adaptive, same split as `money-in.html`.)
- **Progress** — "3 of 6 stages · 47%," current stage name, weighted bar (from `stages-progress.html`).
- **Budget** — spent vs budget with the Material/Labour/Charges split (from `site-expenses.html`).
- **Action nudges** — pull the live cross-signals: "₹2.5L ready to bill" (stage done, unpaid), "2 approvals expiring" (documents), "crew payout due" (attendance). These are the reasons a contractor opens the app.
- Role-adaptive like money-in (contractor vs owner sees different top card). Single-file, same design system. It's assembly, not new logic — every number already exists in a built screen; the dashboard just surfaces them together and links out.

Then, after the dashboard:
- **Project dashboard** — the recommended capstone. One home screen pulling: budget used, received vs spent, current stage, pending dues, expiring approvals. Everything to feed it now exists. NOT yet built.
- **Record-level delete** (worker/project archive-first) — belongs on staff & project screens.
- **Reusable item/price catalogue** — formalise from the learned-materials seed.
- **Other verticals** still specced-not-built: Gym/Yoga, PG/Hostel, Coaching, Clinic (all have HTML mockups + specs). Vasooli (daily follow-up) prototyped, not implemented.
- Real-code phase: everything moves to React Native (Expo) + SQLite; see §5 for the joins that make the mockups real.

---

## 7. Design system (for consistency in new screens)
Green `#1f6f54`, parchment `#fbfbf9`, warm neutrals; Plus Jakarta Sans (headings/weights 600-800) + Inter (body). Single-file, vanilla, no build step. Money-affecting actions get confirm popups; neutral actions don't. Mobile width ~480px max. "Suggestions, not restrictions" — defaults are editable, nothing forced.
