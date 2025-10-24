#!/bin/bash

echo "🚀 Creating Xcode project for StarTune..."

# Projekt-Name und Bundle ID
PROJECT_NAME="StarTune"
BUNDLE_ID="com.benkohler.StarTune"

cd "$(dirname "$0")"

# Erstelle Xcode Projekt-Struktur
mkdir -p "${PROJECT_NAME}.xcodeproj"

echo "✅ Xcode project structure created"
echo ""
echo "⚠️  WICHTIG: Du musst das Projekt in Xcode öffnen und manuell konfigurieren:"
echo ""
echo "1. Öffne Xcode"
echo "2. File → New → Project"
echo "3. macOS → App"
echo "4. Projekt-Einstellungen:"
echo "   - Product Name: StarTune"
echo "   - Team: Dein Apple Developer Team"
echo "   - Organization Identifier: com.benkohler"
echo "   - Bundle Identifier: com.benkohler.StarTune"
echo "   - Interface: SwiftUI"
echo "   - Language: Swift"
echo ""
echo "5. Speicherort: $(pwd)/XcodeProject"
echo ""
echo "6. Dann:"
echo "   - Lösche die auto-generierten Dateien"
echo "   - Füge alle Dateien aus Sources/StarTune/ hinzu"
echo "   - Signing & Capabilities → MusicKit hinzufügen"
echo "   - Info.plist → LSUIElement = YES"
echo ""
echo "Alternativ: Ich kann das Setup-Script erweitern..."
