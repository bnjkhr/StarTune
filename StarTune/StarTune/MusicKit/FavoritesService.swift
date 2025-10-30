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
class FavoritesService {

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
                    print("✅ Successfully added '\(song.title)' to favorites")
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
                print("✅ Successfully added '\(song.title)' to favorites via rating")
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

    /// Prüft ob ein Song bereits favorisiert ist
    /// - Parameter song: Der zu prüfende Song
    /// - Returns: true wenn favorisiert, false wenn nicht
    func isFavorited(song: Song) async throws -> Bool {
        // MusadoraKit hat keine isFavorite() Methode
        // Wir können nur das Rating prüfen als Näherungswert
        do {
            let rating = try await MCatalog.getRating(for: song)
            let isFavorite = (rating.value == .like)
            print("🔍 Rating check for '\(song.title)': \(rating.value) (is favorite: \(isFavorite))")
            return isFavorite
        } catch {
            // Fehler beim Abrufen = nicht favorisiert
            print("⚠️ Could not check rating for '\(song.title)': \(error.localizedDescription)")
            // Wir geben false zurück, damit der Button korrekt angezeigt wird
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
            print("✅ Successfully removed rating for '\(song.title)'")
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
