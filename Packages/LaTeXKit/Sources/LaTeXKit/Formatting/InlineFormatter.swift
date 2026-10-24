import Foundation

/// Zeichenformate wie in Word – jeweils ein LaTeX-Befehl mit einem Argument.
public enum InlineStyle: String, CaseIterable, Sendable, Identifiable {
    case bold          // \textbf
    case italic        // \textit
    case underline     // \underline
    case emphasis      // \emph
    case sansSerif     // \textsf
    case monospace     // \texttt
    case smallCaps     // \textsc

    public var id: String { rawValue }

    /// Befehlsname ohne Backslash, z. B. `textbf`.
    public var command: String {
        switch self {
        case .bold: return "textbf"
        case .italic: return "textit"
        case .underline: return "underline"
        case .emphasis: return "emph"
        case .sansSerif: return "textsf"
        case .monospace: return "texttt"
        case .smallCaps: return "textsc"
        }
    }

    public var title: String {
        switch self {
        case .bold: return "Fett"
        case .italic: return "Kursiv"
        case .underline: return "Unterstrichen"
        case .emphasis: return "Hervorgehoben"
        case .sansSerif: return "Serifenlos"
        case .monospace: return "Schreibmaschine"
        case .smallCaps: return "Kapitälchen"
        }
    }

    /// SF-Symbol für Knöpfe und Menüs.
    public var symbol: String {
        switch self {
        case .bold: return "bold"
        case .italic: return "italic"
        case .underline: return "underline"
        case .emphasis: return "textformat.abc.dottedunderline"
        case .sansSerif: return "textformat"
        case .monospace: return "chevron.left.forwardslash.chevron.right"
        case .smallCaps: return "textformat.size.smaller"
        }
    }
}

/// LaTeX-Schriftgrössen, von klein nach gross.
public enum FontSize: String, CaseIterable, Sendable, Identifiable {
    case tiny, scriptsize, footnotesize, small, normalsize, large, Large, LARGE, huge, Huge

    public var id: String { rawValue }
    /// Befehlsname ohne Backslash (`large`).
    public var command: String { rawValue }

    public var title: String {
        switch self {
        case .tiny: return "Winzig"
        case .scriptsize: return "Sehr klein"
        case .footnotesize: return "Fussnotengrösse"
        case .small: return "Klein"
        case .normalsize: return "Normal"
        case .large: return "Gross"
        case .Large: return "Grösser"
        case .LARGE: return "Sehr gross"
        case .huge: return "Riesig"
        case .Huge: return "Gigantisch"
        }
    }

    /// Ungefährer Skalierungsfaktor zur Normalgrösse (für die Vorschau im Menü).
    public var relativeScale: Double {
        switch self {
        case .tiny: return 0.5
        case .scriptsize: return 0.7
        case .footnotesize: return 0.8
        case .small: return 0.9
        case .normalsize: return 1.0
        case .large: return 1.2
        case .Large: return 1.44
        case .LARGE: return 1.73
        case .huge: return 2.07
        case .Huge: return 2.49
        }
    }
}

/// Textfarben (benötigen das Paket `xcolor`).
public enum TextColor: String, CaseIterable, Sendable, Identifiable {
    case red, blue, green, orange, violet, teal, gray

    public var id: String { rawValue }

    /// Farbname für `\textcolor{…}` – nur Namen, die `xcolor` ohne Optionen kennt.
    public var latexName: String {
        switch self {
        case .red: return "red"
        case .blue: return "blue"
        case .green: return "green!50!black"
        case .orange: return "orange"
        case .violet: return "violet"
        case .teal: return "teal"
        case .gray: return "gray"
        }
    }

    public var title: String {
        switch self {
        case .red: return "Rot"
        case .blue: return "Blau"
        case .green: return "Grün"
        case .orange: return "Orange"
        case .violet: return "Violett"
        case .teal: return "Petrol"
        case .gray: return "Grau"
        }
    }

    /// Farbwert (0…1) für das Farbfeld im Menü – entspricht der Darstellung im PDF.
    public var rgb: (red: Double, green: Double, blue: Double) {
        switch self {
        case .red: return (1, 0, 0)
        case .blue: return (0, 0, 1)
        case .green: return (0, 0.5, 0)
        case .orange: return (1, 0.5, 0)
        case .violet: return (0.5, 0, 0.5)
        case .teal: return (0, 0.5, 0.5)
        case .gray: return (0.5, 0.5, 0.5)
        }
    }
}

/// Zeichenformat an der Cursorposition – damit die Knöpfe der Format-Leiste den Zustand anzeigen.
public struct FormattingState: Equatable, Sendable {
    /// Alle Stile, in deren Argument der Cursor bzw. die ganze Auswahl steht.
    public var styles: Set<InlineStyle>
    /// Innerste Grössenangabe (`{\large …}`), falls vorhanden.
    public var fontSize: FontSize?
    /// Innerste Textfarbe (`\textcolor{…}{…}`), falls vorhanden und bekannt.
    public var color: TextColor?

    public init(styles: Set<InlineStyle> = [], fontSize: FontSize? = nil, color: TextColor? = nil) {
        self.styles = styles
        self.fontSize = fontSize
        self.color = color
    }
}

