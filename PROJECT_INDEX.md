# StarTune Project Index

Schnellübersicht aller Dateien und deren Zweck im StarTune Projekt.

---

## 📁 Project Structure

```
StarTune-Xcode/
├── StarTune/
│   ├── StarTune.xcodeproj/          # Xcode Project File
│   │   └── project.pbxproj          # Project Configuration
│   │
│   └── StarTune/                    # Source Code
│       ├── StarTuneApp.swift        # App Entry Point
│       ├── Info.plist               # App Configuration
│       │
│       ├── MenuBar/                 # Menu Bar Layer
│       │   ├── MenuBarController.swift
│       │   └── MenuBarView.swift
│       │
│       ├── MusicKit/                # Music Integration
│       │   ├── MusicKitManager.swift
│       │   ├── PlaybackMonitor.swift
│       │   ├── FavoritesService.swift
│       │   └── MusicAppBridge.swift
│       │
│       ├── Models/                  # Data Models
│       │   ├── PlaybackState.swift
│       │   └── AppSettings.swift
│       │
│       └── Assets.xcassets/         # App Resources
│           └── AppIcon.appiconset/
│
├── docs/                            # Documentation
│   ├── README.md                    # Documentation Index
│   ├── API_DOCUMENTATION.md         # API Reference
│   ├── ARCHITECTURE.md              # Technical Design
│   └── SETUP_GUIDE.md               # Setup & Deployment
│
├── README.md                        # Project Overview
├── CHANGELOG.md                     # Version History
├── CONTRIBUTING.md                  # Contribution Guide
└── PROJECT_INDEX.md                 # This file
```

---

## 📄 File Reference

### Root Level Files

| File | Purpose | Audience |
|------|---------|----------|
| `README.md` | Project overview, features, quick start | Everyone |
| `CHANGELOG.md` | Version history & release notes | Everyone |
| `CONTRIBUTING.md` | How to contribute code | Contributors |
| `PROJECT_INDEX.md` | File structure overview | Developers |

---

### Source Code Files

#### Core App

**StarTuneApp.swift** (58 lines)
- App entry point (`@main`)
- MenuBarExtra configuration
- Manager initialization
- App lifecycle handling

**Info.plist** (24 lines)
- Bundle configuration
- LSUIElement = true (Menu Bar only)
- Permission descriptions
- Version info

---

#### MenuBar/ (Menu Bar Integration)

**MenuBarController.swift** (159 lines)
```
├── NSStatusItem management
├── Click handling (left/right)
├── Icon updates & animations
├── Context menu
└── Notification observers
```

**Key Methods:**
- `setupMenuBar()` - Creates status item
- `menuBarButtonClicked(_:)` - Handles clicks
- `updateIcon(isPlaying:)` - Updates icon color
- `showSuccessAnimation()` - Green flash
- `showErrorAnimation()` - Red flash

**MenuBarView.swift** (117 lines)
```
├── SwiftUI popover content
├── Authorization section
├── Now Playing display
├── Add to Favorites button
└── Quit button
```

**Sections:**
- `authorizationSection` - Authorization UI
- `currentlyPlayingSection` - Song info
- `actionsSection` - Favorite button

---

#### MusicKit/ (Music Integration)

**MusicKitManager.swift** (65 lines)
```
├── MusicKit authorization
├── Subscription status
└── Availability checks
```

**Properties:**
- `isAuthorized: Bool` - Auth status
- `authorizationStatus: MusicAuthorization.Status`
- `hasAppleMusicSubscription: Bool`

**Methods:**
- `requestAuthorization()` - Asks for permission
- `checkSubscriptionStatus()` - Validates subscription

**PlaybackMonitor.swift** (94 lines)
```
├── Playback state monitoring
├── Song detection
├── MusicKit catalog search
└── Timer-based polling
```

**Properties:**
- `currentSong: Song?` - Current track
- `isPlaying: Bool` - Playback status
- `playbackTime: TimeInterval` - Position

**Methods:**
- `startMonitoring()` - Starts timer
- `stopMonitoring()` - Stops timer
- `updatePlaybackState()` - Updates state
- `findSongInCatalog(...)` - Searches song

**FavoritesService.swift** (67 lines)
```
├── Favorites management
├── MusadoraKit integration
└── Error handling
```

**Methods:**
- `addToFavorites(song:)` - Adds to favorites
- `removeFromFavorites(song:)` - Removes
- `isFavorited(song:)` - Checks status
- `getFavorites()` - Gets all (future)

