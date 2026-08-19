# PG Building Configurator — Full Development Handoff

## What This Is
A single-page interactive web app where a PG/hostel owner visually configures their property. The owner walks through 4 steps (plus a review), and a live SVG blueprint drawing updates in real time as they input data. The output is a structured JSON object representing the owner's entire property — buildings, floors, rooms, names, and occupancy — ready to feed into a backend.

This is the **owner onboarding screen** — the first thing an owner does when they sign up. Every feature in the app (rent tracking, tenant management, deposits) depends on this property structure existing first.

---

## Product Context
- **User:** PG/hostel owners in India (often managing 1–3 buildings, 10–100 tenants)
- **Device:** Desktop-first, but must be responsive down to mobile (380px)
- **Tech:** Single self-contained HTML file. No frameworks, no build step. Vanilla HTML + CSS + JS. SVG for the building drawing. Google Fonts loaded via CDN.
- **Persistence:** None in MVP (data lives in memory only). The JSON export on the review page is the output. Future: save to backend on "Confirm."

---

## Layout Structure

```
┌──────────────────────────────────────────────────┐
│  HEADER (logo + title + "MVP prototype" badge)   │
├──────────────────────────────────────────────────┤
│  STEP RAIL (4 step tabs: Buildings → Floors →    │
│  Rooms → Details, plus a Review tab at end)       │
├──────────────────┬───────────────────────────────┤
│                  │                               │
│   LEFT PANEL     │     RIGHT PANEL               │
│   (controls,     │     (live SVG blueprint        │
│    inputs,       │      drawing of the            │
│    lists)        │      property)                 │
│                  │                               │
│   Fixed width:   │     Flexible width,            │
│   340px          │     horizontally scrollable    │
│                  │                               │
├──────────────────┴───────────────────────────────┤
│  FOOTER BAR (← Back | running totals | Next →)   │
└──────────────────────────────────────────────────┘
```

- On screens < 880px, the two-column grid stacks vertically (panel on top, canvas below).
- The canvas area should be horizontally scrollable when the drawing is wider than the viewport.

---

## Design Tokens

### Colors
| Token | Hex | Usage |
|---|---|---|
| --ink | #0B2E4F | Primary background |
| --ink-deep | #071F38 | Card/panel backgrounds |
| --ink-deeper | #051628 | Input field backgrounds |
| --paper | #EAF4FB | Primary text color |
| --paper-dim | #A9C7DF | Secondary/muted text |
| --line | #3E6E96 | SVG floor band strokes |
| --line-soft | #274F70 | Borders, dividers, dashed lines |
| --accent | #FF8A3D | Primary action color (buttons, highlights, selection) |
| --accent-soft | #FFD9B3 | Accent for badges, subtle highlights |
| --accent-deep | #E0701F | Button hover state |
| --ok | #6FCF97 | "Done" / completed state indicator |

### Typography
| Role | Font | Weight | Size |
|---|---|---|---|
| Display / headings | Space Grotesk | 600–700 | 18–26px |
| Body / UI text | Inter | 400–600 | 12–14px |
| Mono / labels / tags | IBM Plex Mono | 400–600 | 9–12px |

Load via Google Fonts:
```
https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@500;600;700&family=Inter:wght@400;500;600&family=IBM+Plex+Mono:wght@400;500;600&display=swap
```

### Spacing & Radius
- Border radius: 12px for cards, 8–9px for inputs/buttons, 99px for pills/badges
- Card padding: 22px
- Grid gap between panel and canvas: 16px

### Background
The page background has a subtle CSS grid pattern overlay (28px squares, very faint blue lines) on top of the --ink base color, giving a blueprint/drafting-table feel.

---

## State / Data Model

