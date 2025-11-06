//
//  MusicKitManager.swift
//  StarTune
//
//  Created on 2025-10-24.
//

import Foundation
import MusicKit
import Combine

/// Manages MusicKit authorization and Apple Music subscription status.
///
/// `MusicKitManager` is the central authority for MusicKit permissions and capabilities.
/// It handles requesting user authorization, checking subscription status, and providing
/// availability information to other components.
///
/// ## Overview
///
/// MusicKit requires two prerequisites for full functionality:
/// 1. **Authorization**: User permission to access their Apple Music library and data
/// 2. **Subscription**: An active Apple Music subscription
///
/// This manager tracks both and provides a single ``canUseMusicKit`` property that
/// indicates whether all prerequisites are met.
///
/// ## Lifecycle
///
/// The manager is created at app launch as a `@StateObject` in ``StarTuneApp`` and
/// lives for the app's lifetime. It immediately checks the current authorization
/// status during initialization.
///
/// ## Authorization Flow
///
/// ```
/// App Launch
///   ↓
/// MusicKitManager.init()
///   ↓
/// updateAuthorizationStatus() ← Checks current status (no permission request)
///   ↓
/// [User opens app / clicks menu]
///   ↓
/// requestAuthorization() ← Shows system permission prompt
///   ↓
/// checkSubscriptionStatus() ← Verifies active subscription
///   ↓
/// @Published properties update → UI responds automatically
/// ```
///
/// ## Thread Safety
///
/// This class is marked with `@MainActor` to ensure all published properties
/// update on the main thread, enabling direct UI bindings.
///
/// ## Usage
///
/// ```swift
/// let manager = MusicKitManager()
///
/// // Request authorization (shows system prompt)
/// await manager.requestAuthorization()
///
/// // Check if ready to use MusicKit features
/// if manager.canUseMusicKit {
///     // Can add to favorites, access library, etc.
/// } else {
///     // Show error message
///     print(manager.unavailabilityReason ?? "Unknown error")
/// }
/// ```
///
/// ## Requirements
///
/// - macOS 13.0+ (for MusicKit framework)
/// - `NSAppleMusicUsageDescription` in Info.plist
/// - User approval in system permission dialog
/// - Active Apple Music subscription
///
/// - SeeAlso: ``FavoritesService`` which depends on this manager's authorization state
@MainActor
class MusicKitManager: ObservableObject {

    // MARK: - Published Properties

    /// Whether the user has authorized MusicKit access.
    ///
    /// This is `true` when ``authorizationStatus`` is `.authorized`.
    /// The app can only access MusicKit features when this is `true` AND
    /// ``hasAppleMusicSubscription`` is also `true`.
    @Published var isAuthorized = false

    /// The current MusicKit authorization status.
    ///
    /// Possible values:
    /// - `.notDetermined`: User hasn't been asked yet
    /// - `.denied`: User denied access
    /// - `.restricted`: Access restricted by device policy (parental controls, MDM)
    /// - `.authorized`: User granted access
    ///
    /// - SeeAlso: `MusicAuthorization.Status` for more details
    @Published var authorizationStatus: MusicAuthorization.Status = .notDetermined

    /// Whether the user has an active Apple Music subscription.
    ///
    /// This is checked after successful authorization using `MusicSubscription.current`.
    /// Many MusicKit features (like adding to favorites) require an active subscription.
    ///
    /// - Note: This property is only updated after ``requestAuthorization()`` completes
    ///   successfully. It remains `false` if authorization was denied.
    @Published var hasAppleMusicSubscription = false

    // MARK: - Initialization

    /// Creates a new MusicKit manager and checks the current authorization status.
    ///
    /// The initializer immediately checks the current authorization status without
    /// prompting the user. This allows the UI to display the correct initial state.
    ///
    /// To actually request authorization (showing the system prompt), call
    /// ``requestAuthorization()`` separately.
    ///
    /// ## Initialization Behavior
    ///
    /// - Checks `MusicAuthorization.currentStatus` synchronously
    /// - Updates ``isAuthorized`` and ``authorizationStatus`` properties
    /// - Does NOT check subscription status (only happens after explicit authorization)
    /// - Does NOT show any UI or prompts
    init() {
        // Check current authorization status without prompting user
        // This allows UI to display correct initial state
        updateAuthorizationStatus()
    }

