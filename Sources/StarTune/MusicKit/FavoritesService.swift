//
//  FavoritesService.swift
//  StarTune
//
//  Created on 2025-10-24.
//

import Foundation
import MusicKit
import MusadoraKit

/// Service für Favorites Management
/// Thread-safe via @MainActor isolation
@MainActor
class FavoritesService {
    // Shared singleton instance
    static let shared = FavoritesService()

    // Private init to enforce singleton pattern
    private init() {}

    // MARK: - Cache

    // Local cache for favorite status to avoid repeated network checks
    private var favoritedSongs: Set<MusicItemID> = []
    private var unfavoritedSongs: Set<MusicItemID> = []
    private var cacheTime: Date?
    private let cacheTTL: TimeInterval = 300 // 5 minutes cache

    // MARK: - Add to Favorites

    /// Fügt einen Song zu Favorites hinzu
    /// - Parameter song: Der Song der favorisiert werden soll
    /// - Returns: true wenn erfolgreich, false bei Fehler
    func addToFavorites(song: Song) async throws -> Bool {
        print("Adding song to favorites: \(song.title)")

        do {
            // Apple Music verwendet Ratings für "Favoriten"
            // .like = Liked/Favorited, .dislike = Disliked
            _ = try await MCatalog.addRating(for: song, rating: .like)

            // Update cache
            favoritedSongs.insert(song.id)
            unfavoritedSongs.remove(song.id)
            print("✅ Successfully added '\(song.title)' to favorites (cached)")
            return true
        } catch let error as MusadoraKitError {
            print("❌ Error adding to favorites: \(error.localizedDescription)")
            throw mapMusadoraKitError(error)
        } catch {
            print("❌ Error adding to favorites: \(error.localizedDescription)")
            throw FavoritesError.networkError
        }
    }

    // MARK: - Check Favorite Status

    /// Prüft ob ein Song bereits favorisiert ist (mit Cache)
    /// - Parameter song: Der zu prüfenden Song
    /// - Returns: true wenn favorisiert, false wenn nicht
    func isFavorited(song: Song) async throws -> Bool {
        // Check if cache is valid
        let cacheValid = cacheTime.map { Date().timeIntervalSince($0) < cacheTTL } ?? false

        // Check cache first
        if cacheValid {
            if favoritedSongs.contains(song.id) {
                print("✅ Cache hit: '\(song.title)' is favorited")
                return true
            }
            if unfavoritedSongs.contains(song.id) {
                print("✅ Cache hit: '\(song.title)' is not favorited")
                return false
            }
        }

        // Cache miss or expired - return false as default
        // MusadoraKit bietet keine "getRating" Methode
        // Wir können nur Ratings hinzufügen/löschen, nicht abfragen
        print("⚠️ Cache miss for '\(song.title)' - assuming not favorited")
        unfavoritedSongs.insert(song.id)
        if cacheTime == nil {
            cacheTime = Date()
        }
        return false
    }

    // MARK: - Remove from Favorites

    /// Entfernt einen Song aus Favorites
    /// - Parameter song: Der Song der entfernt werden soll
    /// - Returns: true wenn erfolgreich
    func removeFromFavorites(song: Song) async throws -> Bool {
        // Rating entfernen (unlove)
        do {
            _ = try await MCatalog.deleteRating(for: song)

            // Update cache
            favoritedSongs.remove(song.id)
            unfavoritedSongs.insert(song.id)
            print("✅ Successfully removed '\(song.title)' from favorites (cached)")
            return true
        } catch let error as MusadoraKitError {
            throw mapMusadoraKitError(error)
        } catch {
            throw FavoritesError.networkError
        }
    }

    // MARK: - Get All Favorites

    /// Lädt alle favorisierten Songs
    /// - Returns: Array von favorisierten Songs
    func getFavorites() async throws -> [Song] {
        // TODO: Implementierung für zukünftige Features
        return []
    }

    /// Invalidates the favorites cache
    func invalidateCache() {
        favoritedSongs.removeAll()
        unfavoritedSongs.removeAll()
        cacheTime = nil
        print("🔄 Favorites cache invalidated")
    }

    // MARK: - Error Mapping

    /// Maps MusadoraKitError to FavoritesError
    private func mapMusadoraKitError(_ error: MusadoraKitError) -> FavoritesError {
        // Note: MusadoraKit error types have changed in newer versions
        // For now, map all errors to network error for simplicity
        // Future improvement: inspect error message for more specific mapping
        let errorDescription = error.localizedDescription.lowercased()

        if errorDescription.contains("not authorized") || errorDescription.contains("authorization") {
            return .notAuthorized
        } else if errorDescription.contains("subscription") {
            return .noSubscription
        } else if errorDescription.contains("not found") {
            return .songNotFound
        } else {
            return .networkError
        }
    }
}

// MARK: - Error Handling

enum FavoritesError: LocalizedError {
    case notAuthorized
    case noSubscription
    case networkError
    case songNotFound

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Please authorize access to Apple Music"
        case .noSubscription:
            return "An Apple Music subscription is required"
        case .networkError:
            return "Could not connect to Apple Music"
        case .songNotFound:
            return "Song not found"
        }
    }
}
