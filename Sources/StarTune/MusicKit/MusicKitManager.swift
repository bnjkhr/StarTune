//
//  MusicKitManager.swift
//  StarTune
//
//  Created on 2025-10-24.
//

import Foundation
import MusicKit
import Combine

/// Manager für MusicKit Authorization und Status
@MainActor
class MusicKitManager: ObservableObject {
    @Published var isAuthorized = false
    @Published var authorizationStatus: MusicAuthorization.Status = .notDetermined
    @Published var hasAppleMusicSubscription = false

    // MARK: - Initialization

    init() {
        // Aktuellen Authorization Status prüfen
        updateAuthorizationStatus()
    }

    // MARK: - Authorization

    /// Fragt User nach MusicKit Berechtigung
    func requestAuthorization() async {
        let status = await MusicAuthorization.request()
        updateAuthorizationStatus()

        if status == .authorized {
            await checkSubscriptionStatus()
        }
    }

    /// Aktualisiert den internen Authorization Status
    private func updateAuthorizationStatus() {
        let currentStatus = MusicAuthorization.currentStatus
        authorizationStatus = currentStatus
        isAuthorized = (currentStatus == .authorized)
    }

    /// Prüft ob User ein Apple Music Abo hat mit Retry-Logik
    private func checkSubscriptionStatus() async {
        do {
            // MusicSubscription Status abfragen mit Retry-Logik
            let subscription = try await RetryManager.shared.retryNetwork(
                operationName: "checkSubscription"
            ) {
                try await MusicSubscription.current
            }
            hasAppleMusicSubscription = subscription.canPlayCatalogContent
        } catch {
            let appError = AppError.from(error)
            recordError(
                appError,
                operation: "checkSubscription",
                userAction: "check_apple_music_subscription"
            )
            print("Error checking subscription status: \(appError.message)")
            hasAppleMusicSubscription = false
        }
    }

    // MARK: - Public Helpers

    /// Prüft ob alle Voraussetzungen erfüllt sind
    var canUseMusicKit: Bool {
        return isAuthorized && hasAppleMusicSubscription
    }

    /// Fehlermeldung falls MusicKit nicht verfügbar
    var unavailabilityReason: String? {
        if !isAuthorized {
            return "Please allow access to Apple Music in Settings"
        }
        if !hasAppleMusicSubscription {
            return "An Apple Music subscription is required"
        }
        return nil
    }
}

// MARK: - Authorization Status Extension

extension MusicAuthorization.Status {
    var description: String {
        switch self {
        case .notDetermined:
            return "Not Determined"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        case .authorized:
            return "Authorized"
        @unknown default:
            return "Unknown"
        }
    }
}
