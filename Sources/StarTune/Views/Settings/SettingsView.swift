//
//  SettingsView.swift
//  StarTune
//
//  Created on 2025-11-18.
//

import SwiftUI

/// A view that provides app settings, including the option to launch at login.
///
/// This view contains a toggle that allows users to enable or disable the app's
/// autostart functionality. The setting is persisted using `@AppStorage`.
struct SettingsView: View {
    /// Controls the "Launch at Login" setting, persisted in `UserDefaults`.
    ///
    /// When this property changes, the `AutoStartManager` is responsible for
    /// enabling or disabling the autostart functionality.
    @AppStorage("launchAtLogin") private var launchAtLogin = false

    /// The manager responsible for handling autostart logic.
    private let autoStartManager = AutoStartManager()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.title2)
                .fontWeight(.bold)

            // Launch at Login Toggle
            Toggle("Launch at Login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, newValue in
                    autoStartManager.setAutoStart(enabled: newValue)
                }

            Spacer()

            // Close Button
            HStack {
                Spacer()
                Button("Close") {
                    NSApplication.shared.keyWindow?.close()
                }
            }
        }
        .padding()
        .frame(width: 300, height: 150)
        .onAppear {
            // Sync the toggle with the actual autostart status on appear.
            launchAtLogin = autoStartManager.isAutoStartEnabled()
        }
    }
}

#Preview {
    SettingsView()
}
