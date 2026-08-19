# Khaata — Screen Matrix & Gap Analysis

Maps every screen to the five engines. Answers: *which pages does this business owner actually get?*

---

## The Core Idea

The competitor solved your exact problem in Section 16 — a **Features Toggle** where the owner turns off what they don't use. Two features are locked always-on (Invoices, Clients); the other ten are switchable, and data survives being switched off.

Good pattern. But they made the **user** do the work — a newspaper agent has to find and switch off Contracts, Time Tracking, Projects, Estimates one by one.

**Khaata's version:** business type presets the toggles. Gym → recurring on, quotation off. Newspaper agency → recurring on, staff off, calendar off. Contractor → quotation on, recurring off, stages on. Owner can still override in Settings.

Same mechanism, none of the work. That's your onboarding answer: **pick your business type → screens configure themselves.**

---

## Legend

**Engines:** `SUB` Subscription · `APPT` Appointment · `EVENT` Event booking · `JOB` Job/Project · `SALE` Counter sale

**Cells:**
| Mark | Meaning |
|---|---|
| ● | Core — always on, cannot be switched off |
| ○ | Preset ON — default on, owner may switch off |
| ◐ | Preset OFF — hidden by default, owner may switch on |
| · | Not offered for this type |

**Priority:** ★★★ build early · ★★ Phase 2 · ★ later

**Status:** `Built` · `Specced` · `Proto` · **`GAP`** = not in your list, should be

---

## A. Universal Spine — every business, no toggle

| Screen | SUB | APPT | EVENT | JOB | SALE | Priority | Status |
|---|---|---|---|---|---|---|---|
| First-run wizard | ● | ● | ● | ● | ● | ★★★ | Built |
| **Business type picker** | ● | ● | ● | ● | ● | ★★★ | **GAP** |
| Business setup / settings | ● | ● | ● | ● | ● | ★★★ | Specced |
| Business switcher | ● | ● | ● | ● | ● | ★★★ | **GAP** |
| Customer list | ● | ● | ● | ● | ● | ★★★ | Built (M2) |
| Customer add / edit | ● | ● | ● | ● | ● | ★★★ | Built (M2) |
| **Customer ledger / statement** | ● | ● | ● | ● | ● | ★★★ | **GAP** |
| Money in entry | ● | ● | ● | ● | ● | ★★★ | Specced |
| Money out entry | ● | ● | ● | ● | ● | ★★★ | Specced |
| **Vasooli / follow-up list** | ● | ● | ● | ● | ● | ★★★ | Proto |
| Mini dashboard (home) | ● | ● | ● | ● | ● | ★★★ | Specced |
| App settings | ● | ● | ● | ● | ● | ★★★ | **GAP** |
| Global search | ○ | ○ | ○ | ○ | ○ | ★★ | **GAP** |

> **Customer ledger is the biggest gap in your list.** The app is called Khaata. The per-customer running statement — every entry, running balance, share as PDF — *is* the khaata. It wasn't in the ten pages you named.

---

## B. Bills & Documents

| Screen | SUB | APPT | EVENT | JOB | SALE | Priority | Status |
|---|---|---|---|---|---|---|---|
| Bill / invoice generator | ● | ○ | ● | ● | ● | ★★★ | Specced |
| **Item / price book** | ○ | ● | ○ | ● | ● | ★★★ | **GAP** |
| **Payment recording + receipt** | ● | ● | ● | ● | ● | ★★★ | **GAP** |
| **Send / share (WhatsApp, PDF)** | ● | ○ | ● | ● | ○ | ★★★ | **GAP** |
| Quotation / estimate | ◐ | ◐ | ● | ● | ◐ | ★★ | Specced |
| Bill theme / branding | ○ | ○ | ○ | ○ | ○ | ★★ | Specced (Pro) |
| **Number sequence config** | ○ | ○ | ○ | ○ | ○ | ★★ | Schema only |
| **Saved text blocks / terms** | ◐ | · | ◐ | ○ | ◐ | ★ | **GAP** |
| Contract / agreement | ◐ | · | ◐ | ◐ | · | ★ | **GAP** |

> **Item/price book is a silent dependency.** Bill generator can't ship without it — otherwise every bill is retyped by hand. The competitor treats it as a utility; for you it's a prerequisite.
>
> **Payment recording ≠ bill generation.** A ₹5,000 bill with ₹2,000 paid needs a separate entry. Partial payment is the normal case in India, not the exception. Note the competitor's discipline here: late fees print on the PDF but never auto-record a payment. Copy that rule.
>
> Contract is low fit — skip unless a specific module demands it.

---

## C. Recurring — the SUB engine

