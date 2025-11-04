# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

StarTune is a native macOS Menu Bar app that allows users to favorite currently playing Apple Music songs with one click. Built with SwiftUI, AppKit, and MusicKit, it runs discretely in the menu bar with a dynamic star icon that changes based on playback status.

**Tech Stack:** Swift 5.9+, SwiftUI, AppKit, MusicKit, Combine, AppleScript Bridge
**Platform:** macOS 14.0+ (Sonoma)
**Dependencies:** MusadoraKit 4.5+ (via Swift Package Manager)

## Development Commands

### Build and Run
```bash
# Open project
cd StarTune-Xcode/StarTune
open StarTune.xcodeproj

# Build from command line
xcodebuild -project StarTune.xcodeproj -scheme StarTune -configuration Debug build

# Build release
xcodebuild -project StarTune.xcodeproj -scheme StarTune -configuration Release build
```

### Package Management
```bash
# Reset package caches (if MusadoraKit issues)
# File → Packages → Reset Package Caches in Xcode

# Update dependencies
# File → Packages → Update to Latest Package Versions
```

### Testing and Validation
```bash
# Run app from build output
open ~/Library/Developer/Xcode/DerivedData/StarTune-*/Build/Products/Debug/StarTune.app

# Check code signing
security find-identity -v -p codesigning

# Validate notarization (for distribution builds)
xcrun stapler validate StarTune.app
```

### Distribution
```bash
# Archive for distribution
# Product → Archive in Xcode

# Create DMG
hdiutil create -volname "StarTune" -srcfolder StarTune.app -ov -format UDZO StarTune.dmg

# Notarize (manual method)
xcrun notarytool submit StarTune.zip \
  --apple-id "your-email@example.com" \
  --team-id "YOUR_TEAM_ID" \
  --password "@keychain:AC_PASSWORD"
```

## Architecture Overview

### MVVM Pattern with Layer Separation

**Entry Point:** `StarTuneApp.swift`
- Creates and owns all manager instances (`@StateObject`)
- Configures `MenuBarExtra` with dynamic icon
- Handles app lifecycle

**Presentation Layer:**
- `MenuBar/MenuBarController.swift` - NSStatusItem management, click handling, animations
- `MenuBar/MenuBarView.swift` - SwiftUI popover content

**Business Logic Layer:**
- `MusicKit/MusicKitManager.swift` - Authorization and subscription management
- `MusicKit/PlaybackMonitor.swift` - Song detection and state tracking (timer-based, 2s polling)
- `MusicKit/MusicAppBridge.swift` - AppleScript bridge to Music.app for playback state
- `MusicKit/FavoritesService.swift` - Favorites API wrapper using MusadoraKit

**Data Layer:**
- `Models/PlaybackState.swift` - Playback state snapshot
- `Models/AppSettings.swift` - User preferences (UserDefaults backed)

### Key Design Decisions

1. **AppleScript Bridge for Playback Detection**: Uses `NSAppleScript` to communicate with Music.app instead of `MusicPlayer.shared` because the latter is unreliable in menu bar apps. Polls every 2 seconds.

2. **MusadoraKit Wrapper**: Simplifies MusicKit's complex Favorites API. External dependency but actively maintained and reduces boilerplate.

3. **Timer-based Polling**: Simple and predictable. 2-second interval balances responsiveness with CPU usage (~1-2%).

4. **NotificationCenter for Component Communication**: Decouples MenuBarController from MenuBarView for success/error animations (`.favoriteSuccess`, `.favoriteError`).

5. **@MainActor Isolation**: All ObservableObject managers are @MainActor to ensure thread-safe @Published updates.

### Data Flow Pattern

```
Music.app → AppleScript → MusicAppBridge → PlaybackMonitor
                                                    ↓
                                            MusicKit Search
                                                    ↓
                                          @Published Properties
                                                    ↓
                                              MenuBarView (auto-updates)
```

### State Management

- **App State**: Owned by `StarTuneApp` as `@StateObject` (MusicKitManager, PlaybackMonitor)
- **Shared State**: Passed to views as `@ObservedObject`
- **Local State**: View-specific ephemeral state using `@State` (e.g., `isProcessing`)
- **Persistent State**: `AppSettings` backed by UserDefaults

## Important Development Notes

### Required Permissions & Configuration

**Info.plist Keys:**
- `LSUIElement = true` - Menu Bar only app, no Dock icon
- `NSAppleEventsUsageDescription` - Required for AppleScript bridge to Music.app
- `NSAppleMusicUsageDescription` - Required for MusicKit access

**Apple Developer Portal:**
- Bundle ID must have MusicKit capability enabled
- "Automatic Token Generation" must be enabled for MusicKit (no manual JWT needed)
- App ID in portal must EXACTLY match Xcode Bundle ID (case-sensitive)

