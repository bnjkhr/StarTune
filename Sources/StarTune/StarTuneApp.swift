//
//  StarTuneApp.swift
//  StarTune
//
//  Created on 2025-10-24.
//

import SwiftUI
import MusicKit

/// The main entry point for the StarTune menu bar application.
///
/// `StarTuneApp` configures the app as a menu bar-only application that runs discreetly
/// in the menu bar with no Dock icon. It manages the app's lifecycle, dependency
/// injection, and initial setup.
///
/// ## Overview
///
/// StarTune is a utility app that lives exclusively in the macOS menu bar, providing
/// quick access to add the currently playing Apple Music track to favorites. The app
/// uses SwiftUI's `MenuBarExtra` to create a native menu bar presence.
///
/// ## Architecture
///
/// The app follows the MVVM pattern with centralized dependency management:
/// - **@StateObject managers**: Created once at app launch, live for app lifetime
/// - **Dependency injection**: Managers passed to views via initializers
/// - **Reactive updates**: @Published properties automatically update UI
///
/// ```
/// StarTuneApp (Composition Root)
///     ├── @StateObject MusicKitManager
///     ├── @StateObject PlaybackMonitor
///     └── MenuBarExtra
///         ├── MenuBarView (injected dependencies)
///         └── Dynamic star icon (yellow/gray)
/// ```
///
/// ## Lifecycle
///
/// 1. **App Launch**: `init()` called, managers created as `@StateObject`
/// 2. **Menu First Open**: `onAppear` triggers `setupApp()` once
/// 3. **Setup**: Requests MusicKit authorization, starts playback monitoring
/// 4. **Runtime**: App runs continuously, monitoring playback every 2 seconds
///
/// ## Configuration
///
/// The app requires specific Info.plist settings:
/// - `LSUIElement = true`: Hides app from Dock (menu bar only)
/// - `NSAppleMusicUsageDescription`: Permission prompt message for MusicKit
/// - `NSAppleEventsUsageDescription`: Permission prompt for AppleScript/Music.app
///
/// ## Menu Bar Behavior
///
/// - **Icon**: SF Symbol "star.fill" that changes color based on playback
///   - Yellow: Music is playing
///   - Gray: Music is paused or stopped
/// - **Click**: Opens popover with current song info and "Add to Favorites" button
/// - **Style**: `.window` style provides popover appearance
///
/// ## Thread Safety
///
/// All SwiftUI views and `@StateObject` managers run on the main thread by default.
/// Async operations (authorization, monitoring) use Swift's structured concurrency.
///
/// - SeeAlso:
///   - ``MusicKitManager`` for authorization management
///   - ``PlaybackMonitor`` for playback monitoring
///   - ``MenuBarView`` for the menu bar popover content
@main
struct StarTuneApp: App {

    // MARK: - State Objects

    /// The central manager for MusicKit authorization and subscription status.
    ///
    /// Created once at app launch and lives for the app's lifetime. This manager
    /// is injected into views that need to check authorization state or display
    /// error messages.
    ///
    /// - Note: `@StateObject` ensures the manager is created once and survives
    ///   view recreation, unlike `@ObservedObject` which doesn't own the object.
    @StateObject private var musicKitManager = MusicKitManager()

    /// The playback monitor that tracks the currently playing song.
    ///
    /// Created once at app launch and lives for the app's lifetime. This monitor
    /// polls Music.app every 2 seconds and updates published properties that
    /// drive the UI.
    ///
    /// - Note: The monitor isn't started until after successful authorization
    ///   in ``setupApp()``.
    @StateObject private var playbackMonitor = PlaybackMonitor()

    /// Tracks whether the app has completed its one-time setup.
    ///
    /// This flag prevents ``setupApp()`` from running multiple times if the user
    /// closes and reopens the menu bar popover.
    ///
    /// - Important: This is intentionally `@State` (not `@AppStorage`) so setup
    ///   runs fresh on each app launch, not just the first launch ever.
    @State private var hasSetupApp = false

    // MARK: - Initialization

    /// Creates the app instance.
    ///
    /// The initializer is intentionally minimal - all actual setup happens in
    /// ``setupApp()`` which runs on first menu open, not at launch.
    ///
    /// ## Menu Bar Only Configuration
    ///
    /// The app is configured as menu bar-only via Info.plist `LSUIElement = true`.
    /// This setting:
    /// - Hides the app from the Dock
    /// - Prevents the app from appearing in Cmd+Tab switcher
    /// - Removes the menu bar at the top (File, Edit, etc.)
    ///
    /// - Note: The Info.plist setting is what makes this work - no code needed here.
    init() {
        // App configured as menu bar only via Info.plist: LSUIElement = true
        // No initialization needed here - setup happens in setupApp()
    }

