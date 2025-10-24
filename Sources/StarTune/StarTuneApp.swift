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
    @StateObject private var menuBarController = MenuBarController()

    init() {
        // App als Menu Bar Only (kein Dock Icon)
        // Wird über Info.plist gesteuert: LSUIElement = true
    }

    var body: some Scene {
        // Menu Bar Only App - kein Window nötig
        MenuBarExtra("StarTune", systemImage: "star.fill") {
            MenuBarView(
                musicKitManager: musicKitManager,
                playbackMonitor: playbackMonitor
            )
        }
        .menuBarExtraStyle(.window)
        .onChange(of: playbackMonitor.isPlaying) { _, newValue in
            menuBarController.updateIcon(isPlaying: newValue)
        }
    }
}

// MARK: - App Lifecycle

extension StarTuneApp {
    private func setupApp() {
        Task {
            // MusicKit Authorization beim Start
            await musicKitManager.requestAuthorization()

            // Playback Monitoring starten wenn autorisiert
            if musicKitManager.isAuthorized {
                await playbackMonitor.startMonitoring()
            }
        }
    }
}
