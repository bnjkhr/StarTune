# Changelog

All notable changes to StarTune will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned Features
- Global keyboard shortcut (⌘⇧F)
- macOS Notifications bei Success
- Settings window
- Launch at Login option
- Song history (last 10 favorites)

---

## [1.0.1] - 2025-11-03

### Fixed

#### Critical Bug Fixes
- **FavoritesService Error Handling** - Fixed error handling to properly map MusadoraKitError types instead of collapsing all errors into networkError. Now correctly distinguishes between authorization failures, missing subscriptions, and actual network errors, allowing proper user prompts.

- **Apple Events Authorization** - Added missing NSAppleEventsUsageDescription to Info.plist. Without this, macOS would terminate the app when attempting to send Apple Events to Music.app, breaking all playback detection.

- **Multiple Timer Creation** - Fixed PlaybackMonitor creating multiple concurrent timers on repeated startMonitoring() calls, which caused duplicated AppleScript lookups and catalog searches. Timer creation is now idempotent.

- **Repeated App Setup** - Fixed StarTuneApp calling setupApp() on every menu open, triggering multiple monitoring instances. Added guard to ensure setup runs only once.

- **Boolean Conversion Bug** - Fixed MusicAppBridge incorrectly handling boolean results from System Events check, which caused the app to wipe track info even when Music.app was running. AppleScript now returns explicit "true"/"false" strings.

- **Quit Menu Item** - Fixed "Quit StarTune" menu item not working by properly setting the target property on the NSMenuItem.

#### Documentation Fixes
- **RUNNING.md** - Replaced hardcoded maintainer-specific absolute path with placeholder path (/path/to/StarTune) to prevent "No such file or directory" errors for other developers.

- **RUNNING.md** - Fixed Intel-only release build path to support both architectures. Added command using `$(swift build --show-bin-path)` and documented both Intel and Apple Silicon paths.

- **SETUP.md** - Added NSAppleEventsUsageDescription to Info.plist configuration instructions, which was previously omitted despite being required for Apple Events automation.

### Technical Details

**Error Mapping (FavoritesService.swift:32, 59)**
- Added `mapMusadoraKitError()` function to translate MusadoraKitError cases
- Maps `.notAuthorized` → `FavoritesError.notAuthorized`
- Maps `.noSubscription` → `FavoritesError.noSubscription`
- Maps `.notFound` → `FavoritesError.songNotFound`
- Maps network/URL errors → `FavoritesError.networkError`

**Permission Keys (Info.plist:29)**
- Added NSAppleEventsUsageDescription with explanation about Music.app control
- Prevents process termination on first Apple Events send

**Timer Management (PlaybackMonitor.swift:44)**
- Added guard `timer == nil` before scheduling new timer
- Prevents concurrent timer instances

**Setup Guard (StarTuneApp.swift:15, 31)**
- Added `@State hasSetupApp` flag
- Guards setupApp() call in onAppear

**AppleScript Boolean Fix (MusicAppBridge.swift:40)**
- Changed script to return explicit "true"/"false" strings
- Fixed System Events check from boolean to string comparison

**Menu Item Wiring (MenuBarController.swift:81, 91)**
- Set `.target = self` on About and Quit menu items
- Ensures action methods are properly triggered

### Impact
- **High Priority**: Apple Events authorization fix prevents app crashes
- **High Priority**: Error mapping enables proper user messaging for auth/subscription issues
- **Medium Priority**: Timer fix prevents resource waste and duplicate operations
- **Medium Priority**: Boolean fix restores correct playback detection
- **Low Priority**: Documentation fixes improve developer experience

---

## [1.0.0] - 2025-10-27

### Added - Initial Release

#### Core Features
- **Menu Bar Integration**
  - Star icon in macOS Menu Bar
  - Dynamic color (gold when playing, gray when idle)
  - Click to open popover

- **MusicKit Authorization**
  - One-time authorization flow
  - Apple Music subscription detection
  - Proper error handling for denied access

- **Playback Detection**
  - Live detection of currently playing song
  - AppleScript bridge to Music.app
  - MusicKit Catalog search for song matching
  - 2-second polling interval

