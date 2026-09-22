//
//  ContentView.swift
//  Jinsula
//
//  Root view. For now it shows the daily-use screen directly; routing between
//  daily use / setup / history is added once those screens are built.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        DailyUseView()
    }
}

#Preview {
    ContentView()
        .environmentObject(AppModel())
}
