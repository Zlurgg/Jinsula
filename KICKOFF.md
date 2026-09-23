# Jinsula — Kickoff

Rewritten each session (Knobs convention). See `SPEC.md` for durable decisions and
the full session roadmap; `CLAUDE.md` for the codebase map.

## State

- **App icon design is PLANNED (Session 12), not built.** Decided: a bold blood **droplet**
  with a **red/amber/green traffic-light accent**, reusing the `Theme` palette exactly;
  **generated programmatically** via a standalone Swift+CoreGraphics script (not in any Xcode
  target) that exports one flat, opaque 1024 PNG. Full plan in SPEC.md → "App icon — design plan".
- **Both `AppIcon.appiconset`s are still the empty Xcode placeholder** (modern single 1024 slot;
  no image files). Widget icon is out of scope.
- **Everything prior stands:** daily-use screen, result card, setup (units/bands/contacts/
  Lock-PIN/Reminders), PIN gate, retest reminder (finished Sessions 10–11, verified on iPad sim),
  `systemMedium` widget (App Group + `WidgetSnapshot`), `jinsula://check` deep link.
- **Tests extended but UNRUN** — local test target can't run (device signing `-1009`, no profile).

## Next session — pick one

1. **Build the app icon (default).** Execute the Session-12 plan: write `Scripts/GenerateAppIcon.swift`,
   render `icon-1024.png` into the app appiconset, wire `Contents.json`, build to clear the
   missing-icon warning, inspect the PNG. Self-contained, no hardware.
2. **On-device verification (iPad handover).** Confirm on physical hardware what the sim can't:
   `tel:` dialling actually calls, the widget renders a real reading's colour/time from the
   Home-Screen gallery, and a reminder fires + taps through on a real device.
3. **Run the test suite once signing/network is restored** — the `ReminderServiceTests` cases
   (flag-off no-op, tap handler, 15/30 default) have never executed.

Deferred to **v2:** `ReadingsStore` JSON persistence; app-icon dark/tinted variants.

## Load in

- **Build the app icon:** SPEC.md → "App icon — design plan (Session 12)" (the full spec);
  `Jinsula/Jinsula/Assets.xcassets/AppIcon.appiconset/Contents.json` (the slot to fill);
  `Jinsula/Jinsula/Theme/Theme.swift` (the exact band colours). Script goes in a new
  `Scripts/GenerateAppIcon.swift` (do NOT add it to any Xcode target).
- **On-device verification:** no files — manual (widget gallery add, real reading, reminder fire +
  tap, `tel:` dial). SPEC.md → "Retest reminder + widget" §1–§2 for expected behaviours.
- **Run the test suite:** `JinsulaTests/ReminderServiceTests.swift`; fix Xcode signing/account
  first (the `-1009` login + missing `uk.co.zlurgg.Jinsula` profile), or use a simulator
  destination that needs no signing.

## Open questions

- **Icon fine-tuning is post-render:** background shade, droplet proportions, and dot layout are
  all code — expect to eyeball the first PNG and tweak.
- **Test target has never run** — signing blocks it; the new reminder cases are unverified.
- **On-device unknowns remain:** `tel:` no-ops in the sim; widget Home-Screen render confirmed only
  via deep-link routing, not a gallery add; reminder fire + tap verified on sim only, not hardware.
- **OS-floor (iOS 15) sign-off is physical-6s-only** — no iOS ≤15 simulator runtime on this Xcode.
- **Interactive PIN + setup flow still unverified** — no UI-test target.