/// Zeichenformatierung per Klick – wie in Word, aber als LaTeX-Befehle.
///
/// Verhalten (wie in Word):
/// - Mit Auswahl: Auswahl wird eingepackt (`\textbf{Auswahl}`) und bleibt ausgewählt.
///   Ist die Auswahl schon genau so formatiert, wird die Formatierung entfernt.
/// - Ohne Auswahl im Argument eines passenden Befehls: Formatierung entfernen.
/// - Ohne Auswahl mitten in einem Wort: das Wort wird formatiert.
/// - Sonst: `\textbf{}` einfügen, Cursor zwischen die Klammern.
///
/// Gesucht wird nur im aktuellen Absatz; Kommentare und maskierte Klammern zählen nicht.
public enum InlineFormatter {
    public static func state<S: UTF16Source>(in text: S, selection: Range<Int>) -> FormattingState {
        let selection = FormattingText.clamp(selection, in: text)
        let range = selection.isEmpty ? selection : (safeSelection(selection, in: text) ?? selection)
        let scan = GroupScan(text, around: range)
        // Von innen nach aussen: zuerst Gruppen, die genau ausgewählt sind
        // (`«\textbf{Wort}»`), dann alle Gruppen, in deren Inhalt die Auswahl liegt.
        let groups = (range.isEmpty ? [] : Array(scan.peel(range).reversed())) + scan.enclosing(range)
        var state = FormattingState()
        for group in groups {
            if let style = group.style { state.styles.insert(style) }
        }
        state.fontSize = groups.first { $0.size != nil }?.size
        if let nameRange = groups.first(where: { $0.colorNameRange != nil })?.colorNameRange {
            let name = scan.colorName(in: nameRange)
            state.color = TextColor.allCases.first { $0.latexName == name }
        }
        return state
    }

    public static func toggle<S: UTF16Source>(_ style: InlineStyle, in text: S, selection: Range<Int>) -> TextEdit {
        let selection = FormattingText.clamp(selection, in: text)
        guard !isInVerbatim(text, at: selection.lowerBound) else { return FormattingText.noChange(selection) }
        let prefix = "\\" + style.command + "{"
        if selection.isEmpty {
            let scan = GroupScan(text, around: selection)
            // Cursor im Argument von `\textbf{…}`: Formatierung entfernen.
            if let group = scan.enclosing(selection).first(where: { $0.style == style }) {
                return scan.unwrap(group, keeping: selection)
            }
            return wrapWordOrInsert(prefix, "}", in: text, at: selection.lowerBound, scan: scan)
        }
        guard let adjusted = safeSelection(selection, in: text) else { return FormattingText.noChange(selection) }
        let scan = GroupScan(text, around: adjusted)
        guard let range = scan.completed(adjusted) else { return FormattingText.noChange(selection) }
        let (extended, outer) = scan.extend(range)
        // Auswahl ist schon genau so formatiert (auch über andere Formate hinweg,
        // z. B. `\textbf{\textit{«Wort»}}`): Formatierung entfernen.
        let chain = Array(scan.peel(range).reversed()) + outer
        if let group = chain.first(where: { $0.style == style }) {
            return scan.unwrap(group, keeping: range)
        }
        // Auswahl liegt mitten in einem gleich formatierten Text: nur diesen Teil
        // herauslösen, wie in Word (`\textbf{Hallo }«Welt»`).
        if let host = scan.enclosing(extended).first, host.style == style, host.size == nil,
           FormattingText.isBalanced(text, extended) {
            return scan.split(host, around: extended, keeping: range, prefix: prefix)
        }
        return wrap(range, prefix, "}", in: text, keeping: range)
    }

    /// `{\large Auswahl}`. Innerhalb einer bestehenden Grössengruppe wird der Befehl ersetzt;
    /// `.normalsize` entfernt die Gruppe.
    public static func setFontSize<S: UTF16Source>(_ size: FontSize, in text: S, selection: Range<Int>) -> TextEdit {
        let selection = FormattingText.clamp(selection, in: text)
        guard !isInVerbatim(text, at: selection.lowerBound) else { return FormattingText.noChange(selection) }
        let prefix = "{\\" + size.command + " "
        if selection.isEmpty {
            let scan = GroupScan(text, around: selection)
            if let group = scan.enclosing(selection).first(where: { $0.size != nil }) {
                if size == .normalsize { return scan.removeSize(group, keeping: selection) }
                if group.size == size { return FormattingText.noChange(selection) }
                return scan.replaceSize(group, with: size, keeping: selection)
            }
            guard size != .normalsize else { return FormattingText.noChange(selection) }
            return wrapWordOrInsert(prefix, "}", in: text, at: selection.lowerBound, scan: scan)
        }
        guard let adjusted = safeSelection(selection, in: text) else { return FormattingText.noChange(selection) }
        let scan = GroupScan(text, around: adjusted)
        guard let range = scan.completed(adjusted) else { return FormattingText.noChange(selection) }
        let (extended, outer) = scan.extend(range)
        // Genau eine Grössengruppe ausgewählt: Befehl ersetzen bzw. Gruppe entfernen.
        if let group = (Array(scan.peel(range).reversed()) + outer).first(where: { $0.size != nil }) {
            if size == .normalsize { return scan.removeSize(group, keeping: range) }
            if group.size == size { return FormattingText.noChange(selection) }
            return scan.replaceSize(group, with: size, keeping: range)
        }
        let enclosing = scan.enclosing(extended)
        let sizeGroup = enclosing.first { $0.size != nil }
        if size == .normalsize {
            guard let group = sizeGroup, let current = group.size else { return FormattingText.noChange(selection) }
            // Teil einer `{\large …}`-Gruppe: nur die Auswahl herauslösen.
            if let host = enclosing.first, host.open == group.open, host.role == .plain,
               host.innerContent.lowerBound <= extended.lowerBound,
               FormattingText.isBalanced(text, extended) {
                return scan.split(host, around: extended, keeping: range, prefix: "{\\" + current.command + " ")
            }
            return scan.removeSize(group, keeping: range)
        }
        // Teil einer anderen Grösse: nur die Auswahl bekommt die neue Grösse (Gruppe in der Gruppe).
        if sizeGroup?.size == size { return FormattingText.noChange(selection) }
        return wrap(range, prefix, "}", in: text, keeping: range)
    }

