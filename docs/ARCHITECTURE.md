# StarTune Architecture Documentation

Technische Architektur-Dokumentation der StarTune macOS App.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture Pattern](#architecture-pattern)
3. [Layer Architecture](#layer-architecture)
4. [Component Diagrams](#component-diagrams)
5. [Data Flow](#data-flow)
6. [Communication Patterns](#communication-patterns)
7. [Threading Model](#threading-model)
8. [State Management](#state-management)
9. [Dependency Graph](#dependency-graph)
10. [Design Decisions](#design-decisions)
11. [Performance Considerations](#performance-considerations)
12. [Security Architecture](#security-architecture)

---

## Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────┐
│                   StarTune App                      │
│                                                     │
│  ┌───────────┐  ┌──────────────┐  ┌────────────┐  │
│  │    UI     │  │   Business   │  │  External  │  │
│  │   Layer   │◄─┤    Logic     │◄─┤  Services  │  │
│  │           │  │              │  │            │  │
│  └───────────┘  └──────────────┘  └────────────┘  │
│       │               │                   │        │
│       │               │                   │        │
│   SwiftUI        Managers/           MusicKit      │
│   AppKit         UseCases            AppleScript   │
└─────────────────────────────────────────────────────┘
```

### Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Presentation** | SwiftUI + AppKit | UI Rendering & User Interaction |
| **Business Logic** | Swift Concurrency | Managers & Use Cases |
| **Data** | MusicKit + ScriptingBridge | Music Data & Playback Info |
| **Reactive** | Combine | State Propagation |
| **Networking** | URLSession (via MusicKit) | Apple Music API Calls |

---

## Architecture Pattern

### MVVM (Model-View-ViewModel)

```
┌─────────────┐
│    View     │  SwiftUI Views (MenuBarView)
│  (SwiftUI)  │  └─> Presentation Logic Only
└──────┬──────┘
       │ @ObservedObject
       ▼
┌─────────────┐
│  ViewModel  │  Observable Objects (Managers)
│ (@Published)│  └─> Business Logic + State
└──────┬──────┘
       │ Uses
       ▼
┌─────────────┐
│    Model    │  Data Models (PlaybackState, Song)
│   (Struct)  │  └─> Pure Data, No Logic
└─────────────┘
```

### Component Breakdown

**Views (UI Layer):**
- `MenuBarView` - SwiftUI Popover Content
- `MenuBarController` - AppKit NSStatusItem Wrapper

**ViewModels (Business Logic):**
- `MusicKitManager` - Authorization & Subscription
- `PlaybackMonitor` - Song Detection & State
- `MusicAppBridge` - Music.app Communication

**Models (Data Layer):**
- `PlaybackState` - Playback Snapshot
- `AppSettings` - User Preferences
- `Song` (MusicKit) - Song Entity

**Services:**
- `FavoritesService` - Favorites API Wrapper

---

## Layer Architecture

### 1. Presentation Layer

```
StarTuneApp.swift
    │
    ├─> MenuBarExtra (SwiftUI)
    │       │
    │       └─> MenuBarView
    │
    └─> MenuBarController (AppKit)
            └─> NSStatusItem
```

**Responsibilities:**
- UI Rendering
- User Input Handling
- Visual Feedback (Animations)
- Menu Bar Integration

**Key Components:**

#### StarTuneApp
```swift
@main
struct StarTuneApp: App {
    @StateObject private var musicKitManager = MusicKitManager()
    @StateObject private var playbackMonitor = PlaybackMonitor()
}
```

**Role:** App Entry Point & Lifecycle Owner

**Lifetime:** App Lifetime (Singleton)

#### MenuBarView
```swift
struct MenuBarView: View {
    @ObservedObject var musicKitManager: MusicKitManager
    @ObservedObject var playbackMonitor: PlaybackMonitor
}
```

**Role:** Popover UI Content

**Lifetime:** Recreated bei jedem Popover Open

#### MenuBarController
```swift
class MenuBarController: ObservableObject {
    private var statusItem: NSStatusItem?
}
```

**Role:** NSStatusItem Management (AppKit Bridge)

**Lifetime:** App Lifetime

---

### 2. Business Logic Layer

```
MusicKitManager
    ├─> Authorization Flow
    └─> Subscription Check

PlaybackMonitor
    ├─> Playback Detection
    ├─> Song Search
    └─> State Updates

MusicAppBridge
    ├─> AppleScript Execution
    └─> Music.app Communication

FavoritesService
    ├─> Add to Favorites
    └─> Remove from Favorites
```

**Responsibilities:**
- Business Rules
- Data Transformation
- API Orchestration
- Error Handling

**Communication Pattern:**

```
View → ViewModel → Service → External API
       (Manager)
```

**Example Flow:**
```
MenuBarView.addToFavorites()
    ↓
FavoritesService.addToFavorites(song:)
    ↓
MusadoraKit.MCatalog.addRating(for:rating:)
    ↓
MusicKit API (iCloud)
```

---

### 3. Data Layer

```
Models/
├── PlaybackState.swift    (Playback Snapshot)
├── AppSettings.swift      (User Preferences)
└── Song (MusicKit)        (Music Entity)
```

**Characteristics:**
- **Immutable** (Structs preferred)
- **Value Types** (Copy Semantics)
- **No Business Logic** (Pure Data)

**Data Flow:**

```
External API → Model → ViewModel → View
                ↓
           @Published
                ↓
              View
```

---

## Component Diagrams

### App Lifecycle Flow

```
┌──────────────┐
│ App Launch   │
└──────┬───────┘
       │
       ▼
┌──────────────────────────┐
│ StarTuneApp.init()       │
│ - Create Managers        │
│ - Setup Menu Bar         │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│ MenuBarExtra appears     │
│ - Show Icon              │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│ .onAppear triggered      │
│ - setupApp()             │
└──────┬───────────────────┘
       │
       ├─────────────────────┐
       │                     │
       ▼                     ▼
┌──────────────────┐  ┌──────────────────┐
│ Request Auth     │  │ Start Monitoring │
└──────────────────┘  └──────────────────┘
```

### Authorization Flow

```
┌─────────────────┐
│ User Action:    │
│ "Allow Access"  │
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│ MusicKitManager         │
│ .requestAuthorization() │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ MusicAuthorization      │
│ .request()              │
│ (System Dialog)         │
└────────┬────────────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
 Success   Denied
    │         │
    ▼         ▼
┌─────────┐ ┌──────────┐
│ Check   │ │ Show     │
│ Sub     │ │ Error    │
└─────────┘ └──────────┘
```

### Playback Monitoring Flow

```
┌───────────────────┐
│ Timer fires       │
│ (every 2s)        │
└─────────┬─────────┘
          │
          ▼
┌────────────────────────┐
│ MusicAppBridge         │
│ .updatePlaybackState() │
└─────────┬──────────────┘
          │
          ▼
┌────────────────────────┐
│ AppleScript Execution  │
│ "tell Music app..."    │
└─────────┬──────────────┘
          │
          ▼
┌────────────────────────┐
│ Parse Result           │
│ trackName | artist     │
└─────────┬──────────────┘
          │
          ▼
┌────────────────────────┐
│ MusicKit Catalog       │
│ Search for Song        │
└─────────┬──────────────┘
          │
          ▼
┌────────────────────────┐
│ Update @Published      │
│ - currentSong          │
│ - isPlaying            │
└────────────────────────┘
          │
          ▼
┌────────────────────────┐
│ UI Auto-Updates        │
│ (SwiftUI Bindings)     │
└────────────────────────┘
```

### Favorites Flow

```
┌─────────────────┐
│ User clicks     │
│ "Add to         │
│  Favorites"     │
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│ MenuBarView             │
│ .addToFavorites()       │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ FavoritesService        │
│ .addToFavorites(song:)  │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ MusadoraKit             │
│ MCatalog.addRating()    │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ MusicKit API            │
│ (Network Request)       │
└────────┬────────────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
 Success   Error
    │         │
    ▼         ▼
┌─────────┐ ┌──────────┐
│ Post    │ │ Post     │
│ Success │ │ Error    │
│ Notif   │ │ Notif    │
└────┬────┘ └────┬─────┘
     │           │
     └─────┬─────┘
           ▼
┌───────────────────────┐
│ MenuBarController     │
│ .showAnimation()      │
└───────────────────────┘
```

---

## Data Flow

### State Propagation

```
External Change
       │
       ▼
   @Published Property
       │
       ├──> objectWillChange
       │
       ▼
   SwiftUI View
       │
       └──> body recomputed
```

**Example:**

```swift
// 1. State Change
playbackMonitor.isPlaying = true  // @Published

// 2. Auto Notification
// objectWillChange.send() (automatic)

// 3. View Updates
MenuBarView.body {
    if playbackMonitor.isPlaying {
        Text("Playing")  // Automatically re-renders
    }
}
```

### Unidirectional Data Flow

```
┌─────────────┐
│   Action    │  User Click / Timer / API Response
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Manager    │  Process & Update State
│ (@Published)│
└──────┬──────┘
       │
       ▼
┌─────────────┐
│    View     │  Re-render based on new State
└─────────────┘
```

**No Bidirectional Binding** (except Form Inputs)

---

## Communication Patterns

### 1. Observable Objects (@Published)

**Use Case:** Manager → View Communication

```swift
// Manager
class PlaybackMonitor: ObservableObject {
    @Published var isPlaying = false  // Auto-notifies
}

// View
struct MyView: View {
    @ObservedObject var monitor: PlaybackMonitor
    
    var body: some View {
        Text(monitor.isPlaying ? "Playing" : "Paused")
    }
}
```

**Advantages:**
- Type-safe
- Automatic updates
- Compiler-checked

**Disadvantages:**
- Tight coupling
- Hard to test

---

### 2. Notification Center

**Use Case:** Loose coupling between components

```swift
// Sender
NotificationCenter.default.post(
    name: .favoriteSuccess,
    object: nil
)

// Receiver
NotificationCenter.default.addObserver(
    self,
    selector: #selector(handleSuccess),
    name: .favoriteSuccess,
    object: nil
)
```

**Advantages:**
- Decoupled
- Many-to-many
- Easy to extend

**Disadvantages:**
- Not type-safe
- Hard to debug
- Memory leaks if not removed

**Usage in StarTune:**

| Notification | Sender | Receiver | Purpose |
|-------------|--------|----------|---------|
| `.addToFavorites` | MenuBarController | MenuBarView | Trigger Favorite Action |
| `.favoriteSuccess` | MenuBarView | MenuBarController | Show Success Animation |
| `.favoriteError` | MenuBarView | MenuBarController | Show Error Animation |

---

### 3. Dependency Injection

**Use Case:** Testability & Flexibility

```swift
// Protocol
protocol FavoritesServiceProtocol {
    func addToFavorites(song: Song) async throws -> Bool
}

// Implementation
class FavoritesService: FavoritesServiceProtocol { ... }

// Mock (for Testing)
class MockFavoritesService: FavoritesServiceProtocol { ... }

// Injection
struct MenuBarView: View {
    var favoritesService: FavoritesServiceProtocol = FavoritesService()
}
```

**Status in StarTune:** 
- ❌ Not implemented in v1.0
- ✅ Planned for v2.0

---

## Threading Model

### Main Actor Isolation

```swift
@MainActor
class MusicKitManager: ObservableObject {
    @Published var isAuthorized = false
}
```

**Guarantees:**
- All methods run on Main Thread
- Safe @Published updates
- No data races

### Async/Await

```swift
func requestAuthorization() async {
    let status = await MusicAuthorization.request()
    // Automatically on Main Thread (@MainActor)
    self.isAuthorized = (status == .authorized)
}
```

**Benefits:**
- Linear code (no callbacks)
- Automatic thread switching
- Error propagation

### Timer (Background)

```swift
timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
    Task { @MainActor [weak self] in
        await self?.updatePlaybackState()
    }
}
```

**Pattern:**
1. Timer fires (RunLoop Thread)
2. Create Task
3. @MainActor ensures Main Thread
4. Async work can switch threads

---

## State Management

### State Hierarchy

```
App State (Global)
    ├── MusicKitManager
    │   ├── isAuthorized
    │   └── hasSubscription
    │
    ├── PlaybackMonitor
    │   ├── currentSong
    │   ├── isPlaying
    │   └── playbackTime
    │
    └── AppSettings
        ├── launchAtLogin
        └── showNotifications

View State (Local)
    └── MenuBarView
        └── isProcessing (ephemeral)
```

### State Types

| Type | Lifetime | Storage | Example |
|------|----------|---------|---------|
| **Global** | App | @StateObject | MusicKitManager |
| **Shared** | Multi-View | @ObservedObject | PlaybackMonitor |
| **Local** | Single View | @State | isProcessing |
| **Persistent** | Between Sessions | UserDefaults | AppSettings |

### State Ownership

```swift
// Owner (App)
@StateObject private var manager = MusicKitManager()

// Consumer (View)
@ObservedObject var manager: MusicKitManager
```

**Rule:** Only ONE @StateObject per instance!

---

## Dependency Graph

### Component Dependencies

```
StarTuneApp
    ├─> MusicKitManager (owns)
    ├─> PlaybackMonitor (owns)
    │       └─> MusicAppBridge (owns)
    └─> MenuBarController (owns)

MenuBarView
    ├─> MusicKitManager (ref)
    ├─> PlaybackMonitor (ref)
    └─> FavoritesService (owns)
            └─> MusadoraKit (imports)

MenuBarController
    └─> NSStatusItem (owns)
```

### External Dependencies

```
StarTune App
    │
    ├─> SwiftUI (Apple)
    ├─> AppKit (Apple)
    ├─> MusicKit (Apple)
    ├─> Combine (Apple)
    ├─> ScriptingBridge (Apple)
    │
    └─> MusadoraKit (3rd Party - SPM)
            └─> MusicKit (wrapper)
```

### Dependency Injection Points

**Current (Hard-coded):**
```swift
@State private var favoritesService = FavoritesService()
```

**Better (Protocol-based):**
```swift
@State private var favoritesService: FavoritesServiceProtocol = FavoritesService()
```

**Best (Environment Object):**
```swift
.environmentObject(favoritesService)
```

---

## Design Decisions

### 1. Why MVVM?

**Alternatives Considered:**
- MVC (too coupled)
- VIPER (over-engineered for this size)
- Redux/TCA (too complex)

**Chosen:** MVVM
- Natural fit for SwiftUI
- Clear separation of concerns
- Easy to understand

### 2. Why AppleScript Bridge?

**Alternatives:**
- MusicPlayer.shared (MusicKit native)
- MediaPlayer Framework
- Scripting Bridge only

**Chosen:** AppleScript via NSAppleScript
- Most reliable in Menu Bar context
- Works when app is sandboxed
- Direct Music.app access

**Tradeoff:**
- ❌ Polling required (no push notifications)
- ✅ Always accurate
- ✅ No framework bugs

### 3. Why MusadoraKit?

**Alternative:** Raw MusicKit API

**Chosen:** MusadoraKit wrapper
- Simplifies Favorites API
- Better error handling
- Community maintained

**Tradeoff:**
- ❌ External dependency
- ✅ Less boilerplate
- ✅ Active development

### 4. Why Timer Polling?

**Alternative:** Observer-based

**Chosen:** Timer every 2s
- Simple implementation
- Predictable behavior
- Low CPU impact (~1%)

**Future:** Investigate MusicPlayer.queue notifications

### 5. Why NotificationCenter?

**Alternatives:**
- Closures
- Delegates
- Combine Publishers

**Chosen:** NotificationCenter
- Decoupled architecture
- Easy to extend
- Well-known pattern

**Tradeoff:**
- ❌ Not type-safe
- ✅ Very flexible

---

## Performance Considerations

### CPU Usage

| State | CPU % | Notes |
|-------|-------|-------|
| Idle (no music) | <1% | Timer still runs |
| Playing | 1-2% | Timer + AppleScript |
| Catalog Search | 5-8% | Network + Parsing |
| Animation | 2-3% | 60fps rendering |

### Memory Footprint

| Component | Memory | Notes |
|-----------|--------|-------|
| Base App | ~15 MB | SwiftUI + AppKit |
| MusicKit | ~5 MB | Framework overhead |
| Song Cache | ~2 MB per Song | Artwork included |
| **Total** | ~20-25 MB | Very lightweight |

### Network Usage

| Operation | Data | Frequency |
|-----------|------|-----------|
| Authorization | ~10 KB | Once per session |
| Song Search | ~50 KB | Every song change |
| Add Favorite | ~5 KB | On user action |
| **Total** | ~100 KB/hour | Minimal |

### Optimization Techniques

**1. Debouncing**
```swift
// Timer interval 2s (not 0.5s)
timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true)
```

**2. Lazy Loading**
```swift
// Song search only when playing
if isPlaying, let trackName = musicBridge.currentTrackName {
    await findSongInCatalog(trackName: trackName)
}
```

**3. Result Limiting**
```swift
searchRequest.limit = 5  // Not 25
```

**4. Weak References**
```swift
timer = Timer.scheduledTimer(...) { [weak self] in ... }
```

---

## Security Architecture

### Sandboxing

**Enabled Capabilities:**
```
✅ App Sandbox
✅ Network: Outgoing Connections
✅ User Selected Files: Read Only
❌ All other access denied
```

### Entitlements

```xml
<key>com.apple.security.app-sandbox</key>
<true/>

<key>com.apple.security.network.client</key>
<true/>

<key>com.apple.security.files.user-selected.read-only</key>
<true/>
```

### Data Privacy

**Stored Data:**
- ✅ UserDefaults: App Settings (local only)
- ❌ No user credentials stored
- ❌ No music data cached
- ❌ No analytics/tracking

**External Communication:**
- ✅ Apple Music API only (HTTPS)
- ❌ No third-party services
- ❌ No telemetry

### Authorization Flow

```
User → Authorization Dialog → Apple ID
                ↓
        MusicKit Framework
                ↓
        Apple Music API (iCloud)
```

**Token Management:**
- Automatic via MusicKit
- No manual token storage
- Expires after session

---

## Future Architecture Improvements

### 1. Protocol-based Dependencies

**Current:**
```swift
@State private var favoritesService = FavoritesService()
```

**Better:**
```swift
protocol FavoritesServiceProtocol {
    func addToFavorites(song: Song) async throws -> Bool
}

@State private var favoritesService: FavoritesServiceProtocol = FavoritesService()
```

**Benefits:**
- Testability (Mock injection)
- Flexibility (Swap implementations)

### 2. Repository Pattern

**Current:** Services directly call APIs

**Better:**
```
View → UseCase → Repository → API
```

**Example:**
```swift
protocol MusicRepositoryProtocol {
    func addToFavorites(song: Song) async throws
}

class MusicKitRepository: MusicRepositoryProtocol {
    func addToFavorites(song: Song) async throws {
        try await MCatalog.addRating(for: song, rating: .like)
    }
}
```

### 3. Use Cases Layer

**Current:** Views call Services directly

**Better:**
```swift
class AddToFavoritesUseCase {
    private let repository: MusicRepositoryProtocol
    
    func execute(song: Song) async throws {
        // Business logic
        guard song.isPlayable else {
            throw FavoritesError.songNotPlayable
        }
        try await repository.addToFavorites(song: song)
    }
}
```

### 4. Coordinator Pattern

**For navigation in future settings window**

```swift
class AppCoordinator {
    func showSettings() { }
    func showAbout() { }
}
```

### 5. Event Bus

**Replace NotificationCenter**

```swift
class EventBus {
    func publish<T: Event>(_ event: T) { }
    func subscribe<T: Event>(_ handler: @escaping (T) -> Void) { }
}

struct FavoriteAddedEvent: Event {
    let song: Song
}
```

---

## Testing Architecture

### Current State

❌ No tests implemented in v1.0

### Recommended Structure

```
StarTuneTests/
├── Unit/
│   ├── MusicKitManagerTests.swift
│   ├── PlaybackMonitorTests.swift
│   └── FavoritesServiceTests.swift
│
├── Integration/
│   ├── AuthorizationFlowTests.swift
│   └── FavoritesFlowTests.swift
│
└── UI/
    └── MenuBarViewTests.swift
```

### Mock Strategy

```swift
protocol MusicAppBridgeProtocol {
    func updatePlaybackState()
    var isPlaying: Bool { get }
}

class MockMusicAppBridge: MusicAppBridgeProtocol {
    var isPlaying = false
    func updatePlaybackState() {
        // Controllable for tests
    }
}
```

---

## Diagrams Summary

### Component Interaction Matrix

|  | StarTuneApp | MenuBarView | PlaybackMonitor | MusicKitManager | FavoritesService |
|--|------------|-------------|-----------------|-----------------|------------------|
| **StarTuneApp** | - | Creates | Owns | Owns | - |
| **MenuBarView** | - | - | Observes | Observes | Uses |
| **PlaybackMonitor** | - | - | - | - | - |
| **MusicKitManager** | - | - | - | - | - |
| **FavoritesService** | - | Used by | - | - | - |

### Data Flow Summary

```
External World (Music.app, Apple Music API)
    ↓
Business Logic (Managers, Services)
    ↓
@Published Properties
    ↓
SwiftUI Views
    ↓
User Interface
```

---

## Conclusion

StarTune follows a **clean MVVM architecture** with clear layer separation:

1. **Presentation** (SwiftUI/AppKit) - UI only
2. **Business Logic** (Managers) - State & orchestration
3. **Services** (API wrappers) - External communication
4. **Models** (Structs) - Pure data

**Strengths:**
- ✅ Clear separation of concerns
- ✅ Testable (with protocol improvements)
- ✅ Maintainable
- ✅ Scalable

**Areas for Improvement:**
- Protocol-based dependencies
- Unit test coverage
- Repository pattern
- Use case layer

---

**Document Version:** 1.0.0  
**Last Updated:** 2025-10-27  
**Maintainer:** Ben Kohler
