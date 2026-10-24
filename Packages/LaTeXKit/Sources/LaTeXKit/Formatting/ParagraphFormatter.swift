import Foundation

/// Absatzstile wie in Word („Überschrift 1“ …).
public enum ParagraphStyle: String, CaseIterable, Sendable, Identifiable {
    case body
    case heading1
    case heading2
    case heading3
    case heading4

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .body: return "Text"
        case .heading1: return "Überschrift 1"
        case .heading2: return "Überschrift 2"
        case .heading3: return "Überschrift 3"
        case .heading4: return "Überschrift 4"
        }
    }
}

/// Welche LaTeX-Befehle hinter „Überschrift 1–4“ stehen – abhängig von der Dokumentklasse.
public enum HeadingScheme: Sendable, Equatable {
    /// article, scrartcl …: 1 = \section, 2 = \subsection, 3 = \subsubsection, 4 = \paragraph
    case article
    /// report, book, scrreprt, scrbook …: 1 = \chapter, 2 = \section, 3 = \subsection, 4 = \subsubsection
    case book

    /// Liest `\documentclass{…}` aus dem Text; unbekannt → `.article`.
    public static func detect<S: UTF16Source>(in text: S) -> HeadingScheme {
        guard let name = documentClassName(in: text) else { return .article }
        return chapterClasses.contains(name) ? .book : .article
    }

    /// Befehlsname ohne Backslash; `nil` für `.body`.
    public func command(for style: ParagraphStyle) -> String? {
        switch (self, style) {
        case (_, .body): return nil
        case (.article, .heading1): return "section"
        case (.article, .heading2): return "subsection"
        case (.article, .heading3): return "subsubsection"
        case (.article, .heading4): return "paragraph"
        case (.book, .heading1): return "chapter"
        case (.book, .heading2): return "section"
        case (.book, .heading3): return "subsection"
        case (.book, .heading4): return "subsubsection"
        }
    }
}

/// Absatzausrichtung über die Umgebungen `flushleft`, `center`, `flushright`.
public enum TextAlignment: String, CaseIterable, Sendable, Identifiable {
    /// Standard (Blocksatz bzw. linksbündig) – keine Umgebung.
    case standard
    case left
    case center
    case right

    public var id: String { rawValue }

    /// Umgebung, `nil` für `.standard`.
    public var environment: String? {
        switch self {
        case .standard: return nil
        case .left: return "flushleft"
        case .center: return "center"
        case .right: return "flushright"
        }
    }

    public var title: String {
        switch self {
        case .standard: return "Blocksatz"
        case .left: return "Linksbündig"
        case .center: return "Zentriert"
        case .right: return "Rechtsbündig"
        }
    }

    public var symbol: String {
        switch self {
        case .standard: return "text.justify"
        case .left: return "text.alignleft"
        case .center: return "text.aligncenter"
        case .right: return "text.alignright"
        }
    }
}

/// Listenarten.
public enum ListKind: String, CaseIterable, Sendable, Identifiable {
    case itemize
    case enumerate

    public var id: String { rawValue }
    public var environment: String { rawValue }

    public var title: String {
        switch self {
        case .itemize: return "Aufzählung"
        case .enumerate: return "Nummerierte Liste"
        }
    }

    public var symbol: String {
        switch self {
        case .itemize: return "list.bullet"
        case .enumerate: return "list.number"
        }
    }
}

/// Absatzformat an der Cursorposition (für die Format-Leiste).
public struct ParagraphState: Equatable, Sendable {
    public var style: ParagraphStyle
    public var alignment: TextAlignment
    /// Innerste Liste, in der der Cursor steht.
    public var list: ListKind?

    public init(style: ParagraphStyle = .body, alignment: TextAlignment = .standard, list: ListKind? = nil) {
        self.style = style
        self.alignment = alignment
        self.list = list
    }
}


/// Absatzformatierung: Überschriften, Ausrichtung, Listen.
public enum ParagraphFormatter {
    /// Zustand für die Zeile mit dem Cursor bzw. der Auswahl.
    public static func state<S: UTF16Source>(in text: S, selection: Range<Int>, scheme: HeadingScheme) -> ParagraphState {
        let selection = FormattingText.clamp(selection, in: text)
        var state = ParagraphState()
        let line = SourceLine(text, containing: selection.lowerBound)
        if let heading = headingLine(text, containing: line)?.heading {
            state.style = headingStyle(for: heading.name, in: scheme) ?? .body
        }
        let probe = environmentProbe(text, at: selection.lowerBound)
        if let block = BlockEditor.enclosingEnvironment(in: text, at: probe, named: alignmentEnvironments) {
            state.alignment = TextAlignment.allCases.first { $0.environment == block.name } ?? .standard
        }
        if let block = BlockEditor.enclosingEnvironment(in: text, at: probe, named: listEnvironments) {
            state.list = ListKind(rawValue: block.name)
        }
        return state
    }

