//
//  PlaybackMonitor.swift
//  StarTune
//
//  Created on 2025-10-24.
//

import Foundation
import MusicKit
import Combine

/// Überwacht den Apple Music Playback Status
@MainActor
class PlaybackMonitor: ObservableObject {
    @Published var currentSong: Song?
    @Published var isPlaying = false
    @Published var playbackTime: TimeInterval = 0

    private var stateObserver: AnyCancellable?
    private var queueObserver: AnyCancellable?
    private var timer: Timer?

    private let player = ApplicationMusicPlayer.shared

    // MARK: - Monitoring

    /// Startet das Monitoring des Playback Status
    func startMonitoring() async {
        // Initialen Status laden
        await updatePlaybackState()

        // Observer für State Changes
        observePlaybackState()
        observeQueue()

        // Timer für regelmäßige Updates (alle 2 Sekunden)
        startTimer()
    }

    /// Stoppt das Monitoring
    func stopMonitoring() {
        stateObserver?.cancel()
        queueObserver?.cancel()
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Private Helpers

    private func observePlaybackState() {
        stateObserver = player.state.objectWillChange.sink { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.updatePlaybackState()
            }
        }
    }

    private func observeQueue() {
        queueObserver = player.queue.objectWillChange.sink { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.updateCurrentSong()
            }
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.updatePlaybackState()
            }
        }
    }

    private func updatePlaybackState() async {
        // Playback Status aktualisieren
        isPlaying = (player.state.playbackStatus == .playing)
        playbackTime = player.playbackTime

        // Song aktualisieren
        await updateCurrentSong()
    }

    private func updateCurrentSong() async {
        // Aktuellen Song aus Queue holen
        guard let entry = player.queue.currentEntry else {
            currentSong = nil
            return
        }

        // Prüfen ob es ein Song ist
        switch entry.item {
        case .song(let song):
            currentSong = song
        default:
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
