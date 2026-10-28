import Foundation

/// Ränder und Zeilenabstand nur für einen Teil des Dokuments, z. B. „nur diese Seite“.
///
/// - Ränder: `\newgeometry{…}` vor und `\restoregeometry` nach dem Bereich. Beides
///   beginnt eine neue Seite – genau das Verhalten, das man von „nur diese Seite“
///   erwartet. Ist geometry noch nicht geladen, kommt `\usepackage[pass]{geometry}`
///   in die Präambel: `pass` lässt die Ränder des übrigen Dokuments unverändert.
/// - Zeilenabstand: eine Umgebung von setspace um den Bereich
///   (`onehalfspace`, `doublespace`, `spacing{1.3}`, `singlespace`).
///
/// Der Bereich besteht immer aus ganzen Zeilen und schneidet keine Umgebung
/// oder Formel entzwei. Wird derselbe Bereich erneut eingestellt, ersetzt Lemma
/// die vorhandenen Zeilen, statt neue zu stapeln.
public enum LocalLayout {
    public static let geometryRequirement = PackageRequirement("geometry", options: "pass")
    public static let setspaceRequirement = PackageRequirement("setspace")

    /// Umgebungen von setspace, mit denen Lemma den Abstand eines Bereichs setzt.
    public static let spacingEnvironments = ["singlespace", "onehalfspace", "doublespace", "spacing"]

    // MARK: - Bereich bestimmen

    /// Bereich für die Zeilen `lines` (1-basiert, z. B. aus SyncTeX für eine PDF-Seite):
    /// die ganzen Absätze, zu denen diese Zeilen gehören.
    public static func region<S: UTF16Source>(in text: S, lines: ClosedRange<Int>) -> Range<Int>? {
        let index = LineIndex(units(of: text))
        guard let first = index.range(ofLine: max(1, lines.lowerBound)),
              let last = index.range(ofLine: min(lines.upperBound, index.lineCount)) else { return nil }
        let paragraphs = expandedToParagraphs(first.lowerBound..<min(last.upperBound + 1, text.count), in: text)
        return snapped(paragraphs, in: text)
    }

    /// Bereich um eine Auswahl (ganze Zeilen) bzw. – ohne Auswahl – den Absatz am Cursor.
    public static func region<S: UTF16Source>(in text: S, around selection: Range<Int>) -> Range<Int>? {
        let start = text.lineStart(before: selection.lowerBound)
        let end = min(text.lineEnd(after: max(selection.lowerBound, selection.upperBound - 1)) + 1, text.count)
        let lines = start..<max(start, end)
        return snapped(selection.isEmpty ? expandedToParagraphs(lines, in: text) : lines, in: text)
    }

    /// Erweitert ganze Zeilen bis zur nächsten Leerzeile (bzw. Überschrift) nach oben und unten.
    static func expandedToParagraphs<S: UTF16Source>(_ lines: Range<Int>, in text: S) -> Range<Int> {
        var start = lines.lowerBound
        var end = lines.upperBound
        while start > 0 {
            let previous = text.lineStart(before: start - 1)
            if isBlankLine(text, from: previous) || isStructuralLine(text, from: previous) { break }
            start = previous
        }
        while end < text.count, !isBlankLine(text, from: end), !isStructuralLine(text, from: end) {
            end = min(text.lineEnd(after: end) + 1, text.count)
        }
        return start..<end
    }

    /// Erweitert den Bereich, bis er keine Umgebung und keine Formel mehr teilt,
    /// und begrenzt ihn auf den Textteil.
    static func snapped<S: UTF16Source>(_ range: Range<Int>, in text: S) -> Range<Int>? {
        var start = range.lowerBound
        var end = range.upperBound
        let analysis = LaTeXTokenizer.tokenize(units(of: text))
        for _ in 0..<64 {
            var changed = false
            for position in [start, max(start, end - 1)] {
                if let block = BlockEditor.enclosingEnvironment(in: text, at: position),
                   block.range.lowerBound < start || block.range.upperBound > end {
                    start = min(start, text.lineStart(before: block.range.lowerBound))
                    end = max(end, min(text.lineEnd(after: block.range.upperBound) + 1, text.count))
                    changed = true
                }
                if let region = analysis.mathRegion(containing: position), region.style == .display,
                   region.range.lowerBound < start || region.range.upperBound > end {
                    start = min(start, text.lineStart(before: region.range.lowerBound))
                    end = max(end, min(text.lineEnd(after: region.range.upperBound) + 1, text.count))
                    changed = true
                }
            }
            if !changed { break }
        }
        if let body = InsertionPlanner.bodyRange(in: text) {
            start = max(start, body.lowerBound)
            end = min(end, body.upperBound)
        }
        guard start < end else { return nil }
        return start..<end
    }

    // MARK: - Ränder

    /// Ränder nur für `region`. `.standard` entfernt eine vorhandene Einstellung.
    /// `nil`, wenn sich nichts ändert.
    public static func margins<S: UTF16Source>(_ margins: PageMargins, region: Range<Int>, in text: S) -> TextEdit? {
        let opening = margins.geometryOptions.map { "\\newgeometry{\($0)}" }
        return wrap(
            region: region,
            in: text,
            opening: opening,
            closing: opening == nil ? nil : "\\restoregeometry",
            isOpening: { $0.hasPrefix("\\newgeometry{") },
            isClosing: { $0.hasPrefix("\\restoregeometry") }
        )
    }

