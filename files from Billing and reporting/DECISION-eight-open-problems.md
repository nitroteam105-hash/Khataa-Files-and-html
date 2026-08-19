# DECISION — Eight open problems, proposed resolutions
**Status:** All eight **agreed** on 11 Aug 2026. Folded into `SPEC-billing-records-gst.md`. Kept for the reasoning trail.
**Context:** Raised during review of the billing/GST spec and the quotations + adjustments mockups.

Mark each: **Agreed** / **Change** / **Discuss**

---

## 1. Milestone billing — one mechanism, not two

**Problem.** Quotations converts partially by picking *lines*. Civil bills by *stage*. Coaching bills by *installment*. Three mechanisms for one act: "bill for the part that's due."

**Why the line-picker alone is wrong.** A signboard job is rarely billed by line. It's billed *50% advance, 50% on completion* — a percentage of the whole, not a subset of items. Line-picking can't express that.

**Proposal — a billing plan on the job, with three bases.**

```
job_milestones
  id, business_id, job_id, seq, name,
  basis         -- pct | amount | lines
  pct_bp        -- basis points of job value
  amount_paise
  line_ids      -- json array
  due_date      -- optional, for scheduled installments
  status        -- pending | ready | invoiced
  bill_id       -- set when invoiced
```

Every existing pattern becomes one shape:
- *50% advance / 50% on completion* → two `pct` milestones
- *Board now, installation next month* → two `lines` milestones
- *Foundation / slab / plaster* → three `pct` or `amount` milestones tied to civil stages
- *Monthly installments* → `amount` milestones with due dates
- *Bill it all at once* → one auto-created milestone, **never shown**

**Guards.** Milestones must sum to exactly the job value — `pct` rounding uses the largest-remainder method, and the final milestone absorbs any drift so the job bills to the contract value to the paise.

**What changes.** The quotations convert sheet swaps its line-picker for a milestone picker. Civil's stage billing points at the same table instead of its own.

**If you disagree:** keep line-picking for JOB and stages for civil, and accept two code paths that drift apart.

---

## 2. `job_id` — the missing spine

**Problem.** A quote, its advance, three milestone invoices and a final credit note are currently five unconnected rows that happen to share a customer name. Nothing in the spec ties them together.

**Proposal.**
- Add nullable `job_id` to `bills`. Null for SALE/counter bills — this costs nothing there.
- **An accepted quote creates the job.** The quote's total becomes the job's contract value. Advances, milestone invoices and adjustments all inherit `job_id`.
- The job becomes the money unit for JOB-engine work: *quoted → advanced → invoiced → received → outstanding*, on one screen.

**Why it matters beyond tidiness.** "How much is left on the Ashwin Motors job?" is currently unanswerable. It's the single most common question a signboard or civil owner asks.

---

## 3. Vasooli — one list, and I was wrong about what feeds it

**Problem.** Three screens each own a slice of "money that hasn't landed," and nothing adds them up.

**Correction to my own earlier point.** I listed unadjusted advances as a follow-up item. That's backwards — an unadjusted advance is money **you hold** and owe work against. It is not something to chase. It belongs in a separate "held for work" tile, and it's a data-quality flag for the CA export, not a Vasooli row.

**Proposal — the follow-up list has exactly three sources:**

| Source | The ask |
|---|---|
| Issued bills unpaid or part-paid past terms | Chase the payment |
| Sent quotes with no reply past threshold | Chase the decision |
| **Completed milestones never invoiced** | Raise the bill |

The third is new and I think it's the strongest of the three. Work finished and never billed is pure leakage, invisible in every notebook, and only findable once §1 and §2 exist.

**Implementation.** One derived view — `type, party, job, amount, age, suggested_action`. Each screen's hero becomes a filter over that one view, not its own calculation. Advances get a separate, quieter tile: *"₹57,400 held against work not yet done."*

---

## 4. Vocabulary — plain words in the app, GST words on the document

