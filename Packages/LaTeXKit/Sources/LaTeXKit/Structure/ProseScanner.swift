import Foundation

/// Findet den natürlichsprachigen Text in einem LaTeX-Dokument – alles, was
/// später als Wörter im PDF steht.
///
/// Nicht dazu gehören Befehlsnamen, Formeln, Kommentare, wörtlicher Text
/// (`verbatim`, `\verb`) und technische Argumente wie in `\label{…}`,
/// `\includegraphics[width=…]{…}` oder `\begin{tabular}{lcr}`.
///
/// Grundlage für die Rechtschreibprüfung (nur hier wird geprüft) und die
/// Wortzählung.
public enum ProseScanner {
    /// Befehle, deren Pflichtargumente kein Fliesstext sind – mit der Anzahl solcher Argumente.
    static let technicalArguments: [String: Int] = [
        "label": 1, "ref": 1, "eqref": 1, "pageref": 1, "autoref": 1, "cref": 1, "Cref": 1, "nameref": 1, "vref": 1,
        "cite": 1, "citep": 1, "citet": 1, "parencite": 1, "textcite": 1, "autocite": 1, "footcite": 1,
        "nocite": 1, "citeauthor": 1, "citeyear": 1,
        "usepackage": 1, "RequirePackage": 1, "documentclass": 1,
        "includegraphics": 1, "includepdf": 1, "input": 1, "include": 1, "graphicspath": 1,
        "bibliography": 1, "bibliographystyle": 1, "addbibresource": 1,
        "url": 1, "href": 1, "path": 1, "lstinputlisting": 1,
        "begin": 1, "end": 1,
        "vspace": 1, "hspace": 1, "vskip": 1, "hskip": 1, "setlength": 2, "addtolength": 2,
        "newcommand": 2, "renewcommand": 2, "providecommand": 2, "DeclareMathOperator": 2,
        "newenvironment": 3, "renewenvironment": 3, "newtheorem": 2, "theoremstyle": 1,
        "color": 1, "textcolor": 1, "colorbox": 1, "pagecolor": 1, "definecolor": 3,
        "pagestyle": 1, "thispagestyle": 1, "pagenumbering": 1,
        "geometry": 1, "newgeometry": 1, "hypersetup": 1, "captionsetup": 1, "setlist": 1, "sisetup": 1,
        "setcounter": 2, "addtocounter": 2, "stepcounter": 1, "fontsize": 2, "linespread": 1, "setstretch": 1,
        "multicolumn": 2, "multirow": 2, "SI": 2, "si": 1, "num": 1, "ce": 1,
        "rule": 2, "raisebox": 1, "resizebox": 2, "scalebox": 1, "rotatebox": 1, "makebox": 0, "framebox": 0
    ]

    /// Befehle, deren optionales Argument `[…]` Fliesstext ist (`\item[Begriff]`, `\section[Kurz]{…}`).
    static let proseOptionalArguments: Set<String> = [
        "item", "part", "chapter", "section", "subsection", "subsubsection", "paragraph", "subparagraph",
        "caption", "footnote", "title", "author"
    ]

    /// Umgebungen mit technischen Argumenten nach `\begin{…}` (`tabular` → Spaltenformat).
    static let environmentArguments: [String: Int] = [
        "tabular": 1, "tabular*": 2, "tabularx": 2, "tabulary": 2, "longtable": 1, "array": 1,
        "minipage": 1, "multicols": 1, "multicols*": 1, "wrapfigure": 2, "wraptable": 2,
        "thebibliography": 1, "subfigure": 1, "tcolorbox": 0, "tikzpicture": 0
    ]

    /// Umgebungen, deren Inhalt kein Fliesstext ist.
    static let nonProseEnvironments: Set<String> = LaTeXTokenizer.verbatimEnvironments.union(["tikzpicture", "filecontents", "filecontents*"])

