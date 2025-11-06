# Error Handling Improvements

This document demonstrates the comprehensive error handling improvements made to StarTune, including typed error propagation, user-friendly messages, retry logic with exponential backoff, and privacy-preserving error analytics.

## Table of Contents

1. [Overview](#overview)
2. [Typed Error Propagation](#typed-error-propagation)
3. [User-Friendly Error Messages](#user-friendly-error-messages)
4. [Retry Logic with Exponential Backoff](#retry-logic-with-exponential-backoff)
5. [Privacy-Preserving Error Analytics](#privacy-preserving-error-analytics)
6. [Before/After Code Examples](#beforeafter-code-examples)

---

## Overview

The error handling improvements introduce a comprehensive, type-safe error management system that:

- **Categorizes errors** into specific types (Network, Authorization, Resource, Operation, System)
- **Provides user-friendly messages** with recovery suggestions
- **Automatically retries** transient failures with exponential backoff
- **Tracks error patterns** without collecting sensitive user data
- **Propagates errors through async/await chains** with full type information

### Architecture

```
ErrorHandling/
├── AppError.swift          # Typed error definitions with recovery suggestions
├── RetryManager.swift      # Retry logic with exponential backoff
├── ErrorAnalytics.swift    # Privacy-preserving error tracking
└── ErrorPresenter.swift    # User-friendly error presentation
```

---

## Typed Error Propagation

### Before: Generic Error Handling

```swift
// ❌ Old approach - Generic errors with no type safety
func addToFavorites(song: Song) async throws -> Bool {
    do {
        _ = try await MCatalog.addRating(for: song, rating: .like)
        return true
    } catch {
        print("❌ Error: \(error.localizedDescription)")
        throw FavoritesError.networkError  // Generic, loses error details
    }
}
```

**Problems:**
- No distinction between different error types
- Loses original error information
- Difficult to handle different error cases appropriately
- No guidance on whether errors are retryable

### After: Typed Error Propagation

```swift
// ✅ New approach - Typed errors with full context
func addToFavorites(song: Song) async throws -> Bool {
    do {
        let result = try await RetryManager.shared.retryCritical(
            operationName: "addToFavorites"
        ) {
            try await MCatalog.addRating(for: song, rating: .like)
        }
        return true
    } catch let error as MusadoraKitError {
        let appError = mapMusadoraKitError(error)  // Typed mapping
        recordError(appError, operation: "addToFavorites")
        throw appError
    } catch {
        let appError = AppError.from(error)  // Smart conversion
        recordError(appError, operation: "addToFavorites")
        throw appError
    }
}

private func mapMusadoraKitError(_ error: MusadoraKitError) -> AppError {
    switch error {
    case .notAuthorized:
        return .authorizationError(.notAuthorized)  // Specific type
    case .noSubscription:
        return .authorizationError(.noSubscription)
    case .networkError, .urlError:
        return .networkError(.requestFailed(error))
    case .notFound:
        return .resourceError(.notFound("song"))
    default:
        return .networkError(.requestFailed(error))
    }
}
```

**Benefits:**
- Each error has a specific type with full context
- Errors can be handled differently based on type
- Automatic retry logic for retryable errors
- Analytics tracking integrated

---

## User-Friendly Error Messages

### Before: Technical Error Messages

```swift
// ❌ Old approach - Technical messages
enum FavoritesError: LocalizedError {
    case notAuthorized
    case networkError

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Please authorize access to Apple Music"
        case .networkError:
            return "Could not connect to Apple Music"
        }
    }
}
```

**Problems:**
- No recovery suggestions
- No context about why the error occurred
- No guidance on what the user should do next

### After: User-Friendly Messages with Recovery Suggestions

```swift
// ✅ New approach - User-friendly with recovery guidance
enum AuthorizationError: Error {
    case notAuthorized
    case denied
    case noSubscription
}

extension AuthorizationError: UserFriendlyError {
    var title: String {
        switch self {
        case .notAuthorized:
            return "Authorization Required"
        case .denied:
            return "Permission Denied"
        case .noSubscription:
            return "Subscription Required"
        }
    }

    var message: String {
        switch self {
        case .notAuthorized:
            return "StarTune needs permission to access Apple Music. Please grant authorization in the prompt."
        case .denied:
            return "You've denied permission to access Apple Music. StarTune needs this permission to add songs to your favorites."
        case .noSubscription:
            return "An active Apple Music subscription is required to add songs to your favorites."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .notAuthorized:
            return "Click 'Request Authorization' to grant permission"
        case .denied:
            return "Go to System Settings → Privacy → Media & Apple Music to grant permission"
        case .noSubscription:
            return "Subscribe to Apple Music to use this feature"
        }
    }
}
```

**Example Error Display:**

```
❌ Permission Denied

You've denied permission to access Apple Music. StarTune needs this
permission to add songs to your favorites.

💡 Go to System Settings → Privacy → Media & Apple Music to grant permission
```

**Benefits:**
- Clear title indicating the problem
- Detailed explanation in user-friendly language
- Specific recovery suggestions
- Consistent error presentation across the app

---

## Retry Logic with Exponential Backoff

### Before: No Retry Logic

```swift
// ❌ Old approach - Fails immediately on transient errors
func addToFavorites(song: Song) async throws -> Bool {
    _ = try await MCatalog.addRating(for: song, rating: .like)
    return true
}
```

**Problems:**
- Network timeouts cause immediate failure
- Transient errors (temporary network issues) fail operations
- No differentiation between permanent and temporary failures
- Poor user experience during brief network interruptions

### After: Automatic Retry with Exponential Backoff

```swift
// ✅ New approach - Automatic retry for transient failures
func addToFavorites(song: Song) async throws -> Bool {
    let result = try await RetryManager.shared.retryCritical(
        operationName: "addToFavorites"
    ) {
        try await MCatalog.addRating(for: song, rating: .like)
    }
    return true
}
```

**How It Works:**

```swift
// Retry configuration
struct RetryConfig {
    let maxAttempts: Int = 5          // Try up to 5 times
    let baseDelay: TimeInterval = 0.5 // Start with 0.5s delay
    let maxDelay: TimeInterval = 60.0 // Cap at 60s
    let multiplier: Double = 2.0      // Double each time
    let jitter: Double = 0.15         // Add randomness
}

// Exponential backoff calculation
// Attempt 1: 0.5s
// Attempt 2: 1.0s (0.5 * 2^1)
// Attempt 3: 2.0s (0.5 * 2^2)
// Attempt 4: 4.0s (0.5 * 2^3)
// Attempt 5: 8.0s (0.5 * 2^4)
```

**Console Output Example:**

```
Adding song to favorites: "Blinding Lights"
⚠️ Retry attempt 1/5 after 0.5s: Network timeout
⚠️ Retry attempt 2/5 after 1.2s: Network timeout
✅ Successfully added 'Blinding Lights' to favorites
```

**Benefits:**
- Automatically retries transient failures
- Exponential backoff prevents overwhelming servers
- Jitter prevents thundering herd problem
- Only retries when appropriate (network errors, not authorization)
- Tracks statistics for each operation

### Retry Configurations

```swift
// Network operations (3 attempts, 1s base delay)
RetryManager.shared.retryNetwork { ... }

// Critical operations (5 attempts, 0.5s base delay)
RetryManager.shared.retryCritical { ... }

// Quick retries (2 attempts, 0.5s base delay)
RetryManager.shared.retryQuick { ... }

// Custom configuration
let config = RetryConfig(
    maxAttempts: 4,
    baseDelay: 2.0,
    maxDelay: 30.0,
    multiplier: 3.0,
    jitter: 0.2
)
RetryManager.shared.retry(config: config) { ... }
```

---

## Privacy-Preserving Error Analytics

### Before: No Error Tracking

```swift
// ❌ Old approach - Errors lost, no insights
catch {
    print("Error: \(error)")
    // Error information disappears
}
```

**Problems:**
- No visibility into error patterns
- Can't identify problematic operations
- No data for improving reliability
- Can't measure error rates or success rates

### After: Privacy-Preserving Analytics

```swift
// ✅ New approach - Track errors without exposing user data
catch {
    let appError = AppError.from(error)
    recordError(
        appError,
        operation: "addToFavorites",
        userAction: "add_song_to_favorites"
    )
    throw appError
}
```

**What Gets Tracked (Privacy-Safe):**

```swift
struct ErrorEvent {
    let timestamp: Date                    // When it occurred
    let errorType: String                  // "Network.timeout"
    let location: String?                  // "FavoritesService.swift:45"
    let operation: String?                 // "addToFavorites"
    let userAction: String?                // "add_song_to_favorites"
    let isRetryable: Bool                  // true/false

    // ❌ NO user data collected:
    // - No song names, artist names, or other content
    // - No user identifiers
    // - No IP addresses
    // - No personal information
}
```

**Analytics Summary Example:**

```json
{
  "totalErrors": 47,
  "errorsLast24Hours": 12,
  "errorsLast7Days": 47,
  "retryableErrorsPercentage": 0.68,
  "topErrorTypes": [
    {
      "type": "Network.timeout",
      "count": 15
    },
    {
      "type": "Network.noConnection",
      "count": 8
    },
    {
      "type": "Authorization.noSubscription",
      "count": 3
    }
  ],
  "topErrorOperations": [
    {
      "operation": "addToFavorites",
      "errorCount": 20
    },
    {
      "operation": "catalogSearch",
      "errorCount": 15
    }
  ],
  "resolutionStats": {
    "Network.timeout": {
      "retry": 12,
      "manual": 3
    }
  }
}
```

**Benefits:**
- Identify which operations fail most often
- Track error rates over time
- Measure effectiveness of retry logic
- No PII (Personally Identifiable Information) collected
- All data stays local on the device
- Helps improve app reliability

---

## Before/After Code Examples

### Example 1: Adding Song to Favorites

#### Before

```swift
func addToFavorites(song: Song) async throws -> Bool {
    print("Adding song to favorites: \(song.title)")

    do {
        _ = try await MCatalog.addRating(for: song, rating: .like)
        print("✅ Successfully added '\(song.title)' to favorites")
        return true
    } catch let error as MusadoraKitError {
        print("❌ Error adding to favorites: \(error.localizedDescription)")
        throw mapMusadoraKitError(error)  // Returns FavoritesError
    } catch {
        print("❌ Error adding to favorites: \(error.localizedDescription)")
        throw FavoritesError.networkError
    }
}
```

**Issues:**
- ❌ No retry logic - fails immediately on timeout
- ❌ Generic error types lose context
- ❌ No analytics or error tracking
- ❌ No user-friendly messages

#### After

```swift
func addToFavorites(song: Song) async throws -> Bool {
    print("Adding song to favorites: \(song.title)")

    // Use retry logic for network operations
    do {
        let result = try await RetryManager.shared.retryCritical(
            operationName: "addToFavorites"
        ) {
            // Apple Music verwendet Ratings für "Favoriten"
            // .like = Liked/Favorited, .dislike = Disliked
            try await MCatalog.addRating(for: song, rating: .like)
        }

        print("✅ Successfully added '\(song.title)' to favorites")

        // Record success for analytics
        await ErrorAnalytics.shared.recordResolution(
            FavoritesError.networkError,
            method: .automatic
        )

        return true
    } catch let error as MusadoraKitError {
        let appError = mapMusadoraKitError(error)
        print("❌ Error adding to favorites: \(appError.message)")

        // Record error for analytics
        recordError(
            appError,
            operation: "addToFavorites",
            userAction: "add_song_to_favorites"
        )

        throw appError
    } catch {
        let appError = AppError.from(error)
        print("❌ Error adding to favorites: \(appError.message)")

        // Record error for analytics
        recordError(
            appError,
            operation: "addToFavorites",
            userAction: "add_song_to_favorites"
        )

        throw appError
    }
}

private func mapMusadoraKitError(_ error: MusadoraKitError) -> AppError {
    switch error {
    case .notAuthorized:
        return .authorizationError(.notAuthorized)
    case .noSubscription:
        return .authorizationError(.noSubscription)
    case .networkError, .urlError:
        return .networkError(.requestFailed(error))
    case .notFound:
        return .resourceError(.notFound("song"))
    default:
        return .networkError(.requestFailed(error))
    }
}
```

**Improvements:**
- ✅ Automatic retry with exponential backoff (up to 5 attempts)
- ✅ Typed errors with full context
- ✅ Analytics tracking for error patterns
- ✅ User-friendly error messages with recovery suggestions
- ✅ Success tracking for resolution analytics

---

### Example 2: Catalog Search

#### Before

```swift
private func findSongInCatalog(trackName: String, artist: String?) async {
    do {
        var searchTerm = trackName
        if let artist = artist {
            searchTerm += " \(artist)"
        }

        var searchRequest = MusicCatalogSearchRequest(term: searchTerm, types: [Song.self])
        searchRequest.limit = 5

        let response = try await searchRequest.response()

        if let firstSong = response.songs.first {
            currentSong = firstSong
            print("✅ Found song: \(firstSong.title)")
        } else {
            print("⚠️ No song found for: \(searchTerm)")
            currentSong = nil
        }
    } catch {
        print("❌ Error searching for song: \(error.localizedDescription)")
        currentSong = nil
    }
}
```

**Issues:**
- ❌ Silent failure - errors not tracked
- ❌ No retry for transient failures
- ❌ Generic error message
- ❌ Background failures go unnoticed

#### After

```swift
private func findSongInCatalog(trackName: String, artist: String?) async {
    do {
        var searchTerm = trackName
        if let artist = artist {
            searchTerm += " \(artist)"
        }

        // Use quick retry logic for catalog search (2 attempts, 0.5s delay)
        let response = try await RetryManager.shared.retryQuick(
            operationName: "catalogSearch"
        ) {
            var searchRequest = MusicCatalogSearchRequest(term: searchTerm, types: [Song.self])
            searchRequest.limit = 5
            return try await searchRequest.response()
        }

        if let firstSong = response.songs.first {
            currentSong = firstSong
            print("✅ Found song: \(firstSong.title) by \(firstSong.artistName)")
        } else {
            print("⚠️ No song found for: \(searchTerm)")
            currentSong = nil
        }
    } catch {
        let appError = AppError.from(error)

        // Record error for analytics but don't show to user (background operation)
        recordError(
            appError,
            operation: "catalogSearch",
            userAction: "background_playback_monitoring"
        )

        print("❌ Error searching for song: \(appError.message)")
        currentSong = nil
    }
}
```

**Improvements:**
- ✅ Automatic retry for transient failures (2 attempts)
- ✅ Error analytics tracking
- ✅ Typed error conversion
- ✅ Background error monitoring

---

### Example 3: Subscription Check

#### Before

```swift
private func checkSubscriptionStatus() async {
    do {
        let subscription = try await MusicSubscription.current
        hasAppleMusicSubscription = subscription.canPlayCatalogContent
    } catch {
        print("Error checking subscription status: \(error.localizedDescription)")
        hasAppleMusicSubscription = false
    }
}
```

**Issues:**
- ❌ No retry logic
- ❌ Generic error handling
- ❌ No error tracking

#### After

```swift
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
```

**Improvements:**
- ✅ Network retry logic (3 attempts)
- ✅ Typed error conversion
- ✅ Error analytics
- ✅ User-friendly error messages

---

### Example 4: Error Presentation in SwiftUI

#### Before

```swift
// ❌ Generic alert with technical message
.alert("Error", isPresented: $showError) {
    Button("OK") { }
} message: {
    Text(errorMessage)
}
```

#### After

```swift
// ✅ User-friendly error with recovery guidance
@StateObject private var errorHandler = ErrorHandler()

var body: some View {
    VStack {
        // Your view content
    }
    .errorAlert($errorHandler.currentError)
}

// Usage
do {
    try await favoritesService.addToFavorites(song: song)
} catch {
    errorHandler.handle(error)  // Shows user-friendly alert
}
```

**Error Alert Example:**

```
┌─────────────────────────────────────┐
│  ⚠️ No Internet Connection          │
│                                      │
│  Unable to connect to the internet. │
│  Please check your connection and   │
│  try again.                          │
│                                      │
│  💡 Check your internet connection  │
│     and try again                    │
│                                      │
│           [ OK ]                     │
└─────────────────────────────────────┘
```

---

## Summary of Improvements

### 1. **Typed Error Propagation**
- ✅ Comprehensive error type hierarchy
- ✅ Automatic error categorization
- ✅ Full context preservation through async chains
- ✅ Clear distinction between error categories

### 2. **User-Friendly Messages**
- ✅ Clear, non-technical language
- ✅ Specific recovery suggestions
- ✅ Contextual help for each error type
- ✅ Consistent presentation across the app

### 3. **Retry Logic**
- ✅ Automatic retry for transient failures
- ✅ Exponential backoff with jitter
- ✅ Configurable retry strategies
- ✅ Statistics tracking for each operation

### 4. **Privacy-Preserving Analytics**
- ✅ Track error patterns without PII
- ✅ Identify problematic operations
- ✅ Measure success/failure rates
- ✅ Local-only analytics (no data sent externally)

### 5. **Code Quality**
- ✅ Consistent error handling patterns
- ✅ Reduced boilerplate code
- ✅ Better testability
- ✅ Improved maintainability

---

## Usage Guidelines

### When to Use Each Retry Strategy

```swift
// Critical operations (user-initiated, must succeed)
// 5 attempts, 0.5s base delay
RetryManager.shared.retryCritical { ... }

// Network operations (standard reliability)
// 3 attempts, 1s base delay
RetryManager.shared.retryNetwork { ... }

// Quick operations (background, non-critical)
// 2 attempts, 0.5s base delay
RetryManager.shared.retryQuick { ... }
```

### Recording Errors

```swift
// Automatic context (recommended)
recordError(
    error,
    operation: "operationName",
    userAction: "user_action_description"
)

// Manual context
let context = ErrorContext(
    location: "FileName.swift:123",
    operation: "operationName",
    userAction: "user_action_description"
)
await ErrorAnalytics.shared.recordError(error, context: context)
```

### Viewing Analytics

```swift
// Get summary
let summary = await ErrorAnalytics.shared.getSummary()
print("Total errors: \(summary.totalErrors)")
print("Success rate: \(summary.successRate)%")

// Export analytics
let json = await ErrorAnalytics.shared.exportAnalytics()
print(json)
```

---

## Testing Error Handling

### Test Network Errors

```swift
// Simulate network timeout
let error = AppError.networkError(.timeout)
XCTAssertTrue(error.isRetryable)
XCTAssertEqual(error.title, "Request Timed Out")

// Test retry logic
var attempts = 0
let result = try await RetryManager.shared.retry(config: .quick) {
    attempts += 1
    if attempts < 2 {
        throw AppError.networkError(.timeout)
    }
    return "Success"
}
XCTAssertEqual(attempts, 2)
XCTAssertEqual(result, "Success")
```

### Test Authorization Errors

```swift
let error = AppError.authorizationError(.notAuthorized)
XCTAssertFalse(error.isRetryable)  // Don't retry auth errors
XCTAssertEqual(error.recoverySuggestion, "Click 'Request Authorization' to grant permission")
```

---

## Migration Guide

### Step 1: Update Error Handling

Replace generic error handling:

```swift
// Old
catch {
    throw FavoritesError.networkError
}

// New
catch {
    let appError = AppError.from(error)
    recordError(appError, operation: "operationName")
    throw appError
}
```

### Step 2: Add Retry Logic

Wrap network operations:

```swift
// Old
let result = try await networkOperation()

// New
let result = try await RetryManager.shared.retryNetwork {
    try await networkOperation()
}
```

### Step 3: Update UI

Replace generic alerts:

```swift
// Old
.alert("Error", isPresented: $showError) { }

// New
@StateObject private var errorHandler = ErrorHandler()
.errorAlert($errorHandler.currentError)
```

---

## Performance Impact

- **Retry Logic**: Minimal overhead when operations succeed first time
- **Analytics**: Async recording, no UI blocking
- **Memory**: ~1KB per error event, max 100 events stored
- **Battery**: Negligible impact from exponential backoff delays

---

## Future Enhancements

- [ ] Circuit breaker pattern for cascading failures
- [ ] Remote analytics aggregation (opt-in)
- [ ] Error rate alerting for developers
- [ ] Automatic error report generation
- [ ] Machine learning for predicting transient failures

---

## References

- `ErrorHandling/AppError.swift` - Error type definitions
- `ErrorHandling/RetryManager.swift` - Retry logic implementation
- `ErrorHandling/ErrorAnalytics.swift` - Analytics system
- `ErrorHandling/ErrorPresenter.swift` - UI presentation helpers
