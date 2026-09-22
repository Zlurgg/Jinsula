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

/// JSON-backed store. A missing or unreadable file falls back to the safe
/// defaults, so a first run (or a corrupted file) still lands on the
/// guidance-grounded UK bands rather than an empty/unsafe configuration.
final class SettingsStore: SettingsStoring {
    private let fileURL: URL

    init(fileName: String = "settings.json") {
        let directory = FileManager.default.urls(for: .documentDirectory,
                                                 in: .userDomainMask)[0]
        self.fileURL = directory.appendingPathComponent(fileName)
    }

    func load() -> AppSettings {
        guard let data = try? Data(contentsOf: fileURL),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data)
        else {
            return .default
        }
        return settings
    }

    func save(_ settings: AppSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }
}
