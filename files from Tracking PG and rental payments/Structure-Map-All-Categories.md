# Universal Structure Map — All 62 Business Types

Every business in the catalog maps to the same tree. This document shows the structure for each category, then groups them by **shared sub-selection patterns** so the app knows which setup screens to show.

---

## THE UNIVERSAL TREE (what every business maps to)

```
Organization (the business)
  │
  ├── Resource(s) (the space / kitchen / route / facility)
  │     ├── Zone(s) (floor / section / area / route segment)
  │     │     ├── Unit(s) (room / desk / slot / bay / subscriber)
  │     │     │     ├── Occupant / Subscriber details
  │     │     │     ├── Billing (rent / fee / plan / per-use)
  │     │     │     └── Status (active / vacant / paused / expired)
  │     │     └── Facility Unit(s) (gym / laundry / parking — shared spaces)
  │     │           ├── Capacity & timings
  │     │           └── Staff assigned
  │     └── Resource-level services (security, WiFi, water, power)
  │
  ├── Services / Products catalog
  │     ├── Included (bundled free)
  │     ├── Subscription (recurring opt-in)
  │     ├── Usage-based (per-use / per-piece / per-session)
  │     └── One-time (deposit / admission / registration)
  │
  ├── People
  │     ├── Occupant / Subscriber → subscribed services → invoice
  │     ├── Staff → role, attendance, salary
  │     └── Contacts (emergency / family / guarantor)
  │
  └── Billing Engine
        ├── Invoice generation (auto / manual)
        ├── Payment tracking (cash / UPI / bank / card)
        ├── Reminders (SMS / WhatsApp / push)
        ├── Receipts (auto-generated)
        └── Ledger & reports
```

---

## STRUCTURE BY CATEGORY

---

### CATEGORY 1: RESIDENTIAL & STAY
**Applies to:** PG Rooms, Hostel, Co-Living, Flats, Indep. Floors, Villa, Penthouse, Studio Appt., RKs/Kothi, Homestay, Hotel/Lodge, Dharamshala, Old Age Home, Rehab Center, Service Appt.

```
Property
  │
  ├── Building(s)
  │     ├── Floor(s)
  │     │     ├── Tenant Room(s)
  │     │     │     ├── Room name / number
  │     │     │     ├── Room type (single / double / triple / dormitory)
  │     │     │     ├── Occupancy (beds per room)
  │     │     │     ├── Base rent (per bed or per room)
  │     │     │     ├── Sharing type (1-share / 2-share / 3-share)
  │     │     │     └── Status (occupied / vacant / reserved / maintenance)
  │     │     │
  │     │     └── Facility Room(s)
  │     │           ├── Gym → capacity, timings, trainer
  │     │           ├── Dining / Mess → seating, meal times
  │     │           ├── Laundry → machines, slots
  │     │           ├── Common area → TV room, terrace, study room
  │     │           └── Parking → slots (car / bike)
  │     │
  │     └── Building-level services
  │           ├── WiFi (included / extra)
  │           ├── Security (guard, CCTV)
  │           ├── Power backup (generator / inverter)
  │           ├── Water supply (municipal / tanker)
  │           └── Housekeeping
  │
  ├── Services catalog
  │     ├── Included with rent
  │     │     ├── WiFi
  │     │     ├── Water
  │     │     ├── Security
  │     │     └── Housekeeping (common areas)
  │     │
  │     ├── Subscription (monthly opt-in)
  │     │     ├── Meals / Mess (₹X/month)
  │     │     ├── Laundry (₹X/month)
  │     │     ├── Gym access (₹X/month)
  │     │     ├── Room cleaning (₹X/month)
  │     │     └── AC charges (seasonal, ₹X/month)
  │     │
  │     ├── Usage-based
  │     │     ├── Electricity (per unit metered)
  │     │     ├── Washing machine (per use)
  │     │     ├── Printing / Xerox (per page)
  │     │     └── Guest stay (per night)
  │     │
  │     └── One-time
  │           ├── Security deposit
  │           ├── Registration / booking fee
  │           └── Key / access card deposit
  │
  ├── Tenant
  │     ├── Personal details (name, phone, email, photo)
  │     ├── ID verification (Aadhaar, PAN, passport)
  │     ├── Police verification status
  │     ├── Emergency contacts
  │     ├── Move-in date & agreement
  │     ├── Move-in condition photos
  │     ├── Assigned room & bed
  │     ├── Subscribed services
  │     ├── Notice period status
  │     ├── Move-out date & condition photos
  │     └── Deposit refund / deductions
  │
  └── Billing
        ├── Monthly invoice (rent + subscribed services + usage charges)
        ├── Payment tracking (cash / UPI / bank)
        ├── Mutual-confirmation cash log
        ├── Auto-receipts (WhatsApp / PDF)
        ├── Reminders (pre-due / on-due / overdue)
        ├── Partial payment & balance carry-forward
        ├── Defaulter flagging
        └── Tax summary (annual income, GST, TDS)
```

**Sub-variants within this category:**

