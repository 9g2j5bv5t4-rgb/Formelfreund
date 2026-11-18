import Foundation

/// Kleine Tipp-Hilfen im Editor: automatisches Schliessen von Klammern
/// (`{}`, `()`, `[]`, `\left( … \right)`), `$…$`, `\[…\]`, `\begin…\end`,
/// Einrücken und Listen fortsetzen.
///
/// Jede Funktion schaut sich Text und Cursor an und liefert entweder eine
/// `TextEdit` (der Editor führt sie aus) oder `nil` (normales Tippen).
/// Die Logik kennt keinen Editor und ist dadurch einfach zu testen.
public enum EditingAssistant {
    /// Einrückung für neue Zeilen innerhalb einer Umgebung.
    public static let indentUnit = "  "

    /// Umgebungen, bei denen nach `\begin{…}` direkt ein `\item` eingefügt wird.
    static let listEnvironments: Set<String> = ["itemize", "enumerate", "description"]

    // MARK: - Tippen eines Zeichens

    public static func editForTyping<S: UTF16Source>(_ typed: String, in text: S, selection: Range<Int>) -> TextEdit? {
        let units = Array(typed.utf16)
        guard units.count == 1, let typedUnit = units.first else { return nil }
        let cursor = selection.lowerBound
        // In Kommentaren nichts automatisch ergänzen.
        if BracketMatcher.isInComment(text, cursor) { return nil }

        switch typedUnit {
        case TeXChar.braceOpen:
            return typedOpeningBrace(text, selection)
        case TeXChar.braceClose:
            return typedClosingBrace(text, selection)
        case TeXChar.dollar:
            return typedDollar(text, selection)
        case TeXChar.bracketOpen, TeXChar.parenOpen:
            // `\[` und `\(` öffnen eine Formel, alles andere ist eine gewöhnliche Klammer.
            if text.isEscaped(at: cursor) {
                return typedMathBracket(typedUnit, text, selection)
            }
            return typedOpeningPair(typedUnit, text, selection)
        case TeXChar.bracketClose, TeXChar.parenClose:
            return typedClosingPair(typedUnit, text, selection)
        default:
            return nil
        }
    }

    /// `{` → `{|}`, `\{` → `\{|\}`, mit Auswahl → `{Auswahl}`.
    static func typedOpeningBrace<S: UTF16Source>(_ text: S, _ selection: Range<Int>) -> TextEdit? {
        let cursor = selection.lowerBound
        let escaped = text.isEscaped(at: cursor)
        if !selection.isEmpty {
            let inner = text.string(in: selection)
            let (open, close) = escaped ? ("{", "\\}") : ("{", "}")
            return TextEdit(
                range: selection,
                replacement: open + inner + close,
                selectionAfter: (cursor + 1)..<(cursor + 1 + selection.count)
            )
        }
        if escaped {
            return TextEdit(range: cursor..<cursor, replacement: "{\\}", selectionAfter: (cursor + 1)..<(cursor + 1))
        }
        if let next = text.unit(at: cursor), TeXChar.isAlphanumeric(next) || next == TeXChar.backslash {
            return nil
        }
        return TextEdit(range: cursor..<cursor, replacement: "{}", selectionAfter: (cursor + 1)..<(cursor + 1))
    }

    /// `}` überschreibt eine bereits vorhandene schliessende Klammer und
    /// ergänzt nach `\begin{name}` automatisch das passende `\end{name}`.
    static func typedClosingBrace<S: UTF16Source>(_ text: S, _ selection: Range<Int>) -> TextEdit? {
        guard selection.isEmpty else { return nil }
        let cursor = selection.lowerBound
        guard !text.isEscaped(at: cursor) else { return nil }

        let overtype = text.unit(at: cursor) == TeXChar.braceClose
            && !text.isEscaped(at: cursor)
            && braceBalanceInParagraph(text, around: cursor) <= 0
        let replaced = overtype ? cursor..<(cursor + 1) : cursor..<cursor

        if let environment = environmentBeingOpened(text, before: cursor),
           needsEnd(for: environment, in: text, beginIsComplete: overtype) {
            return environmentBlock(environment, in: text, at: cursor, replacing: replaced, closingBrace: true)
        }

        return overtype ? .moveCursor(to: cursor + 1) : nil
    }

