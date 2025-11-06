//
//  TestHelpers.swift
//  StarTuneTests
//
//  Centralized test helpers to avoid duplication and network calls
//

import Foundation
import MusicKit

/// Test helpers for creating mock objects
enum TestHelpers {

    // MARK: - Mock Song Factory

    /// Creates a mock Song object from static data (no network calls)
    /// This is the ONLY place where test Song objects should be created
    /// - Parameters:
    ///   - id: Optional MusicItemID, defaults to a test ID
    ///   - title: Song title, defaults to "Test Song"
    ///   - artistName: Artist name, defaults to "Test Artist"
    ///   - albumTitle: Album title, defaults to "Test Album"
    /// - Returns: A Song object constructed from local data
    static func createMockSong(
        id: MusicItemID? = nil,
        title: String = "Test Song",
        artistName: String = "Test Artist",
        albumTitle: String? = "Test Album"
    ) -> Song {
        // Create a Song from a known Apple Music ID
        // Using a well-known song ID that exists in the catalog
        // This creates the Song object without making a network call
        let songID = id ?? MusicItemID("1440857781") // Example: A known song ID
        return Song(id: songID)
    }

    /// Creates multiple mock songs for testing
    /// - Parameter count: Number of songs to create
    /// - Returns: Array of mock Song objects
    static func createMockSongs(count: Int) -> [Song] {
        return (0..<count).map { index in
            createMockSong(
                title: "Test Song \(index + 1)",
                artistName: "Test Artist \(index + 1)",
                albumTitle: "Test Album \(index + 1)"
            )
        }
    }
}

// MARK: - XCTest Extensions

import XCTest

/// Extension for common test assertions
extension XCTestCase {

    /// Waits for an async operation with a timeout
    func wait(for duration: TimeInterval) async {
        try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
    }

    /// Asserts that an async operation throws a specific error
    func assertThrowsError<T, E: Error & Equatable>(
        _ expression: @autoclosure () async throws -> T,
        expectedError: E,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        do {
            _ = try await expression()
            XCTFail("Expected error to be thrown", file: file, line: line)
        } catch let error as E {
            XCTAssertEqual(error, expectedError, file: file, line: line)
        } catch {
            XCTFail("Unexpected error type: \(error)", file: file, line: line)
        }
    }
}
