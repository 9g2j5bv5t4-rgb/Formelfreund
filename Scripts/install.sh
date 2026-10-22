#!/bin/sh
# Installiert Formelfreund auf diesem Mac – ohne Xcode.
#
# Neueste Version von GitHub laden und installieren:
#   curl -fsSL https://github.com/<besitzer>/<repo>/releases/download/latest/install.sh | sh
#
# Eine bereits heruntergeladene App oder ZIP-Datei installieren:
#   sh install.sh ~/Downloads/Formelfreund.zip
#   sh install.sh build/Build/Products/Release/Formelfreund.app
#
# Was das Skript macht:
#   1. Prüft, ob der Mac passt (Apple Silicon, macOS 26 oder neuer).
#   2. Lädt die neueste Version von GitHub (falls keine Datei angegeben ist).
#   3. Beendet eine laufende Formelfreund-App und ersetzt sie.
#   4. Kopiert die App nach /Programme (oder ~/Programme, falls nötig) und startet sie.

set -eu

# Wird beim Veröffentlichen automatisch durch "besitzer/repo" ersetzt.
REPO="${FORMELFREUND_REPO:-__GITHUB_REPOSITORY__}"
APP_NAME="Formelfreund.app"

say() { printf '%s\n' "$*"; }
fail() { printf 'Fehler: %s\n' "$*" >&2; exit 1; }

# --- 1. Passt der Mac? -------------------------------------------------------

[ "$(uname -s)" = "Darwin" ] || fail "Dieses Skript läuft nur auf einem Mac."
[ "$(uname -m)" = "arm64" ] || fail "Formelfreund braucht einen Mac mit Apple-Chip (M1 oder neuer)."
MACOS_MAJOR=$(sw_vers -productVersion | cut -d. -f1)
[ "$MACOS_MAJOR" -ge 26 ] || fail "Formelfreund braucht macOS 26 oder neuer (installiert: $(sw_vers -productVersion))."

WORK_DIR=$(mktemp -d -t formelfreund)
trap 'rm -rf "$WORK_DIR"' EXIT

# --- 2. App besorgen ---------------------------------------------------------

SOURCE="${1:-}"
if [ -z "$SOURCE" ]; then
    case "$REPO" in
        *__GITHUB_REPOSITORY__*|"")
            fail "Unbekanntes GitHub-Repository. Bitte FORMELFREUND_REPO=besitzer/repo setzen oder eine Datei angeben." ;;
    esac
    URL="https://github.com/$REPO/releases/download/latest/Formelfreund.zip"
    say "Lade die neueste Version von Formelfreund …"
    curl -fL --progress-bar -o "$WORK_DIR/Formelfreund.zip" "$URL" \
        || fail "Download fehlgeschlagen. Besteht eine Internetverbindung? Ist das Repository öffentlich?"
    SOURCE="$WORK_DIR/Formelfreund.zip"
fi

[ -e "$SOURCE" ] || fail "Datei nicht gefunden: $SOURCE"

case "$SOURCE" in
    *.zip)
        ditto -x -k "$SOURCE" "$WORK_DIR/unpacked" || fail "Die ZIP-Datei ist beschädigt."
        NEW_APP=$(find "$WORK_DIR/unpacked" -maxdepth 2 -name "$APP_NAME" -type d | head -n 1)
        ;;
    *.app|*.app/)
        NEW_APP="${SOURCE%/}"
        ;;
    *)
        fail "Bitte eine .zip-Datei oder eine .app angeben."
        ;;
esac
if [ -z "${NEW_APP:-}" ] || [ ! -d "$NEW_APP" ]; then
    fail "In der Datei ist keine Formelfreund-App enthalten."
fi

# --- 3. Zielordner wählen und alte Version ersetzen ---------------------------

if [ -w /Applications ]; then
    DEST_DIR="/Applications"
else
    DEST_DIR="$HOME/Applications"
    mkdir -p "$DEST_DIR"
fi
DEST="$DEST_DIR/$APP_NAME"

if pgrep -xq Formelfreund; then
    say "Beende die laufende Formelfreund-App …"
    osascript -e 'tell application "Formelfreund" to quit' >/dev/null 2>&1 || true
    sleep 1
fi

rm -rf "$DEST"
ditto "$NEW_APP" "$DEST"

# Die App ist nicht über den App Store verteilt. Ohne diesen Schritt würde macOS
# beim ersten Start „kann nicht geöffnet werden“ melden, wenn die Datei aus dem
# Browser stammt. Mit curl geladene Dateien sind davon ohnehin nicht betroffen.
xattr -dr com.apple.quarantine "$DEST" 2>/dev/null || true

# --- 4. Starten --------------------------------------------------------------

say "Formelfreund ist installiert: $DEST"
open "$DEST"
