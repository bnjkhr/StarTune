# StarTune Testing Strategy

## Executive Summary

This document outlines the comprehensive testing strategy for StarTune, a macOS menu bar application for favoriting Apple Music songs. The strategy covers unit testing, integration testing, UI testing, and mock implementations for all critical components.

## Table of Contents

1. [Testing Philosophy](#testing-philosophy)
2. [Test Architecture](#test-architecture)
3. [Component Coverage](#component-coverage)
4. [Testing Tools & Frameworks](#testing-tools--frameworks)
5. [Mock Strategy](#mock-strategy)
6. [Test Execution](#test-execution)
7. [Key Test Cases](#key-test-cases)
8. [CI/CD Integration](#cicd-integration)
9. [Future Improvements](#future-improvements)

## Testing Philosophy

### Core Principles

1. **Testability First**: Code is structured for dependency injection and testability
2. **Fast Feedback**: Unit tests run quickly; integration tests validate external systems
3. **Reliable**: Tests are deterministic and don't depend on external state when possible
4. **Maintainable**: Tests are clear, well-organized, and easy to update
5. **Comprehensive**: Cover happy paths, error cases, and edge cases

### Testing Pyramid

```
         /\
        /  \       E2E Tests (Manual)
       /----\      UI Tests (Automated)
      /      \     Integration Tests
     /--------\    Unit Tests (Largest volume)
    /__________\
```

**Distribution:**
- **70% Unit Tests**: Fast, isolated, test business logic
- **20% Integration Tests**: Test external system integration
- **10% UI Tests**: Test SwiftUI component logic

## Test Architecture

### Directory Structure

```
Tests/StarTuneTests/
├── Mocks/                  # Dependency mocks
├── UnitTests/              # Business logic tests
├── IntegrationTests/       # External integration tests
├── UITests/                # SwiftUI component tests
├── Helpers/                # Shared test utilities
└── README.md               # Test documentation
```

### Dependency Graph

```
StarTune App
├── FavoritesService    → MockMusicCatalog
├── MusicKitManager     → MockMusicKitManager
├── PlaybackMonitor     → MockPlaybackMonitor
├── MusicAppBridge      → MockMusicAppBridge
└── MenuBarView         → All Mocks
```

## Component Coverage

### 1. FavoritesService (Unit Tests)

**Purpose**: Test favorites management business logic

**Test Coverage:**
- ✅ Add to favorites (success path)
- ✅ Add to favorites (authorization error)
- ✅ Add to favorites (subscription error)
- ✅ Add to favorites (network error)
- ✅ Remove from favorites
- ✅ Check favorite status
- ✅ Get all favorites
- ✅ Error mapping (MusadoraKitError → FavoritesError)
- ✅ Concurrent operations

**Dependencies Mocked:**
- MusadoraKit MCatalog
- MusicKit Song objects

**Key Test Cases:**

```swift
// Success case
func testAddToFavorites_Success()

// Error handling
func testAddToFavorites_NotAuthorized()
func testAddToFavorites_NoSubscription()
func testAddToFavorites_NetworkError()

// Edge cases
func testMultipleOperations_Sequential()
```

### 2. MusicKitManager (Unit Tests)

**Purpose**: Test MusicKit authorization and subscription management

**Test Coverage:**
- ✅ Initialization and status check
- ✅ Authorization request flow
- ✅ Subscription status validation
- ✅ Published property updates (@Published)
- ✅ Computed properties (canUseMusicKit, unavailabilityReason)
- ✅ Authorization status descriptions
- ✅ Multiple/concurrent authorization requests

**Dependencies:**
- MusicAuthorization (real, adapts to state)
- MusicSubscription (real, adapts to state)

**Key Test Cases:**

```swift
// Authorization flow
func testRequestAuthorization_UpdatesStatus()
func testRequestAuthorization_ChecksSubscriptionWhenAuthorized()

// State validation
func testCanUseMusicKit_ReturnsTrueWhenAuthorizedWithSubscription()
func testUnavailabilityReason_ReturnsAuthorizationMessage()

// Concurrency
func testConcurrentAuthorizationRequests()
```

### 3. PlaybackMonitor (Unit Tests)

**Purpose**: Test playback state monitoring logic

**Test Coverage:**
- ✅ Start/stop monitoring
- ✅ Timer-based updates (2-second interval)
- ✅ Song catalog search integration
- ✅ Published property updates
- ✅ Computed properties (hasSongPlaying, currentSongInfo)
- ✅ Memory management (no retain cycles)
- ✅ Timer lifecycle management

**Dependencies Mocked:**
- MusicAppBridge (indirectly)

**Key Test Cases:**

```swift
// Monitoring lifecycle
func testStartMonitoring_UpdatesState()
func testStopMonitoring_StopsUpdates()

// State management
func testHasSongPlaying_WhenPlayingWithSong()
func testCurrentSongInfo_WithSong()

// Performance
func testTimer_UpdatesStateRegularly()
func testTimer_DoesNotCreateMultipleTimers()
```

### 4. MusicAppBridge (Integration Tests)

**Purpose**: Test AppleScript integration with Music.app

**Test Coverage:**
- ✅ Initialization
- ✅ Playback state updates
- ✅ Track ID retrieval
- ✅ Track info formatting
- ✅ Error handling (app not running)
- ✅ AppleScript error codes (-600)
- ✅ Multiple consecutive updates
- ✅ Performance metrics

**External Dependencies:**
- Music.app (optional, tests adapt)
- AppleScript runtime
- ScriptingBridge framework

**Key Test Cases:**

```swift
// Integration
func testUpdatePlaybackState_WhenMusicAppNotRunning()
func testUpdatePlaybackState_WhenMusicAppRunning()

// Error handling
func testAppleScript_HandlesAppNotRunning()

// Performance
func testUpdatePlaybackState_Performance()
```

**Manual Test Cases:**
```swift
// Requires Music.app setup
// 1. Open Music.app
// 2. Play a song
// 3. Run test
func testRealPlayback_DetectsPlayingSong()
func testRealPlayback_DetectsPaused()
func testRealPlayback_TracksChanges()
```

### 5. MenuBarView (UI Tests)

**Purpose**: Test SwiftUI MenuBar component logic

**Test Coverage:**
- ✅ View creation
- ✅ Authorization section visibility
- ✅ Currently playing section display
- ✅ Song information rendering
- ✅ Playback indicator (color: green/gray)
- ✅ Add to Favorites button states
- ✅ Progress indicator visibility
- ✅ Notification posting
- ✅ Reactive updates (@ObservedObject)
- ✅ Edge cases (rapid state changes)

**Dependencies Mocked:**
- MusicKitManager → MockMusicKitManager
- PlaybackMonitor → MockPlaybackMonitor
- FavoritesService → TestableFavoritesService

**Key Test Cases:**

```swift
// View sections
func testAuthorizationSection_ShowsWhenNotAuthorized()
func testCurrentlyPlayingSection_ShowsSongInfo()

// Button states
func testFavoriteButton_EnabledWhenSongPlaying()
func testFavoriteButton_DisabledWhenNoSong()

// Reactive updates
func testView_ReactsToAuthorizationChanges()
func testView_ReactsToPlaybackChanges()
```

## Testing Tools & Frameworks

### Built-in Frameworks

1. **XCTest**
   - Apple's testing framework
   - Unit, integration, and performance tests
   - Async/await support

2. **SwiftUI Preview**
   - Visual validation during development
   - Not automated but valuable for UI work

3. **Combine**
   - Test @Published property updates
   - Validate reactive data flow

### Third-Party Tools (Future)

1. **Swift Testing** (Swift 6+)
   - Modern testing framework
   - Better async support
   - Improved assertions

2. **SnapshotTesting**
   - Visual regression testing
   - UI component snapshots

## Mock Strategy

### MockMusicCatalog

**Purpose**: Mock MusadoraKit catalog operations

**Capabilities:**
```swift
// Configure behavior
MockMusicCatalog.shouldSucceed = false
MockMusicCatalog.errorToThrow = .notAuthorized

// Verify interactions
XCTAssertEqual(MockMusicCatalog.addedRatings.count, 1)
```

### MockMusicKitManager

**Purpose**: Mock authorization and subscription state

**Capabilities:**
```swift
// Configure states
mockManager.setAuthorized(withSubscription: true)
mockManager.setDenied()

// Verify behavior
XCTAssertTrue(mockManager.requestAuthorizationCalled)
```

### MockMusicAppBridge

**Purpose**: Mock AppleScript bridge

**Capabilities:**
```swift
// Set playback state
mockBridge.setPlaying(trackName: "Song", artist: "Artist")
mockBridge.setPaused()

// Simulate errors
mockBridge.shouldSimulateAppNotRunning = true
```

### MockPlaybackMonitor

**Purpose**: Mock playback monitoring

**Capabilities:**
```swift
// Set current song
mockMonitor.setCurrentSong(song, playing: true)

// Verify calls
XCTAssertTrue(mockMonitor.startMonitoringCalled)
```

## Test Execution

### Local Development

```bash
# Run all tests
swift test

# Run specific test class
swift test --filter FavoritesServiceTests

# Run with coverage
swift test --enable-code-coverage

# Run in Xcode
# Cmd + U (all tests)
```

### Performance Testing

```swift
// XCTest performance
measure {
    sut.updatePlaybackState()
}

// Custom async measurement
await measureAsync(iterations: 10) {
    await sut.startMonitoring()
}
```

### Test Configuration

**Test Entitlements:**
```xml
<!-- StarTune.entitlements -->
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.automation.apple-events</key>
<true/>
```

**Test Plan:**
- Parallel execution enabled
- Randomized order for independence
- Code coverage enabled

## Key Test Cases

### Critical Happy Paths

1. **User authorizes app → favorites song**
   ```
   1. MusicKitManager.requestAuthorization()
   2. Authorization granted
   3. PlaybackMonitor detects playing song
   4. User clicks "Add to Favorites"
   5. FavoritesService adds to library
   6. Success notification posted
   7. MenuBarController shows green flash
   ```

2. **User opens app → sees currently playing song**
   ```
   1. MusicAppBridge detects Music.app state
   2. PlaybackMonitor searches catalog
   3. MenuBarView displays song info
   4. Playback indicator shows green (playing)
   ```

### Critical Error Paths

1. **Not authorized**
   ```
   1. User opens app
   2. MusicKitManager checks authorization
   3. Status: .denied
   4. MenuBarView shows authorization section
   5. User clicks "Allow Access"
   6. System dialog appears
   ```

2. **Network error during favorites**
   ```
   1. User clicks "Add to Favorites"
   2. Network request fails
   3. FavoritesService throws .networkError
   4. Error notification posted
   5. MenuBarController shows red flash
   6. User sees error state
   ```

### Edge Cases

1. **Music.app not running**
   - MusicAppBridge returns idle state
   - No errors logged (error -600 suppressed)
   - UI shows "No music playing"

2. **Rapid song changes**
   - PlaybackMonitor updates every 2 seconds
   - Song changes between updates
   - Catalog search for new song succeeds

3. **Multiple favorite attempts**
   - Concurrent operations handled
   - Only one operation in progress
   - Subsequent attempts queue or fail gracefully

## CI/CD Integration

### GitHub Actions Configuration

```yaml
name: Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: macos-14

    steps:
      - uses: actions/checkout@v4

      - name: Setup Swift
        uses: swift-actions/setup-swift@v1
        with:
          swift-version: '5.9'

      - name: Run tests
        run: swift test --parallel --enable-code-coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: .build/debug/codecov/*.json
```

### Required CI Environment

- **OS**: macOS 14.0+ (Sonoma)
- **Xcode**: 15.0+
- **Swift**: 5.9+
- **Timeout**: 10 minutes (for network-dependent tests)

### CI Test Strategy

**Fast Feedback:**
- Unit tests run on every commit
- ~30 seconds execution time

**Integration Tests:**
- Run on PR and main branch
- May skip network-dependent tests in CI

**Manual Tests:**
- Music.app integration tests
- Run before releases

## Future Improvements

### Short Term (1-3 months)

1. **Increase Coverage**
   - Target: 90%+ code coverage
   - Focus: Error paths and edge cases

2. **Add Snapshot Tests**
   - Visual regression testing
   - MenuBarView UI validation

3. **Performance Benchmarks**
   - Track AppleScript execution time
   - Catalog search performance

### Medium Term (3-6 months)

1. **E2E Test Suite**
   - Automated UI tests in Xcode
   - Full user flow validation

2. **Test Infrastructure**
   - Shared test fixtures
   - Better mock factory patterns

3. **Documentation**
   - Video tutorials for running tests
   - Contributing guide for tests

### Long Term (6-12 months)

1. **Swift Testing Migration**
   - Adopt Swift Testing framework
   - Modern async/await patterns

2. **Continuous Monitoring**
   - Test flakiness detection
   - Performance regression alerts

3. **Advanced Mocking**
   - Protocol-oriented mocks
   - Auto-generated mocks

## Appendix

### Test Naming Convention

```swift
// Pattern: test[Component]_[Scenario]
func testAddToFavorites_Success()
func testAddToFavorites_NotAuthorized()
func testAuthorizationSection_ShowsWhenNotAuthorized()
```

### Assertion Patterns

```swift
// Boolean assertions
XCTAssertTrue(condition)
XCTAssertFalse(condition)

// Equality
XCTAssertEqual(actual, expected)
XCTAssertNotEqual(actual, unexpected)

// Nil checks
XCTAssertNil(value)
XCTAssertNotNil(value)

// Error handling
XCTAssertThrowsError(try expression())
XCTAssertNoThrow(try expression())

// Async
await XCTAssertTrue(await condition())
```

### Resources

- [StarTune Tests README](../Tests/StarTuneTests/README.md)
- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [MusicKit Testing Guide](https://developer.apple.com/documentation/musickit)
- [Swift Testing (WWDC)](https://developer.apple.com/videos/play/wwdc2024/10179/)

---

**Document Version:** 1.0.0
**Last Updated:** 2025-11-06
**Author:** Claude (Anthropic)
**Review Status:** Initial Release