    // MARK: - Scene

    /// The app's scene configuration using MenuBarExtra for menu bar presence.
    ///
    /// ## Scene Structure
    ///
    /// - **Content**: ``MenuBarView`` with injected dependencies
    /// - **Label**: Dynamic star icon that changes color based on playback state
    /// - **Style**: `.window` provides native popover appearance
    ///
    /// ## One-Time Setup
    ///
    /// The `onAppear` modifier calls ``setupApp()`` only once using the
    /// ``hasSetupApp`` flag. This ensures authorization happens when needed,
    /// not immediately at launch (which might be before the user interacts).
    ///
    /// ## Dynamic Icon
    ///
    /// The menu bar icon reactively changes color:
    /// - **Yellow star**: `playbackMonitor.isPlaying` is `true`
    /// - **Gray star**: `playbackMonitor.isPlaying` is `false`
    ///
    /// SwiftUI automatically updates the icon when the `@Published` property changes.
    var body: some Scene {
        // MenuBarExtra creates the menu bar presence (replaces NSStatusItem in AppKit)
        MenuBarExtra {
            // Menu bar popover content
            MenuBarView(
                musicKitManager: musicKitManager,
                playbackMonitor: playbackMonitor
            )
            .onAppear {
                // One-time app setup on first menu open
                // Guard ensures this only runs once per app session
                guard !hasSetupApp else { return }
                hasSetupApp = true

                // Run async setup in a Task
                Task {
                    await setupApp()
                }
            }
        } label: {
            // Menu bar icon - dynamically changes color based on playback state
            //
            // Why reactive? playbackMonitor.isPlaying is @Published, so SwiftUI
            // automatically rebuilds this view when it changes
            Image(systemName: "star.fill")
                .foregroundColor(playbackMonitor.isPlaying ? .yellow : .gray)
        }
        .menuBarExtraStyle(.window) // Popover style (vs .menu for dropdown menu)
    }
}

// MARK: - App Lifecycle

extension StarTuneApp {

    /// Performs one-time app setup: requests authorization and starts monitoring.
    ///
    /// This method is called once on first menu open (not at app launch) to avoid
    /// showing permission prompts before the user has interacted with the app.
    ///
    /// ## Setup Flow
    ///
    /// 1. **Request Authorization**: Shows system prompt for MusicKit access
    /// 2. **Check Status**: If authorized, also checks Apple Music subscription
    /// 3. **Start Monitoring**: If authorized, begins 2-second polling of playback state
    ///
    /// ## Why Defer Setup?
    ///
    /// - **Better UX**: User sees the app first, then permission prompt makes sense
    /// - **macOS Guidelines**: Request permissions in context, not immediately at launch
    /// - **Faster Launch**: Heavy async operations don't slow down app launch
    ///
    /// ## Error Handling
    ///
    /// If authorization fails or is denied:
    /// - Monitoring doesn't start
    /// - ``MenuBarView`` shows an error message with ``MusicKitManager/unavailabilityReason``
    /// - User can manually retry by reopening System Preferences
    ///
    /// ## Thread Safety
    ///
    /// This is an `async` method called from a `Task`, so it runs concurrently.
    /// However, both `musicKitManager` and `playbackMonitor` are `@MainActor`,
    /// so their property updates automatically happen on the main thread.
    ///
    /// ## Performance
    ///
    /// - Authorization request: Instant if previously authorized, ~1s for new prompt
    /// - Subscription check: 100-500ms network request
    /// - Start monitoring: Instant (just creates timer and does first update)
    /// - Total: ~1-2s on first authorization, <100ms on subsequent launches
    private func setupApp() async {
        // Step 1: Request MusicKit authorization
        // This shows system permission prompt if not yet determined
        await musicKitManager.requestAuthorization()

        // Step 2: Start playback monitoring if authorized
        // Why conditional? Monitoring requires authorization to work properly,
        // and would fail/log errors if not authorized
        if musicKitManager.isAuthorized {
            await playbackMonitor.startMonitoring()
        }
        // Note: If not authorized, MenuBarView will display error UI
        // User can retry by granting permission in System Preferences
    }
}