    /// `(` → `(|)`, `[` → `[|]`, mit Auswahl → `(Auswahl)`, nach `\left` → `\left( | \right)`.
    static func typedOpeningPair<S: UTF16Source>(_ open: UInt16, _ text: S, _ selection: Range<Int>) -> TextEdit? {
        let cursor = selection.lowerBound
        let (openString, closeString) = open == TeXChar.parenOpen ? ("(", ")") : ("[", "]")
        if !selection.isEmpty {
            let inner = text.string(in: selection)
            return TextEdit(
                range: selection,
                replacement: openString + inner + closeString,
                selectionAfter: (cursor + 1)..<(cursor + 1 + selection.count)
            )
        }
        if cursor >= 5, text.matches("\\left", at: cursor - 5), !text.isEscaped(at: cursor - 5) {
            let replacement = openString + "  \\right" + closeString
            return TextEdit(range: cursor..<cursor, replacement: replacement, selectionAfter: (cursor + 2)..<(cursor + 2))
        }
        // Vor einem Wort nicht ergänzen – dort wird meist eine vorhandene Stelle eingeklammert.
        if let next = text.unit(at: cursor), TeXChar.isAlphanumeric(next) || next == TeXChar.backslash {
            return nil
        }
        return TextEdit(range: cursor..<cursor, replacement: openString + closeString, selectionAfter: (cursor + 1)..<(cursor + 1))
    }

    /// `)` bzw. `]` überschreibt eine schon vorhandene schliessende Klammer, wenn
    /// die Klammern im Absatz sonst aufgehen.
    static func typedClosingPair<S: UTF16Source>(_ close: UInt16, _ text: S, _ selection: Range<Int>) -> TextEdit? {
        guard selection.isEmpty else { return nil }
        let cursor = selection.lowerBound
        guard text.unit(at: cursor) == close, !text.isEscaped(at: cursor) else { return nil }
        let open = close == TeXChar.parenClose ? TeXChar.parenOpen : TeXChar.bracketOpen
        guard balanceInParagraph(text, around: cursor, open: open, close: close) <= 0 else { return nil }
        return .moveCursor(to: cursor + 1)
    }

    /// `$` öffnet und schliesst Formeln im Fliesstext.
    static func typedDollar<S: UTF16Source>(_ text: S, _ selection: Range<Int>) -> TextEdit? {
        let cursor = selection.lowerBound
        guard !text.isEscaped(at: cursor) else { return nil }
        if !selection.isEmpty {
            let inner = text.string(in: selection)
            return TextEdit(
                range: selection,
                replacement: "$" + inner + "$",
                selectionAfter: (cursor + 1)..<(cursor + 1 + selection.count)
            )
        }
        let next = text.unit(at: cursor)
        switch dollarMode(text, before: cursor) {
        case .inline, .display:
            // Wir stehen in einer Formel: ein folgendes `$` wird überschrieben,
            // ansonsten schliesst das getippte `$` die Formel ganz normal.
            return next == TeXChar.dollar ? .moveCursor(to: cursor + 1) : nil
        case .text:
            if let next, TeXChar.isAlphanumeric(next) { return nil }
            return TextEdit(range: cursor..<cursor, replacement: "$$", selectionAfter: (cursor + 1)..<(cursor + 1))
        }
    }

    /// `\[` → `\[|\]` und `\(` → `\(|\)`.
    static func typedMathBracket<S: UTF16Source>(_ typed: UInt16, _ text: S, _ selection: Range<Int>) -> TextEdit? {
        guard selection.isEmpty else { return nil }
        let cursor = selection.lowerBound
        // Nur direkt nach einem (selbst nicht maskierten) Backslash.
        guard cursor > 0, text[cursor - 1] == TeXChar.backslash, text.isEscaped(at: cursor) else { return nil }
        guard dollarMode(text, before: cursor - 1) == .text else { return nil }
        let replacement = typed == TeXChar.bracketOpen ? "[\\]" : "(\\)"
        return TextEdit(range: cursor..<cursor, replacement: replacement, selectionAfter: (cursor + 1)..<(cursor + 1))
    }

