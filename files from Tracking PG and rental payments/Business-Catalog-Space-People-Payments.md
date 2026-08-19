# Business Catalog — Space + People + Recurring Payments

Every business listed here shares the same core structure:
**A physical space → with people occupying or using it → paying recurring fees**

This means one app engine can serve all of them by swapping labels, billing logic, and a few domain-specific features.

---

## How to Read This Catalog

Each entry follows this format:
- **Business type**
- **Space unit** — what the "room" is called
- **Person** — what the "tenant" is called
- **Payment** — what the "rent" is called
- **Cycle** — typical billing frequency
- **Capacity model** — how occupancy works
- **Key pain** — the #1 problem this business has that the app solves
- **Domain-specific feature** — what's unique to this business beyond the core

---

## CATEGORY 1: RESIDENTIAL / STAY-BASED

### 1.1 — PG / Paying Guest
- Space unit: Room / Bed
- Person: Tenant
- Payment: Monthly rent
- Cycle: Monthly
- Capacity: Per-bed (2-sharing, 3-sharing, single)
- Key pain: Cash leakage via caretaker, deposit disputes
- Domain features: Mess/food management, electricity splitting, police verification, move-in/out photos

### 1.2 — Hostel (Student / Working Professional)
- Space unit: Room / Dormitory / Bed
- Person: Resident / Boarder
- Payment: Hostel fee
- Cycle: Monthly / Semester / Yearly
- Capacity: Per-bed (dorm = 8–20 beds, room = 2–4 beds)
- Key pain: Semester-based bulk allocation, parent communication
- Domain features: Warden access, student ID linkage, semester-wise allocation, mess opt-in/out, parent portal

### 1.3 — Co-living Space
- Space unit: Room / Pod / Bed
- Person: Member
- Payment: Monthly membership
- Cycle: Monthly
- Capacity: Per-bed or per-room
- Key pain: High churn, service bundling complexity
- Domain features: Community events, flexible move-in/out, included services (WiFi, cleaning, meals), referral programs

### 1.4 — Service Apartment / Furnished Rental
- Space unit: Apartment / Unit
- Person: Guest / Short-stay tenant
- Payment: Monthly rent / Daily rate
- Cycle: Daily / Weekly / Monthly
- Capacity: Per-unit (1 family or group per unit)
- Key pain: Booking calendar conflicts, cleaning coordination
- Domain features: Booking calendar, check-in/out dates, housekeeping schedule, dynamic pricing

### 1.5 — Rental Apartment (Landlord)
- Space unit: Flat / Apartment
- Person: Tenant
- Payment: Monthly rent
- Cycle: Monthly
- Capacity: Per-flat (1 family per flat)
- Key pain: Tracking rent across multiple flats, agreement renewals
- Domain features: Rental agreement management, TDS tracking, maintenance charges, broker commission tracking

### 1.6 — Gated Community / Apartment Association (RWA)
- Space unit: Flat / Villa
- Person: Resident / Flat owner
- Payment: Maintenance fee
- Cycle: Monthly / Quarterly
- Capacity: Per-flat
- Key pain: Defaulters, lack of transparency in association spending
- Domain features: Visitor management, common-area booking, AGM/voting, expense transparency dashboard, sinking fund tracking

### 1.7 — Lodge / Budget Hotel
- Space unit: Room
- Person: Guest
- Payment: Room charge
- Cycle: Daily / Nightly
- Capacity: Per-room (single, double, family)
- Key pain: No digital booking system, walk-in management
- Domain features: Check-in/out, room availability calendar, ID verification, daily housekeeping log

### 1.8 — Dharamshala / Trust Accommodation
- Space unit: Room / Hall / Dormitory
- Person: Pilgrim / Visitor
- Payment: Donation / Nominal fee
- Cycle: Per-night
- Capacity: Per-bed or per-room
- Key pain: Paper registers, no digital record
- Domain features: Donation receipts, trust reporting, seasonal rush management

### 1.9 — Old Age Home / Senior Living
- Space unit: Room / Suite
- Person: Resident / Senior
- Payment: Monthly care fee
- Cycle: Monthly
- Capacity: Per-bed (single or shared)
- Key pain: Medical tracking, family communication
- Domain features: Medical history, medication schedule, emergency contacts, family update portal, staff duty roster

