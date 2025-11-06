# StarTune Test Suite

Comprehensive testing strategy for the StarTune macOS MusicKit app.

## Overview

This test suite provides comprehensive coverage for StarTune's core functionality:

- **Unit Tests**: Business logic testing (FavoritesService, MusicKitManager, PlaybackMonitor)
- **Integration Tests**: AppleScript/Music.app bridge testing
- **UI Tests**: SwiftUI MenuBar interaction testing
- **Mock Implementations**: Dependency injection for isolated testing

## Test Structure

```
Tests/StarTuneTests/
├── Mocks/                          # Mock implementations
│   ├── MockMusicCatalog.swift      # MusadoraKit catalog operations
│   ├── MockMusicKitManager.swift   # MusicKit authorization
│   ├── MockMusicAppBridge.swift    # AppleScript bridge
│   └── MockPlaybackMonitor.swift   # Playback monitoring
├── UnitTests/                      # Business logic tests
│   ├── FavoritesServiceTests.swift # Favorites operations
│   ├── MusicKitManagerTests.swift  # Authorization & subscription
│   └── PlaybackMonitorTests.swift  # Playback state monitoring
├── IntegrationTests/               # External system integration
│   └── MusicAppBridgeIntegrationTests.swift
├── UITests/                        # SwiftUI component tests
│   └── MenuBarViewTests.swift      # MenuBar UI interactions
├── Helpers/                        # Test utilities
│   └── TestHelpers.swift           # Common test helpers
└── README.md                       # This file
```

## Running Tests

### Via Xcode

1. Open `StarTune.xcodeproj` in Xcode
2. Select the test target: **StarTuneTests**
3. Run tests:
   - All tests: `Cmd + U`
   - Single test class: Click diamond icon next to class
   - Single test method: Click diamond icon next to method

### Via Command Line

```bash
# Run all tests
swift test

# Run with verbose output
swift test --verbose

# Run specific test
swift test --filter FavoritesServiceTests

# Run in parallel
swift test --parallel
```

### Via xcodebuild

```bash
# Build and test
xcodebuild test -scheme StarTune

# With specific destination
xcodebuild test \
  -scheme StarTune \
  -destination 'platform=macOS,arch=arm64'
```

## Test Categories

### 1. Unit Tests

#### FavoritesServiceTests
Tests for favorites management business logic.

**Key Test Cases:**
- ✅ Add song to favorites (success)
- ✅ Add song without authorization (error handling)
- ✅ Add song without subscription (error handling)
- ✅ Remove song from favorites
- ✅ Check favorite status
- ✅ Error mapping (MusadoraKitError → FavoritesError)
- ✅ Edge cases (multiple operations, concurrent requests)

**Requirements:**
- MusicKit framework available
- May require authorization for full integration

#### MusicKitManagerTests
Tests for MusicKit authorization and subscription management.

**Key Test Cases:**
- ✅ Initialization and status check
- ✅ Authorization request flow
- ✅ Subscription status checking
- ✅ Published property updates
- ✅ `canUseMusicKit` computed property
- ✅ `unavailabilityReason` messaging
- ✅ Multiple authorization requests
- ✅ Concurrent request handling

**Requirements:**
- MusicKit framework available
- Tests adapt to actual authorization state

#### PlaybackMonitorTests
Tests for playback state monitoring.

**Key Test Cases:**
- ✅ Start/stop monitoring
- ✅ Timer-based updates (2-second interval)
- ✅ Published property updates
- ✅ Current song info formatting
- ✅ `hasSongPlaying` computed property
- ✅ Memory management (no retain cycles)
- ✅ Integration with Music.app bridge

**Requirements:**
- Can run without Music.app running
- Full integration requires Music.app

### 2. Integration Tests

#### MusicAppBridgeIntegrationTests
Tests for AppleScript integration with Music.app.

**Key Test Cases:**
- ✅ Initialization
- ✅ Update playback state (app running/not running)
- ✅ Get current track ID
- ✅ Track info formatting
- ✅ Error handling (app not running: -600 error)
- ✅ Multiple consecutive updates
- ✅ Performance metrics

**Requirements:**
- Can run without Music.app (tests graceful degradation)
- Full functionality requires Music.app running
- Manual tests available for real playback scenarios

**Manual Testing:**
For comprehensive integration testing:
1. Open Music.app
2. Play a song
3. Run integration tests
4. Verify real-time playback detection

### 3. UI Tests

#### MenuBarViewTests
Tests for SwiftUI MenuBar component.

**Key Test Cases:**
- ✅ View creation
- ✅ Authorization section (show/hide)
- ✅ Currently playing section display
- ✅ Song information rendering
- ✅ Playback status indicator (green/gray)
- ✅ Add to Favorites button (enabled/disabled states)
- ✅ Progress indicator visibility
- ✅ Notification posting (success/error)
- ✅ Reactive updates (authorization, playback, song changes)
- ✅ Edge cases (rapid state changes)

**Requirements:**
- Uses mock dependencies
- Tests UI logic without real MusicKit

### 4. Mock Implementations

