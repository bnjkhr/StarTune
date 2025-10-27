# StarTune Documentation

Willkommen zur vollständigen Dokumentation der StarTune macOS App!

---

## 📚 Documentation Overview

### Getting Started

**Neu hier?** Start here:
1. [README.md](../README.md) - Projekt-Übersicht & Quick Start
2. [SETUP_GUIDE.md](SETUP_GUIDE.md) - Detaillierte Setup-Anleitung
3. [API_DOCUMENTATION.md](API_DOCUMENTATION.md) - API Referenz

### For Developers

**Du willst am Projekt arbeiten?**
- [ARCHITECTURE.md](ARCHITECTURE.md) - Technische Architektur
- [CONTRIBUTING.md](../CONTRIBUTING.md) - Contribution Guidelines
- [API_DOCUMENTATION.md](API_DOCUMENTATION.md) - Alle Klassen & Methoden

### For Users

**Du willst die App nutzen?**
- [README.md](../README.md) - Installation & Features
- [TROUBLESHOOTING.md](#) (coming soon) - Häufige Probleme

---

## 📖 Document Details

### [README.md](../README.md)
**Zielgruppe:** Alle  
**Inhalt:**
- Feature-Übersicht
- Quick Start Guide
- Screenshots
- Roadmap
- Ressourcen

**Wann lesen?** Als erstes! Gibt dir einen kompletten Überblick.

---

### [SETUP_GUIDE.md](SETUP_GUIDE.md)
**Zielgruppe:** Entwickler & Advanced Users  
**Inhalt:**
- Development Setup (Step-by-Step)
- Apple Developer Portal Configuration
- Xcode Configuration
- Build für Distribution
- App Store Submission
- Direct Distribution

**Wann lesen?** Wenn du die App builden oder deployen willst.

**Key Sections:**
- [Development Setup](SETUP_GUIDE.md#development-setup) - Erste Schritte
- [Apple Developer Portal](SETUP_GUIDE.md#apple-developer-portal-configuration) - MusicKit Setup
- [Build for Distribution](SETUP_GUIDE.md#build-for-distribution) - Release erstellen
- [Troubleshooting](SETUP_GUIDE.md#troubleshooting) - Häufige Probleme lösen

---

### [API_DOCUMENTATION.md](API_DOCUMENTATION.md)
**Zielgruppe:** Entwickler  
**Inhalt:**
- Komplette API-Referenz aller Klassen
- Properties, Methods, Protocols
- Code-Beispiele
- Use Cases
- Error Handling

**Wann lesen?** Wenn du verstehen willst wie eine spezifische Klasse funktioniert.

**Key Sections:**
- [MusicKitManager](API_DOCUMENTATION.md#musickitmanager) - Authorization & Subscription
- [PlaybackMonitor](API_DOCUMENTATION.md#playbackmonitor) - Song Detection
- [FavoritesService](API_DOCUMENTATION.md#favoritesservice) - Favorites API
- [MenuBarController](API_DOCUMENTATION.md#menubarcontroller) - Menu Bar Integration

---

### [ARCHITECTURE.md](ARCHITECTURE.md)
**Zielgruppe:** Entwickler (Advanced)  
**Inhalt:**
- Architektur-Pattern (MVVM)
- Layer Architecture
- Component Diagrams
- Data Flow
- Threading Model
- Design Decisions

**Wann lesen?** Wenn du verstehen willst WARUM etwas so gebaut ist wie es ist.

**Key Sections:**
- [Architecture Pattern](ARCHITECTURE.md#architecture-pattern) - MVVM Erklärung
- [Component Diagrams](ARCHITECTURE.md#component-diagrams) - Visuelle Übersicht
- [Data Flow](ARCHITECTURE.md#data-flow) - State Management
- [Design Decisions](ARCHITECTURE.md#design-decisions) - Warum nicht anders?

---

### [CONTRIBUTING.md](../CONTRIBUTING.md)
**Zielgruppe:** Contributors  
**Inhalt:**
- Code Style Guidelines
- Commit Message Format
- Pull Request Process
- Testing Requirements
- Development Setup

**Wann lesen?** Bevor du einen Pull Request erstellst!

**Key Sections:**
- [Development Guidelines](../CONTRIBUTING.md#development-guidelines)
- [Pull Request Process](../CONTRIBUTING.md#pull-request-process)
- [Testing](../CONTRIBUTING.md#testing)

---

## 🗺️ Documentation Map

```
StarTune Documentation
│
├── Getting Started
│   ├── README.md ..................... Start here!
│   └── SETUP_GUIDE.md ................ Build & Deploy
│
├── Development
│   ├── API_DOCUMENTATION.md .......... Class Reference
│   ├── ARCHITECTURE.md ............... Technical Design
│   └── CONTRIBUTING.md ............... How to Contribute
│
└── Advanced
    ├── Performance Tuning ............ (coming soon)
    ├── Testing Guide ................. (coming soon)
    └── Deployment Strategies ......... (in SETUP_GUIDE)
```

---

## 🎯 Quick Links

### By Role

**👨‍💻 Developer (First Time):**
1. [README.md](../README.md) - Overview
2. [SETUP_GUIDE.md](SETUP_GUIDE.md) - Development Setup
3. [ARCHITECTURE.md](ARCHITECTURE.md) - How it works
4. [API_DOCUMENTATION.md](API_DOCUMENTATION.md) - Class details

**🔧 Contributor:**
1. [CONTRIBUTING.md](../CONTRIBUTING.md) - Guidelines
2. [ARCHITECTURE.md](ARCHITECTURE.md) - Design
3. [API_DOCUMENTATION.md](API_DOCUMENTATION.md) - API Reference

**📦 Deployer:**
1. [SETUP_GUIDE.md](SETUP_GUIDE.md) - Build & Deploy
2. [SETUP_GUIDE.md#troubleshooting](SETUP_GUIDE.md#troubleshooting) - Common Issues

**👤 End User:**
1. [README.md](../README.md) - What is StarTune?
2. [README.md#installation](../README.md#installation) - How to install

---

## 📝 By Topic

### Authorization & Setup
- [MusicKit Authorization](API_DOCUMENTATION.md#musickitmanager)
- [Apple Developer Portal Setup](SETUP_GUIDE.md#apple-developer-portal-configuration)
- [Permissions & Entitlements](SETUP_GUIDE.md#permissions--entitlements)

### Playback Detection
- [PlaybackMonitor Architecture](ARCHITECTURE.md#playbackmonitor)
- [AppleScript Bridge](API_DOCUMENTATION.md#musicappbridge)
- [Song Detection Flow](ARCHITECTURE.md#playback-monitoring-flow)

### Favorites
- [FavoritesService API](API_DOCUMENTATION.md#favoritesservice)
- [MusadoraKit Integration](ARCHITECTURE.md#why-musadorakit)
- [Favorites Flow Diagram](ARCHITECTURE.md#favorites-flow)

### Menu Bar Integration
- [MenuBarController](API_DOCUMENTATION.md#menubarcontroller)
- [NSStatusItem Management](ARCHITECTURE.md#presentation-layer)
- [Icon Updates & Animations](API_DOCUMENTATION.md#menubarcontroller-methods)

### Testing & Debugging
- [Local Testing](SETUP_GUIDE.md#local-testing)
- [Troubleshooting](SETUP_GUIDE.md#troubleshooting)
- [Console Logging](API_DOCUMENTATION.md#error-handling)

### Distribution
- [Build for Distribution](SETUP_GUIDE.md#build-for-distribution)
- [App Store Submission](SETUP_GUIDE.md#app-store-submission)
- [Direct Distribution](SETUP_GUIDE.md#direct-distribution)

---

## 🔍 Search by Keyword

| Keyword | Document | Section |
|---------|----------|---------|
| **Authorization** | API_DOCUMENTATION.md | [MusicKitManager](#) |
| **AppleScript** | ARCHITECTURE.md | [Why AppleScript Bridge](#) |
| **Build** | SETUP_GUIDE.md | [Build for Distribution](#) |
| **Code Style** | CONTRIBUTING.md | [Development Guidelines](#) |
| **Data Flow** | ARCHITECTURE.md | [Data Flow](#) |
| **Dependencies** | README.md | [Technology Stack](#) |
| **Deployment** | SETUP_GUIDE.md | [Deployment](#) |
| **Error Handling** | API_DOCUMENTATION.md | [Error Handling](#) |
| **Favorites** | API_DOCUMENTATION.md | [FavoritesService](#) |
| **Menu Bar** | API_DOCUMENTATION.md | [MenuBarController](#) |
| **MVVM** | ARCHITECTURE.md | [Architecture Pattern](#) |
| **Notifications** | API_DOCUMENTATION.md | [Notification System](#) |
| **Performance** | ARCHITECTURE.md | [Performance Considerations](#) |
| **Playback** | API_DOCUMENTATION.md | [PlaybackMonitor](#) |
| **Security** | ARCHITECTURE.md | [Security Architecture](#) |
| **Setup** | SETUP_GUIDE.md | [Development Setup](#) |
| **State Management** | ARCHITECTURE.md | [State Management](#) |
| **Testing** | CONTRIBUTING.md | [Testing](#) |
| **Threading** | ARCHITECTURE.md | [Threading Model](#) |
| **Troubleshooting** | SETUP_GUIDE.md | [Troubleshooting](#) |

---

## 📊 Document Statistics

| Document | Words | Reading Time | Last Updated |
|----------|-------|--------------|--------------|
| README.md | ~3500 | 15 min | 2025-10-27 |
| SETUP_GUIDE.md | ~4500 | 20 min | 2025-10-27 |
| API_DOCUMENTATION.md | ~6000 | 25 min | 2025-10-27 |
| ARCHITECTURE.md | ~5500 | 25 min | 2025-10-27 |
| CONTRIBUTING.md | ~2500 | 10 min | 2025-10-27 |
| **Total** | **~22000** | **~95 min** | |

---

## ✏️ Contributing to Docs

Dokumentation falsch oder veraltet? Wir freuen uns über Verbesserungen!

**How to contribute:**
1. Edit Markdown files directly
2. Follow existing structure
3. Add examples where helpful
4. Update this index if needed
5. Submit PR with label "documentation"

**Style Guide:**
- Use headlines (#, ##, ###)
- Add code blocks with syntax highlighting
- Include diagrams where complex
- Link between documents
- Keep sentences short

---

## 🆘 Need Help?

**Dokumentation unklar?**
- Open an issue with label "documentation"
- Describe what's unclear
- Suggest improvements

**Fehlt etwas?**
- Request new documentation
- We'll prioritize based on demand

---

## 📅 Maintenance Schedule

**Review:** Every 3 months  
**Updates:** With every major release  
**Deprecation Notices:** 6 months in advance

---

## 🏆 Documentation Credits

**Written by:** Ben Kohler  
**Review by:** Community  
**Tools:** Markdown, ASCII Diagrams  
**Inspiration:** Stripe API Docs, Apple Developer Docs

---

**Last Updated:** 2025-10-27  
**Version:** 1.0.0

---

<div align="center">

**Questions? [Open an Issue](https://github.com/yourusername/startune/issues)**

Made with 📝 and ☕️

</div>
