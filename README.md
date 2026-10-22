# Formelfreund

Ein LaTeX-Editor für den Mac, gemacht für den Einstieg: Übungsblätter,
Mitschriften und Zusammenfassungen mit viel Mathematik – ohne vorher eine
TeX-Distribution installieren zu müssen.

- Native macOS-App (SwiftUI + AppKit), Dark Mode, Systemakzentfarbe
- Normale `.tex`-Dateien – kompatibel mit Overleaf und TeXShop
- LaTeX-Engine **Tectonic** (wird beim ersten Kompilieren automatisch geladen);
  optional `latexmk`, falls MacTeX installiert ist
- Live-PDF-Vorschau mit SyncTeX (⌘-Klick springt zwischen Quelltext und PDF)

## Installieren (ohne Xcode)

Terminal öffnen (⌘-Leertaste, „Terminal“) und diese Zeile einfügen:

```sh
curl -fsSL https://github.com/__GITHUB_REPOSITORY__/releases/download/latest/install.sh | sh
```

Das Skript lädt die neueste Version, kopiert sie nach „Programme“ und startet
sie. Für ein Update dieselbe Zeile einfach noch einmal ausführen.
Voraussetzung: Mac mit Apple-Chip und macOS 26 oder neuer.

## Selbst bauen (mit Xcode)

Nur nötig, wenn du am Code arbeitest:

```sh
./Scripts/build-and-run.sh
```

Das Skript testet die Logik, baut die App, installiert und startet sie.
Alternativ `Formelfreund.xcodeproj` in Xcode öffnen und ⌘R drücken. Ein
Apple-Entwicklerkonto ist nicht nötig, die App wird lokal „ad hoc“ signiert.

## Aufbau

```
Formelfreund.xcodeproj      Xcode-Projekt (Ordner werden automatisch synchronisiert)
Config/Info.plist           Dateitypen (.tex)
Scripts/                    install.sh (App installieren), build-and-run.sh (selbst bauen)
.github/workflows/          Automatischer Build auf GitHub, veröffentlicht die App
Formelfreund/               Die App (Oberfläche)
  App/                      Einstieg, Menüs, Einstellungen-Schlüssel
  Document/                 Das .tex-Dokument (Laden/Sichern)
  Workspace/                Zustand eines Fensters: Kompilieren, Fehler, Sprünge
  Engine/                   Tectonic-Download, Engine-Auswahl, SyncTeX laden
  Editor/                   Text-Editor (AppKit): Einfärben, Zeilennummern, Klammern
  Preview/                  PDF-Vorschau (PDFKit)
  Sidebar/                  Gliederung, Formeln, Bilder
  Window/                   Fenster, Symbolleiste, Statusanzeige, Meldungen
  Settings/                 Einstellungsfenster
  Resources/                App-Symbol, Texte
Packages/LaTeXKit/          Die Logik ohne Oberfläche – mit Tests
  Sources/LaTeXKit/
    Text/                   Positionen, Zeilen, Textänderungen
    Syntax/                 Syntax-Analyse, Neu-Einfärben, Klammerpaare
    Editing/                Tipp-Hilfen (Klammern schliessen, \begin…\end)
    Structure/              Gliederung für die Seitenleiste
    Compilation/            Tectonic/latexmk aufrufen, Log auswerten
    SyncTeX/                Sprünge Quelltext ↔ PDF
```

**Warum zwei Teile?** Alles in `LaTeXKit` ist reine Logik ohne Oberfläche. Es
lässt sich schnell und automatisch testen (`swift test`) und bleibt
übersichtlich. Die App selbst kümmert sich nur um Darstellung und Bedienung.

## Tastaturkürzel

| Kürzel | Funktion |
| --- | --- |
| ⌘↩ | Kompilieren |
| ⇧⌘J | Cursor-Position im PDF zeigen |
| ⌘-Klick im Editor | Stelle im PDF zeigen |
| ⌘-Klick im PDF | Zur Zeile im Quelltext springen |
| ⇧⌘E | PDF exportieren |
| ⌥⌘P | PDF-Vorschau ein-/ausblenden |
| ⌥⌘L | LaTeX-Protokoll anzeigen |
| ⌘+ / ⌘− / ⌘0 | Schrift grösser / kleiner / Standard |

## Lizenzen

Tectonic (MIT-Lizenz) wird zur Laufzeit von GitHub geladen und über seine
SHA-256-Prüfsumme verifiziert.