    /// `\textcolor{red}{Auswahl}`. Innerhalb einer bestehenden Farbe wird die Farbe ersetzt;
    /// `nil` entfernt sie. Benötigt `PackageRequirement.xcolor`.
    public static func setColor<S: UTF16Source>(_ color: TextColor?, in text: S, selection: Range<Int>) -> TextEdit {
        let selection = FormattingText.clamp(selection, in: text)
        guard !isInVerbatim(text, at: selection.lowerBound) else { return FormattingText.noChange(selection) }
        if selection.isEmpty {
            let scan = GroupScan(text, around: selection)
            // Cursor im farbigen Text oder im Farbnamen selbst (`\textcolor{re|d}{…}`).
            if let group = scan.enclosing(selection).first(where: { $0.colorNameRange != nil })
                ?? scan.coloredGroup(namedAround: selection.lowerBound) {
                guard let color else { return scan.unwrap(group, keeping: selection) }
                return scan.recolor(group, to: color, keeping: selection)
            }
            guard let color else { return FormattingText.noChange(selection) }
            return wrapWordOrInsert(colorPrefix(color), "}", in: text, at: selection.lowerBound, scan: scan)
        }
        guard let adjusted = safeSelection(selection, in: text) else { return FormattingText.noChange(selection) }
        let scan = GroupScan(text, around: adjusted)
        guard let range = scan.completed(adjusted) else { return FormattingText.noChange(selection) }
        let (extended, outer) = scan.extend(range)
        // Genau ein farbiger Text ausgewählt: Farbe ersetzen bzw. entfernen.
        if let group = (Array(scan.peel(range).reversed()) + outer).first(where: { $0.colorNameRange != nil }) {
            guard let color else { return scan.unwrap(group, keeping: range) }
            return scan.recolor(group, to: color, keeping: range)
        }
        let enclosing = scan.enclosing(extended)
        let colorGroup = enclosing.first { $0.colorNameRange != nil }
        guard let color else {
            guard let group = colorGroup else { return FormattingText.noChange(selection) }
            // Teil eines farbigen Textes: nur die Auswahl herauslösen.
            if let host = enclosing.first, host.open == group.open, host.size == nil,
               FormattingText.isBalanced(text, extended) {
                let prefix = text.string(in: host.start..<(host.open + 1))
                return scan.split(host, around: extended, keeping: range, prefix: prefix)
            }
            return scan.unwrap(group, keeping: range)
        }
        if let nameRange = colorGroup?.colorNameRange, scan.colorName(in: nameRange) == color.latexName {
            return FormattingText.noChange(selection)
        }
        return wrap(range, colorPrefix(color), "}", in: text, keeping: range)
    }

    // MARK: - Hilfsfunktionen

    /// In wörtlichen Umgebungen (`verbatim`, `lstlisting`) wären Befehle nur Text.
    private static func isInVerbatim<S: UTF16Source>(_ text: S, at position: Int) -> Bool {
        BlockEditor.enclosingEnvironment(in: text, at: position, named: LaTeXTokenizer.verbatimEnvironments) != nil
    }

    private static func colorPrefix(_ color: TextColor) -> String {
        "\\textcolor{" + color.latexName + "}{"
    }

    /// Packt `range` in `prefix … suffix` ein; die Auswahl wandert mit dem Text mit.
    private static func wrap<S: UTF16Source>(
        _ range: Range<Int>, _ prefix: String, _ suffix: String,
        in text: S, keeping selection: Range<Int>
    ) -> TextEdit {
        var builder = FormattingEditBuilder(range: range)
        builder.insert(prefix)
        builder.copy(range, from: text, preferred: true)
        builder.insert(suffix)
        return builder.edit(selection: selection)
    }

    /// Ohne Auswahl: Wort unter dem Cursor einpacken oder eine leere Gruppe einfügen.
    private static func wrapWordOrInsert<S: UTF16Source>(
        _ prefix: String, _ suffix: String, in text: S, at cursor: Int, scan: GroupScan<S>
    ) -> TextEdit {
        // In `\label{…}`, `\begin{…}` oder einem Farbnamen hat Formatierung nichts verloren:
        // dann kommt sie vor den ganzen Befehl.
        if let key = scan.enclosing(cursor..<cursor).last(where: { $0.isKeyArgument }) {
            let caret = key.start + prefix.utf16.count
            return TextEdit(range: key.start..<key.start, replacement: prefix + suffix, selectionAfter: caret..<caret)
        }
        if let word = wordRange(in: text, at: cursor) {
            return wrap(word, prefix, suffix, in: text, keeping: cursor..<cursor)
        }
        // Mitten in einem Befehlsnamen (`\tex|tbf`) darf nichts eingefügt werden:
        // dann kommt die neue Gruppe vor den Befehl.
        let position = commandToken(in: text, around: cursor)?.lowerBound ?? cursor
        let caret = position + prefix.utf16.count
        return TextEdit(range: position..<position, replacement: prefix + suffix, selectionAfter: caret..<caret)
    }

    /// Wort (Buchstaben inkl. Umlaute, Ziffern) um den Cursor – nur, wenn der Cursor
    /// *mitten* im Wort steht und das Wort kein Befehlsname wie `\textbf` ist.
    private static func wordRange<S: UTF16Source>(in text: S, at cursor: Int) -> Range<Int>? {
        guard cursor > 0, cursor < text.count,
              TeXChar.isAlphanumeric(text[cursor - 1]), TeXChar.isAlphanumeric(text[cursor]) else { return nil }
        var start = cursor
        while start > 0, TeXChar.isAlphanumeric(text[start - 1]) { start -= 1 }
        var end = cursor
        while end < text.count, TeXChar.isAlphanumeric(text[end]) { end += 1 }
        if start > 0, text[start - 1] == TeXChar.backslash, !text.isEscaped(at: start - 1) { return nil }
        return start..<end
    }

