import Foundation

/// Platzhalter `•` in eingefügten Bausteinen.
///
/// Tab springt zum nächsten, ⇧Tab zum vorherigen Platzhalter – aber nur
/// innerhalb des aktuellen Absatzes (bis zur nächsten Leerzeile). So bleibt
/// Tab in normalem Text weiterhin Tab.
public enum Placeholders {
    /// Das Platzhalterzeichen.
    public static let marker = "•"
    /// UTF-16-Wert von `•` (U+2022).
    public static let unit: UInt16 = 0x2022

    /// Nächster Platzhalter ab `position` (einschliesslich) bis zum Ende des Absatzes.
    public static func next<S: UTF16Source>(in text: S, from position: Int) -> Range<Int>? {
        let start = min(max(0, position), text.count)
        guard let paragraph = paragraphBounds(in: text, around: start) else { return nil }
        var i = start
        while i < paragraph.upperBound {
            if text[i] == unit { return i..<(i + 1) }
            i += 1
        }
        return nil
    }

    /// Vorheriger Platzhalter vor `position` (ausschliesslich) bis zum Anfang des Absatzes.
    public static func previous<S: UTF16Source>(in text: S, before position: Int) -> Range<Int>? {
        let end = min(max(0, position), text.count)
        guard let paragraph = paragraphBounds(in: text, around: end) else { return nil }
        var i = end - 1
        while i >= paragraph.lowerBound {
            if text[i] == unit { return i..<(i + 1) }
            i -= 1
        }
        return nil
    }

    /// 1-basierte Zeilennummern aller Zeilen, die noch Platzhalter enthalten (Kommentare ausgenommen).
    public static func lines<S: UTF16Source>(in text: S) -> [Int] {
        var result: [Int] = []
        var line = 1
        var inComment = false
        var i = 0
        while i < text.count {
            let u = text[i]
            if u == TeXChar.newline {
                // Ein Kommentar reicht nur bis zum Zeilenende.
                line += 1
                inComment = false
            } else if inComment {
                // Alles nach `%` erscheint nicht im PDF – Platzhalter dort stören nicht.
            } else if u == TeXChar.percent && !text.isEscaped(at: i) {
                inComment = true
            } else if u == unit && result.last != line {
                result.append(line)
            }
            i += 1
        }
        return result
    }

    // MARK: - Absatzgrenzen

    /// Bereich des Absatzes, in dem `position` liegt: von der ersten bis zum Ende
    /// der letzten nicht leeren Zeile. `nil`, wenn die Zeile selbst leer ist –
    /// auf einer Leerzeile gibt es keinen „aktuellen Absatz“.
    private static func paragraphBounds<S: UTF16Source>(in text: S, around position: Int) -> Range<Int>? {
        let lineStart = text.lineStart(before: position)
        let lineEnd = text.lineEnd(after: position)
        guard !isBlank(text, lineStart..<lineEnd) else { return nil }

        // Rückwärts, bis die vorherige Zeile leer ist (oder der Text beginnt).
        var start = lineStart
        while start > 0 {
            let previousStart = text.lineStart(before: start - 1)
            if isBlank(text, previousStart..<(start - 1)) { break }
            start = previousStart
        }
        // Vorwärts, bis die nächste Zeile leer ist (oder der Text endet).
        var end = lineEnd
        while end < text.count {
            let nextEnd = text.lineEnd(after: end + 1)
            if isBlank(text, (end + 1)..<nextEnd) { break }
            end = nextEnd
        }
        return start..<end
    }

    /// Besteht der Bereich nur aus Leerzeichen und Tabs (oder ist leer)?
    private static func isBlank<S: UTF16Source>(_ text: S, _ range: Range<Int>) -> Bool {
        for i in range {
            let u = text[i]
            if u != TeXChar.space && u != TeXChar.tab && u != TeXChar.carriageReturn { return false }
        }
        return true
    }
}

