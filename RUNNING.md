# Running StarTune

Quick guide to build and run StarTune.

## ✅ Prerequisites

- macOS 14.0+ (Sonoma or newer)
- Xcode 15.0+
- Apple Developer Account (for MusicKit)
- Apple Music subscription (for testing)

---

## 🚀 Quick Start (Command Line)

### 1. Build the App

```bash
cd /Users/benkohler/Projekte/StarTune
swift build
```

### 2. Run the App

```bash
.build/debug/StarTune
```

The star icon should appear in your menu bar!

---

## 🔧 Development in Xcode

For a better development experience with GUI support:

### Option 1: Open in Xcode directly

```bash
cd /Users/benkohler/Projekte/StarTune
xed .
```

This opens the Swift Package in Xcode. You can then:
- Press **Cmd+R** to build and run
- Debug with breakpoints
- Use Instruments for profiling

### Option 2: Generate Xcode Project (Not recommended)

```bash
swift package generate-xcodeproj
open StarTune.xcodeproj
```

Note: Apple is deprecating this command. Use `xed .` instead.

---

## 🧪 Testing

### Manual Testing Steps

1. **Launch StarTune**
   ```bash
   swift run
   ```

2. **Check Menu Bar**
   - Look for the star icon in your menu bar
   - It should be gray (not playing)

3. **Play Music in Apple Music**
   - Open Apple Music app
   - Play any song
   - Star icon should turn gold ⭐️

4. **Click the Star**
   - Click the star icon in menu bar
   - Or: Click the star to open menu, then click "Add to Favorites"
   - Icon should briefly turn green (success)

5. **Verify in Apple Music**
   - Open Apple Music app
   - Go to Library → Songs → Loved (or Recently Played)
   - Your song should have a heart/star rating

---

## 🔐 Apple Developer Setup

Before the app works fully, you need:

### 1. Apple Developer Portal

1. Go to [developer.apple.com/account](https://developer.apple.com/account)
2. Certificates, Identifiers & Profiles
3. Create App ID with Bundle ID: `com.YOUR_NAME.startune`
4. Enable **MusicKit** capability
5. Configure **Automatic Token Generation**

### 2. First Run Authorization

On first launch, you'll see:
- macOS permission dialog for Apple Music access
- **Allow** the permission
- MusicKit authorization screen
- Sign in with your Apple ID

---

## 🐛 Troubleshooting

### Problem: "No such module 'MusadoraKit'"

**Solution:**
```bash
swift package resolve
swift build
```

### Problem: "App doesn't appear in menu bar"

**Check:**
- Is the app still running? (`ps aux | grep StarTune`)
- Did it crash? Check Console.app for errors
- Try running from command line to see output

### Problem: "Authorization failed"

**Solution:**
1. System Settings → Privacy & Security → Media & Apple Music
2. Enable StarTune (if it appears)
3. Or run: `tccutil reset MediaLibrary com.YOUR_NAME.startune`
4. Restart the app

### Problem: "Icon doesn't turn gold when music plays"

**Possible causes:**
- Apple Music (not Spotify!) must be playing
- Check Console.app for errors
- Verify macOS version is 14.0+

### Problem: "Failed to add to favorites"

**Check:**
- Do you have an Apple Music subscription?
- Is network connected?
- Check Console output for API errors

---

## 📊 Debug Output

Run with verbose logging:

```bash
swift run StarTune 2>&1 | tee startune.log
```

This will show:
- Authorization status
- Playback monitoring events
- API calls to Apple Music
- Errors and warnings

---

## 🏗️ Build Configurations

### Debug Build (Default)

```bash
swift build
```

- Fast compilation
- Debug symbols included
- No optimization
- Binary at: `.build/debug/StarTune`

### Release Build

```bash
swift build -c release
```

- Optimized for performance
- Smaller binary size
- Binary at: `.build/x86_64-apple-macosx/release/StarTune`

---

## 📦 Creating a Distributable App Bundle

Currently, `swift build` creates a command-line executable. For a proper macOS app:

### Future: Xcode Project

You'll need to:
1. Create proper Xcode project (not Swift Package)
2. Add Info.plist with `LSUIElement = true`
3. Code signing with Developer ID
4. Notarization for distribution

This is planned for v1.0.

---

## 🔄 Development Workflow

### Recommended Workflow

1. **Make code changes**
2. **Build:** `swift build`
3. **Kill old instance:** `killall StarTune` (if running)
4. **Run:** `swift run`
5. **Test** with Apple Music
6. **Check logs** in Terminal
7. **Repeat**

### Hot Reload?

SwiftUI previews don't work well for Menu Bar apps. Best practice:
- Quick iterations with `swift run`
- Use print statements for debugging
- Check Console.app for system-level errors

---

## 📝 Next Steps

After successfully running:

1. **Test all features:**
   - [ ] Menu bar icon appears
   - [ ] Icon changes color with playback
   - [ ] Click adds song to favorites
   - [ ] Success animation shows
   - [ ] Menu bar dropdown works
   - [ ] Quit button works

2. **Check Apple Music:**
   - [ ] Song has rating/loved status
   - [ ] Appears in "Loved" playlist

3. **Document issues:**
   - Check [GitHub Issues](https://github.com/bnjkhr/StarTune/issues)
   - Report any bugs you find

---

## 📞 Need Help?

- **GitHub:** [https://github.com/bnjkhr/StarTune](https://github.com/bnjkhr/StarTune)
- **Issues:** [github.com/bnjkhr/StarTune/issues](https://github.com/bnjkhr/StarTune/issues)
- **Docs:** See `README.md` and `SETUP.md`

---

**Happy Coding! 🎵⭐️**
