//
//  SetupView.swift
//  Jinsula
//
//  Family-only configuration screen (bands, contacts, units). The rare screen
//  behind the lock — see SPEC.md "Setup screen — design plan".
//
//  Everything here edits a **working copy** of `AppSettings`; nothing reaches
//  the daily-use card until "Done" commits it through `AppModel.commitSettings`.
//  Band editing is a *projection* over the fixed five `GuidanceBand`s: family
//  tunes only the four interior thresholds and each band's `detail` text. Count,
//  severity, action, and headline are fixed — even here — because the headlines
//  carry the non-negotiable safety lines (SPEC.md §1, safety principles #2 & #5).
//

import SwiftUI

struct SetupView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    /// The working copy: edited freely, committed only on "Done".
    @State private var working: AppSettings
    @State private var showResetConfirm = false

    init(settings: AppSettings) {
        _working = State(initialValue: SetupView.normalised(settings))
    }

    /// Defensive: the boundary editor assumes exactly the five fixed bands. Any
    /// unexpected shape (e.g. an old JSON) falls back to the safe defaults.
    private static func normalised(_ settings: AppSettings) -> AppSettings {
        guard settings.bands.count == 5 else {
            var copy = settings
            copy.bands = GuidanceBand.defaultUKBands
            return copy
        }
        return settings
    }

    private static let thresholdFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 1
        return f
    }()

    var body: some View {
        NavigationView {
            Form {
                whoSection
                unitsSection
                thresholdsSection
                detailSection
                previewSection
                contactsSection
            }
            .navigationTitle("Setup")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        model.commitSettings(working)
                        dismiss()
                    }
                    .disabled(!thresholdsValid)
                }
            }
        }
        .navigationViewStyle(.stack)   // consistent full-width form on iPad
    }

    // MARK: - Who this is for

    private var whoSection: some View {
        Section("Who this is for") {
            TextField("Name (optional)", text: $working.userName)
        }
    }

    // MARK: - Units

    private var unitsSection: some View {
        Section {
            Picker("Units", selection: $working.unit) {
                ForEach(GlucoseUnit.allCases, id: \.self) { unit in
                    Text(unit.shortLabel).tag(unit)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Units")
        } footer: {
            Text("Match the units shown on the meter. Readings are used exactly as typed — the app never converts between units.")
        }
    }

    // MARK: - Reading thresholds (boundary editor)

    private var thresholdsSection: some View {
        Section {
            thresholdRow("Very low — below", index: 0)
            thresholdRow("Low — below", index: 1)
            thresholdRow("Okay — up to", index: 2)
            thresholdRow("High — up to", index: 3)

            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset to defaults", systemImage: "arrow.counterclockwise")
            }
        } header: {
            Text("Reading thresholds (\(working.unit.shortLabel))")
        } footer: {
            Text(thresholdsValid
                 ? "Below the first number is an emergency; above the last is very high."
                 : "Numbers must be positive and go from smallest to largest.")
                .foregroundColor(thresholdsValid ? .secondary : Theme.emergency)
        }
        .alert("Reset to defaults?", isPresented: $showResetConfirm) {
            Button("Reset", role: .destructive) {
                // Full safe default: bands AND unit (mmol/L). The unit switch
                // itself never converts numbers (SPEC.md §2) — reset is the one
                // control that puts both back to the guidance-grounded default.
                working.bands = GuidanceBand.defaultUKBands
                working.unit = AppSettings.default.unit
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This restores the standard UK units, thresholds and wording. It takes effect when you tap Done.")
        }
    }

    private func thresholdRow(_ label: String, index: Int) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("", value: thresholdBinding(index),
                      formatter: SetupView.thresholdFormatter)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
        }
    }

    /// Reads/writes boundary `index` (0…3). Writing sets it on **both** adjacent
    /// bands (band N's `upper` == band N+1's `lower`), so ranges stay contiguous
    /// by construction (SPEC.md §1).
    private func thresholdBinding(_ index: Int) -> Binding<Double> {
        Binding(
            get: { working.bands[index].upper ?? 0 },
            set: { newValue in
                working.bands[index].upper = newValue
                working.bands[index + 1].lower = newValue
            }
        )
    }

    // MARK: - Per-band wording (detail only; headlines are fixed)

    private var detailSection: some View {
        Section {
            ForEach(working.bands.indices, id: \.self) { i in
                VStack(alignment: .leading, spacing: 4) {
                    Text(working.bands[i].headline)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.colour(for: working.bands[i].severity))
                    TextField("Wording", text: $working.bands[i].detail)
                }
                .padding(.vertical, 2)
            }
        } header: {
            Text("What each band says")
        } footer: {
            Text("You can reword the supporting line. The bold headline is fixed for safety and never names an amount.")
        }
    }

    // MARK: - Live preview

    private var previewSection: some View {
        Section("Preview") {
            ForEach(working.bands.indices, id: \.self) { i in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.colour(for: working.bands[i].severity))
                        .frame(width: 20, height: 20)
                    Text(rangeText(for: i))
                        .font(.subheadline.monospacedDigit())
                        .frame(width: 120, alignment: .leading)
                    Text(working.bands[i].headline)
                        .font(.subheadline)
                        .lineLimit(2)
                }
            }
        }
    }

    private func rangeText(for index: Int) -> String {
        let band = working.bands[index]
        switch (band.lower, band.upper) {
        case (nil, let hi?):        return "below \(fmt(hi))"
        case (let lo?, nil):        return "\(fmt(lo)) and above"
        case (let lo?, let hi?):    return "\(fmt(lo))–\(fmt(hi))"
        default:                    return ""
        }
    }

    private func fmt(_ value: Double) -> String {
        SetupView.thresholdFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    // MARK: - Emergency contacts

    private var contactsSection: some View {
        Section {
            ForEach($working.contacts) { $contact in
                VStack(alignment: .leading, spacing: 4) {
                    if working.contacts.first?.id == contact.id {
                        Text("Primary — the Call button dials this person")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    TextField("Name", text: $contact.name)
                    TextField("Phone number", text: $contact.phoneNumber)
                        .keyboardType(.phonePad)
                }
                .padding(.vertical, 2)
            }
            .onDelete { working.contacts.remove(atOffsets: $0) }

            Button {
                working.contacts.append(EmergencyContact(name: "", phoneNumber: ""))
            } label: {
                Label("Add contact", systemImage: "plus")
            }
        } header: {
            Text("Emergency contacts")
        } footer: {
            if working.contacts.isEmpty {
                Text("Add at least one contact — without one, the emergency “Call” button can’t appear.")
                    .foregroundColor(Theme.emergency)
            } else {
                Text("The first contact is the one the daily “Call” button dials.")
            }
        }
    }

    // MARK: - Validation

    /// Thresholds must be positive and strictly increasing (SPEC.md §1).
    private var thresholdsValid: Bool {
        let t = (0..<4).map { working.bands[$0].upper ?? 0 }
        guard t.allSatisfy({ $0 > 0 }) else { return false }
        return zip(t, t.dropFirst()).allSatisfy { $0 < $1 }
    }
}

#if DEBUG
struct SetupView_Previews: PreviewProvider {
    static var previews: some View {
        SetupView(settings: .default)
            .environmentObject(AppModel())
    }
}
#endif
