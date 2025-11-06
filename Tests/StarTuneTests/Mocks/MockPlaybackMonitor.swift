//
//  MockPlaybackMonitor.swift
//  StarTuneTests
//
//  Mock implementation of PlaybackMonitor for testing (no network calls)
//

import Foundation
import MusicKit
import Combine
@testable import StarTune

/// Mock implementation of PlaybackMonitor that doesn't make network calls
/// FIX: Addresses violations #7 and #8 - no live MusicCatalogSearchRequest calls
@MainActor
class MockPlaybackMonitor: ObservableObject {

    // MARK: - Published Properties

    @Published var currentSong: Song?
    @Published var isPlaying = false
    @Published var playbackTime: TimeInterval = 0

    // MARK: - Mock State

    private var monitoringStarted = false

    // MARK: - Initialization

    init() {}

    // MARK: - Mock Methods

    /// Mock implementation of startMonitoring (no timer, no network)
    func startMonitoring() async {
        monitoringStarted = true
        // In tests, state is set directly
    }

    /// Mock implementation of stopMonitoring
    func stopMonitoring() {
        monitoringStarted = false
    }

    // MARK: - Public Helpers

    /// Formatted song info for display
    var currentSongInfo: String? {
        guard let song = currentSong else { return nil }
        return "\(song.title) - \(song.artistName)"
    }

    /// Checks if a song is currently playing
    var hasSongPlaying: Bool {
        return isPlaying && currentSong != nil
    }

    // MARK: - Test Helpers

    /// Simulates a song playing
    /// - Parameters:
    ///   - song: The mock song to play
    ///   - time: Optional playback time
    func simulatePlaying(_ song: Song, time: TimeInterval = 0) {
        self.currentSong = song
        self.isPlaying = true
        self.playbackTime = time
    }

    /// Simulates paused state
    func simulatePaused() {
        self.isPlaying = false
    }

    /// Simulates stopped state (no song)
    func simulateStopped() {
        self.currentSong = nil
        self.isPlaying = false
        self.playbackTime = 0
    }

    /// Resets the mock to initial state
    func reset() {
        currentSong = nil
        isPlaying = false
        playbackTime = 0
        monitoringStarted = false
    }

    /// Checks if monitoring has been started
    var isMonitoring: Bool {
        return monitoringStarted
    }
}