    // MARK: - Public Methods

    /// Requests MusicKit authorization from the user.
    ///
    /// This method displays the system permission prompt asking the user to grant
    /// access to Apple Music. If the user approves, the method also checks their
    /// subscription status.
    ///
    /// ## User Experience
    ///
    /// The system shows a dialog with:
    /// - App icon and name
    /// - Permission request message (from `NSAppleMusicUsageDescription`)
    /// - "Don't Allow" and "OK" buttons
    ///
    /// ## Behavior by Status
    ///
    /// - **First request (notDetermined)**: Shows permission dialog
    /// - **Previously authorized**: Immediately returns `.authorized`, no dialog
    /// - **Previously denied**: Immediately returns `.denied`, no dialog (user must use System Preferences)
    /// - **Restricted**: Immediately returns `.restricted`, no dialog
    ///
    /// ## Post-Authorization
    ///
    /// If authorization succeeds (status becomes `.authorized`), the method
    /// automatically checks subscription status via ``checkSubscriptionStatus()``.
    ///
    /// ## Thread Safety
    ///
    /// This is an `async` method that must be called from a `Task` or other async context.
    /// All property updates happen on the main thread due to `@MainActor`.
    ///
    /// ## Usage Example
    ///
    /// ```swift
    /// Button("Authorize") {
    ///     Task {
    ///         await musicKitManager.requestAuthorization()
    ///         if musicKitManager.canUseMusicKit {
    ///             print("Ready to use MusicKit!")
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Important: If the user denies permission, they must manually enable it in
    ///   System Preferences > Privacy & Security > Media & Apple Music. The app
    ///   cannot re-prompt them.
    func requestAuthorization() async {
        // Request authorization - shows system prompt if not determined yet
        let status = await MusicAuthorization.request()

        // Update our published state with the result
        updateAuthorizationStatus()

        // If authorized, check subscription status
        // Why conditional? Subscription check requires authorization, would fail otherwise
        if status == .authorized {
            await checkSubscriptionStatus()
        }
    }

    // MARK: - Private Methods

    /// Updates internal authorization state from MusicKit's current status.
    ///
    /// This method reads the current authorization status synchronously and updates
    /// the published properties. It's called during initialization and after
    /// authorization requests.
    ///
    /// ## Implementation Details
    ///
    /// - Reads `MusicAuthorization.currentStatus` (synchronous, cached)
    /// - Updates ``authorizationStatus`` with raw status
    /// - Updates ``isAuthorized`` boolean for convenience
    ///
    /// - Note: This method does NOT prompt the user or make any network requests.
    ///   It only reads cached authorization state.
    private func updateAuthorizationStatus() {
        // Read current status from MusicKit (cached, no async call needed)
        let currentStatus = MusicAuthorization.currentStatus

        // Update published properties
        authorizationStatus = currentStatus
        isAuthorized = (currentStatus == .authorized)
    }

