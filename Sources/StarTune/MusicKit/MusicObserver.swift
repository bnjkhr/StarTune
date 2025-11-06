//
//  MusicObserver.swift
//  StarTune
//
//  Event-driven Music.app observer using NSDistributedNotificationCenter
//  Replaces timer-based polling with real-time notifications
//

import Foundation
import Combine
import MusicKit

/// Observes Music.app playback via distributed notifications (no polling!)
@MainActor
class MusicObserver: ObservableObject {
    @Published var currentTrack: TrackInfo?
    @Published var isPlaying = false
    @Published var playbackTime: TimeInterval = 0

    // Combine cancellables for memory management
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Track Info

    struct TrackInfo: Equatable {
        let name: String
        let artist: String
        let album: String?
        let persistentID: String?
        let duration: TimeInterval?

        var displayString: String {
            "\(name) - \(artist)"
        }
    }

    // MARK: - Lifecycle

    init() {
        setupNotificationObservers()
    }

    deinit {
        // Automatically cleaned up by cancellables Set
        print("🧹 MusicObserver deallocated - observers removed")
    }

    // MARK: - Setup

    private func setupNotificationObservers() {
        // Observe Music.app distributed notifications
        // This fires ONLY when playback state changes - no polling!
        DistributedNotificationCenter.default().publisher(
            for: NSNotification.Name("com.apple.Music.playerInfo"),
            object: nil
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] notification in
            self?.handlePlayerInfoNotification(notification)
        }
        .store(in: &cancellables)

        // Also observe legacy iTunes notification for backwards compatibility
        DistributedNotificationCenter.default().publisher(
            for: NSNotification.Name("com.apple.iTunes.playerInfo"),
            object: nil
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] notification in
            self?.handlePlayerInfoNotification(notification)
        }
        .store(in: &cancellables)

        print("🎵 MusicObserver initialized - listening for Music.app events")

        // Request initial state
        requestCurrentState()
    }

    // MARK: - Notification Handling

    private func handlePlayerInfoNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: Any] else {
            print("⚠️ Music.app notification received but no userInfo")
            return
        }

        // Extract player state
        // Keys: https://github.com/joshklein/itunes-mac-api/blob/master/iTunes%20API.md
        let playerState = userInfo["Player State"] as? String
        let wasPlaying = isPlaying
        isPlaying = (playerState == "Playing")

        if wasPlaying != isPlaying {
            print("🎵 Playback state changed: \(isPlaying ? "Playing" : "Stopped")")
        }

        // Extract track info
        if isPlaying {
            let name = userInfo["Name"] as? String ?? ""
            let artist = userInfo["Artist"] as? String ?? ""
            let album = userInfo["Album"] as? String
            let persistentID = userInfo["PersistentID"] as? String

            // Duration might be in milliseconds
            var duration: TimeInterval?
            if let totalTime = userInfo["Total Time"] as? Double {
                duration = totalTime / 1000.0 // Convert ms to seconds
            }

            let trackInfo = TrackInfo(
                name: name,
                artist: artist,
                album: album,
                persistentID: persistentID,
                duration: duration
            )

            // Only update if track actually changed (prevents unnecessary UI updates)
            if currentTrack != trackInfo {
                currentTrack = trackInfo
                print("🎵 Track changed: \(trackInfo.displayString)")
            }
        } else {
            currentTrack = nil
        }

        // Update playback position if available
        if let position = userInfo["Playback Position"] as? Double {
            playbackTime = position
        }
    }

    // MARK: - Initial State

    private func requestCurrentState() {
        // Note: Music.app doesn't respond to requests, so we just wait for the next notification
        // The first notification will arrive when playback state changes
        print("⏳ Waiting for Music.app playback events...")
    }
}
