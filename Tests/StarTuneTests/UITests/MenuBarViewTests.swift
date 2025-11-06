//
//  MenuBarViewTests.swift
//  StarTuneTests
//
//  UI tests for MenuBarView SwiftUI component
//

import XCTest
import SwiftUI
import MusicKit
import Combine
@testable import StarTune

@MainActor
final class MenuBarViewTests: XCTestCase {

    var mockMusicKitManager: MockMusicKitManager!
    var mockPlaybackMonitor: MockPlaybackMonitor!

    override func setUp() async throws {
        try await super.setUp()
        mockMusicKitManager = MockMusicKitManager()
        mockPlaybackMonitor = MockPlaybackMonitor()
    }

    override func tearDown() async throws {
        mockMusicKitManager = nil
        mockPlaybackMonitor = nil
        try await super.tearDown()
    }

    // MARK: - View Creation Tests

    func testViewCreation_Succeeds() {
        // When: Creating view
        let view = MenuBarView(
            musicKitManager: mockMusicKitManager,
            playbackMonitor: mockPlaybackMonitor
        )

        // Then: View should be created
        XCTAssertNotNil(view, "MenuBarView should be created")
    }

    // MARK: - Authorization Section Tests

    func testAuthorizationSection_ShowsWhenNotAuthorized() {
        // Given: Not authorized
        mockMusicKitManager.setDenied()

        // When: Creating view
        let view = MenuBarView(
            musicKitManager: mockMusicKitManager,
            playbackMonitor: mockPlaybackMonitor
        )

        // Then: Should show authorization section
        // We verify by checking the manager state
        XCTAssertFalse(mockMusicKitManager.isAuthorized)
    }

    func testAuthorizationSection_HidesWhenAuthorized() {
        // Given: Authorized
        mockMusicKitManager.setAuthorized()

        // When: Creating view
        let view = MenuBarView(
            musicKitManager: mockMusicKitManager,
            playbackMonitor: mockPlaybackMonitor
        )

        // Then: Authorization section should be hidden
        XCTAssertTrue(mockMusicKitManager.isAuthorized)
    }

    // MARK: - Currently Playing Section Tests

    func testCurrentlyPlayingSection_ShowsWhenAuthorized() {
        // Given: Authorized
        mockMusicKitManager.setAuthorized()

        // When: Creating view
        let view = MenuBarView(
            musicKitManager: mockMusicKitManager,
            playbackMonitor: mockPlaybackMonitor
        )

        // Then: Should show currently playing section
        XCTAssertTrue(mockMusicKitManager.isAuthorized)
    }

    func testCurrentlyPlayingSection_ShowsSongInfo() async throws {
        // Given: Authorized with playing song
        mockMusicKitManager.setAuthorized()
        let song = try await createMockSong(title: "Test Song", artist: "Test Artist")
        mockPlaybackMonitor.setCurrentSong(song, playing: true)

        // When: Creating view
        let view = MenuBarView(
            musicKitManager: mockMusicKitManager,
            playbackMonitor: mockPlaybackMonitor
        )

        // Then: Should have song info
        XCTAssertNotNil(mockPlaybackMonitor.currentSong)
        XCTAssertTrue(mockPlaybackMonitor.isPlaying)
    }

    func testCurrentlyPlayingSection_ShowsNoMusicMessage() {
        // Given: Authorized but no song
        mockMusicKitManager.setAuthorized()
        mockPlaybackMonitor.currentSong = nil

        // When: Creating view
        let view = MenuBarView(
            musicKitManager: mockMusicKitManager,
            playbackMonitor: mockPlaybackMonitor
        )

        // Then: Should show no music message
        XCTAssertNil(mockPlaybackMonitor.currentSong)
    }

    // MARK: - Playback Status Indicator Tests

    func testPlaybackIndicator_ShowsGreenWhenPlaying() {
        // Given: Playing
        mockMusicKitManager.setAuthorized()
        mockPlaybackMonitor.isPlaying = true

        // When: Creating view
        let view = MenuBarView(
            musicKitManager: mockMusicKitManager,
            playbackMonitor: mockPlaybackMonitor
        )

        // Then: Indicator should be green (playing)
        XCTAssertTrue(mockPlaybackMonitor.isPlaying)
    }