```javascript
state = {
  step: 1,                    // Current step (1–5, where 5 = review)
  maxStepReached: 1,           // Highest step visited (controls which rail tabs are clickable)
  buildings: [                 // Array of building objects
    {
      id: "b_abc123",          // Unique ID
      name: "Building 1",      // Display name
      floors: [                // Array of floor objects
        {
          id: "f_xyz789",      // Unique ID
          rooms: [             // Array of room objects
            {
              id: "r_def456", // Unique ID
              name: "101",     // Room name/number (max 12 chars)
              occupancy: 1     // Number of beds (1–8)
            }
          ]
        }
      ],
      activeFloorIndex: 0,     // Which floor is currently selected in this building
      floorsStage: false,      // Has the owner configured floors for this building?
      roomsStage: false,       // Has the owner configured rooms?
      detailsStage: false      // Has the owner configured room details?
    }
  ],
  activeBuildingIndex: 0       // Which building is currently selected
}
```

### Default Values
- New building: 1 floor, 1 room per floor, occupancy = 1
- Default room name: floor number + room index, zero-padded (e.g., Floor 3, Room 2 → "302")
- Max buildings: 8
- Max floors per building: 15
- Max rooms per floor: 12
- Max occupancy per room: 8

### JSON Export Format (what the backend receives)
```json
[
  {
    "name": "Building 1",
    "floors": [
      {
        "floor": 1,
        "rooms": [
          { "name": "101", "occupancy": 2 },
          { "name": "102", "occupancy": 3 }
        ]
      },
      {
        "floor": 2,
        "rooms": [
          { "name": "201", "occupancy": 1 }
        ]
      }
    ]
  },
  {
    "name": "Building 2",
    "floors": [...]
  }
]
```

---

## Page-by-Page Specification

### PAGE 1 — Buildings

**Purpose:** Owner declares how many buildings they have.

**Left panel contents:**
- Tag: "Sheet 01" (mono font, accent color, uppercase)
- Heading: "Buildings"
- Subtext: "How many buildings are you setting up?"
- Stepper control: − button | number input | + button | unit label ("buildings")
  - Range: 1–8
- Hint text: "Each building appears on the drawing as a simple plot. You'll configure floors and rooms for each one over the next steps."

**Right panel (SVG drawing) behavior:**
- For each building, draw a **dashed rectangular outline** (a "plot") with a small dashed triangular roof on top and a "?" character centered inside.
- Below each plot: a ground line with small diagonal hatching marks, and the building name ("Building 1", "Building 2"...) centered underneath.
- Buildings are arranged side-by-side horizontally with spacing between them.
- As the owner increases/decreases the count, plots appear/disappear immediately.

**Canvas tip text:** "Tip: pick a number on the left — each building appears here as a simple plot."

**Footer:** ← Back (disabled) | running totals | Next: Floors →

---

### PAGE 2 — Floors

**Purpose:** Owner sets how many floors each building has.

**Left panel contents:**
- **Building tabs** (only shown if 2+ buildings): horizontal row of tab buttons, each showing a colored dot (empty = not started, orange = in progress, green = done) and the building name. Active tab is highlighted. If < 8 buildings, show a dashed "+ Add" tab.
- Tag: "Sheet 02"
- Heading: "Floors"
- Subtext: "How many floors does **Building X** have?"
- Stepper control: − | number | + | "floors"
  - Range: 1–15
- Hint text: "Floor 1 is the ground floor. Switch tabs above to set floors for another building."

**Right panel (SVG drawing) behavior:**
- The active building's dashed plot transforms into a **real building drawing**: stacked horizontal floor bands, each labeled (F1, F2, F3...) on the left margin.
- A small solid rectangular roof cap sits on top of the building.
- The ground line and hatching remain below.
- Other buildings that haven't been configured yet still show as dashed plots with "?".
- If multiple buildings exist and one is active, draw a dashed orange border bracket around the active building to highlight it.
- As the owner increases/decreases floor count, floor bands appear/disappear immediately.

**Canvas tip text:** "Tip: click a building tab on the left to switch which one you're drafting."

**Footer:** ← Back | running totals | Next: Rooms →

---

### PAGE 3 — Rooms

**Purpose:** Owner selects a floor and sets how many rooms it has. This is the first page where the owner **clicks directly on the SVG drawing** to interact.

