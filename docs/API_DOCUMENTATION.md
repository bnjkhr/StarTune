# StarTune API Documentation

Vollständige API-Referenz für alle Klassen und Komponenten der StarTune App.

---

## Table of Contents

1. [App Entry Point](#startuneapp)
2. [MusicKit Layer](#musickit-layer)
   - [MusicKitManager](#musickitmanager)
   - [PlaybackMonitor](#playbackmonitor)
   - [MusicAppBridge](#musicappbridge)
   - [FavoritesService](#favoritesservice)
3. [UI Layer](#ui-layer)
   - [MenuBarController](#menubarcontroller)
   - [MenuBarView](#menubarview)
4. [Models](#models)
   - [PlaybackState](#playbackstate)
   - [AppSettings](#appsettings)
5. [Notifications](#notification-system)
6. [Error Handling](#error-handling)

---

## StarTuneApp

### Overview
Main entry point der Applikation. Verwaltet den App Lifecycle und initialisiert alle Manager.

### Declaration
```swift
@main
struct StarTuneApp: App
```

### Properties

| Name | Type | Description |
|------|------|-------------|
| `musicKitManager` | `@StateObject MusicKitManager` | Manager für MusicKit Authorization |
| `playbackMonitor` | `@StateObject PlaybackMonitor` | Überwacht Playback Status |

### Body
```swift
var body: some Scene {
    MenuBarExtra { ... } label: { ... }
}
```

**MenuBarExtra Label:**
- Icon: `star.fill` SF Symbol
- Farbe: `.yellow` wenn `isPlaying`, sonst `.gray`
- Style: `.window` (Popover-Style)

### Methods

#### `setupApp()`
```swift
private func setupApp() async
```

**Beschreibung:** Initialisiert die App beim ersten Start.

**Flow:**
1. Ruft `musicKitManager.requestAuthorization()` auf
2. Startet `playbackMonitor` wenn autorisiert
3. Wird in `onAppear` des MenuBarExtra aufgerufen

**Fehlerbehandlung:** Keine expliziten throws - Fehler werden von Managern geloggt

---

## MusicKit Layer

## MusicKitManager

### Overview
Verwaltet MusicKit Authorization und Apple Music Subscription Status.

### Declaration
```swift
@MainActor
class MusicKitManager: ObservableObject
```

### Properties

| Name | Type | Access | Description |
|------|------|--------|-------------|
| `isAuthorized` | `@Published Bool` | Public | `true` wenn User MusicKit authorisiert hat |
| `authorizationStatus` | `@Published MusicAuthorization.Status` | Public | Aktueller Authorization Status |
| `hasAppleMusicSubscription` | `@Published Bool` | Public | `true` wenn aktives Apple Music Abo vorhanden |

### Computed Properties

#### `canUseMusicKit`
```swift
var canUseMusicKit: Bool
```
**Returns:** `true` wenn sowohl Authorization als auch Subscription vorhanden sind.

**Verwendung:**
```swift
if musicKitManager.canUseMusicKit {
    // MusicKit API calls sind möglich
}
```

#### `unavailabilityReason`
```swift
var unavailabilityReason: String?
```
**Returns:** Fehlermeldung String wenn MusicKit nicht verfügbar, sonst `nil`.

**Mögliche Werte:**
- `"Please allow access to Apple Music in Settings"`
- `"An Apple Music subscription is required"`
- `nil` (wenn alles OK)

### Methods

#### `requestAuthorization()`
```swift
func requestAuthorization() async
```

**Beschreibung:** Fragt User nach MusicKit Berechtigung.

**Async:** Ja - wartet auf User Input im Authorization Dialog

**Side Effects:**
- Aktualisiert `authorizationStatus`
- Aktualisiert `isAuthorized`
- Ruft `checkSubscriptionStatus()` bei Erfolg auf

**Beispiel:**
```swift
Task {
    await musicKitManager.requestAuthorization()
    if musicKitManager.isAuthorized {
        print("Authorization successful!")
    }
}
```

#### `checkSubscriptionStatus()`
```swift
private func checkSubscriptionStatus() async
```

**Beschreibung:** Prüft ob User ein Apple Music Abo hat.

**Async:** Ja - API Call zu Apple

**Side Effects:** Aktualisiert `hasAppleMusicSubscription`

**Error Handling:** Errors werden geloggt, Subscription wird auf `false` gesetzt

---

## PlaybackMonitor

### Overview
Überwacht den Apple Music Playback Status und erkennt den aktuell spielenden Song.

### Declaration
```swift
@MainActor
class PlaybackMonitor: ObservableObject
```

### Properties

| Name | Type | Access | Description |
|------|------|--------|-------------|
| `currentSong` | `@Published Song?` | Public | MusicKit Song Object des aktuellen Tracks |
| `isPlaying` | `@Published Bool` | Public | `true` wenn gerade Musik läuft |
| `playbackTime` | `@Published TimeInterval` | Public | Aktuelle Playback Position |
| `timer` | `Timer?` | Private | Timer für regelmäßige Updates |
| `musicBridge` | `MusicAppBridge` | Private | Bridge zu Music.app |

### Computed Properties

#### `currentSongInfo`
```swift
var currentSongInfo: String?
```
**Returns:** Formatierter String `"Title - Artist"` oder `nil`.

**Beispiel:**
```swift
if let info = playbackMonitor.currentSongInfo {
    print(info)  // "Bohemian Rhapsody - Queen"
}
```

#### `hasSongPlaying`
```swift
var hasSongPlaying: Bool
```
**Returns:** `true` wenn `isPlaying && currentSong != nil`.

**Verwendung:** Für UI Button States.

### Methods

#### `startMonitoring()`
```swift
func startMonitoring() async
```

**Beschreibung:** Startet das Playback Monitoring.

**Verhalten:**
1. Startet Timer (2 Sekunden Interval)
2. Führt initialen Update aus
3. Läuft kontinuierlich bis `stopMonitoring()` aufgerufen wird

**Performance:** ~1-2% CPU bei aktivem Timer

**Beispiel:**
```swift
await playbackMonitor.startMonitoring()
```

#### `stopMonitoring()`
```swift
func stopMonitoring()
```

**Beschreibung:** Stoppt das Monitoring.

**Side Effects:**
- Invalidiert Timer
- Stoppt alle weiteren Updates

#### `updatePlaybackState()`
```swift
private func updatePlaybackState() async
```

**Beschreibung:** Interner Update-Cycle.

**Flow:**
1. Ruft `musicBridge.updatePlaybackState()` auf
2. Aktualisiert `isPlaying`
3. Wenn Song läuft: `findSongInCatalog()`
4. Sonst: `currentSong = nil`

#### `findSongInCatalog()`
```swift
private func findSongInCatalog(trackName: String, artist: String?) async
```

**Parameter:**
- `trackName`: Name des Tracks aus Music.app
- `artist`: Optional - Artist Name für präzisere Suche

**Beschreibung:** Sucht den Song im MusicKit Catalog.

**Search Strategy:**
- Kombiniert `trackName` + `artist` als Search Term
- Limit: 5 Results
- Nimmt ersten Match als `currentSong`

**Error Handling:** Bei Fehler wird `currentSong = nil` gesetzt und Error geloggt.

**Console Logs:**
```
✅ Found song: Bohemian Rhapsody by Queen
⚠️ No song found for: Unknown Track
❌ Error searching for song: Network error
```

---

## MusicAppBridge

### Overview
AppleScript Bridge zu Music.app für direkten Zugriff auf Playback State.

### Declaration
```swift
@MainActor
class MusicAppBridge: ObservableObject
```

### Properties

| Name | Type | Access | Description |
|------|------|--------|-------------|
| `currentTrackName` | `@Published String?` | Public | Name des aktuellen Tracks |
| `currentArtist` | `@Published String?` | Public | Artist des aktuellen Tracks |
| `isPlaying` | `@Published Bool` | Public | Playback Status |
| `musicApp` | `SBApplication?` | Private | ScriptingBridge zu Music.app |

### Computed Properties

#### `currentTrackInfo`
```swift
var currentTrackInfo: String?
```
**Returns:** Formatierter String `"Track - Artist"` oder nur `"Track"` wenn Artist fehlt.

### Methods

#### `updatePlaybackState()`
```swift
func updatePlaybackState()
```

**Beschreibung:** Synchroner Call - aktualisiert Playback State via AppleScript.

**Flow:**
1. Prüft ob Music.app läuft (via System Events)
2. Wenn nicht: Alle Properties auf `nil`/`false` (KEIN Error)
3. Wenn ja: Fragt Player State ab
4. Parsed Ergebnis und updated Properties

**AppleScript:**
```applescript
tell application "System Events"
    return (name of processes) contains "Music"
end tell

tell application "Music"
    if player state is playing then
        set trackName to name of current track
        set trackArtist to artist of current track
        return trackName & "|" & trackArtist & "|playing"
    else
        return "||paused"
    end if
end tell
```

**Result Parsing:**
```
"Bohemian Rhapsody|Queen|playing" 
→ currentTrackName = "Bohemian Rhapsody"
→ currentArtist = "Queen"
→ isPlaying = true
```

**Error Handling:**
- Keine Exceptions werden geworfen
- Fehler werden nur geloggt (außer -600 = App not running)
- Graceful Degradation zu `nil`/`false` Values

#### `getCurrentTrackID()`
```swift
func getCurrentTrackID() -> String?
```

**Beschreibung:** Holt Persistent ID des Tracks aus Music.app.

**Returns:** Persistent ID String oder `nil` bei Fehler.

**Verwendung:** Für zukünftige Features (z.B. Song History Tracking).

#### `runAppleScript(_:)`
```swift
private func runAppleScript(_ source: String) -> String?
```

**Parameter:** AppleScript Source Code als String

**Returns:** Output String oder `nil` bei Fehler

**Error Handling:**
- Filtert -600 Error (App not running) aus Logs
- Andere Errors werden geloggt mit `⚠️`

---

## FavoritesService

### Overview
Service für Favorites Management via MusadoraKit.

### Declaration
```swift
class FavoritesService
```

### Methods

#### `addToFavorites(song:)`
```swift
func addToFavorites(song: Song) async throws -> Bool
```

**Parameter:**
- `song`: MusicKit `Song` Object

**Returns:** `true` bei Erfolg, sonst throws Error

**Throws:** `FavoritesError` bei Fehlern

**Beschreibung:** Fügt Song zu Apple Music Favorites hinzu.

**Implementation:**
```swift
try await MCatalog.addRating(for: song, rating: .like)
```

**Side Effects:**
- Song wird in iCloud Music Library als "Liked" markiert
- Sync erfolgt automatisch über Apple Music

**Beispiel:**
```swift
do {
    let success = try await favoritesService.addToFavorites(song: song)
    if success {
        print("Song favorited!")
    }
} catch {
    print("Error: \(error.localizedDescription)")
}
```

#### `removeFromFavorites(song:)`
```swift
func removeFromFavorites(song: Song) async throws -> Bool
```

**Parameter:**
- `song`: MusicKit `Song` Object

**Returns:** `true` bei Erfolg

**Throws:** `FavoritesError.networkError` bei Fehlern

**Beschreibung:** Entfernt Song aus Favorites.

**Implementation:**
```swift
try await MCatalog.deleteRating(for: song)
```

#### `isFavorited(song:)`
```swift
func isFavorited(song: Song) async throws -> Bool
```

**Parameter:**
- `song`: MusicKit `Song` Object

**Returns:** `true` wenn favorisiert

**Status:** 🚧 Nicht implementiert in v1.0 (MusadoraKit limitierung)

**Current Behavior:** Returns immer `false`

**Future:** MusicKit bietet keine "getRating" API - müsste via Library Search implementiert werden.

#### `getFavorites()`
```swift
func getFavorites() async throws -> [Song]
```

**Returns:** Array von favorisierten Songs

**Status:** 🚧 Nicht implementiert (für zukünftige Features)

---

## UI Layer

## MenuBarController

### Overview
NSStatusItem Management und Click Handling für Menu Bar Integration.

### Declaration
```swift
class MenuBarController: ObservableObject
```

### Properties

| Name | Type | Access | Description |
|------|------|--------|-------------|
| `statusItem` | `NSStatusItem?` | Private | Menu Bar Status Item |
| `isPlaying` | `@Published Bool` | Public | Current Playback State |

### Methods

#### `init()`
```swift
init()
```

**Side Effects:**
- Ruft `setupMenuBar()` auf
- Registriert Notification Observers

#### `setupMenuBar()`
```swift
private func setupMenuBar()
```

**Beschreibung:** Erstellt und konfiguriert das Status Item.

**Configuration:**
- Length: `NSStatusItem.squareLength` (22x22 pt)
- Icon: `star.fill` SF Symbol
- Color: `.systemGray` (Initial)
- Tooltip: `"StarTune - Click to favorite current song"`
- Action: `menuBarButtonClicked(_:)`
- Events: `.leftMouseUp` + `.rightMouseUp`

#### `menuBarButtonClicked(_:)`
```swift
@objc private func menuBarButtonClicked(_ sender: NSStatusBarButton)
```

**Beschreibung:** Handler für Clicks auf Status Item.

**Behavior:**
- **Left-Click:** Sendet `.addToFavorites` Notification
- **Right-Click:** Zeigt Context Menu

**Event Detection:**
```swift
let event = NSApp.currentEvent
if event?.type == .rightMouseUp {
    // Right-click
} else {
    // Left-click
}
```

#### `updateIcon(isPlaying:)`
```swift
func updateIcon(isPlaying: Bool)
```

**Parameter:**
- `isPlaying`: Neuer Playback Status

**Side Effects:**
- Updated Icon Color (`.systemYellow` oder `.systemGray`)
- Updated Tooltip Text

**Thread-Safe:** Verwendet `DispatchQueue.main.async`

**Beispiel:**
```swift
menuBarController.updateIcon(isPlaying: true)
// Icon wird gold
```

#### `showSuccessAnimation()`
```swift
func showSuccessAnimation()
```

**Beschreibung:** Zeigt Erfolgs-Feedback.

**Animation:**
1. Icon wird `.systemGreen`
2. Nach 0.5s: Zurück zu normalem State

**Visual:**
```
⭐️ (Gold) → ⭐️ (Grün) → ⭐️ (Gold)
    ^           ^           ^
  Normal    Success    Normal (0.5s später)
```

#### `showErrorAnimation()`
```swift
func showErrorAnimation()
```

**Beschreibung:** Zeigt Error-Feedback.

**Animation:**
1. Icon wird `.systemRed`
2. Nach 0.5s: Zurück zu normalem State

#### `showContextMenu()`
```swift
private func showContextMenu()
```

**Beschreibung:** Zeigt Context Menu bei Right-Click.

**Menu Items:**
- "About StarTune" → `showAbout()`
- Separator
- "Quit StarTune" (⌘Q) → `quit()`

**Implementation Detail:**
```swift
statusItem?.menu = menu
statusItem?.button?.performClick(nil)
statusItem?.menu = nil  // Wichtig: Menu danach wieder entfernen!
```

---

## MenuBarView

### Overview
SwiftUI View für den Popover Content des MenuBarExtra.

### Declaration
```swift
struct MenuBarView: View
```

### Properties

| Name | Type | Description |
|------|------|-------------|
| `musicKitManager` | `@ObservedObject` | MusicKit Manager Reference |
| `playbackMonitor` | `@ObservedObject` | Playback Monitor Reference |
| `favoritesService` | `@State` | Favorites Service Instance |
| `isProcessing` | `@State Bool` | API Call läuft gerade |

### Body Structure

```
VStack {
    Header: "StarTune"
    Divider
    
    if !authorized:
        authorizationSection
    else:
        currentlyPlayingSection
        Divider
        actionsSection
    
    Divider
    Quit Button
}
.padding()
.frame(width: 300)
```

### Sections

#### `authorizationSection`
```swift
private var authorizationSection: some View
```

**Content:**
- Text: "Authorization Required"
- Button: "Allow Access to Apple Music"

**Action:** Ruft `musicKitManager.requestAuthorization()` auf

#### `currentlyPlayingSection`
```swift
private var currentlyPlayingSection: some View
```

**Content:**
- Header: "Now Playing"
- Song Title (Body Font)
- Artist Name (Caption, Secondary)
- Album Title (Caption2, Secondary, Optional)
- Status Indicator: 🟢 "Playing" / ⚪️ "Paused"

**Layout:**
```
Now Playing
────────────────
Bohemian Rhapsody
Queen
A Night at the Opera
🟢 Playing
```

#### `actionsSection`
```swift
private var actionsSection: some View
```

**Content:**
- Button: "⭐️ Add to Favorites"
- ProgressView (wenn `isProcessing`)

**Button State:**
```swift
.disabled(!playbackMonitor.hasSongPlaying || isProcessing)
```

**Disabled wenn:**
- Kein Song spielt
- API Call läuft bereits

### Actions

#### `addToFavorites()`
```swift
private func addToFavorites()
```

**Flow:**
1. Guard: `currentSong` muss existieren
2. Set `isProcessing = true`
3. Call `favoritesService.addToFavorites()`
4. Bei Erfolg: Send `.favoriteSuccess` Notification
5. Bei Fehler: Send `.favoriteError` Notification
6. Set `isProcessing = false`

**Thread-Safety:** Verwendet `@MainActor.run` für UI Updates

**Error Handling:**
```swift
do {
    let success = try await favoritesService.addToFavorites(song: song)
    // Handle success
} catch {
    // Handle error
    print("Error: \(error.localizedDescription)")
}
```

---

## Models

## PlaybackState

### Overview
Model für Playback Status Snapshot.

### Declaration
```swift
struct PlaybackState
```

### Properties

| Name | Type | Description |
|------|------|-------------|
| `isPlaying` | `Bool` | Playback läuft |
| `currentSong` | `Song?` | MusicKit Song Object |
| `playbackTime` | `TimeInterval` | Aktuelle Position (Sekunden) |
| `duration` | `TimeInterval?` | Song Länge (Sekunden) |

### Computed Properties

#### `progress`
```swift
var progress: Double
```
**Returns:** Progress von 0.0 bis 1.0

**Formula:** `playbackTime / duration`

**Beispiel:**
```swift
let state = PlaybackState(isPlaying: true, currentSong: song, 
                          playbackTime: 120, duration: 240)
print(state.progress)  // 0.5 (50%)
```

#### `hasActiveSong`
```swift
var hasActiveSong: Bool
```
**Returns:** `true` wenn `currentSong != nil`

### Static Properties

#### `empty`
```swift
static let empty: PlaybackState
```
**Returns:** Leerer Default State (nichts spielt)

---

## AppSettings

### Overview
User Preferences mit UserDefaults Persistence.

### Declaration
```swift
class AppSettings: ObservableObject
```

### Properties

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `launchAtLogin` | `@Published Bool` | `false` | App beim Login starten |
| `showNotifications` | `@Published Bool` | `false` | Success Notifications zeigen |
| `keyboardShortcutEnabled` | `@Published Bool` | `false` | Global Shortcut aktiviert |

### Persistence

**Storage:** UserDefaults.standard

**Keys:**
```swift
private enum Keys {
    static let launchAtLogin = "launchAtLogin"
    static let showNotifications = "showNotifications"
    static let keyboardShortcutEnabled = "keyboardShortcutEnabled"
}
```

**Auto-Save:**
```swift
@Published var launchAtLogin: Bool {
    didSet {
        UserDefaults.standard.set(launchAtLogin, forKey: Keys.launchAtLogin)
    }
}
```

### Usage

```swift
let settings = AppSettings()

// Read
if settings.showNotifications {
    // Show notification
}

// Write (auto-saves to UserDefaults)
settings.launchAtLogin = true
```

---

## Notification System

### Overview
App-weites Event System via NotificationCenter.

### Notification Names

```swift
extension Notification.Name {
    static let addToFavorites = Notification.Name("addToFavorites")
    static let favoriteSuccess = Notification.Name("favoriteSuccess")
    static let favoriteError = Notification.Name("favoriteError")
}
```

### Flow

```
MenuBarView.addToFavorites()
         ↓
   [API Call]
         ↓
    Success?
    /      \
  Yes      No
   ↓        ↓
.favoriteSuccess  .favoriteError
   ↓                    ↓
MenuBarController.favoriteSuccess()
   ↓
showSuccessAnimation()
```

### Usage

**Sender:**
```swift
NotificationCenter.default.post(
    name: .favoriteSuccess,
    object: nil
)
```

**Observer:**
```swift
NotificationCenter.default.addObserver(
    self,
    selector: #selector(favoriteSuccess),
    name: .favoriteSuccess,
    object: nil
)

@objc func favoriteSuccess() {
    // Handle notification
}
```

---

## Error Handling

### FavoritesError

```swift
enum FavoritesError: LocalizedError {
    case notAuthorized
    case noSubscription
    case networkError
    case songNotFound
}
```

### Error Descriptions

| Error | Description | User Action |
|-------|-------------|-------------|
| `notAuthorized` | "Please authorize access to Apple Music" | Open Settings → Privacy |
| `noSubscription` | "An Apple Music subscription is required" | Subscribe to Apple Music |
| `networkError` | "Could not connect to Apple Music" | Check Internet connection |
| `songNotFound` | "Song not found" | Try different song |

### Error Handling Pattern

```swift
do {
    let result = try await operation()
} catch FavoritesError.notAuthorized {
    // Show authorization prompt
} catch FavoritesError.networkError {
    // Show network error
} catch {
    // Generic error
    print("Error: \(error.localizedDescription)")
}
```

### Console Logging

**Convention:**
- ✅ Success: Green checkmark
- ⚠️ Warning: Yellow triangle
- ❌ Error: Red X
- 🎵 Info: Music note

**Beispiele:**
```
✅ Successfully added 'Bohemian Rhapsody' to favorites
⚠️ No song found for: Unknown Track
❌ Error adding to favorites: Network error
🎵 Starting playback monitoring...
```

---

## Performance Considerations

### Timer Intervals

| Component | Interval | Rationale |
|-----------|----------|-----------|
| `PlaybackMonitor` | 2.0s | Balance zwischen Responsiveness und CPU |
| `MenuBarController` | N/A | Event-driven (Notifications) |

### Memory Management

**Weak References:** Bei Closures und Timer Callbacks immer `[weak self]` verwenden.

```swift
timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
    Task { @MainActor [weak self] in
        await self?.updatePlaybackState()
    }
}
```

**Deinit Cleanup:**
```swift
deinit {
    timer?.invalidate()
    NotificationCenter.default.removeObserver(self)
}
```

### API Rate Limiting

**MusicKit Catalog Search:**
- Limit: 5 Results
- Throttle: Max 1 Request pro 2s (via Timer)
- Keine parallelen Requests

---

## Thread Safety

### Main Actor Isolation

**UI-relevante Klassen:**
```swift
@MainActor
class MusicKitManager: ObservableObject { }

@MainActor
class PlaybackMonitor: ObservableObject { }

@MainActor
class MusicAppBridge: ObservableObject { }
```

**Benefit:** Compiler garantiert dass alle Property Updates auf Main Thread erfolgen.

### Async/Await Pattern

**Preferred:**
```swift
Task {
    await manager.requestAuthorization()
}
```

**Avoid:**
```swift
DispatchQueue.main.async {
    // Old-style async
}
```

---

## Testing Guidelines

### Unit Tests

**Example Test:**
```swift
func testPlaybackStateProgress() {
    let state = PlaybackState(
        isPlaying: true,
        currentSong: nil,
        playbackTime: 60,
        duration: 120
    )
    
    XCTAssertEqual(state.progress, 0.5)
}
```

### Integration Tests

**Example:**
```swift
func testMusicKitAuthorization() async {
    let manager = MusicKitManager()
    await manager.requestAuthorization()
    XCTAssertTrue(manager.isAuthorized)
}
```

### Manual Testing

Siehe [README.md Testing Section](../README.md#testing)

---

## Migration Guide

### Von v1.0 zu v2.0 (Future)

**Breaking Changes:** TBD

**Deprecated APIs:** TBD

---

**Last Updated:** 2025-10-27  
**Version:** 1.0.0