/// Fügt einen Baustein passend ein.
public enum SnippetInserter {
    /// Berechnet die Einfügung eines Bausteins.
    ///
    /// - `inline`: an der Cursorposition; eine Auswahl wird ersetzt bzw. landet an `Snippet.selectionToken`.
    /// - `block`: auf eigenen Zeilen. Steht in der aktuellen Zeile schon Text, wird davor bzw.
    ///   danach ein Zeilenumbruch ergänzt. Jede Zeile bekommt die Einrückung der aktuellen Zeile.
    /// - `requiresMath` und `inMath == false`: in `$…$` eingepackt.
    /// - Danach ist der erste Platzhalter ausgewählt; gibt es keinen, steht der Cursor am Ende.
    ///
    /// - Parameter inMath: Steht der Cursor bereits in einer Formel? (`TokenizedText.isInsideMath`)
    public static func edit<S: UTF16Source>(
        inserting snippet: Snippet,
        in text: S,
        selection: Range<Int>,
        inMath: Bool
    ) -> TextEdit {
        // Auswahl auf den Text begrenzen, damit nie ausserhalb gelesen wird.
        var lower = min(max(0, selection.lowerBound), text.count)
        var upper = min(max(lower, selection.upperBound), text.count)
        // Nie zwischen die beiden UTF-16-Hälften eines Zeichens wie 😀 schneiden:
        // Eine Auswahl wächst auf ganze Zeichen, ein Cursor rutscht vor das Zeichen.
        let isCursor = lower == upper
        if splitsSurrogatePair(text, at: lower) { lower -= 1 }
        if isCursor {
            upper = lower
        } else if splitsSurrogatePair(text, at: upper) {
            upper += 1
        }
        switch snippet.placement {
        case .inline:
            return inlineEdit(snippet, in: text, lower: lower, upper: upper, inMath: inMath)
        case .block:
            return blockEdit(snippet, in: text, lower: lower, upper: upper, inMath: inMath)
        }
    }

    // MARK: - Im Fliesstext

    /// Baustein an der Cursorposition, z. B. `\frac{•}{•}` mitten in einer Formel.
    private static func inlineEdit<S: UTF16Source>(
        _ snippet: Snippet, in text: S, lower: Int, upper: Int, inMath: Bool
    ) -> TextEdit {
        // Leerraum am Rand der Auswahl bleibt, wo er ist: `«Wort »weiter` wird zu
        // `\footnote{Wort} weiter`, nicht zu `\footnote{Wort }weiter`. Eine Auswahl nur aus
        // Leerraum (etwa eine Leerzeile) zählt wie ein Cursor an ihrem Anfang – sonst
        // landete ein Absatzwechsel mitten in einer Formel.
        var lower = lower
        var upper = upper
        var contentStart = lower
        while contentStart < upper, TeXChar.isWhitespace(text[contentStart]) { contentStart += 1 }
        if contentStart == upper {
            upper = lower
        } else {
            lower = contentStart
            while TeXChar.isWhitespace(text[upper - 1]) { upper -= 1 }
        }

        var selected = text.string(in: lower..<upper)
        let wrapInDollars = snippet.requiresMath && !inMath

        // Mehrzeilige Bausteine: Folgezeilen bekommen die Einrückung der aktuellen Zeile.
        let indent = leadingWhitespace(of: text, lineContaining: lower)
        var lines = splitLines(snippet.body)
        for index in lines.indices.dropFirst() where !lines[index].isEmpty {
            lines[index] = indent + lines[index]
        }
        var body = lines.joined(separator: "\n")
        if wrapInDollars { body = "$" + body + "$" }

        // Endet die Auswahl mit einem Kommentar (`a % b`), wandert er ans Ende des Bausteins.
        // Sonst wäre der Rest des Bausteins auskommentiert, z. B. in `\frac{a % b}{•}`.
        // Ersetzt der Baustein die Auswahl, bleibt der Kommentar so erhalten – und mit
        // ihm der Rest der Zeile, der ja ebenfalls zum Kommentar gehört.
        var comment = ""
        if !body.hasSuffix(Snippet.selectionToken), let split = splitTrailingComment(selected) {
            selected = split.content
            comment = " " + split.comment
        }
        // Ist die Auswahl selbst schon eine Formel `$x$`, wird sie ausgepackt –
        // sonst entstünde `$\frac{$x$}{…}$`, und das versteht LaTeX nicht.
        if wrapInDollars, let inner = innerFormula(of: selected) { selected = inner }
        body = fillSelectionToken(in: body, with: selected) + comment

        // Ein Befehlsname darf nicht mit einem Buchstaben dahinter (oder davor) verschmelzen:
        // `\rVert` vor `x` ergäbe den unbekannten Befehl `\rVertx`. Ein Leerzeichen trennt
        // die beiden; nach einem Befehlsnamen verschluckt LaTeX es ohnehin.
        let units = Array(body.utf16)
        if let next = text.unit(at: upper), isTeXLetter(next), endsWithCommandName(units, before: units.count) {
            body += " "
        }
        if let first = units.first, isTeXLetter(first), endsWithCommandName(text, before: lower) {
            body = " " + body
        }

        return TextEdit(
            range: lower..<upper,
            replacement: body,
            selectionAfter: selectionAfterInsertion(of: body, at: lower)
        )
    }