    /// Macht die aktuelle Zeile zur Überschrift (`\section{Zeilentext}`), ändert die Ebene
    /// oder macht sie wieder zu normalem Text. Sternform und `\label{…}` bleiben erhalten.
    public static func apply<S: UTF16Source>(_ style: ParagraphStyle, in text: S, selection: Range<Int>, scheme: HeadingScheme) -> TextEdit {
        let selection = FormattingText.clamp(selection, in: text)
        // In der Präambel gibt es keine Überschriften.
        guard !isInPreamble(text, at: selection.lowerBound) else { return FormattingText.noChange(selection) }
        var target = selectedLines(text, selection)
        // Steht der Cursor in der zweiten Zeile eines umbrochenen Titels, gehört die
        // Überschrift ab ihrer ersten Zeile dazu.
        if let found = headingLine(text, containing: SourceLine(text, containing: target.lowerBound)) {
            target = min(target.lowerBound, found.line.range.lowerBound)..<target.upperBound
        }
        let command = scheme.command(for: style)
        // Abgesetzte Formeln (`\[ … \]`, `equation` …): Dort hat eine Überschrift nichts verloren.
        let displayMath = command == nil ? [] : displayMathRanges(text)
        var builder = FormattingEditBuilder(range: target)
        var changed = false
        var sawText = false
        var end = target.upperBound
        var position = target.lowerBound
        while true {
            if position > target.lowerBound { builder.copy((position - 1)..<position, from: text) }
            let line = SourceLine(text, containing: position)
            var lineEnd = line.range.upperBound
            if line.hasCode { sawText = true }

            if let heading = HeadingLine(text, line) {
                // Eine Überschrift kann über mehrere Zeilen gehen: alle gehören dazu.
                lineEnd = heading.end
                if let command, heading.name != command {
                    // Andere Ebene: nur den Befehlsnamen tauschen (Stern, Titel, \label bleiben).
                    builder.copy(line.range.lowerBound..<heading.nameRange.lowerBound, from: text)
                    builder.insert(command)
                    builder.copy(heading.nameRange.upperBound..<lineEnd, from: text, preferred: true)
                    changed = true
                } else if command == nil, headingStyle(for: heading.name, in: scheme) != nil {
                    // Zurück zu Text: Titel und alles danach (z. B. \label) bleiben.
                    builder.copy(line.range.lowerBound..<line.indentEnd, from: text)
                    builder.copy(heading.title, from: text, preferred: true)
                    if FormattingText.endsWithControlWord(text, at: heading.title.upperBound, notBefore: heading.title.lowerBound),
                       heading.afterTitle < lineEnd, TeXChar.isASCIILetter(text[heading.afterTitle]) {
                        builder.insert("{}")
                    }
                    builder.copy(heading.afterTitle..<lineEnd, from: text, preferred: true)
                    changed = true
                } else {
                    builder.copy(line.range.lowerBound..<lineEnd, from: text, preferred: true)
                }
            } else if let command, line.hasCode, !isStructural(text, line),
                      FormattingText.isBalanced(text, line.indentEnd..<line.codeEnd),
                      !displayMath.contains(where: { $0.overlaps(line.indentEnd..<line.codeEnd) }),
                      BlockEditor.enclosingEnvironment(in: text, at: line.indentEnd, named: wholeBlockEnvironments) == nil {
                // Text wird Überschrift; ein Kommentar am Zeilenende bleibt draussen.
                builder.copy(line.range.lowerBound..<line.indentEnd, from: text)
                builder.insert("\\" + command + "{")
                builder.copy(line.indentEnd..<line.codeEnd, from: text, preferred: true)
                builder.insert("}")
                builder.copy(line.codeEnd..<line.range.upperBound, from: text)
                changed = true
            } else {
                builder.copy(line.range, from: text, preferred: true)
            }

            end = max(end, lineEnd)
            if lineEnd >= end || lineEnd >= text.count { break }
            position = lineEnd + 1
        }
        builder.range = target.lowerBound..<end
        if changed { return builder.edit(selection: selection) }

        // Leere Zeile: leere Überschrift einfügen, Cursor zwischen die Klammern.
        if let command, !sawText {
            let line = SourceLine(text, containing: selection.lowerBound)
            if line.isBlank,
               !displayMath.contains(where: { $0.lowerBound < line.indentEnd && line.indentEnd < $0.upperBound }),
               BlockEditor.enclosingEnvironment(in: text, at: line.indentEnd, named: wholeBlockEnvironments) == nil {
                let insertion = "\\" + command + "{}"
                let caret = line.indentEnd + insertion.utf16.count - 1
                return TextEdit(range: line.indentEnd..<line.indentEnd, replacement: insertion, selectionAfter: caret..<caret)
            }
        }
        return FormattingText.noChange(selection)
    }

    /// Richtet den Absatz bzw. die ausgewählten Zeilen aus (packt sie in `center` usw.,
    /// ändert eine bestehende Ausrichtungs-Umgebung oder entfernt sie bei `.standard`).
    public static func align<S: UTF16Source>(_ alignment: TextAlignment, in text: S, selection: Range<Int>) -> TextEdit {
        let selection = FormattingText.clamp(selection, in: text)
        guard !isInPreamble(text, at: selection.lowerBound) else { return FormattingText.noChange(selection) }
        let probe = environmentProbe(text, at: selection.lowerBound)
        if let block = BlockEditor.enclosingEnvironment(in: text, at: probe, named: alignmentEnvironments),
           selection.upperBound <= block.range.upperBound {
            guard let name = alignment.environment else {
                return removeEnvironment(block, in: text, selection: selection, removeItems: false)
            }
            guard name != block.name else { return FormattingText.noChange(selection) }
            return renameEnvironment(block, to: name, in: text, selection: selection)
        }
        guard let name = alignment.environment else { return FormattingText.noChange(selection) }
        let lines = selection.isEmpty
            ? alignmentParagraph(text, at: selection.lowerBound)
            : selectedLines(text, selection)
        guard let block = balancedLines(text, expandedToWholeBlocks(text, lines)) else {
            return FormattingText.noChange(selection)
        }
        return wrapLines(block, in: name, text: text, selection: selection, items: false)
    }

