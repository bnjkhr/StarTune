//
//  MockPlaybackMonitor.swift
//  StarTuneTests
//
//  Mock playback monitoring for testing
//

import Foundation
import MusicKit
import Combine

/// Mock PlaybackMonitor for testing
@MainActor
class MockPlaybackMonitor: ObservableObject {
    @Published var currentSong: Song?
    @Published var isPlaying = false
    @Published var playbackTime: TimeInterval = 0

    var startMonitoringCalled = false
    var stopMonitoringCalled = false

    func startMonitoring() async {
        startMonitoringCalled = true
    }

    func stopMonitoring() {
        stopMonitoringCalled = true
    }

    var currentSongInfo: String? {
        guard let song = currentSong else { return nil }
        return "\(song.title) - \(song.artistName)"
    }

    var hasSongPlaying: Bool {
        return isPlaying && currentSong != nil
    }

    /// Reset mock state
    func reset() {
        currentSong = nil
        isPlaying = false
        playbackTime = 0
        startMonitoringCalled = false
        stopMonitoringCalled = false
    }

    /// Configure with a mock song
    func setCurrentSong(_ song: Song, playing: Bool = true) {
        currentSong = song
        isPlaying = playing
    }
}
