//
//  FavoritesService.swift
//  StarTune
//
//  Created on 2025-10-24.
//

import Foundation
import MusicKit
import MusadoraKit

/// Service for managing Apple Music favorites through the MusadoraKit wrapper.
///
/// `FavoritesService` provides a high-level API for adding and removing songs from
/// the user's Apple Music favorites (heart/like status). It uses MusadoraKit, a
/// community wrapper around MusicKit, to simplify the ratings API.
///
/// ## Overview
///
/// Apple Music uses a "rating" system for favorites:
/// - **Liked (`.like`)**: Song is favorited/hearted
/// - **Disliked (`.dislike`)**: Song is thumbs-downed (not used in this app)
/// - **No rating**: Song has no preference set
///
/// ## Architecture
///
/// ```
/// MenuBarView (User clicks "Add to Favorites")
///     ↓
/// FavoritesService.addToFavorites(song:)
///     ↓
/// MusadoraKit MCatalog.addRating(for:rating:)
///     ↓
/// Apple Music API (network request)
///     ↓
/// Success → Returns true
/// Error → Throws FavoritesError
/// ```
///
/// ## Requirements
///
/// Before calling any method in this service, ensure:
/// 1. User has authorized MusicKit (``MusicKitManager/isAuthorized``)
/// 2. User has an active Apple Music subscription (``MusicKitManager/hasAppleMusicSubscription``)
/// 3. Device has internet connectivity
/// 4. The song is from the Apple Music catalog (not a local file)
///
/// ## Error Handling
///
/// All methods throw ``FavoritesError`` which provides user-friendly, localized
/// error messages. The service maps MusadoraKit-specific errors to app-specific errors.
///
/// ## Limitations
///
/// - **No query support**: MusadoraKit doesn't provide a way to check if a song
///   is already favorited (see ``isFavorited(song:)``)
/// - **Catalog songs only**: Local songs in Music.app cannot be favorited
/// - **Network required**: All operations require an active internet connection
/// - **Rate limits**: Apple Music API has rate limits (unlikely to hit in normal use)
///
/// ## Usage Example
///
/// ```swift
/// let service = FavoritesService()
/// let song: Song = ... // From PlaybackMonitor
///
/// do {
///     let success = try await service.addToFavorites(song: song)
///     if success {
///         print("Added to favorites!")
///     }
/// } catch let error as FavoritesError {
///     print("Error: \(error.errorDescription ?? "Unknown")")
/// }
/// ```
///
/// ## Dependencies
///
/// - **MusicKit**: Apple's framework for Apple Music integration
/// - **MusadoraKit 4.0+**: Community wrapper that simplifies MusicKit APIs
///
/// - SeeAlso:
///   - ``MusicKitManager`` for authorization and subscription management
///   - ``PlaybackMonitor`` for obtaining `Song` objects
class FavoritesService {

    // MARK: - Public Methods

    /// Adds a song to the user's Apple Music favorites.
    ///
    /// This method marks the song as "liked" (hearted) in Apple Music, which adds
    /// it to the user's favorites and influences personalized recommendations.
    ///
    /// ## Behavior
    ///
    /// - Makes a network request to Apple Music API via MusadoraKit
    /// - The song must be from the Apple Music catalog (has a valid catalog ID)
    /// - If already favorited, the operation is idempotent (no error)
    /// - Changes sync across all devices signed in with the same Apple ID
    ///
    /// ## Requirements
    ///
    /// - MusicKit authorization granted
    /// - Active Apple Music subscription
    /// - Internet connectivity
    /// - Valid catalog song (not a local file)
    ///
    /// ## Performance
    ///
    /// - Network latency: 200-800ms typical
    /// - Data usage: ~5-10KB per request
    /// - Safe to call from main thread (async operation)
    ///
    /// ## Implementation Details
    ///
    /// The method uses MusadoraKit's `MCatalog.addRating(for:rating:)` with
    /// a rating value of `.like`. MusadoraKit automatically handles:
    /// - Network request formatting
    /// - Authentication token management
    /// - Response parsing
    /// - Error mapping
    ///
    /// - Parameter song: The MusicKit `Song` object to favorite. Must be from the
    ///   Apple Music catalog with a valid ID.
    ///
    /// - Returns: `true` if the operation succeeded, though in practice this always
    ///   returns `true` (errors are thrown instead).
    ///
    /// - Throws: ``FavoritesError`` with specific failure reason:
    ///   - `.notAuthorized`: User hasn't authorized MusicKit
    ///   - `.noSubscription`: User doesn't have Apple Music subscription
    ///   - `.networkError`: Network connection failed or API timeout
    ///   - `.songNotFound`: Song not found in Apple Music catalog
    ///
    /// ## Usage Example
    ///
    /// ```swift
    /// // In MenuBarView
    /// Button("Add to Favorites") {
    ///     Task {
    ///         do {
    ///             guard let song = playbackMonitor.currentSong else { return }
    ///             _ = try await favoritesService.addToFavorites(song: song)
    ///             showSuccessNotification()
    ///         } catch {
    ///             showErrorAlert(error.localizedDescription)
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Important: This method requires `async` context. Call it from within a
    ///   `Task` if you're in a synchronous context.
    func addToFavorites(song: Song) async throws -> Bool {
        print("Adding song to favorites: \(song.title)")

        do {
            // Use MusadoraKit to add rating
            //
            // Rating types in Apple Music:
            // - .like = Favorited/Hearted (what we want)
            // - .dislike = Thumbs down (not used in this app)
            //
            // Why MusadoraKit? MusicKit's native ratings API is complex and requires
            // manual network requests. MusadoraKit wraps it with a simple async API.
            _ = try await MCatalog.addRating(for: song, rating: .like)

            print("✅ Successfully added '\(song.title)' to favorites")
            return true
        } catch let error as MusadoraKitError {
            // MusadoraKit threw a specific error - map it to our app's error type
            // for consistent error handling throughout the app
            print("❌ Error adding to favorites: \(error.localizedDescription)")
            throw mapMusadoraKitError(error)
        } catch {
            // Unknown error type (shouldn't happen, but handle gracefully)
            print("❌ Error adding to favorites: \(error.localizedDescription)")
            throw FavoritesError.networkError
        }
    }

