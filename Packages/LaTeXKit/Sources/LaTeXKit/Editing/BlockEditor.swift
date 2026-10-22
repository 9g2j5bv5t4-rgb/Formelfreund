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

    // MARK: - Block auswählen

    /// Nächstgrössere sinnvolle Auswahl („Block auswählen“): Wort → Inhalt der
    /// innersten Klammer → Inhalt der Umgebung → ganze Umgebung → Absatz → nächste Umgebung …
    public static func expandSelection<S: UTF16Source>(in text: S, selection: Range<Int>) -> Range<Int> {
        let current = clamped(selection, in: text)
        let units = utf16Units(of: text)
        let analysis = LaTeXTokenizer.tokenize(units)

        // Zuerst alle Bereiche sammeln, die als nächste Stufe in Frage kommen …
        var candidates: [Range<Int>] = []
        if let word = wordRange(in: text, around: current) {
            candidates.append(word)
        }
        candidates += braceContents(in: units, tokens: analysis.tokens, enclosing: current)
        if let region = analysis.mathRegion(containing: current.lowerBound), region.isClosed {
            // Eine Formel ist auch eine Art Klammer: erst ihr Inhalt, dann mit `$…$`.
            candidates.append(trimmedBlock(in: text, region.contentRange))
            candidates.append(region.range)
        }
        // Umgebungen von innen nach aussen; `document` zählt hier als äusserste mit.
        var environments = enclosingEnvironments(in: text, around: current)
        if let document = documentEnvironment(in: text),
           document.range.lowerBound <= current.lowerBound, current.upperBound <= document.range.upperBound {
            environments.append(document)
        }
        for environment in environments {
            candidates.append(trimmedBlock(in: text, innerContent(of: environment, in: text)))
            candidates.append(environment.range)
        }
        if var paragraph = paragraphRange(in: text, around: current) {
            // Ein Absatz endet spätestens am Rand der Umgebung, in der die Auswahl steht.
            if let container = environments.first(where: {
                $0.contentRange.lowerBound <= current.lowerBound && current.upperBound <= $0.contentRange.upperBound
            }) {
                let inner = innerContent(of: container, in: text)
                let lower = max(paragraph.lowerBound, inner.lowerBound)
                paragraph = lower..<max(lower, min(paragraph.upperBound, inner.upperBound))
            }
            candidates.append(trimmedBlock(in: text, paragraph))
        }
        candidates.append(0..<text.count)

        // … dann den kleinsten nehmen, der die Auswahl umfasst und echt grösser ist.
        let larger = candidates.filter {
            $0.lowerBound <= current.lowerBound && $0.upperBound >= current.upperBound && $0.count > current.count
        }
        return larger.min { $0.count < $1.count } ?? selection
    }

    // MARK: - Umgebung umbenennen

    /// Benennt `\begin{alt}` und `\end{alt}` zugleich um. Der Cursor bleibt an derselben Textstelle.
    public static func renameEnvironment<S: UTF16Source>(
        _ block: EnvironmentBlock,
        to newName: String,
        in text: S,
        selection: Range<Int>
    ) -> TextEdit {
        let current = clamped(selection, in: text)
        // Passt der Block (noch) zum Text? Sonst lieber nichts ändern.
        guard block.beginRange.lowerBound >= 0,
              block.beginRange.upperBound <= block.endRange.lowerBound,
              block.endRange.upperBound <= text.count,
              let begin = environmentToken(in: text, at: block.beginRange.lowerBound), begin.isBegin,
              let end = environmentToken(in: text, at: block.endRange.lowerBound), !end.isBegin
        else {
            return unchanged(current)
        }
        var builder = ReplacementBuilder(start: begin.range.lowerBound)
        replaceName(in: begin, with: newName, text: text, builder: &builder)
        replaceName(in: end, with: newName, text: text, builder: &builder)
        builder.keep(text, upTo: end.range.upperBound)
        return builder.edit(selection: current)
    }

    // MARK: - Nummerierung

    /// Nummerierung umschalten: `equation` ↔ `equation*`, `align` ↔ `align*`, `gather`, `multline`, `flalign`.
    /// `nil`, wenn der Cursor in keiner solchen Formel steht.
    public static func toggleNumbering<S: UTF16Source>(in text: S, selection: Range<Int>) -> TextEdit? {
        let current = clamped(selection, in: text)
        let analysis = LaTeXTokenizer.tokenize(utf16Units(of: text))

        // `\[ … \]` und `$$ … $$` haben nie eine Nummer: daraus wird `equation`.
        if let region = analysis.mathRegion(containing: current.lowerBound),
           region.isClosed, region.style == .display, region.environment == nil,
           current.upperBound <= region.range.upperBound {
            var builder = ReplacementBuilder(start: region.range.lowerBound)
            builder.skip(upTo: region.contentRange.lowerBound)
            builder.insert("\\begin{equation}")
            builder.keep(text, upTo: region.contentRange.upperBound)
            builder.skip(upTo: region.range.upperBound)
            builder.insert("\\end{equation}")
            return builder.edit(selection: current)
        }

        guard let block = enclosingEnvironment(in: text, at: current.lowerBound, named: numberedFormulas) else {
            return nil
        }
        // Der Stern bedeutet in LaTeX „ohne Nummer“.
        let newName = block.name.hasSuffix("*") ? String(block.name.dropLast()) : block.name + "*"
        return renameEnvironment(block, to: newName, in: text, selection: current)
    }

    // MARK: - Umgebung auflösen

    /// Entfernt `\begin{…}`/`\end{…}` (samt optionalen Argumenten und dann leeren Zeilen)
    /// und rückt den Inhalt eine Ebene aus. Der Inhalt bleibt erhalten.
    public static func unwrapEnvironment<S: UTF16Source>(_ block: EnvironmentBlock, in text: S, selection: Range<Int>) -> TextEdit {
        let current = clamped(selection, in: text)
        let begin = block.beginRange
        let end = block.endRange
        guard begin.lowerBound >= 0, begin.upperBound <= end.lowerBound, end.upperBound <= text.count else {
            return unchanged(current)
        }

        // 1. Was von `\begin{…}` und `\end{…}` wegfällt – samt Argumenten wie `[htbp]`
        //    und den Leerzeichen daneben, damit keine doppelten Leerzeichen bleiben.
        let argumentsEnd = argumentsEnd(of: block.name, in: text, from: begin.upperBound, limit: end.lowerBound)
        let beginCut = begin.lowerBound..<skipSpaces(in: text, from: argumentsEnd, limit: end.lowerBound)

        let beginLineStart = text.lineStart(before: begin.lowerBound)
        // Zeilenende nach `\begin{…}` samt Argumenten (die bei TikZ auch über
        // mehrere Zeilen gehen können).
        let beginLineEnd = text.lineEnd(after: beginCut.upperBound)
        let endLineStart = text.lineStart(before: end.lowerBound)
        let endLineEnd = text.lineEnd(after: end.lowerBound)
        // Steht `\end{…}` am Zeilenanfang (nur Einrückung davor)?
        let endAtLineStart = onlySpaces(in: text, max(endLineStart, beginCut.upperBound)..<end.lowerBound)
        let endCut: Range<Int>
        if endAtLineStart {
            endCut = end.lowerBound..<skipSpaces(in: text, from: end.upperBound, limit: endLineEnd)
        } else {
            var lower = end.lowerBound
            while lower > max(endLineStart, beginCut.upperBound), isSpaceOrTab(text[lower - 1]) { lower -= 1 }
            endCut = lower..<end.upperBound
        }

        // 2. Alles auf einer Zeile, z. B. `\begin{center}Text\end{center}`.
        if endLineStart <= beginLineEnd {
            let lineBecomesEmpty = onlySpaces(in: text, beginLineStart..<begin.lowerBound)
                && onlySpaces(in: text, beginCut.upperBound..<endCut.lowerBound)
                && onlySpaces(in: text, endCut.upperBound..<endLineEnd)
            var builder: ReplacementBuilder
            if lineBecomesEmpty {
                let line = wholeLine(in: text, from: beginLineStart, to: endLineEnd)
                builder = ReplacementBuilder(start: line.lowerBound)
                builder.skip(upTo: line.upperBound)
            } else {
                builder = ReplacementBuilder(start: beginCut.lowerBound)
                builder.skip(upTo: beginCut.upperBound)
                builder.keep(text, upTo: endCut.lowerBound)
                builder.skip(upTo: endCut.upperBound)
            }
            return builder.edit(selection: current)
        }

        // 3. Zeilen, auf denen nur `\begin{…}` bzw. `\end{…}` stand, fallen ganz weg.
        let beginLineBecomesEmpty = onlySpaces(in: text, beginLineStart..<begin.lowerBound)
            && beginCut.upperBound == beginLineEnd
        let beginRemoval = beginLineBecomesEmpty ? beginLineStart..<(beginLineEnd + 1) : beginCut
        let endLineBecomesEmpty = endAtLineStart && endCut.upperBound == endLineEnd
        let endRemoval: Range<Int>
        if !endLineBecomesEmpty {
            endRemoval = endCut
        } else if endLineEnd < text.count {
            endRemoval = endLineStart..<(endLineEnd + 1)
        } else {
            // Letzte Zeile ohne Zeilenumbruch: den Umbruch davor mitnehmen.
            endRemoval = max(endLineStart - 1, beginRemoval.upperBound)..<endLineEnd
        }

        // 4. Inhaltszeilen eine Ebene ausrücken (wörtliche Inhalte wie `verbatim` nicht).
        let verbatim = verbatimContents(in: text, within: begin.upperBound..<end.lowerBound)
        var dedents: [Range<Int>] = []
        var lineStart = beginLineEnd + 1
        while lineStart <= endLineStart {
            if lineStart == endLineStart && endAtLineStart { break }
            let lineEnd = text.lineEnd(after: lineStart)
            let insideVerbatim = verbatim.contains { lineStart > $0.lowerBound && lineEnd < $0.upperBound }
            if !insideVerbatim {
                let cut = indentationLevelEnd(in: text, lineStart: lineStart, lineEnd: lineEnd)
                if cut > lineStart { dedents.append(lineStart..<cut) }
            }
            lineStart = lineEnd + 1
        }

        // 5. Alles zu *einer* Ersetzung zusammensetzen.
        var builder = ReplacementBuilder(start: beginRemoval.lowerBound)
        builder.skip(upTo: beginRemoval.upperBound)
        for cut in dedents {
            builder.keep(text, upTo: cut.lowerBound)
            builder.skip(upTo: cut.upperBound)
        }
        builder.keep(text, upTo: endRemoval.lowerBound)
        builder.skip(upTo: endRemoval.upperBound)
        return builder.edit(selection: current)
    }

    // MARK: - In Umgebung einpacken

    /// Packt die ausgewählten Zeilen (ganze Zeilen) in eine Umgebung und rückt sie ein.
    /// Ohne Auswahl: leere Umgebung in der aktuellen Zeile, Cursor im Inneren.
    public static func wrap<S: UTF16Source>(selection: Range<Int>, inEnvironment name: String, in text: S) -> TextEdit {
        let current = clamped(selection, in: text)
        let unit = EditingAssistant.indentUnit
        let isList = EditingAssistant.listEnvironments.contains(name)
        let beginLine = "\\begin{\(name)}" + (requiredArguments[name] ?? "")
        let endLine = "\\end{\(name)}"

        let lines = lineRanges(in: text, block: touchedLines(in: text, current))
            .filter { !isBlank(text, $0) }
        // Keine Auswahl (oder nur leere Zeilen markiert): leere Umgebung mit Cursor darin.
        guard !current.isEmpty, let first = lines.first, let last = lines.last else {
            return emptyEnvironment(
                at: current.lowerBound, in: text,
                beginLine: beginLine, endLine: endLine,
                innerLine: unit + (isList ? "\\item " : "")
            )
        }

        // Leere Zeilen am Anfang und Ende der Auswahl bleiben ausserhalb.
        let block = first.lowerBound..<last.upperBound
        let indent = EditingAssistant.leadingWhitespace(text, lineContaining: block.lowerBound)
        let selectedText = text.string(in: block)
        // In einer Liste wird jede Zeile ein eigener Punkt – ausser, es stecken Umgebungen darin.
        let addItems = isList && !selectedText.contains("\\begin{") && !selectedText.contains("\\end{")

        let opening = indent + beginLine + "\n"
        var builder = ReplacementBuilder(start: block.lowerBound)
        builder.insert(opening)
        for line in lineRanges(in: text, block: block) {
            builder.keep(text, upTo: line.lowerBound)
            guard !isBlank(text, line) else { continue }
            builder.insert(unit)
            let contentStart = skipSpaces(in: text, from: line.lowerBound, limit: line.upperBound)
            if addItems, !startsWithItem(text, at: contentStart), text[contentStart] != TeXChar.percent {
                builder.keep(text, upTo: contentStart)
                builder.insert("\\item ")
            }
        }
        builder.keep(text, upTo: block.upperBound)
        let closing = "\n" + indent + endLine
        builder.insert(closing)

        // Die Auswahl bleibt auf denselben Zeichen, aber innerhalb der Umgebung.
        var edit = builder.edit(selection: current)
        let contentStart = block.lowerBound + opening.utf16.count
        let contentEnd = block.lowerBound + builder.length - closing.utf16.count
        edit.selectionAfter = clamp(edit.selectionAfter, to: contentStart..<contentEnd)
        return edit
    }

    // MARK: - Zeilen verschieben

    /// Verschiebt die Zeile(n) der Auswahl eine Zeile nach oben bzw. unten.
    /// `nil` am Textanfang bzw. -ende. Die Auswahl wandert mit.
    public static func moveLines<S: UTF16Source>(in text: S, selection: Range<Int>, up: Bool) -> TextEdit? {
        let current = clamped(selection, in: text)
        let block = touchedLines(in: text, current)
        let blockText = text.string(in: block)

        if up {
            // Darüber gibt es keine Zeile mehr.
            guard block.lowerBound > 0 else { return nil }
            let previousStart = text.lineStart(before: block.lowerBound - 1)
            let previousText = text.string(in: previousStart..<(block.lowerBound - 1))
            let shift = block.lowerBound - previousStart
            return TextEdit(
                range: previousStart..<block.upperBound,
                replacement: blockText + "\n" + previousText,
                selectionAfter: (current.lowerBound - shift)..<(current.upperBound - shift)
            )
        }

        // Darunter gibt es keine Zeile mehr.
        guard block.upperBound < text.count else { return nil }
        let nextStart = block.upperBound + 1
        let nextEnd = text.lineEnd(after: nextStart)
        let nextText = text.string(in: nextStart..<nextEnd)
        let shift = nextEnd - block.upperBound
        // War der Zeilenumbruch nach dem Block mit ausgewählt, und der Block ist nun
        // die letzte Zeile, gibt es diesen Umbruch nicht mehr.
        let upper = min(current.upperBound + shift, text.count)
        return TextEdit(
            range: block.lowerBound..<nextEnd,
            replacement: nextText + "\n" + blockText,
            selectionAfter: (current.lowerBound + shift)..<upper
        )
    }

    // MARK: - Auskommentieren

    /// Kommentiert die Zeilen der Auswahl mit `% ` aus – oder wieder ein,
    /// wenn alle nicht leeren Zeilen bereits auskommentiert sind.
    public static func toggleComment<S: UTF16Source>(in text: S, selection: Range<Int>) -> TextEdit {
        let current = clamped(selection, in: text)
        let block = touchedLines(in: text, current)
        let lines = lineRanges(in: text, block: block)
        let filled = lines.filter { !isBlank(text, $0) }
        // Nur leere Zeilen markiert: dort einen Kommentar beginnen.
        let targets = filled.isEmpty ? lines : filled
        let uncomment = !filled.isEmpty && filled.allSatisfy { line in
            text.unit(at: skipSpaces(in: text, from: line.lowerBound, limit: line.upperBound)) == TeXChar.percent
        }

        var builder = ReplacementBuilder(start: block.lowerBound)
        for line in targets {
            let contentStart = skipSpaces(in: text, from: line.lowerBound, limit: line.upperBound)
            builder.keep(text, upTo: contentStart)
            if uncomment {
                // `% ` oder nur `%` entfernen.
                var commentEnd = contentStart + 1
                if commentEnd < line.upperBound, text[commentEnd] == TeXChar.space { commentEnd += 1 }
                builder.skip(upTo: commentEnd)
            } else {
                builder.insert("% ")
            }
        }
        builder.keep(text, upTo: block.upperBound)
        return builder.edit(selection: current)
    }

    // MARK: - Einrücken

    /// Rückt die Zeilen der Auswahl um `EditingAssistant.indentUnit` ein bzw. aus.
    public static func shiftIndentation<S: UTF16Source>(in text: S, selection: Range<Int>, outdent: Bool) -> TextEdit {
        let current = clamped(selection, in: text)
        let block = touchedLines(in: text, current)
        let lines = lineRanges(in: text, block: block)
        // Leere Zeilen bekommen keine Leerzeichen – ausser, es gibt nur leere Zeilen.
        let hasFilledLine = lines.contains { !isBlank(text, $0) }

        var builder = ReplacementBuilder(start: block.lowerBound)
        var changed = false
        for line in lines {
            if outdent {
                let cut = indentationLevelEnd(in: text, lineStart: line.lowerBound, lineEnd: line.upperBound)
                guard cut > line.lowerBound else { continue }
                builder.keep(text, upTo: line.lowerBound)
                builder.skip(upTo: cut)
                changed = true
            } else {
                guard !hasFilledLine || !isBlank(text, line) else { continue }
                builder.keep(text, upTo: line.lowerBound)
                builder.insert(EditingAssistant.indentUnit)
                changed = true
            }
        }
        // Nichts zum Ausrücken da: Text und Auswahl bleiben, wie sie sind.
        guard changed else { return unchanged(current) }
        builder.keep(text, upTo: block.upperBound)
        return builder.edit(selection: current)
    }

    // MARK: - Formel im Text ↔ abgesetzte Formel

    /// Wandelt die Formel am Cursor um: `$x$` bzw. `\(x\)` → `\[ x \]` auf eigenen Zeilen,
    /// und `\[ x \]` bzw. `$$x$$` → `$x$`. `nil`, wenn der Cursor in keiner solchen Formel steht.
    public static func toggleDisplayMath<S: UTF16Source>(in text: S, selection: Range<Int>) -> TextEdit? {
        let current = clamped(selection, in: text)
        let analysis = LaTeXTokenizer.tokenize(utf16Units(of: text))
        // Umgebungen wie `align` werden nicht umgewandelt, nur `$`, `\(`, `\[` und `$$`.
        guard let region = analysis.mathRegion(containing: current.lowerBound),
              region.isClosed, region.environment == nil,
              current.upperBound <= region.range.upperBound
        else {
            return nil
        }
        switch region.style {
        case .inline:
            return inlineToDisplay(region, in: text, selection: current)
        case .display:
            return displayToInline(region, in: text, selection: current)
        }
    }

    // MARK: - Umwandeln und Anzeigenamen

    /// Sinnvolle Zielumgebungen für „Umgebung umwandeln“, in Menü-Reihenfolge,
    /// ohne die Umgebung selbst. Unbekannt → leer.
    public static func conversions(for environment: String) -> [String] {
        guard let group = conversionGroups.first(where: { $0.contains(environment) }) else { return [] }
        return group.filter { $0 != environment }
    }

    /// Deutscher Anzeigename einer Umgebung (`align*` → „Ausgerichtete Formeln (ohne Nummer)“),
    /// sonst der Name selbst.
    public static func displayName(for environment: String) -> String {
        displayNames[environment] ?? environment
    }
}

