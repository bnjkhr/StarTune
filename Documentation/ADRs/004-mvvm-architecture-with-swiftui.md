# ADR-004: MVVM Architecture with SwiftUI and Dependency Injection

**Status:** Accepted

**Date:** 2025-10-24

**Decision Makers:** StarTune Development Team

## Context

StarTune requires a clear architectural pattern to manage complexity, ensure testability, and maintain code quality as the app evolves. The app needs to:

- Manage MusicKit authorization state
- Monitor Music.app playback continuously
- Handle async operations (networking, authorization)
- Update UI reactively
- Support future features (settings, keyboard shortcuts, notifications)

### Options Considered

1. **MVC (Model-View-Controller)**
   - Traditional AppKit pattern
   - Pros: Well-known, simple for small apps
   - Cons: Massive View Controllers, poor testability, not idiomatic for SwiftUI

2. **MVVM (Model-View-ViewModel)**
   - Separation of concerns: Views, ViewModels/Managers, Models
   - Pros: Clear responsibilities, testable, works naturally with SwiftUI
   - Cons: More classes, can be over-engineered

3. **MV (Model-View) / SwiftUI-Native**
   - Minimal architecture, Views directly observe Models
   - Pros: Simple, less code, embraces SwiftUI patterns
   - Cons: Tight coupling, hard to test, business logic in views

4. **The Composable Architecture (TCA)**
   - Highly structured Redux-like architecture
   - Pros: Pure functions, time-travel debugging, excellent testing
   - Cons: Steep learning curve, verbose, overkill for utility app

5. **VIPER (View-Interactor-Presenter-Entity-Router)**
   - Enterprise-grade architecture with strict layer separation
   - Pros: Maximum testability, clear boundaries
   - Cons: Massive overhead, too complex for small apps

## Decision

**We chose MVVM (Model-View-ViewModel) with Dependency Injection** implemented through SwiftUI's `@StateObject` and `@ObservedObject`.

## Rationale

### Why MVVM?

1. **Natural Fit with SwiftUI**
   ```swift
   // ViewModel publishes state
   class MusicKitManager: ObservableObject {
       @Published var isAuthorized = false
   }

   // View observes state
   struct MenuBarView: View {
       @ObservedObject var musicKitManager: MusicKitManager

       var body: some View {
           if musicKitManager.isAuthorized { ... }
       }
   }
   ```

   SwiftUI's `@Published` + `ObservableObject` pattern IS MVVM.

2. **Clear Separation of Concerns**
   ```
   ┌─────────────────────────────────────┐
   │            View Layer               │
   │  StarTuneApp, MenuBarView, etc.     │
   └─────────────┬───────────────────────┘
                 │ @ObservedObject
                 ↓
   ┌─────────────────────────────────────┐
   │       ViewModel/Manager Layer       │
   │  MusicKitManager, PlaybackMonitor   │
   │  FavoritesService, AppSettings      │
   └─────────────┬───────────────────────┘
                 │ Uses
                 ↓
   ┌─────────────────────────────────────┐
   │          Model Layer                │
   │  PlaybackState, Song (MusicKit)     │
   └─────────────────────────────────────┘
   ```

3. **Testability**
   ```swift
   // Easy to test in isolation
   func testAuthorization() {
       let manager = MusicKitManager()
       // Test without UI
       XCTAssertFalse(manager.canUseMusicKit)
   }
   ```

4. **Scalability**
   - Adding features means adding ViewModels/Managers
   - Views remain thin and focused on rendering
   - Business logic centralized and reusable

### Why Dependency Injection?

**Problem:** Views need managers, but shouldn't create them

**Solution:** Inject via initializers

```swift
// StarTuneApp (Composition Root)
@main
struct StarTuneApp: App {
    @StateObject private var musicKitManager = MusicKitManager()
    @StateObject private var playbackMonitor = PlaybackMonitor()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(
                musicKitManager: musicKitManager,  // ← Injection
                playbackMonitor: playbackMonitor
            )
        }
    }
}

// MenuBarView (receives dependencies)
struct MenuBarView: View {
    @ObservedObject var musicKitManager: MusicKitManager
    @ObservedObject var playbackMonitor: PlaybackMonitor
}
```

**Benefits:**
- ✅ Single source of truth (managers created once in `StarTuneApp`)
- ✅ Easy to test (inject mocks)
- ✅ Clear ownership (`@StateObject` owns, `@ObservedObject` borrows)
- ✅ No singletons needed

## Implementation Details

### Architecture Layers

#### 1. View Layer
**Files:**
- `StarTuneApp.swift` - App entry point, composition root
- `MenuBarView.swift` - Menu bar popover content
- `MenuBarController.swift` - AppKit integration (legacy, minimal)

**Responsibilities:**
- Render UI based on ViewModel state
- Handle user interactions
- Trigger ViewModel methods on user actions
- **No business logic**

