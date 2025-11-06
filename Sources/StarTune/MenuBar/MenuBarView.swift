//
//  MenuBarView.swift
//  StarTune
//
//  Created on 2025-10-24.
//

import SwiftUI
import MusicKit

/// SwiftUI View für Menu Bar Extra Content
struct MenuBarView: View {
    @ObservedObject var musicKitManager: MusicKitManager
    @ObservedObject var playbackMonitor: PlaybackMonitor

    @State private var isProcessing = false

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
            Button("Quit StarTune") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding()
        .frame(width: 300)
    }

    // MARK: - Sections

    private var authorizationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Authorization Required")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button("Allow Access to Apple Music") {
                Task {
                    await musicKitManager.requestAuthorization()
                }
            }
        }
    }

    private var currentlyPlayingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Now Playing")
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
                Text("No music playing")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            // Playback Status Indicator
            HStack {
                Circle()
                    .fill(playbackMonitor.isPlaying ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)

                Text(playbackMonitor.isPlaying ? "Playing" : "Paused")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var actionsSection: some View {
        VStack(spacing: 8) {
            // Favorite Button
            Button(action: addToFavorites) {
                HStack {
                    Image(systemName: "star.fill")
                    Text("Add to Favorites")
                }
                .frame(maxWidth: .infinity)
            }
            .disabled(!playbackMonitor.hasSongPlaying || isProcessing)
            .buttonStyle(.borderedProminent)

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
                let success = try await FavoritesService.shared.addToFavorites(song: song)

                await MainActor.run {
                    isProcessing = false

                    if success {
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
}

// MARK: - Preview

#Preview {
    MenuBarView(
        musicKitManager: MusicKitManager(),
        playbackMonitor: PlaybackMonitor()
    )
}