// MARK: - Tabellen

extension BlockEditor {
    /// Formeln, deren Nummerierung sich mit einem Stern umschalten lässt.
    fileprivate static let numberedFormulas: Set<String> = {
        let names = ["equation", "align", "gather", "multline", "flalign", "alignat"]
        return Set(names + names.map { $0 + "*" })
    }()

    /// Gruppen von Umgebungen, die sich ineinander umwandeln lassen (in Menü-Reihenfolge).
    fileprivate static let conversionGroups: [[String]] = [
        ["equation", "equation*", "align", "align*", "gather", "gather*", "multline", "multline*"],
        ["itemize", "enumerate", "description"],
        ["center", "flushleft", "flushright"],
        ["definition", "satz", "lemma", "korollar", "beispiel", "bemerkung", "proof"],
        ["matrix", "pmatrix", "bmatrix", "vmatrix", "Bmatrix", "Vmatrix"],
        ["quote", "quotation"]
    ]

    /// Deutsche Namen für die Menüs.
    fileprivate static let displayNames: [String: String] = [
        // Abgesetzte Formeln
        "equation": "Formel (mit Nummer)",
        "equation*": "Formel (ohne Nummer)",
        "align": "Ausgerichtete Formeln (mit Nummer)",
        "align*": "Ausgerichtete Formeln (ohne Nummer)",
        "gather": "Zentrierte Formeln (mit Nummer)",
        "gather*": "Zentrierte Formeln (ohne Nummer)",
        "multline": "Lange Formel (mit Nummer)",
        "multline*": "Lange Formel (ohne Nummer)",
        "flalign": "Formeln über die ganze Breite (mit Nummer)",
        "flalign*": "Formeln über die ganze Breite (ohne Nummer)",
        "alignat": "Formeln mit festen Spalten (mit Nummer)",
        "alignat*": "Formeln mit festen Spalten (ohne Nummer)",
        "displaymath": "Abgesetzte Formel",
        "math": "Formel im Text",
        "eqnarray": "Formelzeilen (veraltet)",
        "eqnarray*": "Formelzeilen ohne Nummer (veraltet)",
        // Innerhalb von Formeln
        "cases": "Fallunterscheidung",
        "aligned": "Ausgerichtete Zeilen",
        "gathered": "Zentrierte Zeilen",
        "split": "Geteilte Formel",
        "array": "Feld (Tabelle in einer Formel)",
        "matrix": "Matrix ohne Klammern",
        "pmatrix": "Matrix mit runden Klammern",
        "bmatrix": "Matrix mit eckigen Klammern",
        "Bmatrix": "Matrix mit geschweiften Klammern",
        "vmatrix": "Matrix mit Strichen (Determinante)",
        "Vmatrix": "Matrix mit Doppelstrichen (Norm)",
        "smallmatrix": "Kleine Matrix",
        // Listen
        "itemize": "Aufzählung",
        "enumerate": "Nummerierte Liste",
        "description": "Begriffsliste",
        // Ausrichtung
        "center": "Zentriert",
        "flushleft": "Linksbündig",
        "flushright": "Rechtsbündig",
        // Sätze und Beweise
        "definition": "Definition",
        "satz": "Satz",
        "lemma": "Lemma",
        "korollar": "Korollar",
        "beispiel": "Beispiel",
        "bemerkung": "Bemerkung",
        "proof": "Beweis",
        "theorem": "Satz (theorem)",
        "corollary": "Korollar (corollary)",
        "example": "Beispiel (example)",
        "remark": "Bemerkung (remark)",
        "proposition": "Proposition",
        // Zitate
        "quote": "Zitat",
        "quotation": "Längeres Zitat",
        "verse": "Gedicht",
        // Gleitobjekte und Kästen
        "figure": "Abbildung",
        "figure*": "Abbildung (ganze Seitenbreite)",
        "table": "Tabelle",
        "table*": "Tabelle (ganze Seitenbreite)",
        "tabular": "Tabelleninhalt",
        "tabularx": "Tabelleninhalt (feste Breite)",
        "minipage": "Minipage",
        "multicols": "Mehrere Spalten",
        // Sonstiges
        "document": "Dokument",
        "abstract": "Zusammenfassung",
        "verbatim": "Text wie getippt (verbatim)",
        "lstlisting": "Programmcode",
        "minted": "Programmcode (minted)",
        "tikzpicture": "Zeichnung (TikZ)",
        "frame": "Folie",
        "thebibliography": "Literaturverzeichnis"
    ]

