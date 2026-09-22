//
//  ContentView.swift
//  Jinsula
//
//  Root view. For now it shows the daily-use screen directly; routing between
//  daily use / setup / history is added once those screens are built.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        DailyUseView()
            // Widget deep link (jinsula://check) → shared open-entry intent.
            // The notification-tap source is wired in Session 3.
            .onOpenURL { url in
                if url.scheme == "jinsula" {
                    model.shouldStartFreshEntry = true
                }
            }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppModel())
}
