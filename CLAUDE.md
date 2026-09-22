# Jinsula — Codebase map

Safety-first blood-glucose response helper for an elderly UK user. Read `SPEC.md`
for the why and the safety rules; `KICKOFF.md` for the current to-do.

## Layout (`Jinsula/Jinsula/`)

```
Models/
  GlucoseUnit.swift      – mmol/L (default) | mg/dL
  GlucoseReading.swift   – one logged reading (Codable)
  GuidanceBand.swift     – "rules as data": range → colour/message/action
                           (+ default UK bands; SAFETY notes inline)
  BandEvaluator.swift    – pure fn: reading + [bands] → matched band (testable)
  AppSettings.swift      – all setup config + EmergencyContact; isLocked flag
ViewModels/
  AppModel.swift         – ObservableObject top-level state (@MainActor)
Services/
  SettingsStore.swift    – JSON persistence for settings (stub)
  ReadingsStore.swift    – JSON persistence for readings (stub)
  SpeechService.swift    – AVSpeechSynthesizer wrapper (stub)
Views/
  DailyUseView.swift     – grandma's everyday screen (placeholder)
  ResultCardView.swift   – full-screen colour guidance card (placeholder)
  SetupView.swift        – family-only config, behind the lock (placeholder)
  HistoryView.swift      – past readings list (placeholder)
Theme/
  Theme.swift            – all fonts + band colours
ContentView.swift        – root (currently → DailyUseView)
JinsulaApp.swift         – @main, injects AppModel via .environmentObject
```

## Conventions / constraints

- **Target iOS 15** (old-device support) → use `ObservableObject`, NOT `@Observable`;
  use **Codable JSON**, NOT SwiftData/Core Data.
- Universal app: iPhone + iPad (iPad 8th gen is a first-class large-display target).
- Bands are the single source of truth — never branch band logic inside views.
- **Never compute an insulin dose.** See SPEC.md safety principles.
- Tests: Swift Testing framework; start with pure `BandEvaluator` tests.
