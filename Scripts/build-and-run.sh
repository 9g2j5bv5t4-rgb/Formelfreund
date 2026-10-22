#!/bin/sh
# Baut Formelfreund aus dem Quelltext, installiert die App und startet sie.
# Nur nötig, wenn du selbst am Code arbeitest – zum Ausprobieren genügt install.sh.
#
#   ./Scripts/build-and-run.sh          # bauen, testen, installieren, starten
#   ./Scripts/build-and-run.sh --fast   # ohne die Tests der Logik

set -eu
cd "$(dirname "$0")/.."

say() { printf '\n▸ %s\n' "$*"; }
fail() { printf 'Fehler: %s\n' "$*" >&2; exit 1; }

# Xcode vorhanden? (Die „Command Line Tools“ allein reichen für eine Mac-App nicht.)
if ! xcode-select -p >/dev/null 2>&1 || xcode-select -p | grep -q CommandLineTools; then
    fail "Xcode fehlt. Installiere Xcode aus dem App Store, starte es einmal und führe dann aus:
  sudo xcode-select -s /Applications/Xcode.app"
fi

if [ "${1:-}" != "--fast" ]; then
    say "Teste die Logik (LaTeXKit) …"
    swift test --package-path Packages/LaTeXKit --quiet || fail "Die Tests sind fehlgeschlagen (siehe oben)."
fi

say "Baue die App (das erste Mal dauert etwa eine Minute) …"
LOG="build/xcodebuild.log"
mkdir -p build
if ! xcodebuild \
        -project Formelfreund.xcodeproj \
        -scheme Formelfreund \
        -configuration Release \
        -destination 'platform=macOS,arch=arm64' \
        -derivedDataPath build \
        build >"$LOG" 2>&1; then
    grep -E "error:" "$LOG" | head -n 20 || true
    fail "Bauen fehlgeschlagen. Vollständiges Protokoll: $LOG"
fi

say "Installiere und starte …"
sh Scripts/install.sh build/Build/Products/Release/Formelfreund.app