    /// Liste ein/aus/umschalten:
    /// - In einer Liste derselben Art: Liste auflösen (`\item ` entfernen).
    /// - In einer Liste der anderen Art: Art wechseln (`itemize` ↔ `enumerate`).
    /// - Sonst: jede nicht leere ausgewählte Zeile wird ein `\item`, alles in der Umgebung.
    ///   Ohne Text: leere Liste mit einem `\item ` und Cursor dahinter.
    public static func toggleList<S: UTF16Source>(_ kind: ListKind, in text: S, selection: Range<Int>) -> TextEdit {
        let selection = FormattingText.clamp(selection, in: text)
        guard !isInPreamble(text, at: selection.lowerBound) else { return FormattingText.noChange(selection) }
        let probe = environmentProbe(text, at: selection.lowerBound)
        if let list = BlockEditor.enclosingEnvironment(in: text, at: probe, named: listEnvironments) {
            if list.name == kind.environment {
                return removeEnvironment(list, in: text, selection: selection, removeItems: true)
            }
            return renameEnvironment(list, to: kind.environment, in: text, selection: selection)
        }
        guard let block = balancedLines(text, expandedToWholeBlocks(text, selectedLines(text, selection))) else {
            return FormattingText.noChange(selection)
        }
        return wrapLines(block, in: kind.environment, text: text, selection: selection, items: true)
    }

    // MARK: - Umgebungen bearbeiten

    private static let alignmentEnvironments: Set<String> = ["center", "flushleft", "flushright"]
    private static let listEnvironments: Set<String> = ["itemize", "enumerate"]

    /// Umgebungen, die als Ganzes ausgerichtet werden (Tabellen, Formeln, Zeichnungen):
    /// In ihrem Inhalt hätte `center` nichts verloren.
    private static let wholeBlockEnvironments: Set<String> = LaTeXTokenizer.mathEnvironments
        .union(LaTeXTokenizer.verbatimEnvironments)
        .union(["tabular", "tabular*", "tabularx", "tabulary", "longtable", "array", "tikzpicture", "picture",
                "aligned", "alignedat", "gathered", "split", "cases", "matrix", "pmatrix", "bmatrix",
                "Bmatrix", "vmatrix", "Vmatrix", "smallmatrix"])

    /// Packt ganze Zeilen in `\begin{name} … \end{name}` und rückt sie eine Ebene ein.
    /// Bei Listen bekommt jede Zeile der obersten Ebene ein `\item ` (falls sie keins hat).
    private static func wrapLines<S: UTF16Source>(
        _ block: Range<Int>, in name: String, text: S, selection: Range<Int>, items: Bool
    ) -> TextEdit {
        let lines = sourceLines(text, in: block)
        let unit = EditingAssistant.indentUnit
        guard let first = lines.first(where: { !$0.isBlank }) else {
            // Nur leere Zeilen: leere Umgebung, Cursor im Inneren.
            let line = SourceLine(text, containing: selection.lowerBound)
            let indent = text.string(in: line.range.lowerBound..<line.indentEnd)
            let opening = indent + "\\begin{\(name)}\n" + indent + unit + (items ? "\\item " : "")
            let caret = line.range.lowerBound + opening.utf16.count
            return TextEdit(
                range: line.range,
                replacement: opening + "\n" + indent + "\\end{\(name)}",
                selectionAfter: caret..<caret
            )
        }
        // Die Umgebung bekommt die Einrückung der ersten Zeile.
        let indent = text.string(in: first.range.lowerBound..<first.indentEnd)
        var builder = FormattingEditBuilder(range: block)
        builder.insert(indent + "\\begin{\(name)}\n")
        // Zeilen im Inneren einer abgesetzten Formel (`\[ … \]`) werden kein eigener Punkt.
        let displayMath = items ? displayMathRanges(text) : []
        var depth = 0
        var verbatim: String?
        for (index, line) in lines.enumerated() {
            if index > 0 { builder.copy((line.range.lowerBound - 1)..<line.range.lowerBound, from: text) }
            if let name = verbatim {
                // Wörtlicher Inhalt (`verbatim`, `lstlisting`): nicht einrücken,
                // sonst ändert sich die Ausgabe im PDF.
                builder.copy(line.range, from: text, preferred: true)
                if closesVerbatim(text, name, in: line.range) { verbatim = nil }
                continue
            }
            if line.isBlank {
                builder.copy(line.range, from: text, preferred: true)
                continue
            }
            builder.insert(unit)
            let code = line.indentEnd
            let insideFormula = displayMath.contains { $0.lowerBound < code && code < $0.upperBound }
            if items, depth == 0, !insideFormula, line.hasCode,
               !startsWithCommand(text, at: code, "item"), !startsWithCommand(text, at: code, "end") {
                builder.copy(line.range.lowerBound..<code, from: text)
                builder.insert("\\item ")
                builder.copy(code..<line.range.upperBound, from: text, preferred: true)
            } else {
                builder.copy(line.range, from: text, preferred: true)
            }
            let opened = openedVerbatim(text, in: line.range)
            depth = max(0, depth + environmentDepthChange(text, in: line.indentEnd..<line.codeEnd) - (opened == nil ? 0 : 1))
            verbatim = opened
        }
        builder.insert("\n" + indent + "\\end{\(name)}")
        return builder.edit(selection: selection)
    }