    /// Argumente, die beim Einpacken gleich mitgeschrieben werden, weil LaTeX sonst
    /// einen Fehler meldet. Eine Minipage braucht z. B. immer eine Breite.
    fileprivate static let requiredArguments: [String: String] = [
        "minipage": "{0.45\\textwidth}",
        "multicols": "{2}"
    ]

    /// Wie viele Pflichtargumente `{…}` eine Umgebung direkt nach `\begin{name}` hat
    /// (z. B. `\begin{tabular}{cc}`). Bei allen anderen gehört eine `{` schon zum Inhalt.
    fileprivate static let mandatoryArgumentCounts: [String: Int] = [
        "tabular": 1, "tabular*": 2, "tabularx": 2, "tabulary": 2, "array": 1, "longtable": 1,
        "minipage": 1, "alignat": 1, "alignat*": 1, "multicols": 1, "multicols*": 1,
        "wrapfigure": 2, "wraptable": 2, "subfigure": 1, "subtable": 1,
        "thebibliography": 1, "otherlanguage": 1, "list": 2
    ]

    /// Umgebungen ohne optionales Argument: Eine `[` dahinter ist schon Inhalt
    /// (z. B. das Intervall in `\begin{equation}[0,1] …`).
    fileprivate static let environmentsWithoutOptions: Set<String> = LaTeXTokenizer.mathEnvironments.union([
        "center", "flushleft", "flushright", "quote", "quotation", "verse", "abstract", "document",
        "matrix", "pmatrix", "bmatrix", "Bmatrix", "vmatrix", "Vmatrix", "smallmatrix", "cases", "split"
    ])
}

