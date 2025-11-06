//
//  MockMusicCatalog.swift
//  StarTuneTests
//
//  Mock implementation for MusadoraKit MCatalog operations
//

import Foundation
import MusicKit
import MusadoraKit

/// Mock catalog for testing favorites operations
class MockMusicCatalog {
    static var shouldSucceed = true
    static var errorToThrow: MusadoraKitError?
    static var addedRatings: [(song: Song, rating: MCatalog.Rating)] = []
    static var deletedRatings: [Song] = []

    /// Reset mock state between tests
    static func reset() {
        shouldSucceed = true
        errorToThrow = nil
        addedRatings.removeAll()
        deletedRatings.removeAll()
    }

    /// Mock implementation of MCatalog.addRating
    static func addRating(for song: Song, rating: MCatalog.Rating) async throws {
        if let error = errorToThrow {
            throw error
        }

        guard shouldSucceed else {
            throw MusadoraKitError.networkError
        }

        addedRatings.append((song: song, rating: rating))
    }

    /// Mock implementation of MCatalog.deleteRating
    static func deleteRating(for song: Song) async throws {
        if let error = errorToThrow {
            throw error
        }

        guard shouldSucceed else {
            throw MusadoraKitError.networkError
        }

        deletedRatings.append(song)
    }
}

/// Protocol for injectable favorites service
protocol FavoritesServiceProtocol {
    func addToFavorites(song: Song) async throws -> Bool
    func removeFromFavorites(song: Song) async throws -> Bool
    func isFavorited(song: Song) async throws -> Bool
    func getFavorites() async throws -> [Song]
}

/// Testable version of FavoritesService
class TestableFavoritesService: FavoritesServiceProtocol {
    var shouldSucceed = true
    var errorToThrow: FavoritesError?

    func addToFavorites(song: Song) async throws -> Bool {
        if let error = errorToThrow {
            throw error
        }
        return shouldSucceed
    }

    func removeFromFavorites(song: Song) async throws -> Bool {
        if let error = errorToThrow {
            throw error
        }
        return shouldSucceed
    }

    func isFavorited(song: Song) async throws -> Bool {
        return false
    }

    func getFavorites() async throws -> [Song] {
        return []
    }
}