    /// Entfernt `\begin{…}` und `\end{…}` (ganze Zeilen, wenn sonst nichts darauf steht),
    /// rückt den Inhalt eine Ebene aus und entfernt bei Listen die `\item`-Anfänge.
    private static func removeEnvironment<S: UTF16Source>(
        _ block: EnvironmentBlock, in text: S, selection: Range<Int>, removeItems: Bool
    ) -> TextEdit {
        let beginLine = SourceLine(text, containing: block.beginRange.lowerBound)
        let endLine = SourceLine(text, containing: block.endRange.lowerBound)
        // `\begin{enumerate}[label=…]`: optionale Argumente gehören zum Anfang.
        var beginEnd = block.beginRange.upperBound
        let options = skipSpaces(text, from: beginEnd, limit: beginLine.range.upperBound)
        if text.unit(at: options) == TeXChar.bracketOpen,
           let close = closingBracket(text, from: options, limit: beginLine.range.upperBound) {
            beginEnd = close + 1
        }
        let sameLine = beginLine.range == endLine.range
        let beginAlone = !sameLine
            && FormattingText.isBlank(text, beginLine.range.lowerBound..<block.beginRange.lowerBound)
            && FormattingText.isBlank(text, beginEnd..<beginLine.range.upperBound)
        let endAlone = !sameLine
            && FormattingText.isBlank(text, endLine.range.lowerBound..<block.endRange.lowerBound)
            && FormattingText.isBlank(text, block.endRange.upperBound..<endLine.range.upperBound)

        var editStart = block.beginRange.lowerBound
        var contentStart = skipSpaces(text, from: beginEnd, limit: block.endRange.lowerBound)
        if beginAlone {
            editStart = beginLine.range.lowerBound
            contentStart = min(text.count, beginLine.range.upperBound + 1)
        }
        var editEnd = skipSpaces(text, from: block.endRange.upperBound, limit: endLine.range.upperBound)
        var contentEnd = block.endRange.lowerBound
        if endAlone {
            editEnd = endLine.range.upperBound
            contentEnd = endLine.range.lowerBound - 1
        } else {
            while contentEnd > contentStart,
                  text[contentEnd - 1] == TeXChar.space || text[contentEnd - 1] == TeXChar.tab { contentEnd -= 1 }
        }

        guard contentStart <= contentEnd else {
            // Leere Umgebung: ganz entfernen, ohne eine Leerzeile zu hinterlassen.
            if editEnd < text.count, text[editEnd] == TeXChar.newline {
                editEnd += 1
            } else if editStart > 0, text[editStart - 1] == TeXChar.newline {
                editStart -= 1
            }
            return FormattingEditBuilder(range: editStart..<editEnd).edit(selection: selection)
        }

        var builder = FormattingEditBuilder(range: editStart..<editEnd)
        var depth = 0
        var verbatim: String?
        var wroteSegment = false
        var segmentStart = contentStart
        while true {
            let segmentEnd = min(text.lineEnd(after: segmentStart), contentEnd)
            var parts = [segmentStart..<segmentEnd]
            var drop = false
            if let name = verbatim {
                // Wörtlicher Inhalt bleibt, wie er ist.
                if closesVerbatim(text, name, in: segmentStart..<segmentEnd) { verbatim = nil }
            } else {
                let atLineStart = segmentStart == text.lineStart(before: segmentStart)
                let keep = atLineStart ? dedented(text, from: segmentStart, limit: segmentEnd) : segmentStart
                parts = [keep..<segmentEnd]
                if removeItems, depth == 0, let item = itemPrefix(text, from: keep, limit: segmentEnd) {
                    // Ein `\item` allein auf der Zeile: Zeile fällt weg.
                    drop = atLineStart && FormattingText.isBlank(text, item.upperBound..<segmentEnd)
                    parts = [keep..<item.lowerBound, item.upperBound..<segmentEnd]
                }
                let opened = openedVerbatim(text, in: segmentStart..<segmentEnd)
                depth = max(0, depth + environmentDepthChange(text, in: segmentStart..<segmentEnd) - (opened == nil ? 0 : 1))
                verbatim = opened
            }
            if !drop {
                if wroteSegment { builder.copy((segmentStart - 1)..<segmentStart, from: text) }
                for part in parts { builder.copy(part, from: text, preferred: true) }
                wroteSegment = true
            }
            if segmentEnd >= contentEnd { break }
            segmentStart = segmentEnd + 1
        }
        if !wroteSegment {
            // Nichts übrig (z. B. nur ein leeres `\item`): keine Leerzeile hinterlassen.
            if editEnd < text.count, text[editEnd] == TeXChar.newline {
                builder.range = editStart..<(editEnd + 1)
            } else if editStart > 0, text[editStart - 1] == TeXChar.newline {
                builder.range = (editStart - 1)..<editEnd
            }
        }
        return builder.edit(selection: selection)
    }

    /// Benennt `\begin{alt}` und `\end{alt}` in einem Schritt um.
    private static func renameEnvironment<S: UTF16Source>(
        _ block: EnvironmentBlock, to name: String, in text: S, selection: Range<Int>
    ) -> TextEdit {
        let beginName = environmentName(in: block.beginRange, text: text)
        let endName = environmentName(in: block.endRange, text: text)
        var builder = FormattingEditBuilder(range: block.range)
        builder.copy(block.range.lowerBound..<beginName.lowerBound, from: text)
        builder.insert(name)
        builder.copy(beginName.upperBound..<endName.lowerBound, from: text, preferred: true)
        builder.insert(name)
        builder.copy(endName.upperBound..<block.range.upperBound, from: text)
        return builder.edit(selection: selection)
    }

