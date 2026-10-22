import Foundation

/// Ein Eintrag in der Seitenleiste: Abschnitt, Formel oder Bild.
public struct OutlineItem: Identifiable, Hashable, Sendable {
    public enum Kind: Hashable, Sendable {
        /// Gliederungsebene: 0 = \part, 1 = \chapter, 2 = \section, … 6 = \subparagraph
        case section(level: Int)
        case formula
        case image
    }

    /// Stabile ID aus Art, Titel und Vorkommen – bleibt beim Tippen an anderer Stelle gleich.
    public let id: String
    public var kind: Kind
    public var title: String
    /// Zusatzinfo, z. B. der Umgebungsname einer Formel (`align*`).
    public var detail: String?
    /// 1-basierte Zeile.
    public var line: Int
    /// UTF-16-Offset des Eintrags im Text.
    public var location: Int

    public init(id: String, kind: Kind, title: String, detail: String? = nil, line: Int, location: Int) {
        self.id = id
        self.kind = kind
        self.title = title
        self.detail = detail
        self.line = line
        self.location = location
    }
}

/// Die Struktur eines Dokuments für die Seitenleiste.
public struct DocumentOutline: Equatable, Sendable {
    public var sections: [OutlineItem]
    public var formulas: [OutlineItem]
    public var images: [OutlineItem]

    public init(sections: [OutlineItem] = [], formulas: [OutlineItem] = [], images: [OutlineItem] = []) {
        self.sections = sections
        self.formulas = formulas
        self.images = images
    }

    public static let empty = DocumentOutline()

    public var isEmpty: Bool { sections.isEmpty && formulas.isEmpty && images.isEmpty }

    /// Kleinste vorkommende Gliederungsebene – für die Einrückung in der Seitenleiste.
    public var minimumSectionLevel: Int {
        sections.compactMap { item -> Int? in
            if case .section(let level) = item.kind { return level }
            return nil
        }.min() ?? 2
    }

    /// Liest die Struktur aus dem bereits analysierten Text.
    public static func parse(_ text: [UInt16], tokenized: TokenizedText, lines: LineIndex) -> DocumentOutline {
        var outline = DocumentOutline()
        var idCounter = IDCounter()

        for token in tokenized.tokens where token.kind == .keyword || token.kind == .command {
            // Ein Token kann mehrere direkt aufeinanderfolgende Befehle enthalten.
            var p = token.location
            while p < token.end {
                guard text[p] == TeXChar.backslash else { p += 1; continue }
                var q = p + 1
                while q < text.count && TeXChar.isASCIILetter(text[q]) { q += 1 }
                let name = String(decoding: text[(p + 1)..<q], as: UTF16.self)
                if let level = LaTeXTokenizer.sectioningLevels[name] {
                    if let title = readArgument(text, after: q) {
                        let cleaned = cleanTitle(title)
                        outline.sections.append(OutlineItem(
                            id: idCounter.next("section", cleaned),
                            kind: .section(level: level),
                            title: cleaned.isEmpty ? "Ohne Titel" : cleaned,
                            line: lines.line(at: p),
                            location: p
                        ))
                    }
                } else if name == "includegraphics" {
                    if let path = readArgument(text, after: q) {
                        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
                        outline.images.append(OutlineItem(
                            id: idCounter.next("image", trimmed),
                            kind: .image,
                            title: trimmed,
                            line: lines.line(at: p),
                            location: p
                        ))
                    }
                }
                p = max(q, p + 1)
            }
        }

        for region in tokenized.mathRegions where region.style == .display {
            let content = String(decoding: text[region.contentRange], as: UTF16.self)
            let collapsed = collapseWhitespace(content)
            let title = collapsed.count > 80 ? String(collapsed.prefix(79)) + "…" : collapsed
            outline.formulas.append(OutlineItem(
                id: idCounter.next("formula", collapsed),
                kind: .formula,
                title: title.isEmpty ? "Leere Formel" : title,
                detail: region.environment,
                line: lines.line(at: region.range.lowerBound),
                location: region.range.lowerBound
            ))
        }
        return outline
    }

    public static func parse(_ string: String) -> DocumentOutline {
        let units = Array(string.utf16)
        return parse(units, tokenized: LaTeXTokenizer.tokenize(units), lines: LineIndex(units))
    }

    // MARK: - Hilfsfunktionen

    /// Liest das Pflichtargument `{…}` nach einem Befehl; überspringt `*` und `[…]`.
    static func readArgument(_ text: [UInt16], after index: Int) -> String? {
        var i = index
        let n = text.count
        func skipSpaces() { while i < n && (text[i] == TeXChar.space || text[i] == TeXChar.tab) { i += 1 } }
        if i < n && text[i] == TeXChar.star { i += 1 }
        skipSpaces()
        if i < n && text[i] == TeXChar.bracketOpen {
            var depth = 0
            while i < n {
                if text[i] == TeXChar.bracketOpen { depth += 1 }
                if text[i] == TeXChar.bracketClose { depth -= 1; if depth == 0 { i += 1; break } }
                i += 1
            }
            skipSpaces()
        }
        guard i < n, text[i] == TeXChar.braceOpen else { return nil }
        let start = i + 1
        var depth = 0
        var j = i
        let limit = min(n, i + 500)
        while j < limit {
            let u = text[j]
            if u == TeXChar.braceOpen && !text.isEscaped(at: j) { depth += 1 }
            if u == TeXChar.braceClose && !text.isEscaped(at: j) {
                depth -= 1
                if depth == 0 { return String(decoding: text[start..<j], as: UTF16.self) }
            }
            j += 1
        }
        return nil
    }

    /// Entfernt `\label{…}` und überflüssige Leerzeichen aus einem Titel.
    static func cleanTitle(_ title: String) -> String {
        var result = title
        while let range = result.range(of: "\\label{") {
            if let close = result[range.upperBound...].firstIndex(of: "}") {
                result.removeSubrange(range.lowerBound...close)
            } else {
                break
            }
        }
        result = result.replacingOccurrences(of: "\\\\", with: " ")
        return collapseWhitespace(result)
    }

    static func collapseWhitespace(_ string: String) -> String {
        string.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }

    /// Erzeugt IDs wie `section:Einleitung#0`, eindeutig auch bei gleichen Titeln.
    struct IDCounter {
        var seen: [String: Int] = [:]
        mutating func next(_ kind: String, _ title: String) -> String {
            let key = kind + ":" + title
            let count = seen[key, default: 0]
            seen[key] = count + 1
            return key + "#\(count)"
        }
    }
}