    /// Bereiche mit Fliesstext, sortiert und ohne Überlappung.
    public static func proseRanges<S: UTF16Source>(in text: S, tokenized: TokenizedText) -> [Range<Int>] {
        let count = text.count
        guard count > 0 else { return [] }
        var isProse = [Bool](repeating: true, count: count)

        func exclude(_ range: Range<Int>) {
            let lower = max(0, range.lowerBound)
            let upper = min(count, range.upperBound)
            guard lower < upper else { return }
            for i in lower..<upper { isProse[i] = false }
        }

        for region in tokenized.mathRegions { exclude(region.range) }

        let tokens = tokenized.tokens
        var index = 0
        while index < tokens.count {
            let token = tokens[index]
            index += 1
            switch token.kind {
            case .command, .keyword:
                exclude(token.range)
                guard token.length > 1, text[token.location] == TeXChar.backslash,
                      TeXChar.isASCIILetter(text[token.location + 1]) else { continue }
                var nameEnd = token.location + 1
                while nameEnd < token.end, TeXChar.isASCIILetter(text[nameEnd]) { nameEnd += 1 }
                let name = text.string(in: (token.location + 1)..<nameEnd)
                var position = token.end
                // Sternform (`\vspace*`).
                if position < count, text[position] == TeXChar.star {
                    exclude(position..<(position + 1))
                    position += 1
                }
                if name == "verb" || name == "lstinline" {
                    position = skipDelimited(text, from: position, exclude: exclude)
                    continue
                }
                if name == "begin" {
                    position = handleBegin(text, from: position, exclude: exclude)
                    continue
                }
                // Optionale Argumente.
                while let end = groupEnd(text, at: skipSpaces(text, from: position), open: TeXChar.bracketOpen, close: TeXChar.bracketClose) {
                    if !proseOptionalArguments.contains(name) { exclude(position..<end) }
                    position = end
                }
                // Technische Pflichtargumente.
                if let arguments = technicalArguments[name] {
                    for _ in 0..<arguments {
                        let start = skipSpaces(text, from: position)
                        if let end = groupEnd(text, at: start, open: TeXChar.braceOpen, close: TeXChar.braceClose) {
                            exclude(start..<end)
                            position = end
                        } else if name == "newcommand" || name == "renewcommand" || name == "providecommand",
                                  start < count, text[start] == TeXChar.backslash {
                            // `\newcommand\R{…}`
                            var k = start + 1
                            while k < count, TeXChar.isASCIILetter(text[k]) { k += 1 }
                            exclude(start..<k)
                            position = k
                            if let end = groupEnd(text, at: skipSpaces(text, from: k), open: TeXChar.bracketOpen, close: TeXChar.bracketClose) {
                                exclude(k..<end)
                                position = end
                            }
                        } else {
                            break
                        }
                    }
                    // Abschliessendes optionales Argument (`\newtheorem{satz}{Satz}[section]`).
                    if let end = groupEnd(text, at: skipSpaces(text, from: position), open: TeXChar.bracketOpen, close: TeXChar.bracketClose) {
                        exclude(position..<end)
                    }
                }
            case .special:
                exclude(token.range)
                // `\\[2pt]`: Abstand nach dem Zeilenumbruch.
                if token.length == 2, text[token.location] == TeXChar.backslash,
                   let end = groupEnd(text, at: token.end, open: TeXChar.bracketOpen, close: TeXChar.bracketClose) {
                    exclude(token.end..<end)
                }
            case .comment, .mathDelimiter, .math, .mathCommand, .environmentName, .placeholder, .brace:
                exclude(token.range)
            }
        }

        // Fliesstext zu Bereichen zusammenfassen.
        var ranges: [Range<Int>] = []
        var start: Int?
        for i in 0..<count {
            if isProse[i] {
                if start == nil { start = i }
            } else if let open = start {
                ranges.append(open..<i)
                start = nil
            }
        }
        if let open = start { ranges.append(open..<count) }
        return ranges
    }

    /// Nach `\begin{name}`: technische Argumente und wörtliche Inhalte ausschliessen.
    private static func handleBegin<S: UTF16Source>(_ text: S, from position: Int, exclude: (Range<Int>) -> Void) -> Int {
        let nameStart = skipSpaces(text, from: position)
        guard let nameEnd = groupEnd(text, at: nameStart, open: TeXChar.braceOpen, close: TeXChar.braceClose) else { return position }
        exclude(nameStart..<nameEnd)
        let name = text.string(in: (nameStart + 1)..<(nameEnd - 1))
        var position = nameEnd
        if nonProseEnvironments.contains(name) {
            let terminator = "\\end{\(name)}"
            var k = position
            while k < text.count, !text.matches(terminator, at: k) { k += 1 }
            exclude(position..<k)
            return k
        }
        // `\begin{figure}[htbp]`, `\begin{enumerate}[label=(\alph*)]` …
        while let end = groupEnd(text, at: skipSpaces(text, from: position), open: TeXChar.bracketOpen, close: TeXChar.bracketClose) {
            exclude(position..<end)
            position = end
        }
        for _ in 0..<(environmentArguments[name] ?? 0) {
            let start = skipSpaces(text, from: position)
            guard let end = groupEnd(text, at: start, open: TeXChar.braceOpen, close: TeXChar.braceClose) else { break }
            exclude(start..<end)
            position = end
        }
        return position
    }

    /// `\verb|…|`: alles bis zum gleichen Begrenzer.
    private static func skipDelimited<S: UTF16Source>(_ text: S, from position: Int, exclude: (Range<Int>) -> Void) -> Int {
        guard position < text.count, text[position] != TeXChar.newline else { return position }
        let delimiter = text[position] == TeXChar.braceOpen ? TeXChar.braceClose : text[position]
        var k = position + 1
        while k < text.count, text[k] != delimiter, text[k] != TeXChar.newline { k += 1 }
        let end = min(text.count, k + 1)
        exclude(position..<end)
        return end
    }