    /// Befehl wie `\textbf` oder `\%`, in dessen Innerem `position` liegt
    /// (hinter dem Backslash, vor dem Ende des Namens). Dort darf nichts eingefügt werden.
    private static func commandToken<S: UTF16Source>(in text: S, around position: Int) -> Range<Int>? {
        var start = position
        while start > 0, TeXChar.isASCIILetter(text[start - 1]) { start -= 1 }
        guard start > 0, text[start - 1] == TeXChar.backslash, !text.isEscaped(at: start - 1) else { return nil }
        if start == position {
            // Direkt hinter dem Backslash: Befehlswort (`\|textbf`) oder Sonderzeichen (`\|%`).
            guard position < text.count else { return (position - 1)..<position }
            if !TeXChar.isASCIILetter(text[position]) { return (position - 1)..<(position + 1) }
        }
        var end = position
        while end < text.count, TeXChar.isASCIILetter(text[end]) { end += 1 }
        guard end > position else { return nil }
        return (start - 1)..<end
    }

    /// Auswahl so anpassen, dass das Einpacken nichts kaputt macht:
    /// - Leerraum am Rand bleibt draussen (`«Wort »` → `\textbf{Wort} `).
    /// - `{` und `}` landen beide im Code oder beide im Kommentar.
    /// - Befehle werden nicht zerschnitten (`\te«xtit{x}»` → ganzes `\textit{x}`).
    /// `nil`, wenn nichts Sinnvolles übrig bleibt.
    private static func safeSelection<S: UTF16Source>(_ selection: Range<Int>, in text: S) -> Range<Int>? {
        var lower = selection.lowerBound
        var upper = selection.upperBound
        while lower < upper, TeXChar.isWhitespace(text[lower]) { lower += 1 }
        while upper > lower, TeXChar.isWhitespace(text[upper - 1]) { upper -= 1 }
        if lower == upper { (lower, upper) = (selection.lowerBound, selection.upperBound) }

        let lowerInComment = BracketMatcher.isInComment(text, lower)
        let upperInComment = BracketMatcher.isInComment(text, upper)
        let sameLine = text.lineStart(before: lower) == text.lineStart(before: upper)
        var newLower = lower
        var newUpper = upper
        if lowerInComment && !(upperInComment && sameLine) {
            // Anfang im Kommentar: erst auf der nächsten Zeile beginnen.
            newLower = min(text.count, text.lineEnd(after: lower) + 1)
        }
        if upperInComment && !(lowerInComment && sameLine) {
            // Ende im Kommentar: vor dem Kommentar aufhören.
            newUpper = text.commentStart(inLineStartingAt: text.lineStart(before: upper)) ?? upper
        }
        if newLower != lower || newUpper != upper {
            while newLower < newUpper, TeXChar.isWhitespace(text[newLower]) { newLower += 1 }
            while newUpper > newLower, TeXChar.isWhitespace(text[newUpper - 1]) { newUpper -= 1 }
            if newLower < newUpper {
                (lower, upper) = (newLower, newUpper)
            } else if lowerInComment != upperInComment {
                return nil
            }
        }

        if let token = commandToken(in: text, around: lower) { lower = token.lowerBound }
        if let token = commandToken(in: text, around: upper) {
            upper = token.upperBound > upper ? token.upperBound : token.lowerBound
        }
        guard lower < upper,
              BracketMatcher.isInComment(text, lower) == BracketMatcher.isInComment(text, upper) else { return nil }
        return lower..<upper
    }
}

// MARK: - Klammergruppen im Absatz

/// Eine Klammergruppe `{…}` im aktuellen Absatz und wozu sie gehört.
private struct FormatGroup {
    enum Role: Equatable {
        /// Einfache Gruppe ohne Befehl davor, z. B. `{\large …}`.
        case plain
        /// Argument eines Zeichenformats, z. B. `\textbf{…}`.
        case style(InlineStyle)
        /// Erstes Argument von `\textcolor` (der Farbname).
        case colorName
        /// Zweites Argument von `\textcolor{name}{…}`; `nameRange` zeigt auf den Farbnamen.
        case colored(nameRange: Range<Int>)
        /// Argument eines anderen Befehls (`\frac{…}`, `x^{…}`): Diese Klammern bleiben immer stehen.
        case argument
    }

    /// Position der öffnenden Klammer.
    let open: Int
    /// Position der schliessenden Klammer.
    let close: Int
    /// Beginn des ganzen Konstrukts: Backslash von `\textbf` bzw. `\textcolor`, sonst die Klammer.
    var start: Int
    var role: Role = .plain
    /// Grössenbefehl direkt nach der Klammer (`{\large …}`).
    var size: FontSize?
    /// Nur `\large` (Backslash und Name).
    var sizeCommand: Range<Int>?
    /// Position nach `\large` und den folgenden Leerzeichen.
    var sizeEnd: Int?
    /// Befehl, zu dem die Gruppe als Argument gehört (`frac`, `label`, `textbf` …).
    var command: String?
    /// Argument ohne Fliesstext (`\label{…}`, `\begin{…}`, Farbname): Dort darf keine
    /// Formatierung hinein.
    var isKeyArgument = false

    init(open: Int, close: Int) {
        self.open = open
        self.close = close
        self.start = open
    }

    /// Alles von `\textbf` bis zur schliessenden Klammer.
    var whole: Range<Int> { start..<(close + 1) }
    /// Zwischen den Klammern.
    var content: Range<Int> { (open + 1)..<close }
    /// Zwischen den Klammern, aber ohne einen Grössenbefehl am Anfang.
    var innerContent: Range<Int> { (sizeEnd ?? open + 1)..<close }

    var style: InlineStyle? {
        if case .style(let style) = role { return style }
        return nil
    }

