//
//  PlaybackMonitor.swift
//  StarTune
//
//  Created on 2025-10-24.
//

import Combine
import Foundation
import MusicKit

/// Überwacht den Apple Music Playback Status via Music.app
@MainActor
class PlaybackMonitor: ObservableObject {
    @Published var currentSong: Song?
    @Published var isPlaying = false
    @Published var playbackTime: TimeInterval = 0
    @Published var isFavorited = false

    private var timer: Timer?
    private let musicBridge = MusicAppBridge()
    private let favoritesService = FavoritesService()

    // MARK: - Monitoring

    /// Startet das Monitoring des Playback Status
    func startMonitoring() async {
        print("🎵 Starting playback monitoring...")

        // Timer für regelmäßige Updates (alle 2 Sekunden)
        startTimer()

        // Initialen Status laden
        await updatePlaybackState()

        print("✅ Playback monitoring started")
    }

    /// Stoppt das Monitoring
    func stopMonitoring() {
        print("⏹️ Stopping playback monitoring...")
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Private Helpers

    private func startTimer() {
        print("⏱️ Starting timer (2s interval)...")
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.updatePlaybackState()
            }
        }
    }

    private func updatePlaybackState() async {
        // Status aus Music.app via AppleScript abrufen
        musicBridge.updatePlaybackState()

        let wasPlaying = isPlaying
        isPlaying = musicBridge.isPlaying

        // Log nur bei State-Änderung
        if wasPlaying != isPlaying {
            print("🔄 Playback state changed: \(isPlaying ? "PLAYING" : "STOPPED")")
        }

        // Wenn etwas spielt, versuche den Song in MusicKit zu finden
        if isPlaying, let trackName = musicBridge.currentTrackName {
            await findSongInCatalog(trackName: trackName, artist: musicBridge.currentArtist)
        } else {
            if currentSong != nil {
                print("🚫 No song playing, clearing currentSong")
            }
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

            print("🔍 Searching MusicKit catalog for: \(searchTerm)")

            var searchRequest = MusicCatalogSearchRequest(term: searchTerm, types: [Song.self])
            searchRequest.limit = 5

            let response = try await searchRequest.response()

            // Ersten passenden Song nehmen
            if let firstSong = response.songs.first {
                currentSong = firstSong
                print("✅ Found song: \(firstSong.title) by \(firstSong.artistName)")

                // Favorite-Status prüfen
                await checkFavoriteStatus(for: firstSong)
            } else {
                print("⚠️ No song found in catalog for: \(searchTerm)")
                currentSong = nil
                isFavorited = false
            }
        } catch {
            print("❌ Error searching for song: \(error.localizedDescription)")
            currentSong = nil
            isFavorited = false
        }
    }

    /// Prüft den Favorite-Status für einen Song
    private func checkFavoriteStatus(for song: Song) async {
        do {
            let favorited = try await favoritesService.isFavorited(song: song)
            isFavorited = favorited
        } catch {
            print("⚠️ Could not check favorite status: \(error.localizedDescription)")
            isFavorited = false
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
