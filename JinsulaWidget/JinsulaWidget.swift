//
//  JinsulaWidget.swift
//  JinsulaWidget
//
//  Home Screen widget (SPEC.md "Retest reminder + widget" §2). Shows the last
//  confirmed reading on a band-coloured card; the whole widget is one deep link
//  (jinsula://check) that opens a fresh entry. iOS 15 has no interactive widget
//  buttons, so there is deliberately no button — the card *is* the button.
//
//  The widget is dumb: it reads the shared `WidgetSnapshot` (value, unit, time,
//  severity) and renders. No bands, no `BandEvaluator`, no settings. The band
//  colour comes from the shared `Theme`; absolute time needs no timeline
//  refresh, so the provider reloads only when the app writes a new reading.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline

struct JinsulaEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> JinsulaEntry {
        JinsulaEntry(date: Date(), snapshot: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (JinsulaEntry) -> Void) {
        completion(JinsulaEntry(date: Date(), snapshot: WidgetSnapshotStore.read()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<JinsulaEntry>) -> Void) {
        // The snapshot only changes when the app writes a new reading and calls
        // reloadAllTimelines(); absolute time on the card needs no periodic
        // refresh, so a single never-expiring entry is enough.
        let entry = JinsulaEntry(date: Date(), snapshot: WidgetSnapshotStore.read())
        completion(Timeline(entries: [entry], policy: .never))
    }
}

// MARK: - View

struct JinsulaWidgetEntryView: View {
    var entry: Provider.Entry

    /// Neutral grey before any reading has been logged.
    private var colour: Color {
        entry.snapshot.map { Theme.colour(for: $0.severity) } ?? Color(.systemGray)
    }

    var body: some View {
        // iOS 17+ requires a declared container background to fill edge-to-edge;
        // iOS 15/16 fill the content area with a plain background.
        if #available(iOS 17.0, *) {
            content.containerBackground(colour, for: .widget)
        } else {
            content.background(colour)
        }
    }

    @ViewBuilder
    private var content: some View {
        if let snapshot = entry.snapshot {
            VStack(spacing: 6) {
                Text(formatted(snapshot.value))
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                Text(snapshot.unitLabel)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                Text(snapshot.date, style: .time)
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                Text("Tap to check")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .padding(.top, 2)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Text("Tap to check your sugar")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// mmol/L reads to one decimal (e.g. "5.4"); mg/dL is whole (e.g. "120").
    /// Trim a trailing ".0" so a whole reading shows cleanly.
    private func formatted(_ value: Double) -> String {
        value == value.rounded()
            ? String(Int(value))
            : String(format: "%.1f", value)
    }
}

// MARK: - Widget

struct JinsulaWidget: Widget {
    let kind: String = "JinsulaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            JinsulaWidgetEntryView(entry: entry)
                // Whole widget → fresh-entry deep link (same intent as a
                // notification tap). No per-element buttons on iOS 15.
                .widgetURL(URL(string: "jinsula://check"))
        }
        .configurationDisplayName("Jinsula")
        .description("Your last sugar reading. Tap to check again.")
        .supportedFamilies([.systemMedium])
    }
}
