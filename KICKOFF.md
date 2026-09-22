# Jinsula — Kickoff

Rewritten each session (Knobs convention). See `SPEC.md` for durable decisions and
the full session roadmap; `CLAUDE.md` for the codebase map.

## State

- Compiling skeleton at **iOS 15 / universal (iPhone + iPad)**; bands modelled as data,
  `BandEvaluator` + `Theme` done. Views are still placeholders.
- **Session 2 done:** the daily-use screen is fully planned in SPEC.md
  ("Daily-use screen — design plan"); all its open questions resolved.
- **Session 3 done:** retest reminder + widget fully planned in SPEC.md
  ("Retest reminder + widget — design plan"). Decided: reminder = **local notification**,
  **one gentle re-nudge** (+15 / +30 min), safety-reinforcing copy; widget = **`systemMedium`**,
  **App Group** `{value, unit, date, severity}` snapshot, whole-widget `widgetURL` deep link.
- **Two shared hooks specified (wiring deferred to build):** a single "reading-confirmed"
  call site, and one `AppModel.shouldStartFreshEntry` open-entry intent shared by the
  notification tap and the widget tap.

## Next session — pick one

1. **Session 4 (default) — Plan the setup screen** (bands, contacts, units, the lock).
2. Session 5 — Refine all three plans together; confirm they integrate and still serve
   the goal (safe, dead-simple daily use).
3. Start building — the daily-use screen plan is complete enough to implement.

## Load in

- **Session 4 (setup):** `Jinsula/Jinsula/Views/SetupView.swift`,
  `Jinsula/Jinsula/Models/AppSettings.swift`, `Jinsula/Jinsula/Models/GuidanceBand.swift`;
  SPEC.md → "Two modes" + "Core safety principles". Touch-point: Session 3 said setup should
  offer to enable notifications and strongly encourage adding a contact.
- **Session 5 (refine):** SPEC.md → "Daily-use screen — design plan",
  "Retest reminder + widget — design plan", "Two modes".
- **Build the daily-use screen:** SPEC.md → "Daily-use screen — design plan" (whole section)
  + "Retest reminder + widget — design plan" §0 (the reading-confirmed call site + open-entry
  intent get created here); `Jinsula/Jinsula/Views/DailyUseView.swift`, `ResultCardView.swift`;
  `Theme.swift` (amber darkening); `AppModel.swift`, `BandEvaluator.swift`.

## Open questions

- **Setup lock mechanism (Session 4):** PIN, Face/Touch ID, or a simple hidden gesture —
  which best fits an elderly user + a family member who configures rarely?
- **Band editing UI (Session 4):** how family edits `[GuidanceBand]` safely (ranges must stay
  contiguous / not leave dangerous gaps — `band(for:) == nil` is only a defensive case today).
- **App Group entitlement (build):** the group identifier + entitlement need a real bundle ID /
  signing; deferred to the widget build session.