### 1.10 — Rehabilitation Center
- Space unit: Room / Ward / Bed
- Person: Patient / Resident
- Payment: Program fee
- Cycle: Monthly / Program-based
- Capacity: Per-bed
- Key pain: Program milestone tracking, family billing
- Domain features: Treatment progress, counselor assignment, program phases, family billing portal

---

## CATEGORY 2: EDUCATION & COACHING

### 2.1 — Tuition / Coaching Center
- Space unit: Classroom / Batch
- Person: Student
- Payment: Tuition fee
- Cycle: Monthly / Quarterly / Term
- Capacity: Per-seat (batch of 20–40)
- Key pain: Fee defaults, tracking who paid across multiple batches
- Domain features: Batch scheduling, subject/teacher assignment, attendance, test scores, parent SMS, fee receipts for tax

### 2.2 — Music / Dance / Art Class
- Space unit: Studio / Practice room
- Person: Student
- Payment: Monthly fee / Per-session
- Cycle: Monthly / Per-class pack
- Capacity: Per-slot (group class 10–15, personal 1)
- Key pain: Irregular attendance, pack-based billing complexity
- Domain features: Class schedule, session pack tracking (12 classes in 2 months), makeup class management, recital/event planning

### 2.3 — Language / Spoken English Institute
- Space unit: Classroom
- Person: Learner
- Payment: Course fee
- Cycle: Course-based / Monthly
- Capacity: Per-seat (batch of 10–30)
- Key pain: Batch completion tracking, demo-to-enrollment conversion
- Domain features: Course modules, level progression, demo class scheduling, certificate generation

### 2.4 — Preschool / Daycare / Creche
- Space unit: Room / Activity area
- Person: Child (parent is the payer)
- Payment: Monthly fee
- Cycle: Monthly
- Capacity: Per-child (regulated ratios: 1 staff per 8–10 children)
- Key pain: Parent communication, pickup authorization
- Domain features: Daily activity log, photo updates to parents, authorized pickup list, meal tracking, nap schedule

### 2.5 — Computer Training Center
- Space unit: Lab / Classroom
- Person: Student
- Payment: Course fee
- Cycle: Course-based / Monthly
- Capacity: Per-terminal/seat
- Key pain: Course completion tracking, certificate issuance
- Domain features: Course catalog, lab terminal allocation, certificate generation, placement tracking

### 2.6 — Driving School
- Space unit: Vehicle / Training slot
- Person: Learner
- Payment: Course fee
- Cycle: Package-based
- Capacity: Per-vehicle-slot (1 learner per slot)
- Key pain: Scheduling across multiple instructors and vehicles
- Domain features: Slot booking, instructor assignment, progress milestones (parking, highway, test prep), license application tracking

### 2.7 — Library / Study Hall
- Space unit: Seat / Cabin / Desk
- Person: Member
- Payment: Monthly membership
- Cycle: Monthly / Quarterly
- Capacity: Per-seat
- Key pain: Seat allocation conflicts, peak-hour overcrowding
- Domain features: Seat reservation, time-slot booking, locker allotment, AC/non-AC section pricing

---

## CATEGORY 3: FITNESS & WELLNESS

### 3.1 — Gym / Fitness Center
- Space unit: Hall / Training area
- Person: Member
- Payment: Membership fee
- Cycle: Monthly / Quarterly / Yearly
- Capacity: Per-member (hall limit: 30–50 at a time)
- Key pain: Renewal leakage — packs expire silently, members disappear
- Domain features: Package types (monthly/quarterly/annual), batch timings, trainer assignment, attendance, body metrics tracking, renewal alerts

### 3.2 — Yoga / Pilates / Meditation Studio
- Space unit: Studio / Hall
- Person: Practitioner / Student
- Payment: Monthly fee / Class pack
- Cycle: Monthly / Per-session pack
- Capacity: Per-mat (15–25 per session)
- Key pain: Irregular attendance, seasonal dropoff
- Domain features: Class schedule, session pack countdown, instructor assignment, wellness tracking

### 3.3 — Swimming Pool / Aquatic Center
- Space unit: Pool / Lane
- Person: Member
- Payment: Monthly / Seasonal membership
- Cycle: Monthly / Season (summer)
- Capacity: Per-lane or per-slot (time-based)
- Key pain: Seasonal surge management, safety compliance
- Domain features: Time-slot booking, age-group batches, lifeguard scheduling, water-quality log

