//
//  BandEvaluator.swift
//  Jinsula
//
//  Pure logic that matches a reading to its guidance band. Kept free of any UI
//  so it can be unit-tested directly with the Swift Testing framework.
//

import Foundation

enum BandEvaluator {
    /// Returns the first band whose range contains `value`, or `nil` if none.
    /// Ranges are treated as [lower, upper): lower inclusive, upper exclusive.
    static func band(for value: Double, in bands: [GuidanceBand]) -> GuidanceBand? {
        bands.first { band in
            let aboveLower = band.lower.map { value >= $0 } ?? true
            let belowUpper = band.upper.map { value < $0 } ?? true
            return aboveLower && belowUpper
        }
    }
}
