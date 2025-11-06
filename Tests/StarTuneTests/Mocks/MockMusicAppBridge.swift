//
//  MockMusicAppBridge.swift
//  StarTuneTests
//
//  Mock Music.app AppleScript bridge for testing
//

import Foundation
import MusicKit

/// Mock MusicAppBridge for testing AppleScript integration
@MainActor
class MockMusicAppBridge: ObservableObject {
    @Published var currentTrackName: String?
    @Published var currentArtist: String?
    @Published var isPlaying = false

    var updatePlaybackStateCalled = false
    var getCurrentTrackIDCalled = false

    // Configurable test data
    var mockTrackName: String?
    var mockArtist: String?
    var mockIsPlaying = false
    var mockTrackID: String?
    var shouldSimulateAppNotRunning = false
    var shouldSimulateScriptError = false

    func updatePlaybackState() {
        updatePlaybackStateCalled = true

        if shouldSimulateAppNotRunning {
            isPlaying = false
            currentTrackName = nil
            currentArtist = nil
            return
        }

        if shouldSimulateScriptError {
            isPlaying = false
            currentTrackName = nil
            currentArtist = nil
            return
        }

        isPlaying = mockIsPlaying
        currentTrackName = mockTrackName
        currentArtist = mockArtist
    }

    func getCurrentTrackID() -> String? {
        getCurrentTrackIDCalled = true

        if shouldSimulateAppNotRunning || shouldSimulateScriptError {
            return nil
        }

        return mockTrackID
    }

    var currentTrackInfo: String? {
        guard let name = currentTrackName else { return nil }
        if let artist = currentArtist {
            return "\(name) - \(artist)"
        }
        return name
    }

    /// Reset mock state
    func reset() {
        updatePlaybackStateCalled = false
        getCurrentTrackIDCalled = false
        mockTrackName = nil
        mockArtist = nil
        mockIsPlaying = false
        mockTrackID = nil
        shouldSimulateAppNotRunning = false
        shouldSimulateScriptError = false
        currentTrackName = nil
        currentArtist = nil
        isPlaying = false
    }

    /// Configure for playing state
    func setPlaying(trackName: String, artist: String, trackID: String? = nil) {
        mockTrackName = trackName
        mockArtist = artist
        mockIsPlaying = true
        mockTrackID = trackID
    }

    /// Configure for paused state
    func setPaused() {
        mockIsPlaying = false
    }
}