### 3.4 — Martial Arts / Boxing / Self-defense Academy
- Space unit: Dojo / Training hall
- Person: Student
- Payment: Monthly fee
- Cycle: Monthly / Belt-level
- Capacity: Per-student (batch of 15–25)
- Key pain: Belt/level progression tracking
- Domain features: Belt/rank progression, grading schedule, tournament registration, sparring partner matching

### 3.5 — Sports Academy / Cricket / Football Coaching
- Space unit: Ground / Court / Net
- Person: Trainee / Player
- Payment: Monthly coaching fee
- Cycle: Monthly / Season
- Capacity: Per-batch (15–30 per batch)
- Key pain: Multi-batch scheduling across limited grounds
- Domain features: Ground/court booking, batch scheduling, match/tournament calendar, performance stats, equipment inventory

### 3.6 — Physiotherapy / Rehabilitation Clinic
- Space unit: Treatment room / Bay
- Person: Patient
- Payment: Session fee / Package
- Cycle: Per-session / Monthly package
- Capacity: Per-bay (1 patient per bay per slot)
- Key pain: Session tracking and package exhaustion
- Domain features: Treatment plan, session countdown, therapist assignment, progress notes, insurance billing

### 3.7 — Spa / Salon (Membership-based)
- Space unit: Treatment room / Chair
- Person: Member / Client
- Payment: Monthly membership / Prepaid credits
- Cycle: Monthly / Credit pack
- Capacity: Per-chair/room per slot
- Key pain: No-shows, credit balance tracking
- Domain features: Appointment booking, credit/wallet balance, stylist/therapist assignment, product upsell tracking

---

## CATEGORY 4: COMMERCIAL & WORKSPACE

### 4.1 — Co-working Space
- Space unit: Desk / Cabin / Meeting room
- Person: Member / Startup
- Payment: Monthly rent / Day pass
- Cycle: Monthly / Daily / Hourly
- Capacity: Per-desk (hot desk = shared, dedicated = fixed)
- Key pain: Flexible billing (some daily, some monthly, some hourly for meeting rooms)
- Domain features: Desk booking, meeting room hourly booking, visitor passes, mail handling, event calendar, community directory

### 4.2 — Shop / Commercial Complex
- Space unit: Shop / Unit / Kiosk
- Person: Tenant / Business owner
- Payment: Monthly rent + maintenance
- Cycle: Monthly
- Capacity: Per-unit
- Key pain: Lease renewal tracking, CAM (common area maintenance) billing
- Domain features: Lease terms, rent escalation schedule, CAM charges, footfall tracking, signage allotment

### 4.3 — Industrial Estate / Warehouse
- Space unit: Unit / Godown / Bay
- Person: Tenant / Lessee
- Payment: Monthly lease
- Cycle: Monthly / Quarterly
- Capacity: Per-unit (by sqft)
- Key pain: Long lease tracking, utility sub-metering
- Domain features: Sqft-based pricing, sub-meter readings, loading dock scheduling, security gate log

### 4.4 — Market / Vendor Stall Area
- Space unit: Stall / Booth / Plot
- Person: Vendor
- Payment: Daily / Monthly rent
- Cycle: Daily / Weekly / Monthly
- Capacity: Per-stall
- Key pain: Daily cash collection from dozens of vendors
- Domain features: Daily fee logging, stall map, vendor rotation, event/mela management

---

## CATEGORY 5: VEHICLE & STORAGE

### 5.1 — Parking Lot / Multi-level Parking
- Space unit: Slot / Bay
- Person: Vehicle owner
- Payment: Monthly parking fee
- Cycle: Monthly / Hourly
- Capacity: Per-slot
- Key pain: Slot allocation conflicts, unauthorized parking
- Domain features: Slot assignment, vehicle number logging, hourly vs monthly billing, RFID/barrier integration

### 5.2 — Self-storage Facility
- Space unit: Locker / Unit
- Person: Renter
- Payment: Monthly rental
- Cycle: Monthly
- Capacity: Per-unit (various sizes)
- Key pain: Access tracking, unit availability
- Domain features: Unit size pricing tiers, access log, insurance, lock management

### 5.3 — Boat Marina / Dock
- Space unit: Berth / Slip
- Person: Boat owner
- Payment: Monthly / Seasonal fee
- Cycle: Monthly / Seasonal / Annual
- Capacity: Per-berth
- Key pain: Seasonal occupancy management
- Domain features: Berth size categories, seasonal pricing, weather alerts, maintenance scheduling

---

