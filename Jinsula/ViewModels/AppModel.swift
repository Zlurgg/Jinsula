//
//  AppModel.swift
//  Jinsula
//
//  Top-level app state. Uses `ObservableObject` (not the iOS 17 `@Observable`
//  macro) so the app can target iOS 15 for old-device support. See SPEC.md.
//

import SwiftUI
import Combine

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var settings: AppSettings
    @Published private(set) var readings: [GlucoseReading]

    private let settingsStore: SettingsStoring
    private let readingsStore: ReadingsStoring

    /// Stores are injectable for tests; `nil` uses the JSON-backed defaults.
    init(settingsStore: SettingsStoring? = nil, readingsStore: ReadingsStoring? = nil) {
        let settingsStore = settingsStore ?? SettingsStore()
        let readingsStore = readingsStore ?? ReadingsStore()
        self.settingsStore = settingsStore
        self.readingsStore = readingsStore
        self.settings = settingsStore.load()
        self.readings = readingsStore.load()
    }

    /// Evaluates a typed reading against the configured bands.
    /// Persistence wiring comes in a later session.
    func band(for value: Double) -> GuidanceBand? {
        BandEvaluator.band(for: value, in: settings.bands)
    }
}