| Business | What changes |
|---|---|
| PG Rooms | Bed-level billing, sharing type, mess management, police verification |
| Hostel (student) | Semester allocation, parent portal, warden role, student ID linkage |
| Co-Living | Flexible move-in/out, community events, referral programs |
| Flats / Indep. Floors / Villa / Penthouse | Per-flat billing (not per-bed), rental agreement focus, TDS tracking |
| RKs / Kothi | Multi-family, floor-wise ownership, mixed use |
| Homestay | Short-stay (daily rate), booking calendar, tourist ID |
| Hotel / Lodge | Daily rate, check-in/out calendar, room availability, walk-in management |
| Dharamshala | Donation-based, nominal fee, pilgrim register, trust reporting |
| Old Age Home | Medical history, medication schedule, family portal, care staff roster |
| Rehab Center | Treatment program phases, counselor assignment, family billing |
| Service Appt. | Short/medium stay, furnished inventory, housekeeping schedule |
| Studio Appt. | Single-unit, compact billing, tenant-only (no bed-level) |

---

### CATEGORY 2: EDUCATION & COACHING
**Applies to:** Tuition Center, Dance Class, Music Class, Art Class, Language Inst., Preschool/Daycare, Computer Lab, Driving School

```
Institute
  │
  ├── Branch(es) (location / center)
  │     ├── Classroom(s) / Studio(s)
  │     │     ├── Room name / number
  │     │     ├── Seating capacity
  │     │     ├── Equipment (projector, whiteboard, instruments, computers)
  │     │     └── Status (active / under maintenance)
  │     │
  │     └── Shared Facilities
  │           ├── Reception / waiting area
  │           ├── Library / reading corner
  │           ├── Practice room (music / dance)
  │           └── Parking
  │
  ├── Courses / Batches
  │     ├── Course name (e.g., "10th Math", "Bharatanatyam Beginner", "IELTS Prep")
  │     ├── Batch timing (6 AM / 4 PM / Weekend)
  │     ├── Duration (3 months / 6 months / ongoing)
  │     ├── Teacher / Instructor assigned
  │     ├── Classroom assigned
  │     ├── Max students per batch
  │     ├── Fee structure
  │     │     ├── Monthly fee
  │     │     ├── Quarterly / Term fee (with discount)
  │     │     ├── Annual fee
  │     │     └── Per-session fee
  │     └── Status (active / upcoming / completed)
  │
  ├── Services catalog
  │     ├── Included with course
  │     │     ├── Study material
  │     │     ├── Practice sessions
  │     │     └── Basic assessments
  │     │
  │     ├── Subscription add-ons
  │     │     ├── Extra practice sessions (₹X/month)
  │     │     ├── Transport / pickup-drop (₹X/month)
  │     │     ├── Meal / snacks (₹X/month, for preschool/daycare)
  │     │     └── Extended hours / after-school care
  │     │
  │     ├── Usage-based
  │     │     ├── Extra class / makeup class (per session)
  │     │     ├── Printing / materials (per use)
  │     │     └── Instrument rental (per session)
  │     │
  │     └── One-time
  │           ├── Admission / registration fee
  │           ├── Uniform / kit
  │           ├── Books / materials
  │           └── Exam / certification fee
  │
  ├── Student
  │     ├── Personal details (name, age, phone, photo)
  │     ├── Parent / guardian details (for minors)
  │     ├── ID (school ID / Aadhaar)
  │     ├── Enrolled course(s) & batch(es)
  │     ├── Joining date
  │     ├── Fee plan (monthly / quarterly / annual)
  │     ├── Attendance record
  │     ├── Performance / grades / belt rank
  │     ├── Subscribed add-on services
  │     └── Certificate / completion status
  │
  └── Billing
        ├── Monthly / term invoice (fee + add-ons)
        ├── Payment tracking
        ├── Auto-receipts (for tax / school records)
        ├── Reminders (pre-due / overdue)
        ├── Partial payment tracking
        ├── Defaulter flagging
        └── Fee revision history
```

**Sub-variants within this category:**

| Business | What changes |
|---|---|
| Tuition Center | Subject-wise batches, test scores, parent SMS updates |
| Dance / Music / Art Class | Session-pack billing (12 classes in 2 months), recital/event planning, makeup class management |
| Language Institute | Level progression, demo class scheduling, certificate generation |
| Preschool / Daycare | Daily activity log, parent photo updates, authorized pickup list, nap/meal tracking, staff-child ratio compliance |
| Computer Lab | Terminal allocation, course completion tracking, placement tracking |
| Driving School | Vehicle + instructor slot booking, progress milestones, license application tracking |

---

### CATEGORY 3: FITNESS & WELLNESS
**Applies to:** Gym, Yoga/Pilates, Swimming Pool, Martial Arts, Sports Academy, Spa/Salon, Physiotherapy

