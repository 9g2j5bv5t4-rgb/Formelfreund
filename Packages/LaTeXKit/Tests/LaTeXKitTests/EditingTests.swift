import Foundation
import Testing
@testable import LaTeXKit

/// Simuliert Tippen: `|` im Text markiert den Cursor.
private func type(_ character: String, into textWithCursor: String) -> String {
    let cursor = (textWithCursor as NSString).range(of: "|").location
    let text = textWithCursor.replacingOccurrences(of: "|", with: "")
    let units = Array(text.utf16)
    guard let edit = EditingAssistant.editForTyping(character, in: units, selection: cursor..<cursor) else {
        // Normales Tippen.
        let result = (text as NSString).replacingCharacters(in: NSRange(location: cursor, length: 0), with: character)
        return (result as NSString).replacingCharacters(in: NSRange(location: cursor + character.utf16.count, length: 0), with: "|")
    }
    return apply(edit, to: text)
}

private func apply(_ edit: TextEdit, to text: String) -> String {
    let replaced = (text as NSString).replacingCharacters(
        in: NSRange(location: edit.range.lowerBound, length: edit.range.count),
        with: edit.replacement
    )
    return (replaced as NSString).replacingCharacters(in: NSRange(location: edit.selectionAfter.lowerBound, length: 0), with: "|")
}

private func newline(in textWithCursor: String) -> String? {
    let cursor = (textWithCursor as NSString).range(of: "|").location
    let text = textWithCursor.replacingOccurrences(of: "|", with: "")
    guard let edit = EditingAssistant.editForNewline(in: Array(text.utf16), selection: cursor..<cursor) else { return nil }
    return apply(edit, to: text)
}

private func deleteBackward(in textWithCursor: String) -> String? {
    let cursor = (textWithCursor as NSString).range(of: "|").location
    let text = textWithCursor.replacingOccurrences(of: "|", with: "")
    guard let edit = EditingAssistant.editForDeleteBackward(in: Array(text.utf16), selection: cursor..<cursor) else { return nil }
    return apply(edit, to: text)
}

@Suite("Automatisches Schliessen")
struct AutoPairTests {
    @Test func braces() {
        #expect(type("{", into: "\\frac|") == "\\frac{|}")
        #expect(type("{", into: "|abc") == "{|abc")              // vor Wort: nur öffnen
        #expect(type("{", into: "\\|") == "\\{|\\}")              // \{ … \}
        #expect(type("}", into: "\\frac{1|}") == "\\frac{1}|")    // überschreiben
        #expect(type("}", into: "{a{b|}") == "{a{b}|}")           // fehlende Klammer: einfügen
    }

    @Test func dollar() {
        #expect(type("$", into: "Es gilt |") == "Es gilt $|$")
        #expect(type("$", into: "$x|$") == "$x$|")                 // überschreiben
        #expect(type("$", into: "$x + y|") == "$x + y$|")          // schliessen ohne Paar
        #expect(type("$", into: "Preis \\|") == "Preis \\$|")      // \$ ist kein Formelbeginn
        #expect(type("$", into: "Text |$a$") == "Text $|$$a$")     // neue Formel vor einer anderen
    }

    @Test func displayDollarSequence() {
        var text = "|"
        for character in ["$", "$", "x", "$", "$"] { text = type(character, into: text) }
        #expect(text == "$$x$$|")
    }

    @Test func displayBrackets() {
        #expect(type("[", into: "\\|") == "\\[|\\]")
        #expect(type("(", into: "\\|") == "\\(|\\)")
        #expect(type("[", into: "\\\\|") == "\\\\[|")              // \\[2mm] ist kein \[
        #expect(type("[", into: "|") == "[|")
    }

    @Test func beginEnd() {
        #expect(type("}", into: "\\begin{align|") == "\\begin{align}\n  |\n\\end{align}")
        #expect(type("}", into: "  \\begin{itemize|") == "  \\begin{itemize}\n    \\item |\n  \\end{itemize}")
        #expect(type("}", into: "\\begin{align*|}") == "\\begin{align*}\n  |\n\\end{align*}")
        // \end existiert schon: nichts ergänzen.
        #expect(type("}", into: "\\begin{align|\na\n\\end{align}") == "\\begin{align}|\na\n\\end{align}")
    }

    @Test func noPairingInComments() {
        #expect(type("{", into: "% Notiz |") == "% Notiz {|")
    }

    @Test func wrapSelection() {
        let text = "a b c"
        let edit = EditingAssistant.editForTyping("$", in: Array(text.utf16), selection: 2..<3)
        #expect(edit?.replacement == "$b$")
        #expect(edit?.selectionAfter == 3..<4)
    }
}

@Suite("Zeilenumbruch und Löschen")
struct NewlineTests {
    @Test func keepsIndentation() {
        #expect(newline(in: "    a = b|") == "    a = b\n    |")
        #expect(newline(in: "abc|") == nil)
    }

    @Test func continuesItems() {
        #expect(newline(in: "  \\item Erstens|") == "  \\item Erstens\n  \\item |")
        #expect(newline(in: "  \\item |") == "  |")
    }

    @Test func deletesEmptyPairs() {
        #expect(deleteBackward(in: "a{|}b") == "a|b")
        #expect(deleteBackward(in: "$|$") == "|")
        #expect(deleteBackward(in: "\\[|\\]") == "|")
        #expect(deleteBackward(in: "a{b|}") == nil)
    }
}

@Suite("Klammerpaare")
struct BracketTests {
    @Test func matchesBraces() {
        let text = Array("\\frac{a}{b{c}}".utf16)
        #expect(BracketMatcher.match(in: text, cursor: 14) == .init(open: 8, close: 13))
        #expect(BracketMatcher.match(in: text, cursor: 5) == .init(open: 5, close: 7))
    }

    @Test func ignoresEscapedAndComments() {
        let text = Array("{ \\} % }\n }".utf16)
        #expect(BracketMatcher.match(in: text, cursor: 0) == .init(open: 0, close: 10))
        #expect(BracketMatcher.match(in: text, cursor: 11) == .init(open: 0, close: 10))
    }

    @Test func worksOnNSString() {
        let text = NSStringSource("(a[b]c)" as NSString)
        #expect(BracketMatcher.match(in: text, cursor: 7) == .init(open: 0, close: 6))
    }
}

@Suite("Gliederung")
struct OutlineTests {
    @Test func sectionsFormulasImages() {
        let source = """
        \\section{Einleitung}\\label{sec:intro}
        Text $x$.
        \\subsection*{Details \\emph{wichtig}}
        % \\section{Auskommentiert}
        \\begin{align}
          a &= b
        \\end{align}
        \\centering\\includegraphics[width=5cm]{bilder/graph.pdf}
        \\[ \\int f \\]
        """
        let outline = DocumentOutline.parse(source)
        #expect(outline.sections.map(\.title) == ["Einleitung", "Details \\emph{wichtig}"])
        #expect(outline.sections.map(\.line) == [1, 3])
        #expect(outline.sections[1].kind == .section(level: 3))
        #expect(outline.formulas.map(\.title) == ["a &= b", "\\int f"])
        #expect(outline.formulas[0].detail == "align")
        #expect(outline.images.map(\.title) == ["bilder/graph.pdf"])
        #expect(outline.images[0].line == 8)
        #expect(outline.minimumSectionLevel == 2)
    }

    @Test func idsAreUniqueForDuplicates() {
        let outline = DocumentOutline.parse("\\section{A}\n\\section{A}")
        #expect(Set(outline.sections.map(\.id)).count == 2)
    }
}
