# StarTune Documentation

Welcome to the StarTune documentation! This directory contains comprehensive documentation for the StarTune macOS application, including API documentation, architecture decisions, and usage examples.

## 📚 Documentation Structure

```
Documentation/
├── README.md                    # This file
├── ADRs/                       # Architecture Decision Records
│   ├── 001-applescript-bridge-for-playback-detection.md
│   ├── 002-musadorakit-wrapper-for-favorites.md
│   ├── 003-2-second-polling-interval.md
│   └── 004-mvvm-architecture-with-swiftui.md
└── Examples/
    └── API-USAGE.md            # Comprehensive API usage examples
```

## 🎯 Quick Start

### For New Developers

1. **Start here**: Read this README to understand the documentation structure
2. **Architecture**: Review [ADR-004 (MVVM Architecture)](ADRs/004-mvvm-architecture-with-swiftui.md)
3. **API Examples**: Check [API Usage Examples](Examples/API-USAGE.md)
4. **Code Documentation**: Read SwiftDocC comments in the source files

### For Contributors

1. **Adding Features**: Review relevant ADRs to understand design decisions
2. **API Reference**: Use SwiftDocC comments in source files
3. **Examples**: Refer to [API-USAGE.md](Examples/API-USAGE.md) for patterns
4. **Testing**: See testing patterns in the examples

### For Maintainers

1. **Design Decisions**: Review and update ADRs when architecture changes
2. **API Documentation**: Keep SwiftDocC comments up to date
3. **Examples**: Add examples for new APIs
4. **Onboarding**: Use this documentation to onboard new team members

## 📖 Documentation Types

### 1. SwiftDocC Comments (In Source Code)

**Location:** Inline in `.swift` files

**Purpose:** Detailed API documentation for all public types, methods, and properties

**Example:**
```swift
/// Manages MusicKit authorization and Apple Music subscription status.
///
/// ## Overview
/// MusicKit requires two prerequisites...
///
/// - SeeAlso: ``FavoritesService``
@MainActor
class MusicKitManager: ObservableObject {
    // ...
}
```

**Key Features:**
- Rich markdown formatting
- Code examples
- Cross-references between types
- Compilable (checked by Swift compiler)

**Viewing:** Can be built into HTML documentation using Xcode's Documentation Compiler

### 2. Architecture Decision Records (ADRs)

**Location:** `Documentation/ADRs/`

**Purpose:** Record important architectural decisions, their rationale, and trade-offs

**Format:** Markdown files following the ADR template

**Current ADRs:**

| ADR | Title | Status |
|-----|-------|--------|
| [001](ADRs/001-applescript-bridge-for-playback-detection.md) | AppleScript Bridge for Playback Detection | ✅ Accepted |
| [002](ADRs/002-musadorakit-wrapper-for-favorites.md) | MusadoraKit Wrapper for Favorites API | ✅ Accepted |
| [003](ADRs/003-2-second-polling-interval.md) | 2-Second Polling Interval | ✅ Accepted |
| [004](ADRs/004-mvvm-architecture-with-swiftui.md) | MVVM Architecture with SwiftUI | ✅ Accepted |

**When to Create an ADR:**
- Introducing new architecture patterns
- Choosing between technology options
- Making decisions with long-term implications
- Explaining non-obvious design choices

### 3. API Usage Examples

**Location:** `Documentation/Examples/API-USAGE.md`

**Purpose:** Practical examples of using StarTune's internal APIs

**Includes:**
- Getting started examples
- Authorization flows
- Playback monitoring patterns
- Error handling strategies
- Complete integration examples
- Testing patterns
- Best practices

**Use Cases:**
- Learning how to use the APIs
- Copy-paste patterns for common tasks
- Understanding component interactions
- Writing tests

## 🏗️ Architecture Overview

StarTune follows the **MVVM (Model-View-ViewModel)** architecture pattern with **Dependency Injection**. See [ADR-004](ADRs/004-mvvm-architecture-with-swiftui.md) for detailed rationale.

### Component Layers

