//
//  GuidanceBand.swift
//  Jinsula
//
//  A guidance band maps a range of readings to a plain-language response.
//
//  This is the core "rules as data" model borrowed from the Knobs project: the
//  setup screen edits an array of `GuidanceBand`, and the daily-use card renders
//  whichever band a reading falls into. There is no band logic scattered through
//  the views — the bands ARE the logic.
//
//  SAFETY: these bands are fully customised during setup to match grandma's own
//  care plan. The defaults below are only sensible UK starting points (Diabetes
//  UK "4 is the floor"). The app never calculates an insulin dose itself — a high
//  band points the user to their care team's plan. See SPEC.md.
//

import Foundation

struct GuidanceBand: Codable, Identifiable, Equatable {
    let id: UUID

    /// Inclusive lower bound. `nil` means open-ended (no lower limit).
    var lower: Double?
    /// Exclusive upper bound. `nil` means open-ended (no upper limit).
    var upper: Double?

    var severity: Severity
    /// Short, loud line shown biggest on the card, e.g. "Eat sugar now".
    var headline: String
    /// Supporting **directional** detail (have sugar / follow your plan / call).
    /// Never names amounts or doses — safety principle #5. Family may add their
    /// own care-plan wording here at setup; shipped defaults stay amount-free.
    var detail: String
    /// Which action button (if any) the card offers.
    var action: Action

    enum Severity: String, Codable, CaseIterable {
        case emergency, low, inRange, high
    }

    enum Action: String, Codable, CaseIterable {
        case none          // no button
        case retestTimer   // "Remind me in 15 minutes"
        case callContact   // "Call <name>"
    }

    init(id: UUID = UUID(), lower: Double?, upper: Double?,
         severity: Severity, headline: String, detail: String, action: Action) {
        self.id = id
        self.lower = lower
        self.upper = upper
        self.severity = severity
        self.headline = headline
        self.detail = detail
        self.action = action
    }
}

extension GuidanceBand {
    /// UK defaults (mmol/L), grounded in official guidance and **amount-free**
    /// (safety principle #5 — the app names direction, never quantities/doses).
    /// Starting points only — thresholds are adjusted per person during setup.
    /// Boundaries T1=3.0, T2=4.0, T3=10.0, T4=15.0. See SPEC.md "Default UK bands".
    static var defaultUKBands: [GuidanceBand] {
        [
            GuidanceBand(lower: nil, upper: 3.0, severity: .emergency,
                         headline: "Get help now",
                         detail: "Your sugar is very low. Have sugar now and call for help.",
                         action: .callContact),
            GuidanceBand(lower: 3.0, upper: 4.0, severity: .low,
                         headline: "Eat sugar now — do NOT take insulin",
                         detail: "Your sugar is low. Have something sugary. Test again in 15 minutes.",
                         action: .retestTimer),
            GuidanceBand(lower: 4.0, upper: 10.0, severity: .inRange,
                         headline: "You're okay",
                         detail: "Your sugar is in a good range.",
                         action: .none),
            GuidanceBand(lower: 10.0, upper: 15.0, severity: .high,
                         headline: "Your sugar is high",
                         detail: "Follow the plan your nurse gave you.",
                         action: .none),
            GuidanceBand(lower: 15.0, upper: nil, severity: .emergency,
                         headline: "Reading very high",
                         detail: "Call your family or nurse.",
                         action: .callContact)
        ]
    }
}
