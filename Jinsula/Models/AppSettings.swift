//
//  AppSettings.swift
//  Jinsula
//
//  All configuration a family member sets up once. Persisted as JSON.
//  `isLocked` guards the setup screen so grandma can't change bands or contacts
//  by accident during daily use.
//

import Foundation

struct AppSettings: Codable, Equatable {
    var userName: String
    var unit: GlucoseUnit
    var bands: [GuidanceBand]
    var contacts: [EmergencyContact]
    var isLocked: Bool

    static let `default` = AppSettings(
        userName: "",
        unit: .mmolPerL,
        bands: GuidanceBand.defaultUKBands,
        contacts: [],
        isLocked: false
    )
}

/// A person grandma can call with one tap (name + phone number).
struct EmergencyContact: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var phoneNumber: String

    init(id: UUID = UUID(), name: String, phoneNumber: String) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
    }
}
