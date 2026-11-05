import Foundation

/// Was ein Dokument selbst festlegt: Marken, eigene Befehle und Umgebungen,
/// Quellen. Grundlage für Vorschläge wie `\ref{fig:…}` oder `\R`.
public struct DocumentSymbols: Equatable, Sendable {
    public struct Label: Equatable, Sendable {
        public var key: String
        /// 1-basierte Zeile.
        public var line: Int
    }

    public struct UserCommand: Equatable, Sendable {
        /// Ohne Backslash.
        public var name: String
        public var argumentCount: Int
        /// Mit `\DeclareMathOperator` festgelegt (gehört in Formeln).
        public var isMathOperator: Bool
    }

    public var labels: [Label] = []
    public var userCommands: [UserCommand] = []
    /// Mit `\newtheorem` oder `\newenvironment` festgelegte Umgebungen.
    public var userEnvironments: [String] = []
    /// Alle Umgebungen, die mit `\begin{…}` vorkommen.
    public var usedEnvironments: [String] = []
    /// Schlüssel aus `\bibitem{…}`.
    public var bibItems: [String] = []
    /// Dateien aus `\bibliography{…}` und `\addbibresource{…}` (mit Endung `.bib`).
    public var bibliographyFiles: [String] = []

    public init() {}

    /// Liest alles in einem Durchgang; Kommentare werden übersprungen.
    public static func scan<S: UTF16Source>(_ text: S) -> DocumentSymbols {
        var symbols = DocumentSymbols()
        var seenEnvironments = Set<String>()
        var line = 1
        var i = 0
        let count = text.count
        while i < count {
            let u = text[i]
            if u == TeXChar.newline {
                line += 1
                i += 1
                continue
            }
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
            let name = text.string(in: (i + 1)..<nameEnd)
            var j = nameEnd
            switch name {
            case "label":
                if let (arg, end) = braceArgument(text, at: j) {
                    symbols.labels.append(Label(key: arg.trimmingCharacters(in: .whitespaces), line: line))
                    j = end
                }
            case "newcommand", "renewcommand", "providecommand", "DeclareMathOperator", "DeclareRobustCommand":
                if j < count, text[j] == TeXChar.star { j += 1 }
                j = skipSpaces(text, from: j)
                var commandName: String?
                if let (arg, end) = braceArgument(text, at: j) {
                    commandName = arg.trimmingCharacters(in: .whitespaces)
                    j = end
                } else if j < count, text[j] == TeXChar.backslash {
                    var k = j + 1
                    while k < count, TeXChar.isASCIILetter(text[k]) { k += 1 }
                    commandName = text.string(in: j..<k)
                    j = k
                }
                var arguments = 0
                if let (arg, end) = bracketArgument(text, at: skipSpaces(text, from: j)) {
                    arguments = Int(arg.trimmingCharacters(in: .whitespaces)) ?? 0
                    j = end
                }
                if let commandName, commandName.hasPrefix("\\"), commandName.count > 1 {
                    let bare = String(commandName.dropFirst())
                    if bare.allSatisfy({ $0.isLetter && $0.isASCII }) {
                        symbols.userCommands.append(UserCommand(name: bare, argumentCount: min(arguments, 9), isMathOperator: name == "DeclareMathOperator"))
                    }
                }
            case "def":
                if j < count, text[j] == TeXChar.backslash {
                    var k = j + 1
                    while k < count, TeXChar.isASCIILetter(text[k]) { k += 1 }
                    if k > j + 1 {
                        symbols.userCommands.append(UserCommand(name: text.string(in: (j + 1)..<k), argumentCount: 0, isMathOperator: false))
                    }
                    j = k
                }
            case "newtheorem", "newenvironment", "renewenvironment":
                if j < count, text[j] == TeXChar.star { j += 1 }
                if let (arg, end) = braceArgument(text, at: skipSpaces(text, from: j)) {
                    let environment = arg.trimmingCharacters(in: .whitespaces)
                    if !environment.isEmpty, !symbols.userEnvironments.contains(environment) {
                        symbols.userEnvironments.append(environment)
                    }
                    j = end
                }
            case "begin":
                if let (arg, end) = braceArgument(text, at: j) {
                    let environment = arg.trimmingCharacters(in: .whitespaces)
                    if !environment.isEmpty, seenEnvironments.insert(environment).inserted {
                        symbols.usedEnvironments.append(environment)
                    }
                    j = end
                }
            case "bibitem":
                var k = skipSpaces(text, from: j)
                if let (_, end) = bracketArgument(text, at: k) { k = end }
                if let (arg, end) = braceArgument(text, at: skipSpaces(text, from: k)) {
                    symbols.bibItems.append(arg.trimmingCharacters(in: .whitespaces))
                    j = end
                }
            case "bibliography", "addbibresource":
                var k = skipSpaces(text, from: j)
                if let (_, end) = bracketArgument(text, at: k) { k = end }
                if let (arg, end) = braceArgument(text, at: skipSpaces(text, from: k)) {
                    for file in arg.split(separator: ",") {
                        var path = file.trimmingCharacters(in: .whitespaces)
                        guard !path.isEmpty else { continue }
                        if !path.lowercased().hasSuffix(".bib") { path += ".bib" }
                        symbols.bibliographyFiles.append(path)
                    }
                    j = end
                }
            default:
                break
            }
            // Zeilenumbrüche im übersprungenen Teil mitzählen.
            if j > nameEnd {
                for k in nameEnd..<min(j, count) where text[k] == TeXChar.newline { line += 1 }
            }
            i = max(j, i + 1)
        }
        return symbols
    }