```
Fitness Center
  │
  ├── Facility / Branch
  │     ├── Training Area(s) / Studio(s)
  │     │     ├── Area name (Main floor, Cardio zone, Yoga hall, Pool)
  │     │     ├── Capacity (max members at a time)
  │     │     ├── Equipment list
  │     │     └── Status (active / under maintenance)
  │     │
  │     └── Shared Amenities
  │           ├── Changing rooms / Lockers
  │           ├── Steam / Sauna
  │           ├── Parking
  │           └── Juice bar / Café
  │
  ├── Membership Plans
  │     ├── Plan name (Monthly, Quarterly, Annual, Day Pass)
  │     ├── Duration
  │     ├── Price
  │     ├── Included access (which areas / classes)
  │     ├── Batch / timing restrictions (morning only, any time)
  │     └── Status (active / expired / frozen)
  │
  ├── Classes / Sessions
  │     ├── Class name (Yoga, Zumba, Boxing, Swimming batch)
  │     ├── Instructor / Trainer
  │     ├── Schedule (days + time)
  │     ├── Capacity per session
  │     └── Location (which studio / area)
  │
  ├── Services catalog
  │     ├── Included with membership
  │     │     ├── Open gym access
  │     │     ├── Basic group classes
  │     │     ├── Changing room / locker
  │     │     └── Drinking water / towels
  │     │
  │     ├── Subscription add-ons
  │     │     ├── Personal training (₹X/month)
  │     │     ├── Diet / nutrition plan (₹X/month)
  │     │     ├── Steam / Sauna access (₹X/month)
  │     │     ├── Locker rental (₹X/month)
  │     │     └── Specialty class (kickboxing, swimming, etc.)
  │     │
  │     ├── Usage-based
  │     │     ├── Guest pass (per visit)
  │     │     ├── Spa / massage (per session)
  │     │     ├── Body composition test (per test)
  │     │     └── Equipment rental (per session)
  │     │
  │     └── One-time
  │           ├── Admission / joining fee
  │           ├── ID card
  │           └── Kit / uniform
  │
  ├── Member
  │     ├── Personal details (name, phone, email, photo)
  │     ├── Health details (height, weight, medical conditions)
  │     ├── Emergency contact
  │     ├── Membership plan & start date
  │     ├── Expiry date
  │     ├── Assigned trainer / instructor
  │     ├── Batch / timing preference
  │     ├── Attendance log
  │     ├── Body metrics history (weight, BMI over time)
  │     ├── Subscribed add-on services
  │     ├── Freeze / pause history
  │     └── Renewal status & alerts
  │
  └── Billing
        ├── Membership invoice (plan + add-ons)
        ├── Renewal reminders (7 days, 3 days, expiry day, post-expiry)
        ├── Payment tracking
        ├── Auto-receipts
        ├── Upgrade / downgrade handling
        ├── Freeze period (pause billing, extend expiry)
        ├── Defaulter flagging
        └── Revenue per member / per plan analytics
```

**Sub-variants within this category:**

| Business | What changes |
|---|---|
| Gym | Body metrics tracking, trainer assignment, equipment maintenance log |
| Yoga / Pilates | Session-pack billing, class schedule, substitute instructor management |
| Swimming Pool | Time-slot booking, age-group batches, lifeguard scheduling, water quality log |
| Martial Arts | Belt/rank progression, grading events, tournament registration |
| Sports Academy | Ground/court booking, match calendar, multi-sport multi-batch, equipment inventory |
| Spa / Salon | Appointment booking, stylist/therapist assignment, credit/wallet, no-show penalty |
| Physiotherapy | Treatment plan, session countdown, therapist notes, insurance billing |

---

### CATEGORY 4: FOOD & KITCHEN
**Applies to:** Tiffin/Dabba, Catering, Home Bakery, Mess/Canteen, Juice/Tea Bar, Meal Prep, Cake/Sweets, Cloud Kitchen

```
Kitchen / Food Business
  │
  ├── Kitchen / Production Unit(s)
  │     ├── Kitchen name / location
  │     ├── Daily production capacity (number of meals / items)
  │     ├── Equipment (ovens, stoves, mixers, cold storage)
  │     ├── FSSAI license status
  │     └── Staff (cook, helper, delivery)
  │
  ├── Menu / Plans
  │     ├── Plan name (Lunch Only, Full Day, Weekly Box, Custom Cake)
  │     ├── Menu items / rotation
  │     │     ├── Day-wise menu (Mon: dal rice, Tue: biryani...)
  │     │     ├── Dietary category (veg / non-veg / Jain / vegan)
  │     │     └── Allergen info
  │     ├── Pricing
  │     │     ├── Per-meal price
  │     │     ├── Monthly plan price
  │     │     ├── Weekly plan price
  │     │     └── Per-order (custom cakes, bulk sweets)
  │     └── Status (active / seasonal / discontinued)
  │
  ├── Delivery / Distribution
  │     ├── Delivery zone(s) / route(s)
  │     │     ├── Zone name (Koramangala, Indiranagar, etc.)
  │     │     ├── Delivery boy assigned
  │     │     └── Delivery time window
  │     ├── Container tracking
  │     │     ├── Containers out
  │     │     ├── Containers returned
  │     │     └── Lost / damaged
  │     └── Delivery mode (pickup / delivery / both)
  │
  ├── Services catalog
  │     ├── Included with plan
  │     │     ├── Standard meals (as per menu)
  │     │     ├── Container provided
  │     │     └── Delivery within zone
  │     │
  │     ├── Subscription add-ons
  │     │     ├── Extra roti / rice (₹X/month)
  │     │     ├── Special diet (Jain / keto / diabetic)
  │     │     ├── Weekend meals (if not included)
  │     │     └── Dessert / salad add-on
  │     │
  │     ├── Usage-based
  │     │     ├── Extra meal (per meal)
  │     │     ├── Guest meal (per meal)
  │     │     ├── Custom order (per order — cakes, sweets)
  │     │     └── Out-of-zone delivery surcharge
  │     │
  │     └── One-time
  │           ├── Container deposit
  │           ├── Registration fee
  │           └── Tasting / trial meal
  │
  ├── Subscriber / Customer
  │     ├── Personal details (name, phone, address)
  │     ├── Delivery address & zone
  │     ├── Subscribed plan(s)
  │     ├── Dietary preferences (veg / non-veg / allergies)
  │     ├── Daily opt-in / opt-out log
  │     │     ├── Today: ✅ delivering
  │     │     ├── Tomorrow: ⏸️ paused (traveling)
  │     │     └── Auto-adjust monthly bill
  │     ├── Container balance (out vs returned)
  │     ├── Start date & plan duration
  │     └── Renewal status
  │
  └── Billing
        ├── Monthly invoice (plan - skipped days + add-ons + extra orders)
        ├── Pro-rata calculation for pause/skip days
        ├── Payment tracking (cash to delivery boy / UPI / bank)
        ├── Delivery boy collection log (mutual confirmation)
        ├── Auto-receipts
        ├── Reminders
        ├── Defaulter flagging
        └── Grocery / ingredient cost tracking (P&L per plan)
```

