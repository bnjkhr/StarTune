//
//  StarTuneApp.swift
//  StarTune
//
//  Created on 2025-10-24.
//

import MusicKit
import SwiftUI

@main
struct StarTuneApp: App {
    @StateObject private var musicKitManager = MusicKitManager()
    @StateObject private var playbackMonitor = PlaybackMonitor()
    @State private var hasLaunched = false

    init() {
        print("🚀 StarTune App launching...")
        // App als Menu Bar Only (kein Dock Icon)
        // Wird über Info.plist gesteuert: LSUIElement = true
    }

    var body: some Scene {
        // Menu Bar Only App - MenuBarExtra zeigt Icon an
        MenuBarExtra {
            MenuBarView(
                musicKitManager: musicKitManager,
                playbackMonitor: playbackMonitor
            )
            .onAppear {
                // Setup nur einmal beim ersten Appear
                if !hasLaunched {
                    hasLaunched = true
                    Task {
                        await setupApp()
                    }
                }
            }
        } label: {
            // Dynamisches Icon basierend auf Playback Status
            Image(systemName: "star.fill")
                .foregroundColor(playbackMonitor.isPlaying ? .yellow : .gray)
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - App Lifecycle

extension StarTuneApp {
    private func setupApp() async {
        print("⚙️ Setting up app...")

        // MusicKit Authorization beim Start
        await musicKitManager.requestAuthorization()

        print("🔐 Authorization status: \(musicKitManager.isAuthorized)")

        // Playback Monitoring IMMER starten (auch ohne Authorization)
        // Das AppleScript funktioniert auch ohne MusicKit
        await playbackMonitor.startMonitoring()

        print("✅ App setup complete")
    }
}
