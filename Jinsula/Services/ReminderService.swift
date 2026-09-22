//
//  ReminderService.swift
//  Jinsula
//
//  Schedules the low-band "check your sugar again" retest nudges as local
//  notifications (SPEC.md "Retest reminder + widget" §1). They must fire even
//  after grandma has left the app, so a notification — not an in-app timer.
//
//  The service adds no band logic: it hangs off the single "a reading was just
//  confirmed" moment via `AppModel`. Two non-repeating nudges are scheduled up
//  front (+15 and +30 min) with fixed identifiers, so re-tapping *replaces*
//  rather than stacks, and engaging with the app cancels the survivor.
//

import Foundation
import UserNotifications

/// The slice of `UNUserNotificationCenter` the service needs, expressed as a
/// protocol so the scheduling logic is unit-testable with a spy (the real
/// centre is a singleton that can't otherwise be injected). The system class
/// already provides these exact signatures, so the conformance is empty.
protocol UserNotificationScheduling {
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func add(_ request: UNNotificationRequest) async throws
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
}

extension UNUserNotificationCenter: UserNotificationScheduling {}

final class ReminderService {
    /// Fixed identifiers so only ever one pair is pending — a re-tap replaces.
    static let firstIdentifier = "uk.co.zlurgg.Jinsula.retest.1"
    static let secondIdentifier = "uk.co.zlurgg.Jinsula.retest.2"

#if DEBUG
    // TESTING AFFORDANCE — short nudges so the full retest flow can be observed
    // on a device/simulator in seconds instead of waiting a quarter hour. This
    // applies to ALL Debug builds (including one side-loaded onto the iPad), so
    // it must be replaced by a real, user-visible setting in the dedicated
    // reminders session before release. Release builds use the true 15/30 min.
    static let defaultIntervals: [TimeInterval] = [8, 16]
#else
    static let defaultIntervals: [TimeInterval] = [15 * 60, 30 * 60]
#endif

    private let center: UserNotificationScheduling
    /// Seconds-from-now for each nudge. Injectable so tests assert exact values.
    private let intervals: [TimeInterval]

    init(center: UserNotificationScheduling = UNUserNotificationCenter.current(),
         intervals: [TimeInterval]? = nil) {
        self.center = center
        self.intervals = intervals ?? Self.defaultIntervals
    }

    /// Requested contextually on the first retest tap (SPEC §1 permission
    /// timing). Returns `false` on denial or error — the card still flows, we
    /// simply can't remind.
    @discardableResult
    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    /// Schedules the two non-repeating nudges, clearing any existing pair first
    /// so reminders never stack.
    func scheduleRetest() async {
        cancelRetest()
        let identifiers = [Self.firstIdentifier, Self.secondIdentifier]
        for (index, interval) in intervals.enumerated() where index < identifiers.count {
            let content = UNMutableNotificationContent()
            content.title = "Time to check your sugar again"
            content.body = "Please test your sugar again now. If it's still low, eat sugar — do not take insulin."
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            let request = UNNotificationRequest(identifier: identifiers[index],
                                                content: content,
                                                trigger: trigger)
            try? await center.add(request)
        }
    }

    /// Removes both pending nudges — called when a new reading is confirmed or
    /// the app is otherwise engaged.
    func cancelRetest() {
        center.removePendingNotificationRequests(
            withIdentifiers: [Self.firstIdentifier, Self.secondIdentifier]
        )
    }
}
