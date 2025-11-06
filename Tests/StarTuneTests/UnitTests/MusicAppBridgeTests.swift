//
//  MusicAppBridgeTests.swift
//  StarTuneTests
//
//  Unit tests for MockMusicAppBridge
//  FIX: Verifies violation #5 fix - setPaused properly clears track fields
//

import XCTest
@testable import StarTune

@MainActor
final class MusicAppBridgeTests: XCTestCase {

    var mockBridge: MockMusicAppBridge!

    override func setUp() {
        super.setUp()
        mockBridge = MockMusicAppBridge()
    }

    override func tearDown() {
        mockBridge = nil
        super.tearDown()
    }

    // MARK: - Playing State Tests

    func testSetPlaying() {
        // When: Setting playing state
        mockBridge.setPlaying(
            trackName: "Test Song",
            artist: "Test Artist",
            trackID: "12345"
        )

        // Then: Should have correct state
        XCTAssertTrue(mockBridge.isPlaying, "Should be playing")
        XCTAssertEqual(mockBridge.currentTrackName, "Test Song", "Should have track name")
        XCTAssertEqual(mockBridge.currentArtist, "Test Artist", "Should have artist")
        XCTAssertEqual(mockBridge.getCurrentTrackID(), "12345", "Should have track ID")
    }

    func testSetPlayingWithoutTrackID() {
        // When: Setting playing state without track ID
        mockBridge.setPlaying(
            trackName: "Test Song",
            artist: "Test Artist"
        )

        // Then: Should have correct state
        XCTAssertTrue(mockBridge.isPlaying, "Should be playing")
        XCTAssertEqual(mockBridge.currentTrackName, "Test Song", "Should have track name")
        XCTAssertEqual(mockBridge.currentArtist, "Test Artist", "Should have artist")
        XCTAssertNil(mockBridge.getCurrentTrackID(), "Should not have track ID")
    }

    // MARK: - Paused State Tests (Fix Verification)

    func testSetPaused_ClearsTrackFields() {
        // Given: Mock with playing track
        mockBridge.setPlaying(
            trackName: "Test Song",
            artist: "Test Artist",
            trackID: "12345"
        )
        XCTAssertTrue(mockBridge.isPlaying)
        XCTAssertNotNil(mockBridge.currentTrackName)

        // When: Setting paused state
        // FIX: This now properly clears track fields (addresses violation #5)
        mockBridge.setPaused()

        // Then: Should clear all track data
        XCTAssertFalse(mockBridge.isPlaying, "Should not be playing")
        XCTAssertNil(mockBridge.currentTrackName, "Should clear track name")
        XCTAssertNil(mockBridge.currentArtist, "Should clear artist")
        XCTAssertNil(mockBridge.getCurrentTrackID(), "Should clear track ID")
    }

    func testSetPaused_FromInitialState() {
        // Given: Fresh mock with no track
        XCTAssertNil(mockBridge.currentTrackName)

        // When: Setting paused (already no track)
        mockBridge.setPaused()

        // Then: Should remain in cleared state
        XCTAssertFalse(mockBridge.isPlaying, "Should not be playing")
        XCTAssertNil(mockBridge.currentTrackName, "Should have no track name")
        XCTAssertNil(mockBridge.currentArtist, "Should have no artist")
        XCTAssertNil(mockBridge.getCurrentTrackID(), "Should have no track ID")
    }

    // MARK: - Track Info Tests

    func testCurrentTrackInfo_WithBoth() {
        // Given: Mock with track and artist
        mockBridge.setPlaying(trackName: "Test Song", artist: "Test Artist")

        // When: Getting track info
        let info = mockBridge.currentTrackInfo

        // Then: Should have formatted info
        XCTAssertEqual(info, "Test Song - Test Artist", "Should format with both")
    }

    func testCurrentTrackInfo_TrackOnly() {
        // Given: Mock with only track name
        mockBridge.currentTrackName = "Test Song"
        mockBridge.currentArtist = nil

        // When: Getting track info
        let info = mockBridge.currentTrackInfo

        // Then: Should have track name only
        XCTAssertEqual(info, "Test Song", "Should return just track name")
    }

    func testCurrentTrackInfo_NoTrack() {
        // Given: Mock with no track
        mockBridge.reset()

        // When: Getting track info
        let info = mockBridge.currentTrackInfo

        // Then: Should return nil
        XCTAssertNil(info, "Should return nil when no track")
    }

    // MARK: - Reset Tests

    func testReset() {
        // Given: Mock with playing track
        mockBridge.setPlaying(
            trackName: "Test Song",
            artist: "Test Artist",
            trackID: "12345"
        )

        // When: Resetting
        mockBridge.reset()

        // Then: Should be in initial state
        XCTAssertNil(mockBridge.currentTrackName, "Should have no track name")
        XCTAssertNil(mockBridge.currentArtist, "Should have no artist")
        XCTAssertFalse(mockBridge.isPlaying, "Should not be playing")
        XCTAssertNil(mockBridge.getCurrentTrackID(), "Should have no track ID")
    }

    // MARK: - Update Playback State Tests

    func testUpdatePlaybackState() {
        // When: Calling updatePlaybackState (no-op in mock)
        mockBridge.updatePlaybackState()

        // Then: Should not crash or change state
        XCTAssertFalse(mockBridge.isPlaying, "State unchanged")
        XCTAssertNil(mockBridge.currentTrackName, "State unchanged")
    }
}
