# Ledgr — Tech Stack & Learning Roadmap

*For a total beginner, building solo with Codex + Claude, Android-first, lowest-cost.*

---

## 1. The Stack (locked)

| Layer | Choice | Why |
|---|---|---|
| **App framework** | **React Native (Expo)** | One codebase (Android now, iOS later). Most beginner-friendly real-app tool. Best AI support. Matches your HTML/JS prototypes. |
| **Backend + Database + Auth** | **Supabase** | Postgres (real relational DB) + phone-OTP auth + storage + auto APIs. No servers to run. Free tier. |
| **File storage** | Supabase Storage now → **Google Drive (BYOS)** later | Start simple; layer in owner's-Drive idea once it matters. |
| **Payments / UPI** | Owner's own UPI QR / deep links (NO payment gateway) | Keeps you a record-keeper, not money-mover — no licensing. |
| **WhatsApp** | Click-to-send links (free) now → Business API later | Matches the freemium plan. |
| **Your tools** | **Codex** (writes code) + **Claude** (reviews, debugs, teaches) | You = architect & product owner. |

**One line:** React Native (Expo) + Supabase. Cheapest, most AI-friendly, lowest-ops path that fits relational data and mobile-first.

**Cost to start:** ~₹0 infrastructure (Expo free, Supabase free tier) + ~₹2–4k/mo for AI subscriptions. Supabase paid (~₹2k/mo) only once you have real users.

---

## 2. The Honest Truth About Being a Beginner

**Your starting point — better than a blank slate:** You already **understand and write SQL.** That's a real head start:
- **Database/data work is your home turf.** Supabase = Postgres = SQL. Creating tables, relationships, queries — you've got this. Many React developers are *weak* at databases; you're the opposite.
- **You think in data + logic** (tables, relationships, WHERE, AND/OR) — exactly the mental model the app needs (customers→bills→payments).
- **Your real learning curve is JavaScript + React/React Native** (the language + UI layer). Focus your energy here; the database half you're already prepared for.

So you're strong on the **back** (data) and new on the **front** (UI). Good position — the data layer is where most beginners flounder, and you're solid there.

**The rest still applies:**
- **Your first 2–4 weeks are LEARNING JavaScript + React** (not the database, not Ledgr yet). Normal.
- **Biggest trap:** Codex will generate big, complex code you don't understand. When it breaks, you're stuck. **Discipline: build small pieces you understand. Ask Codex to explain, not just generate.**
- **Scope discipline:** the "build broad" habit hurts 10× more in real code. Build ONE wedge, ship it, expand.

---

## 3. Learning Roadmap (week by week)

### Phase 0 — Setup (a few days)
- [ ] Install **Node.js**, **VS Code**, **Expo Go** app on your phone
- [ ] Create free accounts: **Supabase**, **Expo**, **GitHub**
- [ ] Get Codex + Claude access set up
- [ ] Run the Expo "hello world" — see it live on your phone via QR code
- *Goal: tools working, app runs on your phone.*

### Phase 1 — React Native basics (Week 1–2)
- [ ] Learn: components, props, **state (useState)**, handling input, lists
- [ ] Build a tiny **throwaway to-do app** (add item, show list, delete) — no database, just on-screen
- [ ] Learn navigation (moving between screens)
- *Goal: you understand how a screen works and data shows/updates. Don't touch Ledgr yet.*

### Phase 2 — Supabase basics (Week 2–3) — *FASTER for you (SQL head start)*
- [ ] Tables / CRUD — **you know this** (it's SQL/Postgres). Just learn how Supabase exposes it.
- [ ] Connect your to-do app to Supabase — items now **save and reload** (NEW part: the JS client)
- [ ] Learn **phone-OTP auth** — a login screen that works (NEW: the auth flow)
- *Goal: you understand how the React side talks to your database. The DB itself you already get — focus on the JS connection + auth.*

### Phase 3 — First real Ledgr screen (Week 4)
- [ ] Build **ONE** real screen: "Add a customer" → saves to Supabase → shows in a list
- [ ] This single screen teaches the whole loop: form → save → load → display
- *Goal: one real, working piece of YOUR app. A huge confidence milestone.*

### Phase 4 — Thin MVP: the wedge (Week 5–9)
Build ONLY the job/service wedge, end to end:
- [ ] Add/save **customers** (individual + company w/ GSTIN)
- [ ] Create a **quote** → save it
- [ ] Convert quote → **invoice**
- [ ] **Record a payment** against it
- [ ] See a simple list of what's paid / pending
- *Goal: one complete vertical slice a real owner can actually use.*

### Phase 5 — Real user test (Week 9+)
- [ ] Put it in a **sign-board / welder** owner's hands
- [ ] Watch them use it. Note what confuses them, what's missing
- [ ] Fix → repeat. **Build from feedback + revenue, not more features.**

---

## 4. How to Work with Codex + Claude (the method)

1. **Plan first (with Claude):** before coding a feature, describe it; agree the approach & data shape.
2. **Codex builds** a small piece.
3. **Claude reviews:** paste the code → "explain this, find bugs, is this the simplest way?"
4. **You understand it** before moving on. If you can't explain what a piece does, stop and ask.
5. **Test on your phone** immediately. Small change → test → next.
6. **Commit to GitHub often** (save points you can roll back to).

**Golden rules:**
- Build small pieces you understand, not big pieces you don't.
- One feature at a time, tested, before the next.
- When stuck >30 min, paste the full error to Claude — don't grind alone.
- Resist adding new tools/libraries until you genuinely need them.

---

## 5. What NOT to Do (beginner traps)

- ❌ Don't try to build all 8 business flows + both modes at once. **One wedge.**
- ❌ Don't let Codex generate a giant app you can't read.
- ❌ Don't gold-plate the stack (no extra libraries early).
- ❌ Don't build the Google-Drive/BYOS part first — Supabase storage is fine to start.
- ❌ Don't build full GST compliance (e-way, HSN) before a paying customer needs it.
- ❌ Don't skip Phases 1–2 to rush into Ledgr — you'll get stuck and quit.

---

## 6. Milestone Checklist (big picture)

- [ ] **M1:** App runs on my phone (Phase 0)
- [ ] **M2:** I understand state + can build a screen (Phase 1)
- [ ] **M3:** Data saves & loads from Supabase; login works (Phase 2)
- [ ] **M4:** First real Ledgr screen works (Phase 3)
- [ ] **M5:** Thin MVP wedge complete — quote→invoice→payment (Phase 4)
- [ ] **M6:** A real owner has used it (Phase 5)

*When you hit M6, you're no longer "designing an app" — you have a real product with a real user. That's the goal.*

---

## 7. Reminders from the Strategy (don't lose these)

- **Wedge = job/service billing** (sign-board, welder — they're asking to see it).
- **Record-keeper, not money-mover** (UPI = owner's own, no PG).
- **Configure once, consume everywhere** (Business Settings — but MVP can hardcode first).
- **Simple bill first; layer GST detail only as B2B demand proves out.**
- **Get reviews before/while building.** Real signal > more features.

*Full detail in PG-App-Brainstorm.md and app-structure-status.html.*
