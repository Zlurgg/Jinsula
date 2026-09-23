# Jinsula — Kickoff

Rewritten each session (Knobs convention). See `SPEC.md` for durable decisions and
the full session roadmap; `CLAUDE.md` for the codebase map.

## State

- **Reminder-finish is PLANNED, not built (Session 10, planning-only).** The plan lives in
  SPEC.md → "Retest reminder + widget" §1 ("Finish plan (Session 10)"): three pieces — (1) a
  `UNUserNotificationCenterDelegate` via `@UIApplicationDelegateAdaptor` (foreground banner +
  tap → the shared open-entry intent, reusing the widget path; tap also cancels the survivor),
  (2) the Session-4 setup **Reminders toggle** (new `AppSettings.remindersEnabled`), and
  (3) removing the DEBUG 8s/16s interval. No code was written.
- **Two decisions recommended but UNCONFIRMED** — confirm at the top of the build session:
  (a) toggle default = **ON + gates scheduling**; (b) DEBUG interval **removed entirely**.
- **Already built (Session 9):** the `systemMedium` widget (App Group `group.uk.co.zlurgg.Jinsula`,
  `WidgetSnapshot`, `jinsula://check`) and `ReminderService` scheduling (+15/+30 min, fixed IDs)
  wired into `AppModel` + unit-tested (`ReminderServiceTests`).
- **⚠️ DEBUG reminder interval = 8s/16s** still ships in every Debug build (`ReminderService.defaultIntervals`,
  `#if DEBUG`); the plan removes it. Release already uses 15/30 min.

## Next session — pick one

1. **Build the reminder finish (default).** Implement the Session 10 plan above. Confirm the two
   open decisions first, then: `AppDelegate`/delegate, `AppModel.handleRetestNotificationTap()`,
   `remindersEnabled` + setup toggle, drop the DEBUG interval, extend the tests.
2. **App icon pass.** Still the Xcode default — replace with a real icon (asset + all sizes). Short session.
3. **On-device verification (iPad handover).** Widget renders a real reading's colour/time; a reminder
   actually fires (banner + tap → blank entry); `tel:` dialling on hardware.

Deferred to **v2:** `ReadingsStore` JSON persistence (logged readings surviving relaunch).

## Load in

- **Build the reminder finish:**
  - SPEC.md → "Retest reminder + widget" §1, the "Finish plan (Session 10)" block (the full design +
    the two decisions to confirm).
  - `Services/ReminderService.swift` (drop the DEBUG override; add an `authorizationStatus()` to the
    `UserNotificationScheduling` seam); `ViewModels/AppModel.swift` (add `handleRetestNotificationTap()`;
    gate `scheduleRetestReminder()` on the flag); `JinsulaApp.swift` (where the `AppDelegate` hangs) +
    `ContentView.swift` (wire `appDelegate.model`; update the stale "Session 3" comment on `onOpenURL`).
  - `Models/AppSettings.swift` (add `remindersEnabled`, Codable-tolerant of old JSON);
    `Views/SetupView.swift` (Reminders section between Contacts and Lock).
  - `JinsulaTests/ReminderServiceTests.swift` (extend the spy + new cases).
- **App icon:** `Jinsula/Jinsula/Assets.xcassets/AppIcon.appiconset`.
- **On-device verification:** no files — manual (widget gallery add, real reading, reminder fire, dial).

## Open questions

- **Toggle default + semantics** — recommended **ON + gates scheduling**; alternatives are off-by-default
  or permission-opt-in-only. Unconfirmed.
- **DEBUG 8s interval** — recommended **removed entirely** (always 15/30). Unconfirmed; still ships in
  Debug builds until done.
- **Notification foreground presentation + tap→open-entry** — planned, not built; unverified on device.
- **Widget Home-Screen render is unverified** — deep-link routing confirmed; the widget actually showing
  a real reading's colour/time needs a manual gallery-add (iPad handover).
- **Call button dialling unverified** — `tel:` URLs no-op in the Simulator; confirm on the physical iPad.
- **OS-floor (iOS 15) sign-off is physical-6s-only** — no iOS ≤15 simulator runtime on this Xcode.
- **Interactive PIN + setup flow still unverified** — no UI-test target; a UI-test target would make the
  iPad end-to-end check replayable.