    // MARK: - Zeilenumbruch

    /// Neue Zeile mit gleicher Einrückung; in Listen wird `\item` fortgesetzt.
    public static func editForNewline<S: UTF16Source>(in text: S, selection: Range<Int>) -> TextEdit? {
        if selection.isEmpty, let edit = environmentEndForNewline(text, cursor: selection.lowerBound) {
            return edit
        }
        if selection.isEmpty, let edit = bracketNewline(text, cursor: selection.lowerBound) {
            return edit
        }
        let cursor = selection.lowerBound
        let lineStart = text.lineStart(before: cursor)
        let indent = leadingWhitespace(text, lineContaining: cursor)
        let lineBeforeCursor = text.string(in: lineStart..<cursor)
        let trimmed = lineBeforeCursor.trimmingCharacters(in: .whitespaces)
        let atLineEnd = text.lineEnd(after: selection.upperBound) == selection.upperBound
            || text.string(in: selection.upperBound..<text.lineEnd(after: selection.upperBound))
                .trimmingCharacters(in: .whitespaces).isEmpty

        if trimmed.hasPrefix("\\item"), atLineEnd, selection.isEmpty {
            if trimmed == "\\item" {
                // Leeres \item + Enter: Aufzählungspunkt wieder entfernen.
                let itemStart = lineStart + indent.utf16.count
                return TextEdit(range: itemStart..<cursor, replacement: "", selectionAfter: itemStart..<itemStart)
            }
            let insertion = "\n" + indent + "\\item "
            let caret = cursor + insertion.utf16.count
            return TextEdit(range: selection, replacement: insertion, selectionAfter: caret..<caret)
        }

        guard !indent.isEmpty else { return nil }
        // Nicht mehr Einrückung übernehmen, als vor dem Cursor steht.
        let usableIndent = String(indent.prefix(lineBeforeCursor.count))
        let insertion = "\n" + usableIndent
        let caret = selection.lowerBound + insertion.utf16.count
        return TextEdit(range: selection, replacement: insertion, selectionAfter: caret..<caret)
    }

    /// ↩ direkt nach `\begin{name}` (auch mit Optionen wie `[htbp]` oder `{lcr}`) bzw. in
    /// `\begin{name|}`: Leerzeile mit Cursor und darunter `\end{name}` – sofern das `\end`
    /// noch fehlt. Nach der Zeile darf nur noch Leerraum stehen.
    static func environmentEndForNewline<S: UTF16Source>(_ text: S, cursor: Int) -> TextEdit? {
        guard !BracketMatcher.isInComment(text, cursor) else { return nil }
        let lineEnd = text.lineEnd(after: cursor)

        // Cursor noch im Namen: `\begin{forest|}` oder `\begin{forest|`.
        if let name = environmentBeingOpened(text, before: cursor) {
            let hasBrace = text.unit(at: cursor) == TeXChar.braceClose
            let afterBrace = cursor + (hasBrace ? 1 : 0)
            guard isBlank(text, afterBrace..<lineEnd),
                  needsEnd(for: name, in: text, beginIsComplete: hasBrace) else { return nil }
            return environmentBlock(name, in: text, at: cursor, replacing: cursor..<lineEnd, closingBrace: true)
        }

        // Cursor hinter `\begin{name}` und eventuellen Argumenten.
        guard isBlank(text, cursor..<lineEnd) else { return nil }
        let lineStart = text.lineStart(before: cursor)
        var begin = cursor - 7
        while begin >= lineStart, !(text.matches("\\begin{", at: begin) && !text.isEscaped(at: begin)) { begin -= 1 }
        guard begin >= lineStart else { return nil }
        let nameStart = begin + 7
        var nameEnd = nameStart
        while nameEnd < cursor, text[nameEnd] != TeXChar.braceClose { nameEnd += 1 }
        guard nameEnd < cursor, nameEnd > nameStart else { return nil }
        let name = text.string(in: nameStart..<nameEnd)
        guard name.unicodeScalars.allSatisfy({ CharacterSet.alphanumerics.contains($0) || $0 == "*" }) else { return nil }
        // Danach nur Argumente wie `[htbp]`, `{lcr}` oder `{0.5\textwidth}`.
        var position = nameEnd + 1
        while position < cursor {
            let u = text[position]
            if u == TeXChar.space || u == TeXChar.tab {
                position += 1
            } else if u == TeXChar.bracketOpen || u == TeXChar.braceOpen,
                      let end = ProseScanner.groupEnd(text, at: position, open: u, close: u == TeXChar.bracketOpen ? TeXChar.bracketClose : TeXChar.braceClose),
                      end <= cursor {
                position = end
            } else {
                return nil
            }
        }
        guard needsEnd(for: name, in: text, beginIsComplete: true) else { return nil }
        // Leerzeichen zwischen `\begin{…}` und dem Cursor fallen weg.
        var start = cursor
        while start > nameEnd + 1, text[start - 1] == TeXChar.space || text[start - 1] == TeXChar.tab { start -= 1 }
        return environmentBlock(name, in: text, at: cursor, replacing: start..<lineEnd, closingBrace: false)
    }

