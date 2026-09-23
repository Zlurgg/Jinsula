//
//  DailyUseView.swift
//  Jinsula
//
//  The screen grandma uses every day: drag a big colour dial to her reading,
//  tap one confirm button, and get one huge spoken colour card back.
//
//  This view is deliberately dumb: it holds only the picked value, reads the
//  bands/contacts from `AppModel`, and asks `AppModel.confirmReading(_:)` to
//  match the band. No thresholds or band copy live here. See SPEC.md
//  "Daily-use screen".
//

import SwiftUI

struct DailyUseView: View {
    @EnvironmentObject private var model: AppModel

    /// Neutral starting point for the dial (mid in-range).
    private static let startValue = 7.0

    /// The only local state: the value the dial currently points at.
    @State private var value = DailyUseView.startValue
    @State private var matchedBand: GuidanceBand?
    @State private var showingCard = false
    /// Shown if confirm somehow lands on an unmatched value (defensive only —
    /// the dial is clamped to the plausible range so this should never appear).
    @State private var showTryAgain = false
    /// Presents the family-only setup screen via `SetupGateView`, which shows the
    /// PIN pad first when a PIN is set (SPEC.md §5) and opens setup directly otherwise.
    @State private var showingSetup = false

    private var unit: GlucoseUnit { model.settings.unit }

    /// The picked value formatted to one decimal place (readings are one d.p.).
    private var displayValue: String {
        String(format: "%.1f", value)
    }

    var body: some View {
        VStack(spacing: 24) {
            header
            valueDisplay
            if showTryAgain { tryAgainMessage }
            GlucoseDialView(value: $value, bands: model.settings.bands)
            confirmButton
        }
        .padding(24)
        .frame(maxWidth: 500)                 // capped column so iPad isn't stretched
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .fullScreenCover(isPresented: $showingCard) {
            if let band = matchedBand {
                ResultCardView(band: band,
                               readingText: displayValue,
                               onDone: startFreshEntry)
                    .environmentObject(model)
            }
        }
        // Widget / notification taps ask for a blank screen: dismiss the card
        // AND reset the dial, then clear the flag (SPEC.md shared-hooks §0).
        .onChange(of: model.shouldStartFreshEntry) { fresh in
            guard fresh else { return }
            startFreshEntry()
            model.consumeFreshEntry()
        }
        .sheet(isPresented: $showingSetup) {
            SetupGateView()
                .environmentObject(model)
        }
    }

    // MARK: - Header (discreet family-only door)

    private var header: some View {
        HStack {
            Spacer()
            // Discreet ⋯ menu — the one sanctioned door to setup. `SetupGateView`
            // puts the PIN pad in front when a PIN is set (SPEC.md §5).
            Menu {
                Button {
                    showingSetup = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("More")
        }
    }

    // MARK: - Value display

    private var valueDisplay: some View {
        VStack(spacing: 4) {
            Text(displayValue)
                .font(Theme.reading())
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .foregroundColor(.primary)
            Text(unit.shortLabel)
                .font(Theme.instruction(22))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var tryAgainMessage: some View {
        Text("That doesn't look right — please check and try again.")
            .font(Theme.instruction(20))
            .multilineTextAlignment(.center)
            .foregroundColor(Theme.emergency)
    }

    // MARK: - Confirm

    private var confirmButton: some View {
        Button(action: confirm) {
            Text("Submit result")
                .font(Theme.instruction(26))
                .frame(maxWidth: .infinity, minHeight: 72)
                .foregroundColor(.white)
                .background(Theme.action)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .accessibilityLabel("Submit result")
    }

    // MARK: - Input handling

    /// Fires `confirmReading` once; only a matched value shows the card. The
    /// dial is clamped to the plausible range, so a match is expected — the
    /// `nil` path is defensive (a typo can no longer be typed).
    private func confirm() {
        guard let band = model.confirmReading(value) else {
            showTryAgain = true
            return
        }
        showTryAgain = false
        matchedBand = band
        showingCard = true
    }

    /// Reset to the neutral starting value and dismiss any card — used by Done
    /// and by the shared open-entry intent.
    private func startFreshEntry() {
        showingCard = false
        matchedBand = nil
        value = DailyUseView.startValue
        showTryAgain = false
    }
}
