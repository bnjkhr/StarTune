//
//  PlaybackState.swift
//  StarTune
//
//  Created on 2025-10-24.
//

import Foundation
import MusicKit

/// An immutable snapshot of the current playback state.
///
/// `PlaybackState` is a value type that encapsulates all playback-related information
/// at a specific point in time. It's designed for potential future use as a centralized
/// state container, though currently the app uses ``PlaybackMonitor`` directly.
///
/// ## Overview
///
/// This struct provides:
/// - Raw playback information (playing state, song, time, duration)
/// - Computed convenience properties (progress, hasActiveSong)
/// - A default empty state for initialization
///
/// ## Design Pattern
///
/// `PlaybackState` follows the **value type** pattern:
/// - Immutable: All properties are `let` constants
/// - Copyable: Struct semantics mean copies are independent
/// - Thread-safe: Immutability means safe to pass between threads
///
/// ## Current Status
///
/// ⚠️ **Currently Unused**: This model exists but isn't actively used in v1.0.
/// The app currently accesses ``PlaybackMonitor`` properties directly rather
/// than creating `PlaybackState` snapshots.
///
/// ## Future Use Cases
///
/// This model could be valuable for:
/// - **State History**: Store snapshots for "recently played" feature
/// - **State Persistence**: Save/restore playback state across app launches
/// - **Testing**: Create mock states for unit tests
/// - **Time Travel Debugging**: Capture state at different points in time
///
/// ## Usage Example
///
/// ```swift
/// // Creating a state snapshot
/// let state = PlaybackState(
///     isPlaying: true,
///     currentSong: song,
///     playbackTime: 125.0,
///     duration: 240.0
/// )
///
/// // Using computed properties
/// print("Progress: \(state.progress * 100)%")  // 52.08%
/// if state.hasActiveSong {
///     print("Song: \(state.currentSong?.title ?? "")")
/// }
///
/// // Empty state for initialization
/// var state = PlaybackState.empty
/// ```
///
/// - SeeAlso: ``PlaybackMonitor`` for the actively used playback tracking system
struct PlaybackState {

    // MARK: - Properties

    /// Whether playback is currently active.
    ///
    /// `true` when Music.app's player state is "playing", `false` when paused or stopped.
    let isPlaying: Bool

    /// The currently loaded song, if available.
    ///
    /// This is `nil` when:
    /// - No song is loaded in Music.app
    /// - Song couldn't be found in Apple Music catalog (local files)
    /// - Music.app is not running
    let currentSong: Song?

    /// The current playback position in seconds.
    ///
    /// Range: 0 to ``duration`` (if duration is available)
    ///
    /// - Note: Currently not actively updated in the app - reserved for future functionality.
    let playbackTime: TimeInterval

    /// The total duration of the current song in seconds, if known.
    ///
    /// This is `nil` when:
    /// - No song is loaded
    /// - Duration information isn't available yet
    let duration: TimeInterval?

    // MARK: - Computed Properties

    /// The playback progress as a value from 0.0 to 1.0.
    ///
    /// Calculation: `playbackTime / duration`
    ///
    /// Returns `0` when:
    /// - Duration is `nil`
    /// - Duration is zero (to avoid division by zero)
    ///
    /// ## Usage Example
    ///
    /// ```swift
    /// let state = PlaybackState(isPlaying: true, currentSong: song,
    ///                           playbackTime: 60, duration: 240)
    /// let percentage = state.progress * 100  // 25.0%
    ///
    /// // Use in progress bar
    /// ProgressView(value: state.progress)
    /// ```
    var progress: Double {
        guard let duration = duration, duration > 0 else { return 0 }
        return playbackTime / duration
    }

    /// Whether a song is currently loaded (regardless of playing state).
    ///
    /// Returns `true` if ``currentSong`` is not `nil`, `false` otherwise.
    ///
    /// This is useful for:
    /// - Enabling/disabling UI controls
    /// - Showing/hiding song information
    /// - Determining if any song is in the player
    ///
    /// ## Difference from `isPlaying`
    ///
    /// - `hasActiveSong`: Song is loaded (could be paused)
    /// - ``isPlaying``: Song is loaded AND currently playing
    ///
    /// ## Usage Example
    ///
    /// ```swift
    /// if state.hasActiveSong {
    ///     // Show song title, artwork, etc.
    ///     Text(state.currentSong?.title ?? "")
    /// } else {
    ///     // Show "No song playing" message
    ///     Text("Nothing playing")
    /// }
    /// ```
    var hasActiveSong: Bool {
        return currentSong != nil
    }
}

// MARK: - Default State

extension PlaybackState {

    /// A default empty playback state with no song and all values cleared.
    ///
    /// Use this for initialization or to represent the "nothing playing" state.
    ///
    /// ## Properties
    ///
    /// - `isPlaying`: `false`
    /// - `currentSong`: `nil`
    /// - `playbackTime`: `0`
    /// - `duration`: `nil`
    ///
    /// ## Usage Example
    ///
    /// ```swift
    /// // Initialize with empty state
    /// @State private var playbackState = PlaybackState.empty
    ///
    /// // Reset to empty state
    /// playbackState = .empty
    ///
    /// // Check if state is empty
    /// if !playbackState.hasActiveSong {
    ///     playbackState = .empty  // Already empty
    /// }
    /// ```
    static let empty = PlaybackState(
        isPlaying: false,
        currentSong: nil,
        playbackTime: 0,
        duration: nil
    )
}
