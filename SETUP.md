# StarTune - Setup Guide

## 🚀 Quick Start

### 1. Xcode öffnen

Du hast zwei Möglichkeiten, das Projekt zu öffnen:

**Option A: Terminal**
```bash
cd /Users/benkohler/Projekte/StarTune
open StarTune.xcodeproj
```

**Option B: Finder**
- Navigiere zu `/Users/benkohler/Projekte/StarTune/`
- Doppelklick auf `StarTune.xcodeproj`

### 2. Neues Xcode Projekt erstellen (wenn .xcodeproj nicht funktioniert)

Falls das `.xcodeproj` File Probleme macht, erstelle ein neues Projekt:

1. **Xcode öffnen**
2. **File → New → Project**
3. **macOS → App** auswählen
4. **Projekt-Setup:**
   - Product Name: `StarTune`
   - Team: Dein Apple Developer Team
   - Organization Identifier: `com.DEINNAME` (z.B. `com.benkohler`)
   - Bundle Identifier wird zu: `com.DEINNAME.StarTune`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None**
5. **Speicherort:** `/Users/benkohler/Projekte/StarTune/`
6. **Create Git repository:** Optional

### 3. Dateien ins Xcode-Projekt importieren

Wenn du ein neues Xcode-Projekt erstellt hast:

1. **Lösche die automatisch erstellten Dateien:**
   - `StarTuneApp.swift` (wird durch unsere Version ersetzt)
   - `ContentView.swift` (brauchen wir nicht)

2. **Importiere alle Swift-Dateien:**
   - Rechtsklick auf "StarTune" Ordner im Xcode Navigator
   - "Add Files to StarTune..."
   - Navigiere zu `/Users/benkohler/Projekte/StarTune/StarTune/`
   - Wähle alle `.swift` Dateien aus
   - ✅ "Copy items if needed"
   - ✅ "Create groups"
   - ✅ Target: StarTune
   - "Add"

3. **Ordnerstruktur nachbauen:**
   - Erstelle Groups in Xcode: MenuBar, MusicKit, Models, Resources
   - Verschiebe die Dateien in die entsprechenden Groups

### 4. Dependencies hinzufügen (MusadoraKit)

1. **File → Add Package Dependencies...**
2. **URL eingeben:**
   ```
   https://github.com/rryam/MusadoraKit
   ```
3. **Dependency Rule:**
   - "Up to Next Major Version"
   - Minimum: `4.0.0`
4. **Add Package**
5. **MusadoraKit** auswählen für Target "StarTune"
6. **Add Package**

### 5. Info.plist konfigurieren

1. **Im Project Navigator: StarTune → Info.plist**
2. **Folgende Keys hinzufügen/ändern:**

   ```xml
   <key>LSUIElement</key>
   <true/>

   <key>NSAppleMusicUsageDescription</key>
   <string>StarTune needs access to Apple Music to add songs to your favorites.</string>
   ```

   **In Xcode GUI:**
   - "Application is agent (UIElement)" → YES
   - "Privacy - Apple Music Usage Description" → "StarTune needs access..."

### 6. Capabilities hinzufügen

1. **Target StarTune auswählen**
2. **Tab: "Signing & Capabilities"**
3. **Team auswählen** (dein Apple Developer Account)
4. **"+ Capability" Button klicken**
5. **"App Sandbox" hinzufügen**
6. **"+ Capability" Button klicken**
7. **"MusicKit" hinzufügen** (nur verfügbar mit bezahltem Developer Account!)

### 7. App Sandbox konfigurieren

Unter "App Sandbox":
- ✅ Outgoing Connections (Network)
- ✅ Music Folder (unter File Access)

### 8. Bundle Identifier anpassen

1. **Target StarTune → General**
2. **Bundle Identifier:**
   - Format: `com.DEINNAME.startune`
   - Beispiel: `com.benkohler.startune`
3. **Dieser muss mit deinem Apple Developer Portal übereinstimmen!**

---

## 🔐 Apple Developer Portal Setup

### Voraussetzungen
- ✅ Bezahlter Apple Developer Account ($99/Jahr)
- ✅ Apple Music Abo (für Testing)

### Schritt-für-Schritt

#### 1. App ID erstellen

