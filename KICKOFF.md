# Jinsula — Kickoff

Rewritten each session (Knobs convention). See `SPEC.md` for durable decisions and
the full session roadmap; `CLAUDE.md` for the codebase map.

## State

- Compiling skeleton at **iOS 15 / universal (iPhone + iPad)**; bands modelled as data,
  `BandEvaluator` + `Theme` done. Views are still placeholders.
- **Session 2 done:** the daily-use screen is fully planned in SPEC.md
  ("Daily-use screen — design plan") — keypad entry, full-screen band card, TTS,
  flow-back, accessibility, and how it reads from `AppModel`.
- **All Session 2 open questions resolved:** darken amber (white text on every band);
  hide the call button when no contact is set; input bounds mmol/L 1.0–33.3 / mg/dL 20–600
  with a gentle "try again" state for out-of-range or unmatched readings.
- **Pre-decided for Session 3:** retest reminder = **local notification**; widget =
  **shows last reading**, tap opens number entry.

## Next session — pick one

1. **Session 3 (default) — Plan the retest reminder + Home Screen widget.**
2. Session 4 — Plan the setup screen (bands, contacts, units, the lock).
3. Start building — the daily-use screen plan is complete enough to implement.

## Load in

- **Session 3 (reminder + widget):** SPEC.md → "Daily-use screen — design plan" (§3 TTS,
  §4 flow-back), "Two modes", "Open questions"; `Jinsula/Jinsula/Services/` (new service
  for scheduling); `Jinsula/Jinsula/Models/GlucoseReading.swift` (last-reading source for
  the widget); `Jinsula/Jinsula/ViewModels/AppModel.swift`.
- **Session 4 (setup):** `Jinsula/Jinsula/Views/SetupView.swift`,
  `Jinsula/Jinsula/Models/AppSettings.swift`, `GuidanceBand.swift`;
  SPEC.md → "Two modes" + "Core safety principles".
- **Build the daily-use screen:** SPEC.md → "Daily-use screen — design plan" (whole
  section); `Jinsula/Jinsula/Views/DailyUseView.swift`, `ResultCardView.swift`;
  `Theme.swift` (amber darkening); `AppModel.swift`, `BandEvaluator.swift`.

## Open questions

- Retest reminder mechanics (Session 3): notification copy, whether it repeats if ignored,
  and how tapping it re-opens entry.
- Widget scope detail (Session 3): how "last reading" is shared to the widget on iOS 15
  (App Group + shared JSON?).
