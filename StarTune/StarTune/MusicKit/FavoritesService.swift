//
//  FavoritesService.swift
//  StarTune
//
//  Created on 2025-10-24.
//

import Foundation
import MusadoraKit
import MusicKit

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
            // Methode 1: Versuche MCatalog.favorite (empfohlene Methode)
            do {
                let success = try await MCatalog.favorite(song: song)
                if success {
                    // Update cache
                    favoritedSongs.insert(song.id)
                    unfavoritedSongs.remove(song.id)
                    print("✅ Successfully added '\(song.title)' to favorites (cached)")
                    return true
                } else {
                    print("⚠️ Favorite API returned false, trying rating method")
                }
            } catch {
                print("⚠️ Favorite API failed, trying rating method: \(error.localizedDescription)")
            }

            // Methode 2: Fallback - Versuche Rating zu setzen
            do {
                _ = try await MCatalog.addRating(for: song, rating: .like)
                // Update cache
                favoritedSongs.insert(song.id)
                unfavoritedSongs.remove(song.id)
                print("✅ Successfully added '\(song.title)' to favorites via rating (cached)")
                return true
            } catch {
                print("❌ Both favorite methods failed: \(error.localizedDescription)")
                throw FavoritesError.networkError
            }
        } catch {
            print("❌ Error adding to favorites: \(error.localizedDescription)")
            throw FavoritesError.networkError
        }
    }

    // MARK: - Check Favorite Status

    /// Prüft ob ein Song bereits favorisiert ist (mit Cache)
    /// - Parameter song: Der zu prüfende Song
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

        // Cache miss or expired - check rating from API
        do {
            let rating = try await MCatalog.getRating(for: song)
            let isFavorite = (rating.value == .like)

            // Update cache
            if isFavorite {
                favoritedSongs.insert(song.id)
                unfavoritedSongs.remove(song.id)
            } else {
                unfavoritedSongs.insert(song.id)
                favoritedSongs.remove(song.id)
            }
            if cacheTime == nil {
                cacheTime = Date()
            }

            print("🔍 Rating check for '\(song.title)': \(rating.value) (is favorite: \(isFavorite), cached)")
            return isFavorite
        } catch {
            // Fehler beim Abrufen = nicht favorisiert
            print("⚠️ Could not check rating for '\(song.title)': \(error.localizedDescription)")
            // Cache as unfavorited
            unfavoritedSongs.insert(song.id)
            if cacheTime == nil {
                cacheTime = Date()
            }
            return false
        }
    }

    // MARK: - Remove from Favorites

    /// Entfernt einen Song aus Favorites
    /// - Parameter song: Der Song der entfernt werden soll
    /// - Returns: true wenn erfolgreich
    func removeFromFavorites(song: Song) async throws -> Bool {
        print("Removing song from favorites: \(song.title)")

        do {
            // MusadoraKit hat keine unfavorite() Methode
            // Wir können nur das Rating entfernen
            _ = try await MCatalog.deleteRating(for: song)

            // Update cache
            favoritedSongs.remove(song.id)
            unfavoritedSongs.insert(song.id)
            print("✅ Successfully removed rating for '\(song.title)' (cached)")
            return true
        } catch {
            print("❌ Error removing from favorites: \(error.localizedDescription)")
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
