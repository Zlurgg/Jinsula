# Jinsula — Kickoff

Rewritten each session (Knobs convention). See `SPEC.md` for durable decisions and
the full session roadmap; `CLAUDE.md` for the codebase map.

## State

- Compiling skeleton at **iOS 15 / universal (iPhone + iPad)**; bands modelled as data,
  `BandEvaluator` + `Theme` done. Views are still placeholders.
- **All planning is done.** Three feature plans written (daily-use, retest reminder + widget,
  setup) and **Session 5 has refined + integrated them.** SPEC.md now has **zero open questions.**
- **Session 5 decisions (all in SPEC.md):** safety principle **#5 "no amounts, only direction"**;
  defaults follow UK guidance exactly (**T1=3.0 T2=4.0 T3=10.0 T4=15.0** mmol/L; in-range upper
  moved 9.0→10.0 = Diabetes-UK 3.9–10.0 / 70–180 mg/dL); **no unit conversion ever** (unit is a
  setup choice matching the meter, default UK mmol/L); both shared hooks live on **`AppModel`**
  (`confirmReading(_:)` fires only after a band matches; `shouldStartFreshEntry` must dismiss the
  card *and* clear the field); setup entry = discreet **PIN-gated ⋯ menu**; **reset-to-defaults**
  safety net; headlines stay fixed even behind the PIN; **no PIN recovery**; v1 entry is
  **typing only** (voice deferred).

## Next session — pick one

1. **Build the daily-use screen (default)** — the plan is complete and unblocked; this is the
   first build session and creates the two shared `AppModel` hooks the later features depend on.
2. Build the setup screen, or the retest reminder + widget — either can follow; daily-use first
   is recommended because it creates the shared hooks.

## Load in

- **Build the daily-use screen:** SPEC.md → "Daily-use screen — design plan" (whole section),
  "Default UK bands" (the thresholds + amount-free copy), safety principle #5, and
  "Retest reminder + widget — design plan" §0 (the `AppModel.confirmReading(_:)` call site +
  `shouldStartFreshEntry` open-entry intent get created here). Files:
  `Jinsula/Jinsula/Views/DailyUseView.swift`, `ResultCardView.swift`; `Theme.swift` (amber
  darkening); `AppModel.swift`, `BandEvaluator.swift`; `Models/GuidanceBand.swift`,
  `GlucoseReading.swift`, `GlucoseUnit.swift`.
- **Build the setup screen:** SPEC.md → "Setup screen — design plan" (whole section) + "Default
  UK bands". Files: `Views/SetupView.swift`, `Models/AppSettings.swift`, `Models/GuidanceBand.swift`,
  `Services/SettingsStore.swift`.
- **Build the retest reminder + widget:** SPEC.md → "Retest reminder + widget — design plan"
  (whole section). Depends on the daily-use `confirmReading(_:)` hook existing first.

## Open questions

_None._ All planning questions are resolved in SPEC.md. Remaining unknowns are build-time
mechanics only (e.g. App Group entitlement needs a real bundle ID / signing — deferred to the
widget build session; TTS voice/rate tuning; exact keypad sizing on-device).
