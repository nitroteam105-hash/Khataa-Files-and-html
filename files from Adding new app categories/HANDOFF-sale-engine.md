# Khaata — SALE Engine (Retail / Counter Billing) · Handoff

*Written 2026-07-20. Hand this + `DECISION-capability-model.md` to a fresh chat to continue. Companion to `HANDOFF-civil-build.md` (a different engine).*

---

## 1. What this covers
The **SALE engine** — counter sales / retail billing for shops (grocery, hardware, pharmacy, general, etc.). Built as single-file HTML mockups, capability-driven like the rest of the app. All files in `/mnt/user-data/outputs/`.

The bill generator itself is **built separately by Mr. T** and will be integrated — it is NOT in these files. Everything here is the surrounding engine (setup, items, dashboard, statements) plus the specs the bill generator must honour (§5).

---

## 2. Screens built this session (outputs/)

| File | What it is | Key behaviours |
|---|---|---|
| `shop-onboarding.html` | Shop setup, **three depth tiers** | Simple (name+phone) / Standard (+address, GST toggle, shop type) / Complete (+logo, GSTIN, capabilities, bill prefs, documents). Shop type **presets** capabilities (grocery/hardware/pharmacy/general/electronics/other), owner overrides (PRESET→CHANGED tags). "Other" shop type → **name-your-own** with neutral defaults. Not locked — a Simple shop can level up later. |
| `item-onboarding.html` | Add **and** Edit item (one form, mode toggle) | Capability-gated fields (GST, stock). Pricing: selling (req) + MRP + cost (optional, margin-aware). GST: rate chips + **tax inclusive/exclusive** with live CGST/SGST breakdown. **Barcode scan-to-fill.** **Multi-unit** (base unit + sell-units w/ own price + conversion factor; one stock pool). Learn-a-unit/category. Edit mode: pre-filled, "Update", archive, history peek. |
| `items-list.html` | Item catalogue — the route to Edit | Search (name/barcode) + scan. Category chips + grouping (if categories on). **Low/out-of-stock view** (if stock on). Rows show price + stock w/ flags + multi-unit tag. Tap → edit. Inline **± stock adjust**. + Add. Capability-aware throughout. |
| `shop-dashboard.html` | Shop home / daily driver | Today's sales hero + cash/UPI/udhaar split. **New Bill** primary button. **Attention strip** (low-stock reorder, udhaar to collect) — capability-gated. Week trend bars. Quick tiles (Items/Add/Bills). Recent bills w/ **print/share** sheet (Thermal/WhatsApp/A4). |
| `monthly-statement.html` | Two statements (mode toggle) | **Shop summary:** sales, payment split, **GST collected for filing** (CGST/SGST/IGST, capability-gated), top sellers. **Customer statement:** running khaata (opening→bought→paid→closing), dated activity, amber "to collect" / green "settled", **Send on WhatsApp**. |
| `items-quick-add.html` | Bulk item entry (retail) | Batch defaults (category + GST rate + unit) set once, inherited by all rows. Fast rows = name + price (+ stock column if stock on). Per-row **＋ more** expands to MRP / cost / HSN / multi-unit packs. Save-all with running count. Capability-aware. For fast initial-catalogue setup. |
| `food-item.html` | Food menu item (single, detailed) | Food framing of the item page: name + price, **variants** (plain/masala/cheese, each priced, one default), **add-ons** (+extra cheese), category. No goods fields (MRP/barcode/HSN/multi-unit). Sold-out is NOT here — it's a menu/billing action. |
| `food-quick-add.html` | Bulk menu entry (food) | Batch category, fast rows = name + price, per-row expand to variants/add-ons. Save-all with count. The fast way to set up a whole menu. |
| `items-import.html` | Import catalogue from file | 4-step wizard: upload CSV/Excel → **auto-guess column mapping** → **preview with problem-flagging** (missing price/name → skipped) → import. Simple fields only (name/price/category/stock/GST); variants/multi-unit stay manual. Capability-aware. The barrier-remover for shops switching from Vyapar/KhataBook/spreadsheets. File parsing is real native code — mock shows the flow. |

---

## 3. The engine flow
```
shop-onboarding  (sets capabilities: GST / stock / categories / udhaar)
      │
      ▼
shop-dashboard ──New Bill──► [BILL GENERATOR — Mr. T's, to integrate]
      │                              │ (writes bills)
      ├── items-list ──tap──► item-onboarding (add/edit)
      │
      └── monthly-statement (shop summary + customer statement)
```
Capabilities set once at onboarding drive what every screen shows. The bill generator is the hub that consumes items and produces bills, sales figures, stock decrements, and udhaar.

---

## 4. Decisions locked this session

