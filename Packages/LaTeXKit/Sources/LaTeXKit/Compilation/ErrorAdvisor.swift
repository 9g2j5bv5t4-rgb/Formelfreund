import Foundation

/// Was bei einer Meldung zu tun ist – auf Deutsch und für Einsteiger.
public struct IssueAdvice: Equatable, Sendable {
    /// Was passiert ist, in einem Satz.
    public var explanation: String
    /// Was man tun kann.
    public var suggestion: String
    /// Automatische Behebung mit einem Klick, falls Lemma sie sicher kennt.
    public var fix: QuickFix?

    public init(explanation: String, suggestion: String, fix: QuickFix? = nil) {
        self.explanation = explanation
        self.suggestion = suggestion
        self.fix = fix
    }
}

/// Eine Behebung mit einem Klick.
public enum QuickFix: Hashable, Sendable {
    /// Ein Paket (mit evtl. nötigen Präambel-Zeilen) laden.
    case loadPackage(PackageRequirement)
    /// In Zeile `line` (1-basiert) das erste `old` durch `new` ersetzen.
    case replace(line: Int, old: String, new: String)
    /// Die Umgebung, die in Zeile `line` beginnt, umbenennen (`\begin` und `\end`).
    case renameEnvironment(line: Int, old: String, new: String)

    /// Beschriftung des Knopfs.
    public var title: String {
        switch self {
        case .loadPackage(let requirement):
            return requirement.preambleLines.isEmpty
                ? "Paket \(requirement.name) laden"
                : "In der Präambel definieren"
        case .replace(_, let old, let new):
            return "\(old) durch \(new) ersetzen"
        case .renameEnvironment(_, _, let new):
            return "In „\(new)“ umbenennen"
        }
    }
}

/// Übersetzt LaTeX-Meldungen in verständliche Erklärungen mit Lösungsvorschlag.
public enum ErrorAdvisor {
    // MARK: - Ratschlag

