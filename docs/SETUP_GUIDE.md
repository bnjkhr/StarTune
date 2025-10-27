# StarTune Setup & Deployment Guide

Schritt-für-Schritt Anleitung für Development Setup, Testing und Production Deployment.

---

## Table of Contents

1. [Development Setup](#development-setup)
2. [Apple Developer Portal Configuration](#apple-developer-portal-configuration)
3. [Xcode Configuration](#xcode-configuration)
4. [Local Testing](#local-testing)
5. [Build for Distribution](#build-for-distribution)
6. [App Store Submission](#app-store-submission)
7. [Direct Distribution](#direct-distribution)
8. [Troubleshooting](#troubleshooting)

---

## Development Setup

### Prerequisites

**Hardware:**
- Mac mit Apple Silicon (M1/M2/M3) oder Intel Prozessor
- Mindestens 8 GB RAM
- 5 GB freier Speicherplatz

**Software:**
- macOS 14.0 (Sonoma) oder neuer
- Xcode 15.0 oder neuer
- Git 2.0+
- Apple Music App (installiert und eingeloggt)

**Accounts:**
- Apple Developer Account (bezahlt - $99/Jahr)
- Aktives Apple Music Abo für Testing

### Step 1: Repository klonen

```bash
# Repository klonen
git clone https://github.com/yourusername/startune.git
cd startune

# Projekt-Struktur prüfen
ls -la
# Sollte enthalten: StarTune-Xcode/, docs/, README.md
```

### Step 2: Xcode öffnen

```bash
cd StarTune-Xcode/StarTune
open StarTune.xcodeproj
```

**Wichtig:** Öffne **nicht** `StarTune.xcworkspace` - das Projekt verwendet SPM, nicht CocoaPods.

### Step 3: Dependencies verifizieren

1. Xcode öffnet automatisch
2. Warte auf "Resolving Package Dependencies..." (unten rechts)
3. MusadoraKit sollte automatisch geladen werden

**Falls Dependencies fehlen:**
```
File → Add Package Dependencies...
URL: https://github.com/rryam/MusadoraKit
Branch: main
Add to Target: StarTune
```

### Step 4: Team und Bundle ID konfigurieren

1. Wähle **StarTune** Target (links oben)
2. Tab: **Signing & Capabilities**
3. Team: Wähle dein Apple Developer Team
4. Bundle Identifier: Ändere zu `com.YOURNAME.startune`
   - Muss unique sein
   - Lowercase empfohlen
   - Keine Sonderzeichen

**Screenshot Guide:**
```
StarTune Target
├── Signing & Capabilities
│   ├── Team: [Your Name] (Your Team ID)
│   ├── Bundle Identifier: com.yourname.startune
│   └── Automatically manage signing: ✓
```

### Step 5: First Build

```bash
# Command-Line Build (optional)
xcodebuild -project StarTune.xcodeproj \
           -scheme StarTune \
           -configuration Debug \
           build

# Oder in Xcode:
⌘B (Build)
```

**Erwartetes Ergebnis:**
```
Build Succeeded
Total time: 15-30 seconds
```

**Bei Errors:** Siehe [Troubleshooting](#troubleshooting)

---

## Apple Developer Portal Configuration

### Step 1: App ID erstellen

1. Gehe zu [Apple Developer Portal](https://developer.apple.com/account)
2. Navigate: **Certificates, Identifiers & Profiles**
3. Klick: **Identifiers** → **+** Button

**Configuration:**
```
Type: App IDs
Platform: macOS
Description: StarTune Menu Bar App
Bundle ID: com.yourname.startune (EXACT match mit Xcode!)
```

### Step 2: MusicKit Capability aktivieren

Noch auf der App ID Page:

1. Scroll zu **Capabilities**
2. Finde **MusicKit**
3. Checkbox ✓ aktivieren
4. Klick: **Configure**

**MusicKit Configuration:**
```
Music ID: [Auto-generated]
Music User Tokens: Enabled
Automatic Token Generation: ✓ ENABLED (wichtig!)
```

**Wichtig:** Automatic Token Generation erspart dir manuelle JWT-Generierung!

### Step 3: App ID speichern

1. Klick: **Continue**
2. Klick: **Register**
3. Status: "Enabled" neben MusicKit

**Verification:**
```bash
# CLI Check (optional)
xcrun altool --list-apps \
  --username "your-apple-id@email.com" \
  --password "@keychain:AC_PASSWORD"
```

### Step 4: Provisioning Profile (Optional für Development)

Xcode erstellt automatisch Development Profiles wenn "Automatically manage signing" aktiviert ist.

**Manuelles Erstellen (nur für Distribution):**
1. **Profiles** → **+** Button
2. Type: **Developer ID** oder **Mac App Distribution**
3. App ID: Wähle deine StarTune App ID
4. Certificate: Wähle dein Developer ID Certificate
5. Download und Doppelklick zum Installieren

---

## Xcode Configuration

### Signing & Capabilities

#### 1. Signing

```
Target: StarTune
Tab: Signing & Capabilities

[ ] Automatically manage signing (für Production OFF)
Team: Your Team
Signing Certificate: Mac Developer / Developer ID Application
Provisioning Profile: Xcode Managed / Manual
```

**Empfehlung:**
- **Development:** Automatic Signing ON
- **Production:** Automatic Signing OFF, Manual Profile

#### 2. Capabilities hinzufügen

**App Sandbox:**
```
+ Capability → App Sandbox

App Sandbox: ✓
├── Network
│   ├── Incoming Connections (Client): ✗
│   └── Outgoing Connections (Client): ✓
├── Hardware
│   └── Audio Input: ✗
└── File Access
    └── User Selected Files: Read Only
```

**Hardened Runtime:**
```
+ Capability → Hardened Runtime

Hardened Runtime: ✓
Runtime Exceptions: (leer)
```

**MusicKit:**
```
WICHTIG: MusicKit ist KEINE Capability in Xcode!
Configuration erfolgt nur im Developer Portal.
```

### Build Settings

**Deployment Target:**
```
Build Settings → Deployment
macOS Deployment Target: 14.0
```

**Swift Compiler:**
```
Build Settings → Swift Compiler
Swift Language Version: Swift 5
Compilation Mode: Whole Module Optimization (Release)
```

**Code Signing:**
```
Build Settings → Signing
Code Signing Identity:
  - Debug: Mac Developer
  - Release: Developer ID Application
```

### Info.plist Configuration

Bereits konfiguriert, aber zur Referenz:

```xml
<key>CFBundleDisplayName</key>
<string>StarTune</string>

<key>CFBundleIdentifier</key>
<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>

<key>CFBundleShortVersionString</key>
<string>1.0</string>

<key>CFBundleVersion</key>
<string>1</string>

<!-- Menu Bar Only App -->
<key>LSUIElement</key>
<true/>

<!-- Permissions -->
<key>NSAppleEventsUsageDescription</key>
<string>StarTune needs to communicate with Music.app to detect currently playing songs.</string>

<key>NSAppleMusicUsageDescription</key>
<string>StarTune needs access to Apple Music to add songs to your favorites.</string>
```

**Wichtig:**
- `LSUIElement = true` → Kein Dock Icon
- `NSAppleEventsUsageDescription` → Für AppleScript Bridge
- `NSAppleMusicUsageDescription` → Für MusicKit (optional aber empfohlen)

---

## Local Testing

### Step 1: First Run

```bash
# In Xcode:
⌘R (Run)

# Oder Terminal:
open /Users/yourname/Library/Developer/Xcode/DerivedData/StarTune-*/Build/Products/Debug/StarTune.app
```

**Expected Behavior:**
1. App startet (kein Window!)
2. Stern-Icon erscheint in Menu Bar (grau)
3. Klick auf Icon → Popover öffnet sich

### Step 2: Authorization Testing

**Test 1: Erste Authorization**
1. Klick auf "Allow Access to Apple Music"
2. System Dialog erscheint
3. Klick "OK" (mit Apple ID authentifizieren)
4. Popover zeigt nun "Now Playing" Section

**Test 2: Berechtigung verweigert**
1. Klick "Don't Allow"
2. Button sollte wieder erscheinen
3. Erneuter Click → neuer Dialog

**Test 3: Berechtigung widerrufen**
1. System Settings → Privacy & Security → Media & Apple Music
2. Entferne StarTune
3. App neu starten
4. Authorization Button sollte wieder da sein

### Step 3: Playback Detection Testing

**Setup:**
1. Apple Music öffnen
2. Song abspielen (z.B. "Bohemian Rhapsody")
3. Warte 2-3 Sekunden

**Expected:**
- Icon wird gold ⭐️
- Popover zeigt Song-Info
- Status: "🟢 Playing"

**Test Cases:**

| Action | Expected Behavior |
|--------|-------------------|
| Song pausieren | Icon bleibt gold, Status: "⚪️ Paused" |
| Song stoppen | Icon wird grau nach 2s |
| Song wechseln | Icon bleibt gold, Song-Info updated |
| Music.app beenden | Icon wird grau, kein Error in Console |

### Step 4: Favorites Testing

**Test 1: Song favorisieren**
1. Song läuft in Apple Music
2. Klick auf Icon → Popover
3. Klick "Add to Favorites"
4. Icon wird kurz grün
5. Check in Apple Music: Song sollte "Liked" sein

**Test 2: Ohne Internet**
1. WiFi/Ethernet trennen
2. Song favorisieren
3. Icon sollte rot werden
4. Console: "❌ Error: Network error"

**Test 3: Kein Abo**
1. Apple Music Abo kündigen (⚠️ Vorsicht!)
2. App neu starten
3. Should show "Subscription required" error

### Step 5: Edge Cases

**Test 1: Music.app nicht installiert**
```bash
# Music.app umbenennen (BACKUP FIRST!)
sudo mv /System/Applications/Music.app /System/Applications/Music.app.backup

# App starten → Icon sollte grau sein, kein Crash
```

**Test 2: Lokale Files (nicht Apple Music)**
1. MP3 File in Music.app importieren
2. Lokales File abspielen
3. Icon wird gold, aber Song-Info fehlt (expected)

**Test 3: Podcasts/Radio**
1. Apple Music Radio starten
2. Icon sollte grau bleiben (nur Songs supported)

### Console Logging

**Wichtige Logs:**
```
🎵 Starting playback monitoring...
✅ Found song: Bohemian Rhapsody by Queen
Adding song to favorites: Bohemian Rhapsody
✅ Successfully added 'Bohemian Rhapsody' to favorites
```

**Error Logs:**
```
⚠️ No song found for: Unknown Track
❌ Error adding to favorites: Network error
⚠️ AppleScript Error: Music.app not running
```

---

## Build for Distribution

### Step 1: Archive erstellen

**In Xcode:**
```
1. Product → Scheme → Edit Scheme
2. Run → Build Configuration: Release
3. Product → Archive
4. Warte auf "Archive succeeded"
```

**Verification:**
```
Window → Organizer
├── Archives Tab
└── StarTune 1.0 (2025-10-27)
    ├── Size: ~2 MB
    └── Valid for Distribution: ✓
```

### Step 2: Export Options

**Option A: Developer ID (Direct Distribution)**

```
1. Klick "Distribute App"
2. Method: "Developer ID"
3. Upload: "Upload" (für Notarization)
4. Distribution Certificate: "Developer ID Application"
5. Profile: Xcode Managed
6. Next → Export
```

**Option B: App Store**

```
1. Klick "Distribute App"
2. Method: "Mac App Store"
3. Upload: "Upload"
4. Distribution Certificate: "Mac App Distribution"
5. Profile: Select manually
6. Next → Upload to App Store Connect
```

### Step 3: Notarization (Developer ID only)

**Automatic (Xcode 13+):**
- Xcode notarisiert automatisch bei Export
- Dauer: 5-15 Minuten
- Status: Check in Organizer

**Manual:**
```bash
# 1. Zip App
cd /path/to/StarTune.app
ditto -c -k --keepParent StarTune.app StarTune.zip

# 2. Submit für Notarization
xcrun notarytool submit StarTune.zip \
  --apple-id "your-email@example.com" \
  --team-id "YOUR_TEAM_ID" \
  --password "@keychain:AC_PASSWORD"

# 3. Check Status
xcrun notarytool history --apple-id "your-email@example.com"

# 4. Staple Ticket
xcrun stapler staple StarTune.app
```

**Verification:**
```bash
# Check Notarization
xcrun stapler validate StarTune.app

# Should output:
# The validate action worked!
```

### Step 4: DMG erstellen (Optional)

**Simple DMG:**
```bash
hdiutil create -volname "StarTune" \
               -srcfolder StarTune.app \
               -ov \
               -format UDZO \
               StarTune.dmg
```

**DMG with Custom Background:**
```bash
# 1. Create DMG Template
hdiutil create -size 50m -fs HFS+ -volname "StarTune" temp.dmg
hdiutil attach temp.dmg

# 2. Copy App
cp -R StarTune.app /Volumes/StarTune/

# 3. Create Applications Symlink
ln -s /Applications /Volumes/StarTune/Applications

# 4. Add Background Image
cp background.png /Volumes/StarTune/.background/

# 5. Set View Options (open in Finder)
open /Volumes/StarTune

# 6. Convert to Read-Only
hdiutil detach /Volumes/StarTune
hdiutil convert temp.dmg -format UDZO -o StarTune.dmg
rm temp.dmg
```

---

## App Store Submission

### Prerequisites

1. **App Store Connect Account**
   - Zugang mit Admin/App Manager Rolle
   - Agreement akzeptiert

2. **App ID konfiguriert** (siehe oben)

3. **Screenshots** (Required)
   - 1280x800 px (minimum)
   - PNG oder JPEG
   - Mind. 1 Screenshot, max. 10

4. **App Icon** (Already included in Assets.xcassets)
   - 512x512 px und 1024x1024 px

### Step 1: App Store Connect Setup

1. Login: [App Store Connect](https://appstoreconnect.apple.com)
2. **My Apps** → **+** Button → **New App**

**Configuration:**
```
Platform: macOS
Name: StarTune
Primary Language: English (or German)
Bundle ID: com.yourname.startune (select from dropdown)
SKU: STARTUNE001 (unique identifier)
User Access: Full Access
```

### Step 2: App Information

**Category:**
```
Primary: Music
Secondary: Utilities (optional)
```

**Description:**
```
StarTune is a lightweight macOS Menu Bar app that lets you 
favorite your currently playing Apple Music songs with a 
single click. 

Features:
• One-click favorites from Menu Bar
• Live playback detection
• Dynamic icon shows playback status
• Native macOS integration
• Privacy-focused - all data stays local
```

**Keywords:**
```
music, apple music, favorites, menu bar, utility, productivity, 
songs, playback, quick, easy
```

**Support URL:**
```
https://github.com/yourusername/startune
```

**Privacy Policy URL:**
```
https://yourusername.github.io/startune/privacy
```

### Step 3: Pricing

**Free App:**
```
Price: Free
Availability: All Countries
```

**Paid App (Optional):**
```
Price Tier: Tier 1 ($0.99) oder höher
Free Trial: Optional
```

### Step 4: App Review Information

```
Sign-in Required: No (app nutzt User's eigenen Apple Music Account)

Contact Information:
  First Name: Your Name
  Last Name: Your Name
  Phone: +49...
  Email: your-email@example.com

Notes for Reviewer:
  "StarTune requires an active Apple Music subscription to test.
   Please ensure you're signed in to Apple Music before testing.
   Click the star icon in the Menu Bar and play a song in Apple Music.
   The icon will turn gold when music is playing."

Demo Account: Not required
```

### Step 5: Upload Build

**Via Xcode:**
```
1. Product → Archive
2. Distribute App → App Store
3. Upload
4. Wait for "Upload Successful"
```

**Status Check:**
```
App Store Connect → My Apps → StarTune → TestFlight
Should show: "Processing" → "Ready to Submit" (5-10 minutes)
```

### Step 6: Submit for Review

1. **App Store** Tab (not TestFlight)
2. **+ Version** (z.B. 1.0)
3. Fill out **What's New**: "Initial Release"
4. **Build**: Select uploaded build
5. **Submit for Review**

**Review Timeline:**
- Initial Review: 24-72 hours
- Updates: 24-48 hours

### Step 7: After Approval

**Status:** "Ready for Sale"

**Download Link:**
```
https://apps.apple.com/app/idXXXXXXXXXX
```

**Marketing:**
- Add badge to README
- Tweet/Blog Post
- Submit to Product Hunt

---

## Direct Distribution

### Step 1: Export Signed App

**Xcode:**
```
Product → Archive → Distribute App → Developer ID
```

**Output:**
```
/Users/yourname/Desktop/StarTune/
└── StarTune.app (signed & notarized)
```

### Step 2: Create Distribution Package

**Option A: DMG (Recommended)**

Siehe [Build for Distribution - Step 4](#step-4-dmg-erstellen-optional)

**Option B: ZIP**

```bash
cd /path/to/StarTune.app
ditto -c -k --keepParent StarTune.app StarTune.zip
```

**Option C: PKG Installer**

```bash
pkgbuild --component StarTune.app \
         --install-location /Applications \
         --identifier com.yourname.startune \
         StarTune.pkg
```

### Step 3: Hosting

**Option A: GitHub Releases**

```bash
# Create Release on GitHub
gh release create v1.0.0 \
  StarTune.dmg \
  --title "StarTune v1.0.0" \
  --notes "Initial release"
```

**Option B: Self-Hosting**

```bash
# Upload to your Server
scp StarTune.dmg user@yourserver.com:/var/www/downloads/
```

**Download URL:**
```
https://yourserver.com/downloads/StarTune.dmg
or
https://github.com/yourname/startune/releases/download/v1.0.0/StarTune.dmg
```

### Step 4: Update Mechanism (Optional)

**Sparkle Framework Integration:**

```swift
// Add to Package.swift
dependencies: [
    .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.0.0")
]

// In App
import Sparkle

let updater = SPUStandardUpdaterController(
    startingUpdater: true,
    updaterDelegate: nil,
    userDriverDelegate: nil
)
```

**appcast.xml:**
```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>StarTune Updates</title>
    <item>
      <title>Version 1.0.0</title>
      <sparkle:version>1.0.0</sparkle:version>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
      <pubDate>Mon, 27 Oct 2025 12:00:00 +0000</pubDate>
      <enclosure url="https://yourserver.com/StarTune-1.0.0.dmg"
                 sparkle:edSignature="..."
                 length="2048000"
                 type="application/octet-stream" />
    </item>
  </channel>
</rss>
```

---

## Troubleshooting

### Build Errors

#### Error: "No such module 'MusadoraKit'"

**Lösung:**
```
File → Packages → Reset Package Caches
File → Packages → Update to Latest Package Versions
⌘B (Rebuild)
```

#### Error: "Code Signing Identity not found"

**Lösung:**
```bash
# 1. Check Certificates
security find-identity -v -p codesigning

# 2. Download Certificates
Xcode → Preferences → Accounts → Download Manual Profiles

# 3. Clean Build Folder
Product → Clean Build Folder (⇧⌘K)
```

#### Error: "Bundle ID mismatch"

**Lösung:**
- App ID in Developer Portal muss EXAKT mit Xcode Bundle ID übereinstimmen
- Case-sensitive!
- Keine Wildcards in Bundle ID

### Runtime Errors

#### Error: "Music User Token could not be obtained"

**Lösung:**
1. MusicKit Capability im Developer Portal aktiviert?
2. App ID hat MusicKit enabled?
3. Bundle ID stimmt überein?
4. App neu starten

#### Error: "Permission denied - AppleScript"

**Lösung:**
```
System Settings → Privacy & Security → Automation
→ StarTune → Music.app: ✓
```

#### Error: Icon erscheint nicht

**Lösung:**
```swift
// Check in StarTuneApp.swift:
@StateObject private var menuBarController = MenuBarController()
// NOT @State or @ObservedObject !
```

### Distribution Errors

#### Error: "App is damaged and can't be opened"

**Ursache:** Nicht notarisiert oder Gatekeeper blockiert

**Lösung:**
```bash
# User kann temporär umgehen mit:
xattr -cr /Applications/StarTune.app

# Oder: Proper Notarization durchführen
```

#### Error: "No Apple ID or password"

**Lösung:**
```bash
# App-specific Password erstellen
# appleid.apple.com → Security → App-Specific Passwords

# In Keychain speichern
xcrun notarytool store-credentials "AC_PASSWORD" \
  --apple-id "your-email@example.com" \
  --team-id "YOUR_TEAM_ID"
```

---

## Maintenance

### Updating Dependencies

```bash
# Update MusadoraKit
File → Packages → Update to Latest Package Versions

# Or specific version
File → Packages → Update Package "MusadoraKit"
```

### Version Bumping

```bash
# Update Version in Xcode
# Target → General → Version: 1.0.1
# Build: auto-increment

# Or via agvtool
xcrun agvtool new-marketing-version 1.1.0
xcrun agvtool next-version -all
```

### Changelog

Create `CHANGELOG.md`:
```markdown
# Changelog

## [1.1.0] - 2025-11-01
### Added
- Keyboard shortcut support
- Settings window

### Fixed
- Icon not updating in some cases
```

---

## CI/CD Setup (Advanced)

### GitHub Actions

`.github/workflows/build.yml`:
```yaml
name: Build and Test

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v3
      
      - name: Build
        run: |
          cd StarTune-Xcode/StarTune
          xcodebuild -project StarTune.xcodeproj \
                     -scheme StarTune \
                     -configuration Release \
                     build
      
      - name: Test
        run: |
          xcodebuild test \
                     -project StarTune.xcodeproj \
                     -scheme StarTune
```

---

**Last Updated:** 2025-10-27  
**Version:** 1.0.0  
**Maintainer:** Ben Kohler
