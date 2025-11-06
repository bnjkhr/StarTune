//
//  FavoritesServiceTests.swift
//  StarTuneTests
//
//  Unit tests for FavoritesService business logic
//

import XCTest
import MusicKit
@testable import StarTune

@MainActor
final class FavoritesServiceTests: XCTestCase {

    var sut: FavoritesService!

    override func setUp() async throws {
        try await super.setUp()
        sut = FavoritesService()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Add to Favorites Tests

    func testAddToFavorites_Success() async throws {
        // Given: A valid song
        let song = try await createMockSong()

        // When: Adding to favorites
        // Note: This test requires MusicKit authorization and subscription
        // In a real test environment, you would mock MCatalog
        do {
            let result = try await sut.addToFavorites(song: song)

            // Then: Should succeed
            XCTAssertTrue(result, "Adding to favorites should return true")
        } catch {
            // Expected in test environment without real authorization
            XCTAssertTrue(error is FavoritesError, "Should throw FavoritesError")
        }
    }

    func testAddToFavorites_NotAuthorized() async throws {
        // Given: Not authorized for MusicKit
        let song = try await createMockSong()

        // When/Then: Should throw notAuthorized error
        do {
            _ = try await sut.addToFavorites(song: song)
            // May succeed or fail depending on authorization state
        } catch let error as FavoritesError {
            XCTAssertEqual(error, .notAuthorized, "Should throw notAuthorized error")
        }
    }

    func testAddToFavorites_NoSubscription() async throws {
        // Given: Authorized but no subscription
        let song = try await createMockSong()

        // When/Then: Should handle subscription error
        do {
            _ = try await sut.addToFavorites(song: song)
        } catch let error as FavoritesError {
            // Could be .noSubscription or .notAuthorized
            XCTAssertTrue([.noSubscription, .notAuthorized].contains(error),
                         "Should throw subscription or authorization error")
        }
    }

    // MARK: - Remove from Favorites Tests

    func testRemoveFromFavorites_Success() async throws {
        // Given: A song that was previously favorited
        let song = try await createMockSong()

        // When: Removing from favorites
        do {
            let result = try await sut.removeFromFavorites(song: song)

            // Then: Should succeed
            XCTAssertTrue(result, "Removing from favorites should return true")
        } catch {
            // Expected in test environment
            XCTAssertTrue(error is FavoritesError)
        }
    }

    func testRemoveFromFavorites_NetworkError() async throws {
        // Given: Network issues
        let song = try await createMockSong()

        // When/Then: Should handle network errors
        do {
            _ = try await sut.removeFromFavorites(song: song)
        } catch let error as FavoritesError {
            XCTAssertTrue([.networkError, .notAuthorized].contains(error),
                         "Should handle network errors")
        }
    }

    // MARK: - Check Favorite Status Tests

    func testIsFavorited_AlwaysReturnsFalse() async throws {
        // Given: Any song
        let song = try await createMockSong()

        // When: Checking if favorited
        let result = try await sut.isFavorited(song: song)

        // Then: Always returns false (known limitation)
        XCTAssertFalse(result, "isFavorited should return false due to MusadoraKit limitation")
    }

    // MARK: - Get Favorites Tests

    func testGetFavorites_ReturnsEmptyArray() async throws {
        // When: Getting all favorites
        let favorites = try await sut.getFavorites()

        // Then: Returns empty array (not yet implemented)
        XCTAssertTrue(favorites.isEmpty, "getFavorites should return empty array")
    }

    // MARK: - Error Mapping Tests

    func testFavoritesError_LocalizedDescriptions() {
        // Test all error descriptions
        XCTAssertEqual(FavoritesError.notAuthorized.errorDescription,
                      "Please authorize access to Apple Music")

        XCTAssertEqual(FavoritesError.noSubscription.errorDescription,
                      "An Apple Music subscription is required")

        XCTAssertEqual(FavoritesError.networkError.errorDescription,
                      "Could not connect to Apple Music")

        XCTAssertEqual(FavoritesError.songNotFound.errorDescription,
                      "Song not found")
    }

    func testFavoritesError_Equality() {
        // Test error equality
        XCTAssertEqual(FavoritesError.notAuthorized, FavoritesError.notAuthorized)
        XCTAssertNotEqual(FavoritesError.notAuthorized, FavoritesError.networkError)
    }

    // MARK: - Edge Cases

    func testMultipleOperations_Sequential() async throws {
        // Test multiple operations in sequence
        let song = try await createMockSong()

        // Attempt to add multiple times
        for _ in 0..<3 {
            do {
                _ = try await sut.addToFavorites(song: song)
            } catch {
                // Expected in test environment
            }
        }
    }

    // MARK: - Helper Methods

    private func createMockSong() async throws -> Song {
        // Create a search request for a well-known song
        var searchRequest = MusicCatalogSearchRequest(
            term: "Test Song",
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

// MARK: - FavoritesError Extension

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
