# Replit Agent Brief — Ledgr Web Demo (for owner reviews)

Paste the block below into Replit's Agent. Purpose: a small, clickable web demo of the job/service billing wedge to show small-business owners for feedback. Validation only — not the real product (that will be a mobile app later).

---

## PASTE THIS INTO REPLIT AGENT

> Build a simple, mobile-friendly **web app** (single-page, works well on a phone browser) called **Ledgr** — a billing tool for small Indian service businesses (e.g. a sign-board maker or welder). This is a clickable DEMO for getting user feedback, so keep it clean, simple, and working end-to-end. No login needed. Store data in browser memory (or a simple in-memory store) — no complex backend required.
>
> **Design style:** clean and minimal. Green accent (#1f6f54), off-white background (#fbfbf9), rounded cards, sans-serif fonts. Mobile-first (max width ~480px, centered). Currency is Indian Rupees (₹), use Indian number format (e.g. ₹1,20,000).
>
> **Build these 4 connected screens with a bottom or top nav:**
>
> 1. **Customers** — a list of saved customers. A "+ Add customer" form: name, phone, type (Individual or Company). If Company, also show GSTIN field. Saved customers appear in the list and can be picked later when making a quote/invoice.
>
> 2. **New Quote/Invoice** — pick a saved customer (or add new). A toggle at top: "Quotation" or "Invoice". Add line items (description, quantity, rate) — each row auto-calculates amount (qty × rate). Show running subtotal. Optional GST toggle: when on, add a GST % field and show tax + grand total. A "Save" button stores it.
>
> 3. **Bills list** — shows all saved quotes and invoices with customer name, date, total, and status (Quote / Unpaid / Paid). Tapping one opens it. On an invoice, a "Record payment" button marks it Paid.
>
> 4. **Summary** — simple totals: total invoiced, total received (paid), total pending (unpaid). Just a few numbers in cards.
>
> **Keep it simple:** no user accounts, no real payment processing, no server database needed — in-memory/browser storage is fine for a demo. Prioritize a smooth, obvious click-through: add customer → make quote → convert/save invoice → record payment → see it in summary. Make it feel real and easy for a non-technical shop owner to try.
>
> After building, give me a shareable public link I can send to people to test.

---

## After Replit builds it — how to use for reviews
1. Get the shareable link.
2. Send to your warm leads (sign-board, welder) with: "Made a small tool for billing — can you try it 2 min and tell me if it's useful?"
3. Watch/ask: Was it clear? What's missing? Would you use this? Would you pay ₹199/mo?
4. Note feedback → shapes the real mobile MVP.

## Remember
- This web demo = VALIDATION only. The real product is a mobile app (Expo + Supabase) built later.
- Don't keep expanding the web demo into "the product." Test → learn → build the mobile app.
- Match your existing designs (job-quote-invoice.html, bill-generator.html) for reference if Agent asks.
