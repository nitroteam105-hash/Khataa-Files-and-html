# PG / Rent Management App — Brainstorm Notes

A consolidated record of everything brainstormed: market context, existing solutions, pricing, the adoption problem, market-gap analysis, and a full problem→solution map across owner-side, tenant-side, and two-sided opportunities.

---

## 1. Context — How PG / Rent Owners Track Payments Today

**Traditional methods**
- Cash collected in person, noted in a physical register/ledger
- Bank transfer records (checking statements for NEFT/IMPS)
- UPI screenshots shared by tenants on WhatsApp as proof

**Modern / app-based methods**
- Automated payment tracking with reminders, receipts, and a single dashboard
- Online payment options (UPI, cards, net banking) with ledgers for rent, deposits, expenses
- SMS/WhatsApp reminders (plus the ability to record cash/cheque payments)
- Reports: transaction summaries, profit/loss, due lists, exportable for accounting

---

## 2. Existing Apps in the Market

| App | Focus / Notes |
|---|---|
| **RentOk** | Automated reports, bulk reminders, online rent collection, real-time website, WhatsApp receipts |
| **TrackMyPG** | Built for 1–5 properties / 10–100 tenants; room & bed-wise pricing, electricity unit calc, auto-invoicing, tenant self-service portal |
| **PG Manager** | Online rent payment, digital receipts, room/tenant management |
| **PG Zone** | Payment tracking, auto SMS reminders, digital receipts |
| **Crib** | PG management tool (compared alongside the above) |
| **QuickStay** | PG management tool (compared alongside the above) |
| **SpaceBasic** | Enterprise-grade, larger hostel/PG chains |
| **NoBroker** | Broader rental platform — connects tenants & landlords directly, agreements, background checks (not PG-specific) |

---

## 3. Pricing of Solutions

| App | Starting Price | Mid Plan | Top Plan | Free Trial |
|---|---|---|---|---|
| **PG Manager** | ₹300/mo (+GST) | — | — | 3 months free |
| **TrackMyPG** | ₹299/mo (1 PG) | ₹599/mo (3 PGs) | ₹999/mo (unlimited) | 7 days (₹1) |
| **RentOk** | Not publicly listed | — | — | Available |
| **PG Zone** | Not publicly listed | — | — | Available |
| **SpaceBasic** | Custom / enterprise | — | — | Available |

**Average price range:** ₹300–₹600/month for small-to-mid PGs (1–3 properties). Pricing models vary — fixed monthly fee, per-bed pricing, or tiered plans.

---

## 4. Utility Bill Fetch & Payment (BBPS) — If Integrated as a Feature

**How bill-fetch works:** Apps like Google Pay / PhonePe don't store or calculate the bill — they fetch it live from the biller (BESCOM, water board, gas company) through **BBPS (Bharat BillPay System)**, run by NPCI. The flow: select biller → enter consumer/RR number → app sends a "bill fetch" request → routes through BBPS to the biller's database → biller returns live amount + due date → app displays it. The amount is identical across all apps because they all pull from the same source.

**Cost to integrate BBPS:**
- One-time setup: ₹5,000–₹25,000 (basic API); ₹15,000–₹75,000 (white-label portal); ₹75,000–₹1,50,000+ (enterprise)
- Ongoing: agent registration ₹499–₹799/year; maintenance ₹5,000–₹30,000/year
- Per-transaction: ~₹2–₹5 per payment

**Key caveats:**
- "Bill fetch" is **not sold standalone** — it's bundled with the full fetch+pay BBPS package.
- A revised fee structure (effective Sept 2025) adds charges if your fetch-to-payment ratio exceeds 5:1 (discourages fetch-only usage).
- Cheapest route: use a BBPS **aggregator** (Setu, Decentro, Cashfree) — fetch API sits in their ₹5K–15K basic tier, skipping most licensing complexity.

---

## 5. Why Adoption Is Low (The Core Problem)

1. **Trust & habit inertia** — owners have run on Excel + WhatsApp for years; don't see it as urgent.
2. **Tenants resist new apps** — they'd rather send a UPI screenshot than download an app.
3. **Perceived cost vs. small scale** — ₹300–500/mo feels unnecessary when "free" (messy) tools still work.
4. **Fragmented, low-awareness market** — no dominant brand; discovery is word-of-mouth or chance search.
5. **Switching cost** — migrating records feels like upfront work.
6. **Distrust of money flow** — wary of routing rent through a third party, especially cash-heavy operators.

> The irony: the owners drowning in WhatsApp threads and stale spreadsheets are the ones who'd benefit most — but it doesn't feel like a "systems problem" until the chaos piles up.

---

## 6. Market Gap Analysis

**Is "lack of awareness" the real gap?** Only partially. Existing players have marketed for years; if awareness alone were the blocker, they'd have solved it. The deeper gaps are **activation and trust**, not just discovery.

**Where the real gaps are:**
1. **Tenant-side friction** — owners won't adopt if tenants won't pay through it. Must work UPI-first, no separate tenant app required.
2. **Too generic for Indian PG billing** — bed-wise pricing, electricity-unit splitting, pro-rata rent. Western-style rental tools don't fit.
3. **Trust around money flow** — solvable by starting with *tracking-only* (no payment routing) to build trust first.
4. **High-touch onboarding for low-LTV customers** — a 10-bed PG at ₹300–500/mo has small lifetime value; manual outreach is expensive relative to revenue — which is *why* big players don't dominate door-to-door.

**On the manual-outreach hypothesis:** Local, in-person, trust-building outreach is a strong **entry wedge** (better than ads/SEO for this market — owners are clustered, trust sells face-to-face, word-of-mouth spreads in owner communities). But it **won't scale alone** — it works for the first 50–100 customers per city, then must convert into referrals + tenant-side virality. Economics only work if CAC stays low relative to monthly revenue.

**Bottom line:** The gap is less "nobody knows this exists" and more "switching feels risky and nobody's made it frictionless enough, especially on the tenant-payment side."

---

## 7. Problems & Solutions — Full Map

### A. Owner-Side Problems

| # | Problem | Solution |
|---|---|---|
| 1 | Manual rent collection & follow-up chaos | Auto-invoices + automated reminders + live paid/outstanding dashboard |
| 2 | Cash payments not recorded digitally | "Record cash payment" feature — log manually, optional photo proof, auto-receipt, same ledger as digital |
| 3 | No unified ledger (cash + UPI + bank separate) | Single ledger; auto-sync digital, manual-log cash; one-place reconciliation |
| 4 | Electricity/utility bill splitting | Built-in unit-rate calculator; auto-split across active beds |
| 5 | Security deposit tracking forgotten | Deposit ledger per tenant; auto-flag refunds on checkout with deductions |
| 6 | Inconsistent receipts | Auto digital receipt (PDF/WhatsApp) on every payment |
| 7 | Distrust of routing money via 3rd party | "Tracking-only" mode — app never touches money; upsell collection later |
| 8 | Multi-property owners lose visibility | Property selector + consolidated revenue dashboard |
| 9 | Vacancy / empty beds = silent revenue loss | Occupancy dashboard + alert when tenant gives notice → refill early |
| 10 | Lead & tenant acquisition (broker dependence) | Built-in vacancy listing auto-published to a public page + inquiry tracking |
| 11 | KYC & police verification (legal risk) | Digital KYC at onboarding + police-verification status tracker |
| 12 | ⭐ Caretaker / absentee-owner cash leakage | Mutual-confirmation cash logging (see Two-Sided A) |
| 13 | No real profitability view | Expense tracking + per-property (and per-bed) P&L |
| 14 | Food / mess management | Meal headcount + grocery/expense module |
| 15 | Maintenance & complaints get lost | Ticketing system with status tracking |
| 16 | Defaulters & bad debt | Defaulter flagging + payment history per tenant |
| 17 | Broadcast communication | One-tap broadcast to all tenants of a property |