    var colorNameRange: Range<Int>? {
        if case .colored(let nameRange) = role { return nameRange }
        return nil
    }

    /// Ist die ganze Gruppe eine Formatierung (`\textbf{…}`, `\textcolor{…}{…}`, `{\large …}`)?
    var isFormatting: Bool { style != nil || colorNameRange != nil || (role == .plain && size != nil) }
}

/// Findet alle Klammergruppen im Absatz um eine Position und bestimmt ihre Bedeutung.
/// Kommentare und maskierte Klammern (`\{`) werden übersprungen.
private struct GroupScan<S: UTF16Source> {
    let text: S
    /// Nach der Position der öffnenden Klammer sortiert.
    private(set) var groups: [FormatGroup] = []

    init(_ text: S, around range: Range<Int>) {
        self.text = text
        let start = EditingAssistant.paragraphStart(text, before: range.lowerBound)
        let end = EditingAssistant.paragraphEnd(text, after: range.upperBound)

        // 1. Zusammengehörige Klammern finden.
        var stack: [Int] = []
        var pairs: [(open: Int, close: Int)] = []
        var i = start
        while i < end {
            let unit = text[i]
            if unit == TeXChar.percent, !text.isEscaped(at: i) {
                i = text.lineEnd(after: i)
                continue
            }
            if unit == TeXChar.braceOpen, !text.isEscaped(at: i) {
                stack.append(i)
            } else if unit == TeXChar.braceClose, !text.isEscaped(at: i), let open = stack.popLast() {
                pairs.append((open, i))
            }
            i += 1
        }
        pairs.sort { $0.open < $1.open }

        // 2. Bedeutung jeder Gruppe bestimmen (von vorne nach hinten, damit das
        //    zweite Argument von `\textcolor` sein erstes schon kennt).
        var indexByClose: [Int: Int] = [:]
        for pair in pairs {
            var group = FormatGroup(open: pair.open, close: pair.close)
            classify(&group, indexByClose: indexByClose)
            if group.role != .colorName { detectSize(&group) }
            indexByClose[pair.close] = groups.count
            groups.append(group)
        }
    }

    private func classify(_ group: inout FormatGroup, indexByClose: [Int: Int]) {
        var j = group.open - 1
        while j >= 0, text[j] == TeXChar.space || text[j] == TeXChar.tab { j -= 1 }
        guard j >= 0 else { return }
        let unit = text[j]
        if TeXChar.isASCIILetter(unit) {
            // `\textbf{`, `\textcolor{` oder ein anderer Befehl – oder nur ein Wort davor.
            if let command = commandWord(endingAt: j + 1) { assign(command, to: &group) }
        } else if unit == TeXChar.braceClose, !text.isEscaped(at: j) {
            // Folgt direkt auf eine andere Gruppe: weiteres Argument desselben Befehls
            // (`\textcolor{red}{…}`, `\frac{a}{b}`, `\begin{tabular}{cc}`).
            group.role = .argument
            guard let index = indexByClose[j] else { return }
            let previous = groups[index]
            if previous.role == .colorName {
                group.role = .colored(nameRange: previous.content)
                group.start = previous.start
                group.command = previous.command
            } else if previous.role == .argument, let name = previous.command {
                group.start = previous.start
                group.command = name
                group.isKeyArgument = previous.isKeyArgument && keyCommandsForAllArguments.contains(name)
            }
        } else if unit == TeXChar.bracketClose, !text.isEscaped(at: j) {
            // Nach einem optionalen Argument, z. B. `\textcolor[rgb]{…}`, `\includegraphics[…]{…}`.
            group.role = .argument
            var k = j - 1
            while k >= 0, text[k] != TeXChar.bracketOpen, text[k] != TeXChar.newline { k -= 1 }
            guard k >= 0, text[k] == TeXChar.bracketOpen else { return }
            var e = k
            while e > 0, text[e - 1] == TeXChar.space || text[e - 1] == TeXChar.tab { e -= 1 }
            if let command = commandWord(endingAt: e) { assign(command, to: &group) }
        } else if unit == TeXChar.caret || unit == TeXChar.underscore {
            group.role = .argument
        }
    }

    /// Die Gruppe ist das erste Argument von `command`.
    private func assign(_ command: (name: String, start: Int), to group: inout FormatGroup) {
        group.start = command.start
        group.command = command.name
        if let style = InlineStyle.allCases.first(where: { $0.command == command.name }) {
            group.role = .style(style)
        } else if command.name == "textcolor" {
            group.role = .colorName
            group.isKeyArgument = true
        } else {
            group.role = .argument
            group.isKeyArgument = keyArgumentCommands.contains(command.name)
        }
    }

    /// Befehlswort (`\textbf`), das direkt vor `end` endet.
    private func commandWord(endingAt end: Int) -> (name: String, start: Int)? {
        var s = end
        while s > 0, TeXChar.isASCIILetter(text[s - 1]) { s -= 1 }
        guard s < end, s > 0, text[s - 1] == TeXChar.backslash, !text.isEscaped(at: s - 1) else { return nil }
        return (text.string(in: s..<end), s - 1)
    }

    /// Steht direkt nach der Klammer ein Grössenbefehl (`{\large …}`)?
    private func detectSize(_ group: inout FormatGroup) {
        var k = group.open + 1
        while k < group.close, TeXChar.isWhitespace(text[k]) { k += 1 }
        guard k < group.close, text[k] == TeXChar.backslash else { return }
        var e = k + 1
        while e < group.close, TeXChar.isASCIILetter(text[e]) { e += 1 }
        guard let size = FontSize(rawValue: text.string(in: (k + 1)..<e)) else { return }
        var after = e
        while after < group.close, text[after] == TeXChar.space || text[after] == TeXChar.tab { after += 1 }
        group.size = size
        group.sizeCommand = k..<e
        group.sizeEnd = after
    }

