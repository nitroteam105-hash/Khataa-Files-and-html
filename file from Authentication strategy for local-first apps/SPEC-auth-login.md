# SPEC — Auth, Sign-up & Login

**Status:** Specced (not built)
**Build position:** Phase 3, item 15 (BUILD-ORDER.md). Blocked behind items 10–14.
**Scoped ahead of schedule** — do not build until Phase 3.

---

## 1. Core principle

Auth is **not a gate. It is a claim.**

The app is local-first. SQLite on the device is the primary store and the app is
fully functional with no account, forever, on the free tier. Login exists only to
attach local data to a cloud identity so it can be synced on paid tiers.

Every design decision below follows from that.

---

## 2. Tier structure

**No ads in any tier.** (Re-confirmed after a 4-tier ad-supported model was
considered and rejected — ads appear on customer-facing screens like bills and
payment reminders, which damages the *user's* credibility with *their* customer.)

| Tier | Includes |
|---|---|
| **Free** | Local-only, single device, unlimited businesses, all core features |
| **Pro** | Google Drive backup + restore, bill themes/branding |
| **Premium** | Live cloud sync, multi-device, multi-user staff, advanced reports, priority support |

Key economic property: **Pro costs nothing to serve.** Backup lands in the user's
own Google Drive (BYOS). Only Premium touches paid infrastructure.

## 2a. Decisions locked

| # | Decision |
|---|----------|
| D1 | Sign-up is **skippable** at first launch — "Continue without account" |
| D2 | Free tier auth = **Google Sign-In** + email/password fallback |
| D3 | Phone + OTP collected **at Premium upgrade only** — not Free, not Pro |
| D4 | Phone becomes the **multi-device login key** for Premium users |
| D5 | On sign-in with existing local data → **claim it** (see §5 for the fork) |
| D6 | Free tier remains **local-only** even when signed in |
| D7 | Logout **never** deletes local data |
| D8 | Pro requires a **connected Google Drive**, separate from sign-in (see §3a) |

---

## 3. Identity model

There is **one** account. Phone and Google are two credentials on it, not two accounts.

```
auth.users (Supabase)
  ├── identity: google      ← created at free-tier sign-in
  ├── email + password      ← fallback credential
  └── phone (verified)      ← added at PREMIUM upgrade, enables new-device login
```

Phone is deliberately **not** collected at Pro. Pro restores from Drive using the
Google account, so it never needs OTP — which keeps SMS cost off an entire paid
tier.

## 3a. Google Drive is a second consent

Signing in with Google gives **identity only.** Drive access is a separate OAuth
scope with its own consent screen. A user who signed in with Google still has to
approve Drive access at Pro upgrade, and a user who signed up with email/password
has to connect a Google account at that point too.

Scope decision — pick one before building:

| Scope | Behaviour |
|---|---|
| `drive.appdata` | Hidden app folder. User can't see, move or delete backups. Cleaner, but invisible — user can't independently verify their backup exists. |
| `drive.file` | Files the app creates are visible in the user's Drive. User can download, copy, keep after uninstall. Also means they can delete them by accident. |

Recommendation: **`drive.file`.** Two reasons, the second decisive:

1. For a money app sold on "you won't lose your books", a backup the user can see
   and download themselves is worth more than one they must trust blindly.
2. **`drive.file` is non-sensitive and avoids CASA entirely.** Restricted scopes
   (full `drive`, `drive.readonly`) require an annual third-party ADA-CASA security
   assessment — roughly $500–$4,500/year, revalidated every 12 months, forever.
   Choosing the wrong scope turns a zero-cost tier into a permanent annual bill
   larger than the tier's margin.

> Caveat to confirm at verification: Google's guidance names "backup clients" as a
> case where `drive.file` may not suffice. That targets apps backing up files they
> did not create. Khaata creates its own backup blobs, so `drive.file` should hold —
> but verify rather than assume.

## 3b. Play Store compliance

Adding accounts to the app pulls in obligations that did **not** apply when the
app was purely local. All of these are pre-submission blockers.

| Requirement | Detail |
|---|---|
| **In-app account deletion** | A path from Settings to delete account + associated data. Deletion, not deactivation. |
| **Web deletion URL** | A publicly reachable page where users can request deletion **without installing the app.** Separate from the in-app path — both are required. |
| **Data safety form** | Play Console → App content. Must declare what's collected and the deletion answers. Shows on your store listing. |
| **Privacy policy URL** | Required once any user data is collected. |

**Optional sign-up does not exempt you.** The requirement applies to any app that
offers account creation, including via third-party login, whether or not it is
skippable. D1 does not avoid this.

**New infrastructure implied:** you currently have no website. The web deletion
URL and the privacy policy both need hosting. A static page with a form that
emails you is sufficient — GitHub Pages or similar, near-zero cost — but it must
exist before first submission.

**Identity verification problem to solve:** the web deletion page must confirm the
requester actually owns the account before deleting anything. Simplest compliant
path is a "sign in with Google to confirm deletion" step on that page rather than
a free-text form.

### The linking trap — READ BEFORE BUILDING

Supabase auto-links identities **only when verified emails match.** A phone
identity carries no email, so it will **not** auto-link. If phone is registered
as a separate sign-in, the user gets **two accounts and their data splits.**

Correct mechanism:

1. User signs in with Google → `auth.users` row created
2. User upgrades → `updateUser({ phone })`
3. Verify with `verifyOtp({ type: 'phone_change' })`
4. Phone is now written onto the **existing** user row
5. On a new device, `signInWithOtp({ phone })` resolves to that same user

**Verify this against current Supabase docs before implementing.** Identity-linking
behaviour has changed between versions and this is expensive to fix after users exist.

---

## 4. Screens

### 4.1 Welcome / Auth choice — first launch
- Primary: **Continue with Google** (one tap, no typing)
- Secondary: Continue with email
- Tertiary, visually quiet but not hidden: **Continue without account**
- Copy must state: free tier works fully without an account

### 4.2 Email sign-up / sign-in
- Email + password, single screen, toggle between modes
- Forgot password link → Supabase reset email

### 4.3 Phone verification — Premium upgrade only
- Entry point: **Premium** upgrade. Never on Free, never on Pro.
- +91 default, digits-only, 6/7/8/9 first-digit rule (matches existing customer
  phone field validation — reuse that component)
- OTP entry, resend timer, change-number link

### 4.4 Account screen — settings
- Signed out: shows sign-in prompt + honest "data is on this phone only"
- Signed in, free: account email, **"Data stored on this phone only"** warning,
  upgrade CTA
- Signed in, paid: email, verified phone, last sync time, sign out

---

### 4.5 Delete account — required by Play (§3b)

Design principle: **a warning is not a safeguard.** The flow must make an accidental
tap non-catastrophic, not merely well-labelled.

Flow:

1. **Entry** — Settings, in its own section, visually separated from Sign out.
   Most likely real-world disaster is a user who meant to sign out.
2. **Export step** — not optional-looking, not a footnote. "Save your records
   first" with a one-tap export. Skippable, but presented as the default path.
3. **Choose what to delete** — a single either/or, not checkboxes. Two independent
   boxes produce four combinations (one meaningless) and force a notebook user to
   reason about cloud-vs-local storage.
   - Delete my account, **keep my records on this phone**
   - **Delete everything** — account and all records on this phone

   Default: neither pre-selected. User must choose.

   **The warning text must be tier-aware.** A blanket "all your data will be
   deleted" is false for most users, and false warnings train people to tap
   through real ones.

   | Tier | What deleting the account actually destroys |
   |---|---|
   | Free | The login only. Books were never on our servers. |
   | Pro | Login + the Drive backup. Phone records untouched. |
   | Premium | Login + cloud records + other devices lose access. |
4. **Confirm** — typed confirmation if "this phone" is checked, matching the
   project's tiered-confirmation rule for money-affecting actions.
5. **Grace period** — cloud side soft-deletes, hard-deletes after ~30 days, with
   an email explaining how to cancel. *Confirm this satisfies Play's wording.*

Copy rules:
- Name the actual things: "your bills, customers and udhaar records" — never
  "associated data"
- State plainly what is **not** deleted, not only what is
- No legalese anywhere in this flow
- **Ban the word "disconnect"** from the UI. It sounds mild and could mean sign
  out, revoke Drive, or delete account. Use concrete phrasing: "Sign out of this
  phone", "Stop backing up to Drive", "Delete my account".



When a user signs in on a device that already holds local data:

There are now **two** kinds of prior data to check for, and they live in different
places:

| Prior data found | Where it lives | Behaviour |
|---|---|---|
| Nothing | — | Claim silently. Write account to `local_account`. No prompt. |
| **Drive backup** (Pro history) | User's Google Drive | **Must prompt.** |
| **Cloud rows** (Premium history) | Supabase | **Must prompt.** |

Detection differs: Drive requires the Drive scope to even look, so a free user
signing in **cannot** see their own old Pro backup until they grant Drive access.
Practical consequence — the collision may surface late, at Pro upgrade rather than
at sign-in. Check at both points.

For the prompt case, offer:
- Keep this phone's data (cloud copy archived, not deleted)
- Load the account's data (local archived, not deleted)

**Nothing is ever destroyed on either path.** Archive-first, consistent with the
project-wide deletion principle.

> Note: on free tier this collision is invisible (no sync runs), but the stamp
> persists and detonates at upgrade. Detect and resolve at **sign-in time**, not
> at upgrade time.

---

## 6. Free-tier honesty rule

There are three protection states and the UI must never blur them:

| Tier | True status | Copy must say |
|---|---|---|
| Free | Nothing protected | "Data is on this phone only" |
| Pro | Backup exists, may be stale | "Last backed up to Drive: {time}" |
| Premium | Live | "Synced {time}" |

A signed-in free user has an account but **no backup**. This must be stated
plainly wherever account state is visible:

- Account screen: persistent, non-dismissible line — data is on this phone only
- Never use the words "backup", "synced", or "safe" in free-tier account UI
- Pro must always show **last backup time**, never a bare "Backed up" — a
  three-week-old backup presented as protection is the same failure as no backup

### The warning must come with a free remedy

Stating the risk while offering only payment as the fix is manufactured anxiety
sold back as a cure. **Free users must be able to export a backup file themselves**
(BUILD-ORDER item 10) — to device storage, WhatsApp, anywhere.

That turns the §6 warning from leverage into genuine help: here is the risk, here
is the free way to handle it, Pro simply makes it automatic. Same upgrade path,
no fear tax.
- Losing the phone loses the data — this is true, and saying so is also the
  clearest upgrade argument you have

Getting this wrong produces the single worst support outcome available: a user
who believed they were protected and wasn't.

---

## 7. Logout

- Local data is **kept**, always
- Clears the account row from `local_account`, nothing else
- Paid user logging out → sync stops, data remains readable locally
- Confirmation dialog required for paid users (they may expect a wipe)

---

## 8. Schema deltas

**Do not add `user_id` to every table.** Single-user-per-device means the data
belongs to the device and the device belongs to an account.

New table:

```sql
CREATE TABLE local_account (
  id                INTEGER PRIMARY KEY CHECK (id = 1),  -- single row
  auth_user_id      TEXT,          -- Supabase uid, NULL when signed out
  email             TEXT,
  phone_e164        TEXT,
  phone_verified_at TEXT,          -- ISO 8601
  tier              TEXT NOT NULL DEFAULT 'free',
  claimed_at        TEXT,
  updated_at        TEXT NOT NULL
);
```

Ownership only becomes real where it must:
- `businesses.owner_user_id` — nullable, set at claim
- `business_members` — deferred to Premium multi-user work, not needed now

---

## 9. Cost notes

- Google Sign-In: free
- Email/password: free, but Supabase's built-in SMTP is rate-limited and not for
  production. Needs a real provider before launch (Resend free tier ≈ 3,000
  emails/month is likely sufficient at early scale)
- Google Drive backup (Pro): **free to you** — user's own Drive quota, BYOS
- Phone OTP: requires own SMS provider, ~₹0.15–0.25 per send including failed
  retries. **Premium only**, so it hits your smallest and highest-paying cohort.
  Moving sync to Premium removed SMS cost from the entire Pro tier.
- Supabase sync (Premium): the only tier with real per-user infrastructure cost

---

## 10. Subscription lapse & access revocation

**Governing principle: downgrade removes features, never data.** The user created
those records. Withholding a shopkeeper's ledger to force resubscription is both
wrong and reputationally fatal.

### 10.1 Lapse is four states, not one

| State | Treatment |
|---|---|
| Auto-renew cancelled | Nothing changes. Access runs to end of paid period. |
| Payment failed | Still Premium through Play's grace-period and account-hold states. *Verify current Play Billing state machine before building.* |
| Expired | The actual downgrade moment. |
| Refund / chargeback | Immediate. Rare enough to handle manually at early scale. |

### 10.2 At expiry

- **Cloud rows:** sync stops, data retained **30 days**, then purged.
  Warning emails at expiry, day 15, day 25 — each with a **one-tap export**.
- **Multi-device divergence:** free tier is single-device, so a lapsed Premium
  user with two synced phones exceeds it. Both keep working locally and drift
  immediately. Resolve **at expiry**, not at resubscribe — prompt the user to
  nominate a primary device while they still know which is which.
- **Issued bills never change.** Lapsed themes/branding must not alter documents
  already issued. Bills are snapshots. Non-negotiable.
- **Local data:** fully usable, forever, on the free tier. Untouched by lapse.

### 10.3 Staff access revocation

Applies on Premium lapse **and** on ordinary staff removal.

**Decision: wipe staff device copy fully on revocation.**

Threat being addressed: a departing employee retaining the shop's complete
customer list and outstanding-dues ledger on their personal phone.

**A push wipe alone is insufficient** — it only fires if the device comes online.
Airplane mode, revoked network permission, or simply never reopening the app
defeats it. Therefore:

1. **Lease model (the guarantee).** Staff local data carries a TTL. The app
   refuses to open it without a successful check-in renewing the lease. Going
   offline accelerates expiry rather than preventing it.
2. **Push wipe (the fast path).** Fires immediately when the device is reachable.
3. **Scope reduction (the real fix).** Don't sync sensitive material to staff
   devices at all. Reuse the existing permission insight — View/Can-Edit plus
   split-out sensitive sub-pages. If dues and full customer contacts live on
   pages staff don't have, there is far less to revoke.

> **Honest ceiling:** anyone able to root the device can extract the SQLite file
> regardless. This is a reasonable-measures control against a normal departing
> employee, not a guarantee against a determined attacker. Do not describe it to
> users as more than it is.

### 10.3a Entitlement is not connectivity

These are two separate clocks and must not be conflated.

| Device | Behaviour with no network |
|---|---|
| **Owner** | Works fully, always. Local-first. Identical to free tier. Never blocked, never a "no network" screen. |
| **Staff** | Works until the lease expires. Access is delegated, and delegation has an expiry. |

Premium never *reduces* the owner's capability. A paying user blocked by a network
error while a free user on the same phone keeps working is a broken product.

Sync state is surfaced honestly, never as a blocker:
- Quiet persistent indicator — "Synced 2 min ago" / "3 changes waiting"
- Escalate visually if stale beyond ~24h (may be a real fault, not a tunnel)
- Never modal, never blocking

### 10.3b Lease parameters

- **Lease length: 3 days.** Staff app requires a successful check-in to renew.
- **Hard ceiling:** the lease also carries the subscription's known end date and
  can never outlive it, even with no check-in. Without this, a phone leased on
  day 1 keeps working past a day-3 lapse.
- The lease TTL must always be **shorter** than the retention window, never longer.

### 10.3c Revocation deletes access, not records

Work already performed belongs to the **owner**. Attendance taken Tuesday survives
a Wednesday lapse. Since attendance, payments and advances are stored as dated
immutable events, this follows naturally — but revocation code must be explicit:
delete the staff device's *access and cached dataset*, never the event records on
the owner's device.

### 10.3d Unsynced staff work at lease expiry

**Decision: hold the queue, keep retrying, warn the owner.**

Sequence:
1. On lease expiry, attempt a final push before locking the UI
2. If unreachable — **lock the UI, wipe the cached dataset on schedule anyway**,
   but retain the unpushed event queue
3. Keep retrying in background
4. Warn the owner, naming what is missing

Constraints:
- **The held queue is narrow by design** — unpushed events only, never the cached
  dataset. Those events still contain customer names and amounts, so this is a
  deliberately limited exception to the wipe, not a loophole in it.
- **The queue needs an outer expiry** or a departed employee's phone holds those
  events indefinitely.
- **Retry is best-effort, not a guarantee.** A staff member who quits and never
  reopens the app never delivers Tuesday's attendance.

Therefore the **owner-side warning is the real recovery path**, not the retry. It
must name specifics — "2 days of attendance from Ravi's phone haven't arrived" —
so the owner can ask him or re-enter it. Human fallback is the actual mechanism.

### 10.4 Asymmetry to build around

**Owner data is theirs and stays. Staff data is borrowed and expires.**

**Confirmed: the hard stop applies to staff devices only.** The owner is never
locked out of records they created. Premium sells sync, multi-device and staff
access — it never sold the owner the right to read their own ledger. A lapsed
owner must never be worse off than a free user on the same phone.

## 11. Open items

1. **Two free devices, one Google account.** Both hold separate local data, both
   stamped with the same account, neither knows about the other. Collides at
   upgrade. Likely resolved by §5's prompt, but needs confirming.
2. **Premium staff login.** Staff sign in with their own account and get invited
   to a business. Does that reuse this screen, or is there a separate join-by-invite
   entry? Deferred until multi-user work.
3. **Account deletion scope.** Resolved that it's required (§3b). Still open: does
   deleting the account also wipe **local** data on the device? Policy covers
   account and associated data; local-only records were never sent anywhere.
   Recommend: delete cloud/Drive data, offer local wipe as a separate choice, and
   state clearly which is which.
4. **Web deletion page hosting** — needs deciding alongside privacy policy hosting.
5. **Offline bill numbering across staff devices — UNRESOLVED.** Consecutive series
   with no gaps is a legal requirement, but two staff phones issuing bills offline
   will both claim the same next number. Unlike attendance or payments, this
   *cannot* be reconciled after the fact. Options: per-device number blocks,
   device-prefixed series (A-001 / B-001), or only the primary device issues bills
   offline. **Decide during bills work — this constrains the numbering schema.**
6. **Staff queue outer expiry** — how long a revoked phone may retain unpushed
   events before discarding them (§10.3d).
7. **Resubscribe reconciliation — UNRESOLVED.** Owner works locally through the
   lapse, so on resubscribe there are multiple independently-written sources
   (owner device, frozen cloud copy, held staff queues). Two approaches:
   - *Merge by event timestamp* — correct, handles staff queues, but needs
     same-field conflict handling
   - *Owner device is source of truth, full re-upload replaces cloud* — no merge
     logic, no conflicts, but overwrites any staff events that reached the cloud
     pre-lapse and aren't on the owner's phone (narrow window in practice)

   Leaning toward full re-upload for simplicity. **Decide before sync is built.**
8. **Resubscribe after the 30-day purge** — cloud is gone; owner device re-uploads,
   but staff phones have lost lease and cache and need fresh invites. Should be a
   designed flow, not an error state.