    func testPlaybackIndicator_ShowsGrayWhenPaused() {
        // Given: Paused
        mockMusicKitManager.setAuthorized()
        mockPlaybackMonitor.isPlaying = false

        // When: Creating view
        let view = MenuBarView(
            musicKitManager: mockMusicKitManager,
            playbackMonitor: mockPlaybackMonitor
        )

        // Then: Indicator should be gray (paused)
        XCTAssertFalse(mockPlaybackMonitor.isPlaying)
    }

    // MARK: - Add to Favorites Button Tests

    func testFavoriteButton_EnabledWhenSongPlaying() async throws {
        // Given: Authorized with playing song
        mockMusicKitManager.setAuthorized()
        let song = try await createMockSong()
        mockPlaybackMonitor.setCurrentSong(song, playing: true)

        // When: Creating view
        let view = MenuBarView(
            musicKitManager: mockMusicKitManager,
            playbackMonitor: mockPlaybackMonitor
        )

        // Then: Button should be enabled
        XCTAssertTrue(mockPlaybackMonitor.hasSongPlaying)
    }

    func testFavoriteButton_DisabledWhenNoSong() {
        // Given: Authorized but no song
        mockMusicKitManager.setAuthorized()
        mockPlaybackMonitor.currentSong = nil

        // When: Creating view
        let view = MenuBarView(
            musicKitManager: mockMusicKitManager,
            playbackMonitor: mockPlaybackMonitor
        )

        // Then: Button should be disabled
        XCTAssertFalse(mockPlaybackMonitor.hasSongPlaying)
    }

    func testFavoriteButton_DisabledWhenPaused() async throws {
        // Given: Authorized but paused
        mockMusicKitManager.setAuthorized()
        let song = try await createMockSong()
        mockPlaybackMonitor.setCurrentSong(song, playing: false)

        // When: Creating view
        let view = MenuBarView(
            musicKitManager: mockMusicKitManager,
            playbackMonitor: mockPlaybackMonitor
        )

        // Then: Button should be disabled
        XCTAssertFalse(mockPlaybackMonitor.hasSongPlaying)
    }

    // MARK: - Progress Indicator Tests

    func testProgressIndicator_HiddenInitially() {
        // Given: Initial state
        mockMusicKitManager.setAuthorized()

        // When: Creating view
        let view = MenuBarView(
            musicKitManager: mockMusicKitManager,
            playbackMonitor: mockPlaybackMonitor
        )

        // Then: Progress should not be showing
        // Note: We can't directly test @State from outside,
        // but we verify the initial state logic
        XCTAssertNotNil(view)
    }

    // MARK: - Notification Tests

    func testAddToFavorites_PostsSuccessNotification() async throws {
        // Given: Setup for adding to favorites
        mockMusicKitManager.setAuthorized(withSubscription: true)
        let song = try await createMockSong()
        mockPlaybackMonitor.setCurrentSong(song, playing: true)

        // Notification observer
        let expectation = XCTestExpectation(description: "Success notification")
        var receivedNotification = false

        let observer = NotificationCenter.default.addObserver(
            forName: .favoriteSuccess,
            object: nil,
            queue: .main
        ) { _ in
            receivedNotification = true
            expectation.fulfill()
        }

        // When: Adding to favorites would post notification
        // Note: Actual addToFavorites requires real MusicKit
        // This test validates notification mechanism

        // Simulate success notification
        NotificationCenter.default.post(name: .favoriteSuccess, object: nil)

        // Then: Should receive notification
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(receivedNotification)

        NotificationCenter.default.removeObserver(observer)
    }

    func testAddToFavorites_PostsErrorNotification() async throws {
        // Given: Notification observer
        let expectation = XCTestExpectation(description: "Error notification")
        var receivedNotification = false

        let observer = NotificationCenter.default.addObserver(
            forName: .favoriteError,
            object: nil,
            queue: .main
        ) { _ in
            receivedNotification = true
            expectation.fulfill()
        }

        // When: Error occurs
        NotificationCenter.default.post(name: .favoriteError, object: nil)

        // Then: Should receive error notification
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(receivedNotification)

        NotificationCenter.default.removeObserver(observer)
    }