    /// Bereich des Namens in `\begin{name}` bzw. `\end{name}`.
    private static func environmentName<S: UTF16Source>(in token: Range<Int>, text: S) -> Range<Int> {
        var open = token.lowerBound
        while open < token.upperBound, text[open] != TeXChar.braceOpen { open += 1 }
        return min(open + 1, token.upperBound - 1)..<(token.upperBound - 1)
    }

    /// Zeilen, die ohne Auswahl ausgerichtet werden.
    private static func alignmentParagraph<S: UTF16Source>(_ text: S, at cursor: Int) -> Range<Int> {
        // 1. In einer Tabelle oder Formel: die ganze (äusserste) solche Umgebung.
        var probe = environmentProbe(text, at: cursor)
        var whole: EnvironmentBlock?
        while let block = BlockEditor.enclosingEnvironment(in: text, at: probe),
              wholeBlockEnvironments.contains(block.name) {
            whole = block
            probe = block.range.lowerBound
        }
        if let whole { return linesCovering(whole.range, in: text) }

        // 2. Auf einer Zeile mit `\begin{…}` oder `\end{…}`: die ganze Umgebung.
        let line = SourceLine(text, containing: cursor)
        if startsWithCommand(text, at: line.indentEnd, "begin") || startsWithCommand(text, at: line.indentEnd, "end") {
            if let block = BlockEditor.enclosingEnvironment(in: text, at: line.indentEnd + 1) {
                return linesCovering(block.range, in: text)
            }
            return line.range
        }

        // 3. Zusammenhängende Textzeilen um den Cursor – bis zu Leerzeilen,
        //    Überschriften, `\item` und Umgebungsgrenzen.
        if line.isBlank || HeadingLine(text, line) != nil { return line.range }
        var first = line
        if !startsWithCommand(text, at: line.indentEnd, "item") {
            while first.range.lowerBound > 0 {
                let previous = SourceLine(text, containing: first.range.lowerBound - 1)
                if endsParagraph(text, previous) { break }
                first = previous
            }
        }
        var last = line
        while last.range.upperBound < text.count {
            let next = SourceLine(text, containing: last.range.upperBound + 1)
            if endsParagraph(text, next) { break }
            last = next
        }
        return first.range.lowerBound..<last.range.upperBound
    }

    private static func endsParagraph<S: UTF16Source>(_ text: S, _ line: SourceLine) -> Bool {
        line.isBlank
            || startsWithCommand(text, at: line.indentEnd, "begin")
            || startsWithCommand(text, at: line.indentEnd, "end")
            || startsWithCommand(text, at: line.indentEnd, "item")
            || HeadingLine(text, line) != nil
    }

    /// Zeilen, die nicht zur Überschrift werden: Umgebungsgrenzen, Aufzählungspunkte,
    /// Gliederungsbefehle ohne Titel auf der Zeile und Formelgrenzen.
    private static func isStructural<S: UTF16Source>(_ text: S, _ line: SourceLine) -> Bool {
        let code = line.indentEnd
        if ["begin", "end", "item"].contains(where: { startsWithCommand(text, at: code, $0) }) { return true }
        if LaTeXTokenizer.sectioningLevels.keys.contains(where: { startsWithCommand(text, at: code, $0) }) { return true }
        return ["\\[", "\\]", "$$"].contains { text.matches($0, at: code) }
    }

    /// Erweitert die Zeilen so, dass Tabellen und Formeln, die sie berühren, ganz dazugehören:
    /// In ihrem Inhalt hätten `center` oder `itemize` nichts verloren.
    private static func expandedToWholeBlocks<S: UTF16Source>(_ text: S, _ lines: Range<Int>) -> Range<Int> {
        var lower = lines.lowerBound
        var upper = lines.upperBound
        for position in [lines.lowerBound, lines.upperBound] {
            var probe = environmentProbe(text, at: position)
            var outermost: EnvironmentBlock?
            while let block = BlockEditor.enclosingEnvironment(in: text, at: probe),
                  wholeBlockEnvironments.contains(block.name) {
                outermost = block
                probe = block.range.lowerBound
            }
            if let outermost {
                lower = min(lower, text.lineStart(before: outermost.range.lowerBound))
                upper = max(upper, text.lineEnd(after: outermost.range.upperBound))
            }
        }
        for region in displayMathRanges(text) where region.lowerBound < upper && region.upperBound > lower {
            lower = min(lower, text.lineStart(before: region.lowerBound))
            upper = max(upper, text.lineEnd(after: region.upperBound))
        }
        return lower..<upper
    }
}

// MARK: - Zeilen

/// Eine Zeile im Text, zerlegt in Einrückung, Inhalt und Kommentar.
private struct SourceLine {
    /// Ganze Zeile ohne Zeilenumbruch.
    let range: Range<Int>
    /// Ende der Einrückung (Leerzeichen und Tabs).
    let indentEnd: Int
    /// Ende des eigentlichen Inhalts – vor Leerraum und Kommentar am Zeilenende.
    let codeEnd: Int
    let hasComment: Bool

    init<S: UTF16Source>(_ text: S, containing position: Int) {
        let start = text.lineStart(before: position)
        let end = text.lineEnd(after: start)
        var indentEnd = start
        while indentEnd < end, text[indentEnd] == TeXChar.space || text[indentEnd] == TeXChar.tab { indentEnd += 1 }
        let comment = text.commentStart(inLineStartingAt: start)
        var codeEnd = comment ?? end
        while codeEnd > indentEnd, TeXChar.isWhitespace(text[codeEnd - 1]) { codeEnd -= 1 }
        self.range = start..<end
        self.indentEnd = indentEnd
        self.codeEnd = max(codeEnd, indentEnd)
        self.hasComment = comment != nil
    }