**Sub-variants within this category:**

| Business | What changes |
|---|---|
| Tiffin / Dabba | Daily opt-in/out, container return, delivery boy route, multi-meal plans |
| Catering | Contract-based (offices, events), headcount per client, event calendar |
| Home Bakery | Per-order (custom cakes), advance booking with token, Instagram/WhatsApp intake |
| Mess / Canteen | Walk-in + subscriber, daily headcount for prep, wastage tracking |
| Juice / Tea Bar | Daily redemption against plan, credits system, loyalty points |
| Meal Prep / Diet | Per-subscriber diet customization, calorie/macro tracking, nutritionist assignment |
| Cake / Sweet Shop | Order queue, advance booking calendar, flavor/design catalog |
| Cloud Kitchen | Bay rental, shared equipment booking, multi-brand per kitchen, FSSAI compliance |

---

### CATEGORY 5: DELIVERY & ROUTE-BASED
**Applies to:** Newspaper, Milk Delivery, Water Can, Flowers, Laundry Pickup, Grocery Sub., Dhobi/Ironing, Gas Cylinder, Garbage Pickup, Baby Supplies

```
Delivery Business
  │
  ├── Depot / Distribution Center
  │     ├── Location
  │     ├── Inventory / Stock
  │     │     ├── Products available (newspaper titles, milk types, can sizes)
  │     │     └── Daily stock levels
  │     └── Staff (delivery boys, drivers)
  │
  ├── Route(s)
  │     ├── Route name / area (MG Road, Jayanagar 4th Block)
  │     ├── Delivery boy / driver assigned
  │     ├── Subscriber count on route
  │     ├── Estimated delivery time window
  │     └── Route map / sequence
  │
  ├── Product / Service catalog
  │     ├── Product name
  │     │     ├── Newspaper: Times of India, Deccan Herald, Vijaya Karnataka
  │     │     ├── Milk: Toned 500ml, Full Cream 1L, Curd 400g, Buttermilk
  │     │     ├── Water: 20L Can, 5L Jar
  │     │     ├── Flowers: Daily pooja set, Premium garland
  │     │     ├── Laundry: Wash & fold, Wash & iron, Dry clean
  │     │     ├── Grocery: Daily essentials kit, Weekly box
  │     │     ├── Ironing: Per-piece (shirt, pant, saree)
  │     │     ├── Gas: 14.2kg domestic, 5kg commercial
  │     │     ├── Garbage: Wet waste, Dry waste, Mixed
  │     │     └── Baby: Diapers (size S/M/L/XL), Wipes, Formula
  │     ├── Unit price
  │     ├── Monthly plan price (if applicable)
  │     └── Variant options (size, type, brand)
  │
  ├── Services catalog
  │     ├── Included with subscription
  │     │     ├── Daily delivery to door
  │     │     ├── Monthly billing (no daily payment)
  │     │     └── Pause / resume flexibility
  │     │
  │     ├── Subscription plans
  │     │     ├── Daily delivery plan (₹X/month)
  │     │     ├── Alternate day plan
  │     │     ├── Weekday-only plan
  │     │     └── Weekend-only plan
  │     │
  │     ├── Usage-based
  │     │     ├── Extra delivery (per delivery)
  │     │     ├── Express / priority delivery surcharge
  │     │     ├── Pickup service (for laundry, gas empty return)
  │     │     └── Per-piece pricing (ironing, laundry)
  │     │
  │     └── One-time
  │           ├── Registration fee
  │           ├── Container / bag deposit (tiffin box, water jar, gas cylinder)
  │           └── Key / gate access deposit
  │
  ├── Subscriber
  │     ├── Personal details (name, phone)
  │     ├── Delivery address & landmark
  │     ├── Route assignment
  │     ├── Subscribed products
  │     │     ├── Product 1: Times of India (daily) — ₹10/day
  │     │     ├── Product 2: Deccan Herald (daily) — ₹8/day
  │     │     └── Product 3: India Today (weekly) — ₹40/week
  │     ├── Daily quantity / variant
  │     │     ├── Default: 500ml toned milk
  │     │     ├── Tomorrow: 1L full cream (changed)
  │     │     └── Festival: 2L + 500g curd (special order)
  │     ├── Delivery schedule
  │     │     ├── Active days (Mon–Sat / Daily / Custom)
  │     │     ├── Pause dates (vacation: June 10–20)
  │     │     └── Temporary stop / resume
  │     ├── Container balance (empty cans / jars / cylinders out vs returned)
  │     ├── Complaints log (missed delivery, wrong item, damaged)
  │     └── Start date & renewal
  │
  └── Billing
        ├── Monthly auto-calculated invoice
        │     ├── (Daily quantity × price × active days) for each product
        │     ├── − Paused / skipped days
        │     ├── + Extra deliveries
        │     ├── + Per-piece charges (laundry, ironing)
        │     └── = Total monthly bill
        ├── Delivery boy collection log
        │     ├── Cash collected per subscriber
        │     ├── Mutual confirmation (subscriber confirms amount)
        │     └── Daily collection summary for owner
        ├── Payment tracking (cash / UPI / monthly bank transfer)
        ├── Auto-receipts
        ├── Reminders
        ├── Defaulter flagging
        └── Route-wise revenue & collection report
```