    private static func skipSpaces<S: UTF16Source>(_ text: S, from index: Int) -> Int {
        var i = index
        while i < text.count, text[i] == TeXChar.space || text[i] == TeXChar.tab { i += 1 }
        return i
    }

    /// `{…}` ab `index` (verschachtelte Klammern erlaubt) → Inhalt und Position nach `}`.
    static func braceArgument<S: UTF16Source>(_ text: S, at index: Int) -> (String, Int)? {
        guard index < text.count, text[index] == TeXChar.braceOpen else { return nil }
        var depth = 0
        var i = index
        while i < text.count {
            let u = text[i]
            if u == TeXChar.braceOpen && !text.isEscaped(at: i) { depth += 1 }
            if u == TeXChar.braceClose && !text.isEscaped(at: i) {
                depth -= 1
                if depth == 0 { return (text.string(in: (index + 1)..<i), i + 1) }
            }
            // Ein Argument endet spätestens am Ende des Absatzes.
            if u == TeXChar.newline, i + 1 < text.count, text[i + 1] == TeXChar.newline { return nil }
            i += 1
        }
        return nil
    }

    /// `[…]` ab `index` → Inhalt und Position nach `]`.
    static func bracketArgument<S: UTF16Source>(_ text: S, at index: Int) -> (String, Int)? {
        guard index < text.count, text[index] == TeXChar.bracketOpen else { return nil }
        var i = index + 1
        var depth = 0
        while i < text.count {
            let u = text[i]
            if u == TeXChar.braceOpen { depth += 1 }
            if u == TeXChar.braceClose { depth -= 1 }
            if u == TeXChar.bracketClose && depth <= 0 { return (text.string(in: (index + 1)..<i), i + 1) }
            if u == TeXChar.newline { return nil }
            i += 1
        }
        return nil
    }
}

/// Ein Eintrag aus einer `.bib`-Datei.
public struct BibliographyEntry: Equatable, Sendable {
    public var key: String
    public var title: String?
    public var author: String?
    public var year: String?

    public init(key: String, title: String? = nil, author: String? = nil, year: String? = nil) {
        self.key = key
        self.title = title
        self.author = author
        self.year = year
    }

