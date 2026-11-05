import Foundation

/// Autovervollständigung: erkennt, was gerade getippt wird, sucht passende
/// Vorschläge und berechnet die Einfügung.
///
/// - `\fra|` → Befehle (`\frac{…}{…}`, …). Deutsche Suchbegriffe zählen mit:
///   `\bruch` findet `\frac`.
/// - `\begin{enu|` → Umgebungen; die Auswahl fügt gleich `\end{enumerate}` an.
/// - `\ref{|`, `\eqref{|` → Marken aus dem Dokument.
/// - `\cite{|` → Quellen aus `\bibitem` und `.bib`-Dateien.
/// - `\usepackage{|`, `\documentclass{|` → Pakete bzw. Klassen.
public enum CompletionEngine {
    /// Höchstens so viele Vorschläge zeigen.
    public static let maximumSuggestions = 50

    private static let referenceCommands: Set<String> = ["ref", "eqref", "pageref", "autoref", "cref", "Cref", "nameref", "vref"]
    private static let citationCommands: Set<String> = ["cite", "citep", "citet", "parencite", "textcite", "autocite", "footcite", "nocite", "citeauthor", "citeyear"]

    // MARK: - Was wird getippt?

    /// Erkennt den Vervollständigungs-Kontext am Cursor – oder `nil`, wenn es nichts vorzuschlagen gibt.
    public static func context<S: UTF16Source>(in text: S, cursor: Int, inMath: Bool) -> CompletionContext? {
        guard cursor >= 0, cursor <= text.count else { return nil }
        if BracketMatcher.isInComment(text, cursor) { return nil }

        // 1. Befehlsname: `\abc|`
        var nameStart = cursor
        while nameStart > 0, TeXChar.isASCIILetter(text[nameStart - 1]) { nameStart -= 1 }
        if nameStart > 0, text[nameStart - 1] == TeXChar.backslash, !text.isEscaped(at: nameStart - 1) {
            // Mitten in einem Befehlsnamen (`\fr|ac`) nichts vorschlagen.
            if let next = text.unit(at: cursor), TeXChar.isASCIILetter(next) { return nil }
            return CompletionContext(
                kind: .command,
                prefix: text.string(in: nameStart..<cursor),
                range: (nameStart - 1)..<cursor,
                commandStart: nameStart - 1,
                closingBraceFollows: false,
                inMath: inMath
            )
        }

        // 2. Argument: `\befehl[optionen]{abc|`
        var argumentStart = cursor
        while argumentStart > 0, isArgumentUnit(text[argumentStart - 1]) { argumentStart -= 1 }
        var argumentEnd = cursor
        while argumentEnd < text.count, isArgumentUnit(text[argumentEnd]) { argumentEnd += 1 }

        // Bei mehreren Quellen (`\cite{a,b|`) bis zur öffnenden Klammer zurück.
        var brace = argumentStart - 1
        while brace >= 0, text[brace] == 0x2C /* , */ || text[brace] == TeXChar.space || isArgumentUnit(text[brace]) {
            brace -= 1
        }
        guard brace >= 0, text[brace] == TeXChar.braceOpen, !text.isEscaped(at: brace) else { return nil }
        let hasComma = text.string(in: (brace + 1)..<argumentStart).contains(",")

        // Optionale Argumente `[…]` davor überspringen.
        var commandEnd = brace
        while commandEnd > 0, text[commandEnd - 1] == TeXChar.bracketClose {
            var k = commandEnd - 2
            while k >= 0, text[k] != TeXChar.bracketOpen, text[k] != TeXChar.newline { k -= 1 }
            guard k >= 0, text[k] == TeXChar.bracketOpen else { return nil }
            commandEnd = k
        }
        var commandStart = commandEnd
        while commandStart > 0, TeXChar.isASCIILetter(text[commandStart - 1]) { commandStart -= 1 }
        guard commandStart > 0, commandStart < commandEnd,
              text[commandStart - 1] == TeXChar.backslash, !text.isEscaped(at: commandStart - 1) else { return nil }
        let command = text.string(in: commandStart..<commandEnd)

        let kind: CompletionContext.Kind
        switch command {
        case "begin": kind = .environment(isEnd: false)
        case "end": kind = .environment(isEnd: true)
        case "usepackage", "RequirePackage": kind = .package
        case "documentclass": kind = .documentClass
        default:
            if referenceCommands.contains(command) {
                kind = .reference
            } else if citationCommands.contains(command) {
                kind = .citation
            } else {
                return nil
            }
        }
        // Mehrere Einträge mit Komma gibt es nur bei Quellen und Paketen.
        if hasComma, kind != .citation, kind != .package { return nil }
        return CompletionContext(
            kind: kind,
            prefix: text.string(in: argumentStart..<cursor),
            range: argumentStart..<argumentEnd,
            commandStart: commandStart - 1,
            closingBraceFollows: text.unit(at: argumentEnd) == TeXChar.braceClose,
            inMath: inMath
        )
    }