    /// - Parameter lines: Zeilen der Hauptdatei (für genauere Vorschläge), falls bekannt.
    public static func advice(for issue: CompileIssue, lines: [String]? = nil) -> IssueAdvice? {
        let message = issue.message.trimmingCharacters(in: .whitespaces)
        let line = issue.line
        let sourceLine = line.flatMap { number in lines.flatMap { number >= 1 && number <= $0.count ? $0[number - 1] : nil } }

        if message.hasPrefix("Undefined control sequence") {
            return undefinedCommand(issue, sourceLine: sourceLine)
        }
        if let (begin, end) = captures(message, #"\\begin\{([^}]*)\} on input line \d+ ended by \\end\{([^}]*)\}"#) {
            if end == "document" {
                return IssueAdvice(
                    explanation: "Die Umgebung „\(begin)“ wird nie geschlossen.",
                    suggestion: "Füge \\end{\(begin)} an der richtigen Stelle ein – spätestens vor \\end{document}.",
                    fix: line.map { .replace(line: $0, old: "\\end{document}", new: "\\end{\(begin)}\n\\end{document}") }
                )
            }
            return IssueAdvice(
                explanation: "\\begin{\(begin)} wird mit \\end{\(end)} geschlossen – die beiden müssen gleich heissen.",
                suggestion: "Ersetze \\end{\(end)} durch \\end{\(begin)}.",
                fix: line.map { .replace(line: $0, old: "\\end{\(end)}", new: "\\end{\(begin)}") }
            )
        }
        if let name = capture(message, #"\\begin\{document\} ended by \\end\{([^}]*)\}"#) {
            return IssueAdvice(
                explanation: "\\end{\(name)} hat kein passendes \\begin{\(name)}.",
                suggestion: "Lösche \\end{\(name)} oder ergänze weiter oben \\begin{\(name)}."
            )
        }
        if let name = capture(message, #"Environment (\S+) undefined"#) {
            return undefinedEnvironment(name, line: line)
        }
        if let file = capture(message, #"File `([^']*)' not found"#) {
            if file.hasSuffix(".sty") || file.hasSuffix(".cls") {
                let name = (file as NSString).deletingPathExtension
                return IssueAdvice(
                    explanation: "Das Paket „\(name)“ gibt es nicht.",
                    suggestion: "Prüfe die Schreibweise in \\usepackage{\(name)}. Tectonic lädt vorhandene Pakete automatisch."
                )
            }
            return IssueAdvice(
                explanation: "Die Datei „\(file)“ wurde nicht gefunden.",
                suggestion: "Liegt sie im Ordner des Dokuments (bzw. im Unterordner „Bilder“)? Stimmt die Schreibweise samt Endung? Das Dokument muss gesichert sein, damit Lemma den Ordner kennt."
            )
        }
        if let file = capture(message, #"Unable to load picture or PDF file '([^']*)'"#) {
            return IssueAdvice(
                explanation: "Das Bild „\(file)“ wurde nicht gefunden.",
                suggestion: "Liegt es im Ordner des Dokuments (bzw. im Unterordner „Bilder“)? Stimmt die Schreibweise samt Endung? Am einfachsten fügst du Bilder über Einfügen → Bild ein."
            )
        }
        if let package = capture(message, #"Option clash for package (\S+?)\.?$"#) {
            return IssueAdvice(
                explanation: "Das Paket „\(package)“ wird zweimal mit verschiedenen Optionen geladen.",
                suggestion: "Lade es nur einmal und schreibe alle Optionen in dieselbe Zeile."
            )
        }
        if let command = capture(message, #"Command (\\[A-Za-z@]+) already defined"#) {
            return IssueAdvice(
                explanation: "Den Befehl \(command) gibt es schon.",
                suggestion: "Wähle einen anderen Namen oder überschreibe ihn mit \\renewcommand.",
                fix: line.flatMap { number in
                    sourceLine?.contains("\\newcommand") == true
                        ? .replace(line: number, old: "\\newcommand", new: "\\renewcommand") : nil
                }
            )
        }
        if message.hasPrefix("Missing $ inserted") {
            return IssueAdvice(
                explanation: "Ein Formelzeichen (z. B. ^, _ oder \\alpha) steht ausserhalb einer Formel – oder eine Formel ist nicht geschlossen.",
                suggestion: "Setze die Formel zwischen $ … $ und prüfe, ob jedes $ ein Gegenstück hat. In Formeln darf keine Leerzeile stehen."
            )
        }
        if message.hasPrefix("Double superscript") || message.hasPrefix("Double subscript") {
            let mark = message.hasPrefix("Double superscript") ? "^" : "_"
            return IssueAdvice(
                explanation: "Zwei \(mark == "^" ? "Hochstellungen" : "Tiefstellungen") hintereinander (x\(mark)2\(mark)3) sind nicht eindeutig.",
                suggestion: "Setze geschweifte Klammern: x\(mark){2\(mark)3} oder {x\(mark)2}\(mark)3."
            )
        }
        if message.hasPrefix("Extra alignment tab") {
            return IssueAdvice(
                explanation: "In einer Zeile stehen mehr & als die Tabelle bzw. Matrix Spalten hat.",
                suggestion: "Entferne ein & oder ergänze eine Spalte, z. B. {ccc} statt {cc}."
            )
        }
        if message.hasPrefix("Misplaced alignment tab character") {
            return IssueAdvice(
                explanation: "Das Zeichen & trennt nur Spalten in Tabellen und ausgerichteten Formeln.",
                suggestion: "Für ein echtes &-Zeichen schreibe \\&. Für ausgerichtete Formeln nutze eine align-Umgebung.",
                fix: line.flatMap { number in
                    sourceLine.map(hasUnescapedAmpersand) == true ? .replace(line: number, old: "&", new: "\\&") : nil
                }
            )
        }
        if message.hasPrefix("Missing } inserted") || message.hasPrefix("Missing { inserted") || message.hasPrefix("Runaway argument")
            || message.hasPrefix("Paragraph ended before") || message.hasPrefix("File ended while scanning") {
            return IssueAdvice(
                explanation: "Eine geschweifte Klammer ist nicht geschlossen.",
                suggestion: "Prüfe die Klammern in dieser Zeile: Jede { braucht eine }. Lemma hebt das Gegenstück hervor, wenn der Cursor neben einer Klammer steht."
            )
        }
        if message.hasPrefix("Extra }, or forgotten") || message.hasPrefix("Too many }'s") || message.hasPrefix("Extra }") {
            return IssueAdvice(
                explanation: "Hier steht eine } ohne passende {.",
                suggestion: "Lösche die überzählige } oder ergänze weiter vorne die fehlende {."
            )
        }
        if message.contains("Lonely \\item") {
            return IssueAdvice(
                explanation: "\\item steht ausserhalb einer Liste.",
                suggestion: "Packe die Punkte in eine Liste: Auswahl markieren → Blöcke → Einpacken → Aufzählung."
            )
        }
        if message.contains("perhaps a missing \\item") {
            return IssueAdvice(
                explanation: "In einer Liste fehlt \\item vor dem Text.",
                suggestion: "Beginne jeden Punkt der Liste mit \\item."
            )
        }
        if message.hasPrefix("There's no line here to end") {
            return IssueAdvice(
                explanation: "\\\\ (Zeilenumbruch) steht am Anfang eines Absatzes oder nach einer Leerzeile.",
                suggestion: "Entferne das \\\\ – für einen neuen Absatz genügt eine Leerzeile."
            )
        }
        if message.contains("Missing \\begin{document}") {
            return IssueAdvice(
                explanation: "Text steht in der Präambel, also vor \\begin{document}.",
                suggestion: "Verschiebe den Text hinter \\begin{document}. In der Präambel stehen nur Einstellungen wie \\usepackage."
            )
        }
        if message.hasPrefix("Illegal unit of measure") {
            return IssueAdvice(
                explanation: "Bei einer Längenangabe fehlt die Einheit.",
                suggestion: "Schreibe die Einheit dazu, z. B. 2cm, 5mm oder 12pt."
            )
        }
        if message.hasPrefix("Missing number") {
            return IssueAdvice(
                explanation: "Hier erwartet LaTeX eine Zahl oder Länge.",
                suggestion: "Prüfe Angaben wie \\vspace{…} oder width=…: Steht dort eine Zahl mit Einheit?"
            )
        }
        if message.hasPrefix("Display math should end with $$") {
            return IssueAdvice(
                explanation: "Eine abgesetzte Formel mit $$ … $$ ist nicht richtig geschlossen.",
                suggestion: "Verwende besser \\[ … \\] – das ist die moderne Schreibweise."
            )
        }
        if message.hasPrefix("Bad math environment delimiter") {
            return IssueAdvice(
                explanation: "\\[ oder \\( steht an einer Stelle, an der schon eine Formel offen ist.",
                suggestion: "Schliesse die vorherige Formel zuerst oder entferne das doppelte \\[."
            )
        }
        if message.contains("not set up for use with LaTeX") {
            return IssueAdvice(
                explanation: "Dieses Sonderzeichen kann pdfLaTeX nicht setzen.",
                suggestion: "Mit Tectonic (Standard in Lemma) geht es. Sonst schreibe das Zeichen als LaTeX-Befehl, z. B. \\alpha statt α."
            )
        }
        if let label = capture(message, #"Reference `([^']*)'.*undefined"#) {
            return IssueAdvice(
                explanation: "Der Verweis auf „\(label)“ zeigt ins Leere.",
                suggestion: "Gibt es \\label{\(label)} im Dokument? Stimmt die Schreibweise? Neue Marken erscheinen manchmal erst nach dem zweiten Kompilieren."
            )
        }
        if let label = capture(message, #"Label `([^']*)' multiply defined"#) {
            return IssueAdvice(
                explanation: "Die Marke „\(label)“ ist mehrfach vergeben.",
                suggestion: "Jedes \\label{…} braucht einen eigenen Namen."
            )
        }
        if let key = capture(message, #"Citation `([^']*)'.*undefined"#) {
            return IssueAdvice(
                explanation: "Die Literaturangabe „\(key)“ wurde nicht gefunden.",
                suggestion: "Prüfe den Schlüssel in \\cite{\(key)} und die Literaturdatei."
            )
        }
        if message.hasPrefix("Emergency stop") || message.contains("Fatal error occurred") || message.contains("halted on") {
            return IssueAdvice(
                explanation: "LaTeX hat abgebrochen.",
                suggestion: "Das ist meist eine Folge des ersten Fehlers in der Liste – behebe zuerst diesen."
            )
        }
        return nil
    }