    /// ↩ zwischen zwei passenden Klammern – `{|}`, `[|]`, `(|)`, `\[|\]`, `\(|\)` –
    /// setzt die schliessende Klammer zwei Zeilen tiefer und den Cursor eingerückt
    /// in die Leerzeile dazwischen. Leerzeichen um den Cursor fallen dabei weg.
    static func bracketNewline<S: UTF16Source>(_ text: S, cursor: Int) -> TextEdit? {
        guard !BracketMatcher.isInComment(text, cursor) else { return nil }
        var open = cursor - 1
        while open >= 0, text[open] == TeXChar.space || text[open] == TeXChar.tab { open -= 1 }
        var close = cursor
        while close < text.count, text[close] == TeXChar.space || text[close] == TeXChar.tab { close += 1 }
        guard open >= 0, close < text.count else { return nil }

        let opener = text[open]
        let closer = text[close]
        let isPair: Bool
        switch opener {
        case TeXChar.braceOpen:
            isPair = closer == TeXChar.braceClose && !text.isEscaped(at: open) && !text.isEscaped(at: close)
        case TeXChar.bracketOpen, TeXChar.parenOpen:
            let expected = opener == TeXChar.bracketOpen ? TeXChar.bracketClose : TeXChar.parenClose
            if text.isEscaped(at: open) {
                // Formel-Klammern `\[ … \]` und `\( … \)`.
                isPair = closer == TeXChar.backslash && close + 1 < text.count && text[close + 1] == expected
                    && !text.isEscaped(at: close)
            } else {
                isPair = closer == expected && !text.isEscaped(at: close)
            }
        default:
            isPair = false
        }
        guard isPair else { return nil }

        let indent = leadingWhitespace(text, lineContaining: cursor)
        let firstLine = "\n" + indent + indentUnit
        let replacement = firstLine + "\n" + indent
        let caret = open + 1 + firstLine.utf16.count
        return TextEdit(range: (open + 1)..<close, replacement: replacement, selectionAfter: caret..<caret)
    }

    /// `}` (falls nötig), neue Zeile mit Cursor (bei Listen mit `\item`) und `\end{name}` darunter.
    static func environmentBlock<S: UTF16Source>(
        _ name: String, in text: S, at cursor: Int, replacing range: Range<Int>, closingBrace: Bool
    ) -> TextEdit {
        let indent = leadingWhitespace(text, lineContaining: cursor)
        let innerIndent = name == "document" ? indent : indent + indentUnit
        let item = listEnvironments.contains(name) ? "\\item " : ""
        let firstLine = (closingBrace ? "}" : "") + "\n" + innerIndent + item
        let replacement = firstLine + "\n" + indent + "\\end{\(name)}"
        let caret = range.lowerBound + firstLine.utf16.count
        return TextEdit(range: range, replacement: replacement, selectionAfter: caret..<caret)
    }

