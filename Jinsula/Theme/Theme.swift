//
//  Theme.swift
//  Jinsula
//
//  Central design tokens. Everything here is tuned for an elderly user on an
//  old iPhone: very large type, high contrast, and a small fixed set of band
//  colours. Keep all colours/fonts here — do not scatter literals through views.
//

import SwiftUI

enum Theme {
    // MARK: Band colours (see GuidanceBand.Severity)
    static let emergency = Color(red: 0.85, green: 0.11, blue: 0.09) // red
    static let low       = Color(red: 0.92, green: 0.55, blue: 0.05) // orange
    static let inRange   = Color(red: 0.18, green: 0.68, blue: 0.28) // green
    static let high      = Color(red: 0.90, green: 0.72, blue: 0.10) // amber

    static func colour(for severity: GuidanceBand.Severity) -> Color {
        switch severity {
        case .emergency: return emergency
        case .low:       return low
        case .inRange:   return inRange
        case .high:      return high
        }
    }

    // MARK: Large-format fonts for the daily-use screen
    static func reading(_ size: CGFloat = 96) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    static func headline(_ size: CGFloat = 40) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    static func instruction(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
}