**Sub-variants within this category:**

| Business | What changes |
|---|---|
| Newspaper | Multi-publication per subscriber, daily rate × active days billing, Sunday-only supplements |
| Milk | Daily quantity changes, product variants (toned/full cream/curd), festival surge |
| Water Can | On-demand + scheduled, empty can return tracking, truck/driver assignment |
| Flowers | Festival calendar with auto-upsell, seasonal availability, freshness window |
| Laundry Pickup | Per-garment tracking, damage photo log, express service, garment count per pickup |
| Grocery Sub. | Kit customization, substitution preferences, weekly auto-order |
| Dhobi / Ironing | Per-piece rate card, piece-count log per pickup, colony-wise collection |
| Gas Cylinder | Refill scheduling, subsidy vs market rate, last-refill tracking, safety compliance |
| Garbage Collection | Daily pickup confirmation, missed-pickup complaints, wet/dry segregation tracking |
| Baby Supplies | Auto-size upgrade as baby grows, product swap preferences, bi-weekly schedule |

---

### CATEGORY 6: COMMERCIAL & WORKSPACE
**Applies to:** Co-working, Shops/Complex, Warehouse, Market Stalls

```
Commercial Property
  │
  ├── Property / Complex
  │     ├── Building(s)
  │     │     ├── Floor(s)
  │     │     │     ├── Unit(s)
  │     │     │     │     ├── Unit name / number (Shop 101, Desk A-14, Bay 3)
  │     │     │     │     ├── Type (shop / office / desk / cabin / meeting room / godown)
  │     │     │     │     ├── Area (sqft)
  │     │     │     │     ├── Base rent / lease rate
  │     │     │     │     ├── Lease terms (duration, escalation %, lock-in)
  │     │     │     │     └── Status (occupied / vacant / under-fit-out)
  │     │     │     │
  │     │     │     └── Common Areas
  │     │     │           ├── Lobby / Reception
  │     │     │           ├── Restrooms
  │     │     │           ├── Loading dock (warehouse)
  │     │     │           └── Food court / Cafeteria
  │     │     │
  │     │     └── Building-level services
  │     │           ├── Security / CCTV
  │     │           ├── Elevator / Lift
  │     │           ├── Power backup
  │     │           ├── Fire safety
  │     │           └── Waste management
  │     │
  │     └── Parking
  │           ├── Car slots
  │           ├── Bike slots
  │           └── Visitor parking
  │
  ├── Services catalog
  │     ├── Included (CAM — Common Area Maintenance)
  │     │     ├── Security
  │     │     ├── Cleaning (common areas)
  │     │     ├── Elevator maintenance
  │     │     └── Fire safety
  │     │
  │     ├── Subscription
  │     │     ├── Dedicated parking (₹X/month)
  │     │     ├── Signage / branding slot (₹X/month)
  │     │     ├── Mail handling (co-working)
  │     │     ├── Printer / scanner access (₹X/month)
  │     │     └── Pantry / tea-coffee (₹X/month)
  │     │
  │     ├── Usage-based
  │     │     ├── Meeting room (per hour)
  │     │     ├── Event space (per event)
  │     │     ├── Loading dock (per use)
  │     │     ├── Electricity (sub-metered per unit)
  │     │     └── Day pass (co-working)
  │     │
  │     └── One-time
  │           ├── Security deposit
  │           ├── Fit-out / setup fee
  │           └── Key / access card deposit
  │
  ├── Tenant / Lessee
  │     ├── Business name & owner details
  │     ├── GST number
  │     ├── Trade license
  │     ├── Lease agreement (start, end, terms)
  │     ├── Rent escalation schedule
  │     ├── Assigned unit(s)
  │     ├── Sub-metered electricity reading
  │     ├── Subscribed services
  │     ├── CAM charges
  │     └── Lease renewal alerts
  │
  └── Billing
        ├── Monthly invoice (rent + CAM + electricity + add-ons)
        ├── Rent escalation auto-calculation
        ├── GST-compliant invoicing
        ├── TDS tracking
        ├── Payment tracking
        ├── Auto-receipts
        ├── Reminders
        ├── Lease expiry alerts
        └── Vacancy cost tracking
```

---

### CATEGORY 7: COMMUNITY & RELIGIOUS
**Applies to:** Gated Community/RWA, Temple/Church, Community Hall, Club/Society

