# StarTune API Usage Examples

This document provides comprehensive examples of how to use StarTune's internal APIs for common tasks. These examples are useful for:

- **New developers** onboarding to the codebase
- **Contributors** adding features or fixing bugs
- **Maintainers** understanding component interactions
- **Testing** creating unit and integration tests

## Table of Contents

- [Getting Started](#getting-started)
- [MusicKit Authorization](#musickit-authorization)
- [Playback Monitoring](#playback-monitoring)
- [Adding Songs to Favorites](#adding-songs-to-favorites)
- [Error Handling](#error-handling)
- [Complete Integration Examples](#complete-integration-examples)
- [Testing Patterns](#testing-patterns)

---

## Getting Started

### Basic Setup

StarTune follows the MVVM architecture with dependency injection. All managers are created once in `StarTuneApp` and injected into views:

```swift
import SwiftUI
import MusicKit

@main
struct StarTuneApp: App {
    // Create managers once as @StateObject
    @StateObject private var musicKitManager = MusicKitManager()
    @StateObject private var playbackMonitor = PlaybackMonitor()

    var body: some Scene {
        MenuBarExtra {
            // Inject dependencies into views
            MenuBarView(
                musicKitManager: musicKitManager,
                playbackMonitor: playbackMonitor
            )
        } label: {
            Image(systemName: "star.fill")
        }
    }
}
```

---

## MusicKit Authorization

### Example 1: Check Authorization Status

```swift
import SwiftUI

struct AuthorizationStatusView: View {
    @ObservedObject var musicKitManager: MusicKitManager

    var body: some View {
        VStack {
            Text("Authorization Status: \(musicKitManager.authorizationStatus.description)")

            if musicKitManager.isAuthorized {
                Text("✅ Authorized")
                    .foregroundColor(.green)
            } else {
                Text("❌ Not Authorized")
                    .foregroundColor(.red)
            }

            if musicKitManager.hasAppleMusicSubscription {
                Text("✅ Has Subscription")
            } else {
                Text("⚠️ No Subscription")
            }
        }
    }
}
```

### Example 2: Request Authorization

```swift
import SwiftUI

struct AuthorizationButton: View {
    @ObservedObject var musicKitManager: MusicKitManager
    @State private var isRequesting = false

    var body: some View {
        Button("Authorize Apple Music") {
            isRequesting = true

            Task {
                // Request authorization (shows system prompt)
                await musicKitManager.requestAuthorization()

                isRequesting = false

                // Check result
                if musicKitManager.canUseMusicKit {
                    print("Ready to use MusicKit!")
                } else if let reason = musicKitManager.unavailabilityReason {
                    print("Cannot use MusicKit: \(reason)")
                }
            }
        }
        .disabled(isRequesting || musicKitManager.isAuthorized)
    }
}
```

### Example 3: Conditional UI Based on Authorization

```swift
struct ConditionalAuthView: View {
    @ObservedObject var musicKitManager: MusicKitManager

    var body: some View {
        Group {
            if musicKitManager.canUseMusicKit {
                // Show full app functionality
                MainAppView()
            } else {
                // Show authorization prompt
                VStack {
                    Text("StarTune needs access to Apple Music")
                    Text(musicKitManager.unavailabilityReason ?? "Unknown error")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button("Grant Access") {
                        Task {
                            await musicKitManager.requestAuthorization()
                        }
                    }
                }
            }
        }
    }
}
```

---

## Playback Monitoring

### Example 4: Start Monitoring

```swift
import SwiftUI

extension StarTuneApp {
    func setupApp() async {
        // Request authorization first
        await musicKitManager.requestAuthorization()

        // Start monitoring if authorized
        if musicKitManager.isAuthorized {
            await playbackMonitor.startMonitoring()
            print("🎵 Playback monitoring started")
        }
    }
}
```

### Example 5: Display Current Song

```swift
struct CurrentSongView: View {
    @ObservedObject var playbackMonitor: PlaybackMonitor

    var body: some View {
        VStack(alignment: .leading) {
            if let song = playbackMonitor.currentSong {
                // Song is available
                Text(song.title)
                    .font(.headline)
                Text(song.artistName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Show artwork if available
                if let artwork = song.artwork {
                    ArtworkImage(artwork, width: 60, height: 60)
                }
            } else if playbackMonitor.isPlaying {
                // Playing but song not found in catalog
                Text("Playing (local song)")
                    .foregroundColor(.secondary)
            } else {
                // Nothing playing
                Text("No song playing")
                    .foregroundColor(.secondary)
            }
        }
    }
}
```

### Example 6: Reactive Playback Indicator

```swift
struct PlaybackIndicator: View {
    @ObservedObject var playbackMonitor: PlaybackMonitor

    var body: some View {
        HStack {
            // Icon changes color based on playback state
            Image(systemName: "music.note")
                .foregroundColor(playbackMonitor.isPlaying ? .green : .gray)

            // Show formatted song info
            if let info = playbackMonitor.currentSongInfo {
                Text(info)
            } else {
                Text("Stopped")
                    .foregroundColor(.secondary)
            }
        }
        // View automatically updates when @Published properties change
    }
}
```

### Example 7: Stop Monitoring

```swift
func cleanupApp() {
    // Stop monitoring when needed (e.g., app termination)
    playbackMonitor.stopMonitoring()
    print("🛑 Playback monitoring stopped")
}
```

---

## Adding Songs to Favorites

### Example 8: Basic Add to Favorites

```swift
struct AddToFavoritesButton: View {
    let song: Song
    @State private var favoritesService = FavoritesService()
    @State private var isProcessing = false

    var body: some View {
        Button("Add to Favorites") {
            isProcessing = true

            Task {
                do {
                    let success = try await favoritesService.addToFavorites(song: song)
                    if success {
                        print("✅ Added '\(song.title)' to favorites")
                    }
                } catch {
                    print("❌ Error: \(error.localizedDescription)")
                }

                isProcessing = false
            }
        }
        .disabled(isProcessing)
    }
}
```

### Example 9: Add with Visual Feedback

```swift
struct FavoriteButtonWithFeedback: View {
    let song: Song
    @State private var favoritesService = FavoritesService()
    @State private var isProcessing = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack {
            Button {
                addToFavorites()
            } label: {
                if isProcessing {
                    ProgressView()
                } else {
                    Label("Add to Favorites", systemImage: "heart")
                }
            }
            .disabled(isProcessing)

            // Success message
            if showSuccess {
                Text("Added to Favorites!")
                    .foregroundColor(.green)
            }

            // Error message
            if showError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }

    private func addToFavorites() {
        isProcessing = true
        showSuccess = false
        showError = false

        Task {
            do {
                _ = try await favoritesService.addToFavorites(song: song)

                // Show success
                await MainActor.run {
                    showSuccess = true
                    isProcessing = false
                }

                // Hide success after 3 seconds
                try await Task.sleep(nanoseconds: 3_000_000_000)
                await MainActor.run {
                    showSuccess = false
                }
            } catch let error as FavoritesError {
                // Handle specific errors
                await MainActor.run {
                    errorMessage = error.errorDescription ?? "Unknown error"
                    showError = true
                    isProcessing = false
                }
            } catch {
                // Handle unexpected errors
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isProcessing = false
                }
            }
        }
    }
}
```

### Example 10: Add Current Song

```swift
struct AddCurrentSongButton: View {
    @ObservedObject var playbackMonitor: PlaybackMonitor
    @State private var favoritesService = FavoritesService()

    var body: some View {
        Button("Favorite Current Song") {
            Task {
                await addCurrentSongToFavorites()
            }
        }
        .disabled(!playbackMonitor.hasSongPlaying)
    }

    private func addCurrentSongToFavorites() async {
        guard let song = playbackMonitor.currentSong else {
            print("⚠️ No song currently playing")
            return
        }

        do {
            _ = try await favoritesService.addToFavorites(song: song)
            print("✅ Added '\(song.title)' to favorites")

            // Optional: Post notification for other UI elements
            NotificationCenter.default.post(
                name: .favoriteSuccess,
                object: nil
            )
        } catch {
            print("❌ Failed to add to favorites: \(error.localizedDescription)")

            NotificationCenter.default.post(
                name: .favoriteError,
                object: error
            )
        }
    }
}

// Notification names
extension Notification.Name {
    static let favoriteSuccess = Notification.Name("favoriteSuccess")
    static let favoriteError = Notification.Name("favoriteError")
}
```

---

## Error Handling

### Example 11: Comprehensive Error Handling

```swift
func addToFavorites(song: Song) async {
    let service = FavoritesService()

    do {
        _ = try await service.addToFavorites(song: song)
        // Success!
    } catch FavoritesError.notAuthorized {
        // User hasn't authorized MusicKit
        showAlert(
            title: "Authorization Required",
            message: "Please allow access to Apple Music in System Preferences > Privacy & Security > Media & Apple Music"
        )
    } catch FavoritesError.noSubscription {
        // User doesn't have Apple Music subscription
        showAlert(
            title: "Subscription Required",
            message: "An active Apple Music subscription is required to favorite songs"
        )
    } catch FavoritesError.networkError {
        // Network connection failed
        showAlert(
            title: "Connection Error",
            message: "Could not connect to Apple Music. Please check your internet connection and try again."
        )
    } catch FavoritesError.songNotFound {
        // Song not in Apple Music catalog (local file)
        showAlert(
            title: "Song Unavailable",
            message: "This song cannot be favorited because it's not available in the Apple Music catalog"
        )
    } catch {
        // Unexpected error
        showAlert(
            title: "Error",
            message: error.localizedDescription
        )
    }
}
```

### Example 12: Pre-flight Checks

```swift
struct SmartFavoriteButton: View {
    @ObservedObject var musicKitManager: MusicKitManager
    @ObservedObject var playbackMonitor: PlaybackMonitor

    var body: some View {
        Button("Add to Favorites") {
            Task {
                await addWithPreflightChecks()
            }
        }
        .disabled(!canAddToFavorites)
    }

    // Pre-flight check
    private var canAddToFavorites: Bool {
        // Check all prerequisites
        guard musicKitManager.canUseMusicKit else {
            return false
        }
        guard playbackMonitor.hasSongPlaying else {
            return false
        }
        return true
    }

    private func addWithPreflightChecks() async {
        // Double-check prerequisites
        guard musicKitManager.canUseMusicKit else {
            print("❌ MusicKit not available: \(musicKitManager.unavailabilityReason ?? "")")
            return
        }

        guard let song = playbackMonitor.currentSong else {
            print("❌ No song playing")
            return
        }

        // Proceed with adding
        let service = FavoritesService()
        do {
            _ = try await service.addToFavorites(song: song)
            print("✅ Success!")
        } catch {
            print("❌ Error: \(error.localizedDescription)")
        }
    }
}
```

---

## Complete Integration Examples

### Example 13: Full Menu Bar View

```swift
struct MenuBarView: View {
    @ObservedObject var musicKitManager: MusicKitManager
    @ObservedObject var playbackMonitor: PlaybackMonitor
    @State private var favoritesService = FavoritesService()
    @State private var isProcessing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Text("StarTune")
                .font(.headline)

            Divider()

            // Authorization check
            if !musicKitManager.isAuthorized {
                authorizationSection
            } else {
                // Show current song and actions
                currentlyPlayingSection
                actionsSection
            }

            Divider()

            // Quit button
            Button("Quit StarTune") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .frame(width: 280)
    }

    // MARK: - Sections

    private var authorizationSection: some View {
        VStack {
            Text("Please authorize Apple Music access")
                .font(.caption)
            Button("Authorize") {
                Task {
                    await musicKitManager.requestAuthorization()
                }
            }
        }
    }

    private var currentlyPlayingSection: some View {
        Group {
            if let song = playbackMonitor.currentSong {
                VStack(alignment: .leading) {
                    Text("Now Playing")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(song.title)
                        .font(.headline)
                    Text(song.artistName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("No song playing")
                    .foregroundColor(.secondary)
            }
        }
    }

    private var actionsSection: some View {
        Button {
            Task {
                await addCurrentSongToFavorites()
            }
        } label: {
            if isProcessing {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Label("Add to Favorites", systemImage: "heart")
            }
        }
        .disabled(!playbackMonitor.hasSongPlaying || isProcessing)
    }

    // MARK: - Actions

    private func addCurrentSongToFavorites() async {
        guard let song = playbackMonitor.currentSong else { return }

        isProcessing = true

        do {
            _ = try await favoritesService.addToFavorites(song: song)
            // Success - show animation
            NotificationCenter.default.post(name: .favoriteSuccess, object: nil)
        } catch {
            // Error - show message
            NotificationCenter.default.post(name: .favoriteError, object: error)
        }

        isProcessing = false
    }
}
```

### Example 14: Custom Menu Bar Icon

```swift
struct DynamicMenuBarIcon: View {
    @ObservedObject var playbackMonitor: PlaybackMonitor

    var body: some View {
        Image(systemName: iconName)
            .foregroundColor(iconColor)
    }

    private var iconName: String {
        playbackMonitor.hasSongPlaying ? "star.fill" : "star"
    }

    private var iconColor: Color {
        playbackMonitor.isPlaying ? .yellow : .gray
    }
}

// Usage in app
@main
struct StarTuneApp: App {
    @StateObject private var playbackMonitor = PlaybackMonitor()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(playbackMonitor: playbackMonitor)
        } label: {
            DynamicMenuBarIcon(playbackMonitor: playbackMonitor)
        }
    }
}
```

---

## Testing Patterns

### Example 15: Unit Testing Managers

```swift
import XCTest
@testable import StarTune

@MainActor
class MusicKitManagerTests: XCTestCase {
    var manager: MusicKitManager!

    override func setUp() async throws {
        manager = MusicKitManager()
    }

    func testInitialState() {
        // Manager should not be authorized initially
        // (unless user previously authorized)
        XCTAssertEqual(manager.authorizationStatus, .notDetermined)
    }

    func testCanUseMusicKit() {
        // Should return false when not authorized
        manager.isAuthorized = false
        manager.hasAppleMusicSubscription = true
        XCTAssertFalse(manager.canUseMusicKit)

        // Should return false when no subscription
        manager.isAuthorized = true
        manager.hasAppleMusicSubscription = false
        XCTAssertFalse(manager.canUseMusicKit)

        // Should return true when both authorized and subscribed
        manager.isAuthorized = true
        manager.hasAppleMusicSubscription = true
        XCTAssertTrue(manager.canUseMusicKit)
    }

    func testUnavailabilityReason() {
        // Test not authorized
        manager.isAuthorized = false
        XCTAssertEqual(
            manager.unavailabilityReason,
            "Please allow access to Apple Music in Settings"
        )

        // Test no subscription
        manager.isAuthorized = true
        manager.hasAppleMusicSubscription = false
        XCTAssertEqual(
            manager.unavailabilityReason,
            "An Apple Music subscription is required"
        )

        // Test available
        manager.isAuthorized = true
        manager.hasAppleMusicSubscription = true
        XCTAssertNil(manager.unavailabilityReason)
    }
}
```

### Example 16: SwiftUI Preview with Mock Data

```swift
import SwiftUI

struct MenuBarView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview: Not authorized
            MenuBarView(
                musicKitManager: mockUnauthorizedManager(),
                playbackMonitor: mockPlaybackMonitor()
            )
            .previewDisplayName("Not Authorized")

            // Preview: Playing song
            MenuBarView(
                musicKitManager: mockAuthorizedManager(),
                playbackMonitor: mockPlayingMonitor()
            )
            .previewDisplayName("Playing Song")

            // Preview: Not playing
            MenuBarView(
                musicKitManager: mockAuthorizedManager(),
                playbackMonitor: mockStoppedMonitor()
            )
            .previewDisplayName("Stopped")
        }
    }

    // MARK: - Mocks

    static func mockUnauthorizedManager() -> MusicKitManager {
        let manager = MusicKitManager()
        // Set mock state
        return manager
    }

    static func mockAuthorizedManager() -> MusicKitManager {
        let manager = MusicKitManager()
        // Set mock state (would need to make properties settable for testing)
        return manager
    }

    static func mockPlaybackMonitor() -> PlaybackMonitor {
        return PlaybackMonitor()
    }

    static func mockPlayingMonitor() -> PlaybackMonitor {
        return PlaybackMonitor()
        // Would inject mock song data
    }

    static func mockStoppedMonitor() -> PlaybackMonitor {
        return PlaybackMonitor()
    }
}
```

---

## Best Practices

### DO ✅

1. **Always check prerequisites before operations**
   ```swift
   guard musicKitManager.canUseMusicKit else { return }
   ```

2. **Handle all error cases explicitly**
   ```swift
   catch FavoritesError.notAuthorized { ... }
   catch FavoritesError.noSubscription { ... }
   ```

3. **Use `@MainActor` for UI updates**
   ```swift
   await MainActor.run {
       self.isProcessing = false
   }
   ```

4. **Show loading states for async operations**
   ```swift
   Button { ... } label: {
       if isProcessing { ProgressView() } else { Text("Add") }
   }
   ```

5. **Inject dependencies via initializers**
   ```swift
   struct MyView: View {
       @ObservedObject var manager: MusicKitManager
       init(manager: MusicKitManager) { ... }
   }
   ```

### DON'T ❌

1. **Don't create managers in views**
   ```swift
   // ❌ BAD
   struct MyView: View {
       @StateObject private var manager = MusicKitManager()
   }
   ```

2. **Don't ignore errors**
   ```swift
   // ❌ BAD
   try? await favoritesService.addToFavorites(song: song)
   ```

3. **Don't block the main thread**
   ```swift
   // ❌ BAD
   let song = getSongSynchronously()  // Blocks UI
   ```

4. **Don't use force unwrapping**
   ```swift
   // ❌ BAD
   let song = playbackMonitor.currentSong!
   ```

5. **Don't bypass authorization checks**
   ```swift
   // ❌ BAD
   await favoritesService.addToFavorites(song: song)  // Will fail if not authorized
   ```

---

## Additional Resources

- [SwiftDocC Documentation](../Documentation) - Full API reference
- [Architecture Decision Records](../ADRs) - Design rationale
- [MusicKit Documentation](https://developer.apple.com/documentation/musickit)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)

---

**Last Updated:** 2025-10-24
**Maintainer:** StarTune Development Team
