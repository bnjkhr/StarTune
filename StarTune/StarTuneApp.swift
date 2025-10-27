//
//  StarTuneApp.swift
//  StarTune
//
//  Created on 2025-10-24.
//

import MusicKit
import SwiftUI

// AppDelegate für Lifecycle Management
class AppDelegate: NSObject, NSApplicationDelegate {
    var musicKitManager: MusicKitManager?
    var playbackMonitor: PlaybackMonitor?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 App did finish launching - starting setup...")

        // Setup async starten
        Task { @MainActor in
            // Kurze Verzögerung damit StateObjects initialisiert sind
            try? await Task.sleep(nanoseconds: 200_000_000)  // 0.2 Sekunden
            await self.setupApp()
        }
    }

    private func setupApp() async {
        guard let musicKitManager = musicKitManager,
            let playbackMonitor = playbackMonitor
        else {
            print("❌ Cannot setup: managers not initialized")
            return
        }

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

@main
struct StarTuneApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var musicKitManager = MusicKitManager()
    @StateObject private var playbackMonitor = PlaybackMonitor()

    init() {
        print("🏗️ StarTune App initializing...")
        // App als Menu Bar Only (kein Dock Icon)
        // Wird über Info.plist gesteuert: LSUIElement = true
    }

    var body: some Scene {
        // Managers an AppDelegate übergeben
        let _ = {
            appDelegate.musicKitManager = musicKitManager
            appDelegate.playbackMonitor = playbackMonitor
        }()

        // Menu Bar Only App - MenuBarExtra zeigt Icon an
        return MenuBarExtra {
            MenuBarView(
                musicKitManager: musicKitManager,
                playbackMonitor: playbackMonitor
            )
        } label: {
            // Dynamisches Icon basierend auf Playback Status
            Image(systemName: "star.fill")
                .foregroundColor(playbackMonitor.isPlaying ? .yellow : .gray)
        }
        .menuBarExtraStyle(.window)
    }
}