    // MARK: Suchen

    /// Alle Gruppen, in deren Inhalt `range` liegt – die innerste zuerst.
    func enclosing(_ range: Range<Int>) -> [FormatGroup] {
        groups.filter { $0.open < range.lowerBound && range.upperBound <= $0.close }.reversed()
    }

    /// Formatierungen, die genau die Auswahl ausmachen: `«\textbf{\textit{x}}»`
    /// liefert `\textbf` und `\textit` (von aussen nach innen).
    func peel(_ range: Range<Int>) -> [FormatGroup] {
        var result: [FormatGroup] = []
        var current = range
        while !current.isEmpty, let group = groups.first(where: { $0.isFormatting && $0.whole == current }) {
            result.append(group)
            current = group.innerContent
        }
        return result
    }

    /// Erweitert die Auswahl über Formatierungen, deren ganzer Inhalt sie ist:
    /// `\textbf{\textit{«x»}}` liefert den Bereich von `\textit{x}` bzw. `\textbf{…}`
    /// und die durchlaufenen Gruppen (von innen nach aussen).
    func extend(_ range: Range<Int>) -> (range: Range<Int>, groups: [FormatGroup]) {
        var current = range
        var found: [FormatGroup] = []
        while let group = enclosing(current).first, group.isFormatting,
              group.innerContent == current || group.content == current {
            found.append(group)
            current = group.whole
        }
        return (current, found)
    }

    /// Erweitert die Auswahl so, dass kein Befehl und keine Klammergruppe zerschnitten wird
    /// (`«Hallo \textit{We»lt}` → ganzes `\textit{Welt}`, `«\frac{a}»{b}` → ganzer Bruch).
    /// `nil`, wenn Einpacken den Text kaputt machen würde: in Argumenten wie `\label{…}`
    /// oder über `\begin`/`\end` und Formelgrenzen hinweg.
    func completed(_ range: Range<Int>) -> Range<Int>? {
        var lower = range.lowerBound
        var upper = range.upperBound
        var changed = true
        var rounds = 0
        while changed, rounds < 100 {
            changed = false
            rounds += 1
            for group in groups {
                let openInside = lower <= group.open && group.open < upper
                let closeInside = lower <= group.close && group.close < upper
                let startInside = lower <= group.start && group.start < upper
                guard openInside != closeInside || startInside != closeInside else { continue }
                if group.command == "begin" || group.command == "end" { return nil }
                lower = min(lower, group.start)
                upper = max(upper, group.close + 1)
                changed = true
            }
        }
        let result = lower..<upper
        guard !enclosing(result).contains(where: { $0.isKeyArgument }), keepsStructure(result) else { return nil }
        return result
    }

    /// Gehen `\begin`/`\end`, `$`, `\(`/`\)` und `\[`/`\]` im Bereich auf?
    private func keepsStructure(_ range: Range<Int>) -> Bool {
        var environments = 0
        var dollars = 0
        var inlineMath = 0
        var displayMath = 0
        var i = range.lowerBound
        while i < range.upperBound {
            let unit = text[i]
            if unit == TeXChar.percent, !text.isEscaped(at: i) {
                i = text.lineEnd(after: i)
                continue
            }
            if unit == TeXChar.dollar, !text.isEscaped(at: i) { dollars += 1 }
            if unit == TeXChar.backslash, !text.isEscaped(at: i) {
                if let token = BlockEditor.environmentToken(in: text, at: i), token.range.upperBound <= range.upperBound {
                    environments += token.isBegin ? 1 : -1
                    if environments < 0 { return false }
                    i = token.range.upperBound
                    continue
                }
                switch text.unit(at: i + 1) {
                case TeXChar.parenOpen: inlineMath += 1
                case TeXChar.parenClose: inlineMath -= 1
                case TeXChar.bracketOpen: displayMath += 1
                case TeXChar.bracketClose: displayMath -= 1
                default: break
                }
                if inlineMath < 0 || displayMath < 0 { return false }
                i += 2
                continue
            }
            i += 1
        }
        return environments == 0 && dollars % 2 == 0 && inlineMath == 0 && displayMath == 0
    }

    /// `\textcolor{…}{…}`, in dessen Farbnamen `position` steht.
    func coloredGroup(namedAround position: Int) -> FormatGroup? {
        groups.first { group in
            guard let name = group.colorNameRange else { return false }
            return name.lowerBound <= position && position <= name.upperBound
        }
    }