1. **Gehe zu:** [developer.apple.com/account](https://developer.apple.com/account)
2. **Certificates, Identifiers & Profiles**
3. **Identifiers → "+" (Plus-Button)**
4. **"App IDs" auswählen → Continue**
5. **Type: "App" → Continue**
6. **Konfiguration:**
   - Description: `StarTune`
   - Bundle ID: `com.DEINNAME.startune` (exakt wie in Xcode!)
   - Capabilities: **MusicKit** aktivieren ✅
7. **Continue → Register**

#### 2. MusicKit konfigurieren

1. **Deine App ID in der Liste auswählen**
2. **"MusicKit" → Configure**
3. **"Enable automatic token generation"** ✅
   - Dies erspart manuelle JWT-Erstellung!
4. **Save**

#### 3. Provisioning Profile erstellen (optional, für Testing auf anderen Macs)

Für lokale Entwicklung reicht "Automatically manage signing" in Xcode.

---

## 🏃‍♂️ App starten

### Build & Run

1. **Xcode: Product → Run** (oder Cmd+R)
2. **Bei erstem Start:**
   - macOS fragt nach Berechtigungen
   - "Erlauben" klicken
3. **MusicKit Authorization:**
   - Dialog erscheint
   - Mit Apple ID autorisieren
4. **Stern-Icon erscheint in Menu Bar!** ⭐️

### Testing

1. **Apple Music App öffnen**
2. **Song abspielen**
3. **Stern in Menu Bar sollte gold werden** ⭐️
4. **Auf Stern klicken**
5. **Song wird zu Favorites hinzugefügt**

---

## ⚠️ Troubleshooting

### Problem: "MusicKit capability nicht verfügbar"

**Lösung:**
- Bezahlter Apple Developer Account nötig
- Im Developer Portal: MusicKit für Bundle ID aktivieren
- Xcode neu starten

### Problem: "No such module 'MusadoraKit'"

**Lösung:**
1. File → Add Package Dependencies
2. MusadoraKit URL eingeben: `https://github.com/rryam/MusadoraKit`
3. Product → Clean Build Folder (Cmd+Shift+K)
4. Product → Build (Cmd+B)

### Problem: "Menu Bar Icon erscheint nicht"

**Lösung:**
- Info.plist: `LSUIElement` = YES prüfen
- App im Debug Mode starten
- Console auf Fehler prüfen

### Problem: "Authorization failed"

**Lösung:**
1. System Settings → Privacy & Security → Media & Apple Music
2. StarTune aktivieren
3. App neu starten

### Problem: "Playback Monitor erkennt keine Songs"

**Lösung:**
- Prüfe ob Apple Music (nicht Spotify!) läuft
- macOS Version mindestens 12.0
- MusicKit Berechtigung erteilt

---

## 📁 Projekt-Struktur

```
StarTune/
├── README.md                      # Haupt-Dokumentation
├── SETUP.md                       # Diese Setup-Anleitung
├── Package.swift                  # SPM Dependencies
├── StarTune.xcodeproj/           # Xcode Projekt
└── StarTune/                     # Source Code
    ├── StarTuneApp.swift         # App Entry Point
    ├── Info.plist                # App Configuration
    ├── MenuBar/
    │   ├── MenuBarController.swift
    │   └── MenuBarView.swift
    ├── MusicKit/
    │   ├── MusicKitManager.swift
    │   ├── PlaybackMonitor.swift
    │   └── FavoritesService.swift
    ├── Models/
    │   ├── PlaybackState.swift
    │   └── AppSettings.swift
    └── Resources/
```

---

## 🎯 Nächste Schritte

Nach erfolgreichem Setup:

1. **Code anpassen:**
   - In `FavoritesService.swift`: MusadoraKit Integration vervollständigen
   - TODOs im Code durchgehen

2. **Features hinzufügen:**
   - Keyboard Shortcuts
   - Notifications
   - Settings Window

3. **Testing:**
   - Verschiedene Playback-Szenarien testen
   - Edge Cases prüfen

4. **Deployment:**
   - Code signieren
   - App notarisieren
   - DMG erstellen

---

## 📞 Support

Bei Problemen:
1. Console in Xcode prüfen (Cmd+Shift+Y)
2. README.md → "Bekannte Probleme" durchlesen
3. Apple Developer Forums: [developer.apple.com/forums](https://developer.apple.com/forums)

---

**Viel Erfolg!** 🎵⭐️
