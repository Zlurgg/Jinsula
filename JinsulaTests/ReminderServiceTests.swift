//
//  ReminderServiceTests.swift
//  JinsulaTests
//
//  Verifies the low-band retest nudges (SPEC.md §1) without touching the real
//  notification centre: a spy captures the requests ReminderService schedules
//  and the identifiers it cancels, so the scheduling contract is asserted
//  deterministically (no waiting, no permission prompt).
//

import Testing
import UserNotifications
@testable import Jinsula

/// Records what ReminderService asks the notification centre to do.
private final class SpyNotificationCenter: UserNotificationScheduling {
    var addedRequests: [UNNotificationRequest] = []
    var removedIdentifiers: [String] = []
    var authorizationRequested = false
    var authorizationStatusToReturn: UNAuthorizationStatus = .authorized

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        authorizationRequested = true
        return true
    }

    func add(_ request: UNNotificationRequest) async throws {
        addedRequests.append(request)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removedIdentifiers.append(contentsOf: identifiers)
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        authorizationStatusToReturn
    }
}

/// In-memory doubles so `AppModel` can be exercised without touching disk or
/// the Keychain.
private final class FakeSettingsStore: SettingsStoring {
    var stored: AppSettings
    init(_ settings: AppSettings) { stored = settings }
    func load() -> AppSettings { stored }
    func save(_ settings: AppSettings) { stored = settings }
}

private final class FakeReadingsStore: ReadingsStoring {
    func load() -> [GlucoseReading] { [] }
    func append(_ reading: GlucoseReading) {}
}

private final class FakePINStore: PINStoring {
    var hasPIN = false
    func setPIN(_ pin: String) { hasPIN = true }
    func verify(_ pin: String) -> Bool { false }
    func clear() { hasPIN = false }
}

@Suite("ReminderService")
struct ReminderServiceTests {

    @Test("schedules two non-repeating nudges at the configured intervals")
    func schedulesTwoNudges() async {
        let spy = SpyNotificationCenter()
        let service = ReminderService(center: spy, intervals: [15 * 60, 30 * 60])

        await service.scheduleRetest()

        #expect(spy.addedRequests.count == 2)

        let triggers = spy.addedRequests.compactMap { $0.trigger as? UNTimeIntervalNotificationTrigger }
        #expect(triggers.count == 2)
        #expect(triggers[0].timeInterval == 15 * 60)
        #expect(triggers[1].timeInterval == 30 * 60)
        #expect(triggers.allSatisfy { !$0.repeats })

        // Fixed identifiers → only ever one pair pending.
        let ids = Set(spy.addedRequests.map(\.identifier))
        #expect(ids == [ReminderService.firstIdentifier, ReminderService.secondIdentifier])
    }

    @Test("re-scheduling clears the existing pair first so nudges never stack")
    func replacesRatherThanStacks() async {
        let spy = SpyNotificationCenter()
        let service = ReminderService(center: spy, intervals: [15 * 60, 30 * 60])

        await service.scheduleRetest()

        #expect(spy.removedIdentifiers.contains(ReminderService.firstIdentifier))
        #expect(spy.removedIdentifiers.contains(ReminderService.secondIdentifier))
    }

    @Test("cancelRetest removes exactly the two retest requests")
    func cancelRemovesBoth() {
        let spy = SpyNotificationCenter()
        let service = ReminderService(center: spy, intervals: [15 * 60, 30 * 60])

        service.cancelRetest()

        #expect(Set(spy.removedIdentifiers) == [ReminderService.firstIdentifier,
                                                ReminderService.secondIdentifier])
    }

    @Test("the body reinforces the core safety line — sugar, never insulin")
    func bodyReinforcesSafety() async {
        let spy = SpyNotificationCenter()
        let service = ReminderService(center: spy, intervals: [8, 16])

        await service.scheduleRetest()

        let body = spy.addedRequests.first?.content.body ?? ""
        #expect(body.contains("eat sugar"))
        #expect(body.contains("do not take insulin"))
    }

    @Test("the shipped default intervals are the real 15 and 30 minutes")
    func defaultIntervalsAreFifteenAndThirty() {
        // The DEBUG 8s/16s override was removed (SPEC §1 finish) — every build
        // uses the true quarter-hour cadence.
        #expect(ReminderService.defaultIntervals == [15 * 60, 30 * 60])
    }

    @MainActor
    @Test("scheduleRetestReminder no-ops when the reminders toggle is off")
    func schedulingHonoursTheOffToggle() {
        let spy = SpyNotificationCenter()
        var settings = AppSettings.default
        settings.remindersEnabled = false
        let model = AppModel(settingsStore: FakeSettingsStore(settings),
                             readingsStore: FakeReadingsStore(),
                             pinStore: FakePINStore(),
                             reminderService: ReminderService(center: spy))

        model.scheduleRetestReminder()

        // The guard returns before spawning any work — nothing scheduled, no
        // permission prompt.
        #expect(spy.addedRequests.isEmpty)
        #expect(!spy.authorizationRequested)
    }

    @MainActor
    @Test("a retest-notification tap opens a fresh entry and cancels the survivor")
    func tapOpensFreshEntryAndCancels() {
        let spy = SpyNotificationCenter()
        let model = AppModel(settingsStore: FakeSettingsStore(.default),
                             readingsStore: FakeReadingsStore(),
                             pinStore: FakePINStore(),
                             reminderService: ReminderService(center: spy))

        model.handleRetestNotificationTap()

        #expect(model.shouldStartFreshEntry)
        #expect(Set(spy.removedIdentifiers) == [ReminderService.firstIdentifier,
                                                ReminderService.secondIdentifier])
    }
}
