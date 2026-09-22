# Jinsula — Kickoff

Rewritten each session (Knobs convention). See `SPEC.md` for durable decisions and
the full session roadmap; `CLAUDE.md` for the codebase map.

## State

- **PIN gate is BUILT and compiles** (Session 8, iOS 15 / universal). New
  `Services/PINStore.swift` (Keychain `PINStoring`, injectable; PIN kept out of the settings
  JSON) and `Views/PINEntryView.swift` (one big keypad, `.unlock` + `.set` modes) + `SetupGateView`
  (what the ⋯ door presents: PIN pad first when `hasPIN`, else setup directly). `AppModel` gained
  `hasPIN` / `verifyPIN(_:)` / `setPIN(_:)`. Set/change-PIN lives as a **Lock section at the bottom
  of the setup `Form`** (SPEC §5 note). `AppSettings.isLocked` left unused — gating is driven by
  `hasPIN` (Keychain presence).
- **Verified:** PINStore (real Keychain) + AppModel wiring runtime-verified via `RunCodeSnippet`
  (14 assertions). App **builds, installs, and launches** on "Jinsula SE (layout floor)" (iOS 18.5);
  the first-run gate path (no PIN → setup opens directly) and settings persistence confirmed on
  screen. Interactive taps (scroll to Lock → set → relaunch-gated → unlock) **not driven** — no
  UI-test target / no `idb`.
- **This is the MVP baseline for real-world testing** — the app now goes onto the iPad and is
  handed to the user for testing. Bundle id `uk.co.zlurgg.Jinsula`.
- **Not yet done:** the widget (next session), the reminders toggle + `ReminderService`,
  `ReadingsStore` persistence (**demoted to v2**), and the **app icon (still the Xcode default)**.

## Next session — pick one

1. **Widget — the MVP piece (default).** A Home Screen widget that shows the last reading and,
   tapped, opens number entry. Needs a **new Widget Extension target + App Group entitlement**
   on `uk.co.zlurgg.Jinsula` — target creation is Xcode-UI work (can't be done reliably from code
   edits), so budget the first part of the session for that, then wire the code.
2. **App icon pass** — replace the default Xcode icon; its own short session (asset + all sizes).
3. **Reminders toggle + `ReminderService`** — the §4 setup piece deferred twice now.

Deferred to **v2:** `ReadingsStore` JSON persistence (logged readings surviving relaunch).

## Load in

- **Widget:**
  - SPEC.md → "Retest reminder + widget — design plan" §2 (Home Screen widget — whole subsection:
    App Group snapshot, `systemMedium`, whole-widget `widgetURL`, iOS 15 no interactive buttons).
  - Code hooks already stubbed: `AppModel.writeWidgetSnapshot(for:severity:)` (fill in — write the
    tiny {value, unit, date, severity} JSON to the App Group container + `WidgetCenter.reloadAllTimelines()`),
    and `ContentView.onOpenURL` (`jinsula://check` → `shouldStartFreshEntry`, already wired).
  - `Models/GlucoseReading.swift` for the snapshot shape; `Models/GuidanceBand.swift` for `Severity`.
  - New: a Widget Extension target + App Group entitlement on `uk.co.zlurgg.Jinsula`.
- **App icon pass:** `Jinsula/Jinsula/Assets.xcassets/AppIcon.appiconset`.
- **Reminders toggle + `ReminderService`:** SPEC.md → "Retest reminder + widget" §1 (local
  notification) + §4 in "Setup screen"; `AppModel.scheduleRetestReminder()` / `cancelRetestReminder()`
  (both stubbed).

## Open questions

- **Interactive PIN + setup flow is unverified** — no UI-test target / no `idb`. Real-world iPad
  testing (this session's handover) is the first true end-to-end check; a UI-test target
  (XCUIAutomation) would make it replayable.
- **App icon** is still the default — needs its own pass (candidate topic 2).
- **Widget App Group** entitlement must be wired to `uk.co.zlurgg.Jinsula` (build-mechanics).
- **Call button dialing unverified** — `tel:` URLs no-op in the Simulator; the iPad handover is
  the chance to confirm dialing on a physical device.
- **OS-floor (iOS 15) sign-off is physical-6s-only** — no iOS ≤15 simulator runtime on this Xcode.