    /// Removes a song from the user's Apple Music favorites.
    ///
    /// This method removes the "liked" status from a song, removing it from favorites.
    /// Changes sync across all devices.
    ///
    /// ## Behavior
    ///
    /// - Makes a network request to Apple Music API via MusadoraKit
    /// - If song isn't favorited, the operation is idempotent (no error)
    /// - Changes sync across all devices signed in with the same Apple ID
    ///
    /// ## Implementation
    ///
    /// Uses MusadoraKit's `MCatalog.deleteRating(for:)` which removes any existing
    /// rating (like or dislike) for the song.
    ///
    /// - Parameter song: The MusicKit `Song` object to unfavorite
    ///
    /// - Returns: `true` if the operation succeeded
    ///
    /// - Throws: ``FavoritesError`` with specific failure reason
    ///
    /// - Note: This method is currently unused in the app but provided for future
    ///   functionality (e.g., toggle favorites, unlike button).
    func removeFromFavorites(song: Song) async throws -> Bool {
        // Remove rating from song
        do {
            _ = try await MCatalog.deleteRating(for: song)
            return true
        } catch let error as MusadoraKitError {
            throw mapMusadoraKitError(error)
        } catch {
            throw FavoritesError.networkError
        }
    }

    /// Checks whether a song is currently favorited.
    ///
    /// - Parameter song: The MusicKit `Song` object to check
    ///
    /// - Returns: Always returns `false` due to API limitations
    ///
    /// - Throws: Currently doesn't throw, but signature preserved for future implementation
    ///
    /// - Important: **This method is not functional** due to MusadoraKit API limitations.
    ///   MusadoraKit (as of v4.0) doesn't provide a `getRating()` method - only add/delete.
    ///   For v1 of the app, we always assume songs are not favorited and always add them.
    ///
    /// ## Future Implementation
    ///
    /// When MusadoraKit adds rating query support, this method should:
    /// 1. Query the song's current rating via `MCatalog.getRating(for:)`
    /// 2. Return `true` if rating is `.like`
    /// 3. Return `false` if rating is `.dislike` or `nil`
    ///
    /// This would enable:
    /// - Toggle functionality (favorite/unfavorite button)
    /// - Visual indicators (show heart icon when already favorited)
    /// - Preventing duplicate favorites
    func isFavorited(song: Song) async throws -> Bool {
        // MusadoraKit doesn't provide a getRating method
        // We can only add/delete ratings, not query them
        //
        // For v1, we ignore this and always add to favorites when clicked
        // (idempotent operation - if already liked, nothing changes)
        //
        // TODO: When MusadoraKit adds getRating support, implement this:
        // let rating = try await MCatalog.getRating(for: song)
        // return rating == .like
        return false
    }