```
┌─────────────────────────────────────┐
│          View Layer                 │
│  StarTuneApp, MenuBarView           │
└─────────────┬───────────────────────┘
              │ @ObservedObject
              ↓
┌─────────────────────────────────────┐
│     ViewModel/Manager Layer         │
│  MusicKitManager, PlaybackMonitor   │
│  FavoritesService, AppSettings      │
└─────────────┬───────────────────────┘
              │
              ↓
┌─────────────────────────────────────┐
│         Model Layer                 │
│  PlaybackState, Song (MusicKit)     │
└─────────────────────────────────────┘
```

### Key Components

| Component | Type | Responsibility |
|-----------|------|---------------|
| **StarTuneApp** | App | Composition root, lifecycle |
| **MusicKitManager** | Manager | Authorization & subscription |
| **PlaybackMonitor** | Manager | Playback state tracking |
| **MusicAppBridge** | Service | AppleScript communication |
| **FavoritesService** | Service | Add/remove favorites |
| **MenuBarView** | View | Menu bar UI |

## 🔑 Key Concepts

### 1. AppleScript Bridge

**Why:** MusicKit's `MusicPlayer.shared` doesn't work reliably in menu bar apps

**How:** Use AppleScript via `NSAppleScript` to query Music.app

**Details:** [ADR-001](ADRs/001-applescript-bridge-for-playback-detection.md)

**Example:**
```swift
let bridge = MusicAppBridge()
bridge.updatePlaybackState()

if bridge.isPlaying {
    print("Now playing: \(bridge.currentTrackInfo ?? "")")
}
```

### 2. Two-Layer Playback Detection

**Layer 1:** Fast AppleScript queries (20-50ms)
- Gets track name, artist, playing state
- Reliable, works in menu bar context

**Layer 2:** MusicKit catalog search (100-500ms)
- Gets full Song object with metadata
- Required for favorites functionality

**Polling Interval:** 2 seconds (see [ADR-003](ADRs/003-2-second-polling-interval.md))

### 3. MusadoraKit Wrapper

**Why:** Native MusicKit ratings API is complex and requires manual networking

**Library:** MusadoraKit (community wrapper)

**Usage:**
```swift
let service = FavoritesService()
try await service.addToFavorites(song: song)
```

**Details:** [ADR-002](ADRs/002-musadorakit-wrapper-for-favorites.md)

### 4. Dependency Injection

**Pattern:** Create managers once in `StarTuneApp`, inject into views

**Example:**
```swift
@main
struct StarTuneApp: App {
    @StateObject private var musicKitManager = MusicKitManager()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(musicKitManager: musicKitManager)  // ← Inject
        }
    }
}
```

**Benefits:** Testable, clear ownership, no singletons

## 📝 Documentation Guidelines

### Writing SwiftDocC Comments

**Structure:**
```swift
/// Brief one-line summary.
///
/// Detailed description explaining what this does, when to use it,
/// and any important context.
///
/// ## Section Title
/// Additional organized content using markdown headers.
///
/// - Parameter paramName: Description
/// - Returns: Description
/// - Throws: ErrorType if condition
///
/// ## Example
/// ```swift
/// let manager = MusicKitManager()
/// await manager.requestAuthorization()
/// ```
///
/// - SeeAlso: ``RelatedType``
class MyClass { }
```

**Best Practices:**
- Start with a one-line summary (appears in quick help)
- Provide context: why this exists, when to use it
- Include code examples for non-trivial APIs
- Cross-reference related types
- Document edge cases and limitations
- Explain async/thread safety requirements

### Writing ADRs

**Template:**
```markdown
# ADR-XXX: Title

**Status:** Proposed | Accepted | Deprecated | Superseded

**Date:** YYYY-MM-DD

## Context
Background and problem statement

## Decision
What was decided

## Rationale
Why this decision was made

## Consequences
Positive, negative, and neutral impacts