- **Capability-driven, not tiered builds.** One item page, one list, one dashboard — they show more/less by capability (GST, stock, categories, udhaar). A paan shop and a GST hardware store use the *same* screens at different depths. No separate "simple app."
- **Tax: inclusive OR exclusive, per item, defaulting from business.** Live CGST/SGST breakdown so it's never mysterious. CGST/SGST/IGST are **derived**, never entered.
- **Discount is bill-time, NOT an item property.** Item has MRP + selling price; the gap is the visible discount. Discounting happens on the bill.
- **Multi-unit = one stock pool in the base unit.** Sell-units (box/piece) each have own price + conversion factor. Selling any unit converts to base for stock (1 box = −25 pieces). Availability *displayed* both ways ("19 boxes + 15 loose") but maintained as one honest number. Optional per item — off by default. (Rejected: separate box/piece counters — they drift from reality.)
- **Category AND shop-type: optional + universal + learnable.** No grocery-specific seed. Start empty/neutral, grow from what the owner types (pick-or-add-and-remember). "Other" always lets you name your own. Category never blocks saving.
- **Add + Edit = one form, two modes.** Not two pages (avoids drift). Edit adds pre-fill, Update, archive (archive-first), history. Same pattern for React Native: `mode="add"|"edit"`.
- **Three-tier onboarding depth** (Simple/Standard/Complete) — user chooses how much to set up now; never locked, can level up later.
- **Customer statement = the udhaar ledger, monthly + shareable.** Not a separate data store — reads the same customer credit data.
- **"Pick-or-add-and-remember" now also covers units, categories, shop types** (extends the app-wide standard from the civil session — materials/charges/sources/stages).

---

## 4a. Food stall — a business TYPE on the SALE engine (not a new engine)
Validated this session: a food stall runs on the SALE engine unchanged — billing, dashboard, monthly statements all work as-is. Only the **item shape** differs, via capabilities. "Food stall" becomes a business type presetting:
- **ON:** variants (plain/masala/cheese, each own price, one default), add-ons/extras (+cheese), sold-out toggle
- **OFF:** the goods fields — MRP, barcode, HSN, multi-unit packs, precise stock counting
- **Sold-out replaces stock.** Food doesn't count inventory ("23 dosas left") — it tracks daily availability ("out of idli today"). **Critical placement decision: sold-out is NOT an onboarding field.** Onboarding defines what a dish *is* (permanent); sold-out is daily operational state, so it lives on the **menu list / billing screen** as a one-tap action. (Same principle as "setup configures, never populates.")
- Optional table/token number deferred (sit-down cafés, not stalls).

This is the capability model's proof point: a very different business (food) drops in as a preset bundle, reusing the entire billing/reporting engine. Same as hardware presets stock+categories.

## 4b. Bulk item entry — both engines
Onboarding many items one-at-a-time is the friction that kills setup. Both engines now have a **quick-add** (bulk multi-row) tool alongside the detailed single-item form:
- **Rows stay minimal** (name + price) for the fast 90%; **batch-level defaults** (category always; +GST rate +unit for retail) set once and inherited; **per-row expand** for the rare complex item (variants/add-ons for food; MRP/cost/HSN/multi-unit for retail).
- Retail adds an **optional stock column** (if stock on) so opening qty is entered in the same pass.
- Same interaction pattern across both engines — deliberately, for coherence.
- **Two tools, two jobs:** quick-add for initial-catalogue setup (many at once), detailed form for adding/editing one item carefully later.

**Three on-ramps for item entry** (each for its moment): **detailed form** (one item, full care — variants/multi-unit), **quick-add** (type many fast), **import** (bring a whole catalogue from a file). All land in the same "batch saved" destination. Import is the one that wins users off competitors — it removes the re-typing barrier.


The bill generator exists separately; when integrating, these rules keep it consistent with the engine:

1. **Snapshot at sale time.** Each bill stores its own copy of item price + tax rate + unit at the moment of sale. This is why "edit item anytime" is safe — changing an item later never alters past bills. Critical for GST integrity.
2. **Scan-to-add.** Scanning a barcode adds the item to the cart (increment qty if already present). **Unknown barcode → offer quick-add** (onboard the item on the spot) so a busy counter never stalls.
3. **Multi-unit at billing.** User picks which sell-unit; price + stock decrement follow that unit's factor.
4. **Bill-time discount** (line and/or bill level) — the discount that was deliberately kept off the item.
5. **Writes back:** decrements stock (base units), feeds today's sales + payment split (dashboard), GST collected (statement), and customer udhaar (if credit sale).
6. **Complete-sale step offers Print / Share** — see §6.

---

## 6. Phase-2 hardware: printing (designed now, wired later)
Quick-print to bill printers is real and expected, but is **native, real-device code — cannot be prototyped in HTML** (browsers can't reach Bluetooth thermal printers). Designed into the dashboard/bill print sheet now; built in React Native later.
- **Thermal receipt (58/80mm, Bluetooth ESC/POS)** — the primary counter quick-print. Fiddly, printer-model-dependent formatting; budget real effort.
- **WhatsApp / PDF** — the no-hardware fallback many shops actually use.
- **A4 / system print** — formal GST tax invoice.
Flagged "Phase 2" in the mockups' print options.

---

## 7. Still open / next steps
- **Bills history / list** — past bills, search, view, reprint. May already exist in Mr. T's bill generator — confirm before building.
- **Customer / udhaar screens** — the customer list + per-customer running ledger (the statement reads from this). Overlaps with civil's customer concept; unify in real code.
- **GSTR-ready export** — the monthly GST summary is display-level; real filing export is build-phase tax logic.
- **Business-type category seeds** — optionally seed starter categories from shop type (hardware → Plumbing/Electrical…) as editable suggestions, wired at onboarding.
- Real-code phase: all of this → React Native (Expo) + SQLite; capabilities persist per business; learned lists (units/categories/shop-types) persist per business.

---

## 8. Design system
Same as civil: green `#1f6f54`, parchment `#fbfbf9`, Plus Jakarta Sans + Inter, single-file vanilla, ~480px mobile width. Money-affecting actions confirm; neutral ones don't. "Suggestions, not restrictions" — presets/defaults always editable. Capability toggles in the mockups are demo stand-ins for what shop-onboarding really sets.