    /// Steht ausser Leerraum und Kommentar etwas auf der Zeile?
    var hasCode: Bool { codeEnd > indentEnd }
    /// Ganz leer (auch kein Kommentar)?
    var isBlank: Bool { !hasCode && !hasComment }
}

/// Eine Zeile, die mit einem Gliederungsbefehl beginnt: `\section*[Kurz]{Titel}\label{…}`.
private struct HeadingLine {
    let name: String
    /// Befehlsname ohne Backslash.
    let nameRange: Range<Int>
    /// Inhalt der geschweiften Klammern.
    let title: Range<Int>
    /// Position nach der schliessenden Klammer (bzw. Ende des Titels, wenn sie fehlt).
    let afterTitle: Int
    /// Ende der Zeile, in der die Überschrift endet (Titel können umbrechen).
    let end: Int

    init?<S: UTF16Source>(_ text: S, _ line: SourceLine) {
        let backslash = line.indentEnd
        guard line.hasCode, text[backslash] == TeXChar.backslash else { return nil }
        var i = backslash + 1
        while i < line.codeEnd, TeXChar.isASCIILetter(text[i]) { i += 1 }
        let nameRange = (backslash + 1)..<i
        let name = text.string(in: nameRange)
        guard LaTeXTokenizer.sectioningLevels[name] != nil else { return nil }
        if i < line.codeEnd, text[i] == TeXChar.star { i += 1 }
        i = skipSpaces(text, from: i, limit: line.codeEnd)
        if i < line.codeEnd, text[i] == TeXChar.bracketOpen {
            guard let close = closingBracket(text, from: i, limit: line.codeEnd) else { return nil }
            i = skipSpaces(text, from: close + 1, limit: line.codeEnd)
        }
        guard i < line.codeEnd, text[i] == TeXChar.braceOpen else { return nil }
        self.name = name
        self.nameRange = nameRange
        if let close = closingBrace(text, from: i) {
            title = (i + 1)..<close
            afterTitle = close + 1
            end = text.lineEnd(after: close)
        } else {
            title = (i + 1)..<line.codeEnd
            afterTitle = line.codeEnd
            end = line.range.upperBound
        }
    }
}

/// Die Überschrift, zu der die Zeile gehört – auch wenn ihr Titel schon weiter oben
/// beginnt (`\section{Ein langer` / `Titel}`).
private func headingLine<S: UTF16Source>(_ text: S, containing line: SourceLine) -> (line: SourceLine, heading: HeadingLine)? {
    if let heading = HeadingLine(text, line) { return (line, heading) }
    var current = line
    for _ in 0..<50 {
        guard current.range.lowerBound > 0 else { return nil }
        let previous = SourceLine(text, containing: current.range.lowerBound - 1)
        if previous.isBlank { return nil }
        if let heading = HeadingLine(text, previous) {
            return heading.end >= line.range.upperBound ? (previous, heading) : nil
        }
        current = previous
    }
    return nil
}

/// Steht `position` vor `\begin{document}` (also in der Präambel)?
/// Dateien ohne `\begin{document}` (z. B. eingebundene Kapitel) haben keine Präambel.
private func isInPreamble<S: UTF16Source>(_ text: S, at position: Int) -> Bool {
    var i = 0
    while i < text.count, i < position {
        let unit = text[i]
        if unit == TeXChar.percent, !text.isEscaped(at: i) {
            i = text.lineEnd(after: i)
            continue
        }
        if unit == TeXChar.backslash, !text.isEscaped(at: i), text.matches("\\begin{document}", at: i) {
            return false
        }
        i += 1
    }
    // Erst nach dem Cursor (oder gar nicht): Präambel nur, wenn es den Anfang später gibt.
    while i < text.count {
        let unit = text[i]
        if unit == TeXChar.percent, !text.isEscaped(at: i) {
            i = text.lineEnd(after: i)
            continue
        }
        if unit == TeXChar.backslash, !text.isEscaped(at: i), text.matches("\\begin{document}", at: i) {
            // Auf der Zeile von \begin{document} selbst zählt der Cursor nicht zur Präambel.
            return text.lineStart(before: i) > position
        }
        i += 1
    }
    return false
}

/// Bereiche aller abgesetzten Formeln (`\[ … \]`, `$$ … $$`, `equation` …).
private func displayMathRanges<S: UTF16Source>(_ text: S) -> [Range<Int>] {
    var units: [UInt16] = []
    units.reserveCapacity(text.count)
    for i in 0..<text.count { units.append(text[i]) }
    return LaTeXTokenizer.tokenize(units).mathRegions
        .filter { $0.style == .display && $0.isClosed }
        .map(\.range)
}

/// Alle Zeilen im (zeilengenauen) Bereich.
private func sourceLines<S: UTF16Source>(_ text: S, in range: Range<Int>) -> [SourceLine] {
    var result: [SourceLine] = []
    var position = range.lowerBound
    while true {
        let line = SourceLine(text, containing: position)
        result.append(line)
        if line.range.upperBound >= range.upperBound || line.range.upperBound >= text.count { break }
        position = line.range.upperBound + 1
    }
    return result
}

/// Ganze Zeilen der Auswahl. Endet die Auswahl am Anfang einer Zeile, zählt diese nicht mehr dazu.
private func selectedLines<S: UTF16Source>(_ text: S, _ selection: Range<Int>) -> Range<Int> {
    let start = text.lineStart(before: selection.lowerBound)
    var last = selection.upperBound
    if last > selection.lowerBound, text[last - 1] == TeXChar.newline { last -= 1 }
    return start..<text.lineEnd(after: max(start, last))
}

