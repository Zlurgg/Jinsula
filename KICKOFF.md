# Jinsula — Kickoff

Rewritten each session (Knobs convention). See `SPEC.md` for durable decisions and
the full session roadmap; `CLAUDE.md` for the codebase map.

## State

- **Daily-use input is now a vertical colour WHEEL (Session 14), replacing the keypad.**
  `Views/GlucoseDialView.swift` (new): high value at top / low at bottom, one band-tinted
  square per whole number (colour derived from the bands via `BandEvaluator` + `Theme`, not
  hardcoded), a fixed centre **selection lens**, drag to pick (snap to 0.1) plus **±0.1 nudge
  buttons**, starts at neutral **7.0**, range **1.0–33.3**. `DailyUseView` now holds a
  `Double`, not a typed string; the confirm→card→widget→reminder pipeline is unchanged.
- **Submit button relabelled "Submit result" and recoloured blue** (`Theme.action`,
  deliberately outside the red/orange/green/amber band palette so it never reads as a band).
- **mg/dL removed from the setup UI** (Units picker + the reset-unit line gone) → the app is
  mmol/L-only in practice. `GlucoseUnit` enum + `AppSettings.unit` are **kept** for JSON/data
  compatibility (no migration, widget snapshot unaffected).
- Built + visually verified on the **iPhone 17 simulator** (dial renders, lens frames the pick,
  amber shows at 10 confirming band-derived colour, blue button).
- **Widget entitlement trap found + worked around.** Any build made with
  `CODE_SIGNING_ALLOWED=NO` — or any CLI build while `-1009` persists — drops the
  `application-groups` entitlement, so `containerURL(forSecurityApplicationGroupIdentifier:)`
  returns `nil`, `WidgetSnapshot` write/read silently fail (errors swallowed by design), and the
  widget is stuck on "Tap to check your sugar". This is why the phone widget "broke" this session
  while the iPad (older, properly-signed install) still showed a reading. **Fix applied:** manual
  `codesign -f -s - --entitlements <plist>` re-sign of the `.appex` then the `.app`, then
  reinstall — App Group container restored (verified provisioned).
- Everything prior stands: result card, setup (bands/contacts/Lock-PIN/Reminders), PIN gate,
  retest reminder, `systemMedium` widget, app icon.
- **Physical-device builds + the local test target are still blocked by Xcode `-1009`.**

## Next session — pick one

1. **On-device verification (iPad handover).** No App Store / publishing needed — this is a direct
   personal-use install. Plug the iPad in and just try a device build; if a signing profile doesn't
   mint, sidestep it (manual profile from the developer portal + manual signing) or fix `-1009`.
   Then confirm on hardware: new icon installs, `tel:` dials, widget renders a real reading, a
   reminder fires + taps through. (The widget's App Group won't provision on a **free** Personal
   Team — that piece needs the paid Developer Program, or drop the widget for the free path.)
2. **Run the test suite** — `ReminderServiceTests` has never executed; unblock via the `-1009` fix
   or a no-signing iOS Simulator destination.
3. **Wheel polish / iteration** — drag sensitivity (`pointsPerUnit` = 52), top/bottom square
   clipping at the row edge, lens styling, and a VoiceOver pass on the dial. Two-wheel picker is
   the easy fallback layout if the drag feel is off.
4. **v2 polish** — `ReadingsStore` JSON persistence; app-icon dark/tinted variants.

## Load in

- **Wheel polish:** `Jinsula/Jinsula/Views/GlucoseDialView.swift`, `Jinsula/Jinsula/Views/DailyUseView.swift`,
  `Jinsula/Jinsula/Theme/Theme.swift`; SPEC.md "Daily-use screen — design plan" §1.
- **On-device verification:** no files — manual. SPEC.md "Retest reminder + widget" §1–§2. The
  `-1009` fix is Xcode UI (Settings → Accounts / restart `akd`), not code.
- **Widget entitlement re-sign:** the `codesign -f -s - --entitlements <plist>` workaround;
  entitlements files `Jinsula/Jinsula/Jinsula.entitlements` + `JinsulaWidgetExtension.entitlements`.
  (Or just press **Run** in Xcode against the simulator — Xcode's local signing embeds them.)
- **Run the test suite:** `Jinsula/JinsulaTests/ReminderServiceTests.swift`; build/test against an
  iOS Simulator destination (no signing) or fix `-1009` first.
- **v2:** `Jinsula/Jinsula/Services/ReadingsStore.swift`; `Scripts/GenerateAppIcon.swift` +
  `Jinsula/Assets.xcassets/AppIcon.appiconset/Contents.json` (empty dark/tinted slots).

## Open questions

- **No App Store / publishing is needed** — grandma's device gets a direct personal-use install.
  Device install still needs *some* valid signing profile (a **free Personal Team is fine**), and
  minting one via Xcode is what `-1009` currently breaks — but that's sidesteppable (manual profile
  + manual signing, a cached profile, or the error being transient). So on-device verification is
  **not hard-gated on `-1009`**; first just try a device build. `-1009` also strips the App-Group
  entitlement from CLI simulator builds (widget goes dark) — press Run in Xcode or re-sign manually.
  Durable fix = Xcode Accounts re-auth / restart `akd`. (`-1009` = `NSURLErrorNotConnectedToInternet`
  from the account daemon even though the Mac reaches Apple fine.)
- **Widget on a real device → paid team, or drop it.** A **free Personal Team cannot provision App
  Groups**, so the widget won't work (and its entitlement can fail the install); free-team signing
  also **expires every 7 days**. The **paid Developer Program ($99/yr)** keeps the widget, gives
  1-year signing, and unlocks TestFlight. Free-path fallback = remove the widget/App Group. This is
  the only real decision before handover — the app itself installs fine on a free team.
- **Wheel drag feel** unverified for the full 1–33 range (`pointsPerUnit` = 52); nudge buttons hedge
  it. Two-wheel picker is the easy fallback if drag feels fiddly.
- **Interactive PIN + setup flow still unverified** — no UI-test target.
- **OS-floor (iOS 15) sign-off is physical-6s-only** — no iOS ≤15 simulator runtime on this Xcode.
