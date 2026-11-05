import Foundation

/// „Formatieren“ (⌥⌘L, wie in IntelliJ): bringt den Quelltext in eine saubere Form,
/// ohne am Ergebnis im PDF etwas zu ändern.
///
/// - Rückt Umgebungen, `\[ … \]` und mehrzeilige `{ … }` um zwei Leerzeichen ein
///   (der Inhalt von `document` und `multicols` bleibt bündig). Folgezeilen eines
///   `\item` stehen unter dessen Text – so sieht man, wozu eine Lösung gehört.
/// - Richtet Tabellen, Matrizen, `cases` und mehrzeilige Rechnungen an den `&` aus.
/// - Entfernt Leerzeichen am Zeilenende und doppelte Leerzeilen.
/// - Setzt eine Leerzeile vor Überschriften, die direkt an Text anschliessen.
///
/// Wörtliche Umgebungen (`verbatim`, `lstlisting` …) bleiben unberührt.
/// Ist etwas ausgewählt, werden nur die ausgewählten Zeilen formatiert.
public enum LaTeXFormatter {
    /// Umgebungen, deren Inhalt nicht eingerückt wird.
    static let flatEnvironments: Set<String> = ["document", "multicols", "multicols*"]
    /// Breite von `\item ` – so weit stehen Folgezeilen eines Listenpunkts eingerückt.
    static let itemIndent = 6
    static let listEnvironments: Set<String> = ["itemize", "enumerate", "description", "compactitem", "compactenum", "inparaenum"]
    /// Spalten mit `&`, getrennt durch „ & “.
    static let tableEnvironments: Set<String> = [
        "tabular", "tabular*", "tabularx", "tabulary", "longtable", "array",
        "matrix", "pmatrix", "bmatrix", "Bmatrix", "vmatrix", "Vmatrix", "smallmatrix",
        "cases", "cases*", "dcases", "rcases"
    ]
    /// Rechnungen: `a &= b` – das `&` steht direkt vor dem Rechenzeichen.
    static let equationEnvironments: Set<String> = [
        "align", "align*", "alignat", "alignat*", "flalign", "flalign*",
        "eqnarray", "eqnarray*", "aligned", "alignedat", "split"
    ]
    static let headingCommands = ["\\part", "\\chapter", "\\section", "\\subsection", "\\subsubsection"]
    /// Breitere Zeilen werden nicht mehr ausgerichtet, sondern nur einheitlich getrennt.
    static let maximumAlignedWidth = 140

    // MARK: - Öffentliche Schnittstelle

    /// Formatiert den ganzen Text (leere Auswahl) bzw. die Zeilen der Auswahl.
    /// `nil`, wenn schon alles sauber ist.
    public static func edit<S: UTF16Source>(in text: S, selection: Range<Int>) -> TextEdit? {
        let original = text.string(in: 0..<text.count)
        let oldLines = LineIndex(text)
        let selectedLines: ClosedRange<Int>? = selection.isEmpty
            ? nil
            : (oldLines.line(at: selection.lowerBound) - 1)...(oldLines.line(at: max(selection.lowerBound, selection.upperBound - 1)) - 1)
        let result = format(original, lines: selectedLines)
        guard result.text != original else { return nil }

        let old = Array(original.utf16)
        let new = Array(result.text.utf16)
        // Nur den Teil ersetzen, der sich wirklich ändert (Rückgängig, Einklappen, Scrollen bleiben ruhig).
        var prefix = 0
        while prefix < old.count, prefix < new.count, old[prefix] == new[prefix] { prefix += 1 }
        var suffix = 0
        while suffix < old.count - prefix, suffix < new.count - prefix,
              old[old.count - 1 - suffix] == new[new.count - 1 - suffix] { suffix += 1 }
        let replacement = String(decoding: new[prefix..<(new.count - suffix)], as: UTF16.self)

        let newLines = LineIndex(new)
        func map(_ position: Int) -> Int {
            let line = oldLines.line(at: position) - 1
            let column = oldLines.column(at: position)
            guard line < result.lines.count else { return new.count }
            let mapped = result.lines[line]
            let newLineRange = newLines.range(ofLine: mapped.newLine + 1) ?? new.count..<new.count
            let offset = max(0, column - mapped.oldIndent) + mapped.newIndent
            return min(newLineRange.lowerBound + offset, newLineRange.upperBound)
        }
        let lower = map(selection.lowerBound)
        let upper = selection.isEmpty ? lower : max(lower, map(selection.upperBound))
        return TextEdit(range: prefix..<(old.count - suffix), replacement: replacement, selectionAfter: lower..<upper)
    }

