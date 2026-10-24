#!/bin/sh
# Installiert Lemma auf diesem Mac – ohne Xcode.
#
# Neueste Version von GitHub laden und installieren:
#   curl -fsSL https://github.com/<besitzer>/<repo>/releases/download/latest/install.sh | sh
#
# Eine bereits heruntergeladene App oder ZIP-Datei installieren:
#   sh install.sh ~/Downloads/Lemma.zip
#   sh install.sh build/Build/Products/Release/Lemma.app
#
# Was das Skript macht:
#   1. Prüft, ob der Mac passt (Apple Silicon, macOS 26 oder neuer).
#   2. Lädt die neueste Version von GitHub (falls keine Datei angegeben ist).
#   3. Beendet eine laufende Lemma-App und ersetzt sie.
#   4. Kopiert die App nach /Programme (oder ~/Programme, falls nötig) und startet sie.

set -eu

# Wird beim Veröffentlichen automatisch durch "besitzer/repo" ersetzt.
REPO="${FORMELFREUND_REPO:-__GITHUB_REPOSITORY__}"
APP_NAME="Lemma.app"

say() { printf '%s\n' "$*"; }
fail() { printf 'Fehler: %s\n' "$*" >&2; exit 1; }

# --- 1. Passt der Mac? -------------------------------------------------------

[ "$(uname -s)" = "Darwin" ] || fail "Dieses Skript läuft nur auf einem Mac."
[ "$(uname -m)" = "arm64" ] || fail "Lemma braucht einen Mac mit Apple-Chip (M1 oder neuer)."
MACOS_MAJOR=$(sw_vers -productVersion | cut -d. -f1)
[ "$MACOS_MAJOR" -ge 26 ] || fail "Lemma braucht macOS 26 oder neuer (installiert: $(sw_vers -productVersion))."

WORK_DIR=$(mktemp -d -t lemma)
trap 'rm -rf "$WORK_DIR"' EXIT

# --- 2. App besorgen ---------------------------------------------------------

SOURCE="${1:-}"
if [ -z "$SOURCE" ]; then
    case "$REPO" in
        __GITHUB_*|"")
            fail "Unbekanntes GitHub-Repository. Bitte FORMELFREUND_REPO=besitzer/repo setzen oder eine Datei angeben." ;;
    esac
    URL="https://github.com/$REPO/releases/download/latest/Lemma.zip"
    say "Lade die neueste Version von Lemma …"
    curl -fL --progress-bar -o "$WORK_DIR/Lemma.zip" "$URL" \
        || fail "Download fehlgeschlagen. Besteht eine Internetverbindung? Ist das Repository öffentlich?"
    SOURCE="$WORK_DIR/Lemma.zip"
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
    fail "In der Datei ist keine Lemma-App enthalten."
fi

# --- 3. Zielordner wählen und alte Version ersetzen ---------------------------

if [ -w /Applications ]; then
    DEST_DIR="/Applications"
else
    DEST_DIR="$HOME/Applications"
    mkdir -p "$DEST_DIR"
fi
DEST="$DEST_DIR/$APP_NAME"

# Laufende App beenden – auch unter ihrem früheren Namen „Formelfreund“.
for OLD_NAME in Lemma Formelfreund; do
    if pgrep -xq "$OLD_NAME"; then
        say "Beende die laufende $OLD_NAME-App …"
        osascript -e "tell application \"$OLD_NAME\" to quit" >/dev/null 2>&1 || true
        sleep 1
    fi
done

# Die App hiess früher „Formelfreund“ – die alte Version wird ersetzt.
rm -rf "$DEST_DIR/Formelfreund.app"
rm -rf "$DEST"
ditto "$NEW_APP" "$DEST"

# Die App ist nicht über den App Store verteilt. Ohne diesen Schritt würde macOS
# beim ersten Start „kann nicht geöffnet werden“ melden, wenn die Datei aus dem
# Browser stammt. Mit curl geladene Dateien sind davon ohnehin nicht betroffen.
xattr -dr com.apple.quarantine "$DEST" 2>/dev/null || true

# --- 4. Starten --------------------------------------------------------------

say "Lemma ist installiert: $DEST"
open "$DEST"
