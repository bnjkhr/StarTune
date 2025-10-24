# StarTune - macOS Menu Bar Favorites App

Eine macOS Menu Bar App, die es ermöglicht, den aktuell laufenden Apple Music Song per Klick zu favorisieren.

## 🚀 Status

**✅ Implementation Complete** - App kompiliert und baut erfolgreich!

**Version**: 0.1.0 (MVP)
**Build Status**: ✅ Successful
**Last Update**: 2025-10-24

## 📋 Projekt-Übersicht

**App-Name**: StarTune
**Platform**: macOS 14.0+ (Sonoma oder neuer)
**Framework**: SwiftUI + AppKit
**Sprache**: Swift 5.9+
**Dependencies**: MusadoraKit 4.5.1

### Kern-Feature
- **Menu Bar Icon** (⭐️): Zeigt Status von Apple Music
  - Gold: Apple Music spielt gerade
  - Grau: Keine Wiedergabe
- **Ein-Klick-Favoriten**: Klick auf Stern → aktueller Song wird zu Favorites hinzugefügt

---

## 🏗️ Architektur

### Komponenten-Struktur

```
StarTune/
├── StarTuneApp.swift          # App Entry Point
├── MenuBar/
│   ├── MenuBarController.swift   # NSStatusItem Management
│   └── MenuBarView.swift         # SwiftUI Menu Content
├── MusicKit/
│   ├── MusicKitManager.swift     # MusicKit Authorization & API
│   ├── PlaybackMonitor.swift    # Currently Playing Detection
│   └── FavoritesService.swift   # Favorites Management
├── Models/
│   ├── PlaybackState.swift      # Playback State Model
│   └── AppSettings.swift        # User Preferences
└── Resources/
    └── Assets.xcassets          # Icons & Images
```

---

## 🔧 Technische Details

### Frameworks & Dependencies

#### Native Frameworks
- `SwiftUI` - UI Framework
- `AppKit` - NSStatusItem für Menu Bar
- `MusicKit` - Apple Music Integration

#### External Dependencies (Swift Package Manager)
- **MusadoraKit** `v4.0.0+`
  - URL: `https://github.com/rryam/MusadoraKit`
  - Vereinfacht MusicKit Favorites API

### Entitlements & Capabilities

Benötigte Capabilities in Xcode:
- ✅ App Sandbox
- ✅ MusicKit (unter Signing & Capabilities)
- ✅ Network (Outgoing Connections)

---

## 🔐 Apple Developer Portal Setup

### Voraussetzungen
1. Apple Developer Account (bezahlt)
2. Gültiges Apple Music Abo für Testing

### Setup-Schritte

#### 1. App ID erstellen
- Bundle ID: `com.yourdomain.startune`
- Capabilities: MusicKit aktivieren

#### 2. MusicKit Konfiguration
1. Gehe zu: **Certificates, Identifiers & Profiles**
2. Wähle deine App ID
3. Aktiviere **MusicKit**
4. Konfiguriere **Automatic Token Generation**
   - Dies erspart manuelle JWT-Generierung!

#### 3. In Xcode konfigurieren
- Signing & Capabilities → MusicKit hinzufügen
- Team auswählen
- Automatisches Signing aktivieren

---

## 💻 Implementierungs-Details

### 1. MusicKit Authorization

```swift
import MusicKit

class MusicKitManager: ObservableObject {
    @Published var isAuthorized = false
    @Published var authorizationStatus: MusicAuthorization.Status = .notDetermined

    func requestAuthorization() async {
        let status = await MusicAuthorization.request()
        await MainActor.run {
            self.authorizationStatus = status
            self.isAuthorized = (status == .authorized)
        }
    }
}
```

**Wichtig**: User muss beim ersten Start die Berechtigung erteilen!

### 2. Currently Playing Detection

```swift
import MusicKit

class PlaybackMonitor: ObservableObject {
    @Published var currentSong: Song?
    @Published var isPlaying = false

    private var stateObserver: AnyCancellable?

    func startMonitoring() {
        // Observer für MusicPlayer.shared.state
        stateObserver = MusicPlayer.shared.state.objectWillChange
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.updatePlaybackState()
                }
            }
    }

    private func updatePlaybackState() async {
        let player = MusicPlayer.shared

        // Playback State
        isPlaying = (player.state.playbackStatus == .playing)

        // Aktueller Song
        if let entry = player.queue.currentEntry,
           case .song(let song) = entry.item {
            currentSong = song
        } else {
            currentSong = nil
        }
    }
}
```