    func colorName(in nameRange: Range<Int>) -> String {
        text.string(in: nameRange).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: Bearbeiten

    /// Entfernt `\textbf{…}` bzw. `\textcolor{…}{…}` und behält den Inhalt.
    func unwrap(_ group: FormatGroup, keeping selection: Range<Int>) -> TextEdit {
        var builder = FormattingEditBuilder(range: group.whole)
        if group.size != nil {
            // `\textbf{\large …}`: Klammern behalten, sonst gälte die Grösse für den ganzen Rest.
            builder.insert("{")
            builder.copy(group.content, from: text, preferred: true)
            builder.insert("}")
        } else {
            appendKeepingCommandsApart(group.content, replacing: group.whole, into: &builder)
        }
        return builder.edit(selection: selection)
    }

    /// Löst `range` aus der Gruppe `host` heraus: `\textbf{Hallo «Welt»}` → `\textbf{Hallo }«Welt»`.
    func split(_ host: FormatGroup, around range: Range<Int>, keeping selection: Range<Int>, prefix: String) -> TextEdit {
        let inner = host.innerContent
        let before = inner.lowerBound..<range.lowerBound
        let after = range.upperBound..<inner.upperBound
        var builder = FormattingEditBuilder(range: host.whole)
        if FormattingText.isBlank(text, before) {
            if before.isEmpty, FormattingText.endsWithControlWord(text, at: host.whole.lowerBound),
               startsWithLetter(range) {
                builder.insert("{}")
            }
            builder.copy(before, from: text)
        } else {
            builder.insert(prefix)
            builder.copy(before, from: text)
            builder.insert("}")
        }
        builder.copy(range, from: text, preferred: true)
        if FormattingText.isBlank(text, after) {
            builder.copy(after, from: text)
            if after.isEmpty, FormattingText.endsWithControlWord(text, at: range.upperBound, notBefore: range.lowerBound),
               startsWithLetter(host.whole.upperBound..<text.count) {
                builder.insert("{}")
            }
        } else {
            builder.insert(prefix)
            builder.copy(after, from: text)
            builder.insert("}")
        }
        return builder.edit(selection: selection)
    }

    /// Entfernt die Grössenangabe: `{\large Text}` → `Text`, `\textbf{\large Text}` → `\textbf{Text}`.
    func removeSize(_ group: FormatGroup, keeping selection: Range<Int>) -> TextEdit {
        guard let command = group.sizeCommand, let sizeEnd = group.sizeEnd else {
            return FormattingText.noChange(selection)
        }
        let rest = sizeEnd..<group.close
        if group.role == .plain, !startsWithDeclaration(rest) {
            var builder = FormattingEditBuilder(range: group.whole)
            appendKeepingCommandsApart(rest, replacing: group.whole, into: &builder)
            return builder.edit(selection: selection)
        }
        // Klammern gehören zu einem Befehl oder halten eine weitere Angabe wie `\bfseries`
        // zusammen: nur `\large ` entfernen.
        let builder = FormattingEditBuilder(range: command.lowerBound..<sizeEnd)
        return builder.edit(selection: selection)
    }

    /// Ersetzt `\large` durch einen anderen Grössenbefehl.
    func replaceSize(_ group: FormatGroup, with size: FontSize, keeping selection: Range<Int>) -> TextEdit {
        guard let command = group.sizeCommand else { return FormattingText.noChange(selection) }
        var builder = FormattingEditBuilder(range: command)
        builder.insert("\\" + size.command)
        return builder.edit(selection: selection)
    }

    /// Ersetzt den Farbnamen in `\textcolor{…}{…}`.
    func recolor(_ group: FormatGroup, to color: TextColor, keeping selection: Range<Int>) -> TextEdit {
        guard let nameRange = group.colorNameRange, colorName(in: nameRange) != color.latexName else {
            return FormattingText.noChange(selection)
        }
        var builder = FormattingEditBuilder(range: nameRange)
        builder.insert(color.latexName)
        return builder.edit(selection: selection)
    }

    /// Hängt `content` an, das `whole` ersetzt. Würde dabei ein Befehlsname mit dem
    /// folgenden Wort verschmelzen (`\LaTeX\textbf{ist}` → `\LaTeXist`), kommt `{}` dazwischen.
    private func appendKeepingCommandsApart(
        _ content: Range<Int>, replacing whole: Range<Int>, into builder: inout FormattingEditBuilder
    ) {
        let next = content.isEmpty ? whole.upperBound..<text.count : content
        if FormattingText.endsWithControlWord(text, at: whole.lowerBound), startsWithLetter(next) {
            builder.insert("{}")
        }
        builder.copy(content, from: text, preferred: true)
        if !content.isEmpty,
           FormattingText.endsWithControlWord(text, at: content.upperBound, notBefore: content.lowerBound),
           startsWithLetter(whole.upperBound..<text.count) {
            builder.insert("{}")
        }
    }

    private func startsWithLetter(_ range: Range<Int>) -> Bool {
        !range.isEmpty && TeXChar.isASCIILetter(text[range.lowerBound])
    }

    /// Beginnt der Bereich mit einer Angabe wie `\bfseries` (Befehl ohne Argument)?
    private func startsWithDeclaration(_ range: Range<Int>) -> Bool {
        var k = range.lowerBound
        while k < range.upperBound, TeXChar.isWhitespace(text[k]) { k += 1 }
        guard k < range.upperBound, text[k] == TeXChar.backslash else { return false }
        var e = k + 1
        while e < range.upperBound, TeXChar.isASCIILetter(text[e]) { e += 1 }
        guard e > k + 1 else { return false }
        while e < range.upperBound, text[e] == TeXChar.space || text[e] == TeXChar.tab { e += 1 }
        return text.unit(at: e) != TeXChar.braceOpen
    }
}

/// Befehle, deren (erstes) Argument kein Fliesstext ist: Namen, Schlüssel, Dateien, Masse.
private let keyArgumentCommands: Set<String> = [
    "begin", "end", "label", "ref", "eqref", "pageref", "autoref", "cref", "Cref", "nameref",
    "cite", "citep", "citet", "parencite", "textcite", "autocite", "footcite", "nocite",
    "usepackage", "RequirePackage", "documentclass", "input", "include", "includeonly",
    "includegraphics", "bibliography", "bibliographystyle", "addbibresource",
    "url", "href", "hyperref", "hypersetup", "lstinputlisting", "lstset",
    "color", "colorbox", "fcolorbox", "pagecolor", "definecolor",
    "setlength", "addtolength", "setcounter", "addtocounter", "newcounter", "stepcounter",
    "hspace", "vspace", "rule", "newcommand", "renewcommand", "providecommand",
    "newenvironment", "renewenvironment", "DeclareMathOperator", "newtheorem",
    "theoremstyle", "pagestyle", "thispagestyle", "pagenumbering", "selectlanguage",
    "fontsize", "linespread", "geometry"
]

/// Befehle, bei denen *alle* Argumente keine Fliesstexte sind (`\begin{tabular}{cc}`).
private let keyCommandsForAllArguments: Set<String> = [
    "begin", "definecolor", "setlength", "addtolength", "setcounter", "addtocounter", "fontsize"
]

// MARK: - Gemeinsame Hilfen für Zeichen- und Absatzformatierung

/// Kleine Textfunktionen, die `InlineFormatter` und `ParagraphFormatter` teilen.
enum FormattingText {
    /// Begrenzt die Auswahl auf den Text und zerschneidet keine Emoji
    /// (UTF-16-Ersatzpaare bleiben zusammen).
    static func clamp<S: UTF16Source>(_ selection: Range<Int>, in text: S) -> Range<Int> {
        var lower = min(max(0, selection.lowerBound), text.count)
        var upper = min(max(lower, selection.upperBound), text.count)
        if splitsSurrogatePair(text, at: lower) { lower -= 1 }
        if splitsSurrogatePair(text, at: upper) { upper += 1 }
        return lower..<upper
    }

