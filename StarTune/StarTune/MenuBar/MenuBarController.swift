//
//  MenuBarController.swift
//  StarTune
//
//  Created on 2025-10-24.
//

import AppKit
import Combine
import SwiftUI

/// Controller für das Menu Bar Icon und Interaktionen
class MenuBarController: ObservableObject {
    private var statusItem: NSStatusItem?
    @Published var isPlaying = false
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Setup

    init() {
        setupMenuBar()
        setupIconUpdates()
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
            accessibilityDescription: String(localized: "Favorite Current Song")
        )

        // Initial: Grau (nicht playing)
        button.contentTintColor = .systemGray

        // Tooltip
        button.toolTip = String(localized: "StarTune - Click to favorite current song")

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

    // Lazy cached menu - created once and reused
    private lazy var contextMenu: NSMenu = {
        let menu = NSMenu()

        let aboutItem = NSMenuItem(
            title: String(localized: "About StarTune"),
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(
            title: String(localized: "Quit StarTune"),
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }()

    private func showContextMenu() {
        statusItem?.menu = contextMenu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil  // Menu nach Anzeige wieder entfernen
    }

    @objc private func showAbout() {
        // TODO: About Window anzeigen
        print("About StarTune")
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Icon Updates

    /// Setup throttled icon updates using Combine
    private func setupIconUpdates() {
        // Throttle icon updates to max 10 per second (100ms interval)
        $isPlaying
            .throttle(for: .milliseconds(100), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] isPlaying in
                self?.updateIconImmediate(isPlaying: isPlaying)
            }
            .store(in: &cancellables)
    }

    /// Aktualisiert das Icon basierend auf Playback Status
    func updateIcon(isPlaying: Bool) {
        // Just update the published property
        // Throttled update happens automatically via $isPlaying publisher
        self.isPlaying = isPlaying
    }

    /// Immediate icon update (called by throttled publisher)
    private func updateIconImmediate(isPlaying: Bool) {
        statusItem?.button?.contentTintColor = isPlaying ? .systemYellow : .systemGray

        // Tooltip aktualisieren
        if isPlaying {
            statusItem?.button?.toolTip = String(
                localized: "Click to favorite current song")
        } else {
            statusItem?.button?.toolTip = String(localized: "No music playing")
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
        // Success notifications using Combine
        NotificationCenter.default.publisher(for: .favoriteSuccess)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.showSuccessAnimation()
            }
            .store(in: &cancellables)

        // Error notifications using Combine
        NotificationCenter.default.publisher(for: .favoriteError)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.showErrorAnimation()
            }
            .store(in: &cancellables)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let addToFavorites = Notification.Name("addToFavorites")
    static let favoriteSuccess = Notification.Name("favoriteSuccess")
    static let favoriteError = Notification.Name("favoriteError")
}