**Left panel contents:**
- Building tabs (if 2+ buildings)
- Tag: "Sheet 03"
- Heading: "Rooms"
- Subtext: "Click a floor on the drawing, or pick one below, then set its room count."
- **Floor list:** vertical scrollable list of floor rows (buttons), each showing "Floor N" on the left and "X rooms" on the right. The active floor row is highlighted.
- Section divider: "Floor N — Rooms"
- Stepper control: − | number | + | "rooms"
  - Range: 1–12

**Right panel (SVG drawing) behavior:**
- All floor bands are now **clickable**. On hover, a floor band subtly highlights. On click, it becomes the active floor (updates the left panel).
- The active floor has:
  - An orange selection bracket (corner marks) around it
  - A small orange pill/callout floating above it reading "FLOOR 3 · 5 ROOMS"
- When rooms are set, the floor band visually **splits into cells** with thin vertical divider lines — one cell per room.
- Each floor can have a different room count.
- The building width adjusts to accommodate the floor with the most rooms.

**Canvas tip text:** "Tip: click a floor in the drawing to select it, then set its room count."

**Floor selection via drawing (critical interaction):**
1. Owner clicks a floor band rectangle in the SVG
2. That floor becomes the active floor
3. The left panel updates to show that floor selected in the list
4. The stepper shows that floor's current room count
5. Owner adjusts rooms → the floor band splits/merges cells in real time

**Footer:** ← Back | running totals | Next: Details →

---

### PAGE 4 — Room Details

**Purpose:** Owner names each room and sets its occupancy (bed count). Changes appear on the SVG drawing in real time as the owner types.

**Left panel contents:**
- Building tabs (if 2+ buildings)
- Tag: "Sheet 04"
- Heading: "Room details"
- Subtext: "Name each room and set occupancy — updates appear on the drawing as you type."
- Floor list (same as page 3, to switch floors)
- Section divider: "Floor N — X rooms"
- **Room rows:** scrollable list, one row per room on the selected floor. Each row contains:
  - Text input: room name (max 12 characters, mono font, pre-filled with default like "101")
  - Occupancy field: small number input (1–8) with "occ." label
- **Totals footer:** dashed top border, shows "X floors · Y rooms · Z beds" for the active building

**Right panel (SVG drawing) behavior:**
- Each room cell now shows:
  - **Room name label** centered in the cell (truncated to ~6 chars with ellipsis if longer)
  - **Occupancy badge** in the bottom-right corner of the cell (small circle with a number inside, orange stroke)
- **Live update:** as the owner types in the name field, the SVG label updates character by character. As they change occupancy, the badge number updates instantly. No re-render delay.
- **Click-to-jump:** clicking a room cell in the SVG drawing scrolls to and focuses that room's name input in the left panel (with a brief orange pulse animation on the input).
- Floor bands are still clickable to switch floors.

**Canvas tip text:** "Tip: click a room in the drawing to jump to it in the list on the left."

**Footer:** ← Back | running totals | Finish →

---

### PAGE 5 — Review

**Purpose:** Summary of everything. The owner sees their full property at a glance and can click anything in the drawing to jump back and edit it.

**Left panel contents:**
- Tag: "Review"
- Heading: "Your property"
- Subtext: "Everything drafted, in one view. Click anything on the drawing to jump back and edit it."
- **Stat cards:** 2×2 grid of cards, each showing:
  - Large accent-colored number
  - Small uppercase label
  - Cards: Buildings | Floors | Rooms | Bed capacity
- **"View structured data" button:** ghost/outline style. Toggles open a `<pre>` block showing the full JSON export (see data model above). JSON is formatted with 2-space indentation.

**Right panel (SVG drawing) behavior:**
- All buildings are fully drawn with all floors, room divisions, room labels, and occupancy badges.
- Everything is clickable:
  - Click a building → goes to Page 2 (Floors) with that building selected
  - Click a floor → goes to Page 3 (Rooms) with that floor selected
  - Click a room → goes to Page 4 (Details) with that room's input focused

