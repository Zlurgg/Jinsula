# Jinsula — Kickoff

Rewritten each session (Knobs convention). See `SPEC.md` for durable decisions and
the full session roadmap; `CLAUDE.md` for the codebase map.

## State

- **Retest reminder is DONE (Session 11).** All three finish pieces built and **verified on the
  iPad simulator**: (1) `AppDelegate` notification delegate (foreground banner + tap → blank entry
  and cancels the survivor), (2) setup **Reminders** toggle (`AppSettings.remindersEnabled`, default
  ON, gates scheduling), (3) DEBUG 8s/16s interval **removed** — every build now uses real 15/30 min.
  Both open decisions were confirmed (toggle default ON + gates; DEBUG removed entirely).
- **Tests extended but UNRUN.** `ReminderServiceTests` now covers flag-off no-op, the tap handler,
  and the 15/30 default. The local **test target can't run — device code-signing fails** (login
  `-1009`, no provisioning profiles); the app itself builds + runs fine on the Simulator.
- **Everything prior still stands:** daily-use screen, result card, setup (units/bands/contacts/
  Lock-PIN + now Reminders), PIN gate, `systemMedium` widget (App Group + `WidgetSnapshot`),
  `jinsula://check` deep link.

## Next session — pick one

1. **App icon pass (default).** Still the Xcode placeholder — design/add a real `AppIcon` asset
   (all required sizes). Self-contained, no hardware needed. Short session.
2. **On-device verification (iPad handover).** Confirm on physical hardware what the Simulator
   can't: `tel:` dialling actually calls, the widget renders a real reading's colour/time from the
   Home-Screen gallery, and a reminder fires + taps through on a real device.
3. **Run the test suite once signing/network is restored** — the three new `ReminderServiceTests`
   cases (and the whole target) have never executed. Quick if the environment cooperates.

Deferred to **v2:** `ReadingsStore` JSON persistence (logged readings surviving relaunch).

## Load in

- **App icon:** `Jinsula/Jinsula/Assets.xcassets/AppIcon.appiconset`.
- **On-device verification:** no files — manual (widget gallery add, real reading, reminder fire +
  tap, `tel:` dial). SPEC.md → "Retest reminder + widget" §1–§2 for the expected behaviours.
- **Run the test suite:** `JinsulaTests/ReminderServiceTests.swift`; fix Xcode's signing/account
  first (the `-1009` login + missing `uk.co.zlurgg.Jinsula` profile), or run against a simulator
  destination that needs no signing.

## Open questions

- **Test target has never run** — signing blocks it; the three new cases are unverified in CI/local.
- **On-device unknowns remain:** `tel:` dialling no-ops in the Simulator; the widget's Home-Screen
  render (colour/time from a real reading) is confirmed only via deep-link routing, not a gallery add;
  reminder fire + tap verified on the *simulator* only, not physical hardware.
- **OS-floor (iOS 15) sign-off is physical-6s-only** — no iOS ≤15 simulator runtime on this Xcode.
- **Interactive PIN + setup flow still unverified** — no UI-test target; one would make the iPad
  end-to-end check replayable.
