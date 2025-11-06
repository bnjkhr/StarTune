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

    // Subscription cache with TTL (Time-To-Live)
    private var subscriptionCacheTime: Date?
    private let cacheTTL: TimeInterval = 3600 // 1 hour cache

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

    /// Prüft ob User ein Apple Music Abo hat (mit Cache)
    private func checkSubscriptionStatus() async {
        // Check cache validity
        if let cacheTime = subscriptionCacheTime,
           Date().timeIntervalSince(cacheTime) < cacheTTL {
            print("✅ Using cached subscription status (age: \(Int(Date().timeIntervalSince(cacheTime)))s)")
            return
        }

        do {
            // MusicSubscription Status abfragen (network call)
            print("🌐 Fetching subscription status from network...")
            let subscription = try await MusicSubscription.current
            hasAppleMusicSubscription = subscription.canPlayCatalogContent
            subscriptionCacheTime = Date()
            print("✅ Subscription status cached: \(hasAppleMusicSubscription)")
        } catch {
            print("❌ Error checking subscription status: \(error.localizedDescription)")
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

    /// Invalidates subscription cache and forces refresh
    func refreshSubscriptionStatus() async {
        subscriptionCacheTime = nil
        print("🔄 Subscription cache invalidated, fetching fresh data...")
        await checkSubscriptionStatus()
    }

    /// Returns cache age in seconds, nil if no cache
    var subscriptionCacheAge: TimeInterval? {
        guard let cacheTime = subscriptionCacheTime else { return nil }
        return Date().timeIntervalSince(cacheTime)
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