// MARK: - Hilfsfunktionen

extension BlockEditor {
    /// Baut den Ersatztext für einen Textbereich Stück für Stück auf: alten Text
    /// übernehmen (`keep`), weglassen (`skip`) oder neuen Text einfügen (`insert`).
    ///
    /// Nebenbei merkt er sich, wohin jede alte Position wandert. So bleibt die
    /// Auswahl nach der Änderung auf denselben Zeichen stehen – und das Ganze ist
    /// trotzdem *eine* zusammenhängende Ersetzung (ein Schritt für ⌘Z).
    fileprivate struct ReplacementBuilder {
        /// Beginn des ersetzten Bereichs im alten Text.
        let start: Int
        /// Bis hierhin ist der alte Text verarbeitet (= Ende des ersetzten Bereichs).
        private(set) var position: Int
        private var units: [UInt16] = []
        /// Übernommene bzw. weggelassene Stücke: alter Bereich und Stelle im neuen Text.
        private var pieces: [(old: Range<Int>, new: Int, kept: Bool)] = []

        init(start: Int) {
            self.start = start
            self.position = start
        }

        /// Länge des neuen Textes für den Bereich.
        var length: Int { units.count }

        /// Übernimmt den alten Text bis `end` unverändert.
        mutating func keep<S: UTF16Source>(_ text: S, upTo end: Int) {
            guard end > position else { return }
            pieces.append((position..<end, units.count, true))
            for index in position..<end { units.append(text[index]) }
            position = end
        }

        /// Lässt den alten Text bis `end` weg.
        mutating func skip(upTo end: Int) {
            guard end > position else { return }
            pieces.append((position..<end, units.count, false))
            position = end
        }

        /// Fügt neuen Text ein.
        mutating func insert(_ string: String) {
            units.append(contentsOf: string.utf16)
        }

        /// Neue Position einer alten Position. Wurde genau dort Text eingefügt,
        /// entscheidet `preferLater`, ob die Position davor oder dahinter landet.
        func map(_ old: Int, preferLater: Bool) -> Int {
            if old < start { return old }
            if old > position { return old + units.count - (position - start) }
            var options: [Int] = []
            if old == start { options.append(start) }
            for piece in pieces where piece.old.lowerBound <= old && old <= piece.old.upperBound {
                options.append(start + piece.new + (piece.kept ? old - piece.old.lowerBound : 0))
            }
            if old == position { options.append(start + units.count) }
            return (preferLater ? options.max() : options.min()) ?? start
        }

        /// Die fertige Bearbeitung. Ein Cursor wandert hinter eingefügten Text,
        /// eine Auswahl schliesst Eingefügtes an ihren Rändern mit ein.
        func edit(selection: Range<Int>) -> TextEdit {
            let after: Range<Int>
            if selection.isEmpty {
                let caret = map(selection.lowerBound, preferLater: true)
                after = caret..<caret
            } else {
                let lower = map(selection.lowerBound, preferLater: false)
                after = lower..<max(lower, map(selection.upperBound, preferLater: true))
            }
            return TextEdit(
                range: start..<position,
                replacement: String(decoding: units, as: UTF16.self),
                selectionAfter: after
            )
        }
    }

