//
//  PlaybackMonitorTests.swift
//  StarTuneTests
//
//  Unit tests for PlaybackMonitor using mocks (no live network calls)
//  FIX: Addresses violation #8 - no live MusicCatalogSearchRequest calls
//

import XCTest
import MusicKit
@testable import StarTune

@MainActor
final class PlaybackMonitorTests: XCTestCase {

    var mockPlaybackMonitor: MockPlaybackMonitor!
    var mockSong: Song!

    override func setUp() {
        super.setUp()
        mockPlaybackMonitor = MockPlaybackMonitor()
        // FIX: Using centralized TestHelpers instead of live network call (addresses violation #8)
        mockSong = TestHelpers.createMockSong(
            title: "Test Song",
            artistName: "Test Artist",
            albumTitle: "Test Album"
        )
    }

    override func tearDown() {
        mockPlaybackMonitor = nil
        mockSong = nil
        super.tearDown()
    }

    // MARK: - Monitoring Tests

    func testStartMonitoring() async {
        // Given: Fresh mock
        XCTAssertFalse(mockPlaybackMonitor.isMonitoring, "Should not be monitoring initially")

        // When: Starting monitoring
        await mockPlaybackMonitor.startMonitoring()

        // Then: Monitoring should be active
        XCTAssertTrue(mockPlaybackMonitor.isMonitoring, "Should be monitoring after start")
    }

    func testStopMonitoring() async {
        // Given: Mock that is monitoring
        await mockPlaybackMonitor.startMonitoring()
        XCTAssertTrue(mockPlaybackMonitor.isMonitoring)

        // When: Stopping monitoring
        mockPlaybackMonitor.stopMonitoring()

        // Then: Monitoring should be inactive
        XCTAssertFalse(mockPlaybackMonitor.isMonitoring, "Should not be monitoring after stop")
    }

    // MARK: - Playback State Tests

    func testSimulatePlaying() {
        // Given: Mock with a song
        let song = mockSong!

        // When: Simulating playing state
        mockPlaybackMonitor.simulatePlaying(song, time: 10.0)

        // Then: State should reflect playing
        XCTAssertTrue(mockPlaybackMonitor.isPlaying, "Should be playing")
        XCTAssertEqual(mockPlaybackMonitor.currentSong?.id, song.id, "Should have correct song")
        XCTAssertEqual(mockPlaybackMonitor.playbackTime, 10.0, "Should have correct time")
    }

    func testSimulatePaused() {
        // Given: Mock that is playing
        mockPlaybackMonitor.simulatePlaying(mockSong, time: 10.0)
        XCTAssertTrue(mockPlaybackMonitor.isPlaying)

        // When: Simulating paused state
        mockPlaybackMonitor.simulatePaused()

        // Then: Should be paused but song remains
        XCTAssertFalse(mockPlaybackMonitor.isPlaying, "Should not be playing")
        XCTAssertNotNil(mockPlaybackMonitor.currentSong, "Song should still be set")
    }

    func testSimulateStopped() {
        // Given: Mock that is playing
        mockPlaybackMonitor.simulatePlaying(mockSong, time: 10.0)

        // When: Simulating stopped state
        mockPlaybackMonitor.simulateStopped()

        // Then: Should be stopped with no song
        XCTAssertFalse(mockPlaybackMonitor.isPlaying, "Should not be playing")
        XCTAssertNil(mockPlaybackMonitor.currentSong, "Should have no song")
        XCTAssertEqual(mockPlaybackMonitor.playbackTime, 0.0, "Should have zero time")
    }

    // MARK: - Helper Property Tests

    func testCurrentSongInfo_WithSong() {
        // Given: Mock playing a song
        mockPlaybackMonitor.simulatePlaying(mockSong)

        // When: Getting song info
        let info = mockPlaybackMonitor.currentSongInfo

        // Then: Should return formatted info
        XCTAssertNotNil(info, "Should have song info")
        XCTAssertTrue(info!.contains("Test Song"), "Should contain song title")
        XCTAssertTrue(info!.contains("Test Artist"), "Should contain artist name")
    }

    func testCurrentSongInfo_NoSong() {
        // Given: Mock with no song
        mockPlaybackMonitor.reset()

        // When: Getting song info
        let info = mockPlaybackMonitor.currentSongInfo

        // Then: Should return nil
        XCTAssertNil(info, "Should have no song info")
    }

    func testHasSongPlaying_WhenPlaying() {
        // Given: Mock playing a song
        mockPlaybackMonitor.simulatePlaying(mockSong)

        // When: Checking if song is playing
        let hasPlaying = mockPlaybackMonitor.hasSongPlaying

        // Then: Should return true
        XCTAssertTrue(hasPlaying, "Should have song playing")
    }

    func testHasSongPlaying_WhenPaused() {
        // Given: Mock that is paused
        mockPlaybackMonitor.simulatePlaying(mockSong)
        mockPlaybackMonitor.simulatePaused()

        // When: Checking if song is playing
        let hasPlaying = mockPlaybackMonitor.hasSongPlaying

        // Then: Should return false (paused, not playing)
        XCTAssertFalse(hasPlaying, "Should not have song playing when paused")
    }

    func testHasSongPlaying_WhenStopped() {
        // Given: Mock that is stopped
        mockPlaybackMonitor.simulateStopped()

        // When: Checking if song is playing
        let hasPlaying = mockPlaybackMonitor.hasSongPlaying

        // Then: Should return false
        XCTAssertFalse(hasPlaying, "Should not have song playing when stopped")
    }

    // MARK: - Reset Tests

    func testReset() {
        // Given: Mock with active state
        mockPlaybackMonitor.simulatePlaying(mockSong, time: 10.0)
        await mockPlaybackMonitor.startMonitoring()

        // When: Resetting
        mockPlaybackMonitor.reset()

        // Then: Should be in initial state
        XCTAssertNil(mockPlaybackMonitor.currentSong, "Should have no song")
        XCTAssertFalse(mockPlaybackMonitor.isPlaying, "Should not be playing")
        XCTAssertEqual(mockPlaybackMonitor.playbackTime, 0.0, "Should have zero time")
        XCTAssertFalse(mockPlaybackMonitor.isMonitoring, "Should not be monitoring")
    }
}
