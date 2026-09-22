//
//  GlucoseUnit.swift
//  Jinsula
//
//  The measurement unit for blood glucose readings. Grandma is UK-based, so
//  `.mmolPerL` is the default. `.mgPerDl` is kept so the same band logic can
//  serve other regions later without a rewrite.
//

import Foundation

enum GlucoseUnit: String, Codable, CaseIterable {
    case mmolPerL
    case mgPerDl

    var shortLabel: String {
        switch self {
        case .mmolPerL: return "mmol/L"
        case .mgPerDl:  return "mg/dL"
        }
    }
}
