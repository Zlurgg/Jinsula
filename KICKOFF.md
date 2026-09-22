# Jinsula — Kickoff

Rewritten each session (Knobs convention). See `SPEC.md` for durable decisions and
the full session roadmap; `CLAUDE.md` for the codebase map.

## State

- **Setup screen is BUILT and compiles** (iOS 15 / universal). `SetupView` is a
  `NavigationView` + `Form` editing a **working copy** of `AppSettings`, committed only
  on "Done" via `AppModel.commitSettings(_:)` (Cancel discards). Sections: Who / Units
  (segmented, no-conversion note) / Reading thresholds (four boundary fields written to
  both adjacent bands so ranges stay contiguous; positive-and-increasing validation gates
  Done; **Reset to defaults** restores **unit *and* bands**) / per-band `detail` wording
  (headlines fixed) / live Preview / Emergency contacts (add/edit/delete, first = primary,
  empty-list nudge). The ⋯ menu on the daily screen opens it as a sheet.
- **`SettingsStore` is now real** — atomic Codable JSON in Documents, missing/corrupt file
  falls back to the safe UK defaults. `ReadingsStore` is still a stub.
- **Verified partially:** `SetupView` renders correctly (preview) and the app launches on the
  booted SE sim. The interactive flow (present / commit / persist-across-relaunch / cancel /
  validation / reset / contact edit) was **NOT driven** — there is no UI-test target and no
  `idb`, so nothing scripts taps. Real bundle id observed: `uk.co.zlurgg.Jinsula`.
- **Not yet done:** PIN gate + Keychain, reminders toggle + `ReminderService`, the widget
  target + App Group, `ReadingsStore` persistence, and the **app icon (still the Xcode default)**.
  The ⋯ setup door is currently **unguarded**.

## Next session — pick one

1. **PIN gate + widget — MVP for an iPad demo (default).** Smallest thing that gates the
   setup door and shows a Home Screen widget, so it can be demoed on a physical iPad. Keep
   both bare-bones: a 4-digit Keychain PIN in front of `SetupView`, and a widget that reads
   the last snapshot. `ReminderService` can stay stubbed for the demo.
2. **Wire real persistence** (`ReadingsStore` JSON) — small; makes logged readings survive
   and gives the widget snapshot real data.
3. **App icon pass** — replace the default Xcode icon (`Assets.xcassets/AppIcon`); its own
   short session (asset design + all required sizes).

## Load in

- **PIN gate + widget:**
  - PIN: SPEC.md → "Setup screen — design plan" §5 (Lock — 4-digit PIN) + §0. Files:
    `Views/DailyUseView.swift` (the `showingSetup` sheet + ⋯ menu — put a PIN pad in front),
    `Views/SetupView.swift` (the gated screen), `Models/AppSettings.swift` (`isLocked`;
    add `hasPIN` derived from Keychain). New: `Services/PINStore.swift` (Keychain wrapper).
    First-run: no PIN → setup opens directly, prompt to set one at the end (optional).
  - Widget: SPEC.md → "Retest reminder + widget — design plan" (whole section). Hook into
    `AppModel.writeWidgetSnapshot(_:severity:)` (stub) and `ContentView.onOpenURL`
    (`jinsula://check`). New: a Widget Extension target + App Group entitlement on bundle id
    **`uk.co.zlurgg.Jinsula`**.
- **Wire real persistence:** `Services/ReadingsStore.swift` (stub); `Models/GlucoseReading.swift`
  for the Codable shape. Mirror the now-real `Services/SettingsStore.swift`.
- **App icon pass:** `Jinsula/Assets.xcassets/AppIcon.appiconset`.

## Open questions

- **App icon** is still the default — needs its own pass (candidate topic 3).
- **Interactive setup flow is unverified** — no UI-test target / no `idb` in this project.
  To get replayable end-to-end verification, add a UI-test target using XCUIAutomation.
- **Call button dialing unverified** — `tel:` URLs no-op in the Simulator; needs a physical
  device (part of the physical-device sign-off).
- **OS-floor (iOS 15) sign-off is physical-6s-only** — no iOS ≤15 simulator runtime installable
  on this Xcode. Layout floor covered by the "Jinsula SE (layout floor)" simulator.
- **Widget App Group** needs the entitlement wired to `uk.co.zlurgg.Jinsula` (build-mechanics).