    /// Wohin eine Zeile beim Formatieren wandert.
    public struct LineMapping: Equatable, Sendable {
        /// 0-basierte Zeile im neuen Text.
        public var newLine: Int
        /// Einrückung vorher und nachher (Zeichen).
        public var oldIndent: Int
        public var newIndent: Int
    }

    public struct Result: Equatable, Sendable {
        public var text: String
        /// Für jede alte Zeile (0-basiert).
        public var lines: [LineMapping]
    }

    /// Formatiert `text`; mit `lines` (0-basiert) nur diese Zeilen.
    public static func format(_ text: String, lines selected: ClosedRange<Int>? = nil) -> Result {
        var lines = text.components(separatedBy: "\n")
        let endsWithNewline = text.hasSuffix("\n")
        if endsWithNewline { lines.removeLast() }

        let analyzed = analyze(lines)
        let aligned = alignRows(analyzed, lines: lines)

        var output: [String] = []
        var mappings: [LineMapping] = []
        var previousContent: String?   // letzte nicht leere Zeile (neu)
        for (index, line) in lines.enumerated() {
            let info = analyzed[index]
            let isSelected = selected.map { $0.contains(index) } ?? true
            let oldIndent = line.prefix { $0 == " " || $0 == "\t" }.count
            guard isSelected, !info.isVerbatim else {
                mappings.append(LineMapping(newLine: output.count, oldIndent: oldIndent, newIndent: oldIndent))
                output.append(line)
                if !line.trimmingCharacters(in: .whitespaces).isEmpty { previousContent = line }
                continue
            }
            let carriageReturn = line.hasSuffix("\r") ? "\r" : ""
            let content = aligned[index] ?? line.trimmingCharacters(in: .whitespaces)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\r"))
                .trimmingTrailingWhitespace()

            if content.isEmpty {
                // Höchstens eine Leerzeile hintereinander, keine am Anfang. Bei einer Auswahl
                // entscheidet nur, was ebenfalls ausgewählt ist.
                let previousIsBlank = output.last.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ?? true
                let mayDrop = selected.map { index > $0.lowerBound } ?? true
                mappings.append(LineMapping(newLine: output.count, oldIndent: oldIndent, newIndent: 0))
                if !(previousIsBlank && mayDrop) {
                    output.append(carriageReturn)
                }
                continue
            }

            // Leerzeile vor einer Überschrift, die direkt an Text anschliesst.
            if info.level == 0, isHeading(content), let previous = previousContent,
               let last = output.last, !last.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               !isHeading(previous.trimmingCharacters(in: .whitespaces)), !startsStructure(previous) {
                output.append(carriageReturn)
            }

            let indent = String(repeating: " ", count: info.level)
            mappings.append(LineMapping(newLine: output.count, oldIndent: oldIndent, newIndent: indent.count))
            output.append(indent + content + carriageReturn)
            previousContent = content
        }

        // Keine Leerzeilen am Ende des Dokuments.
        if selected == nil {
            while let last = output.last, last.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                output.removeLast()
            }
            for index in mappings.indices where mappings[index].newLine >= output.count {
                mappings[index].newLine = max(0, output.count - 1)
            }
        }
        var result = output.joined(separator: "\n")
        if endsWithNewline || (selected == nil && !output.isEmpty) { result += "\n" }
        if output.isEmpty && !endsWithNewline { result = "" }
        return Result(text: result, lines: mappings)
    }

    // MARK: - Einrückung

    private enum Frame: Equatable {
        case environment(name: String, id: Int)
        case brace
        case displayMath
        case item

        /// Einrückung in Leerzeichen, die dieses Element zu seinem Inhalt beiträgt.
        var width: Int {
            switch self {
            case .environment(let name, _):
                return flatEnvironments.contains(name) ? 0 : EditingAssistant.indentUnit.count
            case .brace, .displayMath:
                return EditingAssistant.indentUnit.count
            case .item:
                return itemIndent
            }
        }
    }

    struct LineInfo {
        /// Einrückung in Leerzeichen.
        var level = 0
        /// Inhalt einer wörtlichen Umgebung – nicht anfassen.
        var isVerbatim = false
        /// Innerste Umgebung mit Spalten (Name und eindeutige Nummer), falls die Zeile darin steht.
        var alignment: (name: String, id: Int)?
    }

    /// Bestimmt für jede Zeile die Einrückung und die umgebende Tabelle bzw. Rechnung.
    static func analyze(_ lines: [String]) -> [LineInfo] {
        var stack: [Frame] = []
        var verbatim: String?
        var nextID = 0
        var infos: [LineInfo] = []
        infos.reserveCapacity(lines.count)

        func level() -> Int { stack.reduce(0) { $0 + $1.width } }

        func popEnvironment(_ name: String) {
            guard let index = stack.lastIndex(where: {
                if case .environment(let open, _) = $0 { return open == name }
                return false
            }) else { return }
            stack.removeSubrange(index...)
        }

        /// Oberstes Element einer Art entfernen – aber nie über eine Umgebung hinweg.
        func pop(_ frame: Frame) {
            for index in stack.indices.reversed() {
                if stack[index] == frame {
                    stack.removeSubrange(index...)
                    return
                }
                if case .environment = stack[index] { return }
            }
        }

        func innermostEnvironment() -> (name: String, id: Int, bracesAbove: Bool)? {
            var bracesAbove = false
            for frame in stack.reversed() {
                switch frame {
                case .environment(let name, let id): return (name, id, bracesAbove)
                case .brace, .displayMath: bracesAbove = true
                case .item: break
                }
            }
            return nil
        }

        for line in lines {
            var info = LineInfo()
            if let open = verbatim {
                info.isVerbatim = true
                if line.contains("\\end{\(open)}") {
                    verbatim = nil
                    popEnvironment(open)
                }
                infos.append(info)
                continue
            }

            let units = Array(line.utf16)
            var i = 0
            while i < units.count, units[i] == TeXChar.space || units[i] == TeXChar.tab { i += 1 }
            var recorded: Int?
            var alignment: (name: String, id: Int)?
            func record() {
                guard recorded == nil else { return }
                recorded = level()
                if let environment = innermostEnvironment(), !environment.bracesAbove,
                   tableEnvironments.contains(environment.name) || equationEnvironments.contains(environment.name) {
                    alignment = (environment.name, environment.id)
                }
            }

            scan: while i < units.count {
                let u = units[i]
                if u == TeXChar.percent && !units.isEscaped(at: i) {
                    record()
                    break scan
                }
                if u == TeXChar.backslash && !units.isEscaped(at: i) {
                    if units.matches("\\begin{", at: i), let (name, end) = argument(units, from: i + 6) {
                        record()
                        nextID += 1
                        stack.append(.environment(name: name, id: nextID))
                        i = end
                        if LaTeXTokenizer.verbatimEnvironments.contains(name) {
                            let rest = String(decoding: units[end...], as: UTF16.self)
                            if rest.contains("\\end{\(name)}") {
                                popEnvironment(name)
                                break scan
                            }
                            verbatim = name
                            break scan
                        }
                        continue
                    }
                    if units.matches("\\end{", at: i), let (name, end) = argument(units, from: i + 4) {
                        popEnvironment(name)
                        i = end
                        continue
                    }
                    if units.matches("\\[", at: i) {
                        record()
                        stack.append(.displayMath)
                        i += 2
                        continue
                    }
                    if units.matches("\\]", at: i) {
                        pop(.displayMath)
                        i += 2
                        continue
                    }
                    if units.matches("\\item", at: i), !(i + 5 < units.count && TeXChar.isASCIILetter(units[i + 5])) {
                        if stack.last == .item { stack.removeLast() }
                        record()
                        if let environment = innermostEnvironment(), listEnvironments.contains(environment.name) {
                            stack.append(.item)
                        }
                        i += 5
                        continue
                    }
                    if units.matches("\\verb", at: i), i + 5 < units.count, !TeXChar.isASCIILetter(units[i + 5]) {
                        record()
                        let delimiter = units[i + 5]
                        var k = i + 6
                        while k < units.count, units[k] != delimiter { k += 1 }
                        i = k + 1
                        continue
                    }
                    record()
                    i += 1
                    if i < units.count, TeXChar.isASCIILetter(units[i]) {
                        while i < units.count, TeXChar.isASCIILetter(units[i]) { i += 1 }
                    } else {
                        i += 1
                    }
                    continue
                }
                if u == TeXChar.braceOpen && !units.isEscaped(at: i) {
                    record()
                    stack.append(.brace)
                } else if u == TeXChar.braceClose && !units.isEscaped(at: i) {
                    pop(.brace)
                } else if u != TeXChar.space && u != TeXChar.tab && u != TeXChar.carriageReturn {
                    record()
                }
                i += 1
            }
            info.level = recorded ?? level()
            info.alignment = alignment
            infos.append(info)
        }
        return infos
    }

    /// `{name}` ab `index` → Name und Position nach `}`.
    private static func argument(_ units: [UInt16], from index: Int) -> (String, Int)? {
        guard index < units.count, units[index] == TeXChar.braceOpen else { return nil }
        var k = index + 1
        while k < units.count, units[k] != TeXChar.braceClose, k - index < 64 { k += 1 }
        guard k < units.count, units[k] == TeXChar.braceClose else { return nil }
        return (String(decoding: units[(index + 1)..<k], as: UTF16.self).trimmingCharacters(in: .whitespaces), k + 1)
    }

    // MARK: - Ausrichten an &

    private struct Row {
        var cells: [String]
        /// `\\`, `\\[2pt]`, `\\ \hline` … am Zeilenende.
        var ending: String
        var comment: String
    }

    /// Neuer Inhalt (ohne Einrückung) für Zeilen, die ausgerichtet werden.
    static func alignRows(_ infos: [LineInfo], lines: [String]) -> [Int: String] {
        var blocks: [Int: (name: String, rows: [(index: Int, row: Row)])] = [:]
        for (index, info) in infos.enumerated() {
            guard let alignment = info.alignment, !info.isVerbatim else { continue }
            let content = lines[index].trimmingCharacters(in: .whitespaces)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\r"))
                .trimmingTrailingWhitespace()
            guard let row = split(content), row.cells.count > 1 else { continue }
            blocks[alignment.id, default: (alignment.name, [])].rows.append((index, row))
        }

        var result: [Int: String] = [:]
        for block in blocks.values {
            let isEquation = equationEnvironments.contains(block.name)
            let columns = block.rows.map(\.row.cells.count).max() ?? 0
            var widths = [Int](repeating: 0, count: columns)
            for (_, row) in block.rows {
                for (column, cell) in row.cells.enumerated() where column < row.cells.count - 1 {
                    widths[column] = max(widths[column], cell.count)
                }
            }
            let tooWide = widths.reduce(0, +) + columns * 3 > maximumAlignedWidth
            for (index, row) in block.rows {
                var line = ""
                for (column, cell) in row.cells.enumerated() {
                    if column > 0 {
                        line += separator(before: cell, column: column, isEquation: isEquation)
                    }
                    let isLast = column == row.cells.count - 1
                    line += cell
                    if !isLast, !tooWide {
                        line += String(repeating: " ", count: widths[column] - cell.count)
                    }
                }
                line = line.trimmingTrailingWhitespace()
                if !row.ending.isEmpty { line += " " + row.ending }
                if !row.comment.isEmpty { line += " " + row.comment }
                result[index] = line
            }
        }
        return result
    }

    /// In Rechnungen klebt das `&` am Rechenzeichen (`a &= b`), sonst steht es frei (` & `).
    private static func separator(before cell: String, column: Int, isEquation: Bool) -> String {
        guard isEquation, column % 2 == 1 else { return cell.isEmpty ? " &" : " & " }
        if cell.isEmpty { return " &" }
        if let first = cell.first, "=<>\\+-".contains(first) { return " &" }
        return " & "
    }

    /// Zerlegt eine Zeile an den `&` (nicht in `{…}`, nicht `\&`).
    private static func split(_ content: String) -> Row? {
        let units = Array(content.utf16)
        var cells: [String] = []
        var current: [UInt16] = []
        var depth = 0
        var comment = ""
        var i = 0
        while i < units.count {
            let u = units[i]
            if u == TeXChar.percent && !units.isEscaped(at: i) {
                comment = String(decoding: units[i...], as: UTF16.self)
                break
            }
            if u == TeXChar.braceOpen && !units.isEscaped(at: i) { depth += 1 }
            if u == TeXChar.braceClose && !units.isEscaped(at: i) { depth -= 1 }
            if u == TeXChar.ampersand && !units.isEscaped(at: i) && depth == 0 {
                cells.append(String(decoding: current, as: UTF16.self).trimmingCharacters(in: .whitespaces))
                current = []
            } else {
                current.append(u)
            }
            i += 1
        }
        guard depth == 0, !cells.isEmpty else { return nil }
        // Zeilenende `\\` (mit allem danach) von der letzten Zelle trennen.
        let lastUnits = current
        var ending = ""
        var k = 0
        var lastCell = lastUnits
        var braces = 0
        while k + 1 < lastUnits.count {
            if lastUnits[k] == TeXChar.braceOpen { braces += 1 }
            if lastUnits[k] == TeXChar.braceClose { braces -= 1 }
            if braces == 0, lastUnits[k] == TeXChar.backslash, lastUnits[k + 1] == TeXChar.backslash, !lastUnits.isEscaped(at: k) {
                ending = String(decoding: lastUnits[k...], as: UTF16.self).trimmingCharacters(in: .whitespaces)
                lastCell = Array(lastUnits[..<k])
                break
            }
            k += 1
        }
        cells.append(String(decoding: lastCell, as: UTF16.self).trimmingCharacters(in: .whitespaces))
        return Row(cells: cells, ending: ending, comment: comment)
    }

    // MARK: - Hilfen

    private static func isHeading(_ content: String) -> Bool {
        headingCommands.contains { command in
            guard content.hasPrefix(command) else { return false }
            let rest = content.dropFirst(command.count)
            guard let next = rest.first else { return true }
            return next == "{" || next == "*" || next == "[" || next == " "
        }
    }

    /// Zeilen, nach denen eine Überschrift ohne Leerzeile stehen darf.
    private static func startsStructure(_ line: String) -> Bool {
        let content = line.trimmingCharacters(in: .whitespaces)
        return content.hasPrefix("%") || content.hasPrefix("\\begin{") || content.hasPrefix("\\label")
            || content.hasPrefix("\\maketitle") || content.hasPrefix("\\tableofcontents") || content.hasPrefix("\\newpage")
            || content.hasPrefix("\\clearpage") || content.hasPrefix("\\appendix") || content.hasPrefix("\\frame")
    }
}

private extension String {
    func trimmingTrailingWhitespace() -> String {
        var end = endIndex
        while end > startIndex {
            let before = index(before: end)
            guard self[before] == " " || self[before] == "\t" else { break }
            end = before
        }
        return String(self[..<end])
    }
}