    /// Zeichen, die in Marken, Umgebungs- und Paketnamen vorkommen.
    static func isArgumentUnit(_ u: UInt16) -> Bool {
        if TeXChar.isASCIILetter(u) || TeXChar.isASCIIDigit(u) { return true }
        switch u {
        case 0x3A, 0x2D, 0x5F, 0x2E, 0x2F, 0x2B, TeXChar.star: // : - _ . / + *
            return true
        default:
            return u >= 0x80 && TeXChar.isAlphanumeric(u)
        }
    }

    // MARK: - Vorschläge

    /// Passende Vorschläge, die besten zuerst.
    ///
    /// - Parameters:
    ///   - symbols: Marken, eigene Befehle usw. aus dem Dokument (`DocumentSymbols.scan`).
    ///   - bibliography: Einträge aus den `.bib`-Dateien des Dokuments.
    ///   - openEnvironment: Innerste offene Umgebung am Cursor – wird bei `\end{` zuerst vorgeschlagen.
    public static func suggestions(
        for context: CompletionContext,
        symbols: DocumentSymbols = DocumentSymbols(),
        bibliography: [BibliographyEntry] = [],
        openEnvironment: String? = nil
    ) -> [CompletionItem] {
        let candidates: [CompletionItem]
        switch context.kind {
        case .command:
            candidates = commandCandidates(prefix: context.prefix, symbols: symbols)
        case .environment(let isEnd):
            candidates = environmentCandidates(symbols: symbols, typed: context.prefix, openEnvironment: isEnd ? openEnvironment : nil)
        case .reference:
            candidates = symbols.labels.enumerated().map { index, label in
                CompletionItem(
                    id: "label.\(label.key)", kind: .reference, name: label.key, label: label.key,
                    detail: "\(labelKind(label.key)) · Zeile \(label.line)", body: label.key,
                    priority: max(0, 60 - index / 4)
                )
            }
        case .citation:
            var keys = Set<String>()
            var items: [CompletionItem] = []
            for entry in bibliography where keys.insert(entry.key).inserted {
                items.append(CompletionItem(id: "cite.\(entry.key)", kind: .citation, name: entry.key, label: entry.key, detail: entry.summary.isEmpty ? "Quelle" : entry.summary, body: entry.key))
            }
            for key in symbols.bibItems where keys.insert(key).inserted {
                items.append(CompletionItem(id: "cite.\(key)", kind: .citation, name: key, label: key, detail: "Quelle aus \\bibitem", body: key))
            }
            candidates = items
        case .package:
            candidates = CompletionCatalog.packages
        case .documentClass:
            candidates = CompletionCatalog.documentClasses
        }
        return rank(candidates, for: context)
    }

