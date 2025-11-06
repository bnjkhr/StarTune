//
//  MockMusicCatalog.swift
//  StarTuneTests
//
//  Mock implementation of music catalog operations for testing
//

import Foundation
import MusicKit
@testable import StarTune

/// Mock implementation of FavoritesService for testing
/// This mock properly handles error states and doesn't make network calls
class MockMusicCatalog {

    // MARK: - Configuration

    /// Error to throw when methods are called (for testing error paths)
    var errorToThrow: FavoritesError?

    /// Simulated favorite status for songs
    var favoritedSongs: Set<MusicItemID> = []

    /// Simulated list of all favorites
    var mockFavorites: [Song] = []

    // MARK: - Initialization

    init() {}

    // MARK: - Mock Methods

    /// Adds a song to favorites
    /// - Parameter song: The song to favorite
    /// - Returns: true if successful
    /// - Throws: FavoritesError if errorToThrow is set
    func addToFavorites(song: Song) async throws -> Bool {
        // Honor errorToThrow configuration
        if let error = errorToThrow {
            throw error
        }

        // Simulate successful add
        favoritedSongs.insert(song.id)
        if !mockFavorites.contains(where: { $0.id == song.id }) {
            mockFavorites.append(song)
        }
        return true
    }

    /// Checks if a song is favorited
    /// - Parameter song: The song to check
    /// - Returns: true if favorited
    /// - Throws: FavoritesError if errorToThrow is set
    func isFavorited(song: Song) async throws -> Bool {
        // FIX: Honor errorToThrow before returning (addresses violation #3)
        if let error = errorToThrow {
            throw error
        }

        // Return whether the song is in our favorites set
        return favoritedSongs.contains(song.id)
    }

    /// Removes a song from favorites
    /// - Parameter song: The song to remove
    /// - Returns: true if successful
    /// - Throws: FavoritesError if errorToThrow is set
    func removeFromFavorites(song: Song) async throws -> Bool {
        // Honor errorToThrow configuration
        if let error = errorToThrow {
            throw error
        }

        // Simulate successful removal
        favoritedSongs.remove(song.id)
        mockFavorites.removeAll { $0.id == song.id }
        return true
    }

    /// Gets all favorited songs
    /// - Returns: Array of favorited songs
    /// - Throws: FavoritesError if errorToThrow is set
    func getFavorites() async throws -> [Song] {
        // FIX: Honor errorToThrow before returning (addresses violation #4)
        if let error = errorToThrow {
            throw error
        }

        // Return the configured mock favorites
        return mockFavorites
    }

    // MARK: - Test Helpers

    /// Resets the mock to initial state
    func reset() {
        errorToThrow = nil
        favoritedSongs.removeAll()
        mockFavorites.removeAll()
    }

    /// Configures the mock to simulate a favorited song
    /// - Parameter song: The song to mark as favorited
    func simulateFavorited(_ song: Song) {
        favoritedSongs.insert(song.id)
        if !mockFavorites.contains(where: { $0.id == song.id }) {
            mockFavorites.append(song)
        }
    }

    /// Configures the mock to throw a specific error
    /// - Parameter error: The error to throw
    func simulateError(_ error: FavoritesError) {
        errorToThrow = error
    }
}
