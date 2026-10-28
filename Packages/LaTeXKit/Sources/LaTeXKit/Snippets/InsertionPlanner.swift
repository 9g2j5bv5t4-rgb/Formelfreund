import Foundation

/// Sucht für einen Baustein die nächste Stelle, an der er Sinn ergibt.
///
/// Beispiele: Steht der Cursor in der Präambel, kommt eine Matrix an den
/// Anfang des Textteils (nach `\begin{document}`). Steht er mitten in einer
/// Formel, kommt eine abgesetzte Formel direkt hinter diese Formel, und eine
/// Überschrift landet nie in einer Aufzählung, sondern dahinter.
///
/// Ist Text ausgewählt, bleibt die Auswahl, wo sie ist (der Nutzer will sie
/// gezielt einpacken) – ausser sie liegt ausserhalb des Textteils.
public enum InsertionPlanner {
    public struct Plan: Equatable, Sendable {
        /// Wo eingefügt wird (bei einer Verschiebung ein Cursor ohne Auswahl).
        public var selection: Range<Int>
        /// Kurze Erklärung, falls der Baustein woanders als am Cursor landet.
        public var note: String?

        public init(selection: Range<Int>, note: String? = nil) {
            self.selection = selection
            self.note = note
        }
    }

    /// Welche Art Baustein – bestimmt, wo er stehen darf.
    enum Kind {
        /// Im Fliesstext an der Cursorposition (`\frac{•}{•}`, Fussnote …).
        case inline
        /// Erzeugt selbst eine Formel im Text (`$…$`) – nicht in einer Formel.
        case inlineFormula
        /// Abgesetzte Formel, Liste, Satz, Zitat … auf eigenen Zeilen.
        case block
        /// Gleitumgebung (`figure`, `table`) – nicht in Tabellen, Minipages oder anderen Gleitumgebungen.
        case float
        /// Überschrift, Inhaltsverzeichnis, Anhang – nie in einer Umgebung.
        case heading
    }

    /// Umgebungen mit Zellen oder Zeichnungen: Blöcke gehören dahinter.
    static let cellEnvironments: Set<String> = [
        "tabular", "tabular*", "tabularx", "tabulary", "longtable", "array", "tikzpicture",
        "matrix", "pmatrix", "bmatrix", "vmatrix", "Vmatrix", "Bmatrix", "cases"
    ]
    /// Gleitumgebungen und Kästen, in denen keine weitere Gleitumgebung stehen darf.
    static let floatContainers: Set<String> = [
        "figure", "figure*", "table", "table*", "minipage", "wrapfigure", "subfigure"
    ]

    public static func plan<S: UTF16Source>(
        for snippet: Snippet,
        in text: S,
        selection: Range<Int>,
        analysis: TokenizedText? = nil
    ) -> Plan {
        let lower = min(max(0, selection.lowerBound), text.count)
        let upper = min(max(lower, selection.upperBound), text.count)
        let kind = kind(of: snippet)

        // 1. Nur im Textteil zwischen \begin{document} und \end{document}.
        if let body = bodyRange(in: text) {
            if lower < body.lowerBound {
                return adjusted(Plan(selection: body.lowerBound..<body.lowerBound, note: "Am Anfang des Textteils eingefügt – in der Präambel stehen nur Einstellungen."), kind: kind, text: text, analysis: analysis)
            }
            if upper > body.upperBound {
                return adjusted(Plan(selection: body.upperBound..<body.upperBound, note: "Vor \\end{document} eingefügt – danach liest LaTeX nichts mehr."), kind: kind, text: text, analysis: analysis)
            }
        }
        // 2. Eine Auswahl wird gezielt eingepackt und bleibt, wo sie ist.
        guard lower == upper else { return Plan(selection: lower..<upper) }
        return adjusted(Plan(selection: lower..<upper), kind: kind, text: text, analysis: analysis)
    }

