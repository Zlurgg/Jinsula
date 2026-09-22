//
//  DailyUseView.swift
//  Jinsula
//
//  The screen grandma uses every day: enter a reading, get a big plain answer.
//  Skeleton placeholder — the large number pad and result card come in a later
//  session.
//

import SwiftUI

struct DailyUseView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 24) {
            Text("Enter your reading")
                .font(Theme.headline())
            Text("(coming soon)")
                .font(Theme.instruction())
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