    private static func commandCandidates(prefix: String, symbols: DocumentSymbols) -> [CompletionItem] {
        var items = CompletionCatalog.commands
        for command in symbols.userCommands {
            let arguments = String(repeating: "{•}", count: command.argumentCount)
            items.append(CompletionItem(
                id: "user.\(command.name)", kind: .userCommand, name: command.name,
                label: "\\\(command.name)" + String(repeating: "{…}", count: command.argumentCount),
                detail: command.isMathOperator ? "Eigener Operator aus diesem Dokument" : "Eigener Befehl aus diesem Dokument",
                body: "\\\(command.name)" + arguments,
                requiresMath: command.isMathOperator, isMath: command.isMathOperator, priority: 70
            ))
        }
        // Ganze Umgebungen schon beim Befehl anbieten: `\enum` → `\begin{enumerate}`.
        if prefix.count >= 3 {
            let lowered = prefix.lowercased()
            let beginMatches = "begin".hasPrefix(lowered)
            for environment in CompletionCatalog.environments where beginMatches || environment.name.lowercased().hasPrefix(lowered) {
                var item = environment
                item.kind = .environment
                item.label = "\\begin{\(environment.name)}"
                item.requiresMath = false
                // Wird als `begin…` oder über den Umgebungsnamen gefunden.
                item.keywords = environment.keywords + [environment.name.lowercased(), "begin"]
                item.name = beginMatches ? "begin" + environment.name : environment.name
                item.priority = environment.priority - 25
                items.append(item)
            }
        }
        return items
    }

    private static func environmentCandidates(symbols: DocumentSymbols, typed: String, openEnvironment: String?) -> [CompletionItem] {
        var items = CompletionCatalog.environments
        var known = Set(items.map(\.name))
        for name in symbols.userEnvironments where known.insert(name).inserted {
            items.append(CompletionItem(
                id: "environment.\(name)", kind: .environment, name: name, label: name,
                detail: "Eigene Umgebung aus diesem Dokument",
                body: "\\begin{\(name)}\n  ‸\n\\end{\(name)}", priority: 65
            ))
        }
        // Das gerade getippte `\begin{…}` selbst nicht als „kommt vor“ anbieten.
        for name in symbols.usedEnvironments where name != typed && known.insert(name).inserted {
            items.append(CompletionItem(
                id: "environment.\(name)", kind: .environment, name: name, label: name,
                detail: "Kommt im Dokument vor",
                body: "\\begin{\(name)}\n  ‸\n\\end{\(name)}", priority: 45
            ))
        }
        if let openEnvironment, let index = items.firstIndex(where: { $0.name == openEnvironment }) {
            items[index].detail = "Schliesst \\begin{\(openEnvironment)}"
            items[index].priority = 1000
        } else if let openEnvironment {
            items.append(CompletionItem(
                id: "environment.\(openEnvironment)", kind: .environment, name: openEnvironment, label: openEnvironment,
                detail: "Schliesst \\begin{\(openEnvironment)}", body: openEnvironment, priority: 1000
            ))
        }
        return items
    }

    /// Ordnet nach Übereinstimmung, Kontext (Formel oder Text) und Häufigkeit.
    static func rank(_ items: [CompletionItem], for context: CompletionContext) -> [CompletionItem] {
        let prefix = context.prefix
        let lowered = prefix.lowercased()
        var scored: [(item: CompletionItem, tier: Int, score: Int)] = []
        for item in items {
            let name = item.name
            var tier: Int
            if prefix.isEmpty {
                tier = 1
            } else if name.hasPrefix(prefix) {
                tier = 0
            } else if name.lowercased().hasPrefix(lowered) {
                tier = 1
            } else if lowered.count >= 3, item.keywords.contains(where: { keyword in
                keyword.split(separator: " ").contains { $0.hasPrefix(lowered) }
            }) {
                tier = 2
            } else if lowered.count >= 2, name.lowercased().contains(lowered) {
                tier = 3
            } else {
                continue
            }
            var score = item.priority
            if name == prefix { score += 500 }
            if context.kind == .command {
                if context.inMath {
                    score += item.isMath ? 25 : (item.kind == .command ? -20 : 0)
                } else if item.isMath {
                    score -= 10
                }
            }
            scored.append((item, tier, score))
        }
        scored.sort { a, b in
            if a.tier != b.tier { return a.tier < b.tier }
            if a.score != b.score { return a.score > b.score }
            if a.item.name.count != b.item.name.count { return a.item.name.count < b.item.name.count }
            return a.item.label < b.item.label
        }
        var seenLabels = Set<String>()
        var result: [CompletionItem] = []
        for entry in scored where seenLabels.insert(entry.item.label).inserted {
            result.append(entry.item)
            if result.count == maximumSuggestions { break }
        }
        return result
    }

