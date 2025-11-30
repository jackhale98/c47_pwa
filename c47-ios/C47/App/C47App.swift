// SPDX-License-Identifier: GPL-3.0-only
// C47App.swift
// C47 Calculator for iOS - Main App Entry Point

import SwiftUI

@main
struct C47App: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            CalculatorView()
                .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background:
            // App is going to background - save state
            C47Engine.shared.saveState(to: stateFileURL)
        case .active:
            // App became active
            break
        case .inactive:
            // App is transitioning
            break
        @unknown default:
            break
        }
    }

    private var stateFileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("c47_state.dat")
    }
}
