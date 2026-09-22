//
//  ReadingsStore.swift
//  Jinsula
//
//  Persists the log of `GlucoseReading`s as JSON. See SPEC.md for why plain
//  Codable JSON is used rather than SwiftData/Core Data.
//

import Foundation

protocol ReadingsStoring {
    func load() -> [GlucoseReading]
    func append(_ reading: GlucoseReading)
}

/// Skeleton implementation — JSON read/write to be filled in a later session.
final class ReadingsStore: ReadingsStoring {
    func load() -> [GlucoseReading] { [] }
    func append(_ reading: GlucoseReading) { /* TODO: write JSON */ }
}