    // MARK: Unbekannter Befehl

    /// Befehle aus Paketen, die oft fehlen.
    static let packageForCommand: [String: String] = [
        "mathbb": "amssymb", "mathfrak": "amssymb", "varnothing": "amssymb", "nexists": "amssymb",
        "leqslant": "amssymb", "geqslant": "amssymb", "nmid": "amssymb", "square": "amssymb", "checkmark": "amssymb",
        "text": "amsmath", "eqref": "amsmath", "dfrac": "amsmath", "tfrac": "amsmath", "binom": "amsmath",
        "operatorname": "amsmath", "DeclareMathOperator": "amsmath", "numberwithin": "amsmath", "intertext": "amsmath",
        "iint": "amsmath", "iiint": "amsmath", "boldsymbol": "amsmath", "underset": "amsmath", "overset": "amsmath",
        "includegraphics": "graphicx", "graphicspath": "graphicx", "rotatebox": "graphicx", "scalebox": "graphicx",
        "href": "hyperref", "url": "hyperref", "autoref": "hyperref",
        "textcolor": "xcolor", "color": "xcolor", "colorbox": "xcolor", "definecolor": "xcolor",
        "toprule": "booktabs", "midrule": "booktabs", "bottomrule": "booktabs", "cmidrule": "booktabs",
        "SI": "siunitx", "si": "siunitx", "num": "siunitx", "qty": "siunitx", "unit": "siunitx",
        "lipsum": "lipsum", "multirow": "multirow", "coloneqq": "mathtools", "eqqcolon": "mathtools",
        "setstretch": "setspace", "onehalfspacing": "setspace", "doublespacing": "setspace",
        "cancel": "cancel", "enquote": "csquotes", "qedhere": "amsthm", "theoremstyle": "amsthm",
        "newgeometry": "geometry", "restoregeometry": "geometry", "subcaption": "subcaption",
        "lstinline": "listings", "tikz": "tikz", "draw": "tikz", "ce": "mhchem"
    ]

