//
//  AppSettings.swift
//  StarTune
//
//  Created on 2025-10-24.
//

import Foundation
import Combine

/// User preferences and app settings with automatic UserDefaults persistence.
///
/// `AppSettings` is an `ObservableObject` that manages user-configurable preferences
/// for the StarTune app. All settings automatically persist to UserDefaults and
/// trigger UI updates when changed.
///
/// ## Overview
///
/// This class provides a reactive settings layer using Combine:
/// - `@Published` properties notify observers of changes
/// - `didSet` observers automatically persist changes to UserDefaults
/// - SwiftUI views can bind directly to these properties
///
/// ## Architecture Pattern
///
/// ```
/// User changes setting in UI
///     ↓
/// @Published property updates
///     ↓
/// didSet triggers → UserDefaults.standard.set(...)
///     ↓
/// SwiftUI views auto-refresh (via @Published)
/// ```
///
/// ## Current Status
///
/// ⚠️ **Currently Unused**: These settings exist but no UI is implemented yet.
/// V1.0 of the app doesn't have a settings window.
///
/// ## Planned Features
///
/// - **Launch at Login**: Auto-start StarTune when user logs in
/// - **Show Notifications**: Display system notifications when favoriting songs
/// - **Keyboard Shortcut**: Global hotkey to favorite current song (Cmd+Shift+F)
///
/// ## Usage Example
///
/// ```swift
/// // In a settings window (future feature)
/// @StateObject private var settings = AppSettings()
///
/// Toggle("Launch at Login", isOn: $settings.launchAtLogin)
/// Toggle("Show Notifications", isOn: $settings.showNotifications)
/// Toggle("Enable Keyboard Shortcut", isOn: $settings.keyboardShortcutEnabled)
/// ```
///
/// ## Persistence
///
/// Settings persist to `UserDefaults.standard` using string keys defined in
/// the private `Keys` enum. Values are loaded during initialization and saved
/// automatically on every change.
///
/// ## Default Values
///
/// All settings default to `false` if not previously set (per UserDefaults behavior).
/// To change defaults, modify the `init()` method to use `UserDefaults.object(forKey:)`
/// and provide fallback values.
///
/// - SeeAlso: `ObservableObject` for the Combine integration pattern
class AppSettings: ObservableObject {

    // MARK: - Published Properties

    /// Whether the app should automatically launch when the user logs in.
    ///
    /// When enabled, StarTune will:
    /// - Start automatically at login
    /// - Appear in the menu bar immediately
    /// - Begin monitoring playback
    ///
    /// ## Implementation Notes
    ///
    /// Actual "launch at login" functionality requires:
    /// 1. ServiceManagement framework (`SMLoginItemSetEnabled`)
    /// 2. A helper app in the main app bundle
    /// 3. Or using Login Items in System Preferences
    ///
    /// Currently, this setting is stored but not yet implemented.
    ///
    /// - Note: Default value is `false` (doesn't launch at login)
    @Published var launchAtLogin: Bool {
        didSet {
            // Persist to UserDefaults immediately on change
            UserDefaults.standard.set(launchAtLogin, forKey: Keys.launchAtLogin)
        }
    }

    /// Whether to show system notifications when favoriting songs.
    ///
    /// When enabled, the app will display macOS notifications:
    /// - **Success**: "Added [Song Name] to favorites ✅"
    /// - **Error**: "[Error message] ⚠️"
    ///
    /// ## Requirements
    ///
    /// Notifications require:
    /// - User to grant notification permission in System Preferences
    /// - `UNUserNotificationCenter` API
    /// - `NSUserNotificationCenter` for macOS 10.14 and earlier (deprecated)
    ///
    /// - Note: Default value is `false` (no notifications)
    @Published var showNotifications: Bool {
        didSet {
            UserDefaults.standard.set(showNotifications, forKey: Keys.showNotifications)
        }
    }

    /// Whether the global keyboard shortcut is enabled.
    ///
    /// When enabled, the user can press **Cmd+Shift+F** from any app to
    /// favorite the currently playing song without opening the menu bar.
    ///
    /// ## Implementation Notes
    ///
    /// Global keyboard shortcuts require:
    /// - Accessibility permission in System Preferences
    /// - Carbon Event Manager API or modern Swift libraries
    /// - Careful conflict management (not interfering with other apps)
    ///
    /// Planned shortcut: **⌘⇧F** (Command+Shift+F)
    ///
    /// - Note: Default value is `false` (shortcut disabled)
    @Published var keyboardShortcutEnabled: Bool {
        didSet {
            UserDefaults.standard.set(keyboardShortcutEnabled, forKey: Keys.keyboardShortcutEnabled)
        }
    }

    // MARK: - Private Types

    /// UserDefaults keys for settings persistence.
    ///
    /// Using an enum for keys provides:
    /// - Compile-time safety (no typos in string literals)
    /// - Centralized key management
    /// - Easy refactoring (change key in one place)
    ///
    /// ## Naming Convention
    ///
    /// Keys use camelCase matching the property names for consistency.
    private enum Keys {
        static let launchAtLogin = "launchAtLogin"
        static let showNotifications = "showNotifications"
        static let keyboardShortcutEnabled = "keyboardShortcutEnabled"
    }

    // MARK: - Initialization

    /// Creates an AppSettings instance and loads saved values from UserDefaults.
    ///
    /// The initializer:
    /// 1. Loads each setting from UserDefaults
    /// 2. Falls back to `false` if key doesn't exist (first launch)
    /// 3. Assigns loaded values to properties
    ///
    /// ## Default Values
    ///
    /// All settings default to `false` on first launch. To change defaults,
    /// use the `object(forKey:)` method to detect if the key exists:
    ///
    /// ```swift
    /// self.showNotifications = UserDefaults.standard.object(forKey: Keys.showNotifications) as? Bool ?? true
    /// ```
    ///
    /// ## Property Observers
    ///
    /// The `didSet` observers on properties are NOT triggered during initialization,
    /// so UserDefaults isn't written unnecessarily when loading existing values.
    init() {
        // Load settings from UserDefaults, defaulting to false if not set
        self.launchAtLogin = UserDefaults.standard.bool(forKey: Keys.launchAtLogin)
        self.showNotifications = UserDefaults.standard.bool(forKey: Keys.showNotifications)
        self.keyboardShortcutEnabled = UserDefaults.standard.bool(forKey: Keys.keyboardShortcutEnabled)
    }
}
