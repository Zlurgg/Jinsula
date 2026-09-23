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

    /// The app delegate that receives notification taps. Wired to `model` on
    /// appear so the delegate can route a retest-nudge tap into `AppModel`.
    let appDelegate: AppDelegate

    var body: some View {
        DailyUseView()
            .onAppear { appDelegate.model = model }
            // Both open-entry sources land here: the widget deep link
            // (jinsula://check) and — via the app delegate — a notification tap.
            .onOpenURL { url in
                if url.scheme == "jinsula" {
                    model.shouldStartFreshEntry = true
                }
            }
    }
}

#Preview {
    ContentView(appDelegate: AppDelegate())
        .environmentObject(AppModel())
}