    // MARK: - Zeilenabstand

    /// Zeilenabstand nur für `region`. `nil`, wenn sich nichts ändert.
    public static func spacing<S: UTF16Source>(_ spacing: LineSpacing, region: Range<Int>, in text: S) -> TextEdit? {
        let environment: String
        switch spacing {
        case .single: environment = "\\begin{singlespace}"
        case .onehalf: environment = "\\begin{onehalfspace}"
        case .double: environment = "\\begin{doublespace}"
        case .custom(let value): environment = "\\begin{spacing}{\(latexNumber(value))}"
        }
        let name = environment.dropFirst("\\begin{".count).prefix { $0 != "}" }
        return wrap(
            region: region,
            in: text,
            opening: environment,
            closing: "\\end{\(name)}",
            isOpening: { line in spacingEnvironments.contains { line.hasPrefix("\\begin{\($0)}") } },
            isClosing: { line in spacingEnvironments.contains { line.hasPrefix("\\end{\($0)}") } }
        )
    }

    // MARK: - Gemeinsamer Teil

    /// Setzt `opening`/`closing` als eigene Zeilen um den Bereich. Steht dort schon ein
    /// passendes Paar (direkt davor/danach oder als erste/letzte Zeile), wird es ersetzt
    /// bzw. – mit `opening == nil` – entfernt.
    private static func wrap<S: UTF16Source>(
        region: Range<Int>,
        in text: S,
        opening: String?,
        closing: String?,
        isOpening: (String) -> Bool,
        isClosing: (String) -> Bool
    ) -> TextEdit? {
        var start = region.lowerBound
        var end = region.upperBound
        // Vorhandenes Paar suchen: erste/letzte Zeile des Bereichs oder die Zeile davor/danach.
        let firstLine = line(in: text, startingAt: start)
        let lastLineStart = text.lineStart(before: max(start, end - 1))
        let lastLine = line(in: text, startingAt: lastLineStart)
        var hasPair = false
        if isOpening(firstLine.code), isClosing(lastLine.code), lastLineStart > start {
            hasPair = true
        } else if start > 0 {
            let previousStart = text.lineStart(before: start - 1)
            let previous = line(in: text, startingAt: previousStart)
            let next = end < text.count ? line(in: text, startingAt: end) : nil
            if isOpening(previous.code), let next, isClosing(next.code) {
                start = previousStart
                end = min(next.range.upperBound + 1, text.count)
                hasPair = true
            }
        }

        let newline = "\n"
        let indent = String(firstLine.text.prefix { $0 == " " || $0 == "\t" })
        var inner: String
        if hasPair {
            // Inhalt ohne die alten Zeilen.
            let lines = text.string(in: start..<end).components(separatedBy: newline)
            var content = Array(lines)
            if content.last == "" { content.removeLast() }
            content.removeFirst()
            if !content.isEmpty { content.removeLast() }
            inner = content.joined(separator: newline) + (content.isEmpty ? "" : newline)
        } else {
            guard opening != nil else { return nil }
            inner = text.string(in: start..<end)
            if !inner.hasSuffix(newline) { inner += newline }
        }

        var replacement = inner
        if let opening, let closing {
            replacement = indent + opening + newline + inner + indent + closing + newline
        }
        let original = text.string(in: start..<end)
        guard replacement != original else { return nil }
        // Ohne Zeilenumbruch am Textende keinen zusätzlichen anhängen.
        if end == text.count, !original.hasSuffix(newline), replacement.hasSuffix(newline) {
            replacement.removeLast()
        }
        let cursor = start + (opening.map { indent.utf16.count + $0.utf16.count + 1 } ?? 0)
        return TextEdit(range: start..<end, replacement: replacement, selectionAfter: cursor..<cursor)
    }

    private static func line<S: UTF16Source>(in text: S, startingAt start: Int) -> (text: String, code: String, range: Range<Int>) {
        let end = text.lineEnd(after: start)
        let string = text.string(in: start..<end)
        var code = string
        if let comment = text.commentStart(inLineStartingAt: start), comment < end {
            code = text.string(in: start..<comment)
        }
        return (string, code.trimmingCharacters(in: .whitespaces), start..<end)
    }

    private static func isBlankLine<S: UTF16Source>(_ text: S, from start: Int) -> Bool {
        let end = text.lineEnd(after: start)
        return (start..<end).allSatisfy { TeXChar.isWhitespace(text[$0]) }
    }

    /// Zeilen, die einen Absatz begrenzen (Überschriften, \begin/\end der Seite).
    private static func isStructuralLine<S: UTF16Source>(_ text: S, from start: Int) -> Bool {
        let code = line(in: text, startingAt: start).code
        return ["\\begin{document}", "\\end{document}", "\\section", "\\subsection", "\\chapter", "\\newgeometry", "\\restoregeometry", "\\newpage", "\\clearpage"]
            .contains { code.hasPrefix($0) }
    }

    private static func units<S: UTF16Source>(of text: S) -> [UInt16] {
        (0..<text.count).map { text[$0] }
    }
}
