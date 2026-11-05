import Foundation

/// Was die Formelvorschau darstellen soll.
public struct MathPreviewRequest: Equatable, Sendable {
    /// TeX für MathJax – inklusive der benötigten eigenen Befehle.
    public var tex: String
    /// Abgesetzt (gross) oder im Text.
    public var display: Bool

    public init(tex: String, display: Bool) {
        self.tex = tex
        self.display = display
    }
}

/// Bereitet die Formel am Cursor für die Vorschau auf.
///
/// Die Vorschau rechnet nicht mit LaTeX, sondern mit MathJax direkt in der App –
/// das geht bei jedem Tastendruck. Eigene Befehle aus dem Dokument
/// (`\newcommand{\R}{\mathbb{R}}`, `\DeclareMathOperator{\Bild}{Bild}`) werden
/// mitgegeben, aber nur die, die in der Formel vorkommen.
public enum MathPreviewSource {
    public struct Macro: Equatable, Sendable {
        /// Ohne Backslash.
        public var name: String
        /// Definition in einer Form, die MathJax versteht.
        public var definition: String
    }

    /// Umgebungen, die MathJax selbst kennt und die deshalb ganz übergeben werden.
    static let mathJaxEnvironments: Set<String> = [
        "equation", "equation*", "align", "align*", "alignat", "alignat*", "flalign", "flalign*",
        "gather", "gather*", "multline", "multline*", "eqnarray", "eqnarray*"
    ]

    /// Vorschau für eine Formel oder `nil`, wenn sie (noch) leer ist.
    public static func request<S: UTF16Source>(for region: MathRegion, in text: S, macros: [Macro]) -> MathPreviewRequest? {
        let content = text.string(in: region.contentRange)
        guard content.contains(where: { !$0.isWhitespace }) else { return nil }
        var tex: String
        if let environment = region.environment, mathJaxEnvironments.contains(environment) {
            tex = "\\begin{\(environment)}" + content + "\\end{\(environment)}"
        } else {
            tex = content
        }
        tex = tex.trimmingCharacters(in: .whitespacesAndNewlines)
        let definitions = usedMacros(in: tex, from: macros)
        if !definitions.isEmpty {
            tex = definitions.map(\.definition).joined(separator: " ") + " " + tex
        }
        return MathPreviewRequest(tex: tex, display: region.style == .display)
    }

    /// Eigene Befehle aus dem ganzen Dokument (Kommentare ausgenommen).
    public static func macros<S: UTF16Source>(in text: S) -> [Macro] {
        var result: [Macro] = []
        var i = 0
        let count = text.count
        while i < count {
            let u = text[i]
            if u == TeXChar.percent && !text.isEscaped(at: i) {
                i = text.lineEnd(after: i)
                continue
            }
            guard u == TeXChar.backslash, !text.isEscaped(at: i) else {
                i += 1
                continue
            }
            var nameEnd = i + 1
            while nameEnd < count, TeXChar.isASCIILetter(text[nameEnd]) { nameEnd += 1 }
            let command = text.string(in: (i + 1)..<nameEnd)
            switch command {
            case "newcommand", "renewcommand", "providecommand", "DeclareRobustCommand":
                if let (macro, end) = parseNewcommand(text, from: nameEnd) {
                    result.append(macro)
                    i = end
                    continue
                }
            case "DeclareMathOperator":
                var j = nameEnd
                let starred = j < count && text[j] == TeXChar.star
                if starred { j += 1 }
                if let (name, afterName) = macroName(text, at: j),
                   let (body, end) = DocumentSymbols.braceArgument(text, at: skipSpaces(text, from: afterName)) {
                    let operatorCommand = starred ? "\\operatorname*" : "\\operatorname"
                    result.append(Macro(name: name, definition: "\\newcommand{\\\(name)}{\(operatorCommand){\(body)}}"))
                    i = end
                    continue
                }
            case "def":
                var j = nameEnd
                if j < count, text[j] == TeXChar.backslash {
                    var k = j + 1
                    while k < count, TeXChar.isASCIILetter(text[k]) { k += 1 }
                    let name = text.string(in: (j + 1)..<k)
                    j = k
                    // Parameter wie #1#2 bis zur Klammer.
                    while j < count, text[j] != TeXChar.braceOpen, text[j] != TeXChar.newline { j += 1 }
                    if !name.isEmpty, let (_, end) = DocumentSymbols.braceArgument(text, at: j) {
                        result.append(Macro(name: name, definition: text.string(in: i..<end)))
                        i = end
                        continue
                    }
                }
            default:
                break
            }
            i = max(nameEnd, i + 1)
        }
        return result
    }

