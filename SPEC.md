# Jinsula — Spec

A tiny, safety-first app that helps an elderly diabetic user (referred to here as
"grandma") respond **correctly** to a blood glucose reading. She types a number
in; the app gives a big, plain, spoken instruction out.

## The problem we are actually solving

Grandma saw a **low** reading and took insulin out of habit. Insulin pushes blood
sugar **lower** — potentially into a severe, dangerous hypo. The app's number one
job is to prevent that specific mistake.

> On a low reading the app must unmistakably say: **"Do NOT take insulin. Eat sugar now."**

Tracking, trends, and reminders are all secondary to getting that one directional
call right.

## Core safety principles (non-negotiable)

1. **The app delivers a plan, it does not invent medicine.** Bands are fully
   customised during setup to match grandma's own care plan. Shipped defaults are
   only sensible starting points.
2. **Never auto-calculate an insulin dose.** A high reading points the user to the
   plan their nurse/doctor gave them — the app does not compute a correction dose
   from age/weight/etc.
3. **Escalate, don't reassure, on danger.** Very low / very high readings show a
   "get help now" card with a one-tap call to a family contact — not a snack tip.
4. **Settings are lockable** so grandma can't change bands or contacts by accident.

## Default UK bands (starting points only — mmol/L)

Confirmed against Diabetes UK ("4 is the floor") and the NHS/JBDS hypo algorithm.

| Reading (mmol/L) | Band | Card |
|---|---|---|
| below 3.0, or confused/drowsy | Emergency (red) | "Get help now" + one-tap call |
| 3.0 – 3.9 | Low (orange) | "Eat sugar now — do NOT take insulin" + retest timer |
| 4.0 – ~8.5 | In range (green) | "Your reading is fine" |
| ~9 – 15 | High (amber) | "Follow the plan from your nurse" (no dose) |
| above 15 | Very high (red) | "Call your family or nurse" + one-tap call |

Sources: diabetes.org.uk/about-diabetes/looking-after-diabetes/complications/hypos ;
JBDS hypo algorithm (2022).

## Two modes

| Mode | Who | Density |
|---|---|---|
| **Setup** (rare) | Family member, behind the lock | Normal form: name, units, bands, contacts |
| **Daily use** (constant) | Grandma | Giant number entry → one huge colour card + spoken instruction → one action button |

Daily-use actions: **"Remind me in 15 minutes"** (retest timer) on a low; **"Call [name]"**
on emergency/very-high. Reading + date/time logged automatically.

A Home Screen **widget** ("Check my sugar") should launch straight into the number entry.

## Daily-use screen — design plan (Session 2)

The everyday flow is three states: **Entry → Result card → back to Entry**. One value
in, one huge colour card out, spoken aloud. No menus, no history, no settings reachable
from here (setup lives behind the lock). Reads from `AppModel` only.

### 1. Number entry
- **DECIDED: a big custom on-screen keypad**, not a stepper (too many taps to reach 5.6)
  and not the system keyboard (keys too small, decimal keypad is cluttered).
- Layout: phone-style 3×4 grid — `1‑9`, then bottom row `[ . ] [ 0 ] [ ⌫ ]`, with a
  full-width **confirm** button ("Show me my answer") below. The typed value shows above
  the pad, huge (`Theme.reading`, ~96pt).
- **Decimal handling:** unit comes from `settings.unit`.
  - mmol/L → the `.` key is shown; accept **at most one decimal place** (readings are
    always one d.p., e.g. `5.6`). Ignore further digits after the decimal.
  - mg/dL → **hide/disable the `.` key**; integers only.
