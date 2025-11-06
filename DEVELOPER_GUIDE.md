# StarTune Developer Guide

Quick reference for developers working with StarTune's event-driven architecture.

---

## 📁 Project Structure

```
StarTune-Xcode/
├── Sources/StarTune/
│   ├── MusicKit/
│   │   ├── MusicObserver.swift          ← Listens to Music.app notifications
│   │   ├── PlaybackMonitor.swift        ← Reactive state manager + MusicKit
│   │   ├── MusicAppStatus.swift         ← Tracks Music.app lifecycle
│   │   ├── MusicKitManager.swift        ← Authorization & subscription
│   │   └── FavoritesService.swift       ← Favorites management
│   ├── Models/
│   │   ├── AppSettings.swift
│   │   └── PlaybackState.swift
│   └── MenuBar/
│       ├── MenuBarController.swift
│       └── MenuBarView.swift
├── StarTune/StarTune/
│   └── StarTuneApp.swift                ← App entry point + lifecycle
└── ARCHITECTURE.md                      ← Detailed architecture docs
```

---

## 🔑 Key Classes

### MusicObserver

**Purpose**: Low-level Music.app notification observer

```swift
@MainActor
class MusicObserver: ObservableObject {
    @Published var currentTrack: TrackInfo?
    @Published var isPlaying: Bool
    @Published var playbackTime: TimeInterval
}
```

**When to use:**
- Need raw track info from Music.app
- Building custom playback UI
- Don't need MusicKit Song objects

**When NOT to use:**
- Need full Song metadata (use PlaybackMonitor)
- Building high-level features (use PlaybackMonitor)

---

### PlaybackMonitor

**Purpose**: High-level playback manager with MusicKit integration

```swift
@MainActor
class PlaybackMonitor: ObservableObject {
    @Published var currentSong: Song?        // MusicKit Song
    @Published var isPlaying: Bool
    @Published var playbackTime: TimeInterval

    func startMonitoring() async
    func stopMonitoring()
}
```

**When to use:**
- Building UI features
- Need MusicKit Song objects
- Want debounced updates

**Data flow:**
```
MusicObserver → Combine pipeline → MusicKit search → currentSong
```

---

### MusicAppStatus

**Purpose**: Track Music.app running state

```swift
@MainActor
class MusicAppStatus: ObservableObject {
    @Published var isRunning: Bool
    @Published var isFrontmost: Bool

    func activateMusicApp()
}
```

**Usage example:**

```swift
@StateObject private var musicAppStatus = MusicAppStatus()

var body: some View {
    if !musicAppStatus.isRunning {
        Text("Music.app not running")
        Button("Launch Music") {
            musicAppStatus.activateMusicApp()
        }
    }
}
```

---

## 🎯 Common Tasks

### Task 1: Add New Observable Property

**Example: Track Artwork**

```swift
// 1. Add property to MusicObserver
class MusicObserver: ObservableObject {
    @Published var artwork: NSImage?

    private func handlePlayerInfoNotification(_ notification: Notification) {
        // Parse artwork from notification if available
        if let artworkData = userInfo["Artwork Data"] as? Data {
            artwork = NSImage(data: artworkData)
        }
    }
}

// 2. Bind in PlaybackMonitor (if needed)
class PlaybackMonitor: ObservableObject {
    @Published var currentArtwork: NSImage?

    init() {
        musicObserver.$artwork
            .assign(to: &$currentArtwork)
    }
}

// 3. Use in UI
struct MenuBarView: View {
    @ObservedObject var playbackMonitor: PlaybackMonitor

    var body: some View {
        if let artwork = playbackMonitor.currentArtwork {
            Image(nsImage: artwork)
                .resizable()
                .frame(width: 60, height: 60)
        }
    }
}
```

---

### Task 2: Add Custom Debouncing

**Example: Slow Down Updates**

```swift
class PlaybackMonitor {
    private func setupReactiveBindings() {
        // Change debounce duration
        musicObserver.$currentTrack
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)  // 1s instead of 300ms
            .sink { ... }
    }
}
```

**When to increase debounce:**
- Reducing API calls
- Slow network connection
- User feedback says updates too frequent

**When to decrease debounce:**
- Updates feel sluggish
- Need more responsive UI

---

### Task 3: Add Analytics Tracking

**Example: Log Track Changes**

```swift
class PlaybackAnalytics {
    static let shared = PlaybackAnalytics()
    private var trackChangeCount = 0

    func logTrackChange(_ song: Song) {
        trackChangeCount += 1
        print("📊 Total tracks played: \(trackChangeCount)")

        // Send to analytics service
        // AnalyticsService.track("track_changed", properties: [...])
    }
}

// In PlaybackMonitor
private func searchMusicKitCatalog(for trackInfo: MusicObserver.TrackInfo) async {
    // ... existing code ...

    if let song = /* found song */ {
        currentSong = song
        PlaybackAnalytics.shared.logTrackChange(song)
    }
}
```

---

### Task 4: Add Notification Banner

**Example: Show macOS Notification**

```swift
import UserNotifications

class NotificationManager {
    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try? await center.requestAuthorization(options: [.alert, .sound])
        return granted ?? false
    }

    static func showNowPlaying(_ song: Song) {
        let content = UNMutableNotificationContent()
        content.title = "Now Playing"
        content.body = "\(song.title) - \(song.artistName)"
        content.sound = nil

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}

// In AppDelegate
func applicationDidFinishLaunching(_ notification: Notification) {
    Task {
        await NotificationManager.requestAuthorization()
    }
}

// In PlaybackMonitor
private func searchMusicKitCatalog(...) async {
    if let song = /* found */ {
        currentSong = song
        NotificationManager.showNowPlaying(song)
    }
}
```

