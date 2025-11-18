//
//  AutoStartManager.swift
//  StarTune
//
//  Created on 2025-11-18.
//

import Foundation
import ServiceManagement

/// A manager that handles the app's autostart (launch at login) functionality.
///
/// This class provides methods to enable, disable, and check the autostart
/// status using the `ServiceManagement` framework.
class AutoStartManager {
    /// Enables or disables the autostart functionality.
    ///
    /// - Parameter enabled: A boolean indicating whether to enable or disable
    /// autostart.
    func setAutoStart(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to \(enabled ? "enable" : "disable") autostart: \(error.localizedDescription)")
        }
    }

    /// Checks if the autostart functionality is currently enabled.
    ///
    /// - Returns: A boolean indicating whether autostart is enabled.
    func isAutoStartEnabled() -> Bool {
        return SMAppService.mainApp.status == .enabled
    }
}
