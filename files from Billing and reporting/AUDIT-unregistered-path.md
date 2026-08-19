# AUDIT — The unregistered path, end to end
**Purpose:** §7 of the agreed decisions. Walk the flow a non-GST business actually takes and cut everything that appears without earning its place.
**Who this is:** below ₹40L goods / ₹20L services. No GSTIN. The notebook user the product is aimed at. Almost certainly the majority of installs.

**Rule being applied:** every GST field is additive. Not hidden, not disabled, not present-and-empty — absent.

---

## Stage 1 — Onboarding

| Field | Registered | Unregistered |
|---|---|---|
| Business name | ✓ | ✓ |
| Business type | ✓ | ✓ |
| Address / phone (bill header) | ✓ | ✓ |
| GSTIN | ✓ | **cut** |
| State code | ✓ | **cut** |
| GST registration mode | 3-way choice | **cut** |
| Composition category | ✓ | **cut** |
| Turnover bracket | ✓ | **cut** |
| Filing frequency | ✓ | **cut** |
| Supply type (goods/services) | ✓ | **cut** |

**Nine fields become three.**

The mode question itself is the problem. A three-way choice between *unregistered / composition / regular* asks a notebook user to classify themselves in tax vocabulary before they've made a single bill. Replace it with one toggle, off by default:

> **Do you have a GST number?** ‹off›

Off, and nothing further is asked. On, and the mode question appears — because someone with a GSTIN can answer it.

State code is captured only when GST is switched on. It has no non-tax use in billing.

---

## Stage 2 — Adding an item

| Field | Registered | Unregistered |
|---|---|---|
| Name | ✓ | ✓ |
| Unit | ✓ | ✓ |
| Price | ✓ | ✓ |
| HSN code | ✓ | **cut** |
| GST rate | ✓ | **cut** |
| Rate source / slabs | ✓ | **cut** |
| Place-of-supply rule | ✓ | **cut** |

**Seven fields become three.** This is the highest-frequency form in the app — a shop adds items constantly — so it's where the cuts pay off most.

---

## Stage 3 — Making a bill

**Cut:** customer GSTIN, customer state, place of supply, HSN column, GST% column, CGST/SGST/IGST rows, series picker, Tally reference fields.

**Kept:** customer name and mobile, items with qty and rate, discount, freight/packing where relevant, round-off, notes, total, amount in words.

**Kept but reframed:** site address stays for JOB-engine work. A signboard firm needs to know where the board goes whether or not it charges tax — it's operational, not fiscal. It just stops being a tax field.

**Document title:** plain **Bill**. Not *Tax Invoice* (regular only), not *Bill of Supply* (a GST term belonging to composition). A cash memo is a bill.

**Roughly eighteen fields become nine.**

---

## Stage 4 — Taking payment

**Nothing to cut.** Payments are dated events, partial payments and udhaar work identically, payment status is derived. This stage is already GST-free.

Worth stating plainly: **the core promise works the same in all three modes.** Vasooli, dues, follow-ups, money recovery — none of it depends on GST. The tax machinery is a layer on top of the product, not the product.

---

## Stage 5 — Corrections and returns

**Cut:** rate mirroring from the original, the 30 November credit-note deadline warning, the separate legal numbering series, the receipt voucher, the adjustments hub.

**Kept:** one action on the bill — *Customer returned something* — which reduces what's owed and prints a plain return note. Numbered simply, with no 16-character or financial-year constraints, since those are invoice rules.

### One correction rule, not two

The spec currently locks an issued bill forever. That's correct under GST and unnecessarily harsh without it — a shopkeeper who fat-fingers a price shouldn't be forced into cancel-and-reissue.

Rather than branch the behaviour, restate the rule so one sentence covers both:

> **A bill locks the moment it starts to matter** — when it's shared, when a payment lands against it, or when it enters a GST period.

For a registered business, issuing puts it in a GST period, so it locks at issue exactly as before. For an unregistered one, a bill not yet shared or paid stays editable. Same rule, one flag (`locks_on_issue`), no second code path.

**Needs your call** — this is the one place I'm proposing to relax a locked decision.

---

## Stage 6 — Month end

**Cut:** the GST summary screen, the nine-sheet CA export, HSN nudges, the *Given to CA* toggle, period locks.

**Kept:** the ordinary monthly statement — sales, received, outstanding, top customers, best-selling items.

---

## Two things to *add*, not cut

Cutting is most of this audit, but the walk surfaced two additions worth more than anything removed.

### 1. The threshold nudge
An unregistered business that crosses ₹40L (goods) or ₹20L (services) must register, and missing it means penalties and back-tax. They are the least likely of all users to be watching for it — that's precisely what makes them unregistered.

When trailing-twelve-month sales pass roughly 80% of the threshold, show a one-time notice:

> *Your sales over the last year are getting close to the point where GST registration becomes compulsory. Worth a word with a CA.*

Once, dismissible, never nagging. This is the app noticing something the notebook never could — and it protects real money.

### 2. The interstate warning already specced (§5C)
Selling goods to another state requires registration regardless of turnover. This stays. It and the threshold nudge are the **only** two GST things an unregistered user should ever encounter.

---

## Three items — all resolved

1. **Pre-share editing — adopted, with an amendment tier added.** The lock condition became a three-tier ladder: edit freely before it matters, **amend with a full trail** while the GST period is still open, credit/debit note once the period is with the CA. The middle tier came from a case I'd missed — a registered business that spots an error before filing should correct it honestly, not paper over it with a credit note that misrepresents what happened. Full spec in §3.
2. **Threshold nudge — adopted.** Counts both per-business and combined across all businesses, since the legal threshold is PAN-level. Simple level check, no run-rate projection. Spec §5D.
3. **Tally reference fields — adopted as an advanced toggle**, not a mode-driven cut. Some unregistered businesses still use a CA who works in Tally.

---

## What this means for the bills list

Designed for the unregistered user first, the bills list has: number, customer, amount, date, paid/unpaid, and a return action. No document-type filter, no series column, no tax breakdown, no cancelled-bill series integrity display.

Everything else is additive when GST comes on. That ordering matters — the alternative is designing the registered screen and hiding parts of it, which is how the fields creep back in.