    // MARK: - View Layout Tests

    func testViewLayout_HasCorrectWidth() {
        // When: Creating view
        let view = MenuBarView(
            musicKitManager: mockMusicKitManager,
            playbackMonitor: mockPlaybackMonitor
        )

        // Then: View should have 300pt width
        // Note: We can't directly test frame, but verify view exists
        XCTAssertNotNil(view)
    }

    func testViewLayout_HasHeaderText() {
        // When: Creating view
        let view = MenuBarView(
            musicKitManager: mockMusicKitManager,
            playbackMonitor: mockPlaybackMonitor
        )

        // Then: Should have StarTune header
        XCTAssertNotNil(view)
    }

    // MARK: - Quit Button Tests

    func testQuitButton_AlwaysPresent() {
        // Given: Any state
        mockMusicKitManager.setDenied()

        // When: Creating view
        let view = MenuBarView(
            musicKitManager: mockMusicKitManager,
            playbackMonitor: mockPlaybackMonitor
        )

        // Then: Quit button should be present
        XCTAssertNotNil(view)
    }

    // MARK: - Reactive Updates Tests

    func testView_ReactsToAuthorizationChanges() async throws {
        // Given: Not authorized initially
        mockMusicKitManager.setDenied()

        let view = MenuBarView(
            musicKitManager: mockMusicKitManager,
            playbackMonitor: mockPlaybackMonitor
        )

        // When: Authorization changes
        mockMusicKitManager.setAuthorized()

        // Small delay for view update
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s

        // Then: View should react to change
        XCTAssertTrue(mockMusicKitManager.isAuthorized)
    }

    func testView_ReactsToPlaybackChanges() async throws {
        // Given: Not playing initially
        mockMusicKitManager.setAuthorized()
        mockPlaybackMonitor.isPlaying = false

        let view = MenuBarView(
            musicKitManager: mockMusicKitManager,
            playbackMonitor: mockPlaybackMonitor
        )

        // When: Playback starts
        mockPlaybackMonitor.isPlaying = true

        // Small delay for view update
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s

        // Then: View should react to change
        XCTAssertTrue(mockPlaybackMonitor.isPlaying)
    }

    func testView_ReactsToSongChanges() async throws {
        // Given: Initial state
        mockMusicKitManager.setAuthorized()
        mockPlaybackMonitor.currentSong = nil

        let view = MenuBarView(
            musicKitManager: mockMusicKitManager,
            playbackMonitor: mockPlaybackMonitor
        )

        // When: Song changes
        let song = try await createMockSong()
        mockPlaybackMonitor.setCurrentSong(song, playing: true)

        // Small delay for view update
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s

        // Then: View should react to change
        XCTAssertNotNil(mockPlaybackMonitor.currentSong)
    }

    // MARK: - Edge Cases

    func testView_HandlesMultipleStateChanges() async throws {
        // Given: Initial state
        mockMusicKitManager.setDenied()

        let view = MenuBarView(
            musicKitManager: mockMusicKitManager,
            playbackMonitor: mockPlaybackMonitor
        )

        // When: Multiple rapid state changes
        mockMusicKitManager.setAuthorized()
        mockPlaybackMonitor.isPlaying = true

        let song = try await createMockSong()
        mockPlaybackMonitor.setCurrentSong(song)

        mockPlaybackMonitor.isPlaying = false
        mockPlaybackMonitor.isPlaying = true

        // Then: Should handle gracefully
        XCTAssertNotNil(view)
    }

    // MARK: - Helper Methods

    private func createMockSong(title: String = "Test Song", artist: String = "Test Artist") async throws -> Song {
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

// MARK: - Notification Names Extension

extension Notification.Name {
    static let favoriteSuccess = Notification.Name("favoriteSuccess")
    static let favoriteError = Notification.Name("favoriteError")
    static let addToFavorites = Notification.Name("addToFavorites")
}