| Screen | SUB | APPT | EVENT | JOB | SALE | Priority | Status |
|---|---|---|---|---|---|---|---|
| **Plan / package definition** | ● | ◐ | · | · | · | ★★★ | **GAP** |
| **Subscription assignment** | ● | ◐ | · | · | · | ★★★ | **GAP** |
| **Recurring bill auto-generate** | ● | ◐ | · | · | ◐ | ★★★ | **GAP** |
| **Renewal / due list** | ● | ◐ | · | · | ◐ | ★★★ | **GAP** |

> **This whole block is missing from your list, and it's where your ★★★ businesses live.**
>
> PG, gym, coaching, tiffin, milk, newspaper, society, school van — every one of them needs: define a plan (₹2,000/month), attach a customer to it, auto-raise the bill on the 1st, show who hasn't paid. That's four screens and it unlocks ~24 of your ★★★ businesses.
>
> Renewal/due list and Vasooli overlap heavily — likely one screen with two filters, not two screens. Worth deciding early.

---

## D. People — Staff & Attendance

| Screen | SUB | APPT | EVENT | JOB | SALE | Priority | Status |
|---|---|---|---|---|---|---|---|
| Staff list / onboarding | ○ | ○ | ○ | ● | ○ | ★★ | Specced |
| Staff attendance | ○ | ◐ | ◐ | ● | ◐ | ★★ | Specced |
| **Staff salary / payout** | ○ | ○ | ○ | ● | ○ | ★★ | **GAP** |
| Customer attendance | ○ | · | · | · | · | ★★ | Specced |
| **Advance / loan to staff** | ◐ | ◐ | ◐ | ● | ◐ | ★★ | **GAP** |

> **Attendance means two different things and your list merges them.** Gym customer check-in and staff attendance are different screens with different owners. Coaching needs both. Newspaper agency needs neither.
>
> **Salary payout is the gap.** Attendance without payout is a half-loop — you record 24 days present and then... nothing computes. For a labour contractor, attendance→wages *is* the product.
>
> **Staff advance** is near-universal in Indian small business and almost never in competitor apps. Cheap to build, disproportionate goodwill.

---

## E. Scheduling

| Screen | SUB | APPT | EVENT | JOB | SALE | Priority | Status |
|---|---|---|---|---|---|---|---|
| Calendar | ○ | ● | ● | ○ | ◐ | ★★★ | Specced |
| Timetable / batches | ○ | · | · | · | · | ★★ | Specced |
| **Slot booking** | ◐ | ● | · | ◐ | · | ★★★ | **GAP** |
| **Day queue / today's list** | ◐ | ● | ● | ○ | · | ★★ | **GAP** |
| **Date-block booking** | · | ◐ | ● | ◐ | · | ★★★ | **GAP** |

