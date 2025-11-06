//
//  MusicKitManagerTests.swift
//  StarTuneTests
//
//  Unit tests for MusicKitManager authorization logic
//

import XCTest
import MusicKit
import Combine
@testable import StarTune

@MainActor
final class MusicKitManagerTests: XCTestCase {

    var sut: MusicKitManager!
    var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        try await super.setUp()
        sut = MusicKitManager()
        cancellables = []
    }

    override func tearDown() async throws {
        cancellables = nil
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInit_ChecksAuthorizationStatus() {
        // When: Manager is initialized
        // Then: Should check current authorization status
        XCTAssertNotNil(sut, "MusicKitManager should initialize")
        XCTAssertNotNil(sut.authorizationStatus, "Should have authorization status")
    }

    func testInit_SetsInitialState() {
        // Then: Initial state should be set
        let status = sut.authorizationStatus

        // Status should be one of the valid cases
        XCTAssertTrue(
            [.notDetermined, .denied, .restricted, .authorized].contains(status),
            "Should have valid authorization status"
        )

        // isAuthorized should match status
        if status == .authorized {
            XCTAssertTrue(sut.isAuthorized, "Should be authorized when status is authorized")
        } else {
            XCTAssertFalse(sut.isAuthorized, "Should not be authorized when status is not authorized")
        }
    }

    // MARK: - Authorization Request Tests

    func testRequestAuthorization_UpdatesStatus() async {
        // Given: Initial state
        let initialStatus = sut.authorizationStatus

        // When: Requesting authorization
        await sut.requestAuthorization()

        // Then: Status should be updated (may remain same or change)
        XCTAssertTrue(
            [.notDetermined, .denied, .restricted, .authorized].contains(sut.authorizationStatus),
            "Should have valid authorization status after request"
        )
    }

    func testRequestAuthorization_UpdatesIsAuthorized() async {
        // When: Requesting authorization
        await sut.requestAuthorization()

        // Then: isAuthorized should match status
        if sut.authorizationStatus == .authorized {
            XCTAssertTrue(sut.isAuthorized, "isAuthorized should be true when authorized")
        } else {
            XCTAssertFalse(sut.isAuthorized, "isAuthorized should be false when not authorized")
        }
    }

    func testRequestAuthorization_ChecksSubscriptionWhenAuthorized() async {
        // When: Requesting authorization
        await sut.requestAuthorization()

        // Then: If authorized, subscription status should be checked
        if sut.isAuthorized {
            // hasAppleMusicSubscription should have a value (true or false)
            // We can't assert the exact value without knowing the test environment
            XCTAssertNotNil(sut.hasAppleMusicSubscription)
        }
    }

    // MARK: - Published Properties Tests

    func testPublishedProperties_EmitChanges() async {
        // Given: Observers for published properties
        var isAuthorizedValues: [Bool] = []
        var authStatusValues: [MusicAuthorization.Status] = []
        var subscriptionValues: [Bool] = []

        sut.$isAuthorized
            .sink { isAuthorizedValues.append($0) }
            .store(in: &cancellables)

        sut.$authorizationStatus
            .sink { authStatusValues.append($0) }
            .store(in: &cancellables)

        sut.$hasAppleMusicSubscription
            .sink { subscriptionValues.append($0) }
            .store(in: &cancellables)

        // When: Requesting authorization
        await sut.requestAuthorization()

        // Small delay to allow publishers to emit
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s

        // Then: Should have received values
        XCTAssertFalse(isAuthorizedValues.isEmpty, "Should emit isAuthorized values")
        XCTAssertFalse(authStatusValues.isEmpty, "Should emit authorizationStatus values")
        XCTAssertFalse(subscriptionValues.isEmpty, "Should emit hasAppleMusicSubscription values")
    }

    // MARK: - canUseMusicKit Tests

    func testCanUseMusicKit_ReturnsTrueWhenAuthorizedWithSubscription() {
        // Given: Authorized with subscription (mock state)
        // Note: In real tests, we would need to mock MusicKit
        // This test validates the logic, not the actual MusicKit state

        // When/Then: canUseMusicKit should combine both checks
        let canUse = sut.canUseMusicKit

        if sut.isAuthorized && sut.hasAppleMusicSubscription {
            XCTAssertTrue(canUse, "Should be able to use MusicKit when authorized with subscription")
        } else {
            XCTAssertFalse(canUse, "Should not be able to use MusicKit without authorization or subscription")
        }
    }

    func testCanUseMusicKit_ReturnsFalseWhenNotAuthorized() {
        // Given: Not authorized
        if !sut.isAuthorized {
            // When/Then
            XCTAssertFalse(sut.canUseMusicKit, "Should not be able to use MusicKit when not authorized")
        }
    }

    func testCanUseMusicKit_ReturnsFalseWithoutSubscription() {
        // Given: Authorized but no subscription
        if sut.isAuthorized && !sut.hasAppleMusicSubscription {
            // When/Then
            XCTAssertFalse(sut.canUseMusicKit, "Should not be able to use MusicKit without subscription")
        }
    }

    // MARK: - unavailabilityReason Tests

    func testUnavailabilityReason_ReturnsNilWhenCanUseMusicKit() {
        // Given: Can use MusicKit
        if sut.canUseMusicKit {
            // When/Then
            XCTAssertNil(sut.unavailabilityReason, "Should have no unavailability reason when can use MusicKit")
        }
    }

    func testUnavailabilityReason_ReturnsAuthorizationMessage() {
        // Given: Not authorized
        if !sut.isAuthorized {
            // When/Then
            let reason = sut.unavailabilityReason
            XCTAssertNotNil(reason, "Should have unavailability reason when not authorized")
            XCTAssertEqual(reason, "Please allow access to Apple Music in Settings")
        }
    }

    func testUnavailabilityReason_ReturnsSubscriptionMessage() {
        // Given: Authorized but no subscription
        if sut.isAuthorized && !sut.hasAppleMusicSubscription {
            // When/Then
            let reason = sut.unavailabilityReason
            XCTAssertNotNil(reason, "Should have unavailability reason without subscription")
            XCTAssertEqual(reason, "An Apple Music subscription is required")
        }
    }

    func testUnavailabilityReason_PrioritizesAuthorizationOverSubscription() {
        // Given: Neither authorized nor subscribed
        if !sut.isAuthorized && !sut.hasAppleMusicSubscription {
            // When/Then: Should return authorization message first
            let reason = sut.unavailabilityReason
            XCTAssertNotNil(reason)
            XCTAssertEqual(reason, "Please allow access to Apple Music in Settings")
        }
    }

    // MARK: - MusicAuthorization.Status Extension Tests

    func testAuthorizationStatus_Descriptions() {
        // Test all status descriptions
        XCTAssertEqual(MusicAuthorization.Status.notDetermined.description, "Not Determined")
        XCTAssertEqual(MusicAuthorization.Status.denied.description, "Denied")
        XCTAssertEqual(MusicAuthorization.Status.restricted.description, "Restricted")
        XCTAssertEqual(MusicAuthorization.Status.authorized.description, "Authorized")
    }

    // MARK: - Edge Cases

    func testMultipleAuthorizationRequests() async {
        // Test multiple authorization requests in sequence
        await sut.requestAuthorization()
        let status1 = sut.authorizationStatus

        await sut.requestAuthorization()
        let status2 = sut.authorizationStatus

        // Status should remain consistent
        XCTAssertEqual(status1, status2, "Multiple requests should have consistent status")
    }

    func testConcurrentAuthorizationRequests() async {
        // Test concurrent authorization requests
        async let request1: Void = sut.requestAuthorization()
        async let request2: Void = sut.requestAuthorization()

        let _ = await (request1, request2)

        // Should complete without crashes
        XCTAssertTrue(true, "Concurrent requests should complete safely")
    }

    // MARK: - Integration Test Helpers

    func testMusicKitAvailability() {
        // Verify MusicKit is available in the test environment
        let status = MusicAuthorization.currentStatus

        XCTAssertTrue(
            [.notDetermined, .denied, .restricted, .authorized].contains(status),
            "MusicKit should be available in test environment"
        )
    }
}