```
Community / Association
  │
  ├── Property / Campus
  │     ├── Block(s) / Tower(s) / Building(s)
  │     │     ├── Floor(s)
  │     │     │     └── Unit(s) (flat / villa / room / hall)
  │     │     │           ├── Unit number
  │     │     │           ├── Owner name
  │     │     │           ├── Occupant (owner-occupied / tenant)
  │     │     │           └── Size (sqft / BHK)
  │     │     └── Common facilities
  │     │           ├── Clubhouse
  │     │           ├── Swimming pool
  │     │           ├── Gym
  │     │           ├── Park / Playground
  │     │           ├── Community hall (bookable)
  │     │           ├── Temple / Prayer room
  │     │           └── Parking (assigned + visitor)
  │     │
  │     └── Campus-level services
  │           ├── Security (guards, CCTV, gate)
  │           ├── Visitor management
  │           ├── Housekeeping (common areas)
  │           ├── Gardening / Landscaping
  │           ├── STP / Water treatment
  │           └── Power backup (DG set)
  │
  ├── Services catalog
  │     ├── Included (covered by maintenance fee)
  │     │     ├── Security & CCTV
  │     │     ├── Common area cleaning
  │     │     ├── Lift maintenance
  │     │     ├── Water supply
  │     │     ├── Garbage collection
  │     │     └── Garden upkeep
  │     │
  │     ├── Subscription
  │     │     ├── Clubhouse membership (₹X/month)
  │     │     ├── Swimming pool access (₹X/month)
  │     │     ├── Gym access (₹X/month)
  │     │     ├── Reserved parking (₹X/month)
  │     │     └── Newspaper (₹X/month)
  │     │
  │     ├── Usage-based
  │     │     ├── Community hall booking (per event)
  │     │     ├── Guest room (per night)
  │     │     ├── Moving charges (per move-in/out)
  │     │     └── EV charging (per kWh)
  │     │
  │     └── One-time / Fund
  │           ├── Sinking fund contribution
  │           ├── Corpus fund
  │           ├── Interior work deposit
  │           └── Donation (temple / event)
  │
  ├── Resident / Member
  │     ├── Owner details (name, phone, email)
  │     ├── Tenant details (if rented out)
  │     ├── Vehicle details (car / bike reg. numbers)
  │     ├── Family members
  │     ├── Domestic help details
  │     ├── Maintenance payment status
  │     ├── Committee membership / role
  │     └── Voting rights
  │
  └── Billing & Governance
        ├── Monthly maintenance invoice
        ├── Sinking fund tracking
        ├── Payment tracking
        ├── Defaulter list (public / escalation)
        ├── Auto-receipts
        ├── Reminders
        ├── Expense transparency dashboard
        ├── AGM / Meeting minutes
        ├── Voting / Polls
        ├── Notice board / Announcements
        └── Annual audit report
```

---

### CATEGORY 8: VEHICLE & STORAGE
**Applies to:** Parking Lot, Self-Storage, Boat Marina

```
Storage / Parking Facility
  │
  ├── Facility
  │     ├── Section(s) / Level(s)
  │     │     └── Slot(s) / Unit(s)
  │     │           ├── Slot ID / Unit number
  │     │           ├── Size category (bike / car / SUV / small / medium / large)
  │     │           ├── Type (covered / open / climate-controlled)
  │     │           ├── Monthly rate
  │     │           └── Status (occupied / available / reserved)
  │     └── Facility amenities
  │           ├── CCTV
  │           ├── Security guard
  │           ├── Access control (RFID / keypad)
  │           └── Lighting
  │
  ├── Services catalog
  │     ├── Included with rental
  │     │     ├── 24/7 access
  │     │     ├── Security / CCTV
  │     │     └── Basic lighting
  │     │
  │     ├── Subscription
  │     │     ├── Premium / covered slot upgrade
  │     │     ├── Insurance (₹X/month)
  │     │     └── Valet service (₹X/month)
  │     │
  │     ├── Usage-based
  │     │     ├── Hourly parking (visitors)
  │     │     ├── Extra access card (per card)
  │     │     └── Loading / unloading assistance
  │     │
  │     └── One-time
  │           ├── Security deposit
  │           ├── Access card / key deposit
  │           └── Lock purchase
  │
  ├── Renter / Vehicle Owner
  │     ├── Name, phone, email
  │     ├── Vehicle / item details (reg. number, description, photo)
  │     ├── Assigned slot(s)
  │     ├── Access log (entry / exit timestamps)
  │     ├── Start date & contract
  │     ├── Subscribed services
  │     └── Insurance details
  │
  └── Billing
        ├── Monthly rental invoice
        ├── Hourly billing (for visitor / per-use)
        ├── Payment tracking
        ├── Auto-receipts
        ├── Reminders
        └── Occupancy rate reports
```

---

### CATEGORY 9: HEALTHCARE
**Applies to:** Clinic (subscription), Pet Boarding/Vet

