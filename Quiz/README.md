# Basisjahr Quiz

Quiz-App für das erste Semester Informatik an der ETH (HS 2026) mit
Fragen zu **Diskrete Mathematik**, **Lineare Algebra**, **Algorithmen und
Datenstrukturen** und **Einführung in die Programmierung**.

- **Stoffstand**: Ein Regler pro Fach legt fest, bis zu welchem Thema Fragen kommen.
- **Unterwegs**: kurze Tippfragen (eine Antwort, mehrere Antworten,
  „wahr/falsch“ pro Zeile) mit Erklärung, „Merke“ und Quellenangabe.
- **Schreiben**: Aufgaben für Stift und Papier. Ergebnis eintippen und prüfen,
  dann die Musterlösung Schritt für Schritt aufdecken und selbst bewerten.
- **Fortschritt**: was zuletzt richtig war, pro Thema, und „Fehler wiederholen“.
- Jede Runde mischt etwa ¼ leichte, ½ mittlere und ¼ schwere Fragen.
  Neue und zuletzt falsche Fragen kommen zuerst.
- Der Fortschritt bleibt im Browser (localStorage) auf dem jeweiligen Gerät.

## Aufbau

```
Quiz/
  src/shell.html        Markup und Gestaltung (CSS mit Hell/Dunkel-Tokens)
  src/app.js            App-Logik, Mini-Formelsatz, Java-Hervorhebung
  src/topics.js         Fächer und Themen (Reihenfolge = Regler)
  src/questions/*.js    Fragenkatalog, ein Fach in mehreren Dateien
  build.mjs             bündelt alles zu dist/basisjahr-quiz.html
  tools/check.mjs       prüft den Katalog, mit --java auch alle Java-Ausgaben
  dist/                 fertige Einzeldatei, im Browser direkt öffnen
```

```sh
node Quiz/tools/check.mjs --java   # Katalog prüfen, Java-Snippets ausführen
node Quiz/build.mjs                # dist/basisjahr-quiz.html erzeugen
```

## Fragen ergänzen

Neue Kapitel: Thema in `src/topics.js` anhängen, Fragen in einer Datei unter
`src/questions/` mit `QUIZ.add('<fach>', [ … ])` eintragen. Felder:

| Feld | Bedeutung |
| --- | --- |
| `id`, `t`, `d` | eindeutige ID, Thema (z. B. `ep4`), Schwierigkeit 1–3 |
| `k` | `sc` eine Antwort, `mc` mehrere, `tf` wahr/falsch-Zeilen, `w` Schreibaufgabe |
| `q`, `code` | Fragetext (Markdown-light, Mathe in `$…$`), optional Code |
| `o`, `a`, `w` | Optionen, richtige Antwort(en), Erklärung pro Option |
| `rows` | bei `tf`: `[Aussage, true/false, Begründung]` |
| `e`, `m`, `s` | Erklärung, „Merke“, Quelle |
| `out` | erwartete Java-Ausgabe, wird von `check.mjs --java` geprüft |
| `ans`, `sol`, `res`, `hint` | bei `w`: Antwortprüfung (`num`, `vec`, `set`, `str`), Lösungsschritte, Ergebnis, Tipp |

Mathe-Kurzschreibweise in `$…$`: `x_{i}`, `x^{2}`, `\frac{a}{b}`,
`\mat{1,2;3,4}`, `\vec{1;2;3}`, `\sqrt{x}` und gängige Symbole wie `\le`,
`\cdot`, `\equiv`, `\forall`.
