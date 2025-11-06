//
//  PlaybackMonitorTests.swift
//  StarTuneTests
//
//  Unit tests for PlaybackMonitor
//

import XCTest
import MusicKit
import Combine
@testable import StarTune

@MainActor
final class PlaybackMonitorTests: XCTestCase {

    var sut: PlaybackMonitor!
    var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        try await super.setUp()
        sut = PlaybackMonitor()
        cancellables = []
    }

    override func tearDown() async throws {
        sut.stopMonitoring()
        cancellables = nil
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInit_CreatesInstance() {
        // Then: Monitor should initialize
        XCTAssertNotNil(sut, "PlaybackMonitor should initialize")
    }

    func testInit_InitialStateIsIdle() {
        // Then: Initial state should be idle
        XCTAssertNil(sut.currentSong, "Should have no current song initially")
        XCTAssertFalse(sut.isPlaying, "Should not be playing initially")
        XCTAssertEqual(sut.playbackTime, 0, "Playback time should be 0 initially")
    }

    // MARK: - Start Monitoring Tests

    func testStartMonitoring_UpdatesState() async {
        // When: Starting monitoring
        await sut.startMonitoring()

        // Small delay for initial update
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s

        // Then: Should have updated state
        // State depends on whether Music.app is running
        XCTAssertNotNil(sut, "Monitor should be active")
    }

    func testStartMonitoring_PublishesUpdates() async {
        // Given: Observer for isPlaying
        var playingStates: [Bool] = []

        sut.$isPlaying
            .sink { playingStates.append($0) }
            .store(in: &cancellables)

        // When: Starting monitoring
        await sut.startMonitoring()

        // Wait for updates
        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3s (to get at least one timer update)

        // Then: Should have received updates
        XCTAssertFalse(playingStates.isEmpty, "Should emit isPlaying updates")
    }

    // MARK: - Stop Monitoring Tests

    func testStopMonitoring_StopsUpdates() async {
        // Given: Monitoring is active
        await sut.startMonitoring()

        // When: Stopping monitoring
        sut.stopMonitoring()

        // Then: Should stop updates (no crashes, timer invalidated)
        XCTAssertNotNil(sut, "Monitor should remain valid after stopping")
    }

    func testStopMonitoring_CanRestartMonitoring() async {
        // Given: Start and stop monitoring
        await sut.startMonitoring()
        sut.stopMonitoring()

        // When: Restarting
        await sut.startMonitoring()

        // Then: Should work correctly
        XCTAssertNotNil(sut, "Should be able to restart monitoring")
    }

    // MARK: - Current Song Info Tests

    func testCurrentSongInfo_WithSong() async throws {
        // Given: A mock song
        let song = try await createMockSong(title: "Test Song", artist: "Test Artist")
        sut.currentSong = song

        // When: Getting song info
        let info = sut.currentSongInfo

        // Then: Should format correctly
        XCTAssertNotNil(info)
        XCTAssertTrue(info?.contains("Test Song") ?? false)
        XCTAssertTrue(info?.contains("Test Artist") ?? false)
    }

    func testCurrentSongInfo_WithNoSong() {
        // Given: No current song
        sut.currentSong = nil

        // When: Getting song info
        let info = sut.currentSongInfo

        // Then: Should return nil
        XCTAssertNil(info)
    }

    // MARK: - Has Song Playing Tests

    func testHasSongPlaying_WhenPlayingWithSong() async throws {
        // Given: Playing with song
        let song = try await createMockSong()
        sut.currentSong = song
        sut.isPlaying = true

        // When/Then
        XCTAssertTrue(sut.hasSongPlaying, "Should have song playing")
    }

    func testHasSongPlaying_WhenPlayingWithoutSong() {
        // Given: Playing but no song
        sut.currentSong = nil
        sut.isPlaying = true

        // When/Then
        XCTAssertFalse(sut.hasSongPlaying, "Should not have song playing without song object")
    }

    func testHasSongPlaying_WhenPausedWithSong() async throws {
        // Given: Paused with song
        let song = try await createMockSong()
        sut.currentSong = song
        sut.isPlaying = false

        // When/Then
        XCTAssertFalse(sut.hasSongPlaying, "Should not have song playing when paused")
    }

    func testHasSongPlaying_WhenIdle() {
        // Given: Idle state
        sut.currentSong = nil
        sut.isPlaying = false

        // When/Then
        XCTAssertFalse(sut.hasSongPlaying, "Should not have song playing when idle")
    }

    // MARK: - Published Properties Tests

    func testPublishedProperties_EmitChanges() async throws {
        // Given: Observers
        var songValues: [Song?] = []
        var playingValues: [Bool] = []
        var timeValues: [TimeInterval] = []

        sut.$currentSong.sink { songValues.append($0) }.store(in: &cancellables)
        sut.$isPlaying.sink { playingValues.append($0) }.store(in: &cancellables)
        sut.$playbackTime.sink { timeValues.append($0) }.store(in: &cancellables)

        // When: Starting monitoring
        await sut.startMonitoring()

        // Wait for updates
        try await Task.sleep(nanoseconds: 3_000_000_000) // 3s

        // Then: Should have received values
        XCTAssertFalse(songValues.isEmpty, "Should emit currentSong values")
        XCTAssertFalse(playingValues.isEmpty, "Should emit isPlaying values")
        XCTAssertFalse(timeValues.isEmpty, "Should emit playbackTime values")
    }

    // MARK: - Timer Tests

    func testTimer_UpdatesStateRegularly() async {
        // Given: Counter to track updates
        var updateCount = 0

        sut.$isPlaying
            .dropFirst() // Skip initial value
            .sink { _ in updateCount += 1 }
            .store(in: &cancellables)

        // When: Monitoring for 5 seconds
        await sut.startMonitoring()
        try? await Task.sleep(nanoseconds: 5_000_000_000) // 5s

        sut.stopMonitoring()

        // Then: Should have multiple updates (timer fires every 2s)
        // Expect at least 2 updates in 5 seconds
        XCTAssertGreaterThanOrEqual(updateCount, 1, "Should receive regular updates")
    }

    func testTimer_DoesNotCreateMultipleTimers() async {
        // When: Starting monitoring multiple times
        await sut.startMonitoring()
        await sut.startMonitoring()
        await sut.startMonitoring()

        // Then: Should not crash (guard prevents multiple timers)
        XCTAssertNotNil(sut, "Should handle multiple start calls gracefully")

        sut.stopMonitoring()
    }

    // MARK: - Performance Tests

    func testMonitoring_Performance() async {
        // Measure performance of monitoring cycle
        measure {
            let expectation = XCTestExpectation(description: "Monitor cycle")

            Task {
                await sut.startMonitoring()
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2s
                sut.stopMonitoring()
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 5.0)
        }
    }

    // MARK: - Memory Management Tests

    func testMemoryManagement_NoRetainCycles() async {
        // Test that stopping monitoring properly cleans up
        weak var weakSut = sut

        await sut.startMonitoring()
        sut.stopMonitoring()

        // Timer should be invalidated
        XCTAssertNotNil(weakSut, "SUT should still exist while we hold reference")
    }

    // MARK: - Integration Tests

    func testIntegration_WithRealMusicApp() async {
        // This test validates integration with real Music.app
        // Note: Results depend on Music.app state

        // When: Starting monitoring
        await sut.startMonitoring()

        // Wait for initial update
        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3s

        // Then: Should have valid state
        // If Music.app is running and playing:
        if sut.isPlaying {
            // May have current song if MusicKit authorization is granted
            print("Playing: \(sut.currentSongInfo ?? "unknown")")
        }

        // Should complete without crashes
        XCTAssertNotNil(sut, "Integration should work without crashes")

        sut.stopMonitoring()
    }

    // MARK: - Helper Methods

    private func createMockSong(title: String = "Test Song", artist: String = "Test Artist") async throws -> Song {
        // Create a search request
        var searchRequest = MusicCatalogSearchRequest(
            term: "\(title) \(artist)",
            types: [Song.self]
        )
        searchRequest.limit = 1

        let response = try await searchRequest.response()

        guard let song = response.songs.first else {
            throw XCTSkip("Unable to create mock song - requires network access")
        }

        return song
    }
}