/// Ganze Zeilen, die `range` berühren.
private func linesCovering<S: UTF16Source>(_ range: Range<Int>, in text: S) -> Range<Int> {
    text.lineStart(before: range.lowerBound)..<text.lineEnd(after: range.upperBound)
}

/// Erweitert einen Zeilenbereich so, dass keine Umgebung nur halb darin liegt, und hält
/// `\begin{document}`/`\end{document}` heraus. `nil`, wenn nichts übrig bleibt.
private func balancedLines<S: UTF16Source>(_ text: S, _ lines: Range<Int>) -> Range<Int>? {
    var lower = lines.lowerBound
    var upper = lines.upperBound
    for _ in 0..<32 {
        var newLower = lower
        var newUpper = upper
        var open: [(name: String, range: Range<Int>)] = []
        var i = lower
        while i < upper {
            let unit = text[i]
            if unit == TeXChar.percent, !text.isEscaped(at: i) {
                i = text.lineEnd(after: i)
                continue
            }
            guard unit == TeXChar.backslash, !text.isEscaped(at: i),
                  let token = BlockEditor.environmentToken(in: text, at: i) else {
                i += 1
                continue
            }
            if token.name == "document" {
                // Nie das ganze Dokument einpacken.
                if token.isBegin {
                    newLower = max(newLower, text.lineEnd(after: token.range.upperBound) + 1)
                } else {
                    newUpper = min(newUpper, text.lineStart(before: token.range.lowerBound) - 1)
                }
            } else if token.isBegin {
                if LaTeXTokenizer.verbatimEnvironments.contains(token.name),
                   let end = BlockEditor.findEnd(of: token.name, in: text, from: token.range.upperBound) {
                    // Wörtlicher Inhalt: bis zum Ende springen.
                    newUpper = max(newUpper, text.lineEnd(after: end.lowerBound))
                    i = end.upperBound
                    continue
                }
                open.append((token.name, token.range))
            } else if let index = open.lastIndex(where: { $0.name == token.name }) {
                open.removeSubrange(index...)
            } else if let block = BlockEditor.enclosingEnvironment(in: text, at: token.range.lowerBound, named: [token.name]),
                      block.endRange == token.range {
                // `\end{…}` ohne Anfang im Bereich: Anfang dazunehmen.
                newLower = min(newLower, text.lineStart(before: block.range.lowerBound))
            }
            i = token.range.upperBound
        }
        for begin in open {
            if let end = BlockEditor.findEnd(of: begin.name, in: text, from: begin.range.upperBound) {
                newUpper = max(newUpper, text.lineEnd(after: end.lowerBound))
            }
        }
        guard newLower <= newUpper else { return nil }
        if newLower == lower && newUpper == upper { break }
        lower = newLower
        upper = newUpper
    }
    return lower..<upper
}

/// Position, an der nach der umgebenden Umgebung gesucht wird. Steht der Cursor auf
/// einer Zeile mit `\begin{…}` oder `\end{…}`, gehört die ganze Zeile zu dieser Umgebung.
private func environmentProbe<S: UTF16Source>(_ text: S, at position: Int) -> Int {
    let line = SourceLine(text, containing: position)
    if startsWithCommand(text, at: line.indentEnd, "begin") || startsWithCommand(text, at: line.indentEnd, "end") {
        return line.indentEnd + 1
    }
    return position
}

/// Wie viele Umgebungen öffnet (+) bzw. schliesst (−) dieser Zeilenabschnitt?
private func environmentDepthChange<S: UTF16Source>(_ text: S, in range: Range<Int>) -> Int {
    var change = 0
    var i = range.lowerBound
    while i < range.upperBound {
        let unit = text[i]
        if unit == TeXChar.percent, !text.isEscaped(at: i) { break }
        if unit == TeXChar.backslash, !text.isEscaped(at: i), let token = BlockEditor.environmentToken(in: text, at: i) {
            change += token.isBegin ? 1 : -1
            i = token.range.upperBound
            continue
        }
        i += 1
    }
    return change
}

/// Öffnet der Zeilenabschnitt eine wörtliche Umgebung (`verbatim`, `lstlisting` …),
/// die nicht im selben Abschnitt endet? Dann ihr Name.
private func openedVerbatim<S: UTF16Source>(_ text: S, in range: Range<Int>) -> String? {
    var open: String?
    var i = range.lowerBound
    while i < range.upperBound {
        let unit = text[i]
        if open == nil, unit == TeXChar.percent, !text.isEscaped(at: i) { break }
        if unit == TeXChar.backslash, !text.isEscaped(at: i), let token = BlockEditor.environmentToken(in: text, at: i) {
            if let name = open {
                if !token.isBegin && token.name == name { open = nil }
            } else if token.isBegin, LaTeXTokenizer.verbatimEnvironments.contains(token.name) {
                open = token.name
            }
            i = token.range.upperBound
            continue
        }
        i += 1
    }
    return open
}

/// Endet im Zeilenabschnitt die wörtliche Umgebung `name`?
private func closesVerbatim<S: UTF16Source>(_ text: S, _ name: String, in range: Range<Int>) -> Bool {
    let end = "\\end{" + name + "}"
    var i = range.lowerBound
    while i < range.upperBound {
        if text.matches(end, at: i) { return true }
        i += 1
    }
    return false
}