    /// Checks whether the user has an active Apple Music subscription.
    ///
    /// This method queries `MusicSubscription.current` to determine if the user
    /// can play catalog content. It requires prior authorization and makes a
    /// network request to Apple's servers.
    ///
    /// ## Implementation Details
    ///
    /// - Makes an async network request to check subscription
    /// - Updates ``hasAppleMusicSubscription`` with the result
    /// - Handles errors gracefully by setting subscription to `false`
    ///
    /// ## Subscription Requirements
    ///
    /// The subscription check uses `canPlayCatalogContent` which is `true` when:
    /// - User has an active paid Apple Music subscription, OR
    /// - User is in a free trial period
    ///
    /// ## Error Handling
    ///
    /// Errors are logged but don't throw - the method assumes no subscription on error.
    /// Common error scenarios:
    /// - No internet connection
    /// - MusicKit API rate limits
    /// - User not signed in to Apple ID
    ///
    /// ## Performance
    ///
    /// - Network request: ~100-500ms
    /// - Called only after successful authorization
    /// - Result is cached (doesn't need frequent re-checking)
    ///
    /// - Note: This method is private and called automatically by ``requestAuthorization()``.
    private func checkSubscriptionStatus() async {
        do {
            // Query Apple Music subscription status
            // This is a network call that can take 100-500ms
            let subscription = try await MusicSubscription.current

            // Update subscription state
            // canPlayCatalogContent is true for active subscriptions and trials
            hasAppleMusicSubscription = subscription.canPlayCatalogContent
        } catch {
            // Log error but don't crash - assume no subscription on error
            // Common errors: no network, not signed in, API issues
            print("Error checking subscription status: \(error.localizedDescription)")
            hasAppleMusicSubscription = false
        }
    }

    // MARK: - Computed Properties

    /// Whether all prerequisites for MusicKit features are met.
    ///
    /// This is a convenience property that returns `true` only when:
    /// - User has authorized MusicKit access (``isAuthorized`` is `true`)
    /// - User has an active Apple Music subscription (``hasAppleMusicSubscription`` is `true`)
    ///
    /// Use this property to enable/disable UI controls or check feature availability.
    ///
    /// ## Usage Example
    ///
    /// ```swift
    /// if musicKitManager.canUseMusicKit {
    ///     // Can add to favorites, access playlists, etc.
    ///     await favoritesService.addToFavorites(song: song)
    /// } else {
    ///     // Show error message
    ///     showAlert(message: musicKitManager.unavailabilityReason ?? "Unknown error")
    /// }
    /// ```
    ///
    /// - SeeAlso: ``unavailabilityReason`` for user-friendly error messages
    var canUseMusicKit: Bool {
        return isAuthorized && hasAppleMusicSubscription
    }

    /// A user-friendly error message explaining why MusicKit is unavailable.
    ///
    /// Returns `nil` if MusicKit is available (``canUseMusicKit`` is `true`).
    /// Otherwise, returns a localized message explaining what the user needs to do.
    ///
    /// ## Possible Messages
    ///
    /// - "Please allow access to Apple Music in Settings" - Not authorized
    /// - "An Apple Music subscription is required" - Authorized but no subscription
    /// - `nil` - All prerequisites met
    ///
    /// ## Usage Example
    ///
    /// ```swift
    /// if !musicKitManager.canUseMusicKit {
    ///     if let reason = musicKitManager.unavailabilityReason {
    ///         Text(reason)
    ///             .foregroundColor(.red)
    ///     }
    /// }
    /// ```
    var unavailabilityReason: String? {
        if !isAuthorized {
            return "Please allow access to Apple Music in Settings"
        }
        if !hasAppleMusicSubscription {
            return "An Apple Music subscription is required"
        }
        return nil
    }
}

// MARK: - Authorization Status Extension

extension MusicAuthorization.Status {
    /// A human-readable description of the authorization status.
    ///
    /// This extension provides user-friendly string representations of MusicKit
    /// authorization statuses for debugging and logging purposes.
    ///
    /// ## Status Descriptions
    ///
    /// - `.notDetermined`: "Not Determined" - User hasn't been asked yet
    /// - `.denied`: "Denied" - User denied access
    /// - `.restricted`: "Restricted" - Access restricted by device policy
    /// - `.authorized`: "Authorized" - User granted access
    /// - `@unknown default`: "Unknown" - Future status values
    ///
    /// ## Usage Example
    ///
    /// ```swift
    /// print("Authorization status: \(manager.authorizationStatus.description)")
    /// // Output: "Authorization status: Authorized"
    /// ```
    var description: String {
        switch self {
        case .notDetermined:
            return "Not Determined"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        case .authorized:
            return "Authorized"
        @unknown default:
            return "Unknown"
        }
    }
}
