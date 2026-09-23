# Jinsula — Codebase map

Safety-first blood-glucose response helper for an elderly UK user. Read `SPEC.md`
for the why and the safety rules; `KICKOFF.md` for the current to-do.

## Layout (`Jinsula/Jinsula/`)

```
Models/
  GlucoseUnit.swift      – mmol/L (default) | mg/dL (mg/dL retained for data compat only;
                           dropped from the setup UI in Session 14 — app is mmol/L in practice)
  GlucoseReading.swift   – one logged reading (Codable)
  GuidanceBand.swift     – "rules as data": range → colour/message/action
                           (+ default UK bands; SAFETY notes inline)
  BandEvaluator.swift    – pure fn: reading + [bands] → matched band (testable)
  AppSettings.swift      – all setup config + EmergencyContact; isLocked + remindersEnabled
                           (default ON; tolerant decoder for pre-toggle JSON)
  WidgetSnapshot.swift   – shared {value, unitLabel, date, severity} + App-Group read/write
                           (member of BOTH app + JinsulaWidget targets)
ViewModels/
  AppModel.swift         – ObservableObject top-level state (@MainActor)
Services/
  SettingsStore.swift    – JSON persistence for settings (real: atomic, safe-fallback)
  ReadingsStore.swift    – JSON persistence for readings (stub)
  PINStore.swift         – Keychain wrapper for the setup PIN (injectable; not in JSON)
  ReminderService.swift  – UNUserNotificationCenter retest nudges (+15/+30 min always, fixed IDs);
                           injectable seam (+ authorizationStatus()) + intervals. Unit-tested.
                           Scheduling gated on AppSettings.remindersEnabled via AppModel.
  SpeechService.swift    – AVSpeechSynthesizer wrapper (.playback, en-GB, speaks 2 lines)
Views/
  DailyUseView.swift     – grandma's everyday screen: vertical colour WHEEL → card (BUILT).
                           Holds a Double (the picked value), not a typed string.
  GlucoseDialView.swift  – the wheel: high-at-top drag dial, 1.0–33.3, snap 0.1, per-integer
                           squares band-tinted (BandEvaluator+Theme), centre selection lens,
                           ±0.1 nudge buttons, VoiceOver-adjustable. Starts at 7.0. (BUILT S14)
  ResultCardView.swift   – full-screen colour guidance card, renders from band (BUILT)
  SetupView.swift        – family-only config: Form editing a working copy, commit-on-Done
                           (bands/contacts + Reminders toggle + Lock/PIN section BUILT;
                           Units picker removed S14 → mmol/L only)
  PINEntryView.swift     – 4-digit PIN pad (.unlock/.set) + SetupGateView (gates the ⋯ door)
  HistoryView.swift      – past readings list (placeholder)
Theme/
  Theme.swift            – all fonts + band colours + `action` (blue button colour, outside
                           the band palette)
ContentView.swift        – root (currently → DailyUseView); onOpenURL(jinsula://) → fresh entry;
                           onAppear wires AppDelegate.model for notification-tap routing
JinsulaApp.swift         – @main, injects AppModel via .environmentObject; hosts AppDelegate
                           (@UIApplicationDelegateAdaptor) = UNUserNotificationCenter delegate:
                           foreground banner + tap → AppModel.handleRetestNotificationTap()
```

Other targets (siblings of `Jinsula/Jinsula/`):
```
JinsulaWidget/           – Widget Extension (systemMedium, iOS 15). Reads WidgetSnapshot,
                           renders band colour + value/time, whole-widget jinsula://check.
JinsulaTests/            – Swift Testing target (ReminderServiceTests; @testable import Jinsula).
```

Not an Xcode target — a standalone script:
```
Scripts/GenerateAppIcon.swift  – Swift+CoreGraphics renderer for the app icon (droplet +
                                 traffic-light, Theme palette). Run: `swift Scripts/GenerateAppIcon.swift`
                                 → opaque 1024 icon-1024.png into the app AppIcon.appiconset.
                                 NOT a member of any target; editable/reproducible source of the icon.
```

## Conventions / constraints

- **Target iOS 15** (old-device support) → use `ObservableObject`, NOT `@Observable`;
  use **Codable JSON**, NOT SwiftData/Core Data.
- Universal app: iPhone + iPad (iPad 8th gen is a first-class large-display target).
- Bands are the single source of truth — never branch band logic inside views.
- **Never compute an insulin dose, and never name amounts/doses.** The app gives direction
  (low/okay/high, sugar vs insulin, retest in 15 min), never quantities. See SPEC.md safety
  principles #2 & #5.
- **No unit conversion.** The unit (`settings.unit`, always UK mmol/L now) is used as-is;
  no ×/÷ 18.0182 anywhere. mg/dL is dropped from the setup UI (Session 14) but the
  `GlucoseUnit` enum + `AppSettings.unit` field stay for JSON/data compatibility.
- Shared hooks live on `AppModel`, not in views: `confirmReading(_:)` (fires only after a
  band matches), `shouldStartFreshEntry` (open-entry intent for widget/notification taps), and
  `commitSettings(_:)` (setup "Done" — persists + updates live state in one place).
- **Widget stays dumb:** the extension never sees the bands, `BandEvaluator`, or settings —
  only the `WidgetSnapshot` (colour via shared `Theme`). Data crosses via **App Group
  `group.uk.co.zlurgg.Jinsula`** (capability on both targets). The `jinsula://` scheme is
  registered in the app's Info.plist (`CFBundleURLTypes`) — without it the widget/notification
  deep link is a silent no-op.
- **Widget needs the App-Group entitlement embedded** or its shared container is `nil` and it
  shows only "Tap to check your sugar". CLI builds with `CODE_SIGNING_ALLOWED=NO` (or any build
  while Xcode `-1009` persists) **strip** `application-groups` → widget goes dark. Fix: press Run
  in Xcode (embeds it locally), or re-sign manually: `codesign -f -s - --entitlements <plist>` the
  `.appex` then the `.app`. See KICKOFF open questions.
- Tests: Swift Testing framework (target `JinsulaTests`); `ReminderService` covered — inject the
  `UserNotificationScheduling` seam with a spy rather than hitting the real notification centre.
