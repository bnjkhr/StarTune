//
//  MusicAppStatus.swift
//  StarTune
//
//  Utility for checking Music.app status without AppleScript
//  Uses NSWorkspace notifications for real-time app lifecycle tracking
//

import Foundation
import Combine
import AppKit

/// Observes Music.app launch/quit events without AppleScript
@MainActor
class MusicAppStatus: ObservableObject {
    @Published var isRunning = false
    @Published var isFrontmost = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Check initial state
        updateRunningState()

        // Observe workspace notifications for app lifecycle
        NSWorkspace.shared.notificationCenter.publisher(
            for: NSWorkspace.didLaunchApplicationNotification
        )
        .sink { [weak self] notification in
            self?.handleAppLaunched(notification)
        }
        .store(in: &cancellables)

        NSWorkspace.shared.notificationCenter.publisher(
            for: NSWorkspace.didTerminateApplicationNotification
        )
        .sink { [weak self] notification in
            self?.handleAppTerminated(notification)
        }
        .store(in: &cancellables)

        NSWorkspace.shared.notificationCenter.publisher(
            for: NSWorkspace.didActivateApplicationNotification
        )
        .sink { [weak self] notification in
            self?.handleAppActivated(notification)
        }
        .store(in: &cancellables)

        print("🔍 MusicAppStatus initialized - tracking Music.app lifecycle")
    }

    deinit {
        print("🧹 MusicAppStatus deallocated")
    }

    // MARK: - State Management

    private func updateRunningState() {
        isRunning = NSWorkspace.shared.runningApplications.contains { app in
            app.bundleIdentifier == "com.apple.Music"
        }
        print("🎵 Music.app initial state: \(isRunning ? "Running" : "Not running")")
    }

    // MARK: - Notification Handlers

    private func handleAppLaunched(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              app.bundleIdentifier == "com.apple.Music" else { return }

        isRunning = true
        print("▶️ Music.app launched")
    }

    private func handleAppTerminated(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              app.bundleIdentifier == "com.apple.Music" else { return }

        isRunning = false
        isFrontmost = false
        print("⏹️ Music.app terminated")
    }

    private func handleAppActivated(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }

        isFrontmost = app.bundleIdentifier == "com.apple.Music"
    }

    // MARK: - Public API

    /// Get Music.app instance (for programmatic control if needed)
    var musicAppInstance: NSRunningApplication? {
        NSWorkspace.shared.runningApplications.first { app in
            app.bundleIdentifier == "com.apple.Music"
        }
    }

    /// Activate Music.app (bring to front)
    func activateMusicApp() {
        musicAppInstance?.activate(options: .activateIgnoringOtherApps)
        print("🎵 Activating Music.app")
    }
}