/// `\item`, `\item[a)]` samt folgender Leerzeichen am Anfang des Abschnitts.
private func itemPrefix<S: UTF16Source>(_ text: S, from start: Int, limit: Int) -> Range<Int>? {
    let code = skipSpaces(text, from: start, limit: limit)
    guard code < limit, startsWithCommand(text, at: code, "item") else { return nil }
    var end = code + 5
    let options = skipSpaces(text, from: end, limit: limit)
    if options < limit, text[options] == TeXChar.bracketOpen,
       let close = closingBracket(text, from: options, limit: limit) {
        end = close + 1
    }
    return code..<skipSpaces(text, from: end, limit: limit)
}

/// Eine Einrückungsebene entfernen: bis zu zwei Leerzeichen oder einen Tab.
private func dedented<S: UTF16Source>(_ text: S, from start: Int, limit: Int) -> Int {
    if start < limit, text[start] == TeXChar.tab { return start + 1 }
    var i = start
    while i < limit, i - start < EditingAssistant.indentUnit.utf16.count, text[i] == TeXChar.space { i += 1 }
    return i
}

/// Beginnt bei `index` der Befehl `\name` (und nicht ein längerer wie `\itemsep`)?
private func startsWithCommand<S: UTF16Source>(_ text: S, at index: Int, _ name: String) -> Bool {
    guard text.matches("\\" + name, at: index) else { return false }
    guard let next = text.unit(at: index + name.utf16.count + 1) else { return true }
    return !TeXChar.isASCIILetter(next)
}

private func skipSpaces<S: UTF16Source>(_ text: S, from start: Int, limit: Int) -> Int {
    var i = start
    while i < limit, text[i] == TeXChar.space || text[i] == TeXChar.tab { i += 1 }
    return i
}

/// Schliessende eckige Klammer zu `[` bei `open` (geschweifte Klammern dazwischen zählen mit).
private func closingBracket<S: UTF16Source>(_ text: S, from open: Int, limit: Int) -> Int? {
    var depth = 0
    var i = open + 1
    while i < limit {
        let unit = text[i]
        if !text.isEscaped(at: i) {
            if unit == TeXChar.braceOpen { depth += 1 }
            if unit == TeXChar.braceClose { depth -= 1 }
            if unit == TeXChar.bracketClose, depth == 0 { return i }
        }
        i += 1
    }
    return nil
}

/// Schliessende geschweifte Klammer zu `{` bei `open`, höchstens bis zum Absatzende.
private func closingBrace<S: UTF16Source>(_ text: S, from open: Int) -> Int? {
    let limit = EditingAssistant.paragraphEnd(text, after: open)
    var depth = 0
    var i = open
    while i < limit {
        let unit = text[i]
        if unit == TeXChar.percent, !text.isEscaped(at: i) {
            i = text.lineEnd(after: i)
            continue
        }
        if unit == TeXChar.braceOpen, !text.isEscaped(at: i) { depth += 1 }
        if unit == TeXChar.braceClose, !text.isEscaped(at: i) {
            depth -= 1
            if depth == 0 { return i }
        }
        i += 1
    }
    return nil
}

/// Absatzstil zu einem Gliederungsbefehl im gewählten Schema (`nil` z. B. für `\part`).
private func headingStyle(for command: String, in scheme: HeadingScheme) -> ParagraphStyle? {
    ParagraphStyle.allCases.first { scheme.command(for: $0) == command }
}

// MARK: - Dokumentklasse

/// Klassen mit Kapiteln (`\chapter`).
private let chapterClasses: Set<String> = ["report", "book", "scrreprt", "scrbook", "memoir", "extreport", "extbook"]

/// Name aus `\documentclass[…]{name}` – gesucht nur ausserhalb von Kommentaren
/// und vor `\begin{document}`.
private func documentClassName<S: UTF16Source>(in text: S) -> String? {
    var i = 0
    while i < text.count {
        let unit = text[i]
        if unit == TeXChar.percent, !text.isEscaped(at: i) {
            i = text.lineEnd(after: i)
            continue
        }
        if unit == TeXChar.backslash, !text.isEscaped(at: i) {
            if startsWithCommand(text, at: i, "documentclass") { return className(in: text, after: i + 14) }
            if text.matches("\\begin{document}", at: i) { return nil }
        }
        i += 1
    }
    return nil
}

private func className<S: UTF16Source>(in text: S, after start: Int) -> String? {
    var i = skipBlanksAndComments(text, from: start)
    if text.unit(at: i) == TeXChar.bracketOpen {
        // Optionen, eventuell über mehrere Zeilen und mit Kommentaren.
        i += 1
        while i < text.count, !(text[i] == TeXChar.bracketClose && !text.isEscaped(at: i)) {
            if text[i] == TeXChar.percent, !text.isEscaped(at: i) {
                i = text.lineEnd(after: i)
                continue
            }
            i += 1
        }
        i = skipBlanksAndComments(text, from: i + 1)
    }
    guard text.unit(at: i) == TeXChar.braceOpen else { return nil }
    var end = i + 1
    while end < text.count, text[end] != TeXChar.braceClose, text[end] != TeXChar.newline { end += 1 }
    guard text.unit(at: end) == TeXChar.braceClose else { return nil }
    return text.string(in: (i + 1)..<end).trimmingCharacters(in: .whitespaces)
}

private func skipBlanksAndComments<S: UTF16Source>(_ text: S, from start: Int) -> Int {
    var i = start
    while i < text.count {
        if TeXChar.isWhitespace(text[i]) {
            i += 1
        } else if text[i] == TeXChar.percent, !text.isEscaped(at: i) {
            i = text.lineEnd(after: i)
        } else {
            break
        }
    }
    return i
}