    /// Häufige Abkürzungen, die es in LaTeX so nicht gibt.
    static let commonMistakes: [String: String] = [
        "\\R": "\\mathbb{R}", "\\N": "\\mathbb{N}", "\\Z": "\\mathbb{Z}", "\\Q": "\\mathbb{Q}", "\\C": "\\mathbb{C}",
        "\\eps": "\\varepsilon", "\\implies": "\\Rightarrow", "\\iff": "\\Leftrightarrow",
        "\\bold": "\\textbf", "\\italic": "\\textit", "\\cursive": "\\textit", "\\degree": "^\\circ",
        "\\newparagraph": "\\par", "\\linebreak{}": "\\\\"
    ]

    /// Bekannte Befehle für „Meintest du …?“.
    static let knownCommands: [String] = {
        let symbols = MathSymbolGroup.allCases.flatMap(\.symbols).map(\.command).filter { !$0.contains("{") }
        let common = [
            "frac", "dfrac", "sqrt", "sum", "prod", "int", "iint", "oint", "lim", "infty", "cdot", "cdots", "ldots", "dots",
            "times", "leq", "geq", "neq", "approx", "equiv", "mathbb", "mathrm", "mathcal", "mathbf", "mathit", "text",
            "textbf", "textit", "texttt", "textsc", "textsf", "emph", "underline", "section", "subsection",
            "subsubsection", "chapter", "paragraph", "begin", "end", "item", "label", "ref", "eqref", "cite",
            "includegraphics", "caption", "centering", "hline", "newline", "newpage", "clearpage", "vspace", "hspace",
            "left", "right", "big", "Big", "quad", "qquad", "overline", "hat", "bar", "vec", "dot", "ddot", "tilde",
            "widehat", "binom", "log", "ln", "exp", "sin", "cos", "tan", "arcsin", "arccos", "arctan", "sinh", "cosh",
            "max", "min", "sup", "inf", "det", "dim", "ker", "gcd", "mod", "pmod", "bmod", "footnote", "url", "href",
            "textcolor", "tableofcontents", "maketitle", "title", "author", "date", "usepackage", "documentclass",
            "newcommand", "renewcommand", "operatorname", "displaystyle", "limits", "underbrace", "overbrace",
            "rightarrow", "leftarrow", "longrightarrow", "Longrightarrow", "langle", "rangle", "lvert", "rvert",
            "lVert", "rVert", "lfloor", "rfloor", "lceil", "rceil", "vdots", "ddots", "prime", "ell", "hbar",
            "noindent", "par", "smallskip", "medskip", "bigskip", "tiny", "small", "large", "Large", "huge"
        ].map { "\\" + $0 }
        return Array(Set(symbols + common)).sorted()
    }()