    private static func isBlank<S: UTF16Source>(_ text: S, _ range: Range<Int>) -> Bool {
        guard range.lowerBound < range.upperBound else { return true }
        for i in range where text[i] != TeXChar.space && text[i] != TeXChar.tab && text[i] != TeXChar.carriageReturn {
            return false
        }
        return true
    }

    // MARK: - Rückwärts löschen

    /// Löscht ein leeres automatisch eingefügtes Paar (`{|}`, `$|$`, `\[|\]`) auf einmal.
    public static func editForDeleteBackward<S: UTF16Source>(in text: S, selection: Range<Int>) -> TextEdit? {
        guard selection.isEmpty else { return nil }
        let cursor = selection.lowerBound
        guard cursor > 0, let previous = text.unit(at: cursor - 1), let next = text.unit(at: cursor) else { return nil }

        // \[|\] und \(|\)
        if cursor >= 2, text[cursor - 2] == TeXChar.backslash, !text.isEscaped(at: cursor - 2),
           (previous == TeXChar.bracketOpen && text.matches("\\]", at: cursor))
            || (previous == TeXChar.parenOpen && text.matches("\\)", at: cursor)) {
            return TextEdit(range: (cursor - 2)..<(cursor + 2), replacement: "", selectionAfter: (cursor - 2)..<(cursor - 2))
        }
        if (previous == TeXChar.parenOpen && next == TeXChar.parenClose) || (previous == TeXChar.bracketOpen && next == TeXChar.bracketClose),
           !text.isEscaped(at: cursor - 1) {
            return TextEdit(range: (cursor - 1)..<(cursor + 1), replacement: "", selectionAfter: (cursor - 1)..<(cursor - 1))
        }
        if previous == TeXChar.braceOpen, next == TeXChar.braceClose, !text.isEscaped(at: cursor - 1) {
            return TextEdit(range: (cursor - 1)..<(cursor + 1), replacement: "", selectionAfter: (cursor - 1)..<(cursor - 1))
        }
        if previous == TeXChar.dollar, next == TeXChar.dollar, !text.isEscaped(at: cursor - 1) {
            return TextEdit(range: (cursor - 1)..<(cursor + 1), replacement: "", selectionAfter: (cursor - 1)..<(cursor - 1))
        }
        return nil
    }

    // MARK: - Hilfsfunktionen

    /// Führender Leerraum (Leerzeichen/Tabs) der Zeile, in der `position` liegt.
    static func leadingWhitespace<S: UTF16Source>(_ text: S, lineContaining position: Int) -> String {
        let start = text.lineStart(before: position)
        var end = start
        while end < text.count, text[end] == TeXChar.space || text[end] == TeXChar.tab { end += 1 }
        return text.string(in: start..<end)
    }

    /// Anfang des Absatzes (nach der letzten Leerzeile) vor `position`.
    static func paragraphStart<S: UTF16Source>(_ text: S, before position: Int) -> Int {
        var lineStart = text.lineStart(before: position)
        while lineStart > 0 {
            let previousStart = text.lineStart(before: lineStart - 1)
            let previousLine = text.string(in: previousStart..<(lineStart - 1))
            if previousLine.trimmingCharacters(in: .whitespaces).isEmpty { break }
            lineStart = previousStart
        }
        return lineStart
    }

    /// Ende des Absatzes (vor der nächsten Leerzeile) ab `position`.
    static func paragraphEnd<S: UTF16Source>(_ text: S, after position: Int) -> Int {
        var lineEnd = text.lineEnd(after: position)
        while lineEnd < text.count {
            let nextEnd = text.lineEnd(after: lineEnd + 1)
            let nextLine = text.string(in: (lineEnd + 1)..<nextEnd)
            if nextLine.trimmingCharacters(in: .whitespaces).isEmpty { break }
            lineEnd = nextEnd
        }
        return lineEnd
    }

