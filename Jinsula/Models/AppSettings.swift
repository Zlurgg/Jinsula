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
    /// Whether the low-band retest reminder may be scheduled. Defaults ON so a
    /// low reading always nudges a retest unless a family member turns it off in
    /// setup (SPEC.md "Retest reminder + widget" §1).
    var remindersEnabled: Bool
    var isLocked: Bool

    static let `default` = AppSettings(
        userName: "",
        unit: .mmolPerL,
        bands: GuidanceBand.defaultUKBands,
        contacts: [],
        remindersEnabled: true,
        isLocked: false
    )
}

extension AppSettings {
    private enum CodingKeys: String, CodingKey {
        case userName, unit, bands, contacts, remindersEnabled, isLocked
    }

    /// Custom decode so settings JSON written before the Reminders toggle
    /// existed still loads — the missing key defaults to ON (see above). Declared
    /// in an extension so the memberwise initialiser is preserved.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        userName = try c.decode(String.self, forKey: .userName)
        unit = try c.decode(GlucoseUnit.self, forKey: .unit)
        bands = try c.decode([GuidanceBand].self, forKey: .bands)
        contacts = try c.decode([EmergencyContact].self, forKey: .contacts)
        remindersEnabled = try c.decodeIfPresent(Bool.self, forKey: .remindersEnabled) ?? true
        isLocked = try c.decode(Bool.self, forKey: .isLocked)
    }
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