#### 2. ViewModel/Manager Layer
**Files:**
- `MusicKitManager.swift` - Authorization and subscription state
- `PlaybackMonitor.swift` - Playback monitoring and Song resolution
- `FavoritesService.swift` - Favorites add/remove operations
- `AppSettings.swift` - User preferences

**Responsibilities:**
- Business logic and orchestration
- State management with `@Published` properties
- Async operations (networking, authorization)
- **No UI code**

#### 3. Model Layer
**Files:**
- `PlaybackState.swift` - Immutable value type for playback info
- `Song` (from MusicKit) - Track metadata

**Responsibilities:**
- Data structures
- Value types (structs) when possible
- **No logic, just data**

#### 4. Bridge Layer
**Files:**
- `MusicAppBridge.swift` - AppleScript communication

**Responsibilities:**
- External system integration
- Maps external data to app models
- Isolates platform-specific code

### Component Relationships

```
StarTuneApp (Composition Root)
    │
    ├─ @StateObject MusicKitManager
    │      ↓ Uses
    │      MusicKit Framework
    │
    ├─ @StateObject PlaybackMonitor
    │      ↓ Uses
    │      ├─ MusicAppBridge
    │      └─ MusicKit Catalog Search
    │
    └─ MenuBarExtra
           ├─ MenuBarView (@ObservedObject managers)
           │      ↓ Uses (created locally)
           │      FavoritesService
           │
           └─ Dynamic Icon (observes PlaybackMonitor.isPlaying)
```

### State Management Pattern

We use Combine's `@Published` for reactive updates:

```swift
// Manager publishes state changes
@MainActor
class PlaybackMonitor: ObservableObject {
    @Published var currentSong: Song?      // ← Publishes changes
    @Published var isPlaying = false       // ← Publishes changes

    private func updateState() {
        isPlaying = musicBridge.isPlaying  // ← Triggers UI update
    }
}

// View automatically updates when @Published changes
struct MenuBarView: View {
    @ObservedObject var playbackMonitor: PlaybackMonitor

    var body: some View {
        if playbackMonitor.isPlaying {     // ← Auto-refreshes
            Text("Playing")
        }
    }
}
```

**Why this works:**
- `@Published` emits `objectWillChange` notifications
- SwiftUI subscribes to these notifications automatically
- View re-renders only when observed properties change
- Efficient: Only changed views re-render

### Thread Safety Strategy

We use `@MainActor` to ensure UI updates on main thread:

```swift
@MainActor
class MusicKitManager: ObservableObject {
    @Published var isAuthorized = false  // ← Always updates on main thread

    func requestAuthorization() async {  // ← async but runs on MainActor
        let status = await MusicAuthorization.request()
        isAuthorized = (status == .authorized)  // ← Safe UI update
    }
}
```

**Benefits:**
- No manual `DispatchQueue.main.async` calls
- Compiler enforces main thread access
- Prevents data races and UI bugs

## Consequences

### Positive

- ✅ **Testable**: ViewModels can be tested without UI
- ✅ **Maintainable**: Clear responsibilities, easy to find code
- ✅ **Scalable**: Adding features doesn't bloat existing code
- ✅ **SwiftUI-Native**: Uses framework patterns, not fighting framework
- ✅ **Type-Safe**: Compile-time guarantees for state access
- ✅ **Reactive**: UI automatically updates, no manual sync needed

### Negative

- ❌ **More Classes**: More files than MV pattern (~2x)
- ❌ **Indirection**: Views don't directly access models (by design)
- ❌ **Learning Curve**: New developers must understand MVVM

### Neutral

- ⚪ **Boilerplate**: Moderate amount (less than VIPER, more than MV)
- ⚪ **Flexibility**: Less structured than TCA, more than MV

## Trade-offs Analysis

### MVVM vs MV (SwiftUI-Native)

**MV Approach (rejected):**
```swift
// View directly creates and owns manager
struct MenuBarView: View {
    @StateObject private var musicKitManager = MusicKitManager()

    var body: some View {
        Button("Authorize") {
            Task { await musicKitManager.requestAuthorization() }
        }
    }
}
```

**Problems:**
- ❌ Manager recreated every time view appears
- ❌ Hard to test (manager tightly coupled to view)
- ❌ Can't share state between views
- ❌ Business logic leaks into view layer

**MVVM Approach (chosen):**
```swift
// App creates and injects manager
@main
struct StarTuneApp: App {
    @StateObject private var musicKitManager = MusicKitManager()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(musicKitManager: musicKitManager)  // ← Injected
        }
    }
}
```

**Benefits:**
- ✅ Manager created once, lives for app lifetime
- ✅ Easy to test (inject mock manager)
- ✅ State shared across views
- ✅ Clear separation

### MVVM vs TCA

**TCA Approach (rejected):**
```swift
struct AppState {
    var musicKitState: MusicKitState
    var playbackState: PlaybackState
}

enum AppAction {
    case musicKit(MusicKitAction)
    case playback(PlaybackAction)
}

let appReducer = Reducer<AppState, AppAction, AppEnvironment> { state, action, environment in
    // Pure function handling state transitions
}
```