    /// Kurzbeschreibung für die Vorschlagsliste: „Müller (2020): Analysis I“.
    public var summary: String {
        var parts: [String] = []
        if let author {
            let first = author.components(separatedBy: " and ").first ?? author
            let surname = first.contains(",") ? (first.components(separatedBy: ",").first ?? first) : (first.split(separator: " ").last.map(String.init) ?? first)
            parts.append(surname.trimmingCharacters(in: .whitespaces) + (year.map { " (\($0))" } ?? ""))
        } else if let year {
            parts.append(year)
        }
        if let title { parts.append(title) }
        return parts.joined(separator: ": ")
    }
}

/// Liest die Schlüssel (und Titel) aus einer `.bib`-Datei – ohne BibTeX.
public enum BibliographyParser {
    public static func entries(in bibText: String) -> [BibliographyEntry] {
        let text = Array(bibText.utf16)
        var entries: [BibliographyEntry] = []
        var i = 0
        while i < text.count {
            guard text[i] == 0x40 /* @ */ else { i += 1; continue }
            var j = i + 1
            while j < text.count, TeXChar.isASCIILetter(text[j]) { j += 1 }
            let type = text.string(in: (i + 1)..<j).lowercased()
            while j < text.count, TeXChar.isWhitespace(text[j]) { j += 1 }
            guard j < text.count, text[j] == TeXChar.braceOpen || text[j] == TeXChar.parenOpen else { i = j; continue }
            // Ende des Eintrags: passende schliessende Klammer.
            var depth = 0
            var end = j
            while end < text.count {
                if text[end] == TeXChar.braceOpen || text[end] == TeXChar.parenOpen { depth += 1 }
                if text[end] == TeXChar.braceClose || text[end] == TeXChar.parenClose {
                    depth -= 1
                    if depth == 0 { break }
                }
                end += 1
            }
            defer { i = end + 1 }
            guard !["comment", "string", "preamble"].contains(type) else { continue }
            let body = text.string(in: (j + 1)..<min(end, text.count))
            guard let comma = body.firstIndex(of: ",") else { continue }
            let key = body[..<comma].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty else { continue }
            let fields = String(body[body.index(after: comma)...])
            entries.append(BibliographyEntry(
                key: key,
                title: field("title", in: fields),
                author: field("author", in: fields),
                year: field("year", in: fields)
            ))
        }
        return entries
    }

    /// Wert eines Feldes (`title = {…}`, `"…"` oder Zahl), ohne innere Klammern.
    static func field(_ name: String, in fields: String) -> String? {
        let units = Array(fields.utf16)
        let lower = fields.lowercased()
        var search = lower.startIndex
        while let found = lower.range(of: name, range: search..<lower.endIndex) {
            search = found.upperBound
            let start = lower.utf16.distance(from: lower.startIndex, to: found.lowerBound)
            // Ganzes Wort: davor kein Buchstabe.
            if start > 0, TeXChar.isASCIILetter(units[start - 1]) { continue }
            var i = start + name.utf16.count
            while i < units.count, TeXChar.isWhitespace(units[i]) { i += 1 }
            guard i < units.count, units[i] == 0x3D /* = */ else { continue }
            i += 1
            while i < units.count, TeXChar.isWhitespace(units[i]) { i += 1 }
            guard i < units.count else { return nil }
            var value: String
            if units[i] == TeXChar.braceOpen {
                var depth = 0
                var j = i
                while j < units.count {
                    if units[j] == TeXChar.braceOpen { depth += 1 }
                    if units[j] == TeXChar.braceClose {
                        depth -= 1
                        if depth == 0 { break }
                    }
                    j += 1
                }
                value = units.string(in: (i + 1)..<j)
            } else if units[i] == 0x22 /* " */ {
                var j = i + 1
                while j < units.count, units[j] != 0x22 { j += 1 }
                value = units.string(in: (i + 1)..<j)
            } else {
                var j = i
                while j < units.count, units[j] != 0x2C /* , */, units[j] != TeXChar.newline, units[j] != TeXChar.braceClose { j += 1 }
                value = units.string(in: i..<j)
            }
            value = value.replacingOccurrences(of: "{", with: "").replacingOccurrences(of: "}", with: "")
                .components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined(separator: " ")
            return value.isEmpty ? nil : value
        }
        return nil
    }
}
