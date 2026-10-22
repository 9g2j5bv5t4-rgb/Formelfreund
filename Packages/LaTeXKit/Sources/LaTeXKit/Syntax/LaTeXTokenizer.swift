import Foundation

/// Art eines eingefärbten Textstücks. Die Farben selbst legt die App fest (`SyntaxTheme`).
public enum TokenKind: UInt8, Sendable, CaseIterable {
    /// Gewöhnlicher Befehl im Fliesstext, z. B. `\textbf`.
    case command
    /// Strukturbefehl, z. B. `\section`, `\begin`, `\usepackage`.
    case keyword
    /// Name einer Umgebung in `\begin{…}` / `\end{…}`.
    case environmentName
    /// Formel-Begrenzer: `$`, `$$`, `\(`, `\)`, `\[`, `\]`.
    case mathDelimiter
    /// Inhalt einer Formel.
    case math
    /// Befehl innerhalb einer Formel, z. B. `\frac`, `\alpha`.
    case mathCommand
    /// Kommentar ab `%` bis Zeilenende.
    case comment
    /// Geschweifte Klammern.
    case brace
    /// Sonderzeichen mit Bedeutung: `&`, `~`, `#`, `^`, `_`, `\\`.
    case special
}

/// Ein eingefärbter Abschnitt im Text (UTF-16-Offsets).
public struct HighlightToken: Equatable, Sendable {
    public var location: Int
    public var length: Int
    public var kind: TokenKind

    public init(location: Int, length: Int, kind: TokenKind) {
        self.location = location
        self.length = length
        self.kind = kind
    }

    public var end: Int { location + length }
    public var range: Range<Int> { location..<end }
}

/// Eine Formel im Dokument – Grundlage für Formelvorschau und Gliederung.
public struct MathRegion: Equatable, Sendable {
    public enum Style: Sendable, Equatable {
        /// Im Fliesstext: `$…$` oder `\(…\)`.
        case inline
        /// Abgesetzt: `\[…\]`, `$$…$$` oder eine Umgebung wie `align`.
        case display
    }

    /// Gesamter Bereich inklusive Begrenzer bzw. `\begin…\end`.
    public var range: Range<Int>
    /// Nur der Formelinhalt.
    public var contentRange: Range<Int>
    public var style: Style
    /// Name der Umgebung (z. B. `align*`), falls die Formel eine Umgebung ist.
    public var environment: String?
    /// `false`, wenn die Formel nicht geschlossen wurde (Tippfehler oder noch in Arbeit).
    public var isClosed: Bool

    public init(range: Range<Int>, contentRange: Range<Int>, style: Style, environment: String?, isClosed: Bool) {
        self.range = range
        self.contentRange = contentRange
        self.style = style
        self.environment = environment
        self.isClosed = isClosed
    }
}

/// Ergebnis der Syntax-Analyse.
public struct TokenizedText: Sendable, Equatable {
    public var tokens: [HighlightToken]
    public var mathRegions: [MathRegion]

    public init(tokens: [HighlightToken] = [], mathRegions: [MathRegion] = []) {
        self.tokens = tokens
        self.mathRegions = mathRegions
    }

    /// Formel, in der die Position liegt (inklusive Begrenzer), falls vorhanden.
    public func mathRegion(containing offset: Int) -> MathRegion? {
        // Binäre Suche: Regionen sind nach Position sortiert und überlappen nicht.
        var low = 0
        var high = mathRegions.count - 1
        while low <= high {
            let mid = (low + high) / 2
            let region = mathRegions[mid]
            if offset < region.range.lowerBound {
                high = mid - 1
            } else if offset > region.range.upperBound {
                low = mid + 1
            } else {
                return region
            }
        }
        return nil
    }
}

