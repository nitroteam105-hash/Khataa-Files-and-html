# Ledgr — Build Handoff (Claude Code — git, repo, environment, orchestration)

## Tool split (important)
**Codex writes code only** (a separate handoff goes to Codex for that). **You (Claude Code) handle everything else:** git init/commits/pushes, GitHub repo setup, running the Expo dev server, installing dependencies, running the app, reading error output, and telling me what to paste into Codex next if something needs fixing. Don't generate large feature code yourself — if a milestone needs new code, tell me what to ask Codex for; you wire it in, run it, and commit it.

## Who I am
Solo founder, beginner at coding but fluent in SQL. Explain things simply, build in SMALL steps, and make sure I understand each piece before moving on. Ask me before big decisions.

## What we're building
**Ledgr** (working title): a mobile app ("digital diary") for small Indian service businesses — starting with the job/service wedge: sign-board makers, welders, carpenters.
Core MVP flow: **save customers → create quote → convert to invoice → record payment (incl. partial) → see who owes me.**
Principles: record-keeper NOT money-mover (no payment gateway; owner collects via their own UPI). Simple bills first; GST detail later. Indian formats: ₹ with Indian grouping (₹1,20,500), dates like 24 Jun 2026.

## Stack (locked — don't change)
- **React Native + Expo** (Android first, test via Expo Go on my phone)
- **Local-first: SQLite on device** is the primary store (expo-sqlite). App must work fully offline.
- **Supabase later** for auth (phone OTP) + cloud backup/sync (paid tier). NOT needed in early milestones.
- GitHub repo: create private repo `khaata-app`. Commit after every working step.

## Design
Clean, minimal, mobile-first. Background #fbfbf9, ink #16161a, accent green #1f6f54, soft green #e8f3ee, borders #e7e7e2. Rounded cards (12px), big tap targets.

## Build order (one milestone at a time — stop and let me test each on my phone)
1. **M1:** Fresh Expo app, one screen "Ledgr" with green header. Give me exact commands to run it in Expo Go.
2. **M2:** Customers screen — list + add form (name, phone, type Individual/Company; Company shows GSTIN). Saved in SQLite, survives app restart.
3. **M3:** New Bill screen — Quotation/Invoice toggle, pick customer, line items (desc, qty, rate, auto amount), subtotal, optional GST % toggle, save with number series QT-001/INV-001.
4. **M4:** Bills list — status chips (Quote/Unpaid/Paid), open a bill, convert quote→invoice, record payment (partial supported, balance shown).
5. **M5:** Bill preview + share — clean bill layout, WhatsApp share via wa.me text. Footer: "Made with Ledgr".
6. **M6:** Summary screen — total invoiced / received / pending + "who owes me" list.
(Later, not now: Supabase OTP auth, cloud sync, GST detail, other business types.)

## Working rules
- Small pieces I can understand; after each piece explain briefly what you built and why.
- I test on my phone before we continue. If errors, I'll paste them.
- Never add libraries beyond what's needed. No over-engineering.
- Commit to GitHub at each milestone with a clear message.
- **When a milestone needs new code, don't write it yourself — give me a short, clear spec I can hand to Codex, then help me wire in and run whatever Codex produces.**

Start with M1 now: check my environment (node, git), create the repo, and tell me the exact spec to give Codex for the first Expo screen.