> **Calendar means three different things** and this is worth naming clearly:
> - `SUB` — a *money* calendar (what's due when). This is the competitor's version: In / Out / Overdue filters.
> - `APPT` — a *slot* calendar (10:30 free?)
> - `EVENT` — a *blocking* calendar (26th Nov taken — don't double-book)
>
> Same grid, three data sources. Build the money calendar first; it serves your ★★★ tier.
>
> Timetable is coaching/gym only. Correctly excluded from everything else.

---

## F. Appointment engine

| Screen | SUB | APPT | EVENT | JOB | SALE | Priority | Status |
|---|---|---|---|---|---|---|---|
| Service catalogue | · | ● | ○ | ○ | · | ★★ | reuse Price Book |
| **Walk-in quick bill** | · | ● | · | · | ● | ★★ | **GAP** |
| **Repeat visit history** | ◐ | ● | · | ◐ | ◐ | ★★ | **GAP** |

## G. Event engine

| Screen | SUB | APPT | EVENT | JOB | SALE | Priority | Status |
|---|---|---|---|---|---|---|---|
| **Advance vs balance tracker** | · | ◐ | ● | ● | ◐ | ★★★ | **GAP** |
| **Package builder** | · | ◐ | ● | ○ | · | ★★ | **GAP** |
| **Event team payout** | · | · | ● | ○ | · | ★★ | **GAP** |

> Advance/balance is the photographer's and makeup artist's entire anxiety. ₹20k advance in March, ₹60k due on the wedding day in November. No app tracks this well for them.

## H. Job engine

| Screen | SUB | APPT | EVENT | JOB | SALE | Priority | Status |
|---|---|---|---|---|---|---|---|
| **Job card / project** | · | ◐ | ○ | ● | · | ★★★ | **GAP** |
| **Stage / milestone tracker** | · | · | ◐ | ● | · | ★★ | **GAP** |
| **Material & labour log** | · | · | · | ● | · | ★★ | **GAP** |
| **Budget vs actual** | · | · | ◐ | ● | · | ★★ | **GAP** |

> This block also serves every life-event ledger (marriage, home build) — same engine, personal preset.

## I. Sale engine

| Screen | SUB | APPT | EVENT | JOB | SALE | Priority | Status |
|---|---|---|---|---|---|---|---|
| **Udhaar / credit book** | ◐ | ◐ | · | ◐ | ● | ★★★ | **GAP** |
| **Stock / inventory** | · | ◐ | ◐ | ◐ | ● | ★★ | **GAP** |
| **Purchase entry** | · | · | · | ◐ | ● | ★★ | **GAP** |

> Udhaar is the only reason to enter `SALE` at all. Stock is where you'd lose to Vyapar — build shallow or not at all.

---

## J. Reports & Dashboard

| Screen | SUB | APPT | EVENT | JOB | SALE | Priority | Status |
|---|---|---|---|---|---|---|---|
| Full dashboard | ○ | ○ | ○ | ○ | ○ | ★★ | Specced |
| **Aging report** | ● | ○ | ○ | ○ | ● | ★★★ | **GAP** |
| **Customer statement PDF** | ○ | ○ | ○ | ○ | ● | ★★ | **GAP** |
| Collection summary | ● | ○ | ○ | ○ | ○ | ★★ | **GAP** |
| **P&L** | ○ | ○ | ○ | ○ | ○ | ★★ | **GAP** |
| **GST / tax report** | ◐ | ◐ | ◐ | ◐ | ○ | ★★ | Specced |
| **Monthly summary** | ○ | ○ | ○ | ○ | ○ | ★★ | **GAP** |
| Staff attendance report | ○ | ◐ | ◐ | ● | ◐ | ★★ | **GAP** |

> The competitor's aging report is described as *"who owes you, by age"* — bucketed 0–30 / 31–60 / 61–90 / 90+. That is Vasooli with a time axis. Same query, two presentations: Vasooli = today's call list, Aging = the pattern behind it. Build one, render twice.
>
> Mini vs full dashboard is a good split. Mini = money only (3 numbers). Full = charts, toggleable off. Most of your ★★★ owners will never open the full one.

---

## K. System

| Screen | Priority | Status | Note |
|---|---|---|---|
| Login / auth | ★★ | **GAP** | Pro tier only — free users never see it |
| Paywall / upgrade | ★★ | **GAP** | Needed before any revenue exists |
| **Feature toggle screen** | ★★★ | **GAP** | The Section 16 pattern — preset by business type |
| Backup / restore | ★★ | Specced | Pro |
| Export (CSV / JSON) | ★★ | **GAP** | Competitor gates export at Pro, import free — smart asymmetry |
| Document vault (Drive) | ★★ | Specced | BYOS |
| Reminders / notifications | ★★ | **GAP** | |

---

## Gap Summary

Your ten pages were solid. Here's what analysis surfaced on top:

**Critical — blocks your ★★★ tier:**
1. Customer ledger / statement — the actual *khaata*
2. Plan definition + subscription assignment + recurring generate + due list — the `SUB` engine
3. Item / price book — silent prerequisite for the bill generator
4. Payment recording (partial payments)
5. Send / share
6. Aging report
7. Business type picker + feature toggle — the thing that makes onboarding non-generic
8. Business switcher

**Important:**
9. Staff salary payout (closes the attendance loop)
10. Staff advance
11. Udhaar book (`SALE` entry point)
12. Advance vs balance (`EVENT`)
13. Job card + stages (`JOB` + all life-event ledgers)
14. Slot booking (`APPT`)
15. Paywall

**Worth taking from the competitor:**
- Feature toggle with data preservation — but preset it, don't make them do it
- Sample data seeding ("Load sample invoices") — teaches the UI risk-free
- Auto-archive paid bills — list stays clean, nothing deleted
- Import free / export Pro — asymmetry that lets people in and makes them pay to leave
- Per-invoice override of global defaults

**Worth declining:**
- Contracts, time tracking, withholding tax, IBAN/SWIFT — wrong market
- Their pricing (₹499/month, no free tier) — your free tier is the whole strategy

---

## Suggested Sequence

| Step | Screens | Why |
|---|---|---|
| 1 | Customer ledger + payment recording + send | The khaata itself. Nothing works without it. |
| 2 | Business type picker + feature toggle | Makes every later screen conditional. Retrofitting is painful. |
| 3 | Item/price book → bill generator → aging report | Closes the money loop |
| 4 | `SUB` engine (4 screens) | Unlocks ~24 ★★★ businesses at once |
| 5 | Staff + attendance + payout | The `S` flag businesses |
| 6 | `APPT` → `EVENT` → `JOB` → `SALE` | In ★★★ density order |

Step 2 is the one to not get wrong. Every screen after it asks "am I on for this business type?" — cheap to answer if the picker exists, expensive to bolt on later.