    private static func splitsSurrogatePair<S: UTF16Source>(_ text: S, at position: Int) -> Bool {
        position > 0 && position < text.count
            && UTF16.isLeadSurrogate(text[position - 1]) && UTF16.isTrailSurrogate(text[position])
    }

    /// Nichts ändern, Auswahl bleibt, wie sie ist.
    static func noChange(_ selection: Range<Int>) -> TextEdit {
        TextEdit(range: selection.lowerBound..<selection.lowerBound, replacement: "", selectionAfter: selection)
    }

    /// Nur Leerzeichen, Tabs und Zeilenumbrüche (oder leer)?
    static func isBlank<S: UTF16Source>(_ text: S, _ range: Range<Int>) -> Bool {
        var i = range.lowerBound
        while i < range.upperBound {
            if !TeXChar.isWhitespace(text[i]) { return false }
            i += 1
        }
        return true
    }

    /// Gehen alle geschweiften Klammern im Bereich auf (Kommentare und `\{` zählen nicht)?
    static func isBalanced<S: UTF16Source>(_ text: S, _ range: Range<Int>) -> Bool {
        var depth = 0
        var i = range.lowerBound
        while i < range.upperBound {
            let unit = text[i]
            if unit == TeXChar.percent, !text.isEscaped(at: i) {
                i = text.lineEnd(after: i)
                continue
            }
            if unit == TeXChar.braceOpen, !text.isEscaped(at: i) { depth += 1 }
            if unit == TeXChar.braceClose, !text.isEscaped(at: i) {
                depth -= 1
                if depth < 0 { return false }
            }
            i += 1
        }
        return depth == 0
    }

    /// Endet der Text vor `position` mit einem Befehlswort wie `\LaTeX`?
    /// Direkt dahinter darf dann kein Buchstabe folgen, sonst verschmelzen die beiden.
    static func endsWithControlWord<S: UTF16Source>(_ text: S, at position: Int, notBefore lowerLimit: Int = 0) -> Bool {
        var start = position
        while start > lowerLimit, TeXChar.isASCIILetter(text[start - 1]) { start -= 1 }
        guard start < position, start - 1 >= lowerLimit, text[start - 1] == TeXChar.backslash else { return false }
        return !text.isEscaped(at: start - 1)
    }
}

/// Baut den Ersatztext für *einen* zusammenhängenden Bereich Stück für Stück auf
/// und merkt sich, wohin die alten Textstellen wandern.
///
/// So bleibt der Cursor nach dem Formatieren auf demselben Text stehen, auch wenn
/// davor Befehle eingefügt oder entfernt wurden – und der Editor kann alles als
/// *einen* Schritt rückgängig machen.
struct FormattingEditBuilder {
    /// Ersetzter Bereich im alten Text.
    var range: Range<Int>
    private(set) var replacement = ""
    /// Länge von `replacement` in UTF-16-Einheiten.
    private var length = 0
    private var pieces: [Piece] = []

    /// Ein unverändert übernommenes Stück alter Text.
    private struct Piece {
        var old: Range<Int>
        var new: Int
        /// Liegt eine Position genau an der Grenze zweier Stücke, gewinnt das bevorzugte
        /// (z. B. der Titel statt des Rahmens `\section{…}`).
        var preferred: Bool
    }

    init(range: Range<Int>) {
        self.range = range
    }

    /// Neuen Text einfügen.
    mutating func insert(_ string: String) {
        replacement += string
        length += string.utf16.count
    }

    /// Alten Text unverändert übernehmen. Die Stücke müssen in Textreihenfolge kommen.
    mutating func copy<S: UTF16Source>(_ old: Range<Int>, from text: S, preferred: Bool = false) {
        pieces.append(Piece(old: old, new: range.lowerBound + length, preferred: preferred))
        insert(text.string(in: old))
    }

    /// Wohin wandert die alte Position `old`?
    func position(for old: Int) -> Int {
        if old < range.lowerBound { return old }
        if old > range.upperBound { return old + length - range.count }
        let containing = pieces.first { $0.preferred && $0.old.lowerBound <= old && old <= $0.old.upperBound }
            ?? pieces.first { $0.old.lowerBound <= old && old <= $0.old.upperBound }
        if let piece = containing { return piece.new + (old - piece.old.lowerBound) }
        if old == range.upperBound { return range.lowerBound + length }
        // Gelöschter Text: an den Anfang des nächsten erhaltenen Stücks.
        if let next = pieces.first(where: { $0.old.lowerBound > old }) { return next.new }
        if let last = pieces.last { return last.new + last.old.count }
        return old == range.lowerBound ? old : range.lowerBound + length
    }

    /// Die fertige Bearbeitung; die Auswahl wird mitgeführt.
    func edit(selection: Range<Int>) -> TextEdit {
        let lower = position(for: selection.lowerBound)
        let upper = selection.isEmpty ? lower : max(lower, position(for: selection.upperBound))
        return TextEdit(range: range, replacement: replacement, selectionAfter: lower..<upper)
    }
}