**MusicAppBridge.swift** (128 lines)
```
├── AppleScript bridge
├── Music.app communication
├── Playback state reading
└── Error handling
```

**Properties:**
- `currentTrackName: String?`
- `currentArtist: String?`
- `isPlaying: Bool`

**Methods:**
- `updatePlaybackState()` - Gets state via AppleScript
- `getCurrentTrackID()` - Gets persistent ID
- `runAppleScript(_:)` - Executes script

---

#### Models/ (Data Layer)

**PlaybackState.swift** (24 lines)
```swift
struct PlaybackState {
    let isPlaying: Bool
    let currentSong: Song?
    let playbackTime: TimeInterval
    let duration: TimeInterval?
}
```

**Computed Properties:**
- `progress: Double` - Playback progress (0-1)
- `hasActiveSong: Bool` - Song exists

**AppSettings.swift** (42 lines)
```swift
class AppSettings: ObservableObject {
    @Published var launchAtLogin: Bool
    @Published var showNotifications: Bool
    @Published var keyboardShortcutEnabled: Bool
}
```

**Storage:** UserDefaults

---

### Documentation Files

#### docs/

**README.md** (~500 lines)
- Documentation overview
- Quick links by role
- Search by keyword
- Document statistics

**API_DOCUMENTATION.md** (~1200 lines)
```
├── StarTuneApp reference
├── MusicKit Layer
│   ├── MusicKitManager
│   ├── PlaybackMonitor
│   ├── MusicAppBridge
│   └── FavoritesService
├── UI Layer
│   ├── MenuBarController
│   └── MenuBarView
├── Models
├── Notification System
└── Error Handling
```

**ARCHITECTURE.md** (~1100 lines)
```
├── Architecture overview
├── MVVM pattern
├── Layer architecture
├── Component diagrams
├── Data flow
├── Communication patterns
├── Threading model
├── State management
├── Design decisions
└── Performance considerations
```

**SETUP_GUIDE.md** (~1000 lines)
```
├── Development setup
├── Apple Developer Portal config
├── Xcode configuration
├── Local testing
├── Build for distribution
├── App Store submission
├── Direct distribution
└── Troubleshooting
```

---

## 📊 Code Statistics

### Lines of Code

| Category | Files | Lines | Percentage |
|----------|-------|-------|------------|
| **Source Code** | 9 | ~754 | 100% |
| MenuBar Layer | 2 | ~276 | 37% |
| MusicKit Layer | 4 | ~354 | 47% |
| Models | 2 | ~66 | 9% |
| App Entry | 1 | ~58 | 8% |

### Documentation

| Document | Lines | Words |
|----------|-------|-------|
| README.md | ~450 | ~3500 |
| API_DOCUMENTATION.md | ~1200 | ~6000 |
| ARCHITECTURE.md | ~1100 | ~5500 |
| SETUP_GUIDE.md | ~1000 | ~4500 |
| CONTRIBUTING.md | ~500 | ~2500 |
| **Total** | **~4250** | **~22000** |

---

## 🔍 Quick Find

### Need to find...

**Authorization code?**
- `MusicKit/MusicKitManager.swift`
- Method: `requestAuthorization()`

**Playback detection?**
- `MusicKit/PlaybackMonitor.swift`
- Method: `updatePlaybackState()`

**AppleScript bridge?**
- `MusicKit/MusicAppBridge.swift`
- Method: `runAppleScript(_:)`

**Favorites implementation?**
- `MusicKit/FavoritesService.swift`
- Method: `addToFavorites(song:)`

**Menu Bar icon?**
- `MenuBar/MenuBarController.swift`
- Method: `setupMenuBar()`

**UI Layout?**
- `MenuBar/MenuBarView.swift`
- Property: `body`

**App entry point?**
- `StarTuneApp.swift`
- Struct: `StarTuneApp`

**State models?**
- `Models/PlaybackState.swift`
- `Models/AppSettings.swift`

---

## 🎯 File Purpose Summary

### By Layer

**Presentation Layer:**
- `StarTuneApp.swift` - App lifecycle
- `MenuBarController.swift` - NSStatusItem wrapper
- `MenuBarView.swift` - SwiftUI content

**Business Logic Layer:**
- `MusicKitManager.swift` - Authorization
- `PlaybackMonitor.swift` - Detection
- `MusicAppBridge.swift` - Music.app bridge
- `FavoritesService.swift` - API wrapper

