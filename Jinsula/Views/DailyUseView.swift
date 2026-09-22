//
//  DailyUseView.swift
//  Jinsula
//
//  The screen grandma uses every day: type a reading on a big custom keypad,
//  tap one confirm button, and get one huge spoken colour card back.
//
//  This view is deliberately dumb: it holds only the typed string, reads the
//  unit/contacts from `AppModel`, and asks `AppModel.confirmReading(_:)` to
//  match the band. No thresholds or band copy live here. See SPEC.md
//  "Daily-use screen".
//

import SwiftUI

struct DailyUseView: View {
    @EnvironmentObject private var model: AppModel

    /// The only local state: the digits typed so far.
    @State private var entry = ""
    @State private var matchedBand: GuidanceBand?
    @State private var showingCard = false
    /// Shown when confirm is tapped on an implausible / unmatched value.
    @State private var showTryAgain = false
    /// Placeholder for the family-only setup door (real PIN gate: Session 4).
    @State private var showSettingsStub = false

    private var unit: GlucoseUnit { model.settings.unit }
    /// mmol/L readings carry one decimal place; mg/dL are integers only.
    private var allowsDecimal: Bool { unit == .mmolPerL }

    /// Meter-plausible input range for the current unit (SPEC.md setup §2).
    private var validRange: ClosedRange<Double> {
        allowsDecimal ? 1.0...33.3 : 20.0...600.0
    }

    /// The completed numeric value, or `nil` while entry is empty/incomplete.
    private var parsedValue: Double? {
        let cleaned = entry.hasSuffix(".") ? String(entry.dropLast()) : entry
        return Double(cleaned)
    }

    private var canConfirm: Bool {
        guard let v = parsedValue else { return false }
        return validRange.contains(v)
    }

    var body: some View {
        VStack(spacing: 24) {
            header
            valueDisplay
            if showTryAgain { tryAgainMessage }
            keypad
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
        // AND clear the field, then clear the flag (SPEC.md shared-hooks §0).
        .onChange(of: model.shouldStartFreshEntry) { fresh in
            guard fresh else { return }
            startFreshEntry()
            model.consumeFreshEntry()
        }
        .alert("Settings", isPresented: $showSettingsStub) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Settings are managed by your family.")
        }
    }

    // MARK: - Header (discreet family-only door)

    private var header: some View {
        HStack {
            Spacer()
            // Discreet ⋯ menu — the one sanctioned door to setup. The PIN gate
            // and setup screen itself are built in Session 4; reserved here.
            Menu {
                Button {
                    showSettingsStub = true   // TODO (Session 4): PIN pad → SetupView
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

    private var displayValue: String {
        entry.hasSuffix(".") ? String(entry.dropLast()) : entry
    }

    private var valueDisplay: some View {
        VStack(spacing: 4) {
            Text(entry.isEmpty ? "—" : entry)
                .font(Theme.reading())
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .foregroundColor(entry.isEmpty ? .secondary : .primary)
            Text(unit.shortLabel)
                .font(Theme.instruction(22))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var tryAgainMessage: some View {
        Text("That doesn't look right — please check and type it again.")
            .font(Theme.instruction(20))
            .multilineTextAlignment(.center)
            .foregroundColor(Theme.emergency)
    }

    // MARK: - Keypad

    private var keypad: some View {
        VStack(spacing: 12) {
            keyRow(["1", "2", "3"])
            keyRow(["4", "5", "6"])
            keyRow(["7", "8", "9"])
            HStack(spacing: 12) {
                decimalKey
                digitKey("0")
                backspaceKey
            }
        }
    }

    private func keyRow(_ digits: [String]) -> some View {
        HStack(spacing: 12) {
            ForEach(digits, id: \.self) { digitKey($0) }
        }
    }

    private func digitKey(_ digit: String) -> some View {
        keyButton(label: digit, accessibility: digit) { type(digit) }
    }

    @ViewBuilder
    private var decimalKey: some View {
        if allowsDecimal {
            keyButton(label: ".", accessibility: "point") { typeDecimal() }
        } else {
            // Integer-only unit: hold the grid slot but disable it.
            keyButton(label: "", accessibility: "") {}
                .opacity(0)
                .disabled(true)
        }
    }

    private var backspaceKey: some View {
        keyButton(label: "⌫", accessibility: "delete") { backspace() }
    }

    private func keyButton(label: String,
                           accessibility: String,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(Theme.reading(40))
                .frame(maxWidth: .infinity, minHeight: 72)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .foregroundColor(.primary)
        .accessibilityLabel(accessibility)
    }

    // MARK: - Confirm

    private var confirmButton: some View {
        Button(action: confirm) {
            Text("Show me my answer")
                .font(Theme.instruction(26))
                .frame(maxWidth: .infinity, minHeight: 72)
                .foregroundColor(.white)
                .background(canConfirm ? Theme.inRange : Color.gray)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(!canConfirm)
        .accessibilityLabel("Show me my answer")
    }

    // MARK: - Input handling

    private func type(_ digit: String) {
        showTryAgain = false
        // Cap decimals at one place (readings are always one d.p.).
        if let dot = entry.firstIndex(of: ".") {
            let afterDot = entry.distance(from: entry.index(after: dot), to: entry.endIndex)
            if afterDot >= 1 { return }
        }
        // Keep the string sane; bounds are enforced at confirm.
        guard entry.count < 5 else { return }
        entry.append(digit)
    }

    private func typeDecimal() {
        showTryAgain = false
        guard allowsDecimal, !entry.contains(".") else { return }
        entry.append(entry.isEmpty ? "0." : ".")
    }

    private func backspace() {
        showTryAgain = false
        if !entry.isEmpty { entry.removeLast() }
    }

    /// Explicit confirm only — never auto-submit on digit count (5.6 vs 15.6
    /// are one keypress apart). Fires `confirmReading` once; only a matched,
    /// in-range value shows the card.
    private func confirm() {
        guard let value = parsedValue, validRange.contains(value),
              let band = model.confirmReading(value) else {
            showTryAgain = true
            return
        }
        matchedBand = band
        showingCard = true
    }

    /// Reset to a blank entry and dismiss any card — used by Done and by the
    /// shared open-entry intent.
    private func startFreshEntry() {
        showingCard = false
        matchedBand = nil
        entry = ""
        showTryAgain = false
    }
}
