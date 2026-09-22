# Jinsula — Kickoff

Rewritten each session (Knobs convention). See `SPEC.md` for durable decisions and
the full session roadmap; `CLAUDE.md` for the codebase map.

## State

- **Home Screen widget is BUILT (Session 9, iOS 15 / universal).** New Widget Extension
  target `JinsulaWidget` + **App Group `group.uk.co.zlurgg.Jinsula`** on both targets.
  `Models/WidgetSnapshot.swift` (shared into the extension) holds the tiny
  `{value, unitLabel, date, severity}` payload + atomic App-Group read/write; `AppModel.writeWidgetSnapshot`
  now writes it + `WidgetCenter.reloadAllTimelines()` inside `confirmReading`. `JinsulaWidget.swift`
  = `systemMedium`, band-coloured, value/unit/time, "Tap to check your sugar" empty state,
  whole-widget `jinsula://check`. Theme + GuidanceBand shared into the extension for the colour.
- **`Services/ReminderService.swift` is BUILT + unit-tested (Session 9).** `UNUserNotificationCenter`-backed
  (injectable `UserNotificationScheduling` seam + injectable intervals), schedules two non-repeating
  nudges (+15/+30 min) with fixed IDs so a re-tap replaces not stacks; `cancelRetest`, `requestAuthorization`.
  Wired into `AppModel.scheduleRetestReminder()` / `cancelRetestReminder()`. **First test target created**
  (`JinsulaTests`, Swift Testing) — `ReminderServiceTests` (4 tests, all pass): intervals/IDs, no-stacking,
  cancel, and the safety copy ("eat sugar — do not take insulin").
- **Verified:** app builds/installs/launches on the iPad (A16) sim; `jinsula://check` now **routes to the
  app** (fixed — see below); the 4 reminder tests pass via the Xcode test runner.
- **⚠️ DEBUG reminder interval = 8s/16s** (`ReminderService.defaultIntervals`, `#if DEBUG`) so the flow can
  be watched in seconds. This affects **every Debug build, including the iPad handover** — must become a
  real setting (reminders session) before release; Release already uses 15/30 min.

## Next session — pick one

1. **App icon pass (default).** Still the Xcode default — replace with a real icon (asset + all sizes).
   Its own short session.
2. **Finish the reminder — foreground + tap + toggle.** The scheduling exists; still missing: the
   `UNUserNotificationCenterDelegate` (foreground banner + notification-tap → the shared open-entry intent,
   via `UIApplicationDelegateAdaptor`), the Session-4 setup **Reminders toggle**, and replacing the DEBUG
   8s interval with a real default. This is SPEC §1's tap-handling + §4 setup piece.
3. **On-device verification (iPad handover).** Add the widget to the Home Screen and confirm it renders a
   real reading's colour/time; confirm a reminder actually fires; confirm `tel:` dialling on hardware.

Deferred to **v2:** `ReadingsStore` JSON persistence (logged readings surviving relaunch).

## Load in

- **App icon:** `Jinsula/Jinsula/Assets.xcassets/AppIcon.appiconset`.
- **Finish the reminder:**
  - SPEC.md → "Retest reminder + widget" §1 (tap handling / foreground presentation) + §4 in "Setup screen"
    (the Reminders toggle).
  - `Services/ReminderService.swift` (scheduling done; `defaultIntervals` DEBUG override to replace);
    `ViewModels/AppModel.swift` (`scheduleRetestReminder`/`cancelRetestReminder` wired); `JinsulaApp.swift`
    (where a `UIApplicationDelegateAdaptor` + notification delegate would hang); `ContentView.onOpenURL`
    (the open-entry intent the tap should reuse — already wired for the widget).
  - `Models/AppSettings.swift` (add a reminders-enabled flag if the toggle needs persistence).
- **On-device verification:** no files — it's manual (widget gallery add, real reading, reminder fire, dial).

## Open questions

- **DEBUG 8s reminder interval** ships in Debug builds — remove / make it a real setting before release.
- **Widget Home-Screen render is unverified** — deep-link routing is confirmed, but the widget actually
  showing a real reading's colour/time needs a manual gallery-add on a device (iPad handover).
- **Notification foreground presentation + tap→open-entry not built** — the reminder fires, but there's no
  `UNUserNotificationCenterDelegate` yet, so a foreground banner won't show and tapping the notification
  doesn't open a fresh entry. (Widget tap already does, via `onOpenURL`.)
- **Call button dialling unverified** — `tel:` URLs no-op in the Simulator; confirm on the physical iPad.
- **OS-floor (iOS 15) sign-off is physical-6s-only** — no iOS ≤15 simulator runtime on this Xcode.
- **Interactive PIN + setup flow still unverified** — no UI-test target; the iPad handover is the first
  true end-to-end check (a UI-test target would make it replayable).
