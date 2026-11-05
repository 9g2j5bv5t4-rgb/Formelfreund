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

Falls die Server von GitHub gerade keinen Mac frei haben, baut diese Zeile die
neueste Version direkt auf deinem Mac und installiert sie. Voraussetzung:
[Xcode](https://apps.apple.com/app/xcode/id497799835) aus dem App Store, einmal
geöffnet („Zustimmen“ klicken).

```sh
curl -fsSL https://raw.githubusercontent.com/9g2j5bv5t4-rgb/Formelfreund/main/Scripts/build-local.sh | sh
```

Wenn du am Code arbeitest (im geklonten Repository):

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
| ⌘K | Auskommentieren ein/aus |
| ⌥⌘↑ / ⌥⌘↓ | Zeilen nach oben / unten verschieben |
| ⌥⌘A | Block auswählen (mehrmals drücken = grösserer Block) |
| ⇧⌘M | Formel abgesetzt ↔ im Text |
| Tab / ⇧Tab | Nächster / vorheriger Platzhalter • |
| ⌥⌘I | Format-Seitenleiste ein-/ausblenden |
| ⌥⌘T | Symbolleiste ein-/ausblenden |
| esc | Vorschläge zeigen (↑ ↓ wählen, ↩ oder ⇥ einfügen) |
| ⌥⌘← / ⌥⌘→ | Abschnitt einklappen / aufklappen (mit ⇧: alle) |
| ⇧⌘N | Neu aus Vorlage |

## Symbolleiste, Format-Seitenleiste und Bausteine

Die Oberfläche folgt Apples Richtlinien für Mac-Programme – aufgebaut wie
Pages und Keynote. Alles wird als normales LaTeX geschrieben, die Datei bleibt
mit Overleaf und TeXShop kompatibel. Jeder Befehl steht auch in der Menüleiste.

- **Symbolleiste:** Formel, Tabelle, Matrix, Bild, Liste und Bausteine zum
  Einfügen; rechts Status, Kompilieren, Vorschau und Format. Die Knöpfe in der
  Mitte sind frei wählbar und sortierbar: „Darstellung → Symbolleiste anpassen …“
  oder Rechtsklick auf die Knöpfe (zur Wahl stehen auch Fett, Kursiv, Zeichen,
  Suchen, Kommentar, PDF exportieren …).
- **Format-Seitenleiste** (⌥⌘I), drei Register:
  - *Text:* Fett/Kursiv/Unterstrichen, Schriftstil, Grösse, Farbe,
    Ausrichtung, Listen, Einzug, Block-Werkzeuge (auswählen, umwandeln,
    einpacken, auflösen, nummerieren), Zeilen verschieben, auskommentieren.
  - *Formel:* alle Formel-Bausteine, Matrizen, Systeme, Fälle, Rechnungen und
    Vektoren in beliebiger Grösse, alle Zeichen nach Gruppen.
  - *Layout:* Ränder und Zeilenabstand mit Voreinstellung, Regler und
    Eingabefeld – für das ganze Dokument oder nur „diese Seite“ –, Schriftart,
    Grundgrösse, Papier.
- **Freie Grössen:** Tabellen und Matrizen per Raster aufziehen (wie in Word),
  Zeilen und Spalten bis 20 × 20.
- **Passende Stelle:** Bausteine landen dort, wo sie Sinn ergeben – nie in der
  Präambel oder nach `\end{document}`, abgesetzte Formeln hinter der Formel am
  Cursor, Tabellen nicht in Tabellen, Überschriften nicht in Listen.
- **Fehlerhilfe:** Fehler werden über dem Editor auf Deutsch erklärt, mit
  Lösungsvorschlag und – wo möglich – „Beheben“ (Paket laden, Tippfehler …).
- **Vorschläge beim Tippen:** Nach `\` und einem Buchstaben erscheinen passende
  Befehle mit deutscher Erklärung – auch über deutsche Begriffe (`\bruch` findet
  `\frac`, `\wurzel` findet `\sqrt`). Nach `\begin{` folgen Umgebungen (samt
  `\end{…}`), nach `\ref{` die eigenen Marken, nach `\cite{` die Quellen aus
  `\bibitem` und `.bib`-Dateien, nach `\usepackage{` die Pakete.
- **Klammern schliessen:** `{`, `(`, `[`, `$`, `\[` und `\left(` bekommen ihr
  Gegenstück, `\begin{…}` das passende `\end{…}`; der Cursor steht dazwischen.
- **Rechtschreibung:** geprüft wird nur der Fliesstext – Befehle, Formeln,
  Kommentare und technische Angaben wie `\label{…}` werden nie angestrichen.
- **Einklappen:** Dreiecke neben den Zeilennummern klappen Präambel, Abschnitte
  und mehrzeilige Umgebungen ein; „⋯“ klappt wieder auf.
- **Formelvorschau:** Steht der Cursor in einer Formel, schwebt sie fertig
  gesetzt darüber (MathJax, ohne Internet) – mit eigenen Befehlen aus der Präambel.
- **Wortanzahl** unten rechts, bei einer Auswahl auch für die Auswahl.
- **Bilder** in den Editor ziehen oder einsetzen (auch Bildschirmfotos): Lemma
  legt sie im Ordner „Bilder“ ab und fügt eine Abbildung mit Beschriftung ein.
- **Vorlagen** (⇧⌘N): Übungsblatt, Mitschrift, Zusammenfassung,
  Versuchsprotokoll, Seminararbeit, Präsentation.
- **Speichern** (⌘S) und PDF-Export bestätigen sich mit einer kurzen Meldung.
- Fehlende Pakete (z. B. `xcolor` für Farben) ergänzt Lemma automatisch.

## Lizenzen

Tectonic (MIT-Lizenz) wird zur Laufzeit von GitHub geladen und über seine
SHA-256-Prüfsumme verifiziert. Die Formelvorschau verwendet MathJax 3.2.2
(Apache-Lizenz 2.0), enthalten in `Lemma/Resources/MathPreview.html`.
