//
//  MusicKitManagerTests.swift
//  StarTuneTests
//
//  Unit tests for MusicKitManager using mocks (no real authorization calls)
//  FIX: Addresses violation #9 - no real MusicKit authorization flow
//

import XCTest
import MusicKit
@testable import StarTune

@MainActor
final class MusicKitManagerTests: XCTestCase {

    var mockManager: MockMusicKitManager!

    override func setUp() {
        super.setUp()
        mockManager = MockMusicKitManager()
    }

    override func tearDown() {
        mockManager = nil
        super.tearDown()
    }

    // MARK: - Authorization Tests

    func testRequestAuthorization_Success() async {
        // Given: Mock configured to authorize with subscription
        mockManager.shouldAuthorize = true
        mockManager.shouldHaveSubscription = true

        // When: Requesting authorization
        await mockManager.requestAuthorization()

        // Then: Should be authorized with subscription
        XCTAssertTrue(mockManager.isAuthorized, "Should be authorized")
        XCTAssertEqual(mockManager.authorizationStatus, .authorized, "Status should be authorized")
        XCTAssertTrue(mockManager.hasAppleMusicSubscription, "Should have subscription")
    }

    func testRequestAuthorization_Denied() async {
        // Given: Mock configured to deny
        mockManager.shouldAuthorize = false

        // When: Requesting authorization
        await mockManager.requestAuthorization()

        // Then: Should be denied
        XCTAssertFalse(mockManager.isAuthorized, "Should not be authorized")
        XCTAssertEqual(mockManager.authorizationStatus, .denied, "Status should be denied")
        XCTAssertFalse(mockManager.hasAppleMusicSubscription, "Should not have subscription")
    }

    func testRequestAuthorization_AuthorizedNoSubscription() async {
        // Given: Mock configured to authorize but no subscription
        mockManager.shouldAuthorize = true
        mockManager.shouldHaveSubscription = false

        // When: Requesting authorization
        await mockManager.requestAuthorization()

        // Then: Should be authorized but no subscription
        XCTAssertTrue(mockManager.isAuthorized, "Should be authorized")
        XCTAssertFalse(mockManager.hasAppleMusicSubscription, "Should not have subscription")
    }

    // MARK: - Status Tests

    func testCanUseMusicKit_WithBoth() {
        // Given: Mock with authorization and subscription
        mockManager.simulateAuthorizedWithSubscription()

        // When: Checking if can use MusicKit
        let canUse = mockManager.canUseMusicKit

        // Then: Should return true
        XCTAssertTrue(canUse, "Should be able to use MusicKit")
        XCTAssertNil(mockManager.unavailabilityReason, "Should have no unavailability reason")
    }

    func testCanUseMusicKit_NotAuthorized() {
        // Given: Mock not authorized
        mockManager.reset()

        // When: Checking if can use MusicKit
        let canUse = mockManager.canUseMusicKit

        // Then: Should return false
        XCTAssertFalse(canUse, "Should not be able to use MusicKit")
        XCTAssertNotNil(mockManager.unavailabilityReason, "Should have unavailability reason")
        XCTAssertTrue(
            mockManager.unavailabilityReason!.contains("allow access"),
            "Reason should mention authorization"
        )
    }

    func testCanUseMusicKit_NoSubscription() {
        // Given: Mock authorized but no subscription
        mockManager.simulateAuthorizedNoSubscription()

        // When: Checking if can use MusicKit
        let canUse = mockManager.canUseMusicKit

        // Then: Should return false
        XCTAssertFalse(canUse, "Should not be able to use MusicKit")
        XCTAssertNotNil(mockManager.unavailabilityReason, "Should have unavailability reason")
        XCTAssertTrue(
            mockManager.unavailabilityReason!.contains("subscription"),
            "Reason should mention subscription"
        )
    }

    func testCanUseMusicKit_Denied() {
        // Given: Mock with denied status
        mockManager.simulateDenied()

        // When: Checking if can use MusicKit
        let canUse = mockManager.canUseMusicKit

        // Then: Should return false
        XCTAssertFalse(canUse, "Should not be able to use MusicKit")
        XCTAssertEqual(mockManager.authorizationStatus, .denied, "Status should be denied")
    }

    func testCanUseMusicKit_Restricted() {
        // Given: Mock with restricted status
        mockManager.simulateRestricted()

        // When: Checking if can use MusicKit
        let canUse = mockManager.canUseMusicKit

        // Then: Should return false
        XCTAssertFalse(canUse, "Should not be able to use MusicKit")
        XCTAssertEqual(mockManager.authorizationStatus, .restricted, "Status should be restricted")
    }

    // MARK: - Test Helper Tests

    func testSimulateAuthorizedWithSubscription() {
        // When: Simulating authorized with subscription
        mockManager.simulateAuthorizedWithSubscription()

        // Then: Should have correct state
        XCTAssertTrue(mockManager.isAuthorized, "Should be authorized")
        XCTAssertEqual(mockManager.authorizationStatus, .authorized, "Status should be authorized")
        XCTAssertTrue(mockManager.hasAppleMusicSubscription, "Should have subscription")
        XCTAssertTrue(mockManager.canUseMusicKit, "Should be able to use MusicKit")
    }

    func testSimulateAuthorizedNoSubscription() {
        // When: Simulating authorized without subscription
        mockManager.simulateAuthorizedNoSubscription()

        // Then: Should have correct state
        XCTAssertTrue(mockManager.isAuthorized, "Should be authorized")
        XCTAssertEqual(mockManager.authorizationStatus, .authorized, "Status should be authorized")
        XCTAssertFalse(mockManager.hasAppleMusicSubscription, "Should not have subscription")
        XCTAssertFalse(mockManager.canUseMusicKit, "Should not be able to use MusicKit")
    }

    func testSimulateDenied() {
        // When: Simulating denied
        mockManager.simulateDenied()

        // Then: Should have correct state
        XCTAssertFalse(mockManager.isAuthorized, "Should not be authorized")
        XCTAssertEqual(mockManager.authorizationStatus, .denied, "Status should be denied")
        XCTAssertFalse(mockManager.hasAppleMusicSubscription, "Should not have subscription")
    }

    func testSimulateRestricted() {
        // When: Simulating restricted
        mockManager.simulateRestricted()

        // Then: Should have correct state
        XCTAssertFalse(mockManager.isAuthorized, "Should not be authorized")
        XCTAssertEqual(mockManager.authorizationStatus, .restricted, "Status should be restricted")
        XCTAssertFalse(mockManager.hasAppleMusicSubscription, "Should not have subscription")
    }

    func testReset() {
        // Given: Mock with state
        mockManager.simulateAuthorizedWithSubscription()
        mockManager.shouldAuthorize = true
        mockManager.shouldHaveSubscription = true

        // When: Resetting
        mockManager.reset()

        // Then: Should be in initial state
        XCTAssertFalse(mockManager.isAuthorized, "Should not be authorized")
        XCTAssertEqual(mockManager.authorizationStatus, .notDetermined, "Status should be notDetermined")
        XCTAssertFalse(mockManager.hasAppleMusicSubscription, "Should not have subscription")
        XCTAssertFalse(mockManager.shouldAuthorize, "Should not auto-authorize")
        XCTAssertFalse(mockManager.shouldHaveSubscription, "Should not auto-have subscription")
    }
}