    private static func labelKind(_ key: String) -> String {
        let prefix = key.split(separator: ":").first.map { String($0).lowercased() } ?? ""
        switch prefix {
        case "fig", "abb": return "Abbildung"
        case "tab": return "Tabelle"
        case "eq", "gl": return "Gleichung"
        case "sec", "subsec", "chap", "kap", "abs": return "Abschnitt"
        case "def": return "Definition"
        case "thm", "satz", "lem": return "Satz"
        default: return "Marke"
        }
    }

    // MARK: - Einfügen

    /// Berechnet die Einfügung eines Vorschlags.
    ///
    /// Danach steht der Cursor am `‸`, sonst ist der erste Platzhalter `•`
    /// ausgewählt, sonst steht der Cursor am Ende.
    public static func edit<S: UTF16Source>(applying item: CompletionItem, context: CompletionContext, in text: S) -> TextEdit {
        switch context.kind {
        case .command:
            return commandEdit(item, context, text)
        case .environment(let isEnd):
            if !isEnd, item.body.hasPrefix("\\begin{"),
               needsEnd(for: item.name, in: text, typedAt: context.commandStart) {
                return environmentEdit(item, context, text)
            }
            return argumentEdit(item.name, context)
        case .reference, .citation, .package, .documentClass:
            return argumentEdit(item.name, context)
        }
    }

    /// Ist der Vorschlag genau das, was schon dasteht (z. B. `\item` ganz getippt)?
    /// Dann soll ↩ eine neue Zeile beginnen und nicht „vervollständigen“.
    public static func isAlreadyComplete(_ item: CompletionItem, context: CompletionContext) -> Bool {
        guard context.kind == .command else { return item.name == context.prefix && context.closingBraceFollows }
        let body = item.body.trimmingCharacters(in: .whitespaces)
        return body == "\\" + context.prefix
    }

    private static func argumentEdit(_ name: String, _ context: CompletionContext) -> TextEdit {
        let caret: Int
        let replacement: String
        if context.closingBraceFollows {
            replacement = name
            caret = context.range.lowerBound + name.utf16.count + 1
        } else {
            replacement = name + "}"
            caret = context.range.lowerBound + replacement.utf16.count
        }
        return TextEdit(range: context.range, replacement: replacement, selectionAfter: caret..<caret)
    }

    private static func commandEdit<S: UTF16Source>(_ item: CompletionItem, _ context: CompletionContext, _ text: S) -> TextEdit {
        var body = item.body
        let isMultiline = body.contains("\n")
        if isMultiline {
            body = indented(body, like: text, at: context.range.lowerBound)
        }
        if item.requiresMath && !context.inMath && !isMultiline {
            body = "$" + body + "$"
        }
        // `\alpha` direkt vor einem Buchstaben würde zu `\alphax` verschmelzen.
        if !body.contains(Placeholders.marker), !body.contains(CompletionItem.cursorMarker),
           body.last.map({ $0.isLetter && $0.isASCII }) == true,
           let next = text.unit(at: context.range.upperBound), TeXChar.isASCIILetter(next) {
            body += " "
        }
        return finish(body, replacing: context.range)
    }

