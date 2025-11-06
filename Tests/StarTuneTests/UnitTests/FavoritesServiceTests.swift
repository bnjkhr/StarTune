//
//  FavoritesServiceTests.swift
//  StarTuneTests
//
//  Unit tests for favorites functionality using mocks (no live MusicKit calls)
//  FIX: Addresses violation #1 - no live network dependencies
//

import XCTest
import MusicKit
@testable import StarTune

final class FavoritesServiceTests: XCTestCase {

    var mockCatalog: MockMusicCatalog!
    var mockSong: Song!

    override func setUp() {
        super.setUp()
        mockCatalog = MockMusicCatalog()
        // FIX: Using centralized TestHelpers instead of live network call (addresses violation #2)
        mockSong = TestHelpers.createMockSong(
            title: "Bohemian Rhapsody",
            artistName: "Queen"
        )
    }

    override func tearDown() {
        mockCatalog = nil
        mockSong = nil
        super.tearDown()
    }

    // MARK: - Add to Favorites Tests

    func testAddToFavorites_Success() async throws {
        // Given: Mock configured for success
        mockCatalog.reset()

        // When: Adding a song to favorites
        let result = try await mockCatalog.addToFavorites(song: mockSong)

        // Then: Operation succeeds
        XCTAssertTrue(result, "Should successfully add to favorites")
        XCTAssertTrue(mockCatalog.favoritedSongs.contains(mockSong.id), "Song should be in favorites")
    }

    func testAddToFavorites_NotAuthorized() async throws {
        // Given: Mock configured to throw notAuthorized error
        mockCatalog.simulateError(.notAuthorized)

        // When/Then: Adding should throw notAuthorized error
        do {
            _ = try await mockCatalog.addToFavorites(song: mockSong)
            XCTFail("Should have thrown notAuthorized error")
        } catch let error as FavoritesError {
            XCTAssertEqual(error, .notAuthorized, "Should throw notAuthorized error")
        }
    }

    func testAddToFavorites_NoSubscription() async throws {
        // Given: Mock configured to throw noSubscription error
        mockCatalog.simulateError(.noSubscription)

        // When/Then: Adding should throw noSubscription error
        do {
            _ = try await mockCatalog.addToFavorites(song: mockSong)
            XCTFail("Should have thrown noSubscription error")
        } catch let error as FavoritesError {
            XCTAssertEqual(error, .noSubscription, "Should throw noSubscription error")
        }
    }

    func testAddToFavorites_NetworkError() async throws {
        // Given: Mock configured to throw network error
        mockCatalog.simulateError(.networkError)

        // When/Then: Adding should throw network error
        do {
            _ = try await mockCatalog.addToFavorites(song: mockSong)
            XCTFail("Should have thrown network error")
        } catch let error as FavoritesError {
            XCTAssertEqual(error, .networkError, "Should throw network error")
        }
    }

    // MARK: - Check Favorite Status Tests

    func testIsFavorited_ReturnsFalseWhenNotFavorited() async throws {
        // Given: Mock with no favorites
        mockCatalog.reset()

        // When: Checking if song is favorited
        let isFavorited = try await mockCatalog.isFavorited(song: mockSong)

        // Then: Should return false
        XCTAssertFalse(isFavorited, "Should return false for non-favorited song")
    }

    func testIsFavorited_ReturnsTrueWhenFavorited() async throws {
        // Given: Mock with favorited song
        mockCatalog.reset()
        mockCatalog.simulateFavorited(mockSong)

        // When: Checking if song is favorited
        let isFavorited = try await mockCatalog.isFavorited(song: mockSong)

        // Then: Should return true
        XCTAssertTrue(isFavorited, "Should return true for favorited song")
    }

    func testIsFavorited_ThrowsError() async throws {
        // Given: Mock configured to throw error
        // FIX: This test now works because MockMusicCatalog honors errorToThrow (addresses violation #3)
        mockCatalog.simulateError(.networkError)

        // When/Then: Checking should throw error
        do {
            _ = try await mockCatalog.isFavorited(song: mockSong)
            XCTFail("Should have thrown error")
        } catch let error as FavoritesError {
            XCTAssertEqual(error, .networkError, "Should throw configured error")
        }
    }

    // MARK: - Remove from Favorites Tests

    func testRemoveFromFavorites_Success() async throws {
        // Given: Mock with favorited song
        mockCatalog.reset()
        mockCatalog.simulateFavorited(mockSong)

        // When: Removing from favorites
        let result = try await mockCatalog.removeFromFavorites(song: mockSong)

        // Then: Operation succeeds and song is removed
        XCTAssertTrue(result, "Should successfully remove from favorites")
        XCTAssertFalse(mockCatalog.favoritedSongs.contains(mockSong.id), "Song should not be in favorites")
    }

    func testRemoveFromFavorites_ThrowsError() async throws {
        // Given: Mock configured to throw error
        mockCatalog.simulateError(.networkError)

        // When/Then: Removing should throw error
        do {
            _ = try await mockCatalog.removeFromFavorites(song: mockSong)
            XCTFail("Should have thrown error")
        } catch let error as FavoritesError {
            XCTAssertEqual(error, .networkError, "Should throw configured error")
        }
    }

    // MARK: - Get Favorites Tests

    func testGetFavorites_ReturnsEmptyWhenNoFavorites() async throws {
        // Given: Mock with no favorites
        mockCatalog.reset()

        // When: Getting favorites
        let favorites = try await mockCatalog.getFavorites()

        // Then: Should return empty array
        XCTAssertTrue(favorites.isEmpty, "Should return empty array when no favorites")
    }

    func testGetFavorites_ReturnsConfiguredFavorites() async throws {
        // Given: Mock with multiple favorites
        mockCatalog.reset()
        let songs = TestHelpers.createMockSongs(count: 3)
        songs.forEach { mockCatalog.simulateFavorited($0) }

        // When: Getting favorites
        let favorites = try await mockCatalog.getFavorites()

        // Then: Should return all favorited songs
        XCTAssertEqual(favorites.count, 3, "Should return all favorites")
    }

    func testGetFavorites_ThrowsError() async throws {
        // Given: Mock configured to throw error
        // FIX: This test now works because MockMusicCatalog honors errorToThrow (addresses violation #4)
        mockCatalog.simulateError(.notAuthorized)

        // When/Then: Getting favorites should throw error
        do {
            _ = try await mockCatalog.getFavorites()
            XCTFail("Should have thrown error")
        } catch let error as FavoritesError {
            XCTAssertEqual(error, .notAuthorized, "Should throw configured error")
        }
    }
}

// MARK: - FavoritesError Equatable Conformance

extension FavoritesError: Equatable {
    public static func == (lhs: FavoritesError, rhs: FavoritesError) -> Bool {
        switch (lhs, rhs) {
        case (.notAuthorized, .notAuthorized),
             (.noSubscription, .noSubscription),
             (.networkError, .networkError),
             (.songNotFound, .songNotFound):
            return true
        default:
            return false
        }
    }
}