**Xcode Capabilities:**
- App Sandbox: ✓ (with Outgoing Network Connections)
- Hardened Runtime: ✓
- MusicKit is NOT a capability in Xcode, only configured in Developer Portal

### Common Development Patterns

**Async/Await Throughout:**
```swift
// All async operations use async/await, not completion handlers
func requestAuthorization() async {
    let status = await MusicAuthorization.request()
    self.isAuthorized = (status == .authorized)
}
```

**Memory Management:**
```swift
// Always use [weak self] in closures and timers
timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
    Task { @MainActor [weak self] in
        await self?.updatePlaybackState()
    }
}
```

**Section Markers:**
```swift
// Use MARK: for organization
// MARK: - Section Title (with separator line)
// MARK: Subsection (without separator)
```

### Testing Requirements

**Manual Test Checklist:**
- Authorization flow (first time, denial, revocation)
- Playback detection (start, pause, stop, app quit)
- Favorites action (success, network error, no subscription)
- UI feedback (animations, icon color changes)
- Edge cases (Music.app not running, local files, podcasts)

**Important Console Logs:**
```
🎵 Starting playback monitoring...
✅ Found song: [Title] by [Artist]
✅ Successfully added '[Title]' to favorites
⚠️ No song found for: Unknown Track
❌ Error adding to favorites: [Error]
```

### Common Issues & Solutions

**"No such module 'MusadoraKit'"**
- File → Packages → Reset Package Caches
- Rebuild

**"Music User Token could not be obtained"**
- Verify MusicKit capability in Developer Portal
- Ensure Bundle ID matches exactly
- Check App ID has MusicKit enabled

**Icon not appearing in Menu Bar**
- StatusItem must be strong reference (not weak)
- Use `@StateObject` for MenuBarController, not `@State`

**Song detection not working**
- Check MusicKit authorization status
- Verify `NSAppleEventsUsageDescription` in Info.plist
- Grant automation permission in System Settings → Privacy → Automation

## Code Style Guidelines

**Follow Swift API Design Guidelines:**
- Classes/Structs: PascalCase
- Variables/Functions: camelCase
- 4 spaces indentation (no tabs)
- 120 character line limit

**Commit Message Format (Conventional Commits):**
```
feat: add keyboard shortcut support
fix: handle authorization denial correctly
docs: update setup guide
refactor: simplify favorites service
chore: update dependencies
```

**Documentation:**
- Document all public APIs with doc comments
- Use `///` for documentation, `//` for inline comments
- Complex logic requires inline explanation

## Project Structure Reference

```
StarTune/
├── StarTuneApp.swift              # App entry point & lifecycle
├── Info.plist                     # LSUIElement: true, permissions
├── MenuBar/
│   ├── MenuBarController.swift    # NSStatusItem, animations, click handling
│   └── MenuBarView.swift          # SwiftUI popover content
├── MusicKit/
│   ├── MusicKitManager.swift      # Authorization & subscription
│   ├── PlaybackMonitor.swift     # Song detection (timer + AppleScript)
│   ├── FavoritesService.swift    # MusadoraKit wrapper
│   └── MusicAppBridge.swift      # AppleScript → Music.app bridge
├── Models/
│   ├── PlaybackState.swift       # Immutable playback state
│   └── AppSettings.swift         # UserDefaults-backed settings
└── Assets.xcassets/              # App icon & resources
```

## Performance Characteristics

- **Memory:** ~20-25 MB (idle to active)
- **CPU:** <1% idle, 1-2% monitoring, 5-8% during catalog search
- **Network:** ~100 KB/hour typical usage
- **Timer Interval:** 2 seconds (balance of responsiveness vs. performance)

## Future Development Considerations

**Planned Enhancements:**
- Global keyboard shortcut (⌘⇧F)
- Settings window (Launch at Login, etc.)
- macOS notifications for success
- Protocol-based dependency injection for testability
- Unit test coverage

**Testing Strategy (Not Yet Implemented):**
- Protocol abstractions for mockability (e.g., `MusicAppBridgeProtocol`)
- Repository pattern for data layer separation
- Coordinator pattern for future navigation needs

## Related Documentation

- `README.md` - Comprehensive project overview, features, user flows
- `docs/ARCHITECTURE.md` - Detailed technical architecture, design decisions
- `docs/API_DOCUMENTATION.md` - Complete API reference for all components
- `docs/SETUP_GUIDE.md` - Step-by-step setup, testing, and deployment
- `CONTRIBUTING.md` - Contribution guidelines, coding standards
- `PROJECT_INDEX.md` - File structure and quick reference
- `CHANGELOG.md` - Version history

## External Resources

- [MusicKit Documentation](https://developer.apple.com/documentation/musickit)
- [MusadoraKit GitHub](https://github.com/rryam/MusadoraKit)
- [MenuBarExtra SwiftUI](https://developer.apple.com/documentation/swiftui/menubarextra)
- [Swift.org API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