/// Zerlegt LaTeX-Quelltext in einfärbbare Abschnitte und findet alle Formeln.
///
/// Ein einziger Durchlauf über den Text, ohne reguläre Ausdrücke. Bei einem
/// 30-seitigen Dokument (~150 000 Zeichen) dauert das wenige Millisekunden und
/// läuft im Editor ohnehin im Hintergrund.
public enum LaTeXTokenizer {
    /// Umgebungen, deren Inhalt eine abgesetzte Formel ist.
    public static let mathEnvironments: Set<String> = [
        "equation", "equation*", "align", "align*", "alignat", "alignat*",
        "flalign", "flalign*", "gather", "gather*", "multline", "multline*",
        "eqnarray", "eqnarray*", "displaymath", "math", "dmath", "dmath*"
    ]

    /// Umgebungen, deren Inhalt wörtlich ist (keine Befehle).
    public static let verbatimEnvironments: Set<String> = [
        "verbatim", "verbatim*", "Verbatim", "lstlisting", "minted", "comment"
    ]

    /// Befehle, die die Struktur des Dokuments bestimmen und hervorgehoben werden.
    public static let keywordCommands: Set<String> = [
        "documentclass", "usepackage", "begin", "end",
        "part", "chapter", "section", "subsection", "subsubsection", "paragraph", "subparagraph",
        "title", "author", "date", "maketitle", "tableofcontents",
        "input", "include", "newcommand", "renewcommand", "providecommand",
        "newenvironment", "renewenvironment", "newtheorem", "DeclareMathOperator",
        "item", "bibliography", "bibliographystyle", "appendix"
    ]

    /// Befehle, die eine Gliederungsebene erzeugen, mit ihrer Ebene.
    public static let sectioningLevels: [String: Int] = [
        "part": 0, "chapter": 1, "section": 2, "subsection": 3,
        "subsubsection": 4, "paragraph": 5, "subparagraph": 6
    ]

    public static func tokenize(_ text: [UInt16]) -> TokenizedText {
        var scanner = Scanner(text)
        scanner.run()
        return TokenizedText(tokens: scanner.tokens, mathRegions: scanner.regions)
    }

    public static func tokenize(_ string: String) -> TokenizedText {
        tokenize(Array(string.utf16))
    }
}

// MARK: - Interner Scanner

private struct Scanner {
    /// In welchem Modus befindet sich der Scanner gerade?
    enum Mode: Equatable {
        case text
        case inlineDollar      // $…$
        case inlineParen       // \(…\)
        case displayDollar     // $$…$$
        case displayBracket    // \[…\]
        case environment(String)

        var isMath: Bool { self != .text }
    }

    let s: [UInt16]
    let n: Int
    var i = 0
    var mode: Mode = .text
    var mathStart = 0
    var contentStart = 0
    var tokens: [HighlightToken] = []
    var regions: [MathRegion] = []

    init(_ text: [UInt16]) {
        s = text
        n = text.count
        tokens.reserveCapacity(n / 12)
    }

    // MARK: Ausgabe

    /// Fügt ein Token hinzu. Direkt aneinandergrenzende Tokens gleicher Art
    /// (z. B. Formelinhalt) werden zusammengefasst, das spart später Arbeit beim Einfärben.
    mutating func emit(_ location: Int, _ length: Int, _ kind: TokenKind) {
        guard length > 0 else { return }
        let mergeable = kind == .math || kind == .comment || kind == .mathCommand
        if mergeable, let last = tokens.last, last.kind == kind, last.end == location {
            tokens[tokens.count - 1].length += length
        } else {
            tokens.append(HighlightToken(location: location, length: length, kind: kind))
        }
    }

    var commandKind: TokenKind { mode.isMath ? .mathCommand : .command }

    // MARK: Hauptschleife