    private static func undefinedCommand(_ issue: CompileIssue, sourceLine: String?) -> IssueAdvice {
        // LaTeX zeigt den Text bis einschliesslich des unbekannten Befehls.
        let command = issue.contextBefore.flatMap { lastCommand(in: $0) }
        guard let command else {
            return IssueAdvice(
                explanation: "Diesen Befehl kennt LaTeX nicht.",
                suggestion: "Prüfe die Schreibweise oder lade das Paket, zu dem der Befehl gehört."
            )
        }
        let name = String(command.dropFirst())
        if let package = packageForCommand[name] {
            let requirement = package == "geometry" ? LocalLayout.geometryRequirement : PackageRequirement(package)
            return IssueAdvice(
                explanation: "\(command) gehört zum Paket „\(package)“, das noch nicht geladen ist.",
                suggestion: "Lade das Paket in der Präambel: \\usepackage{\(package)}.",
                fix: .loadPackage(requirement)
            )
        }
        if let replacement = commonMistakes[command] {
            let needsSymbols = replacement.hasPrefix("\\mathbb")
            return IssueAdvice(
                explanation: "\(command) gibt es in LaTeX nicht.",
                suggestion: "Schreibe \(replacement)\(needsSymbols ? " (aus dem Paket amssymb)" : "").",
                fix: issue.line.map { .replace(line: $0, old: command, new: replacement) }
            )
        }
        if let guess = closestKnownCommand(to: command) {
            return IssueAdvice(
                explanation: "\(command) kennt LaTeX nicht – wahrscheinlich ein Tippfehler.",
                suggestion: "Meintest du \(guess)?",
                fix: issue.line.map { .replace(line: $0, old: command, new: guess) }
            )
        }
        return IssueAdvice(
            explanation: "\(command) kennt LaTeX nicht.",
            suggestion: "Prüfe die Schreibweise oder lade das Paket, zu dem der Befehl gehört. Eigene Befehle definierst du mit \\newcommand in der Präambel."
        )
    }

    /// Letzter Befehlsname (`\foo`) in einem Text.
    static func lastCommand(in text: String) -> String? {
        let units = Array(text.utf16)
        var i = units.count - 1
        while i >= 0 {
            if units[i] == TeXChar.backslash {
                var j = i + 1
                while j < units.count && TeXChar.isASCIILetter(units[j]) { j += 1 }
                if j > i + 1 { return String(decoding: units[i..<j], as: UTF16.self) }
            }
            i -= 1
        }
        return nil
    }

