import Foundation

/// Eine Umgebung `\begin{name} … \end{name}` im Text.
public struct EnvironmentBlock: Equatable, Sendable {
    public var name: String
    /// Von `\begin` bis einschliesslich `\end{name}`.
    public var range: Range<Int>
    /// Nur `\begin{name}` (ohne optionale Argumente dahinter).
    public var beginRange: Range<Int>
    /// Nur `\end{name}`.
    public var endRange: Range<Int>
    /// Zwischen `\begin{name}` und `\end{name}`.
    public var contentRange: Range<Int>

    public init(name: String, range: Range<Int>, beginRange: Range<Int>, endRange: Range<Int>, contentRange: Range<Int>) {
        self.name = name
        self.range = range
        self.beginRange = beginRange
        self.endRange = endRange
        self.contentRange = contentRange
    }
}

/// Werkzeuge, die ganze Blöcke bearbeiten: Umgebungen umwandeln, auflösen,
/// einpacken, Zeilen verschieben, auskommentieren, einrücken.
///
/// Alle Funktionen sind rein: Sie lesen den Text und liefern eine `TextEdit`,
/// die der Editor als *einen* rückgängig machbaren Schritt ausführt.
/// Kommentare und `verbatim`-Inhalte werden beim Suchen ignoriert.
public enum BlockEditor {
    /// Innerste Umgebung, die `position` enthält (optional nur mit bestimmten Namen).
    /// `document` wird nie geliefert.
    public static func enclosingEnvironment<S: UTF16Source>(
        in text: S,
        at position: Int,
        named names: Set<String>? = nil
    ) -> EnvironmentBlock? {
        let position = min(max(0, position), text.count)
        // 1. Von vorne bis zur Position: Stapel der offenen Umgebungen.
        var stack: [(name: String, begin: Range<Int>)] = []
        var i = 0
        while i < text.count {
            let u = text[i]
            if u == TeXChar.percent && !text.isEscaped(at: i) {
                i = text.lineEnd(after: i)
                continue
            }
            guard u == TeXChar.backslash, !text.isEscaped(at: i) else { i += 1; continue }
            guard let token = environmentToken(in: text, at: i) else { i += 1; continue }
            if token.isBegin {
                guard token.range.lowerBound < position else { break }
                if LaTeXTokenizer.verbatimEnvironments.contains(token.name) {
                    // Inhalt wörtlich: bis zum passenden \end springen.
                    if let end = findEnd(of: token.name, in: text, from: token.range.upperBound) {
                        if position < end.upperBound {
                            stack.append((token.name, token.range))
                            break
                        }
                        i = end.upperBound
                        continue
                    }
                    stack.append((token.name, token.range))
                    break
                }
                stack.append((token.name, token.range))
            } else {
                // Steht der Cursor im \end{…} selbst, gehört er noch zur Umgebung.
                guard token.range.upperBound <= position else { break }
                if let index = stack.lastIndex(where: { $0.name == token.name }) {
                    stack.removeSubrange(index...)
                }
            }
            i = token.range.upperBound
        }

        // 2. Von innen nach aussen die erste passende, geschlossene Umgebung.
        for open in stack.reversed() {
            guard open.name != "document" else { continue }
            if let names, !names.contains(open.name) { continue }
            guard let end = findEnd(of: open.name, in: text, from: open.begin.upperBound) else { continue }
            return EnvironmentBlock(
                name: open.name,
                range: open.begin.lowerBound..<end.upperBound,
                beginRange: open.begin,
                endRange: end,
                contentRange: open.begin.upperBound..<end.lowerBound
            )
        }
        return nil
    }

    /// `\begin{name}` bzw. `\end{name}` ab `index` (muss auf dem Backslash stehen).
    static func environmentToken<S: UTF16Source>(in text: S, at index: Int) -> (isBegin: Bool, name: String, range: Range<Int>)? {
        let isBegin: Bool
        var j: Int
        if text.matches("\\begin", at: index) {
            isBegin = true
            j = index + 6
        } else if text.matches("\\end", at: index) {
            isBegin = false
            j = index + 4
        } else {
            return nil
        }
        // Kein längerer Befehlsname wie \beginning.
        if let next = text.unit(at: j), TeXChar.isASCIILetter(next) { return nil }
        while j < text.count && (text[j] == TeXChar.space || text[j] == TeXChar.tab) { j += 1 }
        guard text.unit(at: j) == TeXChar.braceOpen else { return nil }
        let nameStart = j + 1
        var k = nameStart
        while k < text.count && text[k] != TeXChar.braceClose && text[k] != TeXChar.newline && k - nameStart < 64 { k += 1 }
        guard text.unit(at: k) == TeXChar.braceClose, k > nameStart else { return nil }
        return (isBegin, text.string(in: nameStart..<k), index..<(k + 1))
    }

