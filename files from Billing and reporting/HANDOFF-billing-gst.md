# HANDOFF — Billing, Records & GST
**Session:** 11 Aug 2026
**Paste into a new chat, or fold into `CLAUDE.md` under Current Status.**

---

## Artifacts produced

| File | What it is | Authority |
|---|---|---|
| `SPEC-billing-records-gst.md` | Full spec — modes, numbering, lifecycle, data model, calculations, quotes, advances, summary, export | **Single source of truth** |
| `DECISION-eight-open-problems.md` | Eight architectural gaps found in review, all agreed and folded into the spec | Reasoning trail only |
| `AUDIT-unregistered-path.md` | End-to-end walk of the non-GST flow with cuts and two additions | Folded into spec |
| `quotations.html` | Quote list, detail, convert-to-invoice | Mockup |
| `notes-vouchers.html` | Advances, credit notes, debit notes | Mockup |
| `bills-list.html` | Bills list, detail, lock tiers, fix sheet | Mockup |

---

## The decisions that matter most

**GST registration mode is the master switch**, with three values, not a boolean. Unregistered is the pre-selected default. Every GST field is **additive** — for unregistered they don't exist, not hidden or disabled.

**Plain words in the app, GST words on documents.** "Customer returned something" on screen; "Credit Note" on the print and in the CA export. These are the same object named twice, deliberately.

**A bill locks when it starts to matter.** Three tiers, one condition — edit freely before it's shared or paid; amend with a full trail while the GST period is open; credit/debit note once the period is with the CA. Amendments keep the same number.

**Bills are never deleted.** Gaps in a series are an audit flag. This is the one place archive-first deletion doesn't apply.

**Place of supply has three rules**, not two — customer state, supplier location (hotels, restaurants), or property location (signboards, civil). Resolves at bill level from the principal line, composite-supply style. Never blocks.

**Milestones are the one billing mechanism** — percentage, line subset, or scheduled installment. Replaces line-picking in quotes and stage billing in civil.

**`job_id` ties everything together.** An accepted quote creates the job; advances, milestone invoices and adjustments all inherit it.

**Follow-up list has three sources** — unpaid bills, unanswered quotes, and completed-but-uninvoiced milestones. Advances are explicitly *not* a source; they're money you hold.

**Actor columns from day one.** `created_by` on every table, same reasoning as `business_id` — a free-tier business still has one implicit users row, so adding staff later never triggers a back-fill migration. Attribution on cash payments is the real feature, not the audit trail on bills.

**GST summary is a CA handoff, not a filing tool.** Rate-wise screen plus a multi-sheet Excel export. No portal JSON, no ITC, no purchases.

---

## Known gaps before code

1. **`quotations.html` is stale** — converts by picking lines; the spec now says raise a milestone
2. **Vocabulary drift in the two earlier mockups** — GST terms appear where the spec reserves them for printed output
3. **Nothing has been seen on a device.** All three mockups are jsdom-logic-tested only. Expect layout problems at 360px.
4. **GST Summary + CA export is unbuilt** — the last screen from this spec

---

## Config values needing verification at build time

None of these belong in code. All have changed before.

- B2C Large inter-state threshold
- Composition scheme rates per category
- Registration thresholds (₹40L goods / ₹20L services — and ₹40L applies only to a supplier dealing *exclusively* in goods)
- Threshold nudge trigger point (currently 80%)
- Room tariff slab boundaries; restaurant rate standalone vs in-hotel; works contract rate
- HSN digit requirement by turnover bracket
- Credit note tax deadline (30 November following the financial year)

---

## Suggested next steps

1. Build **GST Summary + CA export** — completes the spec
2. Device-test all four mockups before anything is marked *Tested*
3. Update `quotations.html` to milestone-based conversion
4. Vocabulary pass across all mockups against the §0 table
5. Reseed the MVP tracker — still outstanding from earlier sessions
