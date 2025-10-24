//
//  AppSettings.swift
//  StarTune
//
//  Created on 2025-10-24.
//

import Foundation

/// User Preferences und App Settings
class AppSettings: ObservableObject {
    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
        }
    }

    @Published var showNotifications: Bool {
        didSet {
            UserDefaults.standard.set(showNotifications, forKey: "showNotifications")
        }
    }

    @Published var keyboardShortcutEnabled: Bool {
        didSet {
            UserDefaults.standard.set(keyboardShortcutEnabled, forKey: "keyboardShortcutEnabled")
        }
    }

    init() {
        self.launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
        self.showNotifications = UserDefaults.standard.bool(forKey: "showNotifications")
        self.keyboardShortcutEnabled = UserDefaults.standard.bool(forKey: "keyboardShortcutEnabled")
    }
}

// MARK: - UserDefaults Keys

extension UserDefaults {
    private enum Keys {
        static let launchAtLogin = "launchAtLogin"
        static let showNotifications = "showNotifications"
        static let keyboardShortcutEnabled = "keyboardShortcutEnabled"
    }
}
