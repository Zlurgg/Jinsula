//
//  WidgetSnapshot.swift
//  Jinsula
//
//  The tiny payload the app writes on each confirmed reading and the Home
//  Screen widget reads to render (SPEC.md "Retest reminder + widget" §2).
//
//  Kept deliberately small so the widget stays *dumb*: it never sees the bands
//  array, `BandEvaluator`, or `AppSettings` — only a value, its unit label, the
//  time it was taken, and the matched `Severity` (→ colour via `Theme`). The
//  unit is stored as a display string, not `GlucoseUnit`, so the extension
//  needn't share the unit model.
//
//  SHARED FILE: target membership must include BOTH the Jinsula app and the
//  JinsulaWidget extension.
//

import Foundation

struct WidgetSnapshot: Codable, Equatable {
    let value: Double
    /// Pre-formatted unit label (e.g. "mmol/L") — see `GlucoseUnit.shortLabel`.
    let unitLabel: String
    let date: Date
    let severity: GuidanceBand.Severity
}

/// Read/write access to the single shared snapshot in the App Group container.
/// Both sides use the same suite id and filename; writes are atomic and every
/// failure is swallowed — a snapshot problem must never disturb the reading
/// path or crash the widget.
enum WidgetSnapshotStore {
    /// Must match the **App Groups** capability enabled on BOTH the Jinsula app
    /// and the JinsulaWidget extension targets.
    static let appGroupID = "group.uk.co.zlurgg.Jinsula"
    private static let filename = "widget-snapshot.json"

    private static var fileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(filename)
    }

    static func write(_ snapshot: WidgetSnapshot) {
        guard let url = fileURL else { return }
        do {
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: url, options: .atomic)
        } catch {
            // Non-fatal: a failed snapshot write must not affect the reading.
        }
    }

    static func read() -> WidgetSnapshot? {
        guard let url = fileURL,
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }
}