---

### Task 5: Add Keyboard Shortcut

**Example: Global Hotkey for Play/Pause**

```swift
import Carbon

class HotkeyManager {
    static let shared = HotkeyManager()

    func registerPlayPauseHotkey() {
        // Register Cmd+Shift+P
        let hotkey = EventHotKeyID(signature: OSType(0), id: 1)

        // Note: Requires Carbon framework and private APIs
        // Full implementation beyond scope - see Carbon Event Manager docs
    }
}
```

---

## 🧪 Testing Patterns

### Unit Test: MusicObserver

```swift
@MainActor
class MusicObserverTests: XCTestCase {
    func testPlaybackNotification() async throws {
        let observer = MusicObserver()

        let userInfo: [String: Any] = [
            "Player State": "Playing",
            "Name": "Test Song",
            "Artist": "Test Artist"
        ]

        DistributedNotificationCenter.default().post(
            name: NSNotification.Name("com.apple.Music.playerInfo"),
            object: nil,
            userInfo: userInfo
        )

        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(observer.isPlaying)
        XCTAssertEqual(observer.currentTrack?.name, "Test Song")
    }
}
```

### Integration Test: Full Flow

```swift
@MainActor
class PlaybackIntegrationTests: XCTestCase {
    func testFullPlaybackFlow() async throws {
        let monitor = PlaybackMonitor()
        await monitor.startMonitoring()

        // Simulate notification
        // ... post notification ...

        try await Task.sleep(nanoseconds: 500_000_000)

        XCTAssertNotNil(monitor.currentSong)
        XCTAssertTrue(monitor.isPlaying)

        monitor.stopMonitoring()
    }
}
```

---

## 🐛 Debugging

### Enable Verbose Logging

```swift
// In MusicObserver
private func handlePlayerInfoNotification(_ notification: Notification) {
    print("🔍 Notification received:")
    print("  User Info: \(notification.userInfo ?? [:])")

    // ... existing code ...
}
```

### Monitor Combine Pipeline

```swift
// In PlaybackMonitor
musicObserver.$currentTrack
    .handleEvents(
        receiveOutput: { track in
            print("🔍 Received track: \(track?.displayString ?? "nil")")
        },
        receiveCompletion: { completion in
            print("🔍 Pipeline completed: \(completion)")
        },
        receiveCancel: {
            print("🔍 Pipeline cancelled")
        }
    )
    .sink { ... }
```

### Check Cancellables

```swift
class PlaybackMonitor {
    deinit {
        print("🧹 PlaybackMonitor deallocating")
        print("🧹 Active subscriptions: \(cancellables.count)")
    }
}
```

---

## ⚡ Performance Tips

### 1. Reduce MusicKit API Calls

```swift
// Increase debounce
.debounce(for: .seconds(1), ...)  // Instead of 300ms

// Add more aggressive duplicate filtering
.removeDuplicates()
```

### 2. Batch State Updates

```swift
// Instead of multiple @Published updates
@Published var state: PlaybackState  // Single struct

struct PlaybackState {
    var isPlaying: Bool
    var currentSong: Song?
    var playbackTime: TimeInterval
}
```

### 3. Lazy Loading

```swift
// Don't search MusicKit immediately
private let searchSubject = PassthroughSubject<TrackInfo, Never>()

init() {
    searchSubject
        .debounce(for: .seconds(1), ...)
        .sink { ... }
}
```

---

## 🔐 Memory Safety Checklist

When adding new features:

- [ ] Use `[weak self]` in all closures
- [ ] Store Combine subscriptions in `cancellables`
- [ ] Add cleanup in `deinit`
- [ ] Test with Instruments Leaks template
- [ ] Verify no retain cycles

Example:

```swift
class NewFeature {
    private var cancellables = Set<AnyCancellable>()

    init() {
        NotificationCenter.default.publisher(...)
            .sink { [weak self] notification in
                self?.handle(notification)
            }
            .store(in: &cancellables)  // ← Important!
    }

    deinit {
        print("🧹 NewFeature deallocated")
    }
}
```

---

## 📚 Additional Resources

- **Full Architecture**: See [ARCHITECTURE.md](./ARCHITECTURE.md)
- **Migration Guide**: See [EVENT_DRIVEN_MIGRATION.md](./EVENT_DRIVEN_MIGRATION.md)
- **Apple Docs**: [Combine Framework](https://developer.apple.com/documentation/combine)
- **Music.app API**: [iTunes/Music Notification Keys](https://github.com/joshklein/itunes-mac-api)

---

## 🆘 Getting Help

### Common Issues

1. **No updates** → Check Console.app for notifications
2. **High CPU** → Verify timer code removed
3. **Memory leak** → Run Instruments Leaks template
4. **Slow updates** → Check network and debounce settings

### Debug Commands

```bash
# Check if Music.app is sending notifications
log stream --predicate 'eventMessage contains "com.apple.Music"'

# Monitor CPU wake-ups
sudo opensnoop -n StarTune

# Check memory usage
leaks StarTune

# Profile performance
instruments -t "Time Profiler" StarTune.app
```

---

## ✅ Quick Checklist for New Features

Before merging new code:

- [ ] Uses event-driven patterns (no polling)
- [ ] Proper memory management (`[weak self]`, cancellables)
- [ ] Added tests
- [ ] No blocking on main thread
- [ ] Handles errors gracefully
- [ ] Logged important events
- [ ] Updated documentation
- [ ] Tested with Instruments

---

**Last Updated**: 2025-11-06
**For Questions**: See ARCHITECTURE.md or check inline code comments
