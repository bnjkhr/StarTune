//
//  MockMusicAppBridge.swift
//  StarTuneTests
//
//  Mock implementation of MusicAppBridge for testing
//

import Foundation
@testable import StarTune

/// Mock implementation of MusicAppBridge that doesn't use AppleScript
@MainActor
class MockMusicAppBridge: ObservableObject {

    // MARK: - Published Properties

    @Published var currentTrackName: String?
    @Published var currentArtist: String?
    @Published var isPlaying = false

    // MARK: - Mock State

    private var mockTrackID: String?

    // MARK: - Initialization

    init() {}

    // MARK: - Mock Methods

    /// Updates the playback state (mock implementation)
    func updatePlaybackState() {
        // In tests, state is set directly via setPlaying/setPaused
        // This method is a no-op in the mock
    }

    /// Gets the current track ID (mock implementation)
    func getCurrentTrackID() -> String? {
        return mockTrackID
    }

    /// Formatted track info
    var currentTrackInfo: String? {
        guard let name = currentTrackName else { return nil }
        if let artist = currentArtist {
            return "\(name) - \(artist)"
        }
        return name
    }

    // MARK: - Test Helpers

    /// Simulates a playing state with track information
    /// - Parameters:
    ///   - trackName: Name of the track
    ///   - artist: Artist name
    ///   - trackID: Optional track ID
    func setPlaying(trackName: String, artist: String, trackID: String? = nil) {
        self.currentTrackName = trackName
        self.currentArtist = artist
        self.isPlaying = true
        self.mockTrackID = trackID
    }

    /// Simulates a paused state
    /// FIX: Properly clears track fields to mirror real MusicAppBridge behavior (addresses violation #5)
    func setPaused() {
        self.isPlaying = false
        // Clear track data when paused to match real behavior
        self.currentTrackName = nil
        self.currentArtist = nil
        self.mockTrackID = nil
    }

    /// Resets the mock to initial state
    func reset() {
        currentTrackName = nil
        currentArtist = nil
        isPlaying = false
        mockTrackID = nil
    }
}