**Data Layer:**
- `PlaybackState.swift` - State model
- `AppSettings.swift` - Preferences

**Configuration:**
- `Info.plist` - App config
- `project.pbxproj` - Xcode config

**Documentation:**
- All files in `docs/`
- Root-level `.md` files

---

## 📦 Dependencies

### Swift Package Manager

**MusadoraKit** (External)
- URL: https://github.com/rryam/MusadoraKit
- Version: 4.5+ (main branch)
- Used by: `FavoritesService.swift`

### Native Frameworks

| Framework | Used By | Purpose |
|-----------|---------|---------|
| SwiftUI | MenuBarView | UI rendering |
| AppKit | MenuBarController | NSStatusItem |
| MusicKit | MusicKitManager, PlaybackMonitor | Music API |
| Combine | All ObservableObjects | Reactive updates |
| ScriptingBridge | MusicAppBridge | AppleScript |
| Foundation | All files | Base functionality |

---

## 🔧 Configuration Files

### Xcode Project

**StarTune.xcodeproj/project.pbxproj**
- Build settings
- Signing configuration
- Target settings
- Dependencies

**Key Settings:**
- Deployment Target: macOS 14.0
- Swift Version: 5.0
- Bundle ID: com.benkohler.StarTune
- Team: 5N2YD2P2G5

### Info.plist

**Important Keys:**
```xml
LSUIElement = true               (Menu Bar only)
NSAppleEventsUsageDescription    (AppleScript permission)
NSAppleMusicUsageDescription     (MusicKit permission)
```

---

## 🗂️ Asset Catalog

**Assets.xcassets/**
- AppIcon.appiconset/ (App icons)
- AccentColor.colorset/ (Accent color)

**Icon Sizes:**
- 16x16, 32x32, 64x64, 128x128, 256x256, 512x512, 1024x1024

---

## 📝 File Modification Guide

### When to edit which file?

**Add new feature:**
1. Create use case in `MusicKit/` or `Models/`
2. Update `MenuBarView.swift` for UI
3. Update `README.md` with feature description
4. Update `CHANGELOG.md`

**Fix bug:**
1. Identify file from error log
2. Fix in appropriate layer
3. Add test (future)
4. Update `CHANGELOG.md`

**Change UI:**
1. Edit `MenuBarView.swift` (SwiftUI)
2. Or `MenuBarController.swift` (AppKit)
3. Test on macOS 14.0+

**Update docs:**
1. Edit appropriate `.md` file
2. Update `docs/README.md` if needed
3. Check all internal links

**Add dependency:**
1. File → Add Package Dependencies
2. Update `README.md` dependencies section
3. Update this file

---

## 🚀 Common Tasks

### Add new MusicKit feature

1. Create method in `MusicKitManager.swift`
2. Expose via `@Published` property
3. Consume in `MenuBarView.swift`
4. Document in `API_DOCUMENTATION.md`

### Add new UI section

1. Add computed property in `MenuBarView.swift`
2. Add to `body` VStack
3. Handle actions
4. Test UI updates

### Add new setting

1. Add property to `AppSettings.swift`
2. Add UserDefaults key
3. Create UI in Settings (future)
4. Document in README

---

## 📖 Documentation Cross-Reference

| Code File | Documented In |
|-----------|---------------|
| `StarTuneApp.swift` | API_DOCUMENTATION.md |
| `MusicKitManager.swift` | API_DOCUMENTATION.md, ARCHITECTURE.md |
| `PlaybackMonitor.swift` | API_DOCUMENTATION.md, ARCHITECTURE.md |
| `FavoritesService.swift` | API_DOCUMENTATION.md |
| `MenuBarController.swift` | API_DOCUMENTATION.md |
| `MenuBarView.swift` | API_DOCUMENTATION.md |
| `MusicAppBridge.swift` | API_DOCUMENTATION.md, ARCHITECTURE.md |

---

## 🔄 File Update Frequency

| File Type | Update Frequency |
|-----------|------------------|
| Source Code | With every feature/bugfix |
| README.md | Every release |
| CHANGELOG.md | Every release |
| API_DOCUMENTATION.md | When API changes |
| ARCHITECTURE.md | When design changes |
| SETUP_GUIDE.md | When setup changes |

---

**Last Updated:** 2025-10-27  
**Version:** 1.0.0  
**Maintained by:** Ben Kohler