## CATEGORY 6: HEALTHCARE

### 6.1 — Clinic / Diagnostic Center (Subscription)
- Space unit: Consultation room / Lab
- Person: Patient / Member
- Payment: Monthly health plan / Visit fee
- Cycle: Monthly / Per-visit
- Capacity: Per-slot (time-based appointments)
- Key pain: Subscription tracking, appointment no-shows
- Domain features: Appointment scheduling, health plan tracking, lab report delivery, doctor assignment

### 6.2 — Veterinary Clinic / Pet Boarding
- Space unit: Kennel / Cage / Room
- Person: Pet (owner is the payer)
- Payment: Boarding fee / Monthly plan
- Cycle: Daily / Monthly
- Capacity: Per-kennel
- Key pain: Pet identification, feeding/medication schedule
- Domain features: Pet profile (breed, weight, medical), vaccination tracker, feeding schedule, owner communication, grooming add-ons

---

## CATEGORY 7: COMMUNITY & RELIGIOUS

### 7.1 — Club / Society Membership
- Space unit: Facility (pool, court, lounge, banquet hall)
- Person: Member
- Payment: Annual membership + monthly dues
- Cycle: Monthly / Annual
- Capacity: Per-member
- Key pain: Multi-facility access tracking, guest pass management
- Domain features: Facility booking, guest passes, event calendar, member directory, committee management

### 7.2 — Temple / Mosque / Church (with managed facilities)
- Space unit: Hall / Room / Community kitchen
- Person: Devotee / Committee member
- Payment: Donation / Event booking fee
- Cycle: Event-based / Monthly
- Capacity: Per-event or per-room
- Key pain: Donation tracking, event booking conflicts
- Domain features: Donation receipts (80G), event/hall booking calendar, volunteer management, prasad/meal distribution log

### 7.3 — Community Center / Cultural Hall
- Space unit: Hall / Room / Open area
- Person: Booking party / Regular renter
- Payment: Booking fee / Monthly rental
- Cycle: Per-event / Monthly
- Capacity: Per-hall (by headcount)
- Key pain: Double-booking, advance/refund tracking
- Domain features: Booking calendar, advance payment tracking, refund policy enforcement, equipment inventory (chairs, AV, stage)

---

## CATEGORY 8: AGRICULTURE & LAND

### 8.1 — Farm Plot Rental / Community Garden
- Space unit: Plot / Bed
- Person: Grower / Renter
- Payment: Monthly / Seasonal rent
- Cycle: Monthly / Season
- Capacity: Per-plot
- Key pain: Seasonal allocation, water/resource sharing
- Domain features: Plot map, crop tracking, shared resource scheduling (water, tools), harvest log

### 8.2 — Nursery / Plant Rental (Subscription)
- Space unit: Greenhouse section / Rack
- Person: Subscriber
- Payment: Monthly subscription
- Cycle: Monthly
- Capacity: Per-plant-slot
- Key pain: Delivery scheduling, plant health tracking
- Domain features: Plant catalog, delivery schedule, care instructions, replacement policy

---

## CATEGORY 9: CREATIVE & HOBBY

### 9.1 — Photography / Art Studio (Rental)
- Space unit: Studio / Darkroom / Editing bay
- Person: Member / Renter
- Payment: Hourly / Monthly membership
- Cycle: Hourly / Monthly
- Capacity: Per-studio (1 shoot per slot)
- Key pain: Time-slot conflicts, equipment damage tracking
- Domain features: Slot booking, equipment checkout, lighting/backdrop inventory, damage deposit

### 9.2 — Maker Space / FabLab
- Space unit: Workbench / Machine bay
- Person: Member
- Payment: Monthly membership / Per-use
- Cycle: Monthly / Per-session
- Capacity: Per-bench + per-machine
- Key pain: Machine scheduling, safety certification tracking
- Domain features: Machine booking (3D printer, laser cutter), safety cert per member, material cost add-ons, project showcase

### 9.3 — Music Rehearsal / Podcast Studio
- Space unit: Room / Booth
- Person: Band / Creator
- Payment: Hourly / Monthly membership
- Cycle: Hourly / Monthly
- Capacity: Per-room per slot
- Key pain: Hourly booking management, equipment setup
- Domain features: Room booking, equipment list per room, soundproofing grade, recording add-on pricing

---

## CATEGORY 10: MISCELLANEOUS