    // MARK: - Auf eigenen Zeilen

    /// Baustein auf eigenen Zeilen, z. B. eine `align`-Umgebung.
    private static func blockEdit<S: UTF16Source>(
        _ snippet: Snippet, in text: S, lower: Int, upper: Int, inMath: Bool
    ) -> TextEdit {
        var lower = lower
        var upper = upper
        // Ganze Zeilen werden oft samt Zeilenumbruch (`\n` oder `\r\n`) markiert. Der Umbruch
        // am Rand gehört nicht zum Inhalt, sonst entstünden leere Zeilen im Baustein.
        if upper - lower >= 2, text[lower] == TeXChar.carriageReturn, text[lower + 1] == TeXChar.newline {
            lower += 2
        } else if lower < upper, text[lower] == TeXChar.newline {
            lower += 1
        }
        if lower < upper, text[upper - 1] == TeXChar.newline {
            upper -= 1
            if lower < upper, text[upper - 1] == TeXChar.carriageReturn { upper -= 1 }
        }

        let lineStart = text.lineStart(before: lower)
        let lineEnd = text.lineEnd(after: upper)
        // Bei Windows-Zeilenenden gehört das `\r` vor dem `\n` zum Umbruch, nicht zum Text –
        // sonst entstünde nach dem Baustein eine Leerzeile (und damit ein neuer Absatz).
        var contentEnd = lineEnd
        while contentEnd > upper, text[contentEnd - 1] == TeXChar.carriageReturn { contentEnd -= 1 }
        let indent = leadingWhitespace(of: text, lineContaining: lower)

        // Leerraum direkt vor und nach der Einfügestelle fällt weg, damit keine
        // Leerzeichen am Zeilenende übrig bleiben.
        var start = lower
        while start > lineStart, isSpaceOrTab(text[start - 1]) { start -= 1 }
        var end = upper
        while end < contentEnd, isSpaceOrTab(text[end]) { end += 1 }
        let hasTextBefore = start > lineStart
        let hasTextAfter = end < contentEnd

        // Jede Zeile des Bausteins bekommt die Einrückung der aktuellen Zeile. Nur das erste ⟦⟧
        // nimmt die Auswahl auf; weitere werden schon jetzt zu Platzhaltern, damit ein ⟦⟧ im
        // markierten Text danach unangetastet bleibt.
        var body = keepingFirstSelectionToken(snippet.body)
        if snippet.requiresMath && !inMath { body = "$" + body + "$" }
        var lines = splitLines(body).map { $0.isEmpty ? "" : indent + $0 }

        // Markierte Zeilen wandern an die Stelle von ⟦⟧, sonst wird daraus ein Platzhalter.
        // Beginnt die Auswahl am Zeilenanfang (nur Leerraum davor), zählt die
        // Einrückung der ersten Zeile mit – darum ab `lineStart` lesen.
        let markedLines = selectedLines(
            in: text,
            from: hasTextBefore ? lower : lineStart,
            to: upper,
            firstLineComplete: !hasTextBefore
        )
        if let tokenLine = lines.firstIndex(where: { $0.contains(Snippet.selectionToken) }) {
            lines.replaceSubrange(tokenLine...tokenLine, with: insert(markedLines, intoTokenLine: lines[tokenLine]))
        }
        let block = lines.joined(separator: "\n")

        // Stand der Rest der Zeile in einem Kommentar (`% Notiz| weiter`), bleibt er einer –
        // sonst würde aus der Notiz auf der neuen Zeile plötzlich gesetzter Text.
        let remainderIsComment = hasTextAfter
            && (text.commentStart(inLineStartingAt: text.lineStart(before: end)).map { $0 < end } ?? false)
        let prefix = hasTextBefore ? "\n" : ""
        let suffix = hasTextAfter ? "\n" + indent + (remainderIsComment ? "% " : "") : ""
        let blockStart = start + prefix.utf16.count
        return TextEdit(
            range: start..<end,
            replacement: prefix + block + suffix,
            selectionAfter: selectionAfterInsertion(of: block, at: blockStart)
        )
    }

