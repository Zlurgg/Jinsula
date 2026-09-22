//
//  GlucoseReading.swift
//  Jinsula
//
//  A single blood glucose measurement, logged automatically when grandma
//  enters a value. Persisted as JSON (see ReadingsStore).
//

import Foundation

struct GlucoseReading: Codable, Identifiable, Equatable {
    let id: UUID
    let value: Double
    let date: Date
    let unit: GlucoseUnit

    init(id: UUID = UUID(), value: Double, date: Date, unit: GlucoseUnit) {
        self.id = id
        self.value = value
        self.date = date
        self.unit = unit
    }
}