    /// Auswahl auf den Text begrenzen, damit nie ausserhalb gelesen wird.
    fileprivate static func clamped<S: UTF16Source>(_ selection: Range<Int>, in text: S) -> Range<Int> {
        let lower = min(max(0, selection.lowerBound), text.count)
        let upper = min(max(lower, selection.upperBound), text.count)
        return lower..<upper
    }

    /// Schiebt einen Bereich in die Grenzen `bounds`.
    fileprivate static func clamp(_ range: Range<Int>, to bounds: Range<Int>) -> Range<Int> {
        let lower = min(max(bounds.lowerBound, range.lowerBound), bounds.upperBound)
        let upper = min(max(lower, range.upperBound), bounds.upperBound)
        return lower..<upper
    }

    /// Eine Bearbeitung, die nichts ändert.
    fileprivate static func unchanged(_ selection: Range<Int>) -> TextEdit {
        TextEdit(range: selection.lowerBound..<selection.lowerBound, replacement: "", selectionAfter: selection)
    }

    /// Der Text als `[UInt16]` (für den `LaTeXTokenizer`).
    fileprivate static func utf16Units<S: UTF16Source>(of text: S) -> [UInt16] {
        if let units = text as? [UInt16] { return units }
        var units: [UInt16] = []
        units.reserveCapacity(text.count)
        for index in 0..<text.count { units.append(text[index]) }
        return units
    }

    fileprivate static func isSpaceOrTab(_ unit: UInt16) -> Bool {
        unit == TeXChar.space || unit == TeXChar.tab
    }

    /// Enthält der Bereich nur Leerzeichen und Tabs (oder gar nichts)?
    fileprivate static func onlySpaces<S: UTF16Source>(in text: S, _ range: Range<Int>) -> Bool {
        guard range.lowerBound < range.upperBound else { return true }
        return range.allSatisfy { isSpaceOrTab(text[$0]) }
    }

    /// Erste Position ab `start`, an der kein Leerzeichen oder Tab steht (höchstens bis `limit`).
    fileprivate static func skipSpaces<S: UTF16Source>(in text: S, from start: Int, limit: Int) -> Int {
        var index = start
        while index < limit, isSpaceOrTab(text[index]) { index += 1 }
        return index
    }

    // MARK: Zeilen

    /// Die ganzen Zeilen, die die Auswahl berührt: vom Anfang der ersten bis zum Ende
    /// der letzten Zeile (ohne deren Zeilenumbruch). Endet eine Auswahl am Anfang
    /// einer Zeile, gehört diese Zeile nicht mehr dazu.
    fileprivate static func touchedLines<S: UTF16Source>(in text: S, _ selection: Range<Int>) -> Range<Int> {
        let start = text.lineStart(before: selection.lowerBound)
        var last = selection.upperBound
        if !selection.isEmpty, text.unit(at: last - 1) == TeXChar.newline { last -= 1 }
        return start..<text.lineEnd(after: max(start, last))
    }