    /// Die markierten Zeilen ohne gemeinsame Einrückung (leere Zeilen werden zu "").
    /// Leer, wenn nichts (oder nur Leerraum) markiert ist.
    ///
    /// - Parameter firstLineComplete: `false`, wenn die Auswahl mitten in einer Zeile
    ///   beginnt. Dann zählt die erste Zeile beim Ausrücken nicht mit.
    private static func selectedLines<S: UTF16Source>(
        in text: S, from start: Int, to end: Int, firstLineComplete: Bool
    ) -> [String] {
        var lines = splitLines(text.string(in: start..<end)).map { line -> String in
            // Leerraum am Zeilenende ist unsichtbar und wird entfernt.
            var trimmed = Substring(line)
            while let last = trimmed.last, last == " " || last == "\t" || last == "\r" { trimmed.removeLast() }
            return String(trimmed)
        }
        var firstComplete = firstLineComplete
        if !firstComplete, let first = lines.first {
            // Die erste Zeile beginnt mitten im Text: ihre Einrückung zählt nicht.
            lines[0] = String(first.drop(while: isIndentation))
        }
        // Leere Zeilen am Anfang und Ende der Auswahl gehören nicht in den Baustein.
        while lines.first?.isEmpty == true {
            lines.removeFirst()
            firstComplete = true
        }
        while lines.last?.isEmpty == true { lines.removeLast() }
        guard !lines.isEmpty else { return [] }

        // Gemeinsame Einrückung aller vollständigen, nicht leeren Zeilen entfernen.
        let measured = firstComplete ? lines[...] : lines.dropFirst()
        let common = measured.filter { !$0.isEmpty }.map { $0.prefix(while: isIndentation).count }.min() ?? 0
        return lines.enumerated().map { index, line in
            if index == 0 && !firstComplete { return line }
            return line.isEmpty ? "" : String(line.dropFirst(common))
        }
    }