## Alternatives Considered
Other options and why they were rejected
```

**Guidelines:**
- Record decisions, not implementations
- Explain the "why", not just the "what"
- Include trade-offs and consequences
- Date stamp and maintain status
- Link to related ADRs

### Writing Examples

**Structure:**
- Clear, self-contained examples
- Progressive complexity (basic → advanced)
- Include error handling
- Show complete integration
- Provide context and explanation

**Example Format:**
```markdown
### Example X: Title

Brief description of what this example demonstrates.

```swift
// Complete, runnable code example
```

**Key Points:**
- Point 1
- Point 2
```

## 🔄 Maintaining Documentation

### When Source Code Changes

1. **Update SwiftDocC comments** in changed files
2. **Add examples** for new APIs
3. **Update ADRs** if architecture changes
4. **Review related documentation** for accuracy

### Regular Maintenance

- **Quarterly:** Review ADRs for relevance
- **Per Release:** Update examples with new features
- **On Request:** Add examples for commonly asked questions

### Adding New ADRs

1. Use next sequential number (ADR-005, etc.)
2. Follow the ADR template
3. Link from this README
4. Update table of contents

## 🎓 Learning Resources

### For Understanding the Codebase

1. [MVVM Architecture ADR](ADRs/004-mvvm-architecture-with-swiftui.md)
2. [API Usage Examples](Examples/API-USAGE.md)
3. SwiftDocC comments in source files
4. [AppleScript Bridge ADR](ADRs/001-applescript-bridge-for-playback-detection.md)

### External Resources

- [MusicKit Documentation](https://developer.apple.com/documentation/musickit)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [MusadoraKit GitHub](https://github.com/rryam/MusadoraKit)
- [NSAppleScript Documentation](https://developer.apple.com/documentation/foundation/nsapplescript)

## 🤝 Contributing to Documentation

### Documentation Standards

- ✅ **Clear and concise**: Avoid jargon, explain acronyms
- ✅ **Complete**: Include all necessary context
- ✅ **Accurate**: Keep in sync with code
- ✅ **Examples**: Show, don't just tell
- ✅ **Formatted**: Use proper markdown and code blocks

### Pull Request Checklist

When submitting code changes:

- [ ] Updated SwiftDocC comments for changed APIs
- [ ] Added/updated examples if needed
- [ ] Updated or created ADR for architectural changes
- [ ] Reviewed related documentation for accuracy
- [ ] Tested that code examples compile

## 📊 Documentation Coverage

### Current Status

| Component | SwiftDocC | Examples | ADR |
|-----------|-----------|----------|-----|
| **MusicKitManager** | ✅ Complete | ✅ Multiple | ✅ ADR-002 |
| **PlaybackMonitor** | ✅ Complete | ✅ Multiple | ✅ ADR-001, 003 |
| **MusicAppBridge** | ✅ Complete | ✅ Multiple | ✅ ADR-001 |
| **FavoritesService** | ✅ Complete | ✅ Multiple | ✅ ADR-002 |
| **StarTuneApp** | ✅ Complete | ✅ Multiple | ✅ ADR-004 |
| **MenuBarView** | ⚠️ Partial | ✅ Complete | N/A |
| **MenuBarController** | ⚠️ Partial | ⚠️ Limited | N/A |
| **PlaybackState** | ✅ Complete | ⚠️ Limited | N/A |
| **AppSettings** | ✅ Complete | ⚠️ Limited | N/A |

**Legend:**
- ✅ Complete: Comprehensive documentation
- ⚠️ Partial: Basic documentation, could be expanded
- ❌ Missing: No documentation

## 📞 Getting Help

### Documentation Issues

- **Unclear documentation**: [Open an issue](https://github.com/bnjkhr/StarTune/issues)
- **Missing examples**: Request in issues
- **Outdated information**: Submit a correction PR

### Code Questions

- Review SwiftDocC comments in source
- Check [API Usage Examples](Examples/API-USAGE.md)
- Read relevant ADRs
- Ask in issues or discussions

## 📜 License

This documentation is part of the StarTune project and is covered under the project's license.

---

**Last Updated:** 2025-10-24

**Maintained By:** StarTune Development Team

**Documentation Version:** 1.0.0
