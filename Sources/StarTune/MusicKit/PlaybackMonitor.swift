//
//  PlaybackMonitor.swift
//  StarTune
//
//  Reactive playback monitoring using Combine and event-driven architecture
//  Replaces timer-based polling with NSDistributedNotificationCenter
//

import Foundation
import MusicKit
import Combine

/// Reactive playback monitor that combines Music.app events with MusicKit catalog
@MainActor
class PlaybackMonitor: ObservableObject {
    @Published var currentSong: Song?
    @Published var isPlaying = false
    @Published var playbackTime: TimeInterval = 0

    // Dependencies
    private let musicObserver = MusicObserver()
    private var cancellables = Set<AnyCancellable>()

    // Track the last search to avoid duplicate searches
    private var lastSearchedTrack: MusicObserver.TrackInfo?

    // MARK: - Lifecycle

    init() {
        setupReactiveBindings()
    }

    deinit {
        print("🧹 PlaybackMonitor deallocated - all publishers cancelled")
    }

    // MARK: - Reactive Setup

    private func setupReactiveBindings() {
        // Bind isPlaying state from MusicObserver
        musicObserver.$isPlaying
            .assign(to: &$isPlaying)

        // Bind playback time from MusicObserver
        musicObserver.$playbackTime
            .assign(to: &$playbackTime)

        // React to track changes with debouncing
        musicObserver.$currentTrack
            .compactMap { $0 } // Filter out nil values
            .removeDuplicates() // Only process actual changes
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main) // Debounce rapid changes
            .sink { [weak self] trackInfo in
                Task { [weak self] in
                    await self?.searchMusicKitCatalog(for: trackInfo)
                }
            }
            .store(in: &cancellables)

        // Clear song when playback stops
        musicObserver.$isPlaying
            .filter { !$0 } // Only when stopped
            .sink { [weak self] _ in
                self?.currentSong = nil
                self?.lastSearchedTrack = nil
            }
            .store(in: &cancellables)

        print("🎵 Reactive playback monitoring configured")
    }

    // MARK: - MusicKit Integration

    private func searchMusicKitCatalog(for trackInfo: MusicObserver.TrackInfo) async {
        // Avoid duplicate searches for the same track
        guard lastSearchedTrack != trackInfo else {
            return
        }
        lastSearchedTrack = trackInfo

        do {
            // Build search query
            let searchTerm = "\(trackInfo.name) \(trackInfo.artist)"

            var searchRequest = MusicCatalogSearchRequest(
                term: searchTerm,
                types: [Song.self]
            )
            searchRequest.limit = 5

            // Execute search
            let response = try await searchRequest.response()

            // Find best match
            if let song = findBestMatch(songs: response.songs, trackInfo: trackInfo) {
                currentSong = song
                print("✅ Found MusicKit song: \(song.title) by \(song.artistName)")
            } else {
                print("⚠️ No MusicKit match for: \(trackInfo.displayString)")
                currentSong = nil
            }
        } catch {
            print("❌ MusicKit search error: \(error.localizedDescription)")
            currentSong = nil
        }
    }

    // MARK: - Matching Logic

    private func findBestMatch(
        songs: MusicItemCollection<Song>,
        trackInfo: MusicObserver.TrackInfo
    ) -> Song? {
        // Try exact match first
        let exactMatch = songs.first { song in
            song.title.lowercased() == trackInfo.name.lowercased() &&
            song.artistName.lowercased() == trackInfo.artist.lowercased()
        }

        // Fallback to first result if no exact match
        return exactMatch ?? songs.first
    }

    // MARK: - Public API

    /// Start monitoring (automatically starts via init now)
    func startMonitoring() async {
        print("🎵 Event-driven playback monitoring active (no timer needed!)")
        // No timer needed! Everything is event-driven via MusicObserver
    }

    /// Stop monitoring
    func stopMonitoring() {
        cancellables.removeAll()
        lastSearchedTrack = nil
        print("⏹️ Playback monitoring stopped - all subscriptions cancelled")
    }

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