    /// Setzt die markierten Zeilen an die Stelle von ⟦⟧ in `tokenLine`
    /// (ohne markierte Zeilen: einen Platzhalter).
    ///
    /// Folgezeilen werden wie die Zeile mit ⟦⟧ eingerückt. Steht davor ein `\item`
    /// (Aufzählung), wird jede markierte Zeile zu einem eigenen Punkt – so wie man es
    /// aus Textverarbeitungen kennt.
    private static func insert(_ lines: [String], intoTokenLine tokenLine: String) -> [String] {
        guard let tokenRange = tokenLine.range(of: Snippet.selectionToken) else { return [tokenLine] }
        let head = String(tokenLine[..<tokenRange.lowerBound])
        let tail = String(tokenLine[tokenRange.upperBound...])
        let lineIndent = String(tokenLine.prefix(while: isIndentation))

        // Endet die Auswahl mit einem Kommentar, kommt er ans Zeilenende hinter `tail` –
        // sonst wäre z. B. die schliessende Klammer von `\section{Titel % Notiz}` auskommentiert.
        var lines = lines
        var comment = ""
        if !tail.isEmpty, let last = lines.last, let split = splitTrailingComment(last) {
            lines[lines.count - 1] = split.content
            comment = " " + split.comment
            while lines.last?.isEmpty == true { lines.removeLast() }
        }
        guard !lines.isEmpty else { return [head + Placeholders.marker + tail + comment] }

        let containsEnvironment = lines.contains { $0.contains("\\begin{") || $0.contains("\\end{") }
        if head.trimmingCharacters(in: .whitespaces) == "\\item", !containsEnvironment {
            // Jede nicht leere Zeile wird ein eigener Punkt.
            let items = lines
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            guard !items.isEmpty else { return [head + Placeholders.marker + tail + comment] }
            var result: [String] = []
            for (index, item) in items.enumerated() {
                if index == 0 {
                    // Ein leerer erster Punkt (nur `\item` markiert) bekommt einen Platzhalter.
                    let text = removingItemCommand(from: item)
                    result.append(head + (text.isEmpty ? Placeholders.marker : text))
                } else if startsWithItemCommand(item) {
                    result.append(lineIndent + item)
                } else {
                    result.append(lineIndent + "\\item " + item)
                }
            }
            result[result.count - 1] += tail + comment
            return result
        }

        var result: [String] = []
        for (index, line) in lines.enumerated() {
            if index == 0 {
                result.append(head + line)
            } else {
                result.append(line.isEmpty ? "" : lineIndent + line)
            }
        }
        result[result.count - 1] += tail + comment
        return result
    }

    /// Beginnt die Zeile mit dem Befehl `\item` (nicht z. B. `\itemsep`)?
    private static func startsWithItemCommand(_ line: String) -> Bool {
        guard line.hasPrefix("\\item") else { return false }
        guard let next = line.dropFirst(5).first else { return true }
        return !(next.isASCII && next.isLetter)
    }

    /// `\item Text` → `Text` (das `\item` steht im Baustein schon da).
    private static func removingItemCommand(from line: String) -> String {
        guard startsWithItemCommand(line) else { return line }
        return String(line.dropFirst(5).drop { $0 == " " || $0 == "\t" })
    }

    // MARK: - Hilfsfunktionen

    /// Ersetzt das erste ⟦⟧ durch `selected` (bzw. einen Platzhalter, wenn nichts
    /// markiert ist) und alle weiteren durch Platzhalter. Ein ⟦⟧ in `selected` bleibt stehen.
    private static func fillSelectionToken(in body: String, with selected: String) -> String {
        var body = keepingFirstSelectionToken(body)
        guard let token = body.range(of: Snippet.selectionToken) else { return body }
        body.replaceSubrange(token, with: selected.isEmpty ? Placeholders.marker : selected)
        return body
    }

    /// Lässt das erste ⟦⟧ stehen und macht aus allen weiteren Platzhalter.
    private static func keepingFirstSelectionToken(_ body: String) -> String {
        guard let first = body.range(of: Snippet.selectionToken) else { return body }
        return String(body[..<first.upperBound])
            + String(body[first.upperBound...]).replacingOccurrences(of: Snippet.selectionToken, with: Placeholders.marker)
    }

