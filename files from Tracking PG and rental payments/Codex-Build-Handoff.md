# Ledgr — Codex Handoff (code generation ONLY)

## Your role
You write code only — one milestone at a time, when asked. You don't run git commands, create repos, or manage the environment; that's handled separately. Just generate clean, working React Native (Expo) code for the exact piece requested, plus a short explanation of what you built.

## Project
**Ledgr**: a mobile app for small Indian service businesses (sign-board makers, welders). MVP flow: save customers → create quote → convert to invoice → record payment (partial supported) → see who owes money.

## Stack (don't deviate)
- React Native + Expo (Android first)
- **expo-sqlite** for local, offline-first storage — this is the primary data store for now. No Supabase yet.
- No payment gateway. No login yet (comes later via Supabase OTP).
- Keep dependencies minimal — don't add libraries unless necessary for the task.

## Design tokens (use consistently)
Background #fbfbf9 · ink #16161a · accent green #1f6f54 · soft green #e8f3ee · border #e7e7e2 · amber #b36b00. Rounded cards (12px radius), large tap targets, mobile-first. Currency ₹ with Indian digit grouping (₹1,20,500). Dates like "24 Jun 2026".

## How to work with me
- I'll ask for ONE milestone/screen at a time. Only build that piece — don't scaffold unrelated screens ahead of time.
- Keep code simple and readable — I'm a beginner (though comfortable with SQL/data logic). Comment non-obvious parts.
- After generating, briefly explain: what the code does, which files to create/edit, and how to test it.
- If a request is ambiguous, ask a quick clarifying question rather than guessing big.

## Milestone reference (for context — I'll request these one at a time)
1. Basic Expo app, single "Ledgr" screen, green header
2. Customers screen (list + add form: name, phone, Individual/Company + GSTIN if Company) — SQLite persisted
3. New Bill screen (Quotation/Invoice toggle, customer picker, line items with auto amount, subtotal, optional GST%, save with QT-001/INV-001 numbering)
4. Bills list (status chips, convert quote→invoice, record payment with partial/balance)
5. Bill preview + WhatsApp share (wa.me link), footer "Made with Ledgr"
6. Summary screen (totals + who-owes-me list)

Wait for me to specify which milestone to build now.
