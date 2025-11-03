//
//  StarTuneApp.swift
//  StarTune
//
//  Created on 2025-10-24.
//

import SwiftUI
import MusicKit

@main
struct StarTuneApp: App {
    @StateObject private var musicKitManager = MusicKitManager()
    @StateObject private var playbackMonitor = PlaybackMonitor()
    @State private var hasSetupApp = false

    init() {
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
                // App Setup beim ersten Öffnen (nur einmal)
                guard !hasSetupApp else { return }
                hasSetupApp = true

                Task {
                    await setupApp()
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
        // MusicKit Authorization beim Start
        await musicKitManager.requestAuthorization()

        // Playback Monitoring starten wenn autorisiert
        if musicKitManager.isAuthorized {
            await playbackMonitor.startMonitoring()
        }
    }
}
