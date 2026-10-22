import Foundation
import Testing
@testable import LaTeXKit

/// Hilfsfunktion: Text der Tokens einer Art.
private func texts(_ source: String, _ kind: TokenKind) -> [String] {
    let units = Array(source.utf16)
    return LaTeXTokenizer.tokenize(units).tokens
        .filter { $0.kind == kind }
        .map { String(decoding: units[$0.location..<$0.end], as: UTF16.self) }
}

@Suite("Syntax-Analyse")
struct TokenizerTests {
    @Test func commandsAndKeywords() {
        let source = "\\section{Hallo} Text \\textbf{fett} \\\\ neu"
        #expect(texts(source, .keyword) == ["\\section"])
        #expect(texts(source, .command) == ["\\textbf"])
        #expect(texts(source, .special) == ["\\\\"])
        #expect(texts(source, .brace).count == 4)
    }

    @Test func starredSection() {
        #expect(texts("\\section*{A}", .keyword) == ["\\section*"])
    }

    @Test func comments() {
        let source = "a % Kommentar \\foo\nb \\% kein Kommentar"
        #expect(texts(source, .comment) == ["% Kommentar \\foo"])
        #expect(texts(source, .command) == ["\\%"])
    }

    @Test func inlineMath() {
        let source = "Es gilt $a^2 + \\alpha$ und \\(x\\)."
        let result = LaTeXTokenizer.tokenize(source)
        #expect(result.mathRegions.count == 2)
        #expect(result.mathRegions.allSatisfy { $0.style == .inline && $0.isClosed })
        #expect(texts(source, .mathDelimiter) == ["$", "$", "\\(", "\\)"])
        #expect(texts(source, .mathCommand) == ["\\alpha"])
    }

    @Test func displayMathVariants() {
        let source = "\\[ x \\]\n$$ y $$\n\\begin{align*} a &= b \\end{align*}"
        let regions = LaTeXTokenizer.tokenize(source).mathRegions
        #expect(regions.count == 3)
        #expect(regions.allSatisfy { $0.style == .display && $0.isClosed })
        #expect(regions[2].environment == "align*")
        let units = Array(source.utf16)
        #expect(String(decoding: units[regions[2].contentRange], as: UTF16.self) == " a &= b ")
        #expect(texts(source, .environmentName) == ["align*", "align*"])
    }

    @Test func nestedEnvironmentInsideMath() {
        let source = "\\begin{equation} \\begin{pmatrix} 1 \\end{pmatrix} \\end{equation} Text"
        let regions = LaTeXTokenizer.tokenize(source).mathRegions
        #expect(regions.count == 1)
        #expect(regions[0].environment == "equation")
        #expect(regions[0].range.upperBound == (source as NSString).range(of: " Text").location)
    }

    @Test func unclosedInlineMathStopsAtParagraph() {
        let source = "Ein $Fehler\n\nNeuer Absatz \\textbf{x}"
        let result = LaTeXTokenizer.tokenize(source)
        #expect(result.mathRegions.count == 1)
        #expect(result.mathRegions[0].isClosed == false)
        // Nach der Leerzeile ist wieder Fliesstext.
        #expect(texts(source, .command) == ["\\textbf"])
    }

    @Test func escapedDollarIsNotMath() {
        let source = "Preis: 5 \\$ und $x$"
        #expect(LaTeXTokenizer.tokenize(source).mathRegions.count == 1)
    }

    @Test func verbatimIsSkipped() {
        let source = "\\begin{verbatim}\n$ \\foo %\n\\end{verbatim} \\bar"
        #expect(texts(source, .command) == ["\\bar"])
        #expect(LaTeXTokenizer.tokenize(source).mathRegions.isEmpty)
        #expect(texts("\\verb|$\\x$| \\y", .command) == ["\\verb", "\\y"])
    }

    @Test func mathRegionLookup() {
        let source = "a $x$ b \\[ y \\] c"
        let result = LaTeXTokenizer.tokenize(source)
        #expect(result.mathRegion(containing: 3)?.style == .inline)
        #expect(result.mathRegion(containing: 7) == nil)
        #expect(result.mathRegion(containing: 11)?.style == .display)
    }

    @Test func largeDocumentIsFast() {
        // ~30 Seiten: 1500 Absätze mit Text und Formeln.
        let paragraph = "Für alle $x \\in \\mathbb{R}$ gilt \\[ \\int_0^1 f(x)\\,dx = \\frac{1}{2} \\] % Kommentar\n\n"
        let source = String(repeating: paragraph, count: 1500)
        let units = Array(source.utf16)
        let clock = ContinuousClock()
        let duration = clock.measure { _ = LaTeXTokenizer.tokenize(units) }
        #expect(duration < .milliseconds(500))
    }
}

@Suite("Neu-Einfärben nach Änderungen")
struct HighlightDiffTests {
    @Test func typingPlainTextOnlyRepaintsEditedRange() {
        let old = LaTeXTokenizer.tokenize("\\a xy \\b").tokens
        let new = LaTeXTokenizer.tokenize("\\a xzy \\b").tokens
        let dirty = HighlightDiff.dirtyRange(old: old, new: new, lengthDelta: 1, edited: 4..<5, textLength: 9)
        #expect(dirty != nil)
        #expect(dirty!.contains(4))
        #expect(dirty!.lowerBound >= 2)
        #expect(dirty!.upperBound <= 7)
    }

    @Test func dollarChangesRestOfParagraph() {
        let oldText = "a b \\x c"
        let newText = "a $b \\x c"
        let old = LaTeXTokenizer.tokenize(oldText).tokens
        let new = LaTeXTokenizer.tokenize(newText).tokens
        let dirty = HighlightDiff.dirtyRange(old: old, new: new, lengthDelta: 1, edited: 2..<3, textLength: newText.utf16.count)
        #expect(dirty == 2..<newText.utf16.count)
    }

    @Test func noChangeNoRepaint() {
        let tokens = LaTeXTokenizer.tokenize("\\a b").tokens
        #expect(HighlightDiff.dirtyRange(old: tokens, new: tokens, lengthDelta: 0, edited: nil, textLength: 4) == nil)
    }

    @Test func unionOfEdits() {
        // Erst bei 10 ein Zeichen eingefügt, dann bei 2 eines.
        let first = HighlightDiff.union(previous: nil, editedRange: 10..<11, changeInLength: 1)
        let second = HighlightDiff.union(previous: first, editedRange: 2..<3, changeInLength: 1)
        #expect(second == 2..<12)
    }
}

@Suite("Zeilen")
struct LineIndexTests {
    @Test func lineLookup() {
        let index = LineIndex("a\nbc\n\nd")
        #expect(index.lineCount == 4)
        #expect(index.line(at: 0) == 1)
        #expect(index.line(at: 2) == 2)
        #expect(index.line(at: 4) == 2)
        #expect(index.line(at: 5) == 3)
        #expect(index.line(at: 6) == 4)
        #expect(index.range(ofLine: 2) == 2..<4)
        #expect(index.range(ofLine: 3) == 5..<5)
        #expect(index.range(ofLine: 5) == nil)
    }
}
