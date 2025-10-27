//
//  MusicAppBridge.swift
//  StarTune
//
//  Created on 2025-10-24.
//

import Combine
import Foundation
import MusicKit
import ScriptingBridge

/// Bridge zur Music.app via ScriptingBridge
/// Diese Klasse ermöglicht den Zugriff auf den aktuell spielenden Song der System Music.app
@MainActor
class MusicAppBridge: ObservableObject {
    @Published var currentTrackName: String?
    @Published var currentArtist: String?
    @Published var isPlaying = false

    private var musicApp: SBApplication?

    init() {
        print("🎵 MusicAppBridge initializing...")
        // Verbindung zur Music.app herstellen
        if let app = SBApplication(bundleIdentifier: "com.apple.Music") {
            self.musicApp = app
            print("✅ Connected to Music.app")
        } else {
            print("⚠️ Could not connect to Music.app")
        }
    }

    /// Aktualisiert den Playback Status aus Music.app
    func updatePlaybackState() {
        guard musicApp != nil else {
            print("❌ No Music.app connection")
            isPlaying = false
            currentTrackName = nil
            currentArtist = nil
            return
        }

        // Direkter Zugriff auf Music.app ohne vorherigen Check
        // Der "try" Block fängt alle Fehler ab (auch wenn nicht läuft)
        let script = """
            tell application "Music"
                try
                    if it is running then
                        if player state is playing then
                            set trackName to name of current track
                            set trackArtist to artist of current track
                            return trackName & "|" & trackArtist & "|playing"
                        else if player state is paused then
                            return "||paused"
                        else
                            return "||stopped"
                        end if
                    else
                        return "||notrunning"
                    end if
                on error errMsg
                    return "||error:" & errMsg
                end try
            end tell
            """

        if let result = runAppleScript(script) {
            print("📝 AppleScript result: '\(result)'")

            let parts = result.split(separator: "|", maxSplits: 2, omittingEmptySubsequences: false)

            if parts.count >= 3 {
                let name = String(parts[0])
                let artist = String(parts[1])
                let state = String(parts[2])

                if state.starts(with: "error:") {
                    print("❌ AppleScript error in Music.app: \(state)")
                    isPlaying = false
                    currentTrackName = nil
                    currentArtist = nil
                    return
                }

                currentTrackName = name.isEmpty ? nil : name
                currentArtist = artist.isEmpty ? nil : artist
                isPlaying = (state == "playing")

                if isPlaying {
                    print("🎵 Now playing: \(name) - \(artist)")
                } else if state == "paused" {
                    print("⏸️ Music paused")
                } else if state == "stopped" {
                    print("⏹️ Music stopped")
                } else if state == "notrunning" {
                    print("ℹ️ Music.app not running")
                }
            } else {
                print("⚠️ Unexpected AppleScript result format: \(result)")
                isPlaying = false
                currentTrackName = nil
                currentArtist = nil
            }
        } else {
            print("❌ AppleScript returned nil")
            isPlaying = false
            currentTrackName = nil
            currentArtist = nil
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
                let errorNumber = error["NSAppleScriptErrorNumber"] as? Int ?? 0
                let errorMessage = error["NSAppleScriptErrorMessage"] as? String ?? "Unknown error"

                // Log alle Fehler für Debugging
                print("⚠️ AppleScript Error \(errorNumber): \(errorMessage)")

                return nil
            }

            return output.stringValue
        }

        print("❌ Could not create NSAppleScript object")
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
