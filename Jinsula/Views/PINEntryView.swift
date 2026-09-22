//
//  PINEntryView.swift
//  Jinsula
//
//  The 4-digit PIN pad that guards the family setup screen (SPEC.md §5).
//  Two modes share one big, high-contrast keypad:
//    .unlock — verify the stored PIN before setup opens.
//    .set    — choose a new PIN, confirmed by re-entry.
//
//  `SetupGateView` (bottom of this file) is what the ⋯ menu actually presents:
//  it shows the PIN pad first when a PIN exists, then swaps to `SetupView`.
//  With no PIN set it opens setup directly (first-run — SPEC.md §5).
//

import SwiftUI

struct PINEntryView: View {
    enum Mode { case unlock, set }

    let mode: Mode
    /// Called once the PIN is verified (.unlock) or created (.set). In .set mode
    /// the view then dismisses itself; in .unlock the caller swaps the content.
    var onSuccess: () -> Void

    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    /// Digits typed so far in the current step.
    @State private var entry = ""
    /// First entry captured in .set mode, awaiting confirmation.
    @State private var firstEntry: String?
    @State private var message: String?
    @State private var isError = false

    private let pinLength = 4

    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Text(prompt)
                    .font(Theme.instruction(24))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)

                dots

                if let message = message {
                    Text(message)
                        .font(Theme.instruction(18))
                        .foregroundColor(isError ? Theme.emergency : .secondary)
                        .multilineTextAlignment(.center)
                }

                keypad
            }
            .padding(24)
            .frame(maxWidth: 400)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Copy

    private var title: String {
        mode == .unlock ? "Enter PIN" : "Set a PIN"
    }

    private var prompt: String {
        switch mode {
        case .unlock:
            return "Enter your PIN to open settings"
        case .set:
            return firstEntry == nil ? "Choose a 4-digit PIN" : "Enter the same PIN again"
        }
    }

    // MARK: - Dots

    private var dots: some View {
        HStack(spacing: 20) {
            ForEach(0..<pinLength, id: \.self) { index in
                Circle()
                    .strokeBorder(Color.secondary, lineWidth: 2)
                    .background(
                        Circle().fill(index < entry.count ? Color.primary : Color.clear)
                    )
                    .frame(width: 22, height: 22)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(entry.count) of \(pinLength) digits entered")
    }

    // MARK: - Keypad

    private var keypad: some View {
        VStack(spacing: 12) {
            keyRow(["1", "2", "3"])
            keyRow(["4", "5", "6"])
            keyRow(["7", "8", "9"])
            HStack(spacing: 12) {
                // Empty slot keeps the grid aligned (no decimal for a PIN).
                keyButton(label: "", accessibility: "") {}
                    .opacity(0)
                    .disabled(true)
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

    // MARK: - Input handling

    private func type(_ digit: String) {
        guard entry.count < pinLength else { return }
        isError = false
        entry.append(digit)
        if entry.count == pinLength { evaluate() }
    }

    private func backspace() {
        isError = false
        if !entry.isEmpty { entry.removeLast() }
    }

    /// Runs when the fourth digit lands.
    private func evaluate() {
        switch mode {
        case .unlock:
            if model.verifyPIN(entry) {
                onSuccess()
            } else {
                fail("That PIN isn't right. Try again.")
            }

        case .set:
            if let first = firstEntry {
                if entry == first {
                    model.setPIN(entry)
                    onSuccess()
                    dismiss()
                } else {
                    firstEntry = nil
                    fail("Those didn't match. Start again.")
                }
            } else {
                firstEntry = entry
                entry = ""
                message = nil
                isError = false
            }
        }
    }

    private func fail(_ text: String) {
        entry = ""
        message = text
        isError = true
    }
}

/// What the ⋯ → Settings menu presents. Gates `SetupView` behind the PIN pad
/// when a PIN exists; otherwise opens setup directly (first-run — SPEC.md §5).
struct SetupGateView: View {
    @EnvironmentObject private var model: AppModel
    @State private var unlocked = false

    var body: some View {
        if model.hasPIN && !unlocked {
            PINEntryView(mode: .unlock) { unlocked = true }
        } else {
            SetupView(settings: model.settings)
        }
    }
}

#if DEBUG
struct PINEntryView_Previews: PreviewProvider {
    static var previews: some View {
        PINEntryView(mode: .set) {}
            .environmentObject(AppModel())
    }
}
#endif
