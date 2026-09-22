# Jinsula — Kickoff

Rewritten each session (Knobs convention). See `SPEC.md` for durable decisions and
the full session roadmap; `CLAUDE.md` for the codebase map.

## State

- **Daily-use screen is BUILT and compiles** (iOS 15 / universal). Custom keypad
  (unit-aware `.` key, one-d.p. cap, bounds-checked, explicit confirm) → full-screen
  `ResultCardView` (echo, headline, amount-free detail, action button from `band.action`,
  auto-speak + "Read it again" + Done). Verified at the 4.7" **layout floor** (iPhone SE
  2nd gen sim = 6s screen) via live entry screenshot + all four card states rendered.
- **The two shared hooks now exist on `AppModel`:** `confirmReading(_:)` (matches once,
  then logs reading + cancels retest + writes widget snapshot — collaborators stubbed;
  fires only *after* a band matches) and `shouldStartFreshEntry` + `consumeFreshEntry()`
  (widget/notification open-entry intent; `jinsula://check` wired in `ContentView`).
- **Safety fix landed:** `GuidanceBand.defaultUKBands` was still naming amounts
  ("15–20g… GlucoTabs") and using the old 9.0 edge — replaced with the Session-5
  amount-free copy + T3=10.0 (principle #5). Amber `Theme.high` darkened for WCAG AA.
- **Not yet done:** real persistence (`ReadingsStore`/`SettingsStore` still stubs),
  `ReminderService`, widget target, setup screen + PIN gate (⋯ menu is a placeholder
  alert). No device sign-off yet at the true **OS floor** (iOS 15 — physical 6s only;
  no iOS ≤15 simulator runtime installable on this Xcode).

## Next session — pick one

1. **Build the setup screen + PIN gate (default)** — unblocks the ⋯ menu placeholder
   left on the daily screen; boundaries-only band editor, units, contacts, reset-to-defaults,
   Keychain PIN. Needs real `SettingsStore` persistence too.
2. **Build the retest reminder + widget** — the `confirmReading(_:)` hook it depends on
   now exists; fill in `ReminderService` + the widget target behind the existing stubs.
3. **Wire real persistence** (`ReadingsStore` / `SettingsStore` JSON) — smaller, unblocks
   readings actually surviving and the widget snapshot having data.

## Load in

- **Build the setup screen + PIN gate:** SPEC.md → "Setup screen — design plan" (whole
  section) + "Default UK bands". Files: `Views/SetupView.swift`, `Models/AppSettings.swift`,
  `Models/GuidanceBand.swift`, `Services/SettingsStore.swift`; the ⋯ menu placeholder +
  `showSettingsStub` alert in `Views/DailyUseView.swift` (replace with the PIN pad).
- **Build the retest reminder + widget:** SPEC.md → "Retest reminder + widget — design
  plan" (whole section). Hook into the existing `AppModel.scheduleRetestReminder()` /
  `cancelRetestReminder()` / `writeWidgetSnapshot(...)` stubs (`ViewModels/AppModel.swift`)
  and `ContentView.onOpenURL`. New files: `Services/ReminderService.swift` + a Widget target.
- **Wire real persistence:** `Services/ReadingsStore.swift`, `Services/SettingsStore.swift`
  (both currently return stubs); `Models/GlucoseReading.swift`, `AppSettings.swift` for the
  Codable shapes. `AppModel.confirmReading(_:)` already calls `readingsStore.append(_:)`.

## Open questions

_None blocking._ Remaining unknowns are build-time mechanics only: App Group entitlement
needs a real bundle ID / signing (widget session); TTS voice/rate final tuning on-device;
**OS-floor (iOS 15) sign-off is physical-6s-only** — no iOS ≤15 simulator runtime is
installable on this Xcode (the 6s can't pair with iOS 18.5/26.5). Layout floor is covered
by the "Jinsula SE (layout floor)" simulator (SE 2nd gen = same 375×667pt screen).