    /// `\newcommand{\name}[2][opt]{body}` bzw. `\newcommand\name{body}` → als `\newcommand`.
    private static func parseNewcommand<S: UTF16Source>(_ text: S, from position: Int) -> (Macro, Int)? {
        var j = position
        if j < text.count, text[j] == TeXChar.star { j += 1 }
        guard let (name, afterName) = macroName(text, at: skipSpaces(text, from: j)) else { return nil }
        j = afterName
        var arguments = ""
        var k = skipSpaces(text, from: j)
        // Bis zu zwei optionale Teile: Anzahl der Argumente und Vorgabewert.
        for _ in 0..<2 {
            guard let (value, end) = DocumentSymbols.bracketArgument(text, at: k) else { break }
            arguments += "[\(value)]"
            k = skipSpaces(text, from: end)
        }
        guard let (body, end) = DocumentSymbols.braceArgument(text, at: k) else { return nil }
        return (Macro(name: name, definition: "\\newcommand{\\\(name)}\(arguments){\(body)}"), end)
    }

    /// `{\name}` oder `\name` → Name ohne Backslash und Position danach.
    private static func macroName<S: UTF16Source>(_ text: S, at position: Int) -> (String, Int)? {
        if let (argument, end) = DocumentSymbols.braceArgument(text, at: position) {
            let trimmed = argument.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("\\"), trimmed.count > 1 else { return nil }
            return (String(trimmed.dropFirst()), end)
        }
        guard position < text.count, text[position] == TeXChar.backslash else { return nil }
        var k = position + 1
        while k < text.count, TeXChar.isASCIILetter(text[k]) { k += 1 }
        guard k > position + 1 else { return nil }
        return (text.string(in: (position + 1)..<k), k)
    }

    private static func skipSpaces<S: UTF16Source>(_ text: S, from index: Int) -> Int {
        var i = index
        while i < text.count, TeXChar.isWhitespace(text[i]) { i += 1 }
        return i
    }

    /// Die Befehle, die in `tex` vorkommen – auch solche, die andere benötigen.
    static func usedMacros(in tex: String, from macros: [Macro]) -> [Macro] {
        var used: [Macro] = []
        var names = Set<String>()
        var searchIn = tex
        var changed = true
        while changed {
            changed = false
            for macro in macros where !names.contains(macro.name) && mentions(macro.name, in: searchIn) {
                names.insert(macro.name)
                used.append(macro)
                searchIn += " " + macro.definition
                changed = true
            }
        }
        // In der Reihenfolge des Dokuments, damit Abhängigkeiten zuerst festgelegt sind.
        return macros.filter { macro in names.contains(macro.name) && used.contains(macro) }
            .reduce(into: [Macro]()) { result, macro in
                if !result.contains(where: { $0.name == macro.name }) { result.append(macro) }
            }
    }

    /// Kommt `\name` als ganzer Befehl vor (nicht nur als Anfang von `\namelonger`)?
    private static func mentions(_ name: String, in tex: String) -> Bool {
        let needle = "\\" + name
        var search = tex.startIndex
        while let found = tex.range(of: needle, range: search..<tex.endIndex) {
            if found.upperBound == tex.endIndex { return true }
            let next = tex[found.upperBound]
            if !(next.isLetter && next.isASCII) { return true }
            search = found.upperBound
        }
        return false
    }
}
