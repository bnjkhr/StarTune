//
//  PlaybackMonitor.swift
//  StarTune
//
//  Created on 2025-10-24.
//

import Foundation
import MusicKit
import Combine

/// Überwacht den Apple Music Playback Status via Music.app
@MainActor
class PlaybackMonitor: ObservableObject {
    @Published var currentSong: Song?
    @Published var isPlaying = false
    @Published var playbackTime: TimeInterval = 0

    private var timer: Timer?
    private let musicBridge = MusicAppBridge()

    // MARK: - Monitoring

    /// Startet das Monitoring des Playback Status
    func startMonitoring() async {
        print("🎵 Starting playback monitoring...")

        // Timer für regelmäßige Updates (alle 2 Sekunden)
        startTimer()

        // Initialen Status laden
        await updatePlaybackState()
    }

    /// Stoppt das Monitoring
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Private Helpers

    private func startTimer() {
        // Only create a new timer if one doesn't already exist
        guard timer == nil else { return }

        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.updatePlaybackState()
            }
        }
    }

    private func updatePlaybackState() async {
        // Status aus Music.app via AppleScript abrufen
        musicBridge.updatePlaybackState()

        isPlaying = musicBridge.isPlaying

        // Wenn etwas spielt, versuche den Song in MusicKit zu finden
        if isPlaying, let trackName = musicBridge.currentTrackName {
            await findSongInCatalog(trackName: trackName, artist: musicBridge.currentArtist)
        } else {
            currentSong = nil
        }
    }

    /// Sucht den Song im MusicKit Catalog
    private func findSongInCatalog(trackName: String, artist: String?) async {
        do {
            // Suchanfrage erstellen
            var searchTerm = trackName
            if let artist = artist {
                searchTerm += " \(artist)"
            }

            var searchRequest = MusicCatalogSearchRequest(term: searchTerm, types: [Song.self])
            searchRequest.limit = 5

            let response = try await searchRequest.response()

            // Ersten passenden Song nehmen
            if let firstSong = response.songs.first {
                currentSong = firstSong
                print("✅ Found song: \(firstSong.title) by \(firstSong.artistName)")
            } else {
                print("⚠️ No song found for: \(searchTerm)")
                currentSong = nil
            }
        } catch {
            print("❌ Error searching for song: \(error.localizedDescription)")
            currentSong = nil
        }
    }

    // MARK: - Public Helpers

    /// Formatierte Song-Info für Display
    var currentSongInfo: String? {
        guard let song = currentSong else { return nil }
        return "\(song.title) - \(song.artistName)"
    }

    /// Prüft ob ein Song gerade läuft
    var hasSongPlaying: Bool {
        return isPlaying && currentSong != nil
    }
}