    /// Die einzelnen Zeilen eines Zeilenblocks (jeweils ohne Zeilenumbruch).
    fileprivate static func lineRanges<S: UTF16Source>(in text: S, block: Range<Int>) -> [Range<Int>] {
        var lines: [Range<Int>] = []
        var lineStart = block.lowerBound
        while true {
            let lineEnd = min(text.lineEnd(after: lineStart), block.upperBound)
            lines.append(lineStart..<lineEnd)
            guard lineEnd < block.upperBound else { break }
            lineStart = lineEnd + 1
        }
        return lines
    }

    /// Besteht die Zeile nur aus Leerraum?
    fileprivate static func isBlank<S: UTF16Source>(_ text: S, _ line: Range<Int>) -> Bool {
        line.allSatisfy { TeXChar.isWhitespace(text[$0]) }
    }

    /// Besteht die Zeile, in der `position` liegt, nur aus Leerraum?
    fileprivate static func isBlankLine<S: UTF16Source>(in text: S, containing position: Int) -> Bool {
        let lineStart = text.lineStart(before: position)
        return isBlank(text, lineStart..<text.lineEnd(after: lineStart))
    }

    /// Ende einer Einrückungsebene am Zeilenanfang: ein Tab oder bis zu zwei Leerzeichen.
    fileprivate static func indentationLevelEnd<S: UTF16Source>(in text: S, lineStart: Int, lineEnd: Int) -> Int {
        if lineStart < lineEnd, text[lineStart] == TeXChar.tab { return lineStart + 1 }
        var index = lineStart
        while index < lineEnd, index - lineStart < 2, text[index] == TeXChar.space { index += 1 }
        return index
    }

    /// Ganze Zeile samt Zeilenumbruch (danach, oder davor bei der letzten Zeile).
    fileprivate static func wholeLine<S: UTF16Source>(in text: S, from lineStart: Int, to lineEnd: Int) -> Range<Int> {
        if lineEnd < text.count { return lineStart..<(lineEnd + 1) }
        if lineStart > 0 { return (lineStart - 1)..<lineEnd }
        return lineStart..<lineEnd
    }

    /// Steht bei `index` der Befehl `\item` (nicht z. B. `\itemsep`)?
    fileprivate static func startsWithItem<S: UTF16Source>(_ text: S, at index: Int) -> Bool {
        guard text.matches("\\item", at: index) else { return false }
        guard let next = text.unit(at: index + 5) else { return true }
        return !TeXChar.isASCIILetter(next)
    }

    // MARK: Block auswählen

    /// Das Wort, in dem die Auswahl liegt (bei Befehlen samt Backslash, z. B. `\frac`).
    fileprivate static func wordRange<S: UTF16Source>(in text: S, around selection: Range<Int>) -> Range<Int>? {
        guard selection.allSatisfy({ TeXChar.isAlphanumeric(text[$0]) }) else { return nil }
        var lower = selection.lowerBound
        var upper = selection.upperBound
        while lower > 0, TeXChar.isAlphanumeric(text[lower - 1]) { lower -= 1 }
        while upper < text.count, TeXChar.isAlphanumeric(text[upper]) { upper += 1 }
        guard lower < upper else { return nil }
        if lower > 0, text[lower - 1] == TeXChar.backslash, !text.isEscaped(at: lower - 1),
           TeXChar.isASCIILetter(text[lower]) {
            lower -= 1
        }
        return lower..<upper
    }

    /// Inhalte aller geschweiften Klammern `{…}`, die die Auswahl umschliessen.
    /// Die Klammern kommen vom Tokenizer – Kommentare, `\{` und `verbatim` zählen also nicht.
    fileprivate static func braceContents(
        in units: [UInt16], tokens: [HighlightToken], enclosing selection: Range<Int>
    ) -> [Range<Int>] {
        var openBraces: [Int] = []
        var result: [Range<Int>] = []
        for token in tokens where token.kind == .brace {
            let index = token.location
            if units[index] == TeXChar.braceOpen {
                openBraces.append(index)
            } else if let open = openBraces.popLast(), open < selection.lowerBound, index >= selection.upperBound {
                result.append((open + 1)..<index)
            }
        }
        return result
    }

    /// Alle Umgebungen um die Auswahl, von innen nach aussen.
    fileprivate static func enclosingEnvironments<S: UTF16Source>(
        in text: S, around selection: Range<Int>
    ) -> [EnvironmentBlock] {
        var result: [EnvironmentBlock] = []
        let starts = selection.isEmpty ? [selection.lowerBound] : [selection.lowerBound, selection.upperBound]
        for start in starts {
            var position = start
            // Jede äussere Umgebung beginnt vor der inneren: Die Schleife endet sicher.
            while let environment = enclosingEnvironment(in: text, at: position) {
                if result.contains(where: { $0.range == environment.range }) { break }
                result.append(environment)
                position = environment.range.lowerBound
            }
        }
        return result
    }

    /// Die Umgebung `document` (die `enclosingEnvironment` absichtlich nie liefert).
    fileprivate static func documentEnvironment<S: UTF16Source>(in text: S) -> EnvironmentBlock? {
        var index = 0
        while index < text.count {
            let unit = text[index]
            if unit == TeXChar.percent, !text.isEscaped(at: index) {
                index = text.lineEnd(after: index)
                continue
            }
            if unit == TeXChar.backslash, !text.isEscaped(at: index), let token = environmentToken(in: text, at: index) {
                if token.isBegin, token.name == "document" {
                    guard let end = findEnd(of: "document", in: text, from: token.range.upperBound) else { return nil }
                    return EnvironmentBlock(
                        name: "document",
                        range: token.range.lowerBound..<end.upperBound,
                        beginRange: token.range,
                        endRange: end,
                        contentRange: token.range.upperBound..<end.lowerBound
                    )
                }
                index = token.range.upperBound
                continue
            }
            index += 1
        }
        return nil
    }

    /// Inhalt einer Umgebung ohne Argumente wie `[htbp]` oder `{cc}` am Anfang.
    fileprivate static func innerContent<S: UTF16Source>(of environment: EnvironmentBlock, in text: S) -> Range<Int> {
        let content = environment.contentRange
        let start = argumentsEnd(of: environment.name, in: text, from: content.lowerBound, limit: content.upperBound)
        return start..<content.upperBound
    }