### B. Tenant-Side Problems

| # | Problem | Solution |
|---|---|---|
| 1 | ⭐ Deposit refund disputes (#1 grievance) | Transparent deposit ledger, itemized deductions, photo proof at move-in/out |
| 2 | Hidden / surprise charges | Transparent itemized invoice tenants can read |
| 3 | No proof of payment | Auto-receipt on every payment (cash or digital) |
| 4 | Complaints ignored | Ticketing from tenant's view — track status |
| 5 | No record of agreed terms | Digital agreement stored in-app, visible to both |
| 6 | Payment inflexibility & unclear late fees | Clear dues view + reminders *before* due date |

### C. Two-Sided Wedges ⭐⭐ (one feature solves both ends)

- **A. Mutual-confirmation cash logging** — owner/caretaker logs cash → tenant gets notification → **tenant confirms "paid ₹X cash."** One entry solves: caretaker leakage (owner #12) + proof-of-payment (tenant #3) + future disputes. **Few apps do this well — strong differentiator.**
- **B. Transparent deposit handling** — solves owner tracking + tenant's #1 grievance together; builds trust so tenants *prefer* PGs using the app → owners adopt to attract tenants (growth loop).
- **C. Shared ledger as neutral truth** — most disputes are documentation failures; a record both sides see removes conflict and drives referrals.

### D. Verification & Trust

| Problem | Solution |
|---|---|
| Fake / unverified tenant identity | Aadhaar/PAN-based check at onboarding before bed allotment |
| ⭐ No background / defaulter history | Cross-PG defaulter/reputation flag (anonymized) — network-effect feature |
| Police verification skipped (legal liability) | Digital form pre-fill + submission + status tracker |
| Employment / student status unverified | Optional employer/college verification field |
| ⭐ Tenant can't verify the *owner* (scam PGs) | Verified-owner / verified-property badge — builds tenant trust |
| Staff/caretaker unverified | Staff KYC + role-based access logging |

### E. Documents & Compliance

| Problem | Solution |
|---|---|
| Documents scattered & insecure | Encrypted per-tenant document vault |
| ⭐ Aadhaar storage is itself a legal risk | Masked Aadhaar / verify-without-storing (token only) |
| Weak/missing rental agreements | Auto-generated legal agreement with e-stamp / e-sign |
| Document & agreement expiry slips by | Expiry alerts + one-tap renewal |
| ⭐ No move-in/out condition record | Timestamped photo capture at check-in/out, visible to both |

### F. Safety & Security

| Problem | Solution |
|---|---|
| Visitor / overnight-guest management | Visitor entry log + guest-policy enforcement |
| No emergency contact on file | Mandatory emergency-contact + family details at onboarding |
| Fire-safety / building compliance ignored | Compliance checklist + document tracker (NOC, extinguisher dates) |
| ⭐ Female-PG safety | Curfew/gate-time logging + verified-entry; market to women's PGs & parents |

### G. Tenant Lifecycle & Edge Cases

| Problem | Solution |
|---|---|
| No-show after booking | Token-booking with forfeit terms + auto-release of bed |
| Notice-period not enforced | In-app notice submission → triggers re-listing |
| Pro-rata / partial-month chaos | Auto pro-rata calculation in invoicing |
| Bed swaps / sharing changes mid-month | Mid-cycle allocation changes with auto-adjusted billing |
| Secret subletting | Occupancy verification flags mismatches |
| Tenant travels / long absence | "On leave" status — adjust mess charges, hold rent |

### H. Operations, Staff & Food

| Problem | Solution |
|---|---|
| Mess headcount & wastage | Daily meal opt-in/out headcount + grocery/vendor expense tracking |
| ⭐ FSSAI licensing for food | Compliance reminder + license tracker *(verify current state rules)* |
| Staff attendance & salary | Staff attendance + payroll module |
| Asset/furniture inventory per room | Per-room asset register tied to deposit deductions |
| Utility logistics (tanker, gas, WiFi) | Recurring-task / vendor scheduler |

### I. Financial (Deeper than Rent)

| Problem | Solution |
|---|---|
| Owner's tax & income declaration | Auto annual income summary, export-ready |
| ⭐ GST / TDS confusion | GST-aware invoicing + TDS tracking *(verify current GST treatment of PG accommodation)* |
| Multi-component rent lumped opaquely | Itemized invoice (base + maintenance + electricity + food + WiFi) |
| Partial payments & balance tracking | Partial-payment ledger auto-carrying balance forward |

### J. Reputation & Growth

| Problem | Solution |
|---|---|
| Online reviews unmanaged | Post-stay feedback capture + review prompts for happy tenants |
| ⭐ Referrals left on the table | In-app referral with rent credit — tenants as growth engine |
| No competitive/pricing intelligence | Anonymized local benchmark on occupancy/pricing (network-effect) |

---

## 8. Strategic Takeaways

- The richest opportunities cluster around **trust and proof**: verification, condition photos, mutual-confirmation cash, itemized bills, defaulter history, verified owners.
- Almost all of these are **two-sided**, and several get **better as more PGs join** (defaulter network, owner-verification, pricing benchmarks) — a moat existing owner-first apps lack.
- Existing apps treat the **tenant as a payer**, not a user. But the tenant is the one who creates **trust and virality**. Building tenant-first trust features turns tenants into a distribution channel.
- **Sharpest entry wedge:** *mutual-confirmation cash logging + transparent deposit handling* — simultaneously solves the absentee-owner's biggest fear (leakage), the tenant's biggest fear (deposit/proof), and seeds referrals.

---

## 9. Items to Verify Before Building
- Current **GST treatment** of PG/hostel accommodation (rules have shifted recently)
- **FSSAI** registration thresholds for serving meals (varies by state/scale)
- Latest **BBPS** fee structure and the fetch-to-payment ratio rule (Sept 2025 revision)
- Current published pricing for RentOk, PG Zone, SpaceBasic (not public at time of notes)

---

## 11. Roles, Permissions & the Scan Engine (added later)

### Roles & Permissions (multi-user access)
A real owner rarely runs the business alone — needs delegated, scoped access.

| Role | Who | Can do |
|---|---|---|
| Owner | Business owner | Full control — billing, add/remove staff & admins, all financials, delete data |
| Admin / Manager | Trusted manager | Most operations (add people, mark payments, manage attendance) — restricted from full financials / deletion |
| Staff / Caretaker | Caretaker, warden, receptionist | Limited — mark attendance, log cash collected, raise complaints; can't change rent or see total revenue |
| Worker | Cook, maid, guard, trainer | Self only — scan/view own attendance and pay |
| Member / Tenant | The customer | *(self-service portal — deferred, see below)* |

**Why it matters:**
- Delegation — owner can travel/step back while operations continue
- Cash accountability — caretaker logs collections but can't quietly edit rent (directly addresses the cash-leakage problem identified early in this doc)
- Trust boundaries — staff/receptionist shouldn't see total profit; workers shouldn't see each other's pay
- Audit trail — every action stamped with who did it and when

**Core structure:**
```
Owner account (1)
  ├── invites Admin/Manager (1–2) → runs daily operations
  ├── invites Staff/Caretaker (few) → limited daily tasks
  ├── Workers (cook, maid...) → self-attendance only
  └── Members/Tenants → self-service (deferred — see Section 12)
```

### Manual fallback for scans (offline / app-down resilience)
Scan is the convenience; manual entry is the right that must always exist.
- **Offline** → scans save locally on-device, sync when back online (nothing lost)
- **App/server down** → owner or admin marks attendance/payment manually after the fact
- **Forgot QR** → owner taps "mark present manually" for that person/day
- **Trust safeguard:** every entry is tagged **scanned** vs **manual (by [name])** — keeps a neutral, disputable-proof record either way
- **Abuse guard:** manual back-entry limited to a short window (e.g. last 7 days) and restricted to owner/admin roles, so it stays a fallback, not a way to rewrite history

### Scan engine — two directions (recap)
- **Receiving a service** (member/tenant/subscriber) → scan deducts from a balance (meals, sessions, class packs)
- **Providing a service** (staff/worker) → scan adds to a day/session count → auto-calculates salary (days × rate)
- Same underlying engine powers both; applies across nearly every business type in the catalog (PG cook, gym trainer, tiffin delivery boy, society guard, etc.)

---

## 12. Product North-Star Definition (refined)

> **A simple digital diary for small businesses — track people, record cash & UPI payments, generate bills, and keep key documents safe. Works for PGs, rentals, gyms, classes, tiffin, or any service. Records money, never holds it — so it stays cheap, simple, and trustworthy.**

**Core principle:** be a **record-keeper (ledger), not a money-mover (fintech).**
- Record-keeping only → cheap infra, no RBI/PA-PG licensing, low liability, no "why is my money going through your app" trust barrier.
- If money ever flows *through* the app → becomes a regulated fintech (licensing, escrow, settlement, fraud) — avoid in MVP.
- UPI: show the owner's *own* QR / link so payer pays owner **directly**; app only logs that it happened.

**Two cautions on the "one-stop for everyone" framing:**
1. Stay horizontal in *architecture*, but go to market with a *specific face* first ("rent & PG diary", "fee diary for classes") — nobody searches for "business diary." Broaden messaging only after winning one door.
2. Documents add cost + privacy liability — keep lean (see Section 13).

---

## 13. Sensitive Data & Storage Approach (BYOS)

**Bring-Your-Own-Storage, WhatsApp-style:** sensitive files back up to the **owner's own Google Drive / account**, not our database (same model WhatsApp uses for chat backups). We hold only lightweight structured data + a reference link.
- Storage cost → near zero (lives in owner's free Google quota)
- Breach liability drops sharply (we don't hold the sensitive files)
- Trust pitch owners instantly understand: "your data stays in your own Google Drive, like WhatsApp"

**ID-handling rule:**

| Data | Store in our DB? | Notice to user? |
|---|---|---|
| Aadhaar image | Never | Yes — "not saved with us, only in your Drive / not stored at all" |
| Aadhaar number | No — verify only, keep masked last-4 + ✓ flag | Yes |
| PAN / licence number + name + verified flag | Yes (useful, lower-risk) | Optional |
| PAN / licence *image* | Prefer owner's Drive (cheaper, safer) | Good practice |
| Payment records, names, dues | Yes — this is the core ledger | No |

**Principle:** store the minimum that makes the app work; push document *images* to the owner's Drive regardless of ID type; Aadhaar gets one extra layer (verify-don't-store + visible notice).
*Caveat:* even with BYOS, DPDP Act obligations may still apply — confirm with someone who knows Indian data law before launch. Not legal advice.

---

## 14. Expense Tracking & Reports (phase-2 feature)

The natural other half of the income ledger → turns the diary into a real small-business P&L (income from ledger + expenses from this = mini P&L). Differentiator vs standalone statement converters, and the income half already exists.

**Easy path to generate expense reports (easiest → hardest):**
1. Prefer **CSV/Excel upload** (structured, far easier than PDF) over PDF parsing
2. **Keyword/rules categorization** (~75% auto) before any AI
3. **Owner one-tap corrections** → app learns/remembers → less work each month
4. **Report generation is the cheap, high-value part** (group + sum → polished PDF: income vs expense, by category, trend, net P&L)
5. PDF parsing only later, top 4–5 banks only
6. Account Aggregator framework = cleanest input (no upload), but regulated → phase 3

**AI-for-parsing shortcut:** send the statement text to an AI API → returns categorized structured data (handles every bank format without custom parsers). Build the *report* yourself (cheap); rent AI only for the hard *parsing/categorizing* step.
- Cost control: CSV-first (cheaper than PDF/images), cap size, paid-tier feature, cache corrections as rules to shrink AI use over time
- Privacy: use a no-training API tier, get consent, mask account numbers — sensitive financial data leaving our control

**Quick-add expense capture (make logging effortless so data is complete):**
- **UPI notification auto-capture** — read payment SMS/notification (with permission) → pre-fill "₹250, Swiggy, Food?" → user confirms in 1 tap (Walnut/CRED early-traction trick)
- **Cash** still needs manual quick-add (no notification exists)

**Platform-specific quick access ("hovering button"):**
- **Android** → true **floating bubble/overlay** over any app (native strength) → tap → quick add. Needs overlay permission + clear reason.
- **iOS** → Apple restricts free-floating bubbles; equivalents: **Back Tap**, **Action Button** (15 Pro+), **Lock Screen widget**, **Control Center**, **Shortcuts**, **Siri**
- Both → home-screen widget + UPI auto-capture
- *Implication:* quick-access logging requires a **native app**, not web; handle SMS/overlay permissions transparently (Play Store has SMS-access rules)

**Quick attendance widget (mirrors the expense widget — same quick-access mechanisms):**
Mark staff present in 1–2 taps without opening the full app. Feeds directly into staff payroll (each tap/scan counts up → auto-calculates salary).
- **Tap-to-mark** (simplest) → widget shows today's staff, tap name → present + timestamp. Best when owner is present (home maid/cook).
- **Scan-from-widget** → widget "Scan" button → worker shows QR → dispute-proof, just launched faster.
- **Worker self-scans a fixed QR** (door/gate sticker) → no owner action needed; attendance just appears. Best when owner isn't always present (society, shop).
- Smart default: owner-present → tap; owner-away → worker self-scans door QR. Every entry tagged **scanned vs manual**, timestamped.
- Guards: self-scan needs location/time check (can't scan from home); manual tap-to-mark always available as fallback (app down / forgot QR).
- This is the **providing-a-service** direction of the scan engine → plugs straight into the staff wage calc already designed (tap present → day counted → salary updates).

---

## 15. Competitive Reality (cross-vertical, not just PG)

Every vertical already has mature incumbents — breadth alone is **not** a moat:
- PG/Hostel → RentOk (KYC, attendance, tenant app, agreements)
- Gym → Akton (~1,000–2,000 gyms, 50k members, ₹89/mo flat, QR check-in, payroll, offline, WhatsApp/UPI/GST), FitnessForce, GymForce, + Mindbody/Glofox
- Tiffin → TiffinCRM, DineSpot, Mink Foodiee (pause/skip/cancel subscriptions, auto-billing, portals)

**Key truths:**
- QR check-in, offline mode, pause/skip, WhatsApp/UPI/GST are all **table stakes**, not differentiators.
- Only ~10% of any vertical (the organized, app-comfortable, willing-to-pay slice) uses software; ~90% still run on register + WhatsApp — unconverted *for reasons* (habit, trust, cost, simplicity), not easy wins.
- Incumbents fight over the same converted 10% → thin-margin price war (₹89/mo).

**What converts the manual 90% (triggers, not features):**
1. **Money leaking** they can feel (silent expired renewals) — the #1 converter; sell the *plugged leak*, not "software"
2. **Scale where memory fails** (~150+ people)
3. **Opening a 2nd branch** (notebook breaks)
4. **A dispute/theft they can't prove** (→ our trust/scan angle)
5. Wanting to look professional (softer)
- **Near-zero switching friction** ("we'll set it up for you") may convert more than any feature.

**What to incorporate from competitors:**
- Adopt: consent-based KYC; auto-routed status-tracked complaints; staff access limits; free tier + paid upgrade; tenant→owner referral reward
- Adapt: QR scan instead of AI face detection (cheaper, offline, extends to staff payroll); tenant *view* not separate app; simple WhatsApp API before branded line
- Skip for now: white-label per-owner apps; CA/legal/marketing add-ons; lead CRM
- Meta-lesson: every adopted item solves a **trust/friction** problem — keep focus there.

**Strategic conclusion:** don't out-feature incumbents on their turf. Win via (a) an **underserved wedge** (genuinely unserved micro-segments, or the **multi-business owner** nobody serves) + (b) **trust/dispute-proof mechanics** competitors underplay + (c) the **low-cost ledger + BYOS** model. *Domestic-staff-attendance direct-to-household failed the stress-test (tiny customers, near-zero willingness to pay, two-sided friction); the same feature sold to societies/agencies survives because the customer has scale.*

---

## 16. Sharpened Strategic Position (the core thesis)

> **Every competitor is locked in one vertical. We're the only *one app* for any business — especially the owner whose needs cross categories or fall in the gaps no specialist serves.**

**No competitor spans all categories** — but each established category has its *own* entrenched specialist:
- Gym → Akton, FitnessForce, GymForce · PG → RentOk, PG Manager, TrackMyPG · Tiffin → TiffinCRM, DineSpot, Mink Foodiee · Society → MyGate, ADDA, NoBrokerHood · Tuition → various
- So it's **not** "Akton owns gym, everything else is open" — it's "each category has a specialist; no one is horizontal."

**Where the horizontal position WINS (be specific):**
1. **The multi-business owner** ⭐ — runs a PG *and* a mess *and* shops, or gym *and* tuition. Today needs 3 apps from 3 specialists; nobody offers one dashboard. Common in India, completely unserved. **Sharpest wedge.**
2. **Unserved micro-segments** — newspaper/milk/water delivery routes, small mess/tiffin, society domestic-staff, dhobi. *No* entrenched specialist → open field, no one to fight.
3. **The "simple diary" owner** — finds specialists too heavy/expensive, just wants who-paid-who-didn't + records. Lean ledger + low cost serves where bloated specialists overshoot.

**Where it does NOT win (stay honest):**
- Single-category owner wanting *depth* in one vertical (serious gym chain wanting crowd analytics, branded member app) → specialist beats us on their turf. Don't pitch there.

**Go-to-market:** horizontal is the *destination*; launch through a *specific door* where there's **no competition** —
- Best entry: multi-business owner, or an unserved micro-segment
- Message: "**one app for all your businesses**" (multi-business owner) or "**finally, software for [your gap]**" (unserved segment) — never the un-searchable "we do everything"
- Win one door → prove the engine → add categories one at a time (each cheap, engine already built) → breadth becomes the moat *there*

**One-line strategy:** *Don't compete with specialists inside their category. Own the spaces between and across categories — the multi-business owner and the segments no specialist serves — with one simple, low-cost diary.*

---

## 17. Freemium & Pricing Model

**Tier structure (cost always funded by revenue):**

| Tier | What they get | Our cost | For |
|---|---|---|---|
| **Free** | "Click to send" reminders via owner's *own* WhatsApp (owner taps to send) | ₹0 messaging | Small owners (10–50), cost-conscious |
| **Paid** | Full automation — auto-scheduled/bulk reminders via Business API, AI expense reports, KYC, multi-branch | API/per-use cost, covered by fee | Busy/large owners wanting hands-off |

**Why it's sound:** free users cost ~₹0 (biggest variable cost removed); we only pay WhatsApp API for people *already paying us*. Cost and income move together. Free tier is a real product (owner's own number = more personal/trusted), builds the base; owners self-select into paid when manual taps become a chore at scale. Matches the "convert the manual 90%" path (free removes price barrier → grow → feel friction → upgrade).

**What goes in paid tier:** everything with a per-use cost to us (auto-WhatsApp, AI statement parsing, KYC verification) → costs always funded.

**Pricing shape — use SLABS, not pure per-tenant:**
- Per-tenant *sounds* fair but creates "meter anxiety" + under-reporting.
- Slabs (e.g. ≤25 → ₹199; 26–75 → ₹399; 76–150 → ₹699; 150+ custom) scale with size, stay predictable, easier to sell. (Roughly TrackMyPG's model.)
- Include a **message allowance per tier** as a safety cap so no single heavy user erodes margin (reminders are naturally bounded by tenant count, so mostly self-regulates).
- Cost reality: 50 tenants × ~₹0.30–0.80 × reminders = ~₹15–120/mo WhatsApp cost → any slab price comfortably covers it.

**Don't over-engineer pricing pre-launch** — pick a simple 3–4 slab structure, tune with real usage data after launch.

**WhatsApp caution:** "click to send" (owner manually taps) is safe = genuine human sending. Do NOT fully automate the *personal* WhatsApp via unofficial tools (risks the owner's number getting banned). Automation only on the official paid Business API.

---

## 18. Indicative Operational Cost (Android-only)

Architecture choices (ledger-only + BYOS + owner's-own-WhatsApp) keep run cost low.

- **One-time build:** ₹3–8 lakh outsourced (Android-only ~halves vs Android+iOS), or sweat equity. 2–4 months.
- **Run cost by stage (monthly):** pilot 0–100 owners → ₹4,000–10,000 · early 100–500 → ₹10,000–25,000 · scaling 1,000s → ₹40,000–1,00,000+
- **What's cheap:** cloud/infra (BYOS = no image storage; ledger-only = no transaction infra) — stays flat & small
- **What scales with users:** WhatsApp reminders (gated to paid tier) + support staff — *not* servers
- **First-year all-in:** ~₹4–9 lakh, mostly the one-time build; monthly burn stays small until real scale
- *Caveat:* India estimates from general benchmarks, not live quotes — get current pricing from WhatsApp provider (Meta/Gupshup/Interakt), cloud host, KYC API before committing.

---

## 19. Global Vision, Focused Launch

**Ambition:** usable worldwide, not India-only. The core insight (a simple diary for any small business — people, money in/out, staff, documents) is universal; small businesses everywhere share the same pains.

**What carries over globally:** the engine, the spine+signature interface model, the WhatsApp reminder strategy (WhatsApp dominates India, LatAm, Africa, much of Asia).

**What must change per market:**
- **Payments** — UPI is India-only (others: GCash/PromptPay/QRIS in SEA, M-Pesa in Africa, cards/PayPal/Venmo in West). *Our record-keeper model sidesteps this* — we just log "paid via [local method]," never integrate rails. Quiet advantage.
- **Currency & formats** — ₹/$/€/KSh/₱; Indian lakh-crore vs Western thousands. Localize from start.
- **Language** — non-tech owners often don't speak English; need Spanish/Portuguese/Bahasa/Swahili/Arabic etc. (+ RTL for Arabic). Real build.
- **Channel** — mostly WhatsApp-friendly target markets (helps); US/China differ (SMS/WeChat).
- **Compliance** — KYC, data laws (DPDP/GDPR/etc.), tax formats vary. BYOS helps with data-residency.

**Architecture already global-friendly** thanks to two earlier decisions:
- Record-keeper (not money-mover) → no per-country payment-rail integration
- BYOS storage → lower per-country data-residency burden

**Strategic rule:** *global-ready architecture, India-first launch, market-by-market expansion.*
- **Build global-ready plumbing day one** (currency-agnostic amounts, no hardcoded English, payment-method-agnostic ledger, locale formatting) — cheap upfront, painful to retrofit.
- **Win India first** — home-market insight edge, WhatsApp-friendly, huge market, sharpest understanding (PG/tiffin culture, cash habits, trust barriers).
- **Expand to *similar* markets next** (WhatsApp-dominant, cash-heavy, lots of informal micro-business): SE Asia, parts of Africa, LatAm — *not* US/Europe first (card-based, saturated, different behavior).
- **Re-weight the business catalog per region** (PG/tiffin matter in India; M-Pesa micro-businesses dominate Kenya; etc.).

**Caution:** "world from day one" usually builds something generic that fits nobody. Focus wins early — even WhatsApp/Grab/M-Pesa started hyper-local then expanded. Global vision, focused launch; the discipline is in *sequencing*, not in changing the core idea.

---

## 20. Bill / Invoice Generation (tax % entered by owner)

**Core approach:** owner enters the tax/GST **percentage**; the app only calculates. No HSN codes, no auto CGST/SGST logic, no rate lookups — owner says "18%", app computes. Simpler to build, low legal risk, works in any country (GST/VAT/sales tax — just amount × rate).

**Two bill modes (driven by a one-time setting, not chosen every time):**
- **Simple bill (default, ~80% of owners)** — business name/logo, bill no., date, customer, item/description, amount, paid/pending, payment mode. Zero tax clutter (hide tax fields entirely, don't grey them out).
- **Taxed bill** — toggle on → tax fields appear.

**Calculation:**
```
Amount: ₹5,000 · Tax %: 18% (owner types)
→ Taxable ₹5,000 + Tax ₹900 = Total ₹5,900
```

**Options (keep simple):**
- Tax on/off toggle
- Editable % field (any rate: 5/12/18/custom)
- Save default % in settings (override per bill)
- Optional display split: "CGST 9% + SGST 9%" instead of "GST 18%" — *display only*, math unchanged
- Optional tax-inclusive vs exclusive (app back-calculates)
- GST-registered owners: add GSTIN + "Tax Invoice" label as *optional fields* — but calculation stays "enter % → compute" (NOT a tax engine)

**Why this fits:** removes the error-prone part (app never needs to know any country's tax rules), owner stays in control, universal/global-ready.

**Caveat:** produces a correct-*looking* bill; owner is responsible for the right rate + any registration fields. Fully-compliant Indian GST invoices need GSTIN/HSN/"Tax Invoice" wording — offer as optional add-ons, don't build a compliance engine. Verify current GST treatment (PG/hostel/gym shifted recently) before relying on it.

**Two GSTINs — seller & buyer (B2B vs B2C) [TO BUILD]:**
- **Seller GSTIN** (yours) — already in business profile; always on a GST invoice.
- **Buyer GSTIN** (customer's) — only for B2B (customer is also a registered business). Optional field in the customer section, shown when tax is on. Blank → B2C (PG tenant, gym member); filled → B2B (co-working/catering billing a company).
- Why it matters: B2B buyers need both GSTINs on the invoice to claim input tax credit (ITC); without it the invoice is useless to them for tax.
- Place of supply ties to the CGST/SGST-vs-IGST choice: same state → CGST+SGST, different state → IGST. Keep "owner picks the treatment" (don't auto-detect from GSTIN state code) — just add IGST as a "Show as" option.
- Plan: optional buyer-GSTIN field appears when tax on; both GSTINs print on invoice when buyer's filled (labelled "GSTIN" / "Customer GSTIN"); most users (B2C) leave it blank.

### Bill header & numbering (built)
- Business profile (name, address, phone, GSTIN, logo) set once → auto-fills every bill; per-business (multi-business owner has separate headers).
- Layout: business details left, **logo right** (standard).
- Logo storage: device-local cache + optional backup to owner's Google Drive (BYOS); never in our DB. (Prototype holds it in-memory for the session.)
- Bill number: **auto-generated + editable**; per-business sequence with a settings-set prefix (INV-/BILL-/custom). GST needs sequential, unique numbers → warn on duplicates for registered users.

---

## 21. Premium Interface & Themes (design direction)

**Premium = restraint + craft, not more decoration.** Ingredients: generous whitespace (biggest lever), restrained color (neutral + one sparing accent), typography does the work (Notion-like hierarchy), subtle depth (hairline borders / soft shadows, no heavy drop-shadows), smooth 150ms micro-interactions, strict consistency.

**Themes:** light default (ship polished out-of-box) + dark mode (table stakes for premium feel) + maybe 2–3 curated accent palettes (warm/cool/neutral). NOT fifty garish themes — that reads cheap. One strong default matters more than many themes.

**Audience caution:** for non-tech owners + a *money* app, premium must signal **trustworthy & calm, not flashy**. Bank-grade calm > startup-flashy. Every premium choice must still pass "can a non-tech owner glance and instantly get it?" Elegance that aids clarity, never decoration that fights it.

**Reference family:** ElevenLabs / Notion / Linear / Stripe — light, typography-forward, neutral, calm.

**Reality:** premium UI is a craft (often needs a designer's eye for spacing/type/feel). Current prototypes are clean+functional; premium is a *polish pass* on the solid structure, not a rebuild.

**Notion takeaways:** borrow its calm design + "one data source, many views" idea + light optional customization. Reject its blank-canvas/build-it-yourself flexibility — we're the *anti-Notion* in philosophy (opinionated & pre-built for non-tech owners, not an open configurable canvas).

---

## 22. Keep Interface Universally Understandable (now; full localization later)
- Lean on icons + plain words (📵🔔 need no translation)
- Avoid India-only jargon in UI ("PG" is local; "rooms/tenants/members/collect payment/money in/money out" are universal)
- Don't hardcode ₹ or English deep in design — keep amounts/labels as variables so currency/language swap later is easy (no translation work now, just don't box ourselves in)
- Clean neutral visual language already travels well

---

### Bed labeling & room setup (PG + Hostel) [NOTE]
- Shared rooms hold multiple beds; each **bed** is assigned to a person (not the room). Bed-level tracking powers occupancy ("1 of 2 filled, 1 vacant"), per-bed billing, and dispute clarity.
- Don't force generic "Bed 1/2" — hostels/PGs use **their own labels**: 201-A/201-B, B1/B2, Upper/Lower (bunks), or unique IDs (Bed 047).
- **Proper architecture (same "configure once in Settings, consume everywhere" principle):** rooms + beds with the owner's own labels are created once in **room setup / Business Settings** (the building configurator). The add-person flow then just **picks a vacant bed** from that list (only vacant shown → can't double-book, no retyping).
- Applies identically to **PG and Hostel** (both bed-level, shared rooms).
- Refinements: hide bed picker for single-bed rooms (redundant); make bed optional if a place doesn't track beds.
- Prototype interim: bed field can be editable text (enter "201-A"/"Upper") until room/bed setup exists in Settings.

---

### Configurable required documents (per business, in Settings) [NOTE]
Document needs vary by business — don't hardcode one list:
- PG/hostel → Aadhaar, photo, police verification
- Working hostel → + **company ID / offer letter**
- Student hostel → + **college ID + parent/guardian ID**
- Co-living → + company ID
- Gym → photo, maybe ID + **medical/fitness declaration**
- Coaching → student ID + **parent ID**

**Design (same "configure once in Settings, consume everywhere" pattern):**
- Business Settings → **"Required documents"**: standard checklist (Aadhaar/Govt ID, photo, company ID, college ID, parent ID, police verification…) + **"Add custom document"** (owner types their own — e.g. gym medical declaration, co-working GST cert).
- Each doc marked **required vs optional** (required blocks onboarding; optional = "save now, add later").
- The add-person **Documents step is generated from this list** per business.
- **Storage rule unchanged:** document *images* → owner's Drive (BYOS); Aadhaar stays verify-don't-store. Configurability is about *which* docs, not *where* they're stored.
- Another item that lives in the **Business Settings page** (alongside plans, batches, rooms, bed labels, tax/GSTIN, logo) — reinforces building that page as the foundational next piece.

---

### Parking: two modes (set in Business Settings) [NOTE]
Parking has two distinct operating models — owner picks in setup (can be both):
- **Subscriber parking** (recurring) — person + vehicle + slot + monthly/quarterly/yearly rent. The full add-renter flow (built). For society residents, office staff, monthly renters.
- **Visitor / hourly parking** (identity-light) — **just the number plate + time in/out**, no name/account. Plate is the ticket: plate in → plate out → auto-calculate duration → charge by hour/day. For hospital, mall, event, public lots.

**Key point:** visitor mode is a **daily check-in/out action**, NOT an onboarding form — fits the daily-interface/scan engine (vehicle scans/logs in and out), like a hotel check-in but for vehicles.

**Broader pattern:** "log by number + time in/out, no person details, charge by duration" generalizes beyond parking — hospital token/queue, left-luggage counter, any time-based identity-light service. The plate/number is the identity.

**Where configured:** Business Settings → parking mode (subscriber / visitor / both), hourly & daily rates, grace period. Same "configure once, consume everywhere" principle.

---

### Two product modes: Subscription vs Job/Service [IMPORTANT]
The app serves **two kinds of business**, sharing the same spine (money in/out, staff, bills, ledger):

**Mode 1 — Subscription / Recurring** (built):
- members / tenants / subscribers · recurring billing · attendance
- PG, hostel, co-living, flat, gym, yoga, coaching, tiffin, parking, newspaper...
- Core: add-member flows + recurring dues + reminders

**Mode 2 — Job / Service** (new — big market expansion):
- clients · **quotes/estimates** · one-off invoices · payments · staff
- welding, sign-board/flex printing, carpentry, electrician, plumber, tailoring, photography, printing press, computer/mobile repair, AC/appliance repair, pest control, painting, interior, fabrication...
- No members/rooms/recurring rent. Flow: **client → quote → job → invoice → payment → record**
- Uses: bill generator (✓ built), money in/out (✓), staff/wages (✓), my bills (✓)
- **The one new piece needed: QUOTES/ESTIMATES** = bill generator relabeled "Quotation/Estimate" + a "convert to invoice" button (quote before work → invoice after). ~90% already exists.

**Why it matters:** Mode 2 covers a huge underserved segment — every small welding shop, carpenter, electrician, printer, tailor, repair shop in India, almost all on paper. Fits the "simple diary" thesis and meaningfully widens the market. Same spine, different top layer (one-off jobs vs recurring members).

**Retail/inventory businesses (kirana, hardware, medical store, garment retail)** are a *different* problem (stock management) — NOT a current fit; note and exclude for now.

### Field feedback (real owner calls) [IMPORTANT SIGNAL]
First real prospect calls — strong validation + sharpening:
- **Many already make invoices using ChatGPT** → behaviour shift to digital billing has *started*; ChatGPT is clumsy (no saved customers, no running bill numbers, no GST memory, no record kept). Our bill generator is purpose-built and clearly better → clear wedge. We're not changing behaviour, just giving a proper tool.
- **Advances tracked in a notebook** → bills and advances are split/disconnected; can't answer "paid vs owed" per customer. Our money in/out + ledger solves this directly.
- **GST/tax is a real pain** → validates tax feature; probe whether the pain is *per-bill calc* (done) or *summing up for filing* (→ build a GST summary/report).
- **"Everyone wants to SEE the app"** → strong buying signal, not polite interest. Priority shifts to *showing* warm leads the existing prototypes (bill generator, money in/out).
- **Sign-board owner** = PC access, already invoicing in ChatGPT → digital-ready, wants proper invoice + GST.
- **Welder** = still notebook for expenses, less digital, BUT asked for the hook that would pull him in 👇

**Welder's request — "attach design/drawing photo to the order"** [Mode 2 feature]:
- Attach the approved design/drawing image to a job/quote/invoice → (1) proof of what was agreed (dispute protection), (2) work reference for the worker, (3) future track ("past orders for this customer, with their designs").
- Generalizes across trades: welder→gate/grille drawing, sign-board→design mockup, carpenter→furniture sketch, tailor→dress reference, printer→artwork. **For Mode 2, the order often IS a visual thing.**
- Fits **BYOS** perfectly — design photos → owner's Google Drive, app keeps the link. No storage cost.
- Implies: quote/invoice supports **image attachment**, and a lightweight **per-customer job history with visuals** ("show past orders + designs for this customer") — powerful for repeat-business trades.

**Wedge implication:** Job/service trades (sign-board, welding, fabrication, carpentry) may be the sharpest *first* entry — pain is acute, they're already half-digital, and they're asking to see it. First pilot users = these callers (capture their numbers).

### Quote lifecycle / sales pipeline [NOTE — to build in Mode 2]
A quote isn't a throwaway — it has a life. Save every quote as a record the owner can return to.
```
Quote created → Sent → [customer decides]
   ├─ Approved → Convert to Invoice → job starts
   ├─ Pending  → follow up / remind
   ├─ Revised  → new version (keeps history)
   └─ Rejected / Expired → closed
```
**Flow:**
- Auto-save every quote (status starts "Sent"/"Draft" — never a manual save).
- **Quotes list** — all quotes with customer, amount, date, **status** (Pending/Approved/Rejected/Expired).
- Tap a quote → view/re-share, **convert to invoice** (carries everything, links the two), mark status, **revise** (new version), **follow up** (WhatsApp nudge).
- Quote number sequence (QT-001…), soft **validity/expiry** ("valid 15 days" → auto-expire prompts follow-up).

**Why it matters:** follow-up = money — owners send quotes and forget to chase them (lost business). A "pending quotes" list with a nudge is the *sales-side* version of the "money leaking" trigger ("3 quotes pending, ₹1.2L — follow up?"). Also gives win/loss tracking ("sent 10, won 6") and repeat-customer pricing history — none of which ChatGPT/notebook can do.

**Mental model:** a quote is to the *sales* side what a pending payment is to the *collection* side — both are open items needing follow-up that close when resolved. Same logic as the dues list → consistent app.

**Validate in reviews:** ask sign-board/welder — "After you send a quote, how do you track approval? Do you forget to follow up?" Answer reveals how much the pipeline matters.

### Handling quote pile-up [design refinement]
Quotes WILL pile up (most quotes never convert — quoting is fishing, that's normal). Failure mode = one flat ever-growing list → graveyard the owner ignores → feature dies. Fix:
1. **Status-based views, not one list** — default shows only **Open/Active** (pending, worth chasing — small, actionable). **Won** (converted) and **Lost/Expired** archived separately, out of the daily view.
2. **Auto-expire stale quotes** — no response in ~30 days → auto-move to Expired (no manual cleanup; leaves active list on its own).
3. **Smart targeted prompts, not a wall** — surface only what's worth a nudge ("2 quotes from last week un-followed — ₹85,000"), not all 50. Cold quotes stop prompting.
4. **Archive, don't delete** — keep everything (searchable history, "what did I quote Acme?"), but out of the active view.
5. **Pile-up = data, not clutter** — turn it into a **conversion-rate insight** ("sent 40 this month, won 8 = 20%"). A win-rate metric owners have never had.

**Principle:** active list = only what needs action *now*; everything else archived-but-searchable; system ages quotes out automatically so the owner never has to "clean up." (Same logic as a good email inbox.)

### Bill detail level: Simple vs Detailed/GST — user's choice [DECISION]
Real field benchmark: a Tally-generated GST tax invoice (Computer Mega IT → SVG Signs, B2B) shows what a *full* GST invoice carries vs our current builder. Solution: **let the owner pick the bill mode per bill** — don't force complexity on everyone.

```
Simple bill (B2C / walk-in / everyday)      Detailed / GST bill (B2B / registered)
  • name, phone                               everything in Simple, PLUS:
  • items + rate, total                       • company + GSTIN (buyer)
  • optional simple tax                       • HSN/SAC per item  ← key gap today
  → fast                                      • Ship-to vs Bill-to (can differ)
                                              • State + code → auto CGST/SGST (same
                                                state) vs IGST (diff state)
                                              • per/unit, round-off, amount in words
                                              • PAN, bank details, declaration, T&C
                                                (auto from Business Settings)
                                              → compliant GST tax invoice
```
**Design notes:**
- Most fields in Detailed mode are **settings-driven** (PAN, bank, declaration, T&C set once → auto-printed) or **optional** — so simple stays simple, B2B gets full rigor.
- **HSN/SAC per item** is the main addition we lack (mandatory for GST). Owners reuse codes → saved-HSN list helps.
- **State code auto-drives tax type** (same-state CGST+SGST vs inter-state IGST) — capture both states, app decides (Tally does this manually; we can automate).
- **Amount in words + round-off** = small but expected "looks legal" touches.
- **Smart default + override:** customer = Company w/ GSTIN → default Detailed; Individual → default Simple; always overridable. Smart *and* user's choice.
- **Value prop:** produce Tally-quality GST invoices but simpler than Tally → real draw for B2B job/service owners.

#### GST bill — additional decisions (from owner field input) [DECISION]
All belong to the **Detailed/GST bill** mode (optional, off by default, toggle-revealed — same pattern as discount):
- **Item-level GST** — toggle like discount (No tax / one rate whole-bill / **per-item rate**). When per-item, each item row gets its own GST %; tax computed per item then summed. Needed because job/service mixes rates (steel 18%, some materials 12%/5%, labour differs). → **Rate-wise tax summary** ("GST @18%: ₹X, GST @12%: ₹Y") — how real GST invoices show it, and what accountants need.
- **IGST = automatic, not a manual toggle** — capture **buyer's state**; if buyer state == seller state → **CGST+SGST**; if different → **IGST**. App auto-decides (Tally does this; user shouldn't know the rule).
- **E-way bill = RECORD, not GENERATE** — critical distinction:
  - ❌ Generating an e-way bill needs government **GSP API integration** (ewaybillgst.gov.in) — heavy, phase-2+, needs GSP partnership. Don't build speculatively.
  - ✅ **Record e-way bill details** the owner generated on the portal: optional toggle reveals **e-way bill number, date, vehicle number, transporter name/ID, distance/from-to**. Prints on invoice, saved with the record (ties e-way ref to invoice + customer). Easy, useful now.
- **Discipline note:** these are all "full GST compliance" features pushing toward being Tally — a real but *heavier* market than the "simple diary." First survey respondent wanted "bill & quotation," not e-way bills. Capture the spec, but **don't build heavy compliance before a paying customer demands it.** Build the simple bill first; layer GST-detail as B2B demand proves out.

**Full Detailed/GST bill spec (consolidated):** item-level GST (per-item rates + rate-wise summary), IGST auto-by-state, HSN/SAC per item, Ship-to/Bill-to, amount-in-words, round-off, e-way bill details (record), settings-driven boilerplate (PAN, bank, declaration, T&C).

### First survey response (Girija Arts — sticker/sign boards) [FIELD DATA]
- Mode-2 target, digital-ready (printed bills, UPI). Q15 must-have = **"Bill & quotation"** → direct hit on what we built (wedge pointed right).
- BUT cautionary cluster: **won't pay** (Q14), already using software (Q11), only "Maybe" (Q13) → "warm on problem, cold on paying"; we'd be a *switch*, not first tool.
- Lessons: need is real & matches build; "free expectation" is a monetization threat; we're often a switch (→ "why switch to us" matters); survey can't tell *what they use now* or *why won't pay* — that needs a live interview. One point = noise; watch for patterns across 8–10.
- Survey improvement to consider: add "What app/tool do you use now?" (know the competition).

---

### Staff: Payment vs Attendance — separate but linked [DECISION]
Two different actions, different rhythms — keep separate, link only where needed:
- **Payment** — pay salary / wage / advance → records to **Money Out**, linked to the staff member. Periodic (month-end or advances). From the staff profile.
- **Attendance** — mark present/absent each day. Daily rhythm. **Optional, OFF by default.**

**Key rule — attendance is optional, not forced:**
- **Salaried staff** (caretaker, trainer, office) → fixed pay regardless of attendance; most owners won't mark daily attendance. Don't force it.
- **Daily-wage staff** (helper, labour) → attendance IS the pay basis (present 24 days × ₹600 = ₹14,400). Here attendance feeds payment.
- So turn attendance on per-worker/per-business where it matters; default off.

**Where they live:**
- Payment → staff profile action + Money Out (standalone, built as a flow).
- Attendance → a **daily-operations action** (mark/scan present), belongs on the daily/home screen, NOT staff onboarding. Ties to the scan engine (staff scan counts UP toward wages, vs member scan counts DOWN balance). Build with the daily interface.

**Payment flow detail:** pay type = Salary / Wage / Advance; for daily-wage can pull days×rate (from attendance if tracked) or enter manually; records date, amount, mode (cash/UPI) → Money Out entry tagged to staff; generates a simple payment slip/receipt.

---

### Staff record: full superset now, configurable later [DECISION]
My Staff is shared across ALL business types, but different employers need different detail (welder helper = name+phone+wage; security agency = full KYC + police verification + references; school = certificates). Don't hardcode a fixed set.

**Approach (hybrid B+C):**
1. **Now (independent):** rich profile holds the **full superset** of fields, ALL optional except name. Quick-add stays minimal (name, role, pay, phone, UPI); profile tabs hold everything else; fill progressively ("save now, add rest later").
2. **Later (when Business Settings exists):** a **configuration layer** lets the owner tick which staff fields/documents matter for their business → form hides the rest. Same "configure once, consume everywhere" pattern as tenant required-documents. Welder sees a short form; agency sees full. Layers on without rework.

**Locked principles:** only **name** mandatory; quick-add minimal; profile = full superset in tabs; progressive; later configurable visibility.

**Full superset of staff fields:**
- *Identity:* name, photo, phone, UPI, address, DOB, gender
- *Documents:* ID proof (Aadhaar — verify-don't-store), PAN (number + card image — OK to store), certificates/licences, work agreement, verified flag. **ID type lives in Documents, not Details.**
- *Employment:* role, pay type, pay, join date, shift/timing
- *Emergency:* contact name + phone, relation
- *References:* previous employer / referred-by (trust)
- *Compliance (optional):* police verification, ESI/PF number
- *Money:* payment history, advance balance
- *Attendance:* present/leave (if tracked)

---

### Staff onboarding flow — FINALIZED (onboard-staff.html) [BUILT]
Standalone employee/freelancer/daily-wager onboarding with **three depth presets** (user's idea: presets for speed + full options open):
- **Simple** — name, type, phone, gender, photo, native place + current address, ID(s), emergency, pay. Fastest (daily wagers, quick hires). 4 steps.
- **Standard** — Simple + Background step (referred by, previous employer, experience, documents, resume). 5 steps.
- **Detailed** — Standard + Compliance step (EPFO/PF, ESI, police verification, background verification). 6 steps.

Flow adapts to chosen depth; depth picked on first screen (changeable in Settings later). Worker **type**: Employee / Freelancer / Daily wager / Contract. **Pay type**: Daily / Weekly / Monthly / Per task. **Multiple IDs** supported (add/remove cards — Aadhaar + PAN + licence etc., each with type/number/upload/verified; Aadhaar verify-don't-store notice per card). "Place from" = **both** native place (hometown) and current address. Review shows only sections relevant to the depth. "Save now, add rest later" on every step.

**Note:** field-level customization (the setup-page idea) deferred to Business Settings — presets give quick-start now; exact-field picking layers on later without rework. My Staff (management screen) kept separate, built earlier (my-staff.html).

---

### Payment gateway / auto-fee-tracking [DECISION — deferred]
**Considered:** integrating a 3rd-party payment gateway (Razorpay/Cashfree) so payments auto-confirm via webhook (send link → tenant pays → app auto-marks paid). Valuable UX but changes the model:
- **Transaction fees:** ~1.5-2% per UPI, 2-3% card. On ₹10K/mo from 20 tenants = ₹2-4K/mo in gateway fees. Someone absorbs this. CoFee's reviewer already complains about this.
- **Model shift:** record-keeper → money-mover. Adds KYC, compliance, settlement, refund handling.
- **Cost vs pricing:** at ₹199/mo slab, absorbing gateway fees is impossible. Must pass to owner/tenant → friction.

**Decision: stay simple and cheap for now. Pure record-keeper, no gateway.** Add gateway as an *optional premium tier* only once financially stable and paying users demand it.

**Current payment flow (MVP):**
- FREE: owner collects via own UPI → manually marks "paid" in app. ₹0 transaction cost.
- Future exploration: **UPI notification capture** (Android reads UPI payment notifications with permission → auto-matches to pending dues → marks paid). Preserves record-keeper model, zero fees, auto-tracking. Not as clean as gateway webhook but free and keeps the zero-transaction-fee advantage. Worth exploring post-MVP.
- Future premium: gateway integration as opt-in tier, transaction fees passed through transparently.

**Competitive note (CoFee pricing intel):** CoFee starts at ₹1,199/mo for ≤₹10K transaction volume + transaction fees on top. Their reviewer's #1 complaint = high fees. Our ₹199/mo + zero transaction fees = 6× cheaper, directly addresses their weakness. Record-keeper economics: marginal cost per user ≈ pennies (just DB rows), break-even at ~10-15 paying users, profitable from day one after that.

---

### Data architecture: local-first + cloud-as-premium [DECISION]
**Architecture:** local-first (SQLite on phone) with Supabase as backup/sync/auth layer. NOT cloud-first.
- **Phone (SQLite)** = primary data store. All business data lives here. Fast, works offline, single-device.
- **Supabase** = auth (OTP), backup sync, subscription management, multi-device access for paid users.
- **Google Drive (BYOS)** = document files only (Aadhaar, photos, designs, agreements).

**Why local-first:** users are small Indian business owners in areas with patchy internet. Cloud-first = app freezes without signal = deal-breaker. Local-first = always works, instant, "WhatsApp model" users already understand.

**Freemium split on DATA TIER (the monetization insight):**

| | Free | Paid (₹199-699) |
|---|---|---|
| All features | ✅ full | ✅ full |
| Data storage | Phone only (local) | ☁️ Cloud sync (Supabase) |
| Devices | 1 phone | Multi-device (phone + web + tablet) |
| Backup | Manual / own effort | Auto cloud backup |
| Restore on new phone | ❌ data lost | ✅ instant restore |
| Team access | ❌ | ✅ staff/manager login (premium) |
| Web dashboard | ❌ | ✅ (paid) |
| WhatsApp | Click-to-send (own) | Auto (Business API, premium) |

**Why this works:**
1. Free tier genuinely useful (no feature walls, no crippling) → builds trust + referrals.
2. Upgrade triggers are NATURAL (new phone, lost phone, want laptop access, need team access) — not artificial limits.
3. Free users cost ~₹0 infra (all local, no server queries). Paid users cost ~₹50-100/user/mo but pay ₹199-699 → 80-90% margin.
4. "WhatsApp model" — data on phone, backup to cloud — Indians understand instantly.
5. Subtle honest nudge: "Your data is only on this phone. Upgrade to keep it safe in the cloud." Once a month, not aggressive.

**Revised three-layer architecture:**
```
Phone (SQLite):     ALL business data — fast, offline, free
Supabase:           Auth + cloud backup/sync (paid) + subscriptions
Google Drive (BYOS): Document files (photos, scans, designs)
```

---

## 23. Deferred Topic
**Tenant-side features** (self-service portal, what tenants can see/do, tenant app access) — intentionally **not yet decided**. To be discussed in a future session. Until then, assume owner/admin/staff-side features only.

---
Prioritize all features on a **owner pain × tenant pain × build effort** map to isolate the 4–5 that form a lean MVP wedge, then design a single-city / single-cluster manual-outreach pilot to test penetration economics.
