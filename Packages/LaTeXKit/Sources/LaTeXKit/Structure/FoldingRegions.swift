import Foundation

/// Ein Bereich, den man im Editor einklappen kann – ein Abschnitt, eine
/// mehrzeilige Umgebung oder die Präambel.
public struct FoldingRegion: Equatable, Sendable, Identifiable {
    public enum Kind: Equatable, Sendable {
        case preamble
        /// Gliederungsebene wie in `OutlineItem` (2 = `\section`).
        case section(level: Int)
        case environment(String)
    }

    public var kind: Kind
    /// 1-basierte Zeile, in der der Bereich beginnt – dort steht das Dreieck.
    public var line: Int
    /// Was beim Einklappen verschwindet: vom Ende der ersten Zeile bis vor die
    /// nächste Überschrift bzw. bis vor `\end{…}`. Das erste Zeichen ist immer
    /// der Zeilenumbruch der ersten Zeile.
    public var hiddenRange: Range<Int>

    public var id: Int { hiddenRange.lowerBound }

    public init(kind: Kind, line: Int, hiddenRange: Range<Int>) {
        self.kind = kind
        self.line = line
        self.hiddenRange = hiddenRange
    }
}

public enum FoldingRegions {
    /// Alle einklappbaren Bereiche, sortiert nach Beginn (äussere vor inneren).
    public static func compute<S: UTF16Source>(
        in text: S,
        tokenized: TokenizedText,
        lines: LineIndex,
        outline: DocumentOutline
    ) -> [FoldingRegion] {
        var regions: [FoldingRegion] = []
        let count = text.count
        guard count > 0 else { return [] }

        // Umgebungen und Präambel aus den Tokens.
        var stack: [(name: String, nameEnd: Int)] = []
        var documentClass: Int?
        var beginDocument: Int?
        var endDocument: Int?
        let tokens = tokenized.tokens
        for index in tokens.indices {
            let token = tokens[index]
            if token.kind == .keyword, documentClass == nil, text.matches("\\documentclass", at: token.location) {
                documentClass = token.location
            }
            guard token.kind == .environmentName, index >= 2, tokens[index - 2].kind == .keyword else { continue }
            let keyword = tokens[index - 2]
            let name = text.string(in: token.range)
            if text.matches("\\begin", at: keyword.location) {
                if name == "document" {
                    if beginDocument == nil { beginDocument = keyword.location }
                } else {
                    stack.append((name, token.end))
                }
            } else if text.matches("\\end", at: keyword.location) {
                if name == "document" {
                    endDocument = keyword.location
                    continue
                }
                guard let open = stack.lastIndex(where: { $0.name == name }) else { continue }
                let begin = stack[open]
                stack.removeSubrange(open...)
                let start = text.lineEnd(after: begin.nameEnd)
                let end = keyword.location
                // Mindestens eine Zeile zwischen \begin und \end.
                guard start < end, lines.line(at: end) >= lines.line(at: start) + 2 else { continue }
                regions.append(FoldingRegion(kind: .environment(name), line: lines.line(at: start), hiddenRange: start..<end))
            }
        }

        if let documentClass, let beginDocument {
            let start = text.lineEnd(after: documentClass)
            let end = text.lineStart(before: beginDocument) - 1
            if start < end {
                regions.append(FoldingRegion(kind: .preamble, line: lines.line(at: start), hiddenRange: start..<end))
            }
        }

        // Abschnitte: bis vor die nächste Überschrift gleicher oder höherer Ebene.
        let sections = outline.sections.compactMap { item -> (level: Int, location: Int)? in
            if case .section(let level) = item.kind { return (level, item.location) }
            return nil
        }
        let documentEnd = endDocument.map { text.lineStart(before: $0) } ?? count
        for (index, section) in sections.enumerated() {
            let start = text.lineEnd(after: section.location)
            var next = documentEnd
            for later in sections[(index + 1)...] where later.level <= section.level {
                next = text.lineStart(before: later.location)
                break
            }
            // Der Zeilenumbruch vor der nächsten Überschrift bleibt sichtbar.
            var end = next
            if end > 0, end <= count, end > start, text[end - 1] == TeXChar.newline { end -= 1 }
            guard start < end, start < count, lines.line(at: end) > lines.line(at: start) || end == count else { continue }
            guard text.string(in: start..<end).contains(where: { !$0.isWhitespace }) else { continue }
            regions.append(FoldingRegion(kind: .section(level: section.level), line: lines.line(at: start), hiddenRange: start..<end))
        }

        regions.sort { a, b in
            if a.hiddenRange.lowerBound != b.hiddenRange.lowerBound {
                return a.hiddenRange.lowerBound < b.hiddenRange.lowerBound
            }
            return a.hiddenRange.count > b.hiddenRange.count
        }
        return regions
    }

    /// Bereich, der in Zeile `line` beginnt (bei mehreren der grösste).
    public static func region(startingAt line: Int, in regions: [FoldingRegion]) -> FoldingRegion? {
        regions.filter { $0.line == line }.max { $0.hiddenRange.count < $1.hiddenRange.count }
    }

    /// Innerster Bereich, der die Position enthält oder in ihrer Zeile beginnt.
    public static func innermostRegion(containing position: Int, line: Int, in regions: [FoldingRegion]) -> FoldingRegion? {
        if let starting = regions.filter({ $0.line == line }).min(by: { $0.hiddenRange.count < $1.hiddenRange.count }) {
            return starting
        }
        return regions
            .filter { $0.hiddenRange.lowerBound < position && position < $0.hiddenRange.upperBound }
            .min { $0.hiddenRange.count < $1.hiddenRange.count }
    }

    /// Bereiche, die in keinem anderen liegen – für „Alle einklappen“.
    public static func outermost(_ regions: [FoldingRegion]) -> [FoldingRegion] {
        var result: [FoldingRegion] = []
        for region in regions {
            if let last = result.last,
               last.hiddenRange.lowerBound <= region.hiddenRange.lowerBound,
               region.hiddenRange.upperBound <= last.hiddenRange.upperBound {
                continue
            }
            result.append(region)
        }
        return result
    }
}
