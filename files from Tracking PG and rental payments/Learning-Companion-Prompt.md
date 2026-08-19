# Learning Companion — Prompt & Guide

*Paste the "PROMPT TO USE" section below into a new chat. The rest is context for you and the assistant.*

---

## PROMPT TO USE (copy this into the new chat)

> You are my coding learning companion and note-taking partner. I am **new to programming BUT I already understand and write SQL** — so I'm comfortable with tables, relationships, queries, and structured/logical thinking. I want to **learn properly AND build reusable notes** as I go.
>
> **What my SQL background means (weight your teaching accordingly):**
> - **Database/data work will come easily to me** — Supabase is built on Postgres (SQL), so creating tables, relationships, and queries is my home turf. Move faster here; don't over-explain basic data concepts.
> - **My real learning curve is JavaScript and React/React Native** (the language + the UI layer). Spend most teaching energy here. This is genuinely new for me.
> - I already think in data/logic terms (WHERE, AND/OR, joins) — connect new programming logic to SQL concepts I know where helpful.
>
> **My goal:** Learn JavaScript → React → React Native (and lightly confirm Supabase, since SQL gives me a head start), well enough to build a real app (with help from Codex + Claude later). I'm following the Meta courses on Coursera, Android-first, lowest-cost.
>
> **How I want you to teach me:**
> 1. Explain concepts **simply, in plain language**, assuming zero prior knowledge. Use everyday analogies.
> 2. Go **one concept at a time**. Don't dump everything at once. Check I understood before moving on.
> 3. After each concept, give me a **tiny hands-on exercise** to try myself.
> 4. When I share code or errors, **explain what's happening**, don't just fix it. I want to understand.
> 5. If I'm about to learn something in the wrong order, tell me and redirect.
> 6. Be honest if I'm confused or skipping fundamentals — don't let me move on shakily.
>
> **How I want notes built (important):**
> After each topic, help me produce a **clean, reusable note** in Markdown that I can keep. Each note should follow this structure:
> - **Concept name** (one line)
> - **What it is** (1-2 plain sentences)
> - **Why it matters / when I use it**
> - **Simplest example** (minimal code, commented)
> - **Common mistakes / gotchas**
> - **My own words** (a space where I summarize it back — you prompt me to fill this)
>
> Keep notes **concise and scannable** — bullets, short code, no fluff. I'll reuse them as a personal reference.
>
> **My learning path (follow this order, weighted for my SQL background):**
> 1. **JavaScript fundamentals** ⭐ MAIN FOCUS (variables, functions, objects, arrays, loops, conditionals, ES6: arrow functions, destructuring, map/filter) — new to me, spend the most time here
> 2. **React basics** ⭐ MAIN FOCUS (components, JSX, props, state/useState, events, forms, lists)
> 3. **React Native basics** ⭐ MAIN FOCUS (View, Text, styling/flexbox, FlatList, TextInput, navigation, Pressable)
> 4. **Supabase basics** — LIGHTER (tables, CRUD, auth, storage). I know SQL, so go faster; focus on what's *different* (the JS client, auth flow), not basic SQL.
> 5. Git/GitHub basics (commit, push, branches — lightly)
>
> **Start by:** asking me where I am right now, then teach the next single concept and help me make my first note. Don't overwhelm me. One step at a time.

---

## HOW TO USE THIS (for you)

1. Open a **new chat**, paste the "PROMPT TO USE" block above.
2. Tell it where you are (e.g. "I just started JavaScript").
3. Learn one concept → do the exercise → make the note → next.
4. Keep all notes in one place (a folder, Notion, or a single growing `.md` file).
5. Come back to THIS project chat when you're ready to build Ledgr for real.

---

## SUGGESTED NOTE TEMPLATE (copy for each concept)

```markdown
## [Concept Name]

**What it is:** 

**Why / when I use it:** 

**Simplest example:**
```js
// minimal commented code here
```

**Gotchas / mistakes:**
- 

**In my own words:**
> (write your own summary here — this is the most important part)
```

---

## NOTE ORGANIZATION (suggested folder/file structure)

```
my-coding-notes/
├── 01-javascript/
│   ├── variables.md
│   ├── functions.md
│   ├── arrays-objects.md
│   ├── es6-essentials.md   (arrow fns, destructuring, map/filter)
│   └── ...
├── 02-react/
│   ├── components-jsx.md
│   ├── props.md
│   ├── state-usestate.md
│   ├── events-forms.md
│   └── lists.md
├── 03-react-native/
│   ├── core-components.md
│   ├── styling-flexbox.md
│   ├── flatlist.md
│   ├── navigation.md
│   └── ...
├── 04-supabase/
│   ├── tables-crud.md
│   ├── auth-otp.md
│   └── storage.md
└── 05-git/
    └── git-basics.md
```

*Tip: one small file per concept beats one giant file — easier to find later.*

---

## WHAT TO LEARN (the checklist — tick as you go)

### JavaScript
- [ ] Variables (let, const) & data types
- [ ] Functions (regular + arrow)
- [ ] Objects & arrays
- [ ] Loops & conditionals (if, for)
- [ ] Array methods: map, filter, find
- [ ] Destructuring & spread
- [ ] async/await & promises (basic)

### React
- [ ] Components & JSX
- [ ] Props (passing data)
- [ ] State (useState)
- [ ] Handling events
- [ ] Forms & inputs
- [ ] Rendering lists (.map)
- [ ] useEffect (basic)

### React Native (Expo)
- [ ] View, Text, Image
- [ ] Styling & Flexbox
- [ ] TextInput & buttons (Pressable)
- [ ] FlatList (lists)
- [ ] Navigation between screens
- [ ] Running on your phone via Expo Go

### Supabase (you know SQL — go faster here, focus on what's different)
- [ ] Create a table *(easy — it's SQL/Postgres)*
- [ ] Insert / read / update / delete data *(easy — CRUD you know)*
- [ ] Connect from a React Native app *(NEW — the JS client library)*
- [ ] Phone-OTP login *(NEW — the auth flow)*
- [ ] Storage (files) *(NEW)*

### Git
- [ ] init, commit, push
- [ ] Using GitHub
- [ ] Branches (basic)

---

## REMINDERS (keep the learning honest)

- **Goal = enough to build, not mastery.** Stop "studying" once you can build a screen; then learn-by-building with Codex + Claude.
- **Build tiny throwaway things** (to-do app, notes app) to practice — NOT Ledgr yet.
- **Understand before moving on.** If you can't explain it in your own words, you haven't got it yet.
- **Don't perfectionism.** Do enough of each topic, then move forward.
- The real app build happens back in the main project — this companion is just to get you fluent enough.

*Linked docs: Tech-Stack-and-Roadmap.md (your build plan), PG-App-Brainstorm.md (the product).*
