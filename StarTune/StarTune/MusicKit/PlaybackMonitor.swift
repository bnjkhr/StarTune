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
    /// Note: Monitoring is resilient to errors - continues even if initial state load fails
    /// Errors are handled gracefully by nested methods
    func startMonitoring() async {
        print("🎵 Starting playback monitoring...")

        // Timer für regelmäßige Updates (alle 2 Sekunden)
        startTimer()

        // Initialen Status laden - resilient to errors
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
        // Errors are handled inside findSongInCatalog
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
            // Hol den Track ID vor dem Suchen
            let trackID = musicBridge.getCurrentTrackID()
            
            // Suchanfrage erstellen
            var searchTerm = trackName
            if let artist = artist {
                searchTerm += " \(artist)"
            }

            print("🔍 Searching MusicKit catalog for: \(searchTerm)")

            var searchRequest = MusicCatalogSearchRequest(term: searchTerm, types: [Song.self])
            searchRequest.limit = 5

            let response = try await searchRequest.response()

            // Erst versuchen mit Track ID exakt zu matchen
            var matchedSong: Song?
            
            if let trackID = trackID, !trackID.isEmpty {
                print("🔑 Looking for exact match with track ID: \(trackID)")
                matchedSong = response.songs.first { $0.id.rawValue == trackID }
                
                if matchedSong != nil {
                    print("✅ Found exact match by track ID")
                }
            }
            
            // Falls keine ID-Match oder keine Track ID verfügbar, fallback zu strenger Attribut-Vergleich
            if matchedSong == nil {
                print("🔎 No exact ID match, trying attribute-based matching...")
                matchedSong = findBestMatchingSong(
                    in: response.songs,
                    title: trackName,
                    artist: artist
                )
            }
            
            if let song = matchedSong {
                currentSong = song
                print("✅ Found song: \(song.title) by \(song.artistName)")

                // Favorite-Status prüfen
                await checkFavoriteStatus(for: song)
            } else {
                print("⚠️ No song found in catalog for: \(searchTerm)")
                currentSong = nil
                isFavorited = false
            }
        } catch {
            print("❌ Error searching for song: \(error.localizedDescription)")
            print("⚠️ This may occur if MusicKit authorization is not granted")
            // Non-fatal: continue without current song
            currentSong = nil
            isFavorited = false
            // Don't abort playback monitoring - app can still function
        }
    }
    
    /// Findet den besten passenden Song basierend auf mehreren Attributen
    private func findBestMatchingSong(in songs: MusicItemCollection<Song>, title: String, artist: String?) -> Song? {
        guard !songs.isEmpty else { return nil }
        
        var bestMatch: Song?
        var bestScore: Double = 0
        
        for song in songs {
            var score: Double = 0
            
            // Titel vergleichen (normalisiert)
            let normalizedTitle = title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedSongTitle = song.title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            
            if normalizedTitle == normalizedSongTitle {
                score += 3
            } else if normalizedSongTitle.contains(normalizedTitle) || normalizedTitle.contains(normalizedSongTitle) {
                score += 1
            }
            
            // Artist vergleichen (normalisiert)
            if let artist = artist {
                let normalizedArtist = artist.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                let normalizedSongArtist = song.artistName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                
                if normalizedArtist == normalizedSongArtist {
                    score += 2
                } else if normalizedSongArtist.contains(normalizedArtist) || normalizedArtist.contains(normalizedSongArtist) {
                    score += 1
                }
            } else {
                // Wenn kein Artist angegeben, keine Änderung der Punktzahl
            }
            
            // Album Bonus (wenn verfügbar)
            if song.albumTitle != nil {
                score += 0.5
            }
            
            // Duration Bonus (wenn verfügbar)
            if song.duration != nil {
                score += 0.5
            }
            
            if score > bestScore {
                bestScore = score
                bestMatch = song
            }
        }
        
        if bestScore > 0 {
            print("🏆 Best matching song with score: \(bestScore)")
            return bestMatch
        }
        
        return nil
    }

    /// Prüft den Favorite-Status für einen Song
    /// Resilient to authorization failures - only checks if possible
    private func checkFavoriteStatus(for song: Song) async {
        do {
            let favorited = try await favoritesService.isFavorited(song: song)
            isFavorited = favorited
        } catch {
            // Non-fatal: log warning but don't abort
            print("⚠️ Could not check favorite status: \(error.localizedDescription)")
            print("⚠️ Note: This may occur if MusicKit authorization is not granted")
            isFavorited = false
            // Continue without favorite status - app can still function
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
