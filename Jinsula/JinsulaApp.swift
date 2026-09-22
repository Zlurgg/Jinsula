//
//  JinsulaApp.swift
//  Jinsula
//
//  Created by Joseph Brightman on 22/09/2026.
//

import SwiftUI

@main
struct JinsulaApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
        }
    }
}
