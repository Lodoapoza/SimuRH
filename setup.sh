#!/bin/bash
set -e

echo "========================================"
echo "  SimuRH - Installation et Build"
echo "========================================"
echo ""

# Vérifier que le dossier app existe
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/app"

if [ ! -d "$APP_DIR" ]; then
    echo "❌ Dossier app/ introuvable dans $SCRIPT_DIR"
    echo "   Assurez-vous d'exécuter ce script depuis la racine du projet SimuRH"
    exit 1
fi

# Vérifier Flutter
if ! command -v flutter &> /dev/null; then
    echo "🔍 Flutter SDK non trouvé"
    echo ""
    echo "   Installation via Homebrew..."
    if command -v brew &> /dev/null; then
        echo "   → brew install flutter"
        brew install flutter
        echo "✅ Flutter installé via Homebrew"
    else
        echo ""
        echo "⚠️  Homebrew non disponible."
        echo ""
        echo "   Pour installer Flutter manuellement :"
        echo "   1. Rendez-vous sur https://docs.flutter.dev/get-started/install/macos"
        echo "   2. Téléchargez le SDK pour macOS ARM64"
        echo "   3. Extrayez l'archive dans ~/development/"
        echo "   4. Ajoutez à votre ~/.zshrc : export PATH=\$PATH:\$HOME/development/flutter/bin"
        echo "   5. Rechargez : source ~/.zshrc"
        echo ""
        echo "   Après installation, relancez ce script."
        exit 1
    fi
else
    echo "✅ Flutter SDK trouvé : $(flutter --version 2>&1 | head -1)"
fi

echo ""
echo "📦 Installation des dépendances Dart..."
cd "$APP_DIR"
flutter pub get
echo "✅ Dépendances installées"

echo ""
echo "🔨 Build de l'APK (debug)..."
flutter build apk --debug
echo "✅ Build terminé"

# Afficher le chemin de l'APK
APK_PATH="$APP_DIR/build/app/outputs/flutter-apk/app-debug.apk"
if [ -f "$APK_PATH" ]; then
    echo ""
    echo "📱 APK généré : $APK_PATH"
    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
    echo "   Taille : $APK_SIZE"
    echo ""
    echo "   Transférez cet APK sur votre téléphone Android pour l'installer."
else
    echo "⚠️  APK non trouvé. Vérifiez les logs ci-dessus."
fi

echo ""
echo "========================================"
echo "  ✅ Terminé"
echo "========================================"