- **Enter is always explicit** via the confirm button — never auto-submit on digit count
  (`5.6` vs `15.6` are one keypress apart; auto-submit would be dangerous). Confirm stays
  **disabled until a plausible value is entered** (non-empty, within a sane min/max — exact
  bounds TBD, but reject `0` and absurd values so she can't act on a typo).
- `⌫` deletes one character; long-press or a small "clear" affordance resets. No cursor,
  no mid-string editing.

### 2. Result card
- Presented **full-screen** over the entry (full-screen cover), background =
  `Theme.colour(for: band.severity)`, white text (but see amber caveat below).
- Content, top→bottom:
  1. Small echo line: **"Your reading: 5.6"** so she can see what the card responded to.
  2. **Headline** — biggest (`Theme.headline`), the loud line ("Eat sugar now — do NOT
     take insulin").
  3. **Detail** (`Theme.instruction`) — the supporting amounts/steps.
  4. **One action button**, driven entirely by `band.action` (never branch band logic in
     the view):
     - `.none` → no action button; only the **Done** button (see flow-back).
     - `.retestTimer` → **"Remind me in 15 minutes"** (timer itself is Session 3; here we
       reserve its placement + size).
     - `.callContact` → **"Call [name]"** using `settings.contacts.first`. If no contact is
       configured, fall back to a plain "Get help" message rather than a dead button
       (open question — see below).
- The card renders *only* from the matched `GuidanceBand`; adding a new band never
  requires touching this view.

### 3. Text-to-speech (`SpeechService`)
- On card appearance, **automatically speak** the headline then the detail, once, in a
  calm clear voice (tune rate/voice at build time).
- A visible **"Read it again"** control (speaker icon, large) repeats it; tapping the card
  body also repeats. **Stop speaking** when the card is dismissed (`stop()`).
- **Audio session:** configure `AVAudioSession` to `.playback` so guidance is heard **even
  when the ring/silent switch is on** — this is a safety app, silence must not mute a
  low-glucose warning. (Record as a build decision.)
- Emergency bands may be spoken slightly slower for clarity (nice-to-have, not v1-critical).

### 4. Flow back
- Every card has exactly **one obvious way out**: a large **"Done"** button (and the action
  button, where present, also returns after firing). **No swipe-to-dismiss** — poor
  discoverability for an elderly user.
- Dismissing **resets entry to blank** so the next check starts clean.
- The reading is **logged automatically** (value + date + `settings.unit` → `GlucoseReading`)
  at confirm time; persistence wiring is a later session but the plan assumes it happens
  here, once per confirm.

### 5. Accessibility
- **Tap targets:** keypad keys and buttons far exceed the 44pt HIG minimum. On the 6s
  (375pt wide) a 3-column grid yields ~100–110pt keys; keep ≥72pt everywhere.
- **Dynamic Type:** the daily screen uses **fixed large sizes** (already larger than the
  biggest Dynamic Type step) rather than scaling — but text must **wrap and use
  `minimumScaleFactor`, never truncate**, so long detail lines fit the 4.7" screen.
- **Contrast caveat (needs a decision):** white text on the **amber `high`** colour
  (`0.90, 0.72, 0.10`) likely fails WCAG contrast. Options: darken the amber, or use
  **dark text for the `high` band only**. Flagged in Open questions.
- **iPad 10.2":** portrait-first; centre the entry/card in a **capped-width column
  (~500pt)** so the keypad isn't stretched edge-to-edge. Landscape can wait for v1.
- **VoiceOver:** even with TTS, label every key/button plainly (the digits, "delete",
  "show me my answer", the action button).

### 6. How it reads from `AppModel` / `BandEvaluator`
- `DailyUseView` holds the entry string as local `@State`.
- On confirm: parse to `Double` → `model.band(for: value)` (which calls
  `BandEvaluator.band(for:in:)` over `settings.bands`) → present `ResultCardView(band:)`.
- Unit label and the `.` key come from `settings.unit`; the call action reads
  `settings.contacts`. The view **never** contains band thresholds or messages — those
  live in the bands.
- If no band matches (`nil`), show a safe neutral "couldn't read that — try again" state
  rather than an empty card. (Open question — see below.)

## Devices & platform decisions

- **UK-based → mmol/L default.** (mg/dL kept in the model for future regions.)
- **DECIDED: minimum iPhone 6s, minimum iOS 15.0.** (Not the iPhone 6 — that would
  force a UIKit rewrite. The 6s runs iOS 15, so SwiftUI is fine.)
- **DECIDED: universal app, iPhone + iPad only.** iPad 8th generation (iPadOS 17+,
  10.2" screen) is a first-class large-display target. Device family `1,2`; Mac and
  Vision dropped.
- **Stack consequence:** SwiftUI + `ObservableObject` + Codable JSON (no
  `@Observable`/SwiftData — both need iOS 17).

### Testing note
Current Xcode can't run an iPhone 6s / iOS 15 simulator. The simulator validates
layout and logic at deployment-target iOS 15 but on a newer runtime — real iOS 15
behaviour must be signed off on a **physical iPhone 6s**. iPad is tested on a
**physical iPad**.

## Architecture (borrowed from the Knobs project)

- **SwiftUI + `ObservableObject`** (NOT the iOS 17 `@Observable` macro — too new for
  our floor).
- **"Rules as data":** `[GuidanceBand]` is the single source of truth. Setup edits it;
  the daily card renders from it; `BandEvaluator` matches a reading to a band as a
  pure, unit-testable function.
- **Plain Codable JSON** persistence (SwiftData/Core Data need iOS 17) — data is tiny.
- **`Theme`** holds all fonts/colours in one place.
- **Swift Testing** for logic (pure `BandEvaluator` tests first).

## Session roadmap

Way of working: **plan-only sessions first, then build one feature per session.**
No code is written during the planning sessions.

1. ✅ **Session 1 — Concept + skeleton** (this one). Idea, safety framing, research,
   folder/skeleton, docs, platform decisions.
2. **Session 2 — Plan the daily-use screen** (number entry → result card → speech).
3. **Session 3 — Plan the retest reminder + Home Screen widget.**
4. **Session 4 — Plan the setup screen** (bands, contacts, units, the lock).
5. **Session 5 — Refine all three plans together**; confirm they integrate and still
   serve the goal (safe, dead-simple daily use).
6. **Build sessions — one feature per session**, each followed by review + test on a
   physical iPhone 6s and a physical iPad.

## Open questions

- [x] **Retest reminder → local notification** (survives backgrounding; the 15-min wait
      must fire even if she's left the app). Details in Session 3.
- [x] **Widget → shows the last reading** (not launch-only); tapping it opens number entry.
      Details in Session 3.
- [x] **No age/weight/dose info collected or computed.** Per safety principle #2 the app
      only logs the reading with its **time of day** (already captured by
      `GlucoseReading.date`) and shows the **traffic-light band** — nothing feeds a dose
      calculation.
- [x] **Amber `high` band contrast → darken the amber** in `Theme` until white text
      passes WCAG; keep white text across all bands (one consistent rule, no per-band
      text-colour special case).
- [x] **Call action with no contact configured → hide the button.** If `settings.contacts`
      is empty, a `.callContact` band shows its headline/detail only, no dead button. (Setup
      should strongly encourage adding a contact.)
- [x] **Input bounds + unmatched reading:** confirm accepts only meter-plausible values —
      **mmol/L 1.0–33.3**, **mg/dL 20–600** (outside → stay on entry, show a gentle
      "That doesn't look right — please check and type it again"). If a value is in-bounds
      but `band(for:) == nil` (a gap in the configured bands), show the same safe try-again
      state rather than an empty card. Defaults contiguous + open-ended, so `nil` is a
      defensive case only.
