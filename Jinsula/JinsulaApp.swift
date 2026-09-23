//
//  JinsulaApp.swift
//  Jinsula
//
//  Created by Joseph Brightman on 22/09/2026.
//

import SwiftUI
import UIKit
import UserNotifications

@main
struct JinsulaApp: App {
    @StateObject private var model = AppModel()
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView(appDelegate: appDelegate)
                .environmentObject(model)
        }
    }
}

/// Owns the notification-tap wiring. SwiftUI has no built-in
/// `UNUserNotificationCenterDelegate` hook, so we install one via
/// `@UIApplicationDelegateAdaptor`. It holds a `weak` `AppModel`, wired by
/// `ContentView.onAppear`, and routes both foreground presentation and taps of
/// the retest nudge (SPEC.md "Retest reminder + widget" §1).
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    weak var model: AppModel?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    /// A low-sugar nudge must never be silently swallowed while the app is open,
    /// so present the banner + sound even in the foreground.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    /// Tap → the shared open-entry path (blank entry) and cancel the surviving
    /// nudge. A cold-launch tap arriving before `model` is wired is harmless —
    /// the app already opens on a blank entry.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        Task { @MainActor in
            model?.handleRetestNotificationTap()
            completionHandler()
        }
    }
}
