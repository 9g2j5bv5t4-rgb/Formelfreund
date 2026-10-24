# Lemma

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
curl -fsSL https://github.com/9g2j5bv5t4-rgb/Formelfreund/releases/download/latest/install.sh | sh
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
Alternativ `Lemma.xcodeproj` in Xcode öffnen und ⌘R drücken. Ein
Apple-Entwicklerkonto ist nicht nötig, die App wird lokal „ad hoc“ signiert.

## Aufbau

```
Lemma.xcodeproj      Xcode-Projekt (Ordner werden automatisch synchronisiert)
Config/Info.plist           Dateitypen (.tex)
Scripts/                    install.sh (App installieren), build-and-run.sh (selbst bauen)
.github/workflows/          Automatischer Build auf GitHub, veröffentlicht die App
Lemma/               Die App (Oberfläche)
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
| ⌘B / ⌘I / ⌘U | Fett / Kursiv / Unterstrichen |
| ⌥⌘0 … ⌥⌘4 | Text / Überschrift 1–4 |
| ⌘] / ⌘[ | Einrücken / Ausrücken |
| ⌘/ | Auskommentieren ein/aus |
| ⌥⌘↑ / ⌥⌘↓ | Zeilen nach oben / unten verschieben |
| ⌥⌘A | Block auswählen (mehrmals drücken = grösserer Block) |
| ⇧⌘M | Formel abgesetzt ↔ im Text |
| Tab / ⇧Tab | Nächster / vorheriger Platzhalter • |
| ⌥⌘I | Inspektor (Schrift und Seite des Dokuments) |

## Format-Leiste und Bausteine

Über dem Editor sitzt eine Format-Leiste wie in Word oder Pages: Absatzstil
(Text, Überschrift 1–4), Fett/Kursiv/Unterstrichen, Schriftstil, Grösse,
Farbe, Ausrichtung, Listen, Einrücken. Alles wird als normales LaTeX
geschrieben – die Datei bleibt mit Overleaf und TeXShop kompatibel.

- **Einfügen (+):** über 60 Bausteine – Formeln, abgesetzte Formeln, Matrizen,
  Definition/Satz/Beweis, Listen, Bilder, Tabellen. Platzhalter `•` springst
  du mit Tab an.
- **Block:** Umgebung umwandeln (z. B. Aufzählung → Nummerierung), auflösen,
  in eine Umgebung einpacken, Formel-Nummerierung ein/aus.
- **Inspektor:** Schriftart des Dokuments (Latin Modern, Times, Palatino,
  Charter, Libertinus, Helvetica), Grundgrösse, Papier, Ränder, Zeilenabstand.
- Fehlende Pakete (z. B. `xcolor` für Farben) ergänzt Lemma automatisch.

## Lizenzen

Tectonic (MIT-Lizenz) wird zur Laufzeit von GitHub geladen und über seine
SHA-256-Prüfsumme verifiziert.