**Canvas tip text:** "Tip: click any building, floor, or room in the drawing to jump back and edit it."

**Footer:** ← Edit details | running totals | Start over (with confirmation dialog)

---

## SVG Drawing Specification

### Canvas Setup
- Background: subtle grid pattern (24px squares, faint blue lines)
- SVG uses a dynamic viewBox — width grows as buildings are added, height grows as floors are added
- Horizontally scrollable container if drawing exceeds viewport

### Dimensions (constants)
| Element | Size |
|---|---|
| Room cell width | 42px per room |
| Floor band height | 48px |
| Gap between buildings | 70px |
| Left margin | 56px (space for floor labels) |
| Top margin | 34px |
| Bottom margin | 58px (space for ground line + building name) |
| Placeholder plot width | 92px |
| Placeholder plot height | 74px |

### Building width calculation
`building_width = 42px × max_rooms_on_any_floor`

### Drawing Elements

**Ground line:** Horizontal line below each building + 5–6 small diagonal hatching lines below it.

**Building name:** Centered below the ground line, mono font, muted color.

**Placeholder plot (unconfigured building):**
- Dashed rectangle (stroke-dasharray: 5 4)
- Small dashed triangular roof above it
- "?" character centered inside
- Fill: very subtle (3% opacity white)

**Floor band (configured building):**
- Solid-bordered horizontal rectangle, stacked from ground up
- Very subtle fill (4% opacity white)
- Floor label ("F1", "F2"...) to the left of the band, mono font, muted

**Roof:** Small solid rectangle sitting on top of the topmost floor band, 8px wider than building on each side, 7px tall, muted color fill.

**Room dividers:** Thin vertical lines inside a floor band, creating equal-width cells.

**Room label:** Mono font, 9px, centered horizontally in the cell, positioned near the top.

**Occupancy badge:** Small circle (radius 7.5px) in the bottom-right of each room cell. Dark fill, orange stroke. Number centered inside in mono font, 8px.

**Active floor indicators:**
- Selection bracket: 4 corner marks (L-shaped lines) around the floor band, orange color, 2px stroke
- Callout pill: small rounded rectangle above the floor band, accent-colored fill, with dark text reading "FLOOR N · X ROOMS"

**Active building indicator (when multiple buildings exist):**
- Dashed orange rectangle around the entire building, with rounded corners

### SVG Interaction Rules
| Element | Hover | Click (Page 3) | Click (Page 4) | Click (Page 5) |
|---|---|---|---|---|
| Floor band | Subtle highlight fill | Select this floor | Select this floor | Jump to Page 3, this floor |
| Room cell | — | — | Focus room's input field | Jump to Page 4, focus room |
| Whole building | — | — | — | Jump to Page 2, this building |

---

## Step Rail Behavior