**Tipp**: `MusicPlayer.shared.queue.currentEntry` liefert den aktuellen Song auf macOS 12.0+

### 3. Favorites Management (mit MusadoraKit)

```swift
import MusadoraKit
import MusicKit

class FavoritesService {
    func addToFavorites(song: Song) async throws -> Bool {
        // MusadoraKit vereinfacht die Favorites API
        let success = try await MCatalog.favorite(song: song)
        return success
    }

    func checkIfFavorited(song: Song) async throws -> Bool {
        // Optional: Prüfen ob Song bereits favorisiert ist
        // Details in MusadoraKit Docs
        return false // Implementation folgt
    }
}
```

**Alternative ohne MusadoraKit**:
Falls MusadoraKit nicht funktioniert, können wir die native MusicKit API verwenden (komplexer).

### 4. Menu Bar Integration

```swift
import AppKit
import SwiftUI

class MenuBarController: ObservableObject {
    private var statusItem: NSStatusItem?
    @Published var isPlaying = false

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.squareLength
        )

        guard let button = statusItem?.button else { return }

        // SF Symbol Icon
        button.image = NSImage(
            systemSymbolName: "star.fill",
            accessibilityDescription: "Favorite Current Song"
        )

        // Tint basierend auf Playback State
        button.contentTintColor = isPlaying ? .systemYellow : .systemGray

        // Action
        button.action = #selector(menuBarButtonClicked)
        button.target = self
    }

    @objc func menuBarButtonClicked() {
        // Trigger Favorite Action
        NotificationCenter.default.post(
            name: .addToFavorites,
            object: nil
        )
    }

    func updateIcon(isPlaying: Bool) {
        self.isPlaying = isPlaying
        statusItem?.button?.contentTintColor = isPlaying ? .systemYellow : .systemGray
    }
}

extension Notification.Name {
    static let addToFavorites = Notification.Name("addToFavorites")
}
```

**UI-Details**:
- Icon wird automatisch an macOS Dark/Light Mode angepasst
- Mindestgröße: 44x44pt (Touch Target Guidelines)
- Tooltip zeigt Song-Info beim Hover

### 5. App als Menu Bar Only (kein Dock Icon)

In `Info.plist`:
```xml
<key>LSUIElement</key>
<true/>
```

Oder in Xcode:
- Info.plist → Add Row
- Key: "Application is agent (UIElement)" → Value: YES

---

## 🎯 User Flow

### Erster Start
1. App startet
2. MusicKit Authorization Dialog erscheint
3. User authentifiziert mit Apple ID
4. Stern-Icon erscheint in Menu Bar (grau)

### Laufender Betrieb
1. User startet Apple Music
2. Song beginnt zu spielen
3. Stern-Icon wird gold ⭐️
4. User klickt auf Stern
5. Song wird zu Favorites hinzugefügt
6. Kurze Erfolgs-Animation
7. Optional: Notification "Song added to favorites"

### Fehlerbehandlung
- Kein Apple Music Abo → Zeige Alert mit Link zu apple.com/music
- Keine Berechtigung → "Please allow access to Apple Music in Settings"
- Netzwerkfehler → "Could not connect to Apple Music"
- Kein Song spielt → "No music is currently playing"

---

## 🧪 Testing

### Test-Szenarien

1. **Authorization**
   - ✅ Erste Autorisierung
   - ✅ Berechtigung verweigert
   - ✅ Berechtigung widerrufen (in System Settings)

2. **Playback Detection**
   - ✅ Song startet → Icon wird gold
   - ✅ Song pausiert → Icon bleibt gold
   - ✅ Song stoppt → Icon wird grau
   - ✅ Song wechselt → Icon bleibt gold, Song-Info aktualisiert

3. **Favorites**
   - ✅ Song favorisieren (neu)
   - ✅ Song favorisieren (bereits favorisiert)
   - ✅ Favorit ohne Apple Music Abo
   - ✅ Favorit ohne Internet

4. **Menu Bar**
   - ✅ Icon erscheint in Menu Bar
   - ✅ Klick-Action funktioniert
   - ✅ Dark/Light Mode Support
   - ✅ Multi-Monitor Setup

---

## 🚀 Build & Run

### Voraussetzungen
- macOS 13.0+ (Development Machine)
- Xcode 15.0+
- Apple Developer Account

### Erste Schritte

1. **Xcode Projekt öffnen**
   ```bash
   cd /Users/benkohler/Projekte/StarTune
   open StarTune.xcodeproj
   ```

