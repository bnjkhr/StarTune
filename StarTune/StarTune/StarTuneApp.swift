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
    
    // Track if setup has been initiated to avoid duplicate calls
    private var setupInProgress = false
    private var setupCompleted = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 App did finish launching")
        // Note: Setup will be triggered from MenuBarView.onAppear where StateObjects are guaranteed ready
    }
    
    /// Called from view's onAppear when StateObjects are ready
    func performSetupIfNeeded() {
        guard !setupInProgress, !setupCompleted else {
            print("⚠️ Setup already completed or in progress")
            return
        }
        
        setupInProgress = true
        print("🚀 Starting app setup...")
        
        Task { @MainActor in
            await self.setupApp()
            setupCompleted = true
            setupInProgress = false
        }
    }

    @MainActor
    private func setupApp() async {
        guard let musicKitManager = musicKitManager,
            let playbackMonitor = playbackMonitor
        else {
            print("❌ Cannot setup: managers not initialized")
            return
        }

        print("⚙️ Setting up app...")

        // MusicKit Authorization beim Start with error handling
        let authStatus = await musicKitManager.requestAuthorization()
        print("🔐 Authorization status: \(authStatus.description)")
        
        // Log detailed status for debugging
        switch authStatus {
        case .authorized:
            print("✅ MusicKit authorization granted")
            if musicKitManager.isAuthorized {
                print("✅ User has Apple Music subscription: \(musicKitManager.hasAppleMusicSubscription)")
            } else {
                print("⚠️ MusicKit authorized but subscription check failed")
            }
        case .denied:
            print("❌ MusicKit authorization denied by user")
            print("⚠️ App will function with limited features - user can authorize later via UI")
        case .restricted:
            print("⚠️ MusicKit authorization restricted (parental controls)")
            print("⚠️ App will function with limited features")
        case .notDetermined:
            print("⚠️ MusicKit authorization not determined (unexpected state after request)")
        @unknown default:
            print("⚠️ MusicKit authorization in unknown state")
        }

        // Playback Monitoring IMMER starten (auch ohne Authorization)
        // Das AppleScript funktioniert auch ohne MusicKit
        // Note: startMonitoring doesn't throw - all errors handled gracefully inside
        await playbackMonitor.startMonitoring()
        print("✅ Playback monitoring started")

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
        // Menu Bar Only App - MenuBarExtra zeigt Icon an
        MenuBarExtra {
            MenuBarView(
                musicKitManager: musicKitManager,
                playbackMonitor: playbackMonitor,
                appDelegate: appDelegate
            )
            .onAppear {
                // Pass managers to AppDelegate when view appears
                appDelegate.musicKitManager = musicKitManager
                appDelegate.playbackMonitor = playbackMonitor
            }
        } label: {
            // Dynamisches Icon basierend auf Playback Status
            Image(systemName: "star.fill")
                .foregroundColor(playbackMonitor.isPlaying ? .yellow : .gray)
        }
        .menuBarExtraStyle(.window)
    }
}