    mutating func run() {
        while i < n {
            let c = s[i]
            switch c {
            case TeXChar.percent:
                let end = lineEnd(from: i)
                emit(i, end - i, .comment)
                i = end
            case TeXChar.backslash:
                handleBackslash()
            case TeXChar.dollar:
                handleDollar()
            case TeXChar.braceOpen, TeXChar.braceClose:
                emit(i, 1, .brace)
                i += 1
            case TeXChar.ampersand, TeXChar.tilde, TeXChar.hash, TeXChar.caret, TeXChar.underscore:
                emit(i, 1, .special)
                i += 1
            case TeXChar.newline:
                // Eine Leerzeile beendet in LaTeX den Absatz – und damit jede
                // Formel im Fliesstext. So bleibt ein vergessenes `$` lokal.
                if closesAtParagraph(mode) && isParagraphBreak(at: i) {
                    closeMath(end: i, contentEnd: i, closed: false)
                }
                if mode.isMath { emit(i, 1, .math) }
                i += 1
            default:
                if mode.isMath { emit(i, 1, .math) }
                i += 1
            }
        }
        if mode.isMath {
            closeMath(end: n, contentEnd: n, closed: false)
        }
    }

    // MARK: Befehle

    mutating func handleBackslash() {
        let start = i
        guard i + 1 < n else {
            emit(i, 1, commandKind)
            i += 1
            return
        }
        let next = s[i + 1]
        if TeXChar.isASCIILetter(next) {
            var j = i + 1
            while j < n && TeXChar.isASCIILetter(s[j]) { j += 1 }
            let name = String(decoding: s[(i + 1)..<j], as: UTF16.self)
            switch name {
            case "begin", "end":
                handleEnvironment(start: start, nameEnd: j, isBegin: name == "begin")
            case "verb":
                handleVerb(start: start, nameEnd: j)
            default:
                if LaTeXTokenizer.keywordCommands.contains(name) {
                    // Sternform wie \section* gehört zum Befehl.
                    if j < n && s[j] == TeXChar.star { j += 1 }
                    emit(start, j - start, .keyword)
                } else {
                    emit(start, j - start, commandKind)
                }
                i = j
            }
            return
        }

        // Steuerzeichen: \\ \{ \$ \( \[ usw.
        switch next {
        case TeXChar.parenOpen where mode == .text:
            emit(i, 2, .mathDelimiter)
            startMath(.inlineParen, at: i, contentStart: i + 2)
            i += 2
        case TeXChar.parenClose where mode == .inlineParen:
            emit(i, 2, .mathDelimiter)
            closeMath(end: i + 2, contentEnd: i, closed: true)
            i += 2
        case TeXChar.bracketOpen where mode == .text:
            emit(i, 2, .mathDelimiter)
            startMath(.displayBracket, at: i, contentStart: i + 2)
            i += 2
        case TeXChar.bracketClose where mode == .displayBracket:
            emit(i, 2, .mathDelimiter)
            closeMath(end: i + 2, contentEnd: i, closed: true)
            i += 2
        case TeXChar.backslash:
            emit(i, 2, .special)
            i += 2
        case TeXChar.newline:
            // "\" am Zeilenende: Den Umbruch selbst der Hauptschleife überlassen,
            // damit Leerzeilen weiterhin erkannt werden.
            emit(i, 1, commandKind)
            i += 1
        default:
            emit(i, 2, commandKind)
            i += 2
        }
    }

    mutating func handleEnvironment(start: Int, nameEnd: Int, isBegin: Bool) {
        emit(start, nameEnd - start, .keyword)
        var k = nameEnd
        while k < n && (s[k] == TeXChar.space || s[k] == TeXChar.tab) { k += 1 }
        guard k < n, s[k] == TeXChar.braceOpen else {
            i = nameEnd
            return
        }
        let nameStart = k + 1
        var e = nameStart
        while e < n && s[e] != TeXChar.braceClose && s[e] != TeXChar.newline && e - nameStart < 64 {
            e += 1
        }
        guard e < n, s[e] == TeXChar.braceClose else {
            // Noch unvollständig (z. B. während des Tippens): normal weiter scannen.
            i = nameEnd
            return
        }
        let environment = String(decoding: s[nameStart..<e], as: UTF16.self)
        emit(k, 1, .brace)
        emit(nameStart, e - nameStart, .environmentName)
        emit(e, 1, .brace)
        i = e + 1

        if isBegin {
            if mode == .text && LaTeXTokenizer.mathEnvironments.contains(environment) {
                startMath(.environment(environment), at: start, contentStart: i)
            } else if mode == .text && LaTeXTokenizer.verbatimEnvironments.contains(environment) {
                skipVerbatim(until: environment)
            }
        } else if case .environment(let open) = mode, open == environment {
            closeMath(end: i, contentEnd: start, closed: true)
        }
    }