    /// Anzahl öffnender minus schliessender geschweifter Klammern im Absatz.
    /// > 0 heisst: Es fehlt noch mindestens eine `}`.
    static func braceBalanceInParagraph<S: UTF16Source>(_ text: S, around position: Int) -> Int {
        balanceInParagraph(text, around: position, open: TeXChar.braceOpen, close: TeXChar.braceClose)
    }

    /// Öffnende minus schliessende Klammern einer Art im Absatz (maskierte wie `\(` zählen nicht).
    static func balanceInParagraph<S: UTF16Source>(_ text: S, around position: Int, open: UInt16, close: UInt16) -> Int {
        let start = paragraphStart(text, before: position)
        let end = paragraphEnd(text, after: position)
        var balance = 0
        var i = start
        while i < end {
            let u = text[i]
            if u == TeXChar.percent && !text.isEscaped(at: i) {
                i = text.lineEnd(after: i)
                continue
            }
            if u == open && !text.isEscaped(at: i) { balance += 1 }
            if u == close && !text.isEscaped(at: i) { balance -= 1 }
            i += 1
        }
        return balance
    }

    enum DollarMode: Equatable { case text, inline, display }

    /// In welcher Art Formel (`$…$` oder `$$…$$`) steht der Cursor?
    /// Wertet nur den aktuellen Absatz aus, so wie LaTeX selbst.
    static func dollarMode<S: UTF16Source>(_ text: S, before position: Int) -> DollarMode {
        var mode = DollarMode.text
        var i = paragraphStart(text, before: position)
        while i < position {
            let u = text[i]
            if u == TeXChar.percent && !text.isEscaped(at: i) {
                i = min(position, text.lineEnd(after: i))
                continue
            }
            if u == TeXChar.dollar && !text.isEscaped(at: i) {
                // `$$` zählt nur, wenn beide Zeichen vor dem Cursor liegen.
                let double = i + 1 < position && text[i + 1] == TeXChar.dollar
                switch mode {
                case .text:
                    mode = double ? .display : .inline
                    i += double ? 2 : 1
                case .inline:
                    mode = .text
                    i += 1
                case .display:
                    if double { mode = .text }
                    i += double ? 2 : 1
                }
                continue
            }
            i += 1
        }
        return mode
    }

    /// Steht direkt vor `position` ein `\begin{name` (ohne schliessende Klammer)?
    static func environmentBeingOpened<S: UTF16Source>(_ text: S, before position: Int) -> String? {
        var j = position - 1
        while j >= 0 {
            let u = text[j]
            if TeXChar.isASCIILetter(u) || TeXChar.isASCIIDigit(u) || u == TeXChar.star {
                j -= 1
            } else {
                break
            }
        }
        guard j >= 0, text[j] == TeXChar.braceOpen, j + 1 < position else { return nil }
        guard text.matches("\\begin", at: j - 6), !text.isEscaped(at: j - 6) else { return nil }
        return text.string(in: (j + 1)..<position)
    }

    /// Fehlt zu `\begin{name}` noch ein `\end{name}`? Vergleicht die Anzahl
    /// im ganzen Dokument; das gerade getippte `\begin{name` zählt mit.
    ///
    /// - Parameter beginIsComplete: Steht das `\begin{name}` schon samt `}` im Text
    ///   (dann ist es bereits mitgezählt)?
    static func needsEnd<S: UTF16Source>(for environment: String, in text: S, beginIsComplete: Bool = false) -> Bool {
        let begins = occurrences(of: "\\begin{\(environment)}", in: text) + (beginIsComplete ? 0 : 1)
        let ends = occurrences(of: "\\end{\(environment)}", in: text)
        return begins > ends
    }

    static func occurrences<S: UTF16Source>(of literal: String, in text: S) -> Int {
        let pattern = Array(literal.utf16)
        guard let first = pattern.first, text.count >= pattern.count else { return 0 }
        var count = 0
        var i = 0
        let last = text.count - pattern.count
        while i <= last {
            if text[i] == first && text.matches(literal, at: i) && !BracketMatcher.isInComment(text, i) {
                count += 1
                i += pattern.count
            } else {
                i += 1
            }
        }
        return count
    }
}
