//
//  AutoStartManager.swift
//  StarTune
//
//  Created on 2025-11-18.
//

import Foundation
import ServiceManagement

/// Manages the app's autostart functionality using ServiceManagement.
///
/// This manager provides methods to enable, disable, and check the autostart status.
/// It uses the modern `SMAppService.mainApp` API available in macOS 13.0+.
class AutoStartManager {

    /// Enables or disables autostart for the app.
    /// - Parameter enabled: `true` to enable autostart, `false` to disable it.
    func setAutoStart(enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status == .enabled {
                    print("✅ Autostart is already enabled")
                } else {
                    try SMAppService.mainApp.register()
                    print("✅ Successfully enabled autostart")
                }
            } else {
                try SMAppService.mainApp.unregister()
                print("✅ Successfully disabled autostart")
            }
        } catch {
            print("❌ Failed to set autostart: \(error.localizedDescription)")
        }
    }

    /// Checks if autostart is currently enabled.
    /// - Returns: `true` if autostart is enabled, `false` otherwise.
    func isAutoStartEnabled() -> Bool {
        return SMAppService.mainApp.status == .enabled
    }
}