### 10.1 — EV Charging Station (Subscription)
- Space unit: Charging point / Bay
- Person: Subscriber / Vehicle owner
- Payment: Monthly plan / Per-use
- Cycle: Monthly / Per-charge
- Capacity: Per-point
- Key pain: Slot availability, billing per kWh vs flat fee
- Domain features: Charger availability status, kWh metering, slot reservation, vehicle type compatibility

### 10.2 — Laundromat (Membership)
- Space unit: Machine / Slot
- Person: Member
- Payment: Monthly plan / Per-wash
- Cycle: Monthly / Per-use
- Capacity: Per-machine per time slot
- Key pain: Machine availability, load tracking
- Domain features: Machine booking, wash cycle tracking, pickup/delivery scheduling

### 10.3 — Coworking Kitchen / Cloud Kitchen Bay
- Space unit: Kitchen bay / Station
- Person: Chef / Food brand
- Payment: Monthly rent + revenue share
- Cycle: Monthly
- Capacity: Per-bay
- Key pain: Shared resource scheduling (ovens, cold storage), hygiene compliance
- Domain features: Bay assignment, shared equipment booking, FSSAI compliance tracker, order volume tracking

### 10.4 — Cemetery / Burial Plot
- Space unit: Plot / Niche
- Person: Family / Estate
- Payment: One-time + Annual maintenance
- Cycle: Annual
- Capacity: Per-plot (permanent)
- Key pain: Perpetual maintenance tracking, family contact updates over decades
- Domain features: Plot map, genealogy linking, maintenance schedule, memorial services

---

## CATEGORY 11: FOOD & KITCHEN

### 11.1 — Tiffin / Dabba Service
- Space unit: Kitchen
- Person: Subscriber
- Payment: Monthly meal plan
- Cycle: Monthly
- Capacity: Per-tiffin (daily output capacity)
- Key pain: Headcount changes daily (pauses, skips, new joins), manual billing
- Domain features: Daily opt-in/out, menu rotation calendar, pause/resume per subscriber, delivery boy route assignment, container return tracking

### 11.2 — Catering (Regular Contracts)
- Space unit: Kitchen / Banquet
- Person: Client (office, hostel, event venue)
- Payment: Monthly contract / Per-event
- Cycle: Monthly / Per-event
- Capacity: Per-contract (headcount-based)
- Key pain: Multi-client headcount tracking, menu customization per client
- Domain features: Contract terms, headcount per client, menu per client, staff deployment, FSSAI compliance

### 11.3 — Home Bakery (Subscription)
- Space unit: Kitchen / Studio
- Person: Customer / Subscriber
- Payment: Monthly box / Per-order
- Cycle: Monthly / Weekly / Per-order
- Capacity: Per-batch (daily baking capacity)
- Key pain: Order tracking, advance booking for custom cakes, ingredient cost tracking
- Domain features: Order calendar, custom order form, ingredient cost calculator, delivery schedule, Instagram/WhatsApp order intake

### 11.4 — Mess / Canteen
- Space unit: Dining hall
- Person: Member / Student / Employee
- Payment: Monthly mess fee
- Cycle: Monthly
- Capacity: Per-member (seating + meal prep capacity)
- Key pain: Daily headcount for meal prep, food wastage, who's eating today
- Domain features: Daily meal opt-in/out, menu rotation, grocery/vendor expense, wastage log, veg/non-veg split

### 11.5 — Juice / Smoothie / Tea Bar (Membership)
- Space unit: Counter / Kiosk
- Person: Member
- Payment: Monthly plan (1 drink/day)
- Cycle: Monthly / Per-use credits
- Capacity: Per-member
- Key pain: Tracking daily redemptions against plan limits
- Domain features: Daily redemption log, plan types (1/day, 2/day), add-on charges, loyalty points

### 11.6 — Meal Prep / Diet Food Service
- Space unit: Kitchen
- Person: Subscriber
- Payment: Weekly / Monthly plan
- Cycle: Weekly / Monthly
- Capacity: Per-subscriber (daily meal prep)
- Key pain: Dietary customization per subscriber, delivery logistics
- Domain features: Diet plan per subscriber (keto, vegan, diabetic), calorie/macro tracking, delivery slot management, nutritionist assignment

### 11.7 — Cake / Sweet Shop (Bulk Orders)
- Space unit: Kitchen / Shop
- Person: Recurring client (offices, event planners)
- Payment: Per-order / Monthly retainer
- Cycle: Per-order / Monthly
- Capacity: Per-order (production capacity)
- Key pain: Advance order tracking, seasonal rush management
- Domain features: Order calendar, advance booking with token, flavor/design catalog, production queue