    private static func environmentEdit<S: UTF16Source>(_ item: CompletionItem, _ context: CompletionContext, _ text: S) -> TextEdit {
        // Von `\begin` bis hinter die (automatisch eingefügte) schliessende Klammer ersetzen.
        let end = context.range.upperBound + (context.closingBraceFollows ? 1 : 0)
        let body = indented(item.body, like: text, at: context.commandStart)
        return finish(body, replacing: context.commandStart..<end)
    }

    /// Fehlt zur Umgebung noch ein `\end`? Das gerade getippte `\begin{…}` zählt
    /// als neu, auch wenn sein Name schon vollständig dasteht.
    static func needsEnd<S: UTF16Source>(for name: String, in text: S, typedAt position: Int) -> Bool {
        var begins = EditingAssistant.occurrences(of: "\\begin{\(name)}", in: text)
        if text.matches("\\begin{\(name)}", at: position) { begins -= 1 }
        let ends = EditingAssistant.occurrences(of: "\\end{\(name)}", in: text)
        return begins + 1 > ends
    }

    /// Folgezeilen bekommen die Einrückung der Zeile, in der eingefügt wird.
    private static func indented<S: UTF16Source>(_ body: String, like text: S, at position: Int) -> String {
        let indent = EditingAssistant.leadingWhitespace(text, lineContaining: position)
        guard !indent.isEmpty else { return body }
        return body.replacingOccurrences(of: "\n", with: "\n" + indent)
    }

    /// Entfernt `‸`, setzt den Cursor bzw. wählt den ersten Platzhalter aus.
    private static func finish(_ body: String, replacing range: Range<Int>) -> TextEdit {
        let units = Array(body.utf16)
        let caretUnits = Array(CompletionItem.cursorMarker.utf16)
        if let caretIndex = firstIndex(of: caretUnits, in: units) {
            var cleaned = units
            cleaned.removeSubrange(caretIndex..<(caretIndex + caretUnits.count))
            let caret = range.lowerBound + caretIndex
            return TextEdit(range: range, replacement: String(decoding: cleaned, as: UTF16.self), selectionAfter: caret..<caret)
        }
        if let placeholder = units.firstIndex(of: Placeholders.unit) {
            let start = range.lowerBound + placeholder
            return TextEdit(range: range, replacement: body, selectionAfter: start..<(start + 1))
        }
        let caret = range.lowerBound + units.count
        return TextEdit(range: range, replacement: body, selectionAfter: caret..<caret)
    }

    private static func firstIndex(of needle: [UInt16], in haystack: [UInt16]) -> Int? {
        guard !needle.isEmpty, haystack.count >= needle.count else { return nil }
        for start in 0...(haystack.count - needle.count) where haystack[start] == needle[0] {
            if Array(haystack[start..<(start + needle.count)]) == needle { return start }
        }
        return nil
    }

    // MARK: - Offene Umgebung

    /// Innerste Umgebung, die vor `position` mit `\begin` geöffnet und noch nicht geschlossen wurde.
    public static func openEnvironment<S: UTF16Source>(in text: S, before position: Int) -> String? {
        var stack: [String] = []
        var i = 0
        let limit = min(position, text.count)
        while i < limit {
            let u = text[i]
            if u == TeXChar.percent && !text.isEscaped(at: i) {
                i = text.lineEnd(after: i)
                continue
            }
            if u == TeXChar.backslash, !text.isEscaped(at: i) {
                let isBegin = text.matches("\\begin{", at: i)
                let isEnd = text.matches("\\end{", at: i)
                if isBegin || isEnd {
                    let open = i + (isBegin ? 7 : 5)
                    var close = open
                    while close < limit, text[close] != TeXChar.braceClose, text[close] != TeXChar.newline { close += 1 }
                    if close < limit, text[close] == TeXChar.braceClose {
                        let name = text.string(in: open..<close)
                        if isBegin {
                            stack.append(name)
                        } else if let index = stack.lastIndex(of: name) {
                            stack.removeSubrange(index...)
                        }
                        i = close + 1
                        continue
                    }
                }
            }
            i += 1
        }
        return stack.last
    }
}