    /// Absatz (durch Leerzeilen begrenzt) um die Auswahl; `nil` auf einer Leerzeile.
    fileprivate static func paragraphRange<S: UTF16Source>(in text: S, around selection: Range<Int>) -> Range<Int>? {
        guard !isBlankLine(in: text, containing: selection.lowerBound),
              !isBlankLine(in: text, containing: selection.upperBound)
        else {
            return nil
        }
        let start = EditingAssistant.paragraphStart(text, before: selection.lowerBound)
        let end = EditingAssistant.paragraphEnd(text, after: selection.upperBound)
        return start..<max(start, end)
    }

    /// Bereich ohne Leerraum am Anfang und Ende. Beginnt der Inhalt auf einer eigenen
    /// Zeile, gehört deren Einrückung dazu – so wirkt die Auswahl wie ganze Zeilen.
    fileprivate static func trimmedBlock<S: UTF16Source>(in text: S, _ range: Range<Int>) -> Range<Int> {
        var lower = range.lowerBound
        var upper = range.upperBound
        while lower < upper, TeXChar.isWhitespace(text[lower]) { lower += 1 }
        // Ein maskiertes Leerzeichen (`\ `) ist Inhalt und bleibt.
        while upper > lower, TeXChar.isWhitespace(text[upper - 1]), !text.isEscaped(at: upper - 1) { upper -= 1 }
        let lineStart = text.lineStart(before: lower)
        if lower < upper, lineStart >= range.lowerBound { lower = lineStart }
        return lower..<upper
    }

    // MARK: Umgebungen

    /// Ersetzt den Namen in `\begin{name}` bzw. `\end{name}`. Gleiche Anfangs- und
    /// Endbuchstaben bleiben stehen (`align` → `align*` fügt nur den Stern ein),
    /// damit ein Cursor im Namen an seiner Stelle bleibt.
    fileprivate static func replaceName<S: UTF16Source>(
        in token: (isBegin: Bool, name: String, range: Range<Int>),
        with newName: String,
        text: S,
        builder: inout ReplacementBuilder
    ) {
        let old = Array(token.name.utf16)
        let new = Array(newName.utf16)
        let nameEnd = token.range.upperBound - 1
        let nameStart = nameEnd - old.count
        var prefix = 0
        while prefix < old.count, prefix < new.count, old[prefix] == new[prefix] { prefix += 1 }
        var suffix = 0
        while suffix < old.count - prefix, suffix < new.count - prefix,
              old[old.count - 1 - suffix] == new[new.count - 1 - suffix] {
            suffix += 1
        }
        builder.keep(text, upTo: nameStart + prefix)
        builder.skip(upTo: nameEnd - suffix)
        builder.insert(String(decoding: new[prefix..<(new.count - suffix)], as: UTF16.self))
    }

    /// Ende der Argumente direkt nach `\begin{name}`: optionale `[…]` und so viele
    /// `{…}`, wie die Umgebung verlangt (z. B. `figure[htbp]`, `tabular{cc}`).
    fileprivate static func argumentsEnd<S: UTF16Source>(of name: String, in text: S, from start: Int, limit: Int) -> Int {
        var mandatory = mandatoryArgumentCounts[name] ?? 0
        let takesOptions = !environmentsWithoutOptions.contains(name)
        var end = start
        while end < limit {
            let next = skipSpaces(in: text, from: end, limit: limit)
            guard next < limit else { break }
            if takesOptions, text[next] == TeXChar.bracketOpen,
               let close = groupClose(in: text, openingAt: next, limit: limit) {
                end = close + 1
            } else if mandatory > 0, text[next] == TeXChar.braceOpen,
                      let close = groupClose(in: text, openingAt: next, limit: limit) {
                mandatory -= 1
                end = close + 1
            } else {
                break
            }
        }
        return end
    }

    /// Position der schliessenden Klammer zu `[` bzw. `{` bei `start`. Geschweifte
    /// Klammern darin werden mitgezählt, Kommentare und `\]`, `\}` übersprungen.
    fileprivate static func groupClose<S: UTF16Source>(in text: S, openingAt start: Int, limit: Int) -> Int? {
        let isBracket = text[start] == TeXChar.bracketOpen
        var depth = 0
        var index = start + 1
        while index < limit {
            let unit = text[index]
            if text.isEscaped(at: index) {
                index += 1
                continue
            }
            switch unit {
            case TeXChar.percent:
                index = text.lineEnd(after: index)
                continue
            case TeXChar.braceOpen:
                depth += 1
            case TeXChar.braceClose:
                if depth == 0 { return isBracket ? nil : index }
                depth -= 1
            case TeXChar.bracketClose where isBracket && depth == 0:
                return index
            default:
                break
            }
            index += 1
        }
        return nil
    }

    /// Inhalte wörtlicher Umgebungen (`verbatim`, `lstlisting` …) innerhalb von `range`.
    fileprivate static func verbatimContents<S: UTF16Source>(in text: S, within range: Range<Int>) -> [Range<Int>] {
        var result: [Range<Int>] = []
        var index = range.lowerBound
        while index < range.upperBound {
            let unit = text[index]
            if unit == TeXChar.percent, !text.isEscaped(at: index) {
                index = text.lineEnd(after: index)
                continue
            }
            if unit == TeXChar.backslash, !text.isEscaped(at: index), let token = environmentToken(in: text, at: index) {
                if token.isBegin, LaTeXTokenizer.verbatimEnvironments.contains(token.name),
                   let end = findEnd(of: token.name, in: text, from: token.range.upperBound) {
                    result.append(token.range.upperBound..<end.lowerBound)
                    index = end.upperBound
                } else {
                    index = token.range.upperBound
                }
                continue
            }
            index += 1
        }
        return result
    }

    /// Leere Umgebung an der Cursorposition, auf eigenen Zeilen. Steht in der Zeile
    /// schon Text, wird er davor bzw. danach umbrochen.
    fileprivate static func emptyEnvironment<S: UTF16Source>(
        at position: Int, in text: S, beginLine: String, endLine: String, innerLine: String
    ) -> TextEdit {
        let lineStart = text.lineStart(before: position)
        let lineEnd = text.lineEnd(after: position)
        let indent = EditingAssistant.leadingWhitespace(text, lineContaining: position)
        // Leerzeichen um den Cursor fallen weg, damit keine am Zeilenende übrig bleiben.
        var start = position
        while start > lineStart, isSpaceOrTab(text[start - 1]) { start -= 1 }
        let end = skipSpaces(in: text, from: position, limit: lineEnd)
        let prefix = start > lineStart ? "\n" : ""
        let suffix = end < lineEnd ? "\n" + indent : ""
        let upToCursor = prefix + indent + beginLine + "\n" + indent + innerLine
        let replacement = upToCursor + "\n" + indent + endLine + suffix
        let caret = start + upToCursor.utf16.count
        return TextEdit(range: start..<end, replacement: replacement, selectionAfter: caret..<caret)
    }