### 11.8 — Cloud Kitchen
- Space unit: Kitchen bay / Station
- Person: Chef / Food brand
- Payment: Monthly rent + revenue share
- Cycle: Monthly
- Capacity: Per-bay
- Key pain: Shared resource scheduling (ovens, cold storage), hygiene compliance
- Domain features: Bay assignment, shared equipment booking, FSSAI compliance tracker, order volume tracking

---

## CATEGORY 12: DELIVERY & ROUTE-BASED

### 12.1 — Newspaper Delivery
- Space unit: Distribution center
- Person: Subscriber (household / shop)
- Payment: Monthly bill
- Cycle: Monthly
- Capacity: Per-route (200–400 houses per delivery boy)
- Key pain: Cash collection from hundreds of doors, pocket-notebook tracking, start/stop/vacation adjustments
- Domain features: Route mapping, multi-publication per subscriber (TOI + local paper + magazine), pro-rata pause/resume, delivery boy assignment, daily non-delivery complaints, payment collection log per delivery boy

### 12.2 — Milk Delivery
- Space unit: Collection / Distribution center
- Person: Subscriber
- Payment: Monthly bill
- Cycle: Monthly (daily delivery)
- Capacity: Per-route
- Key pain: Daily quantity changes (500ml today, 1L tomorrow), festival spikes, cash collection
- Domain features: Daily quantity log per subscriber, product variants (toned, full cream, curd, buttermilk), delivery boy route, monthly auto-billing based on daily log

### 12.3 — Water Can Supply
- Space unit: Warehouse / Plant
- Person: Subscriber (household / office)
- Payment: Per-delivery / Monthly plan
- Cycle: Monthly / Per-can
- Capacity: Per-route + per-truck
- Key pain: Reorder tracking (who needs a refill when), empty can return tracking
- Domain features: Delivery schedule, empty can return log, auto-reorder alerts, truck/driver assignment

### 12.4 — Flower Delivery (Temple / Pooja)
- Space unit: Garden / Collection center
- Person: Subscriber
- Payment: Monthly subscription
- Cycle: Monthly (daily delivery)
- Capacity: Per-route
- Key pain: Seasonal flower availability, festival-day surge
- Domain features: Daily delivery log, festival calendar with auto-upsell, flower type preference per subscriber

### 12.5 — Laundry / Ironing Pickup-Drop
- Space unit: Laundry facility
- Person: Subscriber / Customer
- Payment: Monthly plan / Per-piece
- Cycle: Monthly / Per-pickup
- Capacity: Per-route (pickup slots)
- Key pain: Garment tracking (which clothes belong to whom), damage claims
- Domain features: Per-garment tag tracking, pickup/drop scheduling, damage photo log, garment count per pickup, express service add-on

### 12.6 — Grocery / Essentials Subscription
- Space unit: Store / Dark store
- Person: Subscriber
- Payment: Weekly / Monthly kit price
- Cycle: Weekly / Monthly
- Capacity: Per-route
- Key pain: Kit customization per subscriber, last-mile delivery coordination
- Domain features: Kit builder (subscriber picks items), substitution preferences, delivery slot booking, recurring auto-order

### 12.7 — Dhobi / Ironing Service (Colony-based)
- Space unit: Ironing cart / Shop
- Person: Household subscriber
- Payment: Monthly flat fee / Per-piece
- Cycle: Monthly / Weekly
- Capacity: Per-colony / Per-route
- Key pain: Piece-count disputes, cash collection across 50–100 houses
- Domain features: Piece-count log per pickup, monthly auto-tally, rate card (shirt ₹8, pant ₹10, saree ₹15), cash collection tracker per colony

### 12.8 — Gas Cylinder Delivery
- Space unit: Depot / Agency
- Person: Customer / Connection holder
- Payment: Per-delivery
- Cycle: On-demand (~monthly)
- Key pain: Subsidy tracking, refill scheduling, empty cylinder return
- Domain features: Connection number tracking, last-refill date, auto-remind when due, delivery scheduling, subsidy vs market-rate billing

