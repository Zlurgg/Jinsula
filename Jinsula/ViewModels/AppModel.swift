//
//  AppModel.swift
//  Jinsula
//
//  Top-level app state. Uses `ObservableObject` (not the iOS 17 `@Observable`
//  macro) so the app can target iOS 15 for old-device support. See SPEC.md.
//

import SwiftUI
import Combine
import WidgetKit
import UserNotifications

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var settings: AppSettings
    @Published private(set) var readings: [GlucoseReading]

    /// Open-entry intent (SPEC.md "Retest reminder + widget" §0). Set when a
    /// widget or notification tap should land on a **blank** entry screen;
    /// `DailyUseView` observes it, dismisses the result card *and* clears the
    /// field, then clears the flag. Idempotent across both sources.
    @Published var shouldStartFreshEntry = false

    /// Whether a family PIN currently gates the setup screen. Derived from the
    /// Keychain (SPEC.md §5) and mirrored here as published state so the setup
    /// door and the Lock section react the moment a PIN is set.
    @Published private(set) var hasPIN: Bool

    private let settingsStore: SettingsStoring
    private let readingsStore: ReadingsStoring
    private let pinStore: PINStoring
    private let reminderService: ReminderService

    /// Collaborators are injectable for tests; `nil` uses the JSON-/Keychain-/
    /// notification-backed defaults.
    init(settingsStore: SettingsStoring? = nil,
         readingsStore: ReadingsStoring? = nil,
         pinStore: PINStoring? = nil,
         reminderService: ReminderService? = nil) {
        let settingsStore = settingsStore ?? SettingsStore()
        let readingsStore = readingsStore ?? ReadingsStore()
        let pinStore = pinStore ?? PINStore()
        self.settingsStore = settingsStore
        self.readingsStore = readingsStore
        self.pinStore = pinStore
        self.reminderService = reminderService ?? ReminderService()
        self.settings = settingsStore.load()
        self.readings = readingsStore.load()
        self.hasPIN = pinStore.hasPIN
    }

    /// Evaluates a typed reading against the configured bands.
    func band(for value: Double) -> GuidanceBand? {
        BandEvaluator.band(for: value, in: settings.bands)
    }

    /// The single "a reading was just confirmed" hook (SPEC.md "Retest reminder
    /// + widget" §0). Matches the band **once**, and only if a band matches does
    /// it commit the side effects in one place: log the `GlucoseReading`, cancel
    /// any pending retest reminder, and write the widget snapshot.
    ///
    /// Returns the matched band so `DailyUseView` can present the card, or `nil`
    /// for out-of-band input — in which case **nothing is logged and no snapshot
    /// is written**, and the view stays on the entry screen (a typo is never
    /// recorded). The `nil` path is defensive: with contiguous open-ended bands
    /// an in-range value always matches.
    func confirmReading(_ value: Double) -> GuidanceBand? {
        guard let band = band(for: value) else { return nil }

        let reading = GlucoseReading(value: value, date: Date(), unit: settings.unit)
        readingsStore.append(reading)
        readings.append(reading)

        cancelRetestReminder()
        writeWidgetSnapshot(for: reading, severity: band.severity)

        return band
    }

    /// Called when a low-band card's "Remind me in 15 minutes" is tapped.
    /// Requests notification permission (contextually, on first tap) then
    /// schedules the +15/+30 min nudges. Fire-and-forget: the card dismisses
    /// immediately whether or not permission is granted (SPEC §1).
    func scheduleRetestReminder() {
        guard settings.remindersEnabled else { return }
        Task {
            await reminderService.requestAuthorization()
            await reminderService.scheduleRetest()
        }
    }

    /// Called by the notification delegate when grandma taps a retest nudge.
    /// Reuses the widget's open-entry path (lands on a blank entry) **and**
    /// cancels the surviving nudge, so the second reminder never fires after
    /// she's already engaged (SPEC.md "Retest reminder + widget" §1).
    func handleRetestNotificationTap() {
        shouldStartFreshEntry = true
        reminderService.cancelRetest()
    }

    /// Requests notification permission up front when the setup Reminders toggle
    /// is switched on (SPEC §1 permission timing). Fire-and-forget from the view.
    @discardableResult
    func requestReminderAuthorization() async -> Bool {
        await reminderService.requestAuthorization()
    }

    /// Current notification permission, so the setup toggle can hint at iOS
    /// Settings when notifications are off for Jinsula.
    func reminderAuthorizationStatus() async -> UNAuthorizationStatus {
        await reminderService.authorizationStatus()
    }

    /// Clears the open-entry intent after `DailyUseView` has consumed it.
    func consumeFreshEntry() {
        shouldStartFreshEntry = false
    }

    /// Commits edited settings from the setup screen (SPEC.md "Setup screen" §0).
    /// The setup screen edits a **working copy** and calls this only on "Done", so
    /// a half-edited band array never reaches the daily-use card. Persists through
    /// the store and updates live state in one step, so the next reading is matched
    /// against the new bands immediately.
    func commitSettings(_ newSettings: AppSettings) {
        settings = newSettings
        settingsStore.save(newSettings)
    }

    // MARK: - Setup PIN (SPEC.md §5)

    /// True only when `pin` matches the stored PIN. Used by the unlock pad.
    func verifyPIN(_ pin: String) -> Bool {
        pinStore.verify(pin)
    }

    /// Stores (or replaces) the setup PIN and flips `hasPIN`, so the gate is
    /// live immediately. There is no recovery flow — see `PINStore` / SPEC.md §5.
    func setPIN(_ pin: String) {
        pinStore.setPIN(pin)
        hasPIN = true
    }

    // MARK: - Stubbed collaborators (wired in later build sessions)

    /// A new confirmed reading supersedes any pending retest nudge.
    private func cancelRetestReminder() {
        reminderService.cancelRetest()
    }

    /// Writes the tiny {value, unit, date, severity} snapshot to the App Group
    /// container and reloads widget timelines, so the Home Screen widget shows
    /// the reading grandma just confirmed (SPEC.md §2). Storing the matched
    /// `severity` (not the bands) keeps the widget dumb — a colour and text.
    private func writeWidgetSnapshot(for reading: GlucoseReading,
                                     severity: GuidanceBand.Severity) {
        let snapshot = WidgetSnapshot(value: reading.value,
                                      unitLabel: reading.unit.shortLabel,
                                      date: reading.date,
                                      severity: severity)
        WidgetSnapshotStore.write(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