    // MARK: Formeln

    /// Satzzeichen, die bei abgesetzten Formeln in die Formel gehören (`\[ x = 1. \]`).
    fileprivate static func isFormulaPunctuation(_ unit: UInt16) -> Bool {
        unit == 0x2E || unit == 0x2C || unit == 0x3B // . , ;
    }

    /// `$x$` bzw. `\(x\)` → `\[ x \]` auf einer eigenen Zeile.
    fileprivate static func inlineToDisplay<S: UTF16Source>(
        _ region: MathRegion, in text: S, selection: Range<Int>
    ) -> TextEdit {
        let content = trimmedFormula(in: text, region.contentRange)
        // Ein Satzzeichen direkt nach der Formel wandert mit hinein: „$x$.“ → „\[ x. \]“.
        var formulaEnd = region.range.upperBound
        if let next = text.unit(at: formulaEnd), isFormulaPunctuation(next),
           text.unit(at: formulaEnd + 1).map(TeXChar.isWhitespace) ?? true {
            formulaEnd += 1
        }
        let punctuation = text.string(in: region.range.upperBound..<formulaEnd)

        // Die Formel kommt auf eine eigene Zeile, mit der Einrückung der aktuellen Zeile.
        let lineStart = text.lineStart(before: region.range.lowerBound)
        let lineEnd = text.lineEnd(after: formulaEnd)
        let indent = EditingAssistant.leadingWhitespace(text, lineContaining: region.range.lowerBound)
        var start = region.range.lowerBound
        while start > lineStart, isSpaceOrTab(text[start - 1]) { start -= 1 }
        let end = skipSpaces(in: text, from: formulaEnd, limit: lineEnd)
        let prefix = start > lineStart ? "\n" : ""
        let suffix = end < lineEnd ? "\n" + indent : ""

        let opening = prefix + indent + "\\[ "
        var builder = ReplacementBuilder(start: start)
        builder.skip(upTo: content.lowerBound)
        builder.insert(opening)
        builder.keep(text, upTo: content.upperBound)
        builder.skip(upTo: end)
        let closing = punctuation + " \\]" + suffix
        builder.insert(closing)

        // Cursor und Auswahl bleiben im Formelinhalt.
        var edit = builder.edit(selection: selection)
        let newContentStart = start + opening.utf16.count
        edit.selectionAfter = clamp(edit.selectionAfter, to: newContentStart..<(newContentStart + content.count))
        return edit
    }

    /// `\[ x \]` bzw. `$$x$$` → `$x$`. Zeilenumbrüche und mehrfacher Leerraum werden
    /// zu einem Leerzeichen, denn eine Formel im Text steht in einer Zeile.
    fileprivate static func displayToInline<S: UTF16Source>(
        _ region: MathRegion, in text: S, selection: Range<Int>
    ) -> TextEdit {
        var content = trimmedFormula(in: text, region.contentRange)
        // Ein Satzzeichen am Ende kommt hinter die Formel: „\[ x. \]“ → „$x$.“
        var punctuation = ""
        if content.count > 1, isFormulaPunctuation(text[content.upperBound - 1]),
           !text.isEscaped(at: content.upperBound - 1) {
            punctuation = text.string(in: (content.upperBound - 1)..<content.upperBound)
            var upper = content.upperBound - 1
            while upper > content.lowerBound, TeXChar.isWhitespace(text[upper - 1]), !text.isEscaped(at: upper - 1) {
                upper -= 1
            }
            content = content.lowerBound..<upper
        }

        var builder = ReplacementBuilder(start: region.range.lowerBound)
        builder.skip(upTo: content.lowerBound)
        builder.insert("$")
        var index = content.lowerBound
        while index < content.upperBound {
            let unit = text[index]
            if unit == TeXChar.percent, !text.isEscaped(at: index) {
                // Ein Kommentar reicht bis zum Zeilenende. Danach muss ein Zeilenumbruch
                // bleiben, sonst wäre der Rest der Formel (und das `$`) auskommentiert.
                let commentEnd = min(text.lineEnd(after: index), content.upperBound)
                builder.keep(text, upTo: commentEnd)
                var next = commentEnd
                while next < content.upperBound, TeXChar.isWhitespace(text[next]) { next += 1 }
                builder.skip(upTo: next)
                builder.insert("\n")
                index = next
            } else if TeXChar.isWhitespace(unit), !text.isEscaped(at: index) {
                var next = index
                while next < content.upperBound, TeXChar.isWhitespace(text[next]) { next += 1 }
                builder.skip(upTo: next)
                builder.insert(" ")
                index = next
            } else {
                builder.keep(text, upTo: index + 1)
                index += 1
            }
        }
        builder.skip(upTo: region.range.upperBound)
        // Leere Formel: `$ $` statt `$$` (das wäre eine abgesetzte Formel).
        let closing = (content.isEmpty ? " $" : "$") + punctuation
        builder.insert(closing)

        var edit = builder.edit(selection: selection)
        let newContentStart = region.range.lowerBound + 1
        let newContentEnd = region.range.lowerBound + builder.length - closing.utf16.count
        edit.selectionAfter = clamp(edit.selectionAfter, to: newContentStart..<newContentEnd)
        return edit
    }

    /// Formelinhalt ohne Leerraum am Anfang und Ende. Endet die letzte Zeile mit einem
    /// Kommentar, bleibt ihr Zeilenumbruch erhalten – sonst wäre das Formelende auskommentiert.
    fileprivate static func trimmedFormula<S: UTF16Source>(in text: S, _ range: Range<Int>) -> Range<Int> {
        var lower = range.lowerBound
        var upper = range.upperBound
        while lower < upper, TeXChar.isWhitespace(text[lower]) { lower += 1 }
        while upper > lower, TeXChar.isWhitespace(text[upper - 1]), !text.isEscaped(at: upper - 1) { upper -= 1 }
        let lastLineStart = max(lower, text.lineStart(before: upper))
        if let comment = text.commentStart(inLineStartingAt: lastLineStart), comment < upper,
           upper < range.upperBound {
            upper = min(text.lineEnd(after: upper) + 1, range.upperBound)
        }
        return lower..<upper
    }
}