- 4 tabs: Buildings (01), Floors (02), Rooms (03), Details (04)
- A 5th "Review" tab appears only when on the review page
- Tab states:
  - **Current:** accent background, dark text
  - **Done:** subtle border, light text (clickable — can go back)
  - **Locked:** dimmed, not clickable (haven't reached this step yet)
- Once a step is visited, it stays unlocked forever (owner can jump back and forth freely)

---

## Footer Bar Behavior

- Always visible at the bottom
- Three sections: Back button (left) | Running totals (center) | Next/action button (right)
- Running totals format: "3 buildings · 12 floors · 48 rooms · 96 beds"
- Totals update live as the owner changes anything
- Back button is disabled on Page 1
- On Page 5: Back says "← Edit details" (goes to Page 4), primary button says "Start over" (shows a confirm dialog, then resets everything)

---

## Interaction Details

### Stepper Controls
- Three elements: minus button (−) | number input | plus button (+)
- Number input: type="number", centered text, styled to hide browser spin buttons
- Clicking + increments by 1, clicking − decrements by 1, clamped to min/max
- Direct typing in the input also works (on change, clamp to valid range)

### Building Tabs
- Only shown on Pages 2, 3, 4 when there are 2+ buildings
- Each tab shows: status dot + building name
- Status dot colors: empty/gray = not started, orange = in progress, green = floors+rooms+details all done
- Clicking a tab switches the active building and updates the panel + drawing
- A dashed "+ Add" button appears at the end if < 8 buildings exist

### Floor List (Pages 3, 4)
- Scrollable list (max-height with overflow-y: auto)
- Each row: "Floor N" on left, "X rooms" on right
- Active floor row has orange border + subtle orange background fill
- Clicking a row selects that floor

### Room Input Rows (Page 4)
- Each row: text input (name) + occupancy field (number input + "occ." label)
- Name input: mono font, max 12 chars, pre-filled with default room number
- Occupancy input: mono font, range 1–8
- Both fire on `input` event (not just `change`) for real-time SVG updates
- When a room is clicked in the SVG, its name input scrolls into view, receives focus, and briefly flashes with an orange border (0.9s animation)

### Click-on-Drawing Interactions
- **Page 3:** clicking a floor band in the SVG = selecting that floor (same as clicking its row in the list)
- **Page 4:** clicking a room cell in the SVG = scrolls to + focuses that room's name input in the panel
- **Page 5:** clicking anything in the SVG navigates back to the appropriate page with the right building/floor/room selected

---

## Accessibility Requirements
- All interactive elements must have `aria-label` attributes
- The step rail should use `role="navigation"` with `aria-label="Steps"`
- Focus-visible outlines: 2px solid accent color, 2px offset
- Respect `prefers-reduced-motion`: disable all transitions and animations
- Number inputs should hide browser spin buttons via CSS
- The SVG canvas should have `role="img"` and an `aria-label` describing it

---

## Responsive Behavior
- **Desktop (> 880px):** two-column grid, panel 340px fixed, canvas flexible
- **Mobile (≤ 880px):** single column, panel full width on top, canvas below
- Canvas is always horizontally scrollable
- Touch targets on SVG floor bands / room cells should be large enough (min 44px tap target via the floor band height of 48px)

---

## File Structure
Single HTML file containing:
1. All CSS in a `<style>` tag in `<head>`
2. All HTML structure in `<body>`
3. All JavaScript in a single `<script>` tag at the end of `<body>`
4. No external dependencies except Google Fonts CDN

---

## Edge Cases to Handle
- Building count decreased while a later building is active → clamp activeBuildingIndex
- Floor count decreased while a later floor is active → clamp activeFloorIndex
- Room count decreased → truncate rooms array (rooms at the end are removed)
- Empty number input → treat as 1 (minimum)
- Room name left blank → still valid (shows empty cell in SVG)
- Very long room name → truncate display to 6 chars with ellipsis in SVG, but keep full value in data
- 1 building → no building tabs shown
- 1 floor → floor list still shown (single row)
- Navigating backward and changing buildings/floors → rooms/details from earlier edits are preserved

---

## Summary of User Flow

```
Owner opens the app
  │
  ├─ Page 1: "I have 3 buildings"
  │   → 3 dashed plots appear on the drawing
  │
  ├─ Page 2: "Building 1 has 4 floors, Building 2 has 2 floors..."
  │   → Each building grows into a stacked floor diagram
  │
  ├─ Page 3: *clicks Floor 2 on the drawing* → "This floor has 5 rooms"
  │   → Floor 2 splits into 5 room cells
  │   → Repeat for every floor of every building
  │
  ├─ Page 4: Types "Suite A" → occupancy 3, "Room 102" → occupancy 2...
  │   → Labels and badges appear on the drawing in real time
  │   → *clicks a room on the drawing* → jumps to its input field
  │
  └─ Page 5: Reviews the full property
      → Sees totals: 3 buildings, 12 floors, 48 rooms, 96 beds
      → Exports structured JSON
      → Clicks any part of the drawing to go back and edit
```

---

## What to Build
A single self-contained HTML file implementing everything above. No frameworks, no build tools, no npm. Vanilla HTML + CSS + JavaScript + inline SVG. The file should open directly in any browser and be fully functional.
