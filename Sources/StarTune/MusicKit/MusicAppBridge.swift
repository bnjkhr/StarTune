//
//  MusicAppBridge.swift
//  StarTune
//
//  Created on 2025-10-24.
//

import Foundation
import ScriptingBridge
import MusicKit

/// Bridge zur Music.app via ScriptingBridge
/// Diese Klasse ermöglicht den Zugriff auf den aktuell spielenden Song der System Music.app
@MainActor
class MusicAppBridge: ObservableObject {
    @Published var currentTrackName: String?
    @Published var currentArtist: String?
    @Published var isPlaying = false

    private var musicApp: SBApplication?

    init() {
        // Verbindung zur Music.app herstellen
        if let app = SBApplication(bundleIdentifier: "com.apple.Music") {
            self.musicApp = app
        }
    }

    /// Aktualisiert den Playback Status aus Music.app
    func updatePlaybackState() {
        guard musicApp != nil else {
            isPlaying = false
            currentTrackName = nil
            currentArtist = nil
            return
        }

        // Player State abrufen via AppleScript
        let script = """
        tell application "Music"
            if it is running then
                if player state is playing then
                    set trackName to name of current track
                    set trackArtist to artist of current track
                    return trackName & "|" & trackArtist & "|playing"
                else
                    return "||paused"
                end if
            else
                return "||stopped"
            end if
        end tell
        """

        if let result = runAppleScript(script) {
            let parts = result.split(separator: "|", maxSplits: 2, omittingEmptySubsequences: false)

            if parts.count >= 3 {
                let name = String(parts[0])
                let artist = String(parts[1])
                let state = String(parts[2])

                currentTrackName = name.isEmpty ? nil : name
                currentArtist = artist.isEmpty ? nil : artist
                isPlaying = (state == "playing")
            } else {
                isPlaying = false
                currentTrackName = nil
                currentArtist = nil
            }
        }
    }

    /// Holt die aktuelle Track ID für MusicKit
    func getCurrentTrackID() -> String? {
        let script = """
        tell application "Music"
            if it is running and player state is playing then
                try
                    get persistent ID of current track
                on error
                    return ""
                end try
            else
                return ""
            end if
        end tell
        """

        return runAppleScript(script)
    }

    /// Führt ein AppleScript aus und gibt das Ergebnis zurück
    private func runAppleScript(_ source: String) -> String? {
        var error: NSDictionary?

        if let scriptObject = NSAppleScript(source: source) {
            let output = scriptObject.executeAndReturnError(&error)

            if let error = error {
                print("AppleScript Error: \(error)")
                return nil
            }

            return output.stringValue
        }

        return nil
    }

    /// Gibt formatierte Track-Info zurück
    var currentTrackInfo: String? {
        guard let name = currentTrackName else { return nil }
        if let artist = currentArtist {
            return "\(name) - \(artist)"
        }
        return name
    }
}
