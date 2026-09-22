# Jinsula — Kickoff

Rewritten each session (Knobs convention). See `SPEC.md` for durable decisions and
the full session roadmap; `CLAUDE.md` for the codebase map.

## State

- Compiling skeleton at **iOS 15 / universal (iPhone + iPad)**; bands modelled as data,
  `BandEvaluator` + `Theme` done. Views are still placeholders.
- **All three feature plans are now written in SPEC.md:** daily-use screen (Session 2),
  retest reminder + widget (Session 3), and setup screen (Session 4).
- **Session 4 done — setup screen planned** ("Setup screen — design plan"). Decided:
  lock = **4-digit PIN** (Keychain, knowledge-gated); band editing = **boundaries only**
  (four editable thresholds over a fixed 5-band shape, contiguity by construction, no model
  change); headlines/actions fixed to protect safety copy; working-copy-then-commit flow;
  contacts (first = primary) + notifications toggle. This retires the `band(for:) == nil`
  open question.

## Next session — pick one

1. **Session 5 (default) — Refine all three plans together**; confirm they integrate and
   still serve the goal (safe, dead-simple daily use).
2. Start building — the daily-use screen plan is complete enough to implement.

## Load in

- **Session 5 (refine):** SPEC.md → "Daily-use screen — design plan",
  "Retest reminder + widget — design plan", "Setup screen — design plan", "Two modes".
  Cross-check the shared hooks: reading-confirmed call site + `AppModel.shouldStartFreshEntry`
  open-entry intent (used by notification tap, widget tap) and the setup working-copy commit.
- **Build the daily-use screen:** SPEC.md → "Daily-use screen — design plan" (whole section)
  + "Retest reminder + widget — design plan" §0 (the reading-confirmed call site + open-entry
  intent get created here); `Jinsula/Jinsula/Views/DailyUseView.swift`, `ResultCardView.swift`;
  `Theme.swift` (amber darkening); `AppModel.swift`, `BandEvaluator.swift`.

## Open questions

- **Unit switch converts thresholds (build):** switching mmol/L ↔ mg/dL must convert the four
  band thresholds (×/÷ 18.0182), convert-then-confirm — never reinterpret the same number.
  Recommended in "Setup screen — design plan" §2; finalise in build.
- **PIN recovery (build):** leaning "none — reinstall resets" (settings are local JSON);
  confirm in build (§5).
- **Headline editability (Session 5):** headlines currently fixed to protect the safety copy
  (e.g. "do NOT take insulin"). Confirm family never needs to edit them, or add a guarded path.
- **App Group entitlement (build):** the group identifier + entitlement need a real bundle ID /
  signing; deferred to the widget build session.
