//
//  ResultCardView.swift
//  Jinsula
//
//  Full-screen colour card that shows the matched band's guidance and speaks it
//  aloud. Renders ENTIRELY from the matched `GuidanceBand` — no band logic and
//  no thresholds live here, so adding or editing a band never touches this view.
//  See SPEC.md "Daily-use screen §2".
//

import SwiftUI

struct ResultCardView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.openURL) private var openURL

    /// The matched band — the single source of colour, copy, and action.
    let band: GuidanceBand
    /// Echo of the value the card responded to, e.g. "5.6".
    let readingText: String
    /// The one obvious way out (also fired after the action button runs).
    let onDone: () -> Void

    @State private var speech = SpeechService()

    var body: some View {
        ZStack {
            Theme.colour(for: band.severity)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                // 1. Small echo so she can see what the card responded to.
                Text("Your reading: \(readingText)")
                    .font(Theme.instruction(22))
                    .opacity(0.9)

                Spacer(minLength: 0)

                // 2. The loud line.
                Text(band.headline)
                    .font(Theme.headline())
                    .minimumScaleFactor(0.5)

                // 3. Supporting directional detail (never amounts — principle #5).
                Text(band.detail)
                    .font(Theme.instruction())
                    .minimumScaleFactor(0.5)

                Spacer(minLength: 0)

                actionButton
                readItAgainButton
                doneButton
            }
            .multilineTextAlignment(.center)
            .foregroundColor(.white)
            .padding(28)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        // Tapping anywhere on the card body repeats the guidance.
        .contentShape(Rectangle())
        .onTapGesture { speakGuidance() }
        .onAppear { speakGuidance() }
        .onDisappear { speech.stop() }
    }

    // MARK: - Action button (driven only by `band.action`)

    @ViewBuilder
    private var actionButton: some View {
        switch band.action {
        case .none:
            EmptyView()

        case .retestTimer:
            cardButton(title: "Remind me in 15 minutes", filled: true) {
                model.scheduleRetestReminder()
                dismiss()
            }

        case .callContact:
            // Hide the button entirely if no contact is configured — no dead
            // button (SPEC.md open question). The headline/detail still stand.
            if let contact = model.settings.contacts.first {
                cardButton(title: "Call \(contact.name)", filled: true) {
                    call(contact)
                }
            }
        }
    }

    private var readItAgainButton: some View {
        cardButton(title: "🔊  Read it again", filled: false) {
            speakGuidance()
        }
    }

    private var doneButton: some View {
        cardButton(title: "Done", filled: false) {
            dismiss()
        }
    }

    // MARK: - Helpers

    /// A big high-contrast button: filled = white fill + band-coloured label
    /// (the primary/loud action); otherwise a white-outlined transparent button.
    private func cardButton(title: String,
                            filled: Bool,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Theme.instruction(26))
                .frame(maxWidth: .infinity, minHeight: 72)
                .foregroundColor(filled ? Theme.colour(for: band.severity) : .white)
                .background(filled ? Color.white : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white, lineWidth: filled ? 0 : 3)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func speakGuidance() {
        speech.speak(headline: band.headline, detail: band.detail)
    }

    private func dismiss() {
        speech.stop()
        onDone()
    }

    private func call(_ contact: EmergencyContact) {
        let digits = contact.phoneNumber.filter { $0.isNumber || $0 == "+" }
        if let url = URL(string: "tel://\(digits)") {
            openURL(url)
        }
    }
}

#if DEBUG
private final class PreviewSettingsStore: SettingsStoring {
    let settings: AppSettings
    init(_ settings: AppSettings) { self.settings = settings }
    func load() -> AppSettings { settings }
    func save(_ settings: AppSettings) {}
}

@MainActor
private func previewModel(withContact: Bool) -> AppModel {
    var settings = AppSettings.default
    if withContact {
        settings.contacts = [EmergencyContact(name: "Sarah", phoneNumber: "07700900123")]
    }
    return AppModel(settingsStore: PreviewSettingsStore(settings))
}

private let previewBands = GuidanceBand.defaultUKBands

#Preview("Low (orange)") {
    ResultCardView(band: previewBands[1], readingText: "3.5", onDone: {})
        .environmentObject(previewModel(withContact: false))
}

#Preview("Emergency very low") {
    ResultCardView(band: previewBands[0], readingText: "2.4", onDone: {})
        .environmentObject(previewModel(withContact: true))
}

#Preview("High (amber contrast)") {
    ResultCardView(band: previewBands[3], readingText: "12.0", onDone: {})
        .environmentObject(previewModel(withContact: false))
}

#Preview("In range (green)") {
    ResultCardView(band: previewBands[2], readingText: "6.5", onDone: {})
        .environmentObject(previewModel(withContact: false))
}
#endif
