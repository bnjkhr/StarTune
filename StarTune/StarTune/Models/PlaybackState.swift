//
//  PlaybackState.swift
//  StarTune
//
//  Created on 2025-10-24.
//

import Foundation
import MusicKit

/// Model für Playback State
struct PlaybackState {
    let isPlaying: Bool
    let currentSong: Song?
    let playbackTime: TimeInterval
    let duration: TimeInterval?

    var progress: Double {
        guard let duration = duration, duration > 0 else { return 0 }
        return playbackTime / duration
    }

    var hasActiveSong: Bool {
        return currentSong != nil
    }
}

// MARK: - Default State

extension PlaybackState {
    static let empty = PlaybackState(
        isPlaying: false,
        currentSong: nil,
        playbackTime: 0,
        duration: nil
    )
}
