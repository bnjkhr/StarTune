# Xcode Project Setup für StarTune

## Problem: MusicKit braucht Entitlements

Swift Package Manager kann keine Entitlements setzen, daher **müssen wir ein Xcode-Projekt erstellen**.

---

## 🚀 Schritt-für-Schritt Anleitung

### 1. Xcode öffnen

```bash
open -a Xcode
```

### 2. Neues Projekt erstellen

1. **File → New → Project** (Cmd+Shift+N)
2. **macOS** → **App** auswählen
3. **Next**

### 3. Projekt konfigurieren

Wichtig - **exakt diese Werte verwenden**:

```
Product Name:           StarTune
Team:                   [Dein Apple Developer Team auswählen]
Organization Identifier: com.benkohler
Bundle Identifier:      com.benkohler.StarTune
Interface:              SwiftUI
Language:               Swift
Storage:                None
✅ Include Tests:       Optional
```

### 4. Speicherort wählen

**WICHTIG**: Speichere in einem **neuen Ordner**:

```
Location: /Users/benkohler/Projekte/StarTune-Xcode
```

(Nicht im bestehenden StarTune Ordner!)

### 5. Projekt öffnet sich

Xcode erstellt automatisch:
- `StarTuneApp.swift`
- `ContentView.swift`
- `Assets.xcassets`
- `StarTune.entitlements`

---

## 📁 Dateien hinzufügen

### 1. Alte Dateien löschen

Im Xcode Navigator (links):
- **Rechtsklick** auf `ContentView.swift` → **Delete** → **Move to Trash**
- **Rechtsklick** auf `StarTuneApp.swift` → **Delete** → **Move to Trash**

### 2. Unsere Dateien importieren

1. **Im Finder**: Navigiere zu `/Users/benkohler/Projekte/StarTune/Sources/StarTune/`

2. **Markiere alle Dateien und Ordner**:
   - `StarTuneApp.swift`
   - `MenuBar/` (Ordner)
   - `MusicKit/` (Ordner)
   - `Models/` (Ordner)

3. **Ziehe sie in Xcode** in den `StarTune` Ordner (links im Navigator)

4. **Im Dialog**:
   - ✅ **Copy items if needed**
   - ✅ **Create groups**
   - ✅ **Add to targets: StarTune**
   - **Finish**

### 3. Package Dependencies hinzufügen

1. **File → Add Package Dependencies...**
2. **URL eingeben**:
   ```
   https://github.com/rryam/MusadoraKit
   ```
3. **Dependency Rule**: Up to Next Major Version, ab `4.0.0`
4. **Add Package**
5. **MusadoraKit** für Target "StarTune" auswählen
6. **Add Package**

---

## 🔐 Capabilities konfigurieren

### 1. Target auswählen

- Klicke auf **StarTune** (ganz oben, blaues Icon)
- Tab: **Signing & Capabilities**

### 2. Team auswählen

- **Team**: Wähle dein Apple Developer Account

### 3. App Sandbox hinzufügen

- **+ Capability** → **App Sandbox**
- In App Sandbox:
  - ✅ **Outgoing Connections (Client)**

### 4. MusicKit hinzufügen

- **+ Capability** → **MusicKit**
- Erscheint automatisch in der Liste

### 5. Entitlements prüfen

In `StarTune.entitlements` sollte stehen:

```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.developer.music-kit</key>
<true/>
<key>com.apple.security.automation.apple-events</key>
<true/>
```

Falls `automation.apple-events` fehlt:
- Öffne `StarTune.entitlements`
- Füge manuell hinzu (für AppleScript-Zugriff auf Music.app)

---

## 📄 Info.plist konfigurieren

### 1. Info.plist öffnen

- Im Navigator: **Info** (oder Info.plist)

### 2. Keys hinzufügen

**Rechtsklick** → **Add Row**:

1. **Application is agent (UIElement)**
   - Typ: Boolean
   - Value: **YES**
   - (Versteckt App aus Dock)

2. **Privacy - Apple Music Usage Description**
   - Typ: String
   - Value: **"StarTune needs access to Apple Music to add songs to your favorites."**

---

## 🏃 Build & Run

### 1. Build

- **Product → Build** (Cmd+B)
- Sollte ohne Fehler durchlaufen

### 2. Run

- **Product → Run** (Cmd+R)
- App startet
- Stern erscheint in Menu Bar

### 3. Berechtigungen erlauben

Beim ersten Start:

1. **MusicKit Authorization**
   - Dialog erscheint
   - **Allow** klicken
   - Mit Apple ID einloggen

2. **Automation Permission** (falls gefragt)
   - System Settings → Privacy & Security → Automation
   - StarTune → Music.app erlauben

---

## ✅ Testing

1. **Apple Music öffnen**
2. **Song abspielen**
3. **Stern wird gelb** (nach 2-4 Sekunden)
4. **Stern anklicken**
5. **"Add to Favorites"** klicken
6. **Im Terminal** (Xcode Console):
   ```
   ✅ Found song: [Title] by [Artist]
   ✅ Successfully added '[Title]' to favorites
   ```

---

## 🐛 Troubleshooting

### Build Error: "No such module 'MusadoraKit'"

**Lösung**:
- File → Add Package Dependencies
- MusadoraKit erneut hinzufügen

### "Permission denied" für MusicKit

**Check**:
1. Signing & Capabilities → MusicKit ist hinzugefügt
2. Team ist ausgewählt
3. Bundle ID stimmt mit Apple Developer Portal überein

### Stern erscheint nicht in Menu Bar

**Check**:
- Info.plist → Application is agent = YES
- App im Debug Mode laufen lassen
- Console auf Fehler prüfen

### Music.app wird nicht erkannt

**Check**:
- System Settings → Privacy → Automation
- StarTune → Music erlauben
- Oder: Terminal öffnen und ausführen:
  ```bash
  osascript -e 'tell application "Music" to get player state'
  ```

---

## 📦 Alternative: Pre-configured Project

Falls das zu kompliziert ist, kann ich ein fertiges Xcode-Projekt für dich generieren.

**Sag Bescheid!** 🎵

---

## 🔄 Zurück zu Swift Package

Falls du später wieder zum Swift Package wechseln willst:
- Code ist identisch
- Einfach Dateien zurück nach `Sources/StarTune/` kopieren
- Aber: MusicKit wird **nicht funktionieren** ohne Entitlements

---

**Viel Erfolg!** 🚀⭐️