    /// Schiebt einen Cursor so lange hinter umgebende Formeln bzw. Umgebungen,
    /// bis der Baustein dort erlaubt ist.
    private static func adjusted<S: UTF16Source>(_ plan: Plan, kind: Kind, text: S, analysis: TokenizedText?) -> Plan {
        var position = plan.selection.lowerBound
        var note = plan.note
        let analysis = analysis ?? LaTeXTokenizer.tokenize(units(of: text))
        for _ in 0..<32 {
            if kind != .inline, analysis.isInsideMath(at: position), let region = analysis.mathRegion(containing: position) {
                position = region.range.upperBound
                note = "Hinter der Formel eingefügt – dieser Baustein gehört nicht in eine Formel."
                continue
            }
            if let block = BlockEditor.enclosingEnvironment(in: text, at: position, named: forbiddenContainers(for: kind)),
               block.range.upperBound > position {
                position = block.range.upperBound
                note = "Hinter „\(BlockEditor.displayName(for: block.name))“ eingefügt – dort drin wäre der Baustein nicht erlaubt."
                continue
            }
            break
        }
        return Plan(selection: position..<position, note: position == plan.selection.lowerBound ? plan.note : note)
    }

    /// Umgebungen, in denen dieser Baustein nicht stehen darf (`nil` = keine einzige).
    private static func forbiddenContainers(for kind: Kind) -> Set<String>? {
        let verbatim = LaTeXTokenizer.verbatimEnvironments
        switch kind {
        case .inline, .inlineFormula:
            return verbatim
        case .block:
            return verbatim.union(cellEnvironments)
        case .float:
            return verbatim.union(cellEnvironments).union(floatContainers)
        case .heading:
            // Jede Umgebung ausser `document` (die liefert enclosingEnvironment nie).
            return nil
        }
    }

    static func kind(of snippet: Snippet) -> Kind {
        let body = snippet.body.trimmingCharacters(in: .whitespacesAndNewlines)
        if snippet.placement == .inline {
            return body.hasPrefix("$") || body.hasPrefix("\\(") ? .inlineFormula : .inline
        }
        if body.hasPrefix("\\begin{figure") || body.hasPrefix("\\begin{table") {
            return .float
        }
        let headingCommands = ["\\part", "\\chapter", "\\section", "\\subsection", "\\subsubsection", "\\paragraph", "\\tableofcontents", "\\appendix", "\\maketitle", "\\title"]
        if snippet.category == .headings, headingCommands.contains(where: { body.hasPrefix($0) }) {
            return .heading
        }
        return .block
    }

    /// Bereich des Textteils: vom Anfang der Zeile nach `\begin{document}` bis zum
    /// Anfang der Zeile mit `\end{document}`. `nil` ohne `\begin{document}`
    /// (z. B. ein Kapitel, das per `\input` eingebunden wird).
    public static func bodyRange<S: UTF16Source>(in text: S) -> Range<Int>? {
        guard let begin = PreambleEditor.preambleEnd(in: text),
              let token = BlockEditor.environmentToken(in: text, at: begin) else { return nil }
        let lineEnd = text.lineEnd(after: token.range.upperBound)
        let restIsBlank = (token.range.upperBound..<lineEnd).allSatisfy { TeXChar.isWhitespace(text[$0]) }
        let start = restIsBlank ? min(lineEnd + 1, text.count) : token.range.upperBound
        guard let end = BlockEditor.findEnd(of: "document", in: text, from: token.range.upperBound) else {
            return start..<text.count
        }
        let endLineStart = text.lineStart(before: end.lowerBound)
        let onlySpaceBefore = (endLineStart..<end.lowerBound).allSatisfy { TeXChar.isWhitespace(text[$0]) }
        let stop = onlySpaceBefore ? endLineStart : end.lowerBound
        return start..<max(start, stop)
    }

    private static func units<S: UTF16Source>(of text: S) -> [UInt16] {
        (0..<text.count).map { text[$0] }
    }
}