- **Favorites Management**
  - One-click add to favorites
  - MusadoraKit integration
  - Success/Error visual feedback
  - Green flash on success, red on error

- **UI/UX**
  - SwiftUI popover interface
  - Song info display (title, artist, album)
  - Playback status indicator (🟢 Playing / ⚪️ Paused)
  - Quit button with keyboard shortcut (⌘Q)

#### Technical Implementation
- MVVM architecture pattern
- Swift Concurrency (async/await)
- Combine framework for reactive updates
- @MainActor isolation for thread safety
- Menu Bar only app (no Dock icon)

#### Dependencies
- MusadoraKit 4.5+ (via Swift Package Manager)
- Native frameworks: SwiftUI, AppKit, MusicKit, ScriptingBridge

#### Documentation
- Comprehensive README with setup guide
- API documentation for all classes
- Architecture documentation
- Setup & deployment guide
- Contributing guidelines

#### Permissions
- NSAppleEventsUsageDescription for Music.app access
- NSAppleMusicUsageDescription for MusicKit
- App Sandbox with network access

#### Build Configuration
- macOS 14.0+ deployment target
- Swift 5.9+
- Developer ID signing support
- Notarization ready

### Implementation Details

**MusicKitManager:**
- Authorization status tracking
- Subscription validation
- Error message generation

**PlaybackMonitor:**
- Timer-based monitoring (2s interval)
- Song catalog search
- State management

**MusicAppBridge:**
- AppleScript execution engine
- Music.app communication
- Robust error handling

**FavoritesService:**
- MusadoraKit wrapper
- Rating API integration
- Network error handling

**MenuBarController:**
- NSStatusItem management
- Click handling (left/right)
- Animation system (success/error)

**MenuBarView:**
- Authorization section
- Now Playing display
- Action buttons
- Processing state

### Known Limitations

#### v1.0 Limitations
- No keyboard shortcuts
- No settings window
- No launch at login
- No song history
- No notification support
- Polling-based detection (no push updates)
- Limited to Apple Music (no Spotify)
- Local files not fully supported

#### Technical Constraints
- Requires active Apple Music subscription
- Requires macOS 14.0+ (Sonoma)
- Music.app must be running for detection
- Network required for favorites sync
- 2-second detection delay

### Bug Fixes
N/A - Initial Release

### Changed
N/A - Initial Release

### Deprecated
N/A - Initial Release

### Removed
N/A - Initial Release

### Security
- App Sandbox enabled
- Hardened Runtime enabled
- No user data collection
- No third-party analytics
- All data stays local (except Apple Music API)

---

## Version History Summary

| Version | Date | Highlights |
|---------|------|------------|
| 1.0.1 | 2025-11-03 | Critical bug fixes - Error handling, Apple Events, timer management |
| 1.0.0 | 2025-10-27 | Initial Release - Core features |

---

## Upgrade Guide

### From Nothing to 1.0.0

First installation - follow [README.md](README.md) setup instructions.

---

## Breaking Changes

### v1.0.0
No breaking changes - initial release.

---

## Migration Guide

### Future Versions

Migration guides will be added here when needed.

---

## Development Notes

### Build Info

**Version 1.0.0:**
- Build Number: 1
- Git Commit: [hash]
- Swift Version: 5.9
- Xcode Version: 15.0+
- MusadoraKit: 4.5+

### Testing Coverage

**v1.0.0:**
- Unit Tests: 0% (planned for v1.1)
- Integration Tests: Manual only
- UI Tests: Manual only

---

## Contributor Recognition

### v1.0.0
- **Ben Kohler** - Initial implementation & documentation

---

## Links

- **Repository:** https://github.com/yourusername/startune
- **Issues:** https://github.com/yourusername/startune/issues
- **Releases:** https://github.com/yourusername/startune/releases
- **Documentation:** [docs/](docs/)

---

## Changelog Maintenance

**Update Frequency:** Every release  
**Format:** Keep a Changelog format  
**Versioning:** Semantic Versioning  
**Review:** Before each release

---

**Last Updated:** 2025-11-03
**Maintained by:** Ben Kohler
