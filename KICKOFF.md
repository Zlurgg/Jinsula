# Jinsula — Kickoff

Rewritten each session (Knobs convention). See `SPEC.md` for durable decisions and
the full session roadmap; `CLAUDE.md` for the codebase map.

## State

- **App icon is BUILT (Session 13).** `Scripts/GenerateAppIcon.swift` (standalone Swift+
  CoreGraphics, **not in any Xcode target**) renders an opaque 1024 `icon-1024.png` — a red
  blood droplet + vertical red/amber/green traffic-light accent on a neutral background,
  `Theme` palette verbatim. `Contents.json`'s universal-iOS slot points at it. Regenerate with
  `swift Scripts/GenerateAppIcon.swift`; proportions/dots are all code, easy to tweak.
- **Icon verified without device signing:** `actool` compiles the catalog with no missing-icon
  warning and downscales to iPhone + iPad; PNG is opaque (`hasAlpha: no`); and it renders on a
  running **iPad (A16) simulator** home screen (droplet + lights show in grid + dock).
- **Everything prior stands:** daily-use screen, result card, setup (units/bands/contacts/
  Lock-PIN/Reminders), PIN gate, retest reminder, `systemMedium` widget, `jinsula://check`.
- **Physical-device builds are blocked by Xcode `-1009`.** The account login fails at build time
  (`Unable to log in… -1009`) so no provisioning profiles mint for either target — even though the
  Mac reaches Apple fine (curl → HTTP 200) and the user re-signed in. No cached profiles exist.
  Simulator builds are unaffected (signing disabled). Tests still UNRUN (same signing wall).

## Next session — pick one

1. **On-device verification (iPad handover) — needs the `-1009` fix first.** Fully quit &
   relaunch Xcode (restart the `akd` account daemon) + re-auth the Apple ID so profiles mint;
   connect/register the iPad. Then confirm on hardware: the new icon installs, `tel:` actually
   dials, the widget renders a real reading from the Home-Screen gallery, a reminder fires + taps
   through. (Delete-and-reinstall to force the new icon past iPadOS's icon cache.)
2. **Run the test suite** — the `ReminderServiceTests` cases (flag-off no-op, tap handler, 15/30
   default) have never executed; unblocked either by the `-1009` fix or a no-signing sim destination.
3. **v2 polish:** `ReadingsStore` JSON persistence; app-icon dark/tinted variants (add the two
   empty `Contents.json` slots + render variants in `GenerateAppIcon.swift`).

## Load in

- **On-device verification:** no files — manual. SPEC.md → "Retest reminder + widget" §1–§2 for
  expected behaviours. The `-1009` fix is Xcode UI (Settings → Accounts), not code.
- **Run the test suite:** `Jinsula/JinsulaTests/ReminderServiceTests.swift`; fix Xcode signing
  first, or build/test against an iOS Simulator destination (no signing) — e.g.
  `xcodebuild test -scheme Jinsula -destination 'platform=iOS Simulator,id=<booted-iPad-udid>' CODE_SIGNING_ALLOWED=NO`.
- **Icon variants / regen:** `Scripts/GenerateAppIcon.swift` (the renderer), `Jinsula/Theme/Theme.swift`
  (exact colours), `Jinsula/Assets.xcassets/AppIcon.appiconset/Contents.json` (the empty dark/tinted slots).

## Open questions

- **Xcode `-1009` at build time** blocks all physical-device builds and the local test target;
  the Mac reaches Apple over the wire, so it's an Xcode account-session problem, not connectivity.
  Fixing it is prerequisite to on-device verification and to ever running the tests on a device.
- **Icon fine-tuning is post-render:** the red top light is the lowest-contrast element against the
  red droplet body (it sits on the neutral housing, so it's visible but subtle). Darkening/enlarging
  the housing would lift it — a one-line edit + re-run if desired.
- **On-device unknowns remain (sim-only so far):** `tel:` dialling, widget Home-Screen gallery add,
  reminder fire + tap on real hardware, and the new icon actually installing on the iPad.
- **OS-floor (iOS 15) sign-off is physical-6s-only** — no iOS ≤15 simulator runtime on this Xcode.
- **Interactive PIN + setup flow still unverified** — no UI-test target.
