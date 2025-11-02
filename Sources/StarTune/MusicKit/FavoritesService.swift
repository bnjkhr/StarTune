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
class FavoritesService {

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

            print("✅ Successfully added '\(song.title)' to favorites")
            return true
        } catch {
            print("❌ Error adding to favorites: \(error.localizedDescription)")
            throw FavoritesError.networkError
        }
    }

    // MARK: - Check Favorite Status

    /// Prüft ob ein Song bereits favorisiert ist
    /// - Parameter song: Der zu prüfende Song
    /// - Returns: true wenn favorisiert, false wenn nicht
    func isFavorited(song: Song) async throws -> Bool {
        // MusadoraKit bietet keine "getRating" Methode
        // Wir können nur Ratings hinzufügen/löschen, nicht abfragen
        // Für v1 ignorieren wir das und fügen einfach immer hinzu
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
            return true
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