```
Healthcare Facility
  │
  ├── Facility
  │     ├── Room(s) / Bay(s)
  │     │     ├── Room name (Consultation 1, Treatment Bay A, Kennel 3)
  │     │     ├── Type (consultation / treatment / recovery / kennel / cage)
  │     │     ├── Capacity
  │     │     ├── Equipment
  │     │     └── Status
  │     └── Support areas
  │           ├── Waiting area
  │           ├── Lab / Diagnostic
  │           ├── Pharmacy
  │           └── Grooming area (vet)
  │
  ├── Services catalog
  │     ├── Included with plan
  │     │     ├── Basic consultation
  │     │     ├── Follow-up visits
  │     │     └── Health records
  │     │
  │     ├── Subscription
  │     │     ├── Monthly health plan (₹X/month)
  │     │     ├── Boarding (₹X/day or ₹X/month)
  │     │     ├── Grooming package (₹X/month)
  │     │     └── Vaccination schedule plan
  │     │
  │     ├── Usage-based
  │     │     ├── Specialist consultation (per visit)
  │     │     ├── Lab tests (per test)
  │     │     ├── Grooming session (per session)
  │     │     ├── Surgery / procedure (per procedure)
  │     │     └── Medication (per prescription)
  │     │
  │     └── One-time
  │           ├── Registration fee
  │           ├── Boarding deposit
  │           └── Emergency visit charge
  │
  ├── Patient / Pet
  │     ├── Patient: name, age, phone, medical history
  │     ├── Pet: name, breed, weight, age, owner details
  │     ├── Vaccination records
  │     ├── Treatment history
  │     ├── Assigned doctor / vet
  │     ├── Current plan / subscription
  │     ├── Appointment schedule
  │     ├── Medication schedule
  │     ├── Feeding schedule (boarding)
  │     └── Emergency contact
  │
  └── Billing
        ├── Plan invoice / Visit invoice
        ├── Insurance claim tracking
        ├── Payment tracking
        ├── Auto-receipts
        ├── Reminders (appointment, vaccination due, renewal)
        └── Treatment cost history
```

---

### CATEGORY 10: CREATIVE & HOBBY
**Applies to:** Photo Studio, Maker Space, Rehearsal Studio

```
Creative Space
  │
  ├── Facility
  │     ├── Room(s) / Studio(s) / Bay(s)
  │     │     ├── Room name (Studio A, Darkroom, Booth 1, Workbench 4)
  │     │     ├── Type (photo studio / recording booth / workbench / machine bay)
  │     │     ├── Equipment list (cameras, lights, 3D printer, laser cutter, mics)
  │     │     ├── Hourly rate / Monthly membership
  │     │     ├── Capacity (1 shoot / 1 band / 2 makers)
  │     │     └── Status (available / booked / maintenance)
  │     └── Shared amenities
  │           ├── Editing stations
  │           ├── Material storage
  │           ├── Lounge / break area
  │           └── Display / gallery wall
  │
  ├── Services catalog
  │     ├── Included with membership
  │     │     ├── Basic room access
  │     │     ├── Shared tools / equipment
  │     │     ├── WiFi
  │     │     └── Storage locker
  │     │
  │     ├── Subscription
  │     │     ├── Dedicated workbench (₹X/month)
  │     │     ├── Extended hours access (₹X/month)
  │     │     ├── Premium equipment access (₹X/month)
  │     │     └── Material subscription (₹X/month)
  │     │
  │     ├── Usage-based
  │     │     ├── Hourly room booking
  │     │     ├── Equipment checkout (per session)
  │     │     ├── Material cost (per gram / per sheet)
  │     │     ├── Print / output (per piece)
  │     │     └── Event / exhibition space (per event)
  │     │
  │     └── One-time
  │           ├── Membership / joining fee
  │           ├── Safety certification / training
  │           ├── Equipment damage deposit
  │           └── Exhibition fee
  │
  ├── Member / Creator
  │     ├── Name, phone, email, portfolio link
  │     ├── Membership plan & start date
  │     ├── Safety certification status (for maker spaces)
  │     ├── Equipment checkout history
  │     ├── Booking history
  │     ├── Project showcase (optional)
  │     ├── Subscribed services
  │     └── Renewal status
  │
  └── Billing
        ├── Monthly membership + usage invoice
        ├── Hourly booking charges
        ├── Material cost tracking
        ├── Payment tracking
        ├── Auto-receipts
        ├── Reminders
        └── Revenue per room / equipment utilization report
```

---

### CATEGORY 11: OTHER / MISCELLANEOUS
**Applies to:** EV Charging, Laundromat, Library/Study Hall, Farm/Garden

```
Miscellaneous Facility
  │
  ├── Facility
  │     ├── Station(s) / Unit(s) / Seat(s) / Plot(s)
  │     │     ├── Unit ID (Charger 1, Machine A, Seat 42, Plot B-7)
  │     │     ├── Type (charger type / washer-dryer / desk-cabin / raised-bed)
  │     │     ├── Capacity / specs
  │     │     ├── Rate (per kWh / per wash / per month / per season)
  │     │     └── Status (available / in-use / booked / maintenance)
  │     └── Common amenities
  │           ├── Waiting area
  │           ├── Restrooms
  │           ├── Tool shed (garden)
  │           └── Water supply (garden)
  │
  ├── Services catalog
  │     ├── Included
  │     │     ├── Basic access / usage
  │     │     └── Standard amenities
  │     │
  │     ├── Subscription
  │     │     ├── Monthly unlimited plan (laundromat)
  │     │     ├── Monthly seat reservation (library)
  │     │     ├── Seasonal plot rental (garden)
  │     │     └── Monthly charging plan (EV)
  │     │
  │     ├── Usage-based
  │     │     ├── Per-wash / per-dry cycle
  │     │     ├── Per kWh charging
  │     │     ├── Hourly seat booking (library)
  │     │     └── Tool rental (garden)
  │     │
  │     └── One-time
  │           ├── Membership / registration
  │           └── Deposit (locker, tools)
  │
  ├── Member / User
  │     ├── Name, phone
  │     ├── Subscription plan
  │     ├── Usage log
  │     ├── Assigned unit (if reserved)
  │     └── Renewal status
  │
  └── Billing
        ├── Monthly plan / usage invoice
        ├── Per-use billing
        ├── Payment tracking
        ├── Auto-receipts
        └── Reminders
```