### 12.9 — Garbage / Waste Collection (Private)
- Space unit: Collection zone
- Person: Household / Business subscriber
- Payment: Monthly fee
- Cycle: Monthly
- Capacity: Per-route
- Key pain: Daily pickup confirmation, complaints on missed pickups
- Domain features: Daily pickup log, missed-pickup complaints, segregation compliance (wet/dry), vehicle/staff route assignment

### 12.10 — Diaper / Baby Supply Subscription
- Space unit: Warehouse / Store
- Person: Parent subscriber
- Payment: Monthly box
- Cycle: Monthly / Bi-weekly
- Capacity: Per-subscriber
- Key pain: Size changes as baby grows, auto-adjustment of contents
- Domain features: Baby age/weight tracking, auto-size upgrade, delivery scheduling, product swap preferences

---

## Summary Stats

| Category | Count |
|---|---|
| Residential / Stay | 10 |
| Education & Coaching | 7 |
| Fitness & Wellness | 7 |
| Commercial & Workspace | 4 |
| Vehicle & Storage | 3 |
| Healthcare | 2 |
| Community & Religious | 3 |
| Agriculture & Land | 2 |
| Creative & Hobby | 3 |
| Miscellaneous | 3 (Cloud Kitchen moved to Food & Kitchen) |
| Food & Kitchen | 8 |
| Delivery & Route-based | 10 |
| **TOTAL** | **62** |

---

## The Universal Data Model

Every single one of the 62 businesses above maps to:

```
Organization (the business)
  └── Resource(s) (building / kitchen / depot / route)
        └── Zone(s) (floor / section / area / route segment)
              └── Unit(s) (room / desk / slot / bed / tiffin / newspaper subscription)
                    └── Subscriber(s) (tenant / member / student / customer / household)
                          └── Subscription(s) (rent / fee / membership / meal plan / delivery plan)
                                └── Payment(s) (monthly / per-use / annual / per-delivery)
                                      └── Reminder → Receipt → Ledger
```

The resource can be:
- **A space** — room, hall, desk, slot, plot (Categories 1–9)
- **A production facility** — kitchen, bakery, prep station (Category 11)
- **A delivery route** — newspaper round, milk route, pickup zone (Category 12)

Only 3 things change per business:
1. **Labels** — what you call each layer (room vs desk vs slot vs route vs kitchen)
2. **Billing model** — monthly fixed vs per-use vs pack-based vs seasonal vs per-delivery
3. **Domain extras** — the 2–3 features unique to that business (belt ranks for martial arts, semester allocation for hostels, container return for tiffin, route mapping for newspaper)

The engine underneath — resource setup, people management, recurring billing, reminders, receipts, ledger, dashboard — is identical for all 62.

---

## Recommended Product Strategy

**Phase 1 (MVP):** PG / Hostel owners — sharpest pain, fastest feedback, concentrated in Indian cities.

**Phase 2:** Gym + Tuition + Coaching — same billing engine, different labels, huge market in every Indian neighborhood.

**Phase 3:** Gated communities / RWAs — higher LTV per customer (500+ flats), maintenance fee collection.

**Phase 4:** Food & Kitchen — tiffin services, mess, bakeries. Subscription + headcount billing. Every Indian city has hundreds of tiffin operators tracking fees in notebooks.

**Phase 5:** Delivery & Route-based — newspaper, milk, laundry, water. Route + subscriber billing. Millions of delivery agents across India with zero digital tools.

**Phase 6:** Everything else — the platform is label-agnostic by now, onboarding any new vertical is just a new template with the right labels and 2–3 domain features.

**The onboarding screen adapts:**

```
"What do you manage?"

🏠 PG / Hostel          → Room, Tenant, Rent
🏋️ Gym / Fitness        → Hall, Member, Fee
📚 Coaching / Tuition    → Classroom, Student, Fee
🏢 Apartment / RWA       → Flat, Resident, Maintenance
🅿️ Parking              → Slot, Vehicle owner, Parking fee
💼 Co-working            → Desk, Member, Subscription
🏪 Commercial complex    → Shop, Tenant, Rent
🎨 Studio / Creative     → Room, Member, Membership
🍱 Tiffin / Catering     → Kitchen, Subscriber, Meal plan
🍰 Bakery / Mess         → Kitchen, Customer, Order / Fee
📰 Newspaper / Milk      → Route, Subscriber, Monthly bill
👕 Laundry / Delivery     → Route, Customer, Monthly plan
⚙️ Other                 → (custom labels)
```

One selection, and the entire app relabels itself. Same engine. 62 markets.