**Problem.** "Notes & vouchers," "receipt voucher," "place of supply" is Tally's language. A notebook user says *he returned it* and *he paid something in advance*.

**Proposal — two layers, strictly separated.**

| The owner sees | The document says |
|---|---|
| Customer returned something | Credit Note |
| Charged too little / extra work done | Debit Note |
| Took money before the work | Receipt Voucher |
| Where the work happens | Place of Supply |
| Charged too much | Credit Note |

**Structural change.** These become **actions on a bill**, not a top-level destination. You open the Suresh Traders bill and tap *Customer returned something*; the app decides it's a credit note, picks the series, mirrors the rates, and prints it correctly. The adjustments hub still exists under Records for anyone who thinks in documents, but it stops being the front door.

**Rule to lock:** GST terminology appears on printed output and in CA export headers. Nowhere else.

---

## 5. Numbering — several series per business

**Problem.** The spec locked one series per doc type per year. A hotel running rooms and a restaurant, or a shop with three counters, breaks that on day one. Multiple series are legal as long as each is internally consecutive.

**Proposal.**
- `bill_number_series` gains `name` and `is_default`; a business may hold N series per doc type per financial year
- **Default is one series, and it's invisible** — no picker, no setup step
- Auto-created second series when `has_rooms && has_food`
- A staff member can be bound to a series in Team Access, so their bills always land in their counter's run
- Series picker appears at issue **only** when more than one exists

---

## 6. Mixed place of supply — I had this wrong too

**Problem.** I specced "block issue and prompt to split." A signboard firm billing design work plus on-site installation would hit that on an ordinary invoice.

**The actual answer isn't a better warning — it's that most of these aren't mixed at all.** Design plus fabrication plus installation, sold together as one signboard, is a **composite supply**: naturally bundled, taxed as the principal supply, one place of supply for the whole invoice.

**Proposal.**
- `pos_rule` resolves at the **bill level** from the principal line — highest taxable value — not per line
- Where lines disagree, show a quiet note: *"Taxed as one supply, following the signboard installation."* No block.
- Offer **Split into two bills** as a one-tap action for genuinely separate supplies
- Only block when the owner explicitly marks lines as separate supplies

This is simpler than what I specced, non-blocking, and closer to how the law actually treats bundled work.

---

## 7. The unregistered path has never been walked

**Problem.** Most of this session served registered businesses. The notebook user we're aimed at is unregistered, and I have not once traced their flow end to end to check it stayed simple.

**Proposal — a rule, then an audit.**

> **Every GST-driven field is additive on top of the plain flow. Never a default, never a hidden-but-present field.**

For `unregistered`, these do not exist: HSN, place of supply, tax columns, series picker, receipt vouchers, the adjustments hub. A return simply reduces what's owed and prints a plain credit note with no tax. Advances are money-in events, nothing more.

**Onboarding:** unregistered is the pre-selected default, not one of three equal choices.

**Action:** before the bills list is built, walk the full unregistered flow — onboarding → item → bill → payment → return → month-end — and cut anything that appears without needing to.

---

## 8. Nothing has been seen on a device

Both mockups are jsdom-tested for logic only. That is not your verification gate. Nothing here should be marked *Tested* until it has run on a physical screen — and the two mockups are dense enough that I'd expect real layout problems at 360px.

---

## Sequencing, if the above is agreed

1. §1 and §2 first — both change the `bills` table, and the bills list reads it
2. §4 and §6 next — both cheap, both change screens already mocked
3. §7 audit before the bills list is designed
4. §3 once §1 exists, since uninvoiced milestones depend on it
5. §5 whenever multi-counter or hotel work starts

---

## Where I expect you to push back

- **§1** is the expensive one. It adds a table and touches civil, which is already built.
- **§4** demotes a screen I just built. That's fine — better to move it now than after it ships.
- **§7** may cut features you want, since simplifying the unregistered path means the free tier gets thinner.
