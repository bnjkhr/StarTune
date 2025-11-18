//
//  FavoritesService.swift
//  StarTune
//
//  Created on 2025-10-24.
//  Updated: 2025-11-06 - Added typed error handling with retry logic
//

import Foundation
import MusicKit
import MusadoraKit

/// Service für Favorites Management
class FavoritesService {

    // MARK: - Add to Favorites

    /// Fügt einen Song zu Favorites hinzu mit automatischer Retry-Logik
    /// - Parameter song: Der Song der favorisiert werden soll
    /// - Returns: true wenn erfolgreich, false bei Fehler
    func addToFavorites(song: Song) async throws -> Bool {
        print("Adding song to favorites: \(song.title)")

        // Use retry logic for network operations
        do {
            let result = try await RetryManager.shared.retryCritical(
                operationName: "addToFavorites"
            ) {
                // Apple Music verwendet Ratings für "Favoriten"
                // .like = Liked/Favorited, .dislike = Disliked
                try await MCatalog.addRating(for: song, rating: .like)
            }

            print("✅ Successfully added '\(song.title)' to favorites")

            // Record success for analytics
            await ErrorAnalytics.shared.recordResolution(
                FavoritesError.networkError,
                method: .automatic
            )

            return true
        } catch let error as MusadoraKitError {
            let appError = mapMusadoraKitError(error)
            print("❌ Error adding to favorites: \(appError.message)")

            // Record error for analytics
            recordError(
                appError,
                operation: "addToFavorites",
                userAction: "add_song_to_favorites"
            )

            throw appError
        } catch {
            let appError = AppError.from(error)
            print("❌ Error adding to favorites: \(appError.message)")

            // Record error for analytics
            recordError(
                appError,
                operation: "addToFavorites",
                userAction: "add_song_to_favorites"
            )

            throw appError
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

    /// Entfernt einen Song aus Favorites mit automatischer Retry-Logik
    /// - Parameter song: Der Song der entfernt werden soll
    /// - Returns: true wenn erfolgreich
    func removeFromFavorites(song: Song) async throws -> Bool {
        // Rating entfernen (unlove) mit Retry-Logik
        do {
            _ = try await RetryManager.shared.retryNetwork(
                operationName: "removeFromFavorites"
            ) {
                try await MCatalog.deleteRating(for: song)
            }

            print("✅ Successfully removed '\(song.title)' from favorites")
            return true
        } catch let error as MusadoraKitError {
            let appError = mapMusadoraKitError(error)
            recordError(
                appError,
                operation: "removeFromFavorites",
                userAction: "remove_song_from_favorites"
            )
            throw appError
        } catch {
            let appError = AppError.from(error)
            recordError(
                appError,
                operation: "removeFromFavorites",
                userAction: "remove_song_from_favorites"
            )
            throw appError
        }
    }

    // MARK: - Get All Favorites

    /// Lädt alle favorisierten Songs
    /// - Returns: Array von favorisierten Songs
    func getFavorites() async throws -> [Song] {
        // TODO: Implementierung für zukünftige Features
        return []
    }

    // MARK: - Error Mapping

    /// Maps MusadoraKitError to typed AppError with recovery suggestions
    private func mapMusadoraKitError(_ error: MusadoraKitError) -> AppError {
        switch error {
        case .notFound(let item):
            return .resourceError(.notFound(item))
        case .typeMissing:
            return .networkError(.requestFailed(error))
        case .recommendationOverLimit, .historyOverLimit:
            return .networkError(.requestFailed(error))
        }
    }
}

// MARK: - Legacy Error Handling (Deprecated)

/// Legacy error type - Use AppError instead
@available(*, deprecated, message: "Use AppError from ErrorHandling module instead")
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
