//
//  SettingsStore.swift
//  Jinsula
//
//  Persists `AppSettings` as JSON in the app's Documents directory. Plain
//  Codable JSON is used instead of SwiftData/Core Data so the app runs on very
//  old iOS versions (iPhone 6s / iOS 15). See SPEC.md.
//

import Foundation

protocol SettingsStoring {
    func load() -> AppSettings
    func save(_ settings: AppSettings)
}

/// Skeleton implementation — JSON read/write to be filled in a later session.
final class SettingsStore: SettingsStoring {
    func load() -> AppSettings { .default }
    func save(_ settings: AppSettings) { /* TODO: write JSON */ }
}
