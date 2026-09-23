//
//  GlucoseDialView.swift
//  Jinsula
//
//  The daily-use input: a tall vertical dial grandma drags to pick a reading.
//  High values sit at the top, low at the bottom; a fixed pointer in the middle
//  marks the current pick. Each whole-number square is tinted by the band that
//  value falls in, so the dial *shows* the guidance as you scroll — but it never
//  computes anything: it only reports a `Double`. The bands stay the single
//  source of truth (colour comes from `BandEvaluator` + `Theme`, never from
//  thresholds branched here). See SPEC.md "Daily-use screen".
//

import SwiftUI

struct GlucoseDialView: View {
    /// The picked reading (one decimal place), driven by drag + nudge buttons.
    @Binding var value: Double
    /// The configured bands — used only to colour each square via `Theme`.
    let bands: [GuidanceBand]

    /// Plausible meter range for mmol/L (SPEC.md setup §2). The dial can never
    /// produce a value outside this, so the result screen always matches a band.
    private let range: ClosedRange<Double> = 1.0...33.3
    /// Vertical points per 1 mmol/L. Bigger = slower scroll, finer decimals.
    private let pointsPerUnit: CGFloat = 52
    /// Height of the visible window (only a few squares show at once).
    private let viewportHeight: CGFloat = 340
    /// Readings carry one decimal place.
    private let step = 0.1

    /// Value at drag start, so cumulative translation maps to an absolute value.
    @State private var dragAnchor: Double?

    /// Whole-number squares the dial draws (1…33 for the mmol/L range).
    private var integerTicks: [Int] {
        Array(Int(range.lowerBound.rounded(.up))...Int(range.upperBound.rounded(.down)))
    }

    var body: some View {
        HStack(spacing: 16) {
            dialWindow
            nudgeButtons
        }
        .frame(height: viewportHeight)
        // One adjustable element for VoiceOver: swipe up/down steps ±0.1.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Blood sugar reading")
        .accessibilityValue(String(format: "%.1f mmol per litre", value))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: nudge(+step)
            case .decrement: nudge(-step)
            @unknown default: break
            }
        }
    }

    // MARK: - Scrolling dial

    private var dialWindow: some View {
        GeometryReader { geo in
            let width = geo.size.width
            strip(width: width)
                // Shift the strip so the current value sits at the centre line.
                .offset(y: viewportHeight / 2 - yFromTop(value))
                // Top-anchor the tall strip inside the viewport window (a plain
                // ZStack would centre it and push every square off-screen).
                .frame(width: width, height: viewportHeight, alignment: .top)
                .contentShape(Rectangle())
                // Hard rounded edge — the reel fills the window, no fade-out.
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(Color(.separator), lineWidth: 1)
                )
                // Fixed selection lens frames the picked row (slot-reel style).
                .overlay(selectionLens(width: width))
                .gesture(dragGesture)
        }
    }

    /// The full coloured strip: one tinted square per whole number, labelled.
    private func strip(width: CGFloat) -> some View {
        ZStack(alignment: .top) {
            ForEach(integerTicks, id: \.self) { tick in
                square(for: tick, width: width)
            }
        }
        .frame(width: width, height: totalStripHeight, alignment: .top)
    }

    private func square(for tick: Int, width: CGFloat) -> some View {
        let colour = Theme.colour(for: severity(at: Double(tick)))
        // Signed distance (−1…1) of this square from the centre line, so it can
        // tilt like a slat on a spinning wheel (no opacity fade — the reel stays
        // solid to the rounded edge).
        let offsetFromCentre = (value - Double(tick)) * Double(pointsPerUnit)
        let normalised = max(-1, min(1, offsetFromCentre / Double(viewportHeight / 2)))
        let tilt = normalised * 55                 // degrees — barrel curvature
        return RoundedRectangle(cornerRadius: 12)
            .fill(colour)
            .frame(width: width - 12, height: pointsPerUnit - 4)
            .overlay(
                Text("\(tick)")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            )
            .rotation3DEffect(.degrees(tilt), axis: (x: 1, y: 0, z: 0), perspective: 0.6)
            // Position the square's centre at its value on the strip.
            .position(x: width / 2, y: yFromTop(Double(tick)))
    }

    /// A fixed capsule framing the centre row — the "selected" window of the
    /// reel. Border-only, so the picked square's colour still shows through.
    private func selectionLens(width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .strokeBorder(Color.primary, lineWidth: 3)
            .frame(width: width - 4, height: pointsPerUnit)
            .shadow(color: Color.black.opacity(0.25), radius: 3)
    }

    // MARK: - Nudge buttons (fine ±0.1 control, safer than drag alone)

    private var nudgeButtons: some View {
        VStack(spacing: 12) {
            nudgeButton("chevron.up", "Higher", by: step)
            nudgeButton("chevron.down", "Lower", by: -step)
        }
    }

    private func nudgeButton(_ symbol: String, _ label: String, by delta: Double) -> some View {
        Button {
            nudge(delta)
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 28, weight: .bold))
                .frame(width: 64, height: 64)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .foregroundColor(.primary)
        .accessibilityLabel(label)
    }

    // MARK: - Geometry

    private var totalStripHeight: CGFloat {
        CGFloat(range.upperBound - range.lowerBound) * pointsPerUnit
    }

    /// Distance (points) from the top of the strip to `v` — top = highest value.
    private func yFromTop(_ v: Double) -> CGFloat {
        CGFloat(range.upperBound - v) * pointsPerUnit
    }

    // MARK: - Interaction

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { g in
                let anchor = dragAnchor ?? value
                if dragAnchor == nil { dragAnchor = anchor }
                // Finger up (negative height) raises the value (top = high).
                set(anchor - Double(g.translation.height) / Double(pointsPerUnit))
            }
            .onEnded { _ in dragAnchor = nil }
    }

    private func nudge(_ delta: Double) {
        set(value + delta)
    }

    /// Clamp to range and snap to one decimal place.
    private func set(_ newValue: Double) {
        let clamped = min(max(newValue, range.lowerBound), range.upperBound)
        value = (clamped * 10).rounded() / 10
    }

    /// The severity of the band a value falls in, so the square can be coloured.
    /// Delegates to `BandEvaluator` — no thresholds are branched in the view.
    private func severity(at v: Double) -> GuidanceBand.Severity {
        BandEvaluator.band(for: v, in: bands)?.severity ?? .inRange
    }
}
