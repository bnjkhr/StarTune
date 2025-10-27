//
//  AppSettings.swift
//  StarTune
//
//  Created on 2025-10-24.
//

import Foundation
import Combine

/// User Preferences und App Settings
@MainActor
class AppSettings: ObservableObject {
    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: Keys.launchAtLogin)
        }
    }

    @Published var showNotifications: Bool {
        didSet {
            UserDefaults.standard.set(showNotifications, forKey: Keys.showNotifications)
        }
    }

    @Published var keyboardShortcutEnabled: Bool {
        didSet {
            UserDefaults.standard.set(keyboardShortcutEnabled, forKey: Keys.keyboardShortcutEnabled)
        }
    }

    private enum Keys {
        static let launchAtLogin = "launchAtLogin"
        static let showNotifications = "showNotifications"
        static let keyboardShortcutEnabled = "keyboardShortcutEnabled"
    }

    init() {
        self.launchAtLogin = UserDefaults.standard.bool(forKey: Keys.launchAtLogin)
        self.showNotifications = UserDefaults.standard.bool(forKey: Keys.showNotifications)
        self.keyboardShortcutEnabled = UserDefaults.standard.bool(forKey: Keys.keyboardShortcutEnabled)
    }
}
