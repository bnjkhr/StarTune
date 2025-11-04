//
//  MenuBarView.swift
//  StarTune
//
//  Created on 2025-10-24.
//

import MusicKit
import SwiftUI

/// SwiftUI View für Menu Bar Extra Content
@MainActor
struct MenuBarView: View {
    @ObservedObject var musicKitManager: MusicKitManager
    @ObservedObject var playbackMonitor: PlaybackMonitor

    let appDelegate: AppDelegate

    @State private var favoritesService = FavoritesService()
    @State private var isProcessing = false
    @State private var hasSetupRun = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Text("StarTune")
                .font(.headline)

            Divider()

            // Authorization Status
            if !musicKitManager.isAuthorized {
                authorizationSection
            } else {
                // Currently Playing Info
                currentlyPlayingSection

                Divider()

                // Actions
                actionsSection
            }

            Divider()

            // Quit Button
            Button(String(localized: "Quit StarTune")) {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding()
        .frame(width: 300)
        .onAppear {
            // Trigger setup only once when view appears and StateObjects are guaranteed ready
            if !hasSetupRun {
                hasSetupRun = true
                appDelegate.performSetupIfNeeded()
            }

            // Listen for favorite requests from MenuBarController
            NotificationCenter.default.addObserver(
                forName: .addToFavorites,
                object: nil,
                queue: .main
            ) { [self] _ in
                self.addToFavorites()
            }
        }
        .onDisappear {
            // Clean up notification observer
            NotificationCenter.default.removeObserver(self, name: .addToFavorites, object: nil)
        }
    }

    // MARK: - Sections

    private var authorizationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Authorization Required"))
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button(String(localized: "Allow Access to Apple Music")) {
                Task {
                    await musicKitManager.requestAuthorization()
                }
            }
        }
    }

    private var currentlyPlayingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Now Playing"))
                .font(.caption)
                .foregroundColor(.secondary)

            if let song = playbackMonitor.currentSong {
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title)
                        .font(.body)
                        .lineLimit(1)

                    Text(song.artistName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    if let albumTitle = song.albumTitle {
                        Text(albumTitle)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            } else {
                Text(String(localized: "No music playing"))
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            // Playback Status Indicator
            HStack {
                Circle()
                    .fill(playbackMonitor.isPlaying ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)

                Text(String(localized: playbackMonitor.isPlaying ? "Playing" : "Paused"))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var actionsSection: some View {
        VStack(spacing: 8) {
            // Favorite Button - zeigt verschiedene States
            if playbackMonitor.isFavorited {
                // Song ist bereits favorisiert
                Button(action: removeFromFavorites) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(String(localized: "Remove from Favorites"))
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(!playbackMonitor.hasSongPlaying || isProcessing)
                .buttonStyle(.bordered)
            } else {
                // Song noch nicht favorisiert
                Button(action: addToFavorites) {
                    HStack {
                        Image(systemName: "star")
                        Text(String(localized: "Add to Favorites"))
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(!playbackMonitor.hasSongPlaying || isProcessing)
                .buttonStyle(.borderedProminent)
            }

            if isProcessing {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
    }

    // MARK: - Actions

    private func addToFavorites() {
        guard let song = playbackMonitor.currentSong else { return }

        isProcessing = true

        Task {
            do {
                let success = try await favoritesService.addToFavorites(song: song)

                await MainActor.run {
                    isProcessing = false

                    if success {
                        // Status aktualisieren
                        playbackMonitor.isFavorited = true

                        // Success Notification
                        NotificationCenter.default.post(
                            name: .favoriteSuccess,
                            object: nil
                        )
                    } else {
                        // Error Notification
                        NotificationCenter.default.post(
                            name: .favoriteError,
                            object: nil
                        )
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    NotificationCenter.default.post(
                        name: .favoriteError,
                        object: nil
                    )
                    print("Error adding to favorites: \(error.localizedDescription)")
                }
            }
        }
    }

    private func removeFromFavorites() {
        guard let song = playbackMonitor.currentSong else { return }

        isProcessing = true

        Task {
            do {
                let success = try await favoritesService.removeFromFavorites(song: song)

                await MainActor.run {
                    isProcessing = false

                    if success {
                        // Status aktualisieren
                        playbackMonitor.isFavorited = false

                        print("✅ Successfully removed '\(song.title)' from favorites")

                        // Success Notification
                        NotificationCenter.default.post(
                            name: .favoriteSuccess,
                            object: nil
                        )
                    } else {
                        // Error Notification
                        NotificationCenter.default.post(
                            name: .favoriteError,
                            object: nil
                        )
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    NotificationCenter.default.post(
                        name: .favoriteError,
                        object: nil
                    )
                    print("Error removing from favorites: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MenuBarView(
        musicKitManager: MusicKitManager(),
        playbackMonitor: PlaybackMonitor(),
        appDelegate: AppDelegate()
    )
}
