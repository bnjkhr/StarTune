//
//  MenuBarController.swift
//  StarTune
//
//  Created on 2025-10-24.
//

import AppKit
import SwiftUI

/// Controller für das Menu Bar Icon und Interaktionen
class MenuBarController: ObservableObject {
    private var statusItem: NSStatusItem?
    @Published var isPlaying = false

    // MARK: - Setup

    init() {
        setupMenuBar()
        observeFavoriteNotifications()
    }

    private func setupMenuBar() {
        // Status Item in Menu Bar erstellen
        statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.squareLength
        )

        guard let button = statusItem?.button else { return }

        // SF Symbol Icon
        button.image = NSImage(
            systemSymbolName: "star.fill",
            accessibilityDescription: "Favorite Current Song"
        )

        // Initial: Grau (nicht playing)
        button.contentTintColor = .systemGray

        // Tooltip
        button.toolTip = "StarTune - Click to favorite current song"

        // Action beim Klick
        button.action = #selector(menuBarButtonClicked)
        button.target = self

        // Right-Click für Menü (optional)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    // MARK: - Actions

    @objc private func menuBarButtonClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent

        if event?.type == .rightMouseUp {
            // Right-Click: Zeige Kontext-Menü (für zukünftige Features)
            showContextMenu()
        } else {
            // Left-Click: Favorit hinzufügen
            addCurrentSongToFavorites()
        }
    }

    private func addCurrentSongToFavorites() {
        // Notification senden → wird von App aufgefangen
        NotificationCenter.default.post(
            name: .addToFavorites,
            object: nil
        )
    }

    private func showContextMenu() {
        let menu = NSMenu()

        let aboutItem = NSMenuItem(
            title: "About StarTune",
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(
            title: "Quit StarTune",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil // Menu nach Anzeige wieder entfernen
    }

    @objc private func showAbout() {
        // TODO: About Window anzeigen
        print("About StarTune")
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Icon Updates

    /// Aktualisiert das Icon basierend auf Playback Status
    func updateIcon(isPlaying: Bool) {
        self.isPlaying = isPlaying

        DispatchQueue.main.async { [weak self] in
            self?.statusItem?.button?.contentTintColor = isPlaying ? .systemYellow : .systemGray

            // Tooltip aktualisieren
            if isPlaying {
                self?.statusItem?.button?.toolTip = "Click to favorite current song"
            } else {
                self?.statusItem?.button?.toolTip = "No music playing"
            }
        }
    }

    /// Zeigt eine Erfolgs-Animation
    func showSuccessAnimation() {
        // TODO: Animation implementieren (z.B. kurzes Pulse)
        DispatchQueue.main.async { [weak self] in
            // Temporär Icon grün färben
            self?.statusItem?.button?.contentTintColor = .systemGreen

            // Nach 0.5 Sekunden zurück zu normal
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.updateIcon(isPlaying: self?.isPlaying ?? false)
            }
        }
    }

    /// Zeigt eine Fehler-Indication
    func showErrorAnimation() {
        DispatchQueue.main.async { [weak self] in
            // Temporär Icon rot färben
            self?.statusItem?.button?.contentTintColor = .systemRed

            // Nach 0.5 Sekunden zurück zu normal
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.updateIcon(isPlaying: self?.isPlaying ?? false)
            }
        }
    }

    // MARK: - Notifications

    private func observeFavoriteNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(favoriteSuccess),
            name: .favoriteSuccess,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(favoriteError),
            name: .favoriteError,
            object: nil
        )
    }

    @objc private func favoriteSuccess() {
        showSuccessAnimation()
    }

    @objc private func favoriteError() {
        showErrorAnimation()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let addToFavorites = Notification.Name("addToFavorites")
    static let favoriteSuccess = Notification.Name("favoriteSuccess")
    static let favoriteError = Notification.Name("favoriteError")
}