#### MockMusicCatalog
Mock for MusadoraKit catalog operations.

**Features:**
- Configurable success/failure
- Track added/deleted ratings
- Error simulation

#### MockMusicKitManager
Mock for MusicKit authorization.

**Features:**
- Simulate authorization states
- Configure subscription status
- Track authorization requests

#### MockMusicAppBridge
Mock for AppleScript bridge.

**Features:**
- Simulate playback states
- Configure track information
- Simulate app not running/errors

#### MockPlaybackMonitor
Mock for playback monitoring.

**Features:**
- Set current song
- Control playback state
- Track method calls

## Test Coverage Goals

| Component | Target Coverage | Current Status |
|-----------|----------------|----------------|
| FavoritesService | 90%+ | ✅ Comprehensive |
| MusicKitManager | 90%+ | ✅ Comprehensive |
| PlaybackMonitor | 85%+ | ✅ Comprehensive |
| MusicAppBridge | 80%+ | ✅ Integration covered |
| MenuBarView | 75%+ | ✅ UI logic covered |

## Known Limitations

### 1. MusicKit Authorization
- Tests adapt to actual authorization state
- Cannot fully mock MusicAuthorization.request()
- Some tests may skip if authorization unavailable

### 2. Network Dependencies
- Song catalog searches require network access
- Tests use `XCTSkip` when network unavailable
- Consider CI/CD environment network access

### 3. Music.app Integration
- Integration tests work with/without Music.app
- Full integration requires Music.app running
- Manual tests recommended for complete validation

### 4. SwiftUI Testing
- Cannot directly inspect SwiftUI view hierarchy
- Tests validate state and logic, not visual rendering
- Consider snapshot testing for visual validation

## Best Practices

### Writing New Tests

1. **Use descriptive test names:**
   ```swift
   func testAddToFavorites_Success() { }
   func testAddToFavorites_NotAuthorized() { }
   ```

2. **Follow Given-When-Then pattern:**
   ```swift
   // Given: Setup test state
   let song = try await createMockSong()

   // When: Perform action
   let result = try await sut.addToFavorites(song: song)

   // Then: Assert results
   XCTAssertTrue(result)
   ```

3. **Use mocks for external dependencies:**
   ```swift
   let mockManager = MockMusicKitManager()
   mockManager.setAuthorized()
   ```

4. **Handle async operations properly:**
   ```swift
   func testAsync() async throws {
       await sut.startMonitoring()
       try await Task.sleep(nanoseconds: 100_000_000)
   }
   ```

5. **Clean up resources:**
   ```swift
   override func tearDown() async throws {
       sut.stopMonitoring()
       sut = nil
       try await super.tearDown()
   }
   ```

### Using Test Helpers

```swift
// Create test song
let song = try await createTestSong(title: "Test", artist: "Test Artist")

// Wait for condition
try await waitFor { mockManager.isAuthorized }

// Assert notification
try await assertNotificationPosted(.favoriteSuccess) {
    await service.addToFavorites(song: song)
}
```

## Continuous Integration

### Recommended CI Configuration

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - name: Run tests
        run: swift test --parallel
```

### Test Requirements
- macOS 14.0 (Sonoma) or later
- Swift 5.9+
- Xcode 15.0+

## Troubleshooting

### Common Issues

**1. "Unable to create mock song" error**
- **Cause:** No network access or MusicKit not authorized
- **Solution:** Tests will skip automatically with `XCTSkip`

**2. Timer tests flaky**
- **Cause:** Timing-dependent tests on slow CI
- **Solution:** Increase timeout values or disable on CI

**3. AppleScript tests fail**
- **Cause:** Sandboxing restrictions
- **Solution:** Ensure entitlements include AppleEvents

**4. Authorization tests inconsistent**
- **Cause:** Tests adapt to real authorization state
- **Solution:** Expected behavior; tests validate logic regardless

### Debug Tips

**Enable verbose output:**
```bash
swift test --verbose
```

**Run single test:**
```bash
swift test --filter testAddToFavorites_Success
```

**Check test logs:**
```swift
print("Debug: \(value)")  // Visible in test output
```

## Contributing

### Adding New Tests

1. Determine test category (Unit/Integration/UI)
2. Create test file in appropriate directory
3. Follow naming convention: `ComponentNameTests.swift`
4. Use existing mocks or create new ones
5. Follow best practices above
6. Update this README with new test coverage

### Code Review Checklist

- [ ] Tests follow Given-When-Then pattern
- [ ] Descriptive test names
- [ ] Proper async/await handling
- [ ] Resources cleaned up in tearDown
- [ ] Edge cases covered
- [ ] Documentation updated

## Resources

- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [Swift Testing Guide](https://swift.org/documentation/articles/testing.html)
- [MusicKit Documentation](https://developer.apple.com/documentation/musickit)
- [SwiftUI Testing](https://developer.apple.com/documentation/swiftui/testing)

## License

Tests follow the same license as the main StarTune project.

---

**Last Updated:** 2025-11-06
**Test Suite Version:** 1.0.0
