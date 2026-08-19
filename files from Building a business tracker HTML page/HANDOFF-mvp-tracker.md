# HANDOFF — MVP Screen Tracker

**File:** `khaata-mvp-tracker.html` (single file, vanilla HTML/CSS/JS, no build step)
**Purpose:** Track build status of every MVP screen, and derive which business types are shippable as a result.
**Status:** Built. Not yet verified on a physical device.

---

## 1. What this replaces

Nothing in the repo. It sits alongside `BUILD-ORDER.md`, answering a different question:

| Tool | Question it answers |
|---|---|
| `BUILD-ORDER.md` | What do I build next? |
| This tracker | Which business types can I actually ship? |
| Miro kanban | What does the flow look like? |

Do not duplicate screen status into Miro. This file is the source of truth for status; Miro stays visual-only (and its connector is create-only anyway).

---

## 2. Data model

Three inputs, all inlined as constants at the top of the `<script>`:

- **`SCREENS`** — 64 rows: `[name, section, marks, seedStatus]`
- **`BIZ`** — ~250 business types grouped by category: `"Name|ENGINE|stars"`
- **`ENGINES`** — `["SUB","APPT","EVENT","JOB","SALE"]`, fixed order

### The marks string

`marks` is exactly 5 characters, one per engine in `ENGINES` order:

| Char | Meaning |
|---|---|
| `C` | Core — always on for this engine |
| `N` | On by default in the preset |
| `F` | Off by default, available |
| `X` | Not offered |

Example: `"CFXXX"` = core for SUB, off-by-default for APPT, not offered elsewhere.

Both `SCREENS` and `BIZ` were transcribed from `Khaata-Screen-Matrix.md` and
`Khaata-Business-Categories.md`. **Those two docs remain the upstream source.** If a
screen or business type is added there, add it here too — nothing syncs automatically.

---

## 3. The MVP line is derived, not listed

```
a screen is in MVP  ⟺  it is marked C for at least one engine in S.mvpEngines
```

`S.mvpEngines` currently = `["SUB","JOB"]`. The engine chips in the UI are live —
toggling one recomputes the MVP set instantly. This is deliberate: it makes scope
creep visible as a number rather than a vibe.

**Consequence already noted:** JOB marks the entire staff block (list, attendance,
payout, advance) plus quotation as core. Including JOB in MVP is therefore ~7 screens
more expensive than SUB alone. If build order is ever revisited, this is the reason
JOB business types show lower readiness than SUB ones.

---

## 4. Status model

Ladder, in order: `GAP → Specced → Mockup → Built → Tested`

- `Tested` means **passed on a real physical device**, not a simulator. Same gate as the rest of the project.
- Tap the chip on a row to advance one step; the detail sheet lets you jump directly.

### Per-business variation (sparse overrides)

Some screens genuinely differ by business type — PG settings (rooms, rent cycle,
electricity) is not shop settings (GST, counter, barcode). One global status for
"Business setup / settings" would report the shop as finished because PG was.

So:

1. Open the screen → toggle **Varies by business type** on. Sets `S.varies[screenName] = true`.
2. Open a business on the Businesses tab → tap that screen's chip to set a status
   for that business alone. Writes `S.overrides["screenName|businessName"]`.
3. Businesses you never touch keep inheriting the base status (shown as `↩`).

**Resolution rule:**

```js
effStatus(screen, business) = S.overrides[screen|business]  // if varies and set
                            ?? S.status[screen]             // otherwise base
```

**Completion rule** — a varying screen counts as done only when the base *and every
override* are done. So marking settings Built for PG alone does not inflate the
headline %; the header shows "N built, variants pending" in amber instead.

Design intent: all 250 businesses are individually editable, but nothing varies until
explicitly flagged. A dense 250 × 64 grid requiring manual entry would be abandoned
within weeks; sparse overrides keep the maintenance cost proportional to real divergence.

Switching `Varies` off discards that screen's overrides, behind a confirm.

---

## 5. Business readiness

Per business type, over the screens its engine marks `C` or `N`:

- **pct** = done ÷ required (drives the conic-gradient ring; green ≥80, ochre ≥40, else terracotta)
- **core left** = required-and-core screens not yet done — the real launch blocker count
- **own** = how many statuses have been overridden for that business

A business is shippable when `core left = 0`. The `pct` figure is softer — it includes
`N` screens, which are on-by-default but not strictly blocking.

---

## 6. Notes

Append-only, timestamped (`en-IN` format), two scopes:

- **Per screen** — defects, decisions, open questions
- **Per business** — preset tweaks, label overrides, field defaults

Append-only rather than a single editable field, matching the project's
store-events-derive-summaries rule: the history of when something was flagged and
when it was resolved is the useful part. Individual notes can be removed.

---

## 7. Persistence and export

- **Storage:** `localStorage`, key `khaata-mvp-tracker-v1`. Device-local, no sync.
- **Export JSON** — full state; the real backup. **Import JSON** merges over defaults, so older exports missing newer keys still load.
- **Export CSV** — flat sheet for Excel. Emits one `(base)` row per screen plus one row per override, so the sheet matches the app rather than hiding variants.
- **Reset** — back to seeded statuses, behind a confirm.

Bump the storage key if the shape of `S` ever changes incompatibly.

---

## 8. Design conformance

Modern Ledger, per project standard: parchment `#f4f3ee` family, forest green
`#1f6f54` sparingly, ochre for in-progress/attention, terracotta for danger, SVG-filter
grain, 18px card radius, Plus Jakarta Sans headings / Inter body, `prefers-reduced-motion`
respected on the sheet transition. State-object + render-function architecture. All
user-generated strings pass through `esc()`.

---

## 9. Open items

- [ ] **Verify on a physical device.** Two things to watch: the readiness ring uses `conic-gradient`, and the detail sheet is a bottom-slide transform.
- [ ] **Reseed statuses.** Seed values came from the screen matrix and are already stale — the build has moved on. Needs a pass to set actual current status, and to flag which screens are genuinely PG-specific vs shared.
- [ ] Decide whether `Tested` needs a following `Verified` step after a defect round, or whether one terminal state is enough. Currently one.
- [ ] Screen list will drift from `Khaata-Screen-Matrix.md` over time. No sync — worth a periodic diff.
