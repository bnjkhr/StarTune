//
//  MockMusicKitManager.swift
//  StarTuneTests
//
//  Mock MusicKit authorization and subscription management
//

import Foundation
import MusicKit
import Combine

/// Mock MusicKitManager for testing
@MainActor
class MockMusicKitManager: ObservableObject {
    @Published var isAuthorized = false
    @Published var authorizationStatus: MusicAuthorization.Status = .notDetermined
    @Published var hasAppleMusicSubscription = false

    var requestAuthorizationCalled = false
    var shouldAuthorizeOnRequest = true
    var shouldHaveSubscription = true

    func requestAuthorization() async {
        requestAuthorizationCalled = true

        if shouldAuthorizeOnRequest {
            authorizationStatus = .authorized
            isAuthorized = true
            hasAppleMusicSubscription = shouldHaveSubscription
        } else {
            authorizationStatus = .denied
            isAuthorized = false
            hasAppleMusicSubscription = false
        }
    }

    var canUseMusicKit: Bool {
        return isAuthorized && hasAppleMusicSubscription
    }

    var unavailabilityReason: String? {
        if !isAuthorized {
            return "Please allow access to Apple Music in Settings"
        }
        if !hasAppleMusicSubscription {
            return "An Apple Music subscription is required"
        }
        return nil
    }

    /// Reset mock state
    func reset() {
        isAuthorized = false
        authorizationStatus = .notDetermined
        hasAppleMusicSubscription = false
        requestAuthorizationCalled = false
        shouldAuthorizeOnRequest = true
        shouldHaveSubscription = true
    }

    /// Configure for authorized state
    func setAuthorized(withSubscription: Bool = true) {
        isAuthorized = true
        authorizationStatus = .authorized
        hasAppleMusicSubscription = withSubscription
    }

    /// Configure for denied state
    func setDenied() {
        isAuthorized = false
        authorizationStatus = .denied
        hasAppleMusicSubscription = false
    }
}
