//
//  ResultCardView.swift
//  Jinsula
//
//  Full-screen colour card that shows the matched band's guidance and speaks it
//  aloud. Skeleton placeholder.
//

import SwiftUI

struct ResultCardView: View {
    let band: GuidanceBand

    var body: some View {
        VStack(spacing: 20) {
            Text(band.headline)
                .font(Theme.headline())
                .multilineTextAlignment(.center)
            Text(band.detail)
                .font(Theme.instruction())
                .multilineTextAlignment(.center)
        }
        .foregroundColor(.white)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.colour(for: band.severity))
    }
}
