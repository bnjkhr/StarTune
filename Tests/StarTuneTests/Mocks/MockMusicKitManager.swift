//
//  MockMusicKitManager.swift
//  StarTuneTests
//
//  Mock implementation of MusicKitManager for testing (no real authorization calls)
//

import Foundation
import MusicKit
import Combine
@testable import StarTune

/// Mock implementation of MusicKitManager that doesn't call real MusicKit authorization
/// FIX: Addresses violation #9 - real MusicKit authorization hangs in tests
@MainActor
class MockMusicKitManager: ObservableObject {

    // MARK: - Published Properties

    @Published var isAuthorized = false
    @Published var authorizationStatus: MusicAuthorization.Status = .notDetermined
    @Published var hasAppleMusicSubscription = false

    // MARK: - Mock Configuration

    /// Configure the mock to simulate a successful authorization
    var shouldAuthorize: Bool = false

    /// Configure the mock to simulate having a subscription
    var shouldHaveSubscription: Bool = false

    // MARK: - Initialization

    init() {}

    // MARK: - Mock Methods

    /// Mock implementation of requestAuthorization (no real MusicKit call)
    func requestAuthorization() async {
        // Simulate authorization based on mock configuration
        if shouldAuthorize {
            authorizationStatus = .authorized
            isAuthorized = true

            if shouldHaveSubscription {
                hasAppleMusicSubscription = true
            }
        } else {
            authorizationStatus = .denied
            isAuthorized = false
        }
    }

    // MARK: - Public Helpers

    /// Checks if all requirements are met
    var canUseMusicKit: Bool {
        return isAuthorized && hasAppleMusicSubscription
    }

    /// Error message if MusicKit is not available
    var unavailabilityReason: String? {
        if !isAuthorized {
            return "Please allow access to Apple Music in Settings"
        }
        if !hasAppleMusicSubscription {
            return "An Apple Music subscription is required"
        }
        return nil
    }

    // MARK: - Test Helpers

    /// Configures the mock to simulate authorized state with subscription
    func simulateAuthorizedWithSubscription() {
        authorizationStatus = .authorized
        isAuthorized = true
        hasAppleMusicSubscription = true
    }

    /// Configures the mock to simulate authorized but no subscription
    func simulateAuthorizedNoSubscription() {
        authorizationStatus = .authorized
        isAuthorized = true
        hasAppleMusicSubscription = false
    }

    /// Configures the mock to simulate denied authorization
    func simulateDenied() {
        authorizationStatus = .denied
        isAuthorized = false
        hasAppleMusicSubscription = false
    }

    /// Configures the mock to simulate restricted authorization
    func simulateRestricted() {
        authorizationStatus = .restricted
        isAuthorized = false
        hasAppleMusicSubscription = false
    }

    /// Resets the mock to initial state
    func reset() {
        isAuthorized = false
        authorizationStatus = .notDetermined
        hasAppleMusicSubscription = false
        shouldAuthorize = false
        shouldHaveSubscription = false
    }
}