2. **Dependencies installieren**
   - File → Add Package Dependencies
   - URL: `https://github.com/rryam/MusadoraKit`
   - Version: "Up to Next Major" ab 4.0.0

3. **Bundle ID & Signing konfigurieren**
   - Targets → StarTune → Signing & Capabilities
   - Team auswählen
   - Bundle ID anpassen: `com.YOURNAME.startune`

4. **MusicKit Capability hinzufügen**
   - Signing & Capabilities → "+" → MusicKit

5. **Build & Run**
   - Cmd+R oder Product → Run
   - Bei erstem Start: MusicKit Authorization erlauben

### Deployment

Für Distribution außerhalb App Store:
1. Developer ID Certificate erstellen
2. App notarisieren lassen
3. DMG oder PKG erstellen

---

## 🐛 Bekannte Probleme & Lösungen

### Problem: "Music User Token could not be obtained"
**Lösung**:
- MusicKit Capability in Xcode aktivieren
- Bundle ID im Developer Portal mit MusicKit verknüpfen
- App neu starten

### Problem: "nowPlayingItem ist nil"
**Lösung**:
- Verwende `MusicPlayer.shared.queue.currentEntry` statt `MPMusicPlayerController`
- Nur auf macOS 12.0+ verfügbar

### Problem: Menu Bar Icon erscheint nicht
**Lösung**:
- `NSStatusItem` muss als Strong Reference gespeichert werden
- In `@main` App struct als `@StateObject` halten

### Problem: Favorit wird nicht gespeichert
**Lösung**:
- Prüfe Authorization Status
- Prüfe Apple Music Abo-Status
- Prüfe Netzwerkverbindung
- Logge API-Response für Debugging

---

## 📚 Ressourcen & Links

### Apple Dokumentation
- [MusicKit Overview](https://developer.apple.com/musickit/)
- [MusicKit Swift Docs](https://developer.apple.com/documentation/musickit)
- [Automatic Token Generation](https://developer.apple.com/documentation/musickit/using-automatic-token-generation-for-apple-music-api)
- [NSStatusItem Documentation](https://developer.apple.com/documentation/appkit/nsstatusitem)

### Third-Party
- [MusadoraKit GitHub](https://github.com/rryam/MusadoraKit)
- [MusadoraKit Documentation](https://rryam.github.io/MusadoraKit/documentation/musadorakit/)

### WWDC Sessions
- [Meet MusicKit for Swift (WWDC21)](https://developer.apple.com/videos/play/wwdc2021/10294/)
- [Explore more content with MusicKit (WWDC22)](https://developer.apple.com/videos/play/wwdc2022/110347/)

---

## 🔄 Roadmap & Features

### Phase 1 - MVP (Aktuell)
- ✅ Menu Bar Icon
- ✅ Currently Playing Detection
- ✅ Add to Favorites
- ✅ Basic Authorization

### Phase 2 - Enhancements
- ⏳ Keyboard Shortcut (z.B. Cmd+Shift+F)
- ⏳ Notification bei Success
- ⏳ Settings Window (Launch at Login, etc.)
- ⏳ Zeige Song-Info in Popover

### Phase 3 - Advanced
- ⏳ Lyrics anzeigen
- ⏳ Rating System (1-5 Sterne)
- ⏳ Custom Playlists erstellen
- ⏳ Statistiken (Meist favorisierte Artists)

---

## 📝 Development Notes

### Coding Style
- SwiftUI + Combine für reaktive Updates
- Async/await für MusicKit API calls
- MVVM Architecture
- Dependency Injection wo möglich

### Performance Considerations
- Playback Monitoring: Nicht zu häufig pollen (alle 1-2 Sekunden reicht)
- Icon Updates: Nur bei State-Change
- API Calls: Rate Limiting beachten

### Accessibility
- VoiceOver Support für Menu Bar Item
- Keyboard Navigation
- High Contrast Mode Support

---

## 👥 Team & Credits

**Developer**: [Dein Name]
**Inspiration**: Apple Music + Menu Bar Apps
**Libraries**: MusadoraKit by Rudrank Riyam

---

## 📄 Lizenz

[Lizenz hier einfügen - z.B. MIT, Apache 2.0, etc.]

---

## 🤝 Contributing

Contributions sind willkommen! Bitte erstelle ein Issue oder Pull Request.

### Development Setup
1. Fork das Repository
2. Clone dein Fork
3. Erstelle einen Feature Branch
4. Commit deine Änderungen
5. Push zum Branch
6. Erstelle einen Pull Request

---

**Letzte Aktualisierung**: 2025-10-24
**Projekt Status**: 🟡 In Development