    private static func skipSpaces<S: UTF16Source>(_ text: S, from index: Int) -> Int {
        var i = index
        while i < text.count, text[i] == TeXChar.space || text[i] == TeXChar.tab { i += 1 }
        return i
    }

    /// Ende (hinter der schliessenden Klammer) einer Gruppe ab `index`, sonst `nil`.
    /// Eine Gruppe endet spätestens an einer Leerzeile.
    static func groupEnd<S: UTF16Source>(_ text: S, at index: Int, open: UInt16, close: UInt16) -> Int? {
        guard index < text.count, text[index] == open, !text.isEscaped(at: index) else { return nil }
        var depth = 0
        var braceDepth = 0
        var i = index
        while i < text.count {
            let u = text[i]
            if !text.isEscaped(at: i) {
                if open != TeXChar.braceOpen {
                    // In `[…]` zählen geschweifte Klammern mit: `[label={[a]}]`.
                    if u == TeXChar.braceOpen { braceDepth += 1 }
                    if u == TeXChar.braceClose { braceDepth -= 1 }
                }
                if braceDepth <= 0 {
                    if u == open { depth += 1 }
                    if u == close {
                        depth -= 1
                        if depth == 0 { return i + 1 }
                    }
                }
            }
            if u == TeXChar.newline, i + 1 < text.count, text[i + 1] == TeXChar.newline { return nil }
            i += 1
        }
        return nil
    }
}

/// Wörter und Zeichen im Fliesstext – wie in Pages unten im Fenster.
public struct WordCount: Equatable, Sendable {
    public var words = 0
    /// Zeichen ohne Leerzeichen.
    public var characters = 0
    /// Formeln (im Text und abgesetzt).
    public var formulas = 0

    public init(words: Int = 0, characters: Int = 0, formulas: Int = 0) {
        self.words = words
        self.characters = characters
        self.formulas = formulas
    }
}

public enum WordCounter {
    /// Zählt im Inhalt des Dokuments (zwischen `\begin{document}` und `\end{document}`,
    /// ohne diese Befehle gibt es den ganzen Text), optional nur in `selection`.
    public static func count<S: UTF16Source>(
        in text: S,
        prose: [Range<Int>],
        tokenized: TokenizedText,
        selection: Range<Int>? = nil
    ) -> WordCount {
        var bounds = bodyRange(in: text)
        if let selection {
            bounds = max(bounds.lowerBound, selection.lowerBound)..<max(max(bounds.lowerBound, selection.lowerBound), min(bounds.upperBound, selection.upperBound))
        }
        var result = WordCount()
        guard !bounds.isEmpty else { return result }

        for range in prose {
            let lower = max(range.lowerBound, bounds.lowerBound)
            let upper = min(range.upperBound, bounds.upperBound)
            guard lower < upper else { continue }
            var inWord = false
            var i = lower
            while i < upper {
                let u = text[i]
                if isWordUnit(u) {
                    if !inWord { result.words += 1 }
                    inWord = true
                } else if inWord, isJoiner(u), i + 1 < upper, isWordUnit(text[i + 1]) {
                    // Bindestrich und Apostroph innerhalb eines Wortes: „Lern-Software“, „geht's“.
                } else {
                    inWord = false
                }
                if !TeXChar.isWhitespace(u), !isLowSurrogate(u) { result.characters += 1 }
                i += 1
            }
        }
        result.formulas = tokenized.mathRegions.filter { bounds.contains($0.range.lowerBound) }.count
        return result
    }

    /// Bereich zwischen `\begin{document}` und `\end{document}` (oder der ganze Text).
    public static func bodyRange<S: UTF16Source>(in text: S) -> Range<Int> {
        let begin = "\\begin{document}"
        let end = "\\end{document}"
        var lower = 0
        var upper = text.count
        var i = 0
        var foundBegin = false
        while i < text.count {
            if text[i] == TeXChar.backslash, !BracketMatcher.isInComment(text, i) {
                if !foundBegin, text.matches(begin, at: i) {
                    lower = i + begin.utf16.count
                    foundBegin = true
                    i = lower
                    continue
                }
                if foundBegin, text.matches(end, at: i) {
                    upper = i
                    break
                }
            }
            i += 1
        }
        return lower..<max(lower, upper)
    }

    private static func isWordUnit(_ u: UInt16) -> Bool {
        if TeXChar.isAlphanumeric(u) { return true }
        // Zeichen ausserhalb der Basisebene (z. B. 𝑥) als Wortteil zählen.
        return u >= 0xD800 && u <= 0xDFFF
    }

    private static func isLowSurrogate(_ u: UInt16) -> Bool { u >= 0xDC00 && u <= 0xDFFF }

    private static func isJoiner(_ u: UInt16) -> Bool {
        u == 0x2D || u == 0x27 || u == 0x2019 // - ' ’
    }
}