    /// Passendes `\end{name}` ab `start`, verschachtelte gleichnamige Umgebungen werden übersprungen.
    static func findEnd<S: UTF16Source>(of name: String, in text: S, from start: Int) -> Range<Int>? {
        let isVerbatim = LaTeXTokenizer.verbatimEnvironments.contains(name)
        var depth = 1
        var i = start
        while i < text.count {
            let u = text[i]
            if !isVerbatim && u == TeXChar.percent && !text.isEscaped(at: i) {
                i = text.lineEnd(after: i)
                continue
            }
            if u == TeXChar.backslash, !text.isEscaped(at: i), let token = environmentToken(in: text, at: i) {
                if token.name == name {
                    if token.isBegin && !isVerbatim {
                        depth += 1
                    } else if !token.isBegin {
                        depth -= 1
                        if depth == 0 { return token.range }
                    }
                }
                i = token.range.upperBound
                continue
            }
            i += 1
        }
        return nil
    }

    /// Nächstgrössere sinnvolle Auswahl („Block auswählen“): Wort → Inhalt der
    /// innersten Klammer → Inhalt der Umgebung → ganze Umgebung → Absatz → nächste Umgebung …
    public static func expandSelection<S: UTF16Source>(in text: S, selection: Range<Int>) -> Range<Int> {
        fatalError("Noch nicht umgesetzt")
    }

    /// Benennt `\begin{alt}` und `\end{alt}` zugleich um. Der Cursor bleibt an derselben Textstelle.
    public static func renameEnvironment<S: UTF16Source>(
        _ block: EnvironmentBlock,
        to newName: String,
        in text: S,
        selection: Range<Int>
    ) -> TextEdit {
        fatalError("Noch nicht umgesetzt")
    }

    /// Nummerierung umschalten: `equation` ↔ `equation*`, `align` ↔ `align*`, `gather`, `multline`, `flalign`.
    /// `nil`, wenn der Cursor in keiner solchen Formel steht.
    public static func toggleNumbering<S: UTF16Source>(in text: S, selection: Range<Int>) -> TextEdit? {
        fatalError("Noch nicht umgesetzt")
    }

    /// Entfernt `\begin{…}`/`\end{…}` (samt optionalen Argumenten und dann leeren Zeilen)
    /// und rückt den Inhalt eine Ebene aus. Der Inhalt bleibt erhalten.
    public static func unwrapEnvironment<S: UTF16Source>(_ block: EnvironmentBlock, in text: S, selection: Range<Int>) -> TextEdit {
        fatalError("Noch nicht umgesetzt")
    }

    /// Packt die ausgewählten Zeilen (ganze Zeilen) in eine Umgebung und rückt sie ein.
    /// Ohne Auswahl: leere Umgebung in der aktuellen Zeile, Cursor im Inneren.
    public static func wrap<S: UTF16Source>(selection: Range<Int>, inEnvironment name: String, in text: S) -> TextEdit {
        fatalError("Noch nicht umgesetzt")
    }

    /// Verschiebt die Zeile(n) der Auswahl eine Zeile nach oben bzw. unten.
    /// `nil` am Textanfang bzw. -ende. Die Auswahl wandert mit.
    public static func moveLines<S: UTF16Source>(in text: S, selection: Range<Int>, up: Bool) -> TextEdit? {
        fatalError("Noch nicht umgesetzt")
    }

    /// Kommentiert die Zeilen der Auswahl mit `% ` aus – oder wieder ein,
    /// wenn alle nicht leeren Zeilen bereits auskommentiert sind.
    public static func toggleComment<S: UTF16Source>(in text: S, selection: Range<Int>) -> TextEdit {
        fatalError("Noch nicht umgesetzt")
    }

    /// Rückt die Zeilen der Auswahl um `EditingAssistant.indentUnit` ein bzw. aus.
    public static func shiftIndentation<S: UTF16Source>(in text: S, selection: Range<Int>, outdent: Bool) -> TextEdit {
        fatalError("Noch nicht umgesetzt")
    }

    /// Wandelt die Formel am Cursor um: `$x$` bzw. `\(x\)` → `\[ x \]` auf eigenen Zeilen,
    /// und `\[ x \]` bzw. `$$x$$` → `$x$`. `nil`, wenn der Cursor in keiner solchen Formel steht.
    public static func toggleDisplayMath<S: UTF16Source>(in text: S, selection: Range<Int>) -> TextEdit? {
        fatalError("Noch nicht umgesetzt")
    }

    /// Sinnvolle Zielumgebungen für „Umgebung umwandeln“, in Menü-Reihenfolge,
    /// ohne die Umgebung selbst. Unbekannt → leer.
    public static func conversions(for environment: String) -> [String] {
        fatalError("Noch nicht umgesetzt")
    }

    /// Deutscher Anzeigename einer Umgebung (`align*` → „Ausgerichtete Formeln (ohne Nummer)“),
    /// sonst der Name selbst.
    public static func displayName(for environment: String) -> String {
        fatalError("Noch nicht umgesetzt")
    }
}