    /// Trennt einen Kommentar am Ende ab: `a % b` → (`a`, `% b`). Nur die letzte Zeile zählt,
    /// denn ein Kommentar reicht bis zum Zeilenende; `\%` ist kein Kommentar.
    private static func splitTrailingComment(_ string: String) -> (content: String, comment: String)? {
        let units = Array(string.utf16)
        let lastLineStart = (units.lastIndex(of: TeXChar.newline) ?? -1) + 1
        guard let percent = units.commentStart(inLineStartingAt: lastLineStart) else { return nil }
        var contentEnd = percent
        while contentEnd > 0, TeXChar.isWhitespace(units[contentEnd - 1]) { contentEnd -= 1 }
        return (units.string(in: 0..<contentEnd), units.string(in: percent..<units.count))
    }

    /// Zerlegt Text an jedem `\n` in Zeilen – auch innerhalb von `\r\n`, und zwar auf jeder
    /// Plattform gleich (`components(separatedBy: "\n")` trennt `\r\n` unter Linux nicht).
    private static func splitLines(_ string: String) -> [String] {
        Array(string.utf16)
            .split(separator: TeXChar.newline, omittingEmptySubsequences: false)
            .map { String(decoding: $0, as: UTF16.self) }
    }

    /// Kann das Zeichen in einem Befehlsnamen stehen? Unter XeLaTeX zählen auch Umlaute dazu.
    private static func isTeXLetter(_ u: UInt16) -> Bool {
        if TeXChar.isASCIILetter(u) { return true }
        guard u >= 0x80, let scalar = Unicode.Scalar(u) else { return false }
        return scalar.properties.isAlphabetic
    }

    /// Endet der Text vor `end` mit einem Befehlsnamen wie `\rVert`? (`\\` ist keiner.)
    private static func endsWithCommandName<T: UTF16Source>(_ text: T, before end: Int) -> Bool {
        var start = end
        while start > 0, isTeXLetter(text[start - 1]) { start -= 1 }
        return start < end && start > 0 && text[start - 1] == TeXChar.backslash && !text.isEscaped(at: start - 1)
    }

    /// Liegt `index` zwischen den beiden UTF-16-Hälften eines Zeichens wie 😀?
    private static func splitsSurrogatePair<S: UTF16Source>(_ text: S, at index: Int) -> Bool {
        index > 0 && index < text.count
            && UTF16.isLeadSurrogate(text[index - 1]) && UTF16.isTrailSurrogate(text[index])
    }

    /// Erster Platzhalter im eingefügten Text (ausgewählt), sonst der Cursor an dessen Ende.
    private static func selectionAfterInsertion(of inserted: String, at start: Int) -> Range<Int> {
        let units = Array(inserted.utf16)
        if let index = units.firstIndex(of: Placeholders.unit) {
            return (start + index)..<(start + index + 1)
        }
        let end = start + units.count
        return end..<end
    }

    /// `$x$` → `x`; `nil`, wenn der Text keine einzelne Formel in `$…$` ist.
    private static func innerFormula(of selected: String) -> String? {
        let units = Array(selected.utf16)
        guard units.count >= 2,
              units.first == TeXChar.dollar,
              units.last == TeXChar.dollar,
              !units.isEscaped(at: units.count - 1) else { return nil }
        // Kein `$$…$$` und kein weiteres `$` dazwischen (sonst wären es zwei Formeln).
        for i in 1..<(units.count - 1) where units[i] == TeXChar.dollar && !units.isEscaped(at: i) {
            return nil
        }
        return units.string(in: 1..<(units.count - 1))
    }

    /// Führender Leerraum (Leerzeichen/Tabs) der Zeile, in der `position` liegt.
    private static func leadingWhitespace<S: UTF16Source>(of text: S, lineContaining position: Int) -> String {
        let start = text.lineStart(before: position)
        var end = start
        while end < text.count, isSpaceOrTab(text[end]) { end += 1 }
        return text.string(in: start..<end)
    }

    private static func isSpaceOrTab(_ u: UInt16) -> Bool {
        u == TeXChar.space || u == TeXChar.tab
    }

    /// Gehört das Zeichen zur Einrückung (Leerzeichen oder Tab)?
    private static func isIndentation(_ character: Character) -> Bool {
        character == " " || character == "\t"
    }
}