---

## GROUPED BY SHARED SUB-SELECTION PATTERNS

These are the **setup screen flows** the app needs. Businesses that share the same sub-selection flow can reuse the same UI screens.

---

### GROUP A: Building → Floor → Room → Occupant (Space-based, multi-level)
**Setup flow:** Select buildings → Set floors → Add rooms per floor → Name rooms + set occupancy/rent

| Businesses |
|---|
| PG Rooms, Hostel, Co-Living, Flats, Indep. Floors, Villa, Penthouse, Studio Appt., RKs/Kothi, Hotel/Lodge, Dharamshala, Old Age Home, Rehab Center, Service Appt., Homestay |
| Shops/Complex, Warehouse |
| Gated Community (blocks → floors → flats) |

**Shared screens:** Building configurator (existing MVP), floor selector, room editor, occupant/tenant form

---

### GROUP B: Facility → Area/Hall → Batch/Class → Member (Single-space, batch-based)
**Setup flow:** Define facility → Add training areas/studios → Create batches/classes with schedule → Add members with plans

| Businesses |
|---|
| Gym, Yoga/Pilates, Swimming Pool, Martial Arts, Sports Academy, Spa/Salon, Physiotherapy |
| Tuition Center, Dance Class, Music Class, Art Class, Language Inst., Computer Lab |
| Preschool/Daycare |
| Photo Studio, Maker Space, Rehearsal Studio |
| Library/Study Hall |
| Club/Society |

**Shared screens:** Facility setup (name, areas, capacity), batch/class creator, schedule builder, member form, plan/package selector

---

### GROUP C: Kitchen → Menu/Plans → Subscribers → Delivery (Production + subscription)
**Setup flow:** Define kitchen/capacity → Create menu items & plans → Add subscribers with dietary preferences → Assign delivery routes

| Businesses |
|---|
| Tiffin/Dabba, Catering, Home Bakery, Mess/Canteen, Juice/Tea Bar, Meal Prep, Cake/Sweets, Cloud Kitchen |

**Shared screens:** Kitchen setup, menu/plan builder, subscriber form (with dietary prefs), delivery zone/route setup, daily opt-in/out dashboard

---

### GROUP D: Depot → Route → Subscriber → Daily Log (Route + recurring delivery)
**Setup flow:** Define depot/center → Create delivery routes → Add subscribers with products/quantities → Daily delivery & collection log

| Businesses |
|---|
| Newspaper, Milk Delivery, Water Can, Flowers, Laundry Pickup, Grocery Sub., Dhobi/Ironing, Gas Cylinder, Garbage Pickup, Baby Supplies |

**Shared screens:** Depot setup, route creator, subscriber form (with product selection + daily quantity), delivery boy assignment, daily log dashboard, container tracking

---

### GROUP E: Facility → Slot/Unit → Renter (Single-level, unit-based)
**Setup flow:** Define facility → Add slots/units with type & size → Add renters/users

| Businesses |
|---|
| Parking Lot, Self-Storage, Boat Marina |
| Co-working (desks/cabins) |
| Market Stalls |
| EV Charging, Laundromat, Farm/Garden |

**Shared screens:** Facility setup (no floors needed), unit grid/map, renter form, slot assignment, access log

---

### GROUP F: Campus → Blocks → Units → Residents + Governance (Association/community)
**Setup flow:** Define campus → Add blocks/towers → Add flats → Add residents/owners → Set maintenance + governance

| Businesses |
|---|
| Gated Community / RWA |
| Temple/Church/Mosque (campus with halls, rooms, kitchen) |
| Community Hall |

**Shared screens:** Campus setup (reuses building configurator), resident/member form, maintenance billing, committee/governance tools, visitor management, event booking

---

### GROUP G: Clinic → Rooms → Patients/Pets (Healthcare, appointment-based)
**Setup flow:** Define facility → Add rooms/bays → Add patients/pets → Track treatments & appointments

| Businesses |
|---|
| Clinic, Pet Boarding/Vet |
| Driving School (vehicle = "room", learner = "patient" with progress milestones) |

**Shared screens:** Facility room setup, patient/pet profile, appointment scheduler, treatment plan tracker, vaccination/milestone tracker

---

## SUMMARY: SETUP FLOW GROUPS

| Group | Pattern | Businesses | Count |
|---|---|---|---|
| A | Building → Floor → Room → Occupant | PG, Hostel, Flats, Hotels, Shops, RWA, etc. | 18 |
| B | Facility → Area → Batch → Member | Gym, Yoga, Tuition, Dance, Studios, Library | 16 |
| C | Kitchen → Menu → Subscriber → Delivery | Tiffin, Catering, Bakery, Mess, etc. | 8 |
| D | Depot → Route → Subscriber → Daily Log | Newspaper, Milk, Water, Laundry, etc. | 10 |
| E | Facility → Slot → Renter | Parking, Storage, Co-working, EV, etc. | 6 |
| F | Campus → Block → Unit → Resident + Governance | RWA, Temple, Community Hall | 3 |
| G | Clinic → Room → Patient → Treatment | Clinic, Vet, Driving School | 3 |
| **TOTAL** | **7 setup flows** | | **64** |

**This means:** You need to build only **7 distinct setup screen flows** to cover all 62+ business types. The billing engine, payment tracking, reminders, receipts, and dashboard are shared across all 7.
