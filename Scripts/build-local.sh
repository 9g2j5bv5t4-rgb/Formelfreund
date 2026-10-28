#!/bin/sh
# Baut Lemma auf diesem Mac selbst (mit Xcode) und installiert die App –
# unabhängig von den Servern von GitHub.
#
# Im Terminal eingeben:
#   curl -fsSL https://raw.githubusercontent.com/9g2j5bv5t4-rgb/Formelfreund/main/Scripts/build-local.sh | sh
#
# Voraussetzung: Xcode aus dem App Store, einmal geöffnet und eingerichtet.
# Für jedes spätere Update genügt derselbe Befehl.
#
# Was das Skript macht:
#   1. Prüft den Mac und findet Xcode (ohne Admin-Passwort).
#   2. Lädt den neuesten Quelltext von GitHub (ohne git).
#   3. Baut die App (1–3 Minuten).
#   4. Installiert sie mit Scripts/install.sh und startet sie.

set -eu

REPO="${LEMMA_REPO:-9g2j5bv5t4-rgb/Formelfreund}"
BRANCH="${LEMMA_BRANCH:-main}"

say() { printf '%s\n' "$*"; }
fail() { printf '\nFehler: %s\n' "$*" >&2; exit 1; }

# Alles steckt in einer Funktion, die erst ganz am Ende aufgerufen wird:
# So läuft nichts, falls der Download des Skripts unterwegs abbricht.
main() {
    # --- 1. Mac und Xcode prüfen ----------------------------------------------

    [ "$(uname -s)" = "Darwin" ] || fail "Dieses Skript läuft nur auf einem Mac."
    [ "$(uname -m)" = "arm64" ] || fail "Lemma braucht einen Mac mit Apple-Chip (M1 oder neuer)."
    MACOS_MAJOR=$(sw_vers -productVersion | cut -d. -f1)
    [ "$MACOS_MAJOR" -ge 26 ] || fail "Lemma braucht macOS 26 oder neuer (installiert: $(sw_vers -productVersion))."

    XCODE=""
    for CANDIDATE in /Applications/Xcode.app /Applications/Xcode*.app "$HOME"/Applications/Xcode*.app; do
        if [ -d "$CANDIDATE/Contents/Developer" ]; then
            XCODE="$CANDIDATE"
            break
        fi
    done
    if [ -z "$XCODE" ]; then
        say "Xcode ist noch nicht installiert. Ich öffne den App Store."
        say "Bitte Xcode laden (kostenlos, gross – das dauert eine Weile),"
        say "einmal öffnen und danach diesen Befehl erneut eingeben."
        open "macappstore://apps.apple.com/app/xcode/id497799835" || true
        exit 1
    fi
    # Xcode direkt verwenden – ohne „sudo xcode-select“ und ohne Passwort.
    DEVELOPER_DIR="$XCODE/Contents/Developer"
    export DEVELOPER_DIR

    # Lizenz zugestimmt und Ersteinrichtung erledigt? Beides geht am
    # einfachsten, indem man Xcode einmal öffnet.
    if ! xcodebuild -version >/dev/null 2>&1 || ! xcodebuild -checkFirstLaunchStatus >/dev/null 2>&1; then
        say "Xcode muss einmal eingerichtet werden. Ich öffne Xcode jetzt:"
        say "  1. „Zustimmen“ (Agree) klicken und ggf. das Mac-Passwort eingeben."
        say "  2. Warten, bis die Einrichtung fertig ist, dann Xcode beenden."
        say "  3. Diesen Befehl erneut eingeben."
        open "$XCODE" || true
        exit 1
    fi

    XCODE_VERSION=$(xcodebuild -version | head -n 1 | sed 's/[^0-9.]//g')
    XCODE_MAJOR=$(printf '%s' "$XCODE_VERSION" | cut -d. -f1)
    [ "${XCODE_MAJOR:-0}" -ge 26 ] || fail "Xcode $XCODE_VERSION ist zu alt – bitte im App Store auf Xcode 26 oder neuer aktualisieren."
    say "Verwende Xcode $XCODE_VERSION."

    WORK_DIR=$(mktemp -d -t lemma-build)
    trap 'rm -rf "$WORK_DIR"' EXIT

    # --- 2. Quelltext laden ----------------------------------------------------

    say "Lade den neuesten Quelltext …"
    curl -fL --progress-bar -o "$WORK_DIR/source.tar.gz" \
        "https://github.com/$REPO/archive/refs/heads/$BRANCH.tar.gz" \
        || fail "Download fehlgeschlagen. Besteht eine Internetverbindung?"
    tar -xzf "$WORK_DIR/source.tar.gz" -C "$WORK_DIR" || fail "Der Quelltext ist beschädigt."
    PROJECT=$(find "$WORK_DIR" -maxdepth 2 -name Lemma.xcodeproj -type d | head -n 1)
    [ -n "$PROJECT" ] || fail "Im Quelltext fehlt Lemma.xcodeproj."
    SOURCE_DIR=$(dirname "$PROJECT")

    # --- 3. Bauen --------------------------------------------------------------

    say "Baue Lemma … (dauert 1–3 Minuten, der Mac darf dabei warm werden)"
    LOG="$WORK_DIR/build.log"
    if ! xcodebuild \
            -project "$PROJECT" \
            -scheme Lemma \
            -configuration Release \
            -destination 'platform=macOS,arch=arm64' \
            -derivedDataPath "$WORK_DIR/build" \
            build > "$LOG" 2>&1 < /dev/null; then
        say ""
        grep -E "error:" "$LOG" | sort -u | head -n 15 || true
        cp "$LOG" "$HOME/Desktop/Lemma-Bauprotokoll.txt" 2>/dev/null || true
        fail "Das Bauen hat nicht geklappt. Bitte schick mir die Fehlerzeilen oben.
Das ganze Protokoll liegt auf dem Schreibtisch: Lemma-Bauprotokoll.txt"
    fi
    APP="$WORK_DIR/build/Build/Products/Release/Lemma.app"
    [ -d "$APP" ] || fail "Xcode hat keine App erzeugt."
    say "Fertig gebaut."

    # --- 4. Installieren und starten ------------------------------------------

    sh "$SOURCE_DIR/Scripts/install.sh" "$APP" < /dev/null
}

main "$@"