    /// Ähnlichster bekannter Befehl (höchstens ein bzw. zwei Zeichen Unterschied, eindeutig).
    static func closestKnownCommand(to command: String) -> String? {
        guard command.count >= 3 else { return nil }
        let limit = command.count >= 7 ? 2 : 1
        var best: [(String, Int)] = []
        for candidate in knownCommands where abs(candidate.count - command.count) <= limit {
            let distance = editDistance(command, candidate)
            if distance <= limit { best.append((candidate, distance)) }
        }
        guard let minimum = best.map(\.1).min() else { return nil }
        let winners = best.filter { $0.1 == minimum }
        return winners.count == 1 ? winners[0].0 : nil
    }

    /// Abstand zweier Wörter: Einfügen, Löschen, Ersetzen und Vertauschen zweier
    /// Nachbarbuchstaben (`alpah` → `alpha`) kosten je 1.
    static func editDistance(_ a: String, _ b: String) -> Int {
        let a = Array(a), b = Array(b)
        guard !a.isEmpty else { return b.count }
        guard !b.isEmpty else { return a.count }
        var table = Array(repeating: Array(repeating: 0, count: b.count + 1), count: a.count + 1)
        for i in 0...a.count { table[i][0] = i }
        for j in 0...b.count { table[0][j] = j }
        for i in 1...a.count {
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                table[i][j] = min(table[i - 1][j] + 1, table[i][j - 1] + 1, table[i - 1][j - 1] + cost)
                if i > 1, j > 1, a[i - 1] == b[j - 2], a[i - 2] == b[j - 1] {
                    table[i][j] = min(table[i][j], table[i - 2][j - 2] + 1)
                }
            }
        }
        return table[a.count][b.count]
    }

    // MARK: Unbekannte Umgebung

    /// Umgebungen aus Paketen, die oft fehlen.
    static let packageForEnvironment: [String: String] = [
        "align": "amsmath", "align*": "amsmath", "gather": "amsmath", "gather*": "amsmath",
        "multline": "amsmath", "multline*": "amsmath", "equation*": "amsmath", "cases": "amsmath",
        "pmatrix": "amsmath", "bmatrix": "amsmath", "vmatrix": "amsmath", "Vmatrix": "amsmath",
        "Bmatrix": "amsmath", "matrix": "amsmath", "aligned": "amsmath", "split": "amsmath",
        "proof": "amsthm", "tabularx": "tabularx", "longtable": "longtable", "lstlisting": "listings",
        "spacing": "setspace", "onehalfspace": "setspace", "doublespace": "setspace", "singlespace": "setspace",
        "tikzpicture": "tikz", "minted": "minted", "subfigure": "subcaption", "wrapfigure": "wrapfig",
        "multicols": "multicol"
    ]

    static let knownEnvironments: [String] = Array(Set(
        Array(packageForEnvironment.keys) + Array(LaTeXTokenizer.mathEnvironments) + [
            "itemize", "enumerate", "description", "figure", "table", "tabular", "center", "flushleft", "flushright",
            "quote", "quotation", "verbatim", "minipage", "abstract", "document", "array", "thebibliography",
            "definition", "satz", "lemma", "korollar", "beispiel", "bemerkung"
        ]
    )).sorted()

    private static func undefinedEnvironment(_ name: String, line: Int?) -> IssueAdvice {
        if let snippet = SnippetCatalog.snippet(withID: "theorem.\(name)"), !snippet.requirements.isEmpty {
            return IssueAdvice(
                explanation: "Die Umgebung „\(name)“ ist nicht definiert.",
                suggestion: "Sätze, Definitionen & Co. müssen in der Präambel mit \\newtheorem angelegt werden – Lemma kann das übernehmen.",
                fix: snippet.requirements.first.map { .loadPackage($0) }
            )
        }
        if let package = packageForEnvironment[name] {
            return IssueAdvice(
                explanation: "Die Umgebung „\(name)“ gehört zum Paket „\(package)“, das noch nicht geladen ist.",
                suggestion: "Lade das Paket in der Präambel: \\usepackage{\(package)}.",
                fix: .loadPackage(PackageRequirement(package))
            )
        }
        let candidates = knownEnvironments.filter { abs($0.count - name.count) <= 2 }
        let scored = candidates.map { ($0, editDistance(name, $0)) }.filter { $0.1 <= (name.count >= 6 ? 2 : 1) }
        if let minimum = scored.map(\.1).min() {
            let winners = scored.filter { $0.1 == minimum }
            if winners.count == 1 {
                let guess = winners[0].0
                return IssueAdvice(
                    explanation: "Die Umgebung „\(name)“ gibt es nicht – wahrscheinlich ein Tippfehler.",
                    suggestion: "Meintest du „\(guess)“?",
                    fix: line.map { .renameEnvironment(line: $0, old: name, new: guess) }
                )
            }
        }
        return IssueAdvice(
            explanation: "Die Umgebung „\(name)“ ist nicht definiert.",
            suggestion: "Prüfe die Schreibweise oder lade das Paket, zu dem sie gehört."
        )
    }

    // MARK: - Behebung ausführen

    /// Berechnet die Änderung für eine Behebung. Pakete ergänzt der Aufrufer über
    /// `PreambleEditor.ensure` (siehe `requirements`). `nil`, wenn die Stelle nicht mehr passt.
    public static func edit<S: UTF16Source>(applying fix: QuickFix, in text: S) -> TextEdit? {
        switch fix {
        case .loadPackage(let requirement):
            return PreambleEditor.ensure([requirement], in: text)
        case .replace(let line, let old, let new):
            guard let range = LineIndex(text).range(ofLine: line),
                  let position = occurrence(of: old, in: text, range: range) else { return nil }
            let length = old.utf16.count
            let edit = TextEdit(
                range: position..<(position + length),
                replacement: new,
                selectionAfter: (position + new.utf16.count)..<(position + new.utf16.count)
            )
            return edit
        case .renameEnvironment(let line, let old, let new):
            guard let range = LineIndex(text).range(ofLine: line),
                  let begin = occurrence(of: "\\begin{\(old)}", in: text, range: range),
                  let block = BlockEditor.enclosingEnvironment(in: text, at: begin + 1, named: [old]) else { return nil }
            return BlockEditor.renameEnvironment(block, to: new, in: text, selection: begin..<begin)
        }
    }

    /// Erstes Vorkommen von `literal` in `range` – ein Befehlsname nur, wenn kein Buchstabe folgt,
    /// ein `&` nur, wenn es nicht schon `\&` ist.
    private static func occurrence<S: UTF16Source>(of literal: String, in text: S, range: Range<Int>) -> Int? {
        let units = Array(literal.utf16)
        guard !units.isEmpty, range.count >= units.count else { return nil }
        let endsWithLetter = units.last.map(TeXChar.isASCIILetter) ?? false
        var i = range.lowerBound
        while i + units.count <= range.upperBound {
            if text.matches(literal, at: i) {
                let next = text.unit(at: i + units.count)
                let letterFollows = endsWithLetter && literal.hasPrefix("\\") && next.map(TeXChar.isASCIILetter) == true
                let escaped = literal == "&" && text.isEscaped(at: i)
                if !letterFollows && !escaped { return i }
            }
            i += 1
        }
        return nil
    }

    private static func hasUnescapedAmpersand(_ line: String) -> Bool {
        let units = Array(line.utf16)
        return units.indices.contains { units[$0] == 0x26 && !units.isEscaped(at: $0) }
    }

    // MARK: - Hilfen

    private static func capture(_ text: String, _ pattern: String) -> String? {
        guard let expression = try? NSRegularExpression(pattern: pattern),
              let match = expression.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges > 1, let range = Range(match.range(at: 1), in: text) else { return nil }
        return String(text[range])
    }

    private static func captures(_ text: String, _ pattern: String) -> (String, String)? {
        guard let expression = try? NSRegularExpression(pattern: pattern),
              let match = expression.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges > 2,
              let first = Range(match.range(at: 1), in: text),
              let second = Range(match.range(at: 2), in: text) else { return nil }
        return (String(text[first]), String(text[second]))
    }
}