    /// Retrieves all favorited songs from the user's Apple Music library.
    ///
    /// - Returns: Empty array (not implemented yet)
    ///
    /// - Throws: Currently doesn't throw, but signature preserved for future implementation
    ///
    /// - Important: **This method is not implemented** and always returns an empty array.
    ///   It's a placeholder for future functionality.
    ///
    /// ## Future Implementation
    ///
    /// When implemented, this method should:
    /// 1. Query the user's library for songs with `.like` rating
    /// 2. Return array of favorited songs with full metadata
    /// 3. Support pagination for large libraries
    ///
    /// Potential use cases:
    /// - "View Favorites" menu item
    /// - Favorites history window
    /// - Export favorites to playlist
    func getFavorites() async throws -> [Song] {
        // TODO: Implement for future features like:
        // - "View all favorites" menu item
        // - Favorites history window
        // - Recently favorited songs list
        //
        // Implementation would query MusicKit for user's library songs
        // filtered by rating == .like
        return []
    }

    // MARK: - Private Methods

    /// Maps MusadoraKit-specific errors to app-specific error types.
    ///
    /// This method provides a translation layer between MusadoraKit's error types
    /// and our app's ``FavoritesError`` enum, allowing for consistent error
    /// handling throughout the application.
    ///
    /// ## Error Mapping
    ///
    /// | MusadoraKitError | FavoritesError | Meaning |
    /// |------------------|----------------|---------|
    /// | `.notAuthorized` | `.notAuthorized` | User hasn't granted MusicKit permission |
    /// | `.noSubscription` | `.noSubscription` | User doesn't have Apple Music subscription |
    /// | `.networkError`, `.urlError` | `.networkError` | Network connection failed or timeout |
    /// | `.notFound` | `.songNotFound` | Song not in Apple Music catalog |
    /// | Other | `.networkError` | Unknown error, default to network issue |
    ///
    /// ## Why Error Mapping?
    ///
    /// 1. **Abstraction**: Hides MusadoraKit implementation details from the rest of the app
    /// 2. **Consistency**: All favorites-related errors use the same enum
    /// 3. **Localization**: ``FavoritesError`` provides user-friendly messages
    /// 4. **Flexibility**: Can switch from MusadoraKit to native MusicKit without changing error handling
    ///
    /// - Parameter error: The MusadoraKit error to map
    /// - Returns: The corresponding ``FavoritesError`` case
    private func mapMusadoraKitError(_ error: MusadoraKitError) -> FavoritesError {
        switch error {
        case .notAuthorized:
            return .notAuthorized

        case .noSubscription:
            return .noSubscription

        case .networkError, .urlError:
            // Both represent connection issues - map to same error
            return .networkError

        case .notFound:
            // Song isn't in Apple Music catalog (likely a local file)
            return .songNotFound

        default:
            // Unknown error - default to network error as most common failure mode
            return .networkError
        }
    }
}

// MARK: - Error Types

/// Errors that can occur during favorites operations.
///
/// `FavoritesError` provides user-friendly, localized error messages for all
/// failure scenarios in the favorites system. These errors are designed to be
/// displayed directly to users in alerts or notifications.
///
/// ## Error Cases
///
/// - ``notAuthorized``: User hasn't granted MusicKit permission
/// - ``noSubscription``: User doesn't have an active Apple Music subscription
/// - ``networkError``: Network connection failed or API timeout
/// - ``songNotFound``: Song isn't in the Apple Music catalog
///
/// ## Usage Example
///
/// ```swift
/// do {
///     try await favoritesService.addToFavorites(song: song)
/// } catch let error as FavoritesError {
///     // error.errorDescription provides localized message
///     showAlert(message: error.errorDescription ?? "Unknown error")
/// }
/// ```
enum FavoritesError: LocalizedError {
    /// User hasn't authorized MusicKit access.
    ///
    /// **User Action Required**: Open System Preferences > Privacy & Security >
    /// Media & Apple Music and enable access for StarTune.
    case notAuthorized

    /// User doesn't have an active Apple Music subscription.
    ///
    /// **User Action Required**: Subscribe to Apple Music via the Music app
    /// or App Store.
    case noSubscription

    /// Network connection failed or Apple Music API is unavailable.
    ///
    /// **Possible Causes**:
    /// - No internet connection
    /// - Apple Music servers are down
    /// - Request timeout
    /// - Rate limits exceeded
    ///
    /// **User Action**: Check internet connection and try again
    case networkError

    /// Song was not found in the Apple Music catalog.
    ///
    /// **Possible Causes**:
    /// - Song is a local file (not from Apple Music)
    /// - Song has been removed from Apple Music
    /// - Song is region-restricted
    ///
    /// **User Action**: This song cannot be favorited
    case songNotFound

    /// A localized, user-friendly description of the error.
    ///
    /// These messages are designed to be displayed directly in UI alerts or
    /// notifications. They explain what went wrong and suggest next steps.
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