    /// Überspringt den Inhalt einer wörtlichen Umgebung bis `\end{name}`.
    mutating func skipVerbatim(until environment: String) {
        let terminator = Array("\\end{\(environment)}".utf16)
        var p = i
        while p + terminator.count <= n {
            if s[p] == TeXChar.backslash && Array(s[p..<(p + terminator.count)]) == terminator {
                i = p
                return
            }
            p += 1
        }
        i = n
    }

    /// `\verb|…|` – der Inhalt zwischen den Begrenzern ist wörtlich.
    mutating func handleVerb(start: Int, nameEnd: Int) {
        var j = nameEnd
        if j < n && s[j] == TeXChar.star { j += 1 }
        emit(start, j - start, commandKind)
        guard j < n, s[j] != TeXChar.newline else {
            i = j
            return
        }
        let delimiter = s[j]
        var k = j + 1
        while k < n && s[k] != delimiter && s[k] != TeXChar.newline { k += 1 }
        i = (k < n && s[k] == delimiter) ? k + 1 : k
    }

    // MARK: Formeln

    mutating func handleDollar() {
        let isDouble = i + 1 < n && s[i + 1] == TeXChar.dollar
        switch mode {
        case .text:
            if isDouble {
                emit(i, 2, .mathDelimiter)
                startMath(.displayDollar, at: i, contentStart: i + 2)
                i += 2
            } else {
                emit(i, 1, .mathDelimiter)
                startMath(.inlineDollar, at: i, contentStart: i + 1)
                i += 1
            }
        case .inlineDollar:
            emit(i, 1, .mathDelimiter)
            closeMath(end: i + 1, contentEnd: i, closed: true)
            i += 1
        case .displayDollar where isDouble:
            emit(i, 2, .mathDelimiter)
            closeMath(end: i + 2, contentEnd: i, closed: true)
            i += 2
        default:
            // Ein `$` an dieser Stelle ist in LaTeX ein Fehler; als Formelinhalt einfärben.
            emit(i, 1, .math)
            i += 1
        }
    }

    mutating func startMath(_ newMode: Mode, at start: Int, contentStart content: Int) {
        mode = newMode
        mathStart = start
        contentStart = content
    }

    mutating func closeMath(end: Int, contentEnd: Int, closed: Bool) {
        let style: MathRegion.Style
        var environment: String?
        switch mode {
        case .inlineDollar, .inlineParen:
            style = .inline
        case .environment(let name):
            style = .display
            environment = name
        default:
            style = .display
        }
        regions.append(MathRegion(
            range: mathStart..<max(mathStart, end),
            contentRange: contentStart..<max(contentStart, contentEnd),
            style: style,
            environment: environment,
            isClosed: closed
        ))
        mode = .text
    }

    func closesAtParagraph(_ mode: Mode) -> Bool {
        switch mode {
        case .inlineDollar, .inlineParen, .displayDollar, .displayBracket: return true
        case .text, .environment: return false
        }
    }

    // MARK: Hilfsfunktionen

    func lineEnd(from index: Int) -> Int {
        var j = index
        while j < n && s[j] != TeXChar.newline { j += 1 }
        return j
    }

    /// Folgt auf den Zeilenumbruch bei `index` eine leere Zeile?
    func isParagraphBreak(at index: Int) -> Bool {
        var j = index + 1
        while j < n && (s[j] == TeXChar.space || s[j] == TeXChar.tab || s[j] == TeXChar.carriageReturn) {
            j += 1
        }
        return j >= n || s[j] == TeXChar.newline
    }
}
