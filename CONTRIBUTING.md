# Contributing to StarTune

Danke für dein Interesse an StarTune! Dieses Dokument beschreibt wie du zum Projekt beitragen kannst.

---

## Code of Conduct

Wir erwarten von allen Contributors respektvolles und konstruktives Verhalten. Bitte lies unseren [Code of Conduct](CODE_OF_CONDUCT.md) (coming soon).

---

## Wie kann ich beitragen?

### 1. Bug Reports

Wenn du einen Bug findest:

1. Prüfe ob der Bug bereits als [Issue](https://github.com/yourusername/startune/issues) existiert
2. Wenn nicht, erstelle ein neues Issue mit:
   - **Beschreibung**: Was ist passiert?
   - **Erwartetes Verhalten**: Was sollte passieren?
   - **Schritte zum Reproduzieren**: Wie kann man den Bug nachstellen?
   - **System Info**: macOS Version, Xcode Version, App Version
   - **Console Logs**: Relevante Logs aus Console.app
   - **Screenshots**: Falls hilfreich

**Template:**
```markdown
**Bug Beschreibung**
Icon wird nicht gold wenn Song spielt

**Erwartetes Verhalten**
Icon sollte gold sein während Musik läuft

**Schritte zum Reproduzieren**
1. Apple Music öffnen
2. Song abspielen
3. Icon bleibt grau

**System**
- macOS: 14.1
- Xcode: 15.0
- StarTune: 1.0.0

**Logs**
```
🎵 Starting playback monitoring...
⚠️ No song found for: Unknown Track
```
```

### 2. Feature Requests

Ideen für neue Features sind willkommen!

1. Öffne ein Issue mit Label "enhancement"
2. Beschreibe:
   - **Problem**: Welches Problem löst das Feature?
   - **Lösung**: Wie soll es funktionieren?
   - **Alternativen**: Andere Lösungsansätze?
   - **Use Case**: Wer profitiert davon?

### 3. Pull Requests

**Workflow:**

1. **Fork** das Repository
2. **Clone** deinen Fork
   ```bash
   git clone https://github.com/YOURNAME/startune.git
   cd startune
   ```
3. **Branch** erstellen
   ```bash
   git checkout -b feature/amazing-feature
   ```
4. **Changes** committen
   ```bash
   git commit -m "feat: add amazing feature"
   ```
5. **Push** zum Fork
   ```bash
   git push origin feature/amazing-feature
   ```
6. **Pull Request** öffnen

---

## Development Guidelines

### Code Style

**Swift Style Guide:**
- Follow [Swift.org API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use SwiftLint (configuration coming soon)
- 4 spaces (no tabs)
- Max line length: 120 characters

**Naming Conventions:**
```swift
// Classes/Structs: PascalCase
class MusicKitManager { }

// Variables/Functions: camelCase
var currentSong: Song?
func updatePlaybackState() { }

// Constants: camelCase
let maxRetryCount = 3

// Enums: PascalCase
enum PlaybackStatus { }
```

**Comments:**
```swift
// MARK: - Section Title (mit Trennlinie)
// MARK: Subsection (ohne Trennlinie)

/// Documentation comment für public APIs
/// - Parameter song: The song to favorite
/// - Returns: true if successful
func addToFavorites(song: Song) async throws -> Bool
```

### Commit Messages

**Conventional Commits Format:**
```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types:**
- `feat:` Neues Feature
- `fix:` Bug Fix
- `docs:` Dokumentation
- `refactor:` Code Refactoring
- `test:` Tests hinzufügen/ändern
- `chore:` Build/Config Changes
- `style:` Code Formatting (kein Logic Change)
- `perf:` Performance Verbesserung

**Beispiele:**
```
feat(playback): add keyboard shortcut support

Add global keyboard shortcut (Cmd+Shift+F) to favorite current song.
Includes Settings UI to enable/disable shortcut.

Closes #42
```

```
fix(auth): handle authorization denial correctly

Previously app would crash when user denied authorization.
Now shows proper error message and retry button.

Fixes #38
```

### Architecture

- Follow MVVM pattern
- Use `@MainActor` für UI-relevante Klassen
- Prefer Async/Await over callbacks
- Use `@Published` für reactive state
- Keep Views thin (no business logic)

**Example:**
```swift
// ❌ Bad: Business logic in View
struct MyView: View {
    var body: some View {
        Button("Favorite") {
            Task {
                // Complex API logic here...
            }
        }
    }
}

// ✅ Good: Delegate to Manager
struct MyView: View {
    @ObservedObject var manager: MusicKitManager
    
    var body: some View {
        Button("Favorite") {
            Task {
                await manager.addToFavorites()
            }
        }
    }
}
```

### Testing

**Test Requirements:**
- [ ] All new features must have tests
- [ ] Bug fixes must have regression tests
- [ ] Test coverage should increase (not decrease)

**Test Structure:**
```swift
class MusicKitManagerTests: XCTestCase {
    var sut: MusicKitManager!
    
    override func setUp() {
        super.setUp()
        sut = MusicKitManager()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testAuthorizationSuccess() async {
        // Given
        // When
        await sut.requestAuthorization()
        // Then
        XCTAssertTrue(sut.isAuthorized)
    }
}
```

### Documentation

**Required Documentation:**
- [ ] Public APIs need doc comments
- [ ] Complex logic needs inline comments
- [ ] Architecture changes need docs/ARCHITECTURE.md update
- [ ] New features need README.md update

**Doc Comment Template:**
```swift
/// Short one-line description
///
/// Longer description explaining what the function does,
/// when to use it, and any important details.
///
/// - Parameters:
///   - song: The song to add to favorites
///   - notify: Whether to show notification (default: true)
/// - Returns: true if the operation succeeded
/// - Throws: `FavoritesError` if authorization fails or network error
///
/// # Example
/// ```swift
/// let success = try await addToFavorites(song: song)
/// if success {
///     print("Added!")
/// }
/// ```
func addToFavorites(song: Song, notify: Bool = true) async throws -> Bool
```

---

## Pull Request Process

### Before Submitting

**Checklist:**
- [ ] Code follows style guidelines
- [ ] Self-review of code done
- [ ] Comments added for complex parts
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No warnings in Xcode
- [ ] App builds and runs successfully
- [ ] Manual testing completed

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix (non-breaking change)
- [ ] New feature (non-breaking change)
- [ ] Breaking change (fix or feature that breaks existing functionality)
- [ ] Documentation update

## Testing
- [ ] Tested on macOS 14.0
- [ ] Tested on macOS 15.0 (if available)
- [ ] Unit tests pass
- [ ] Manual testing completed

## Screenshots (if applicable)
Add screenshots here

## Related Issues
Closes #123
```

### Review Process

1. **Automated Checks**: CI must pass (once configured)
2. **Code Review**: At least 1 approval required
3. **Testing**: Reviewer tests changes locally
4. **Merge**: Squash and merge to main

---

## Development Setup

### Prerequisites
- macOS 14.0+
- Xcode 15.0+
- Apple Developer Account
- Apple Music Subscription

### Setup Steps

1. **Fork & Clone**
   ```bash
   git clone https://github.com/YOURNAME/startune.git
   cd startune/StarTune-Xcode/StarTune
   ```

2. **Open in Xcode**
   ```bash
   open StarTune.xcodeproj
   ```

3. **Configure Signing**
   - Target → Signing & Capabilities
   - Team: Your Team
   - Bundle ID: com.yourname.startune

4. **Build & Run**
   ```
   ⌘B → Build
   ⌘R → Run
   ```

5. **Verify**
   - Icon appears in Menu Bar
   - Authorization works
   - Song detection works

---

## Areas Looking for Help

### High Priority
- [ ] Unit test coverage
- [ ] Keyboard shortcut support
- [ ] Settings window
- [ ] Notification support

### Medium Priority
- [ ] Lyrics display
- [ ] Song history
- [ ] Custom playlists
- [ ] Statistics/Analytics

### Low Priority
- [ ] Widget support
- [ ] Shortcuts integration
- [ ] Localization (DE, EN)
- [ ] Dark icon variant

---

## Communication

### GitHub Issues
- Bug Reports: Use "bug" label
- Feature Requests: Use "enhancement" label
- Questions: Use "question" label

### Discussion Topics
- Architecture decisions
- Feature proposals
- Best practices

---

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (MIT).

---

## Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Mentioned in release notes
- Thanked in README.md

---

## Questions?

Feel free to:
- Open an issue with label "question"
- Contact maintainer: mail@benkohler.de

---

Thank you for contributing to StarTune! 🎵⭐️
