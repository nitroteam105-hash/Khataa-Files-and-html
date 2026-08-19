# Ledgr Web Demo — Detailed Build Spec for Replit Agent

Paste everything below the line into Replit Agent. Goal: a clickable, mobile-friendly web demo of a billing tool for small Indian service businesses (sign-board makers, welders, carpenters) to collect owner feedback. Demo only — the real product will be a mobile app later.

---

Build a single-page **web app** called **Ledgr** (working title), mobile-first (max-width 480px, centered), that works smoothly in a phone browser.

## Purpose
A billing "digital diary" demo for a small Indian job/service business: save customers → make quotes → convert to invoices → record payments → see totals. A non-technical shop owner must be able to click through in 2 minutes without instructions.

## Tech constraints
- Frontend only. No login, no accounts, no server DB. Use localStorage so data survives refresh.
- Vanilla JS or React — whichever you build most reliably. Single deployable app with a public share link.
- All currency in Indian Rupees with Indian digit grouping (₹1,20,500). Dates as 24 Jun 2026.

## Design
- Clean, minimal, card-based. Background #fbfbf9, ink #16161a, accent green #1f6f54, soft green #e8f3ee, light border #e7e7e2, danger #b3261e, amber #b36b00.
- Font: system sans or Plus Jakarta Sans for headings. Rounded corners (12px), generous tap targets.
- Bottom nav with 4 tabs: **Customers · New Bill · Bills · Summary**.

## CRITICAL: Demo mode (first-run experience)
On first load, pre-seed localStorage with a sample business "Apex Signs & Fabrication" containing:
- 3 customers: "Ravi Kumar" (Individual), "Hotel Sunshine" (Company, GSTIN 29ABCDE1234F1Z5), "Girija Arts" (Individual)
- 2 saved bills: one QUOTE (Hotel Sunshine, "Glow sign board 8x4 ft" qty 1 × ₹18,500), one INVOICE marked partially context: (Ravi Kumar, "Steel gate fabrication" 1 × ₹22,000 + "Installation" 1 × ₹1,500, status Unpaid)
- A dismissible banner at top: "This is sample data — try adding your own customer or bill."
The owner must land in a working, populated app — zero setup.

## Screen 1 — Customers
- List of customer cards: name, phone, type tag (Individual / Company), and total pending amount if any.
- "+ Add customer" opens a bottom-sheet form: Name (required), Phone, Type toggle (Individual | Company). If Company → show GSTIN and Company address fields.
- Tapping a customer shows their bills and total paid/pending.

## Screen 2 — New Bill (the core)
- Top toggle: **Quotation | Invoice**.
- Customer picker: dropdown of saved customers + "New customer" inline option.
- Line items: rows of [Description | Qty | Rate] with auto Amount = qty × rate. "+ Add item" adds rows; ✕ removes. Live Subtotal.
- **GST toggle (off by default).** When ON: a GST % field (default 18) → shows GST amount and Grand Total. If customer is a Company, print both GSTINs on the bill preview (seller GSTIN hardcoded demo value).
- Optional Note field (prints on bill).
- Save → stores the bill, assigns number (QT-001 / INV-001 series), goes to bill preview.
- **Bill preview**: clean printable card — business name & phone (hardcoded demo header), bill number & date, customer details, items table, subtotal/GST/total, note. Buttons: "Share on WhatsApp" (wa.me link with plain-text bill summary) and "Back".
- **Footer line on every bill preview & WhatsApp text: "Made with Ledgr — free billing diary".**

## Screen 3 — Bills
- List of all quotes & invoices, newest first: number, customer, date, total, status chip (Quote / Unpaid / Paid).
- Tap a QUOTE → view + button "Convert to Invoice" (creates INV copy, links them).
- Tap an INVOICE → view + "Record payment" (amount field, defaults to balance; supports partial payments; shows Paid ₹X / Balance ₹Y; status flips to Paid when balance = 0).

## Screen 4 — Summary
- 4 stat cards: Total invoiced, Received, Pending, Quotes open.
- Under it, a short list of unpaid invoices ("Who owes me") with amounts.

## Behavior rules
- Only customer name and one line item required — never block on optional fields.
- Confirm dialog ONLY for destructive actions (delete). Everything else one tap.
- Empty states with friendly hints ("No bills yet — make your first quote").
- Everything must actually work end-to-end: add customer → new quote → convert → record partial payment → summary updates.

## After building
Give me the public shareable link and a one-line summary of anything you couldn't implement.