**Why rejected:**
- ❌ Overkill for utility app
- ❌ Steep learning curve
- ❌ Verbose (3-4x more code)
- ❌ Async/await integration is awkward

**When TCA would be better:**
- Large team needing strict architecture
- Complex state machines
- Time-travel debugging requirements
- Apps with extensive business logic

## Validation

### Code Metrics

| Metric | Value | Assessment |
|--------|-------|------------|
| **Total files** | 9 Swift files | ✅ Manageable |
| **Lines per file** | 100-400 LOC | ✅ Readable |
| **Cyclomatic complexity** | <10 per method | ✅ Simple |
| **Test coverage** | TBD | ⚪ Tests pending |

### Architecture Health Indicators

✅ **Good Signs:**
- No circular dependencies
- Views have no business logic
- Managers are pure Swift (no SwiftUI imports except @ObservedObject protocol)
- Clear data flow (unidirectional: Manager → View)

⚠️ **Watch For:**
- Managers growing too large (currently all <400 LOC, good)
- Views creating their own @StateObject managers (none found, good)
- Singletons appearing (none exist, good)

### Maintainability Assessment

**Adding a new feature requires:**
1. Create new Manager/Service (if needed)
2. Add to StarTuneApp composition root
3. Inject into relevant views
4. Use `@Published` for state
5. Views react automatically

**Example: Adding keyboard shortcuts**
```swift
// 1. Create manager
@MainActor
class KeyboardShortcutManager: ObservableObject {
    @Published var isEnabled = false
    func registerShortcut() { ... }
}

// 2. Add to composition root
@main
struct StarTuneApp: App {
    @StateObject private var shortcutManager = KeyboardShortcutManager()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(
                ...,
                shortcutManager: shortcutManager  // ← Inject
            )
        }
    }
}

// 3. Done! Views can now use it
```

**Effort:** ~30 minutes, very predictable pattern

## Alternative Patterns Considered

### Singleton Pattern

```swift
// Rejected approach
class MusicKitManager {
    static let shared = MusicKitManager()
    private init() {}
}

// Usage
MusicKitManager.shared.requestAuthorization()
```

**Why rejected:**
- ❌ Hard to test (can't inject mocks)
- ❌ Global state (implicit dependencies)
- ❌ Not SwiftUI-friendly (doesn't integrate with @ObservedObject)
- ❌ Anti-pattern in modern Swift

### Environment Objects

```swift
// Considered but rejected
@main
struct StarTuneApp: App {
    @StateObject private var musicKitManager = MusicKitManager()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(musicKitManager)  // ← Environment injection
        }
    }
}

struct MenuBarView: View {
    @EnvironmentObject var musicKitManager: MusicKitManager  // ← Implicit dependency
}
```

**Why rejected:**
- ❌ Implicit dependencies (less clear than explicit injection)
- ❌ Runtime crashes if environment not set
- ❌ Harder to track dependencies
- ✅ More convenient for deep hierarchies

**When we'd use it:**
- Deep view hierarchies (5+ levels)
- Truly app-wide state (theme, locale)
- StarTune is too small to benefit

## Future Considerations

### If App Complexity Grows

**Indicators to reconsider architecture:**
1. Files exceed 500 LOC consistently
2. Managers have 10+ `@Published` properties
3. Complex state machines needed
4. Team grows beyond 2-3 developers

**Potential migrations:**
- MVVM → TCA (if complexity demands it)
- Add Coordinator pattern for navigation (if multi-window)
- Extract domain layer (if business logic grows)

### Testing Strategy

**Current:**
- No unit tests yet (acceptable for v1.0 utility app)

**Future:**
```swift
// Unit test example
class MusicKitManagerTests: XCTestCase {
    func testAuthorizationRequest() async {
        let manager = MusicKitManager()
        await manager.requestAuthorization()
        XCTAssertTrue(manager.isAuthorized)
    }
}

// UI test with mocks
struct MenuBarView_Previews: PreviewProvider {
    static var previews: some View {
        let mockManager = MusicKitManager()
        mockManager.isAuthorized = true  // Mock state

        return MenuBarView(musicKitManager: mockManager)
    }
}
```

## Review Cycle

This ADR should be reviewed if:

1. **Complexity increases**: Adding 5+ new features
2. **Team grows**: More than 3 developers
3. **Testing becomes priority**: Need comprehensive test suite
4. **SwiftUI patterns change**: Major SwiftUI updates

**Next Review Date:** 2026-10-24 (1 year) or when adding complex features

## References

- [SwiftUI MVVM Pattern](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app)
- [Combine Framework](https://developer.apple.com/documentation/combine)
- [ObservableObject Protocol](https://developer.apple.com/documentation/combine/observableobject)
- [Dependency Injection in Swift](https://www.swiftbysundell.com/articles/dependency-injection-using-functions-in-swift/)

## Author

StarTune Development Team

## Change Log

- 2025-10-24: Initial decision recorded
- 2025-10-24: Added validation metrics and future considerations
