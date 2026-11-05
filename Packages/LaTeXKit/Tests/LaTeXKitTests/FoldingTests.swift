import Foundation
import Testing
@testable import LaTeXKit

private func regions(_ string: String) -> (text: [UInt16], regions: [FoldingRegion]) {
    let text = Array(string.utf16)
    let tokenized = LaTeXTokenizer.tokenize(text)
    let lines = LineIndex(text)
    let outline = DocumentOutline.parse(text, tokenized: tokenized, lines: lines)
    return (text, FoldingRegions.compute(in: text, tokenized: tokenized, lines: lines, outline: outline))
}

/// Text mit eingeklapptem Bereich: Das Ausgeblendete wird zu „⋯“.
private func folded(_ text: [UInt16], _ region: FoldingRegion) -> String {
    text.string(in: 0..<region.hiddenRange.lowerBound) + "⋯" + text.string(in: region.hiddenRange.upperBound..<text.count)
}

@Suite("Einklappen")
struct FoldingTests {
    let document = """
        \\documentclass{article}
        \\usepackage{amsmath}
        \\begin{document}
        \\section{Eins}
        Text
        \\begin{itemize}
          \\item a
          \\item b
        \\end{itemize}
        \\subsection{Eins A}
        Mehr

        \\section{Zwei}
        Ende
        \\end{document}
        """

    @Test func findsPreambleSectionsAndEnvironments() throws {
        let (text, found) = regions(document)
        let kinds = found.map(\.kind)
        #expect(kinds == [.preamble, .section(level: 2), .environment("itemize"), .section(level: 3), .section(level: 2)])
        #expect(found.map(\.line) == [1, 4, 6, 10, 13])

        let preamble = try #require(found.first)
        #expect(folded(text, preamble).hasPrefix("\\documentclass{article}⋯\n\\begin{document}"))

        let itemize = try #require(found.first { $0.kind == .environment("itemize") })
        #expect(folded(text, itemize).contains("\\begin{itemize}⋯\\end{itemize}\n\\subsection"))

        // \section{Eins} reicht bis vor \section{Zwei}, die Leerzeile davor wird mit ausgeblendet.
        let first = found[1]
        #expect(folded(text, first).contains("\\section{Eins}⋯\n\\section{Zwei}"))
        // Der letzte Abschnitt endet vor \end{document}.
        let last = try #require(found.last)
        #expect(folded(text, last).hasSuffix("\\section{Zwei}⋯\n\\end{document}"))
    }

    @Test func skipsShortEnvironmentsAndEmptySections() {
        let (_, found) = regions("\\section{A}\n\\section{B}\nx\n\\begin{center}\n\\end{center}")
        #expect(found.map(\.kind) == [.section(level: 2)])
        #expect(found.first?.line == 2)
    }

    @Test func lookupHelpers() throws {
        let (_, found) = regions(document)
        #expect(FoldingRegions.region(startingAt: 6, in: found)?.kind == .environment("itemize"))
        #expect(FoldingRegions.region(startingAt: 5, in: found) == nil)
        let inner = try #require(FoldingRegions.innermostRegion(containing: (document as NSString).range(of: "\\item a").location, line: 7, in: found))
        #expect(inner.kind == .environment("itemize"))
        #expect(FoldingRegions.outermost(found).map(\.kind) == [.preamble, .section(level: 2), .section(level: 2)])
    }
}
