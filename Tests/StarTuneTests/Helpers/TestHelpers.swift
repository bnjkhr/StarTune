//
//  TestHelpers.swift
//  StarTuneTests
//
//  Helper utilities for testing
//

import Foundation
import XCTest
import MusicKit
@testable import StarTune

// MARK: - Song Creation Helpers

extension XCTestCase {
    /// Creates a mock song for testing
    /// - Parameters:
    ///   - title: Song title for search
    ///   - artist: Artist name for search
    /// - Returns: Song object from MusicKit catalog
    func createTestSong(title: String = "Test", artist: String = "Test Artist") async throws -> Song {
        var searchRequest = MusicCatalogSearchRequest(
            term: "\(title) \(artist)",
            types: [Song.self]
        )
        searchRequest.limit = 1

        let response = try await searchRequest.response()

        guard let song = response.songs.first else {
            throw TestError.songNotFound
        }

        return song
    }
}

// MARK: - Test Error Types

enum TestError: Error {
    case songNotFound
    case authorizationFailed
    case subscriptionUnavailable
    case networkError

    var localizedDescription: String {
        switch self {
        case .songNotFound:
            return "Test song not found in catalog"
        case .authorizationFailed:
            return "MusicKit authorization failed"
        case .subscriptionUnavailable:
            return "Apple Music subscription unavailable"
        case .networkError:
            return "Network error during test"
        }
    }
}

// MARK: - Async Testing Helpers

extension XCTestCase {
    /// Wait for a condition to be true
    func waitFor(
        timeout: TimeInterval = 5.0,
        condition: @escaping () -> Bool,
        description: String = "Condition"
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)

        while !condition() {
            if Date() > deadline {
                XCTFail("\(description) timed out after \(timeout) seconds")
                return
            }

            try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        }
    }

    /// Wait for published value to change
    @MainActor
    func waitForPublisher<T: Equatable>(
        _ publisher: Published<T>.Publisher,
        toEqual expectedValue: T,
        timeout: TimeInterval = 5.0,
        description: String = "Publisher value"
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)

        var cancellable: AnyCancellable?
        var currentValue: T?

        let expectation = XCTestExpectation(description: description)

        cancellable = publisher.sink { value in
            currentValue = value
            if value == expectedValue {
                expectation.fulfill()
            }
        }

        let result = await XCTWaiter().fulfillment(of: [expectation], timeout: timeout)

        cancellable?.cancel()

        if result != .completed {
            XCTFail("\(description) did not equal expected value. Got: \(String(describing: currentValue)), Expected: \(expectedValue)")
        }
    }
}

// MARK: - Mock Data

struct MockData {
    static let testSongTitle = "Test Song"
    static let testArtistName = "Test Artist"
    static let testAlbumTitle = "Test Album"
    static let testTrackID = "test-track-id-123"

    static let appleScriptPlayingResponse = "Test Song|Test Artist|playing"
    static let appleScriptPausedResponse = "||paused"
    static let appleScriptErrorResponse = "||error"
    static let appleScriptMusicNotRunning = "false"
}

// MARK: - Assertion Helpers

extension XCTestCase {
    /// Assert that an async operation throws a specific error
    func assertThrowsError<T, E: Error>(
        _ expression: @autoclosure () async throws -> T,
        expectedError: E,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async where E: Equatable {
        do {
            _ = try await expression()
            XCTFail("Expected error \(expectedError) to be thrown", file: file, line: line)
        } catch let error as E {
            XCTAssertEqual(error, expectedError, file: file, line: line)
        } catch {
            XCTFail("Wrong error type: \(error)", file: file, line: line)
        }
    }

    /// Assert that a notification is posted
    func assertNotificationPosted(
        _ name: Notification.Name,
        timeout: TimeInterval = 1.0,
        operation: () async throws -> Void
    ) async throws {
        let expectation = XCTestExpectation(description: "Notification \(name.rawValue)")

        let observer = NotificationCenter.default.addObserver(
            forName: name,
            object: nil,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }

        defer {
            NotificationCenter.default.removeObserver(observer)
        }

        try await operation()

        let result = await XCTWaiter().fulfillment(of: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, "Expected notification \(name.rawValue) to be posted")
    }
}

// MARK: - Combine Helpers

import Combine

extension XCTestCase {
    /// Collect published values over time
    @MainActor
    func collectPublishedValues<T>(
        from publisher: Published<T>.Publisher,
        during operation: () async throws -> Void,
        timeout: TimeInterval = 2.0
    ) async throws -> [T] {
        var values: [T] = []
        var cancellable: AnyCancellable?

        cancellable = publisher.sink { value in
            values.append(value)
        }

        try await operation()

        // Allow time for final updates
        try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))

        cancellable?.cancel()

        return values
    }
}

// MARK: - Performance Testing Helpers

extension XCTestCase {
    /// Measure async operation performance
    func measureAsync(
        iterations: Int = 10,
        operation: () async throws -> Void
    ) async rethrows {
        var times: [TimeInterval] = []

        for _ in 0..<iterations {
            let start = Date()
            try await operation()
            let duration = Date().timeIntervalSince(start)
            times.append(duration)
        }

        let average = times.reduce(0, +) / Double(times.count)
        let min = times.min() ?? 0
        let max = times.max() ?? 0

        print("""
        Performance Metrics:
        - Average: \(String(format: "%.4f", average))s
        - Min: \(String(format: "%.4f", min))s
        - Max: \(String(format: "%.4f", max))s
        """)
    }
}
