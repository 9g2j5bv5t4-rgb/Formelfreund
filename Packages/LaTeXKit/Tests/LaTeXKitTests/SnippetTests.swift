import Foundation
import Testing
@testable import LaTeXKit

// Schreibweise in diesen Tests:
// `|` markiert den Cursor, `«…»` eine Auswahl – im Text vorher wie nachher.

/// Zerlegt einen markierten Text in reinen Text und Auswahl (UTF-16-Offsets).
private func parseMarked(_ marked: String) -> (text: String, selection: Range<Int>) {
    let string = marked as NSString
    let open = string.range(of: "«")
    if open.location != NSNotFound {
        let close = string.range(of: "»")
        let text = marked.replacingOccurrences(of: "«", with: "").replacingOccurrences(of: "»", with: "")
        return (text, open.location..<(close.location - 1))
    }
    let cursor = string.range(of: "|").location
    return (marked.replacingOccurrences(of: "|", with: ""), cursor..<cursor)
}

/// Setzt die Markierungen für eine Auswahl in einen Text.
private func marking(_ selection: Range<Int>, in text: String) -> String {
    let string = text as NSString
    if selection.isEmpty {
        return string.replacingCharacters(in: NSRange(location: selection.lowerBound, length: 0), with: "|")
    }
    let closed = string.replacingCharacters(in: NSRange(location: selection.upperBound, length: 0), with: "»") as NSString
    return closed.replacingCharacters(in: NSRange(location: selection.lowerBound, length: 0), with: "«")
}

/// Führt eine Bearbeitung aus und liefert den neuen Text (ohne Markierungen).
private func applying(_ edit: TextEdit, to text: String) -> String {
    (text as NSString).replacingCharacters(
        in: NSRange(location: edit.range.lowerBound, length: edit.range.count),
        with: edit.replacement
    )
}

/// Fügt einen Baustein ein und liefert das Ergebnis mit Markierungen.
private func inserting(_ snippet: Snippet, into marked: String, inMath: Bool = false) -> String {
    let (text, selection) = parseMarked(marked)
    let edit = SnippetInserter.edit(inserting: snippet, in: Array(text.utf16), selection: selection, inMath: inMath)
    return marking(edit.selectionAfter, in: applying(edit, to: text))
}

/// Wie oben, aber mit einem Baustein aus dem Katalog.
private func inserting(_ id: String, into marked: String, inMath: Bool = false) -> String {
    guard let snippet = SnippetCatalog.snippet(withID: id) else {
        Issue.record("Baustein \(id) fehlt im Katalog")
        return ""
    }
    return inserting(snippet, into: marked, inMath: inMath)
}

/// Tab (bzw. ⇧Tab): springt zum nächsten (vorherigen) Platzhalter.
private func tab(_ marked: String, backwards: Bool = false) -> String? {
    let (text, selection) = parseMarked(marked)
    let units = Array(text.utf16)
    let found = backwards
        ? Placeholders.previous(in: units, before: selection.lowerBound)
        : Placeholders.next(in: units, from: selection.upperBound)
    return found.map { marking($0, in: text) }
}

// MARK: - Katalog

@Suite("Bausteine: Katalog")
struct SnippetCatalogTests {
    let all = SnippetCatalog.all

    @Test func idsAndTitlesAreUnique() {
        #expect(Set(all.map(\.id)).count == all.count)
        #expect(Set(all.map(\.title)).count == all.count)
    }

    @Test func everyCategoryHasSnippetsInMenuOrder() {
        for category in SnippetCategory.allCases {
            #expect(!SnippetCatalog.snippets(in: category).isEmpty, "Gruppe \(category) ist leer")
        }
        // Die Gruppen stehen zusammenhängend in der Reihenfolge von `SnippetCategory`.
        var seen: [SnippetCategory] = []
        for snippet in all where seen.last != snippet.category {
            seen.append(snippet.category)
        }
        #expect(seen == SnippetCategory.allCases)
    }

    @Test func lookupByIDAndCategory() {
        #expect(SnippetCatalog.snippet(withID: "formula.fraction")?.title == "Bruch")
        #expect(SnippetCatalog.snippet(withID: "gibt-es-nicht") == nil)
        #expect(SnippetCatalog.snippets(in: .tables).map(\.title) == ["Tabelle 2×2", "Tabelle 3×3"])
        #expect(SnippetCatalog.snippets(in: .lists).map(\.id) == ["list.itemize", "list.enumerate", "list.description"])
        #expect(SnippetCatalog.all == all)
    }

    @Test func everySnippetIsDocumentedForBeginners() {
        for snippet in all {
            #expect(!snippet.title.isEmpty)
            #expect(snippet.help.count > 15, "Hilfetext fehlt: \(snippet.id)")
            #expect(snippet.keywords.count >= 2, "Suchbegriffe fehlen: \(snippet.id)")
            #expect(snippet.keywords.allSatisfy { $0 == $0.lowercased() && !$0.isEmpty }, "\(snippet.id)")
            #expect(Set(snippet.keywords).count == snippet.keywords.count, "Doppelte Suchbegriffe: \(snippet.id)")
            if let symbol = snippet.symbol { #expect(!symbol.isEmpty) }
        }
    }

    /// Schweizer Rechtschreibung: „ss“ statt Eszett.
    @Test func swissSpellingWithoutSharpS() {
        for snippet in all {
            let texts = [snippet.title, snippet.help] + snippet.keywords
            #expect(texts.allSatisfy { !$0.contains("\u{00DF}") }, "Eszett in \(snippet.id)")
        }
    }

    @Test func placementAndMathMode() {
        for snippet in all {
            if snippet.category == .formulas {
                #expect(snippet.placement == .inline, "\(snippet.id)")
                #expect(snippet.requiresMath, "\(snippet.id)")
            } else {
                #expect(!snippet.requiresMath, "\(snippet.id)")
            }
            let blockCategories: [SnippetCategory] = [.headings, .lists, .formulaBlocks, .theorems, .figures, .tables, .document]
            if blockCategories.contains(snippet.category) {
                #expect(snippet.placement == .block, "\(snippet.id)")
            }
        }
        let inlineText = SnippetCatalog.snippets(in: .text).filter { $0.placement == .inline }.map(\.id)
        #expect(inlineText == ["text.footnote", "text.label", "text.ref", "text.eqref", "text.link", "text.lineBreak"])
    }

    @Test func bodiesAreWellFormed() {
        for snippet in all {
            let body = snippet.body
            // Höchstens eine Stelle für die Auswahl.
            #expect(body.components(separatedBy: Snippet.selectionToken).count <= 2, "\(snippet.id)")
            // Geschweifte Klammern (ohne \{ und \}) sind ausgeglichen.
            let units = Array(body.utf16)
            var depth = 0
            for (index, unit) in units.enumerated() where !units.isEscaped(at: index) {
                if unit == TeXChar.braceOpen { depth += 1 }
                if unit == TeXChar.braceClose { depth -= 1 }
                #expect(depth >= 0, "\(snippet.id)")
            }
            #expect(depth == 0, "\(snippet.id)")
            // Zu jedem \begin{x} gibt es ein \end{x}.
            for name in environmentNames(in: body) {
                #expect(body.components(separatedBy: "\\begin{\(name)}").count
                    == body.components(separatedBy: "\\end{\(name)}").count, "\(snippet.id): \(name)")
            }
            // Einrückung in Zweierschritten, nur Leerzeichen, nichts am Zeilenende.
            for line in body.components(separatedBy: "\n") {
                let indent = line.prefix { $0 == " " || $0 == "\t" }
                #expect(!indent.contains("\t") && indent.count % 2 == 0, "\(snippet.id): \(line)")
                #expect(line.last != " ", "\(snippet.id): Leerzeichen am Zeilenende")
            }
        }
    }

    @Test func requirementsMatchTheCommands() {
        for snippet in all {
            let names = snippet.requirements.map(\.name)
            let needsAmsmath = ["\\binom", "\\text{", "\\lVert", "\\eqref", "{align", "{cases}", "{pmatrix}"]
                .contains { snippet.body.contains($0) }
            if needsAmsmath { #expect(names.contains("amsmath"), "\(snippet.id)") }
            if snippet.body.contains("\\mathbb") { #expect(names.contains("amssymb"), "\(snippet.id)") }
            if snippet.body.contains("\\includegraphics") { #expect(names == ["graphicx"], "\(snippet.id)") }
            if snippet.body.contains("\\href") { #expect(names == ["hyperref"], "\(snippet.id)") }
        }
    }

    @Test func theoremEnvironmentsAreDeclaredInThePreamble() {
        let theorems = SnippetCatalog.snippets(in: .theorems)
        #expect(theorems.map(\.title) == ["Definition", "Satz", "Lemma", "Korollar", "Beispiel", "Bemerkung", "Beweis"])
        let declarations = PackageRequirement.theorems.preambleLines.joined(separator: "\n")
        for snippet in theorems {
            guard let name = environmentNames(in: snippet.body).first else {
                Issue.record("Keine Umgebung in \(snippet.id)")
                continue
            }
            #expect(snippet.body == "\\begin{\(name)}\n  ⟦⟧\n\\end{\(name)}")
            if name == "proof" {
                // „Beweis“ bringt amsthm selbst mit, ohne \newtheorem.
                #expect(snippet.requirements == [PackageRequirement("amsthm")])
            } else {
                #expect(snippet.requirements == [.theorems], "\(snippet.id)")
                #expect(declarations.contains("{\(name)}"), "\(name) ist in der Präambel nicht festgelegt")
            }
        }
    }

    @Test func selectedBodies() {
        func body(_ id: String) -> String? { SnippetCatalog.snippet(withID: id)?.body }
        #expect(body("heading.section") == "\\section{⟦⟧}")
        #expect(body("heading.sectionUnnumbered") == "\\section*{⟦⟧}")
        #expect(body("heading.title") == "\\title{•}\n\\author{•}\n\\date{\\today}\n\\maketitle")
        #expect(body("text.lineBreak") == "\\\\")
        #expect(body("text.link") == "\\href{•}{⟦⟧}")
        #expect(body("formula.integral") == "\\int_{•}^{•} • \\,\\mathrm{d}•")
        #expect(body("formula.set") == "\\{ • \\mid • \\}")
        #expect(body("display.unnumbered") == "\\[\n  ⟦⟧\n\\]")
        #expect(body("display.alignUnnumbered") == "\\begin{align*}\n  ⟦⟧ &= • \\\\\n  &= •\n\\end{align*}")
        #expect(body("list.itemize") == "\\begin{itemize}\n  \\item ⟦⟧\n  \\item •\n\\end{itemize}")
        #expect(body("figure.includegraphics") == "\\includegraphics[width=0.5\\textwidth]{•}")
        #expect(body("document.exercise") == "\\section*{Aufgabe •}\n⟦⟧")
        #expect(body("document.comment") == "% •")
    }

    /// Namen aller `\begin{…}` im Text.
    private func environmentNames(in body: String) -> [String] {
        body.components(separatedBy: "\\begin{").dropFirst().compactMap { $0.components(separatedBy: "}").first }
    }
}

// MARK: - Platzhalter

@Suite("Bausteine: Platzhalter")
struct SnippetPlaceholderTests {
    @Test func nextPlaceholder() {
        #expect(tab("|\\frac{•}{•}") == "\\frac{«•»}{•}")
        #expect(tab("\\frac{«•»}{•}") == "\\frac{•}{«•»}")
        #expect(tab("\\frac{•}{«•»}") == nil)
        #expect(tab("a|•") == "a«•»")                       // einschliesslich der Position
        #expect(tab("\\begin{align*}\n  x| &= • \\\\\n  &= •\n\\end{align*}")
            == "\\begin{align*}\n  x &= «•» \\\\\n  &= •\n\\end{align*}")
    }

    @Test func nextStaysInsideTheParagraph() {
        #expect(tab("a|\nb\n•") == "a\nb\n«•»")             // einfache Zeilenumbrüche zählen nicht
        #expect(tab("a|\n\n•") == nil)                      // Leerzeile ist die Grenze
        #expect(tab("a|\n  \t\n•") == nil)                  // auch mit Leerraum
        #expect(tab("•\n|\n•") == nil)                      // auf einer Leerzeile: kein Absatz
        #expect(tab("x|\n\n") == nil)
    }

    @Test func previousPlaceholder() {
        #expect(tab("\\frac{•}{«•»}", backwards: true) == "\\frac{«•»}{•}")
        #expect(tab("•{•}|", backwards: true) == "•{«•»}")
        #expect(tab("a|•", backwards: true) == nil)        // ausschliesslich der Position
        #expect(tab("«•»{•}", backwards: true) == nil)
        #expect(tab("•\nx|", backwards: true) == "«•»\nx")
        #expect(tab("•\n\n|a", backwards: true) == nil)
        #expect(tab("•\n \n•a|", backwards: true) == "•\n \n«•»a")
    }

    @Test func textBoundaries() {
        let empty: [UInt16] = []
        #expect(Placeholders.next(in: empty, from: 0) == nil)
        #expect(Placeholders.previous(in: empty, before: 0) == nil)
        #expect(Placeholders.lines(in: empty) == [])
        let units = Array("•a•".utf16)
        #expect(Placeholders.next(in: units, from: -4) == 0..<1)
        #expect(Placeholders.next(in: units, from: 3) == nil)
        #expect(Placeholders.next(in: units, from: 99) == nil)
        #expect(Placeholders.previous(in: units, before: 99) == 2..<3)
        #expect(Placeholders.previous(in: units, before: -1) == nil)
        #expect(tab("•|") == nil)
        #expect(tab("|•") == "«•»")
    }

    @Test func offsetsAreUTF16() {
        #expect(tab("äöü|•") == "äöü«•»")
        #expect(Placeholders.next(in: Array("😀•".utf16), from: 0) == 2..<3)
        #expect(Placeholders.previous(in: Array("•😀".utf16), before: 3) == 0..<1)
        #expect(Placeholders.marker.utf16.first == Placeholders.unit)
    }

    @Test func tabAlsoReachesPlaceholdersInComments() {
        // Die Kommentar-Notiz „% •“ soll sich ebenfalls ausfüllen lassen.
        #expect(tab("|% •") == "% «•»")
    }

    @Test func linesWithPlaceholders() {
        #expect(Placeholders.lines(in: Array("•".utf16)) == [1])
        #expect(Placeholders.lines(in: Array("a\n•\n\nb • •\n% •\nx \\% •".utf16)) == [2, 4, 6])
        #expect(Placeholders.lines(in: Array("a % •\n•".utf16)) == [2])        // Kommentar endet am Zeilenende
        #expect(Placeholders.lines(in: Array("• % •".utf16)) == [1])
        #expect(Placeholders.lines(in: Array("\\\\% •".utf16)) == [])          // \\ dann echter Kommentar
        #expect(Placeholders.lines(in: Array("Länge\nä•".utf16)) == [2])
        #expect(Placeholders.lines(in: Array("ohne Platzhalter\n".utf16)) == [])
    }
}

// MARK: - Einfügen

@Suite("Bausteine: Einfügen im Fliesstext")
struct SnippetInlineInsertionTests {
    @Test func formulaOutsideMathGetsDollars() {
        #expect(inserting("formula.fraction", into: "Es gilt |.") == "Es gilt $\\frac{«•»}{•}$.")
        #expect(inserting("formula.integral", into: "|") == "$\\int_{«•»}^{•} • \\,\\mathrm{d}•$")
        #expect(inserting("formula.realNumbers", into: "x aus |") == "x aus $\\mathbb{R}$|")
    }

    @Test func formulaInsideMath() {
        #expect(inserting("formula.fraction", into: "$x = |$", inMath: true) == "$x = \\frac{«•»}{•}$")
        #expect(inserting("formula.realNumbers", into: "$x \\in |$", inMath: true) == "$x \\in \\mathbb{R}|$")
        #expect(inserting("formula.limit", into: "\\[\n  |\n\\]", inMath: true) == "\\[\n  \\lim_{«•» \\to •}\n\\]")
    }

    @Test func selectionGoesToTheToken() {
        #expect(inserting("formula.fraction", into: "$«a+b»$", inMath: true) == "$\\frac{a+b}{«•»}$")
        #expect(inserting("formula.squareRoot", into: "$«2»$", inMath: true) == "$\\sqrt{2}|$")
        #expect(inserting("formula.nthRoot", into: "$«8»$", inMath: true) == "$\\sqrt[«•»]{8}$")
        #expect(inserting("formula.superscript", into: "$x«10»$", inMath: true) == "$x^{10}|$")
        #expect(inserting("formula.squareRoot", into: "«2»") == "$\\sqrt{2}$|")
        #expect(inserting("text.footnote", into: "Wort«Erklärung».") == "Wort\\footnote{Erklärung}|.")
        #expect(inserting("text.link", into: "Siehe «Webseite».") == "Siehe \\href{«•»}{Webseite}.")
    }

    @Test func selectedFormulaIsNotWrappedTwice() {
        #expect(inserting("formula.squareRoot", into: "Also «$x+1$» gilt") == "Also $\\sqrt{x+1}$| gilt")
        #expect(inserting("formula.fraction", into: "«$a$»") == "$\\frac{a}{«•»}$")
    }

    @Test func selectionWithoutTokenIsReplaced() {
        #expect(inserting("text.label", into: "\\section{A}«alt»") == "\\section{A}\\label{«•»}")
        #expect(inserting("formula.realNumbers", into: "$x \\in «R»$", inMath: true) == "$x \\in \\mathbb{R}|$")
    }

    @Test func snippetsWithoutPlaceholderPutTheCursorAtTheEnd() {
        #expect(inserting("text.lineBreak", into: "Zeile|") == "Zeile\\\\|")
        #expect(inserting("text.lineBreak", into: "Zeile| weiter") == "Zeile\\\\| weiter")
    }

    @Test func umlautsAndEmojiBeforeTheCursor() {
        #expect(inserting("formula.vector", into: "Länge |") == "Länge $\\vec{«•»}$")
        #expect(inserting("formula.vector", into: "😀 |") == "😀 $\\vec{«•»}$")
    }

    @Test func multilineInlineSnippetFollowsTheIndentation() {
        let snippet = Snippet(id: "test.multiline", title: "Test", category: .text, body: "a{\n  •\n}", placement: .inline)
        #expect(inserting(snippet, into: "  x |") == "  x a{\n    «•»\n  }")
    }

    @Test func selectionIsClampedToTheText() throws {
        let fraction = try #require(SnippetCatalog.snippet(withID: "formula.fraction"))
        let edit = SnippetInserter.edit(inserting: fraction, in: Array("ab".utf16), selection: 1..<9, inMath: true)
        #expect(edit.range == 1..<2)
        #expect(edit.replacement == "\\frac{b}{•}")
        #expect(edit.selectionAfter == 10..<11)
    }
}

@Suite("Bausteine: Einfügen auf eigenen Zeilen")
struct SnippetBlockInsertionTests {
    @Test func emptyTextAndEmptyLines() {
        #expect(inserting("heading.section", into: "|") == "\\section{«•»}")
        #expect(inserting("heading.section", into: "a\n\n|\n\nb") == "a\n\n\\section{«•»}\n\nb")
        #expect(inserting("heading.section", into: "a\n|") == "a\n\\section{«•»}")
        #expect(inserting("heading.title", into: "|") == "\\title{«•»}\n\\author{•}\n\\date{\\today}\n\\maketitle")
        #expect(inserting("heading.tableOfContents", into: "|") == "\\tableofcontents|")
        #expect(inserting("document.exercise", into: "|") == "\\section*{Aufgabe «•»}\n•")
    }

    @Test func splitsTheCurrentLine() {
        #expect(inserting("heading.section", into: "Text| mehr") == "Text\n\\section{«•»}\nmehr")
        #expect(inserting("text.newPage", into: "Ende.   |") == "Ende.\n\\newpage|")
        #expect(inserting("text.newPage", into: "|Weiter") == "\\newpage|\nWeiter")
        // Eine Zeile nur aus Leerraum: Dieser Leerraum ist ihre Einrückung.
        #expect(inserting("text.newPage", into: "|   ") == "   \\newpage|")
        #expect(inserting("document.comment", into: "Text|") == "Text\n% «•»")
        #expect(inserting("display.unnumbered", into: "Es gilt |\nund weiter")
            == "Es gilt\n\\[\n  «•»\n\\]\nund weiter")
    }

    @Test func everyLineGetsTheCurrentIndentation() {
        #expect(inserting("display.unnumbered", into: "  |") == "  \\[\n    «•»\n  \\]")
        #expect(inserting("display.unnumbered", into: "\t|") == "\t\\[\n\t  «•»\n\t\\]")
        #expect(inserting("list.itemize", into: "  \\item Obst:|")
            == "  \\item Obst:\n  \\begin{itemize}\n    \\item «•»\n    \\item •\n  \\end{itemize}")
        #expect(inserting("text.newPage", into: "  Satz eins.| Satz zwei.") == "  Satz eins.\n  \\newpage|\n  Satz zwei.")
        #expect(inserting("text.newPage", into: "|  eingerückt") == "  \\newpage|\n  eingerückt")
    }

    @Test func selectedLinesGoToTheToken() {
        #expect(inserting("theorem.definition", into: "«Eine Folge heisst …\nzweite Zeile»")
            == "\\begin{definition}\n  Eine Folge heisst …\n  zweite Zeile\n\\end{definition}|")
        #expect(inserting("display.alignUnnumbered", into: "«(a+b)^2»")
            == "\\begin{align*}\n  (a+b)^2 &= «•» \\\\\n  &= •\n\\end{align*}")
        #expect(inserting("heading.section", into: "«Einleitung»") == "\\section{Einleitung}|")
    }

    @Test func newlinesAtTheEdgesOfTheSelectionStayOutside() {
        #expect(inserting("theorem.satz", into: "«a\nb\n»c") == "\\begin{satz}\n  a\n  b\n\\end{satz}|\nc")
        #expect(inserting("theorem.satz", into: "x«\na»\nc") == "x\n\\begin{satz}\n  a\n\\end{satz}|\nc")
    }

    @Test func selectedLinesAreReindented() {
        #expect(inserting("text.quote", into: "  «Zeile 1\n    eingerückt\n  Zeile 3»")
            == "  \\begin{quote}\n    Zeile 1\n      eingerückt\n    Zeile 3\n  \\end{quote}|")
        // Auswahl ab dem ersten Zeichen (ohne Einrückung) wirkt genauso.
        #expect(inserting("text.quote", into: "  «Zeile 1\n  Zeile 2»")
            == "  \\begin{quote}\n    Zeile 1\n    Zeile 2\n  \\end{quote}|")
        // Leere Zeilen bleiben leer (ohne Leerzeichen am Zeilenende).
        #expect(inserting("theorem.satz", into: "«a\n\n  b»") == "\\begin{satz}\n  a\n\n    b\n\\end{satz}|")
        // Code behält seine eigene Einrückung.
        #expect(inserting("text.codeBlock", into: "«def f():\n    return 1»")
            == "\\begin{verbatim}\ndef f():\n    return 1\n\\end{verbatim}|")
    }

    @Test func selectionInTheMiddleOfALine() {
        #expect(inserting("display.unnumbered", into: "Es gilt «x^2 = 1» für alle x.")
            == "Es gilt\n\\[\n  x^2 = 1\n\\]|\nfür alle x.")
        #expect(inserting("text.quote", into: "Text «a\n  b\n  c» Rest")
            == "Text\n\\begin{quote}\n  a\n  b\n  c\n\\end{quote}|\nRest")
    }

    @Test func selectedLinesBecomeListItems() {
        #expect(inserting("list.itemize", into: "«Äpfel\nBirnen\n\nKirschen»")
            == "\\begin{itemize}\n  \\item Äpfel\n  \\item Birnen\n  \\item Kirschen\n  \\item «•»\n\\end{itemize}")
        #expect(inserting("list.enumerate", into: "«\\item a\nb»")
            == "\\begin{enumerate}\n  \\item a\n  \\item b\n  \\item «•»\n\\end{enumerate}")
        // Steht eine Umgebung in der Auswahl, bleibt sie als Ganzes erhalten.
        #expect(inserting("list.itemize", into: "«a\n\\begin{center}\nb\n\\end{center}»")
            == "\\begin{itemize}\n  \\item a\n  \\begin{center}\n  b\n  \\end{center}\n  \\item «•»\n\\end{itemize}")
    }

    @Test func selectionWithoutTokenIsReplaced() {
        #expect(inserting("text.newPage", into: "a «weg» b") == "a\n\\newpage|\nb")
        #expect(inserting("text.quote", into: "«   »") == "   \\begin{quote}\n     «•»\n   \\end{quote}")
    }

    @Test func blockThatNeedsMathIsWrapped() {
        let snippet = Snippet(id: "test.block", title: "Test", category: .formulaBlocks, body: "x", placement: .block, requiresMath: true)
        #expect(inserting(snippet, into: "|") == "$x$|")
        #expect(inserting(snippet, into: "$|$", inMath: true) == "$\nx|\n$")
    }

    @Test func editIsOneContiguousReplacement() throws {
        let section = try #require(SnippetCatalog.snippet(withID: "heading.section"))
        let edit = SnippetInserter.edit(inserting: section, in: Array("ab".utf16), selection: 5..<9, inMath: false)
        #expect(edit.range == 2..<2)
        #expect(edit.replacement == "\n\\section{•}")
        #expect(edit.selectionAfter == 12..<13)
    }
}

@Suite("Bausteine: alle Bausteine überall einfügen")
struct SnippetInsertionInvariantTests {
    /// Verschiedene Ausgangslagen: leer, mitten im Satz, eingerückt, mit Auswahl …
    static let contexts = [
        "|", "Text| mehr", "  eingerückt|", "«Auswahl»", "a «b\n  c» d", "Übung: |\n\nNächster Absatz", "% Kommentar|"
    ]

    @Test(arguments: SnippetCatalog.all)
    func insertionIsConsistent(_ snippet: Snippet) {
        for context in Self.contexts {
            let (text, selection) = parseMarked(context)
            let edit = SnippetInserter.edit(inserting: snippet, in: Array(text.utf16), selection: selection, inMath: false)
            #expect(edit.range.lowerBound >= 0 && edit.range.upperBound <= text.utf16.count)
            let result = applying(edit, to: text)
            let units = Array(result.utf16)
            #expect(edit.selectionAfter.lowerBound >= 0 && edit.selectionAfter.upperBound <= units.count)
            #expect(!result.contains(Snippet.selectionToken), "\(snippet.id) in \(context)")
            // Kein Leerraum am Zeilenende.
            for line in result.components(separatedBy: "\n") {
                #expect(line.last != " " && line.last != "\t", "\(snippet.id) in \(context): »\(line)«")
            }
            // Erster Platzhalter ausgewählt, sonst Cursor ohne Auswahl.
            if edit.replacement.contains(Placeholders.marker) {
                #expect(edit.selectionAfter.count == 1)
                #expect(units[edit.selectionAfter.lowerBound] == Placeholders.unit)
                let firstInReplacement = Array(edit.replacement.utf16).firstIndex(of: Placeholders.unit) ?? -1
                #expect(edit.selectionAfter.lowerBound == edit.range.lowerBound + firstInReplacement)
            } else {
                #expect(edit.selectionAfter.isEmpty)
            }
            // Der ausgewählte Platzhalter eines Formel-Bausteins steht in einer Formel
            // (ausser in einem Kommentar). Ohne Platzhalter steht der Cursor hinter dem `$`.
            if snippet.requiresMath && !context.hasPrefix("%") && !edit.selectionAfter.isEmpty {
                let tokens = LaTeXTokenizer.tokenize(units)
                #expect(tokens.isInsideMath(at: edit.selectionAfter.lowerBound), "\(snippet.id) in \(context)")
            }
            // Bausteine auf eigenen Zeilen: Der eingefügte Text beginnt am Zeilenanfang.
            if snippet.placement == .block {
                let start = edit.range.lowerBound + (edit.replacement.hasPrefix("\n") ? 1 : 0)
                let lineStart = units.lineStart(before: start)
                #expect(units.string(in: lineStart..<start).allSatisfy { $0 == " " || $0 == "\t" }, "\(snippet.id) in \(context)")
            }
        }
    }

    @Test(arguments: SnippetCatalog.snippets(in: .formulas))
    func formulasInsideMathAreNotWrapped(_ snippet: Snippet) {
        let (text, selection) = parseMarked("$x = |$")
        let edit = SnippetInserter.edit(inserting: snippet, in: Array(text.utf16), selection: selection, inMath: true)
        #expect(!edit.replacement.contains("$"))
        #expect(edit.replacement == snippet.body.replacingOccurrences(of: Snippet.selectionToken, with: Placeholders.marker))
    }

    @Test func tabWalksThroughAllPlaceholdersOfAnInsertedTable() throws {
        let table = try #require(SnippetCatalog.snippet(withID: "table.2x2"))
        let edit = SnippetInserter.edit(inserting: table, in: [UInt16](), selection: 0..<0, inMath: false)
        let units = Array(edit.replacement.utf16)
        var selection = edit.selectionAfter
        var visited = 1
        while let next = Placeholders.next(in: units, from: selection.upperBound) {
            selection = next
            visited += 1
        }
        #expect(visited == 5)           // vier Zellen und die Beschriftung
        #expect(Placeholders.lines(in: units).count == 3)
    }
}

// MARK: - Grenzfälle (Gegenprüfung)
//
// Die folgenden Tests versuchen gezielt, das Modul zu brechen: Textränder,
// Windows-Zeilenenden, Emoji, Kommentare, Auswahlen mit • oder ⟦⟧ darin.

/// Zerlegt Text an jedem `\n` – auch innerhalb von `\r\n` und auf jeder Plattform gleich.
/// (`components(separatedBy:)` behandelt `\r\n` unter Linux als ein einziges Zeichen.)
private func lineList(_ text: String) -> [String] {
    Array(text.utf16).split(separator: TeXChar.newline, omittingEmptySubsequences: false)
        .map { String(decoding: $0, as: UTF16.self) }
}

/// Einfacher Zufallsgenerator mit festem Startwert, damit jeder Testlauf dieselben Texte prüft.
private struct SeededGenerator {
    var state: UInt64
    mutating func next(_ upperBound: Int) -> Int {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Int((state >> 33) % UInt64(upperBound))
    }
}

/// Zufällige kurze Texte aus heiklen Zeichen: Platzhalter, Umbrüche, Leerraum, `\r`, `%`, `\`, Emoji.
private func randomTexts(count: Int, maxLength: Int) -> [[UInt16]] {
    let alphabet: [String] = ["a", "•", "•", "\n", "\n", " ", "\t", "\r", "%", "\\", "😀"]
    var generator = SeededGenerator(state: 0x2022)
    return (0..<count).map { _ in
        let length = generator.next(maxLength + 1)
        let text = (0..<length).map { _ in alphabet[generator.next(alphabet.count)] }.joined()
        return Array(text.utf16)
    }
}

/// Absatz um `position` – bewusst anders umgesetzt als im Modul (über eine Zeilenliste).
private func referenceParagraph(_ units: [UInt16], around position: Int) -> Range<Int>? {
    var lines: [Range<Int>] = []
    var start = 0
    for (index, unit) in units.enumerated() where unit == TeXChar.newline {
        lines.append(start..<index)
        start = index + 1
    }
    lines.append(start..<units.count)
    func isBlank(_ line: Range<Int>) -> Bool {
        units[line].allSatisfy { $0 == TeXChar.space || $0 == TeXChar.tab || $0 == TeXChar.carriageReturn }
    }
    guard let current = lines.firstIndex(where: { $0.lowerBound <= position && position <= $0.upperBound }),
          !isBlank(lines[current]) else { return nil }
    var first = current
    var last = current
    while first > 0, !isBlank(lines[first - 1]) { first -= 1 }
    while last < lines.count - 1, !isBlank(lines[last + 1]) { last += 1 }
    return lines[first].lowerBound..<lines[last].upperBound
}

/// Zeilen mit Platzhaltern ausserhalb von Kommentaren – ebenfalls unabhängig vom Modul gezählt.
private func referencePlaceholderLines(_ units: [UInt16]) -> [Int] {
    var result: [Int] = []
    for (index, line) in units.split(separator: TeXChar.newline, omittingEmptySubsequences: false).enumerated() {
        let line = Array(line)
        let commentStart = line.indices.first { line[$0] == TeXChar.percent && !line.isEscaped(at: $0) } ?? line.count
        if line[..<commentStart].contains(Placeholders.unit) { result.append(index + 1) }
    }
    return result
}

/// Ist jedes UTF-16-Ersatzpaar (z. B. 😀) vollständig?
private func hasOnlyCompleteSurrogatePairs(_ units: [UInt16]) -> Bool {
    for (index, unit) in units.enumerated() {
        if UTF16.isLeadSurrogate(unit), !(index + 1 < units.count && UTF16.isTrailSurrogate(units[index + 1])) { return false }
        if UTF16.isTrailSurrogate(unit), !(index > 0 && UTF16.isLeadSurrogate(units[index - 1])) { return false }
    }
    return true
}

/// Anzahl Zeilen, die mit Leerzeichen oder Tab enden.
private func linesWithTrailingWhitespace(_ text: String) -> Int {
    lineList(text).filter { line in
        let trimmed = line.hasSuffix("\r") ? String(line.dropLast()) : line
        return trimmed.hasSuffix(" ") || trimmed.hasSuffix("\t")
    }.count
}

/// Ist `needle` (ohne Leerraum) eine Teilfolge von `haystack` (ohne Leerraum)?
private func isSubsequenceIgnoringWhitespace(_ needle: String, of haystack: String) -> Bool {
    let isContent: (Unicode.Scalar) -> Bool = { !$0.properties.isWhitespace }
    var remaining = needle.unicodeScalars.filter(isContent)[...]
    for scalar in haystack.unicodeScalars where isContent(scalar) {
        if remaining.first == scalar { remaining.removeFirst() }
        if remaining.isEmpty { return true }
    }
    return remaining.isEmpty
}

@Suite("Bausteine: Katalog unter der Lupe")
struct SnippetCatalogAuditTests {
    let all = SnippetCatalog.all

    @Test func idsAreWellFormedAndGroupedByCategory() {
        #expect(Set(all.map(\.id)).count == all.count)
        var prefixes: [SnippetCategory: Set<String>] = [:]
        for snippet in all {
            let parts = snippet.id.split(separator: ".", omittingEmptySubsequences: false)
            #expect(parts.count == 2 && parts.allSatisfy { !$0.isEmpty }, "\(snippet.id)")
            #expect(snippet.id.unicodeScalars.allSatisfy { $0.isASCII && ($0.properties.isAlphabetic || ("0"..."9").contains($0) || $0 == ".") },
                    "\(snippet.id)")
            prefixes[snippet.category, default: []].insert(String(parts[0]))
        }
        // Jede Gruppe hat genau ein Präfix, und keine zwei Gruppen teilen sich eines.
        #expect(prefixes.values.allSatisfy { $0.count == 1 })
        #expect(Set(prefixes.values.flatMap { $0 }).count == prefixes.count)
    }

    /// Schweizer Rechtschreibung auch in den Bausteinen selbst und in den Menütiteln.
    @Test func noSharpSAnywhere() {
        for snippet in all {
            let texts = [snippet.title, snippet.help, snippet.body] + snippet.keywords
            #expect(!texts.joined().contains("\u{00DF}"), "Eszett in \(snippet.id)")
        }
        for category in SnippetCategory.allCases {
            #expect(!category.title.contains("\u{00DF}"), "\(category)")
        }
    }

    /// Umgebungen richtig verschachtelt, `\[ \]`, `\left \right`, `[ ]`, `( )` und `{ }` ausgeglichen.
    @Test func delimitersAreProperlyNested() {
        for snippet in all {
            let units = Array(snippet.body.utf16)
            var environments: [String] = []
            var braces = 0, brackets = 0, parentheses = 0, displays = 0, leftRight = 0, dollars = 0
            func name(after start: Int) -> (String, Int) {
                var end = start
                while end < units.count, units[end] != TeXChar.braceClose { end += 1 }
                return (units.string(in: start..<end), end + 1)
            }
            func isCommand(_ command: String, at index: Int) -> Bool {
                guard units.matches(command, at: index) else { return false }
                let after = index + command.utf16.count
                return after >= units.count || !TeXChar.isASCIILetter(units[after])
            }
            var i = 0
            while i < units.count {
                let unit = units[i]
                if unit == TeXChar.backslash {
                    if units.matches("\\begin{", at: i) {
                        let (environment, next) = name(after: i + 7)
                        environments.append(environment)
                        i = next
                    } else if units.matches("\\end{", at: i) {
                        let (environment, next) = name(after: i + 5)
                        #expect(environments.popLast() == environment, "\(snippet.id): \\end{\(environment)}")
                        i = next
                    } else if units.matches("\\[", at: i) {
                        #expect(displays == 0, "\(snippet.id): verschachteltes \\[")
                        displays += 1
                        i += 2
                    } else if units.matches("\\]", at: i) {
                        displays -= 1
                        #expect(displays >= 0, "\(snippet.id)")
                        i += 2
                    } else if isCommand("\\left", at: i) {
                        leftRight += 1
                        i += 6       // samt Begrenzer wie `(` oder `|`
                    } else if isCommand("\\right", at: i) {
                        leftRight -= 1
                        #expect(leftRight >= 0, "\(snippet.id)")
                        i += 7
                    } else {
                        // `\\`, `\{`, `\}` usw. überspringen; bei Befehlsnamen reicht der Backslash.
                        i += (i + 1 < units.count && !TeXChar.isASCIILetter(units[i + 1])) ? 2 : 1
                    }
                    continue
                }
                switch unit {
                case TeXChar.braceOpen: braces += 1
                case TeXChar.braceClose: braces -= 1
                case TeXChar.bracketOpen: brackets += 1
                case TeXChar.bracketClose: brackets -= 1
                case TeXChar.parenOpen: parentheses += 1
                case TeXChar.parenClose: parentheses -= 1
                case TeXChar.dollar: dollars += 1
                default: break
                }
                #expect(braces >= 0 && brackets >= 0 && parentheses >= 0, "\(snippet.id)")
                i += 1
            }
            #expect(environments.isEmpty, "\(snippet.id): offene Umgebung \(environments)")
            #expect(braces == 0 && brackets == 0 && parentheses == 0, "\(snippet.id)")
            #expect(displays == 0 && leftRight == 0 && dollars % 2 == 0, "\(snippet.id)")
        }
    }

    /// `\partial•` würde zu `\partialx`, sobald man für den Platzhalter x tippt.
    @Test func noCommandNameRunsIntoAPlaceholder() {
        let tokenStart = Snippet.selectionToken.utf16.first!
        for snippet in all {
            let units = Array(snippet.body.utf16)
            for index in units.indices where units[index] == Placeholders.unit || units[index] == tokenStart {
                var start = index
                while start > 0, TeXChar.isASCIILetter(units[start - 1]) { start -= 1 }
                let isCommandName = start < index && start > 0 && units[start - 1] == TeXChar.backslash
                    && !units.isEscaped(at: start - 1)
                #expect(!isCommandName, "\(snippet.id): Befehl direkt vor einem Platzhalter")
            }
        }
    }

    @Test func bodiesUsePlainCharactersOnly() {
        for snippet in all {
            #expect(!snippet.body.contains("\r") && !snippet.body.contains("\t"), "\(snippet.id)")
            #expect(!snippet.body.isEmpty && !snippet.body.hasPrefix("\n") && !snippet.body.hasSuffix("\n"), "\(snippet.id)")
            // Formel-Bausteine bringen ihre `$` nicht selbst mit – das macht das Einfügen.
            if snippet.requiresMath { #expect(!snippet.body.contains("$"), "\(snippet.id)") }
        }
    }
}

@Suite("Bausteine: Platzhalter-Grenzfälle")
struct PlaceholderEdgeCaseTests {
    @Test func paragraphEdges() {
        #expect(tab("|•\n\n•") == "«•»\n\n•")                         // Textanfang
        #expect(tab("•\n\n•|", backwards: true) == "•\n\n«•»")       // Textende
        #expect(tab("•\n\n|•", backwards: true) == nil)              // Absatzanfang
        #expect(tab("•|\n\n•") == nil)                               // Absatzende
        #expect(tab("a•|\nb•") == "a•\nb«•»")                        // Zeilenende mitten im Absatz
        #expect(tab("a•\n|b•", backwards: true) == "a«•»\nb•")
        #expect(tab("x\n\n•\ny|", backwards: true) == "x\n\n«•»\ny")
    }

    @Test func whitespaceOnlyLines() {
        #expect(tab("•\n  |  \n•") == nil)                           // Cursor auf einer Zeile nur aus Leerraum
        #expect(tab("•\n\t|\n•", backwards: true) == nil)
        #expect(tab("|a\n \t \n•") == nil)                            // sie trennt Absätze
        #expect(tab("•\n\t\n|a", backwards: true) == nil)
        #expect(tab("   |") == nil)
    }

    @Test func windowsLineEndings() {
        #expect(tab("|a\r\nb •") == "a\r\nb «•»")
        #expect(tab("|a\r\n\r\n•") == nil)                            // `\r\n\r\n` ist eine Leerzeile
        #expect(tab("•\r\n \r\nx|", backwards: true) == nil)
        #expect(tab("•\r\nx|", backwards: true) == "«•»\r\nx")
        #expect(tab("•\r\n|\r\n•") == nil)                           // Cursor auf der Leerzeile
        #expect(Placeholders.lines(in: Array("a\r\n•\r\n% •\r\n".utf16)) == [2])
    }

    @Test func emojiAroundPlaceholders() {
        #expect(tab("😀|😀•") == "😀😀«•»")
        #expect(tab("•😀|😀", backwards: true) == "«•»😀😀")
        #expect(Placeholders.lines(in: Array("😀\n😀•".utf16)) == [2])
    }

    @Test func commentsAndEscapedPercent() {
        #expect(Placeholders.lines(in: Array("x \\% • % •".utf16)) == [1])          // \% ist kein Kommentar
        #expect(Placeholders.lines(in: Array("x \\% % •".utf16)) == [])             // danach ein echter
        #expect(Placeholders.lines(in: Array("\\\\\\% •".utf16)) == [1])            // \\ und \%
        #expect(Placeholders.lines(in: Array("%•\n•%\n\\%•".utf16)) == [2, 3])
        #expect(Placeholders.lines(in: Array("% •\n% •".utf16)) == [])
    }

    /// Vergleich mit einer unabhängigen Umsetzung auf vielen zufälligen Texten, an jeder Position.
    @Test func matchesAReferenceImplementation() {
        for units in randomTexts(count: 600, maxLength: 14) {
            for position in -1...(units.count + 1) {
                let clamped = min(max(0, position), units.count)
                let paragraph = referenceParagraph(units, around: clamped)
                let expectedNext = paragraph.flatMap { p in
                    (clamped..<p.upperBound).first { units[$0] == Placeholders.unit }.map { $0..<($0 + 1) }
                }
                let expectedPrevious = paragraph.flatMap { p in
                    (p.lowerBound..<clamped).last { units[$0] == Placeholders.unit }.map { $0..<($0 + 1) }
                }
                #expect(Placeholders.next(in: units, from: position) == expectedNext,
                        "next in \(String(decoding: units, as: UTF16.self).debugDescription) ab \(position)")
                #expect(Placeholders.previous(in: units, before: position) == expectedPrevious,
                        "previous in \(String(decoding: units, as: UTF16.self).debugDescription) vor \(position)")
            }
            #expect(Placeholders.lines(in: units) == referencePlaceholderLines(units),
                    "lines in \(String(decoding: units, as: UTF16.self).debugDescription)")
        }
    }
}

@Suite("Bausteine: Einfügen in Grenzfällen")
struct SnippetInsertionEdgeCaseTests {
    @Test func textStartAndEnd() {
        #expect(inserting("formula.fraction", into: "|Text") == "$\\frac{«•»}{•}$Text")
        #expect(inserting("formula.fraction", into: "Text|") == "Text$\\frac{«•»}{•}$")
        #expect(inserting("text.label", into: "|") == "\\label{«•»}")
        #expect(inserting("text.lineBreak", into: "|") == "\\\\|")
    }

    @Test func blockOnTheLastLine() {
        #expect(inserting("text.newPage", into: "Text|") == "Text\n\\newpage|")
        #expect(inserting("heading.section", into: "a\nText|") == "a\nText\n\\section{«•»}")
        #expect(inserting("heading.section", into: "Text\n|") == "Text\n\\section{«•»}")
        #expect(inserting("display.unnumbered", into: "  Es gilt|") == "  Es gilt\n  \\[\n    «•»\n  \\]")
        #expect(inserting("theorem.satz", into: "Text «Aussage»") == "Text\n\\begin{satz}\n  Aussage\n\\end{satz}|")
    }

    @Test func inlineInsideAnExistingFormula() {
        #expect(inserting("formula.sum", into: "$a = |$", inMath: true) == "$a = \\sum_{«•»}^{•}$")
        #expect(inserting("formula.fraction", into: "$x = «a+b» + c$", inMath: true) == "$x = \\frac{a+b}{«•»} + c$")
        #expect(inserting("formula.text", into: "\\[\n  x «für alle» y\n\\]", inMath: true) == "\\[\n  x \\text{für alle}| y\n\\]")
        #expect(inserting("formula.vector", into: "$$|$$", inMath: true) == "$$\\vec{«•»}$$")
    }

    @Test func emojiBeforeAndAfterTheCursor() {
        #expect(inserting("formula.fraction", into: "😀|😀") == "😀$\\frac{«•»}{•}$😀")
        #expect(inserting("text.footnote", into: "«😀»") == "\\footnote{😀}|")
        #expect(inserting("heading.section", into: "😀 «Titel» 😀") == "😀\n\\section{Titel}|\n😀")
        #expect(inserting("text.quote", into: "😀|") == "😀\n\\begin{quote}\n  «•»\n\\end{quote}")
        #expect(inserting("text.quote", into: "|😀") == "\\begin{quote}\n  «•»\n\\end{quote}\n😀")
    }

    /// Eine Position zwischen den beiden UTF-16-Hälften von 😀 darf das Zeichen nicht zerreissen.
    @Test func surrogatePairsAreNeverSplit() throws {
        let footnote = try #require(SnippetCatalog.snippet(withID: "text.footnote"))
        let section = try #require(SnippetCatalog.snippet(withID: "heading.section"))
        let text = Array("a😀b".utf16)          // a, zwei Hälften, b
        let cases: [(Range<Int>, Range<Int>)] = [(2..<2, 1..<1), (2..<3, 1..<3), (0..<2, 0..<3), (1..<2, 1..<3)]
        for (selection, expected) in cases {
            let edit = SnippetInserter.edit(inserting: footnote, in: text, selection: selection, inMath: false)
            #expect(edit.range == expected, "\(selection)")
            let result = Array(applying(edit, to: "a😀b").utf16)
            #expect(hasOnlyCompleteSurrogatePairs(result), "\(selection)")
        }
        let block = SnippetInserter.edit(inserting: section, in: text, selection: 2..<2, inMath: false)
        #expect(hasOnlyCompleteSurrogatePairs(Array(applying(block, to: "a😀b").utf16)))
    }

    /// Leerraum am Rand einer Auswahl bleibt ausserhalb des Bausteins.
    @Test func whitespaceAtTheEdgesOfAnInlineSelection() {
        #expect(inserting("text.footnote", into: "«Wort »weiter") == "\\footnote{Wort}| weiter")
        #expect(inserting("formula.fraction", into: "Es gilt« a »und") == "Es gilt $\\frac{a}{«•»}$ und")
        #expect(inserting("text.label", into: "a« alt »b") == "a \\label{«•»} b")
        #expect(inserting("formula.squareRoot", into: "x« $y$\n»z") == "x $\\sqrt{y}$|\nz")
        // Nur Leerraum markiert: wie ein Cursor am Anfang – kein Absatzwechsel in der Formel.
        #expect(inserting("formula.absoluteValue", into: "x«\n\n»y") == "x$\\left| «•» \\right|$\n\ny")
        #expect(inserting("text.footnote", into: "a« »b") == "a\\footnote{«•»} b")
    }

    @Test func selectionSpanningLines() {
        #expect(inserting("text.footnote", into: "a«b\nc»d") == "a\\footnote{b\nc}|d")
        #expect(inserting("theorem.lemma", into: "Vorher «eins\nzwei» nachher")
            == "Vorher\n\\begin{lemma}\n  eins\n  zwei\n\\end{lemma}|\nnachher")
    }

    @Test func selectionContainingAPlaceholder() {
        // Der erste • im eingefügten Text wird ausgewählt – auch wenn er aus der Auswahl stammt.
        #expect(inserting("text.footnote", into: "«a • b»") == "\\footnote{a «•» b}")
        #expect(inserting("theorem.satz", into: "«x = •»") == "\\begin{satz}\n  x = «•»\n\\end{satz}")
        #expect(inserting("formula.fraction", into: "$«•»$", inMath: true) == "$\\frac{«•»}{•}$")
    }

    /// Ein ⟦⟧ im markierten Text ist Text des Nutzers und bleibt, wie es ist.
    @Test func selectionContainingTheToken() {
        #expect(inserting("text.footnote", into: "«a ⟦⟧ b»") == "\\footnote{a ⟦⟧ b}|")
        #expect(inserting("theorem.satz", into: "«a ⟦⟧ b»") == "\\begin{satz}\n  a ⟦⟧ b\n\\end{satz}|")
        #expect(inserting("list.itemize", into: "«a\n⟦⟧»")
            == "\\begin{itemize}\n  \\item a\n  \\item ⟦⟧\n  \\item «•»\n\\end{itemize}")
        let twoTokens = Snippet(id: "test.twoTokens", title: "Test", category: .text, body: "\\a{⟦⟧}\n\\b{⟦⟧}", placement: .block)
        #expect(inserting(twoTokens, into: "«x⟦⟧»") == "\\a{x⟦⟧}\n\\b{«•»}")
        #expect(inserting(twoTokens, into: "|") == "\\a{«•»}\n\\b{•}")
    }

    @Test func tabIndentation() {
        #expect(inserting("text.quote", into: "\t«a\n\tb»") == "\t\\begin{quote}\n\t  a\n\t  b\n\t\\end{quote}|")
        #expect(inserting("heading.section", into: "\tText|\tmehr") == "\tText\n\t\\section{«•»}\n\tmehr")
        #expect(inserting("display.unnumbered", into: "\t\t|") == "\t\t\\[\n\t\t  «•»\n\t\t\\]")
    }

    /// Windows-Zeilenenden: `\r` gehört zum Zeilenumbruch und erzeugt keine zusätzliche Leerzeile.
    @Test func windowsLineEndings() {
        #expect(inserting("heading.section", into: "Text|\r\nmehr") == "Text\n\\section{«•»}\r\nmehr")
        #expect(inserting("text.newPage", into: "|\r\nWeiter") == "\\newpage|\r\nWeiter")
        #expect(inserting("text.newPage", into: "  |\r\n") == "  \\newpage|\r\n")
        #expect(inserting("text.newPage", into: "Ende.  |\r\n") == "Ende.\n\\newpage|\r\n")
        #expect(inserting("theorem.satz", into: "«a\r\nb»\r\nc") == "\\begin{satz}\n  a\n  b\n\\end{satz}|\r\nc")
        // Ganze Zeilen samt Umbruch markiert: Die Umbrüche davor und danach bleiben unberührt.
        #expect(inserting("theorem.satz", into: "x\r\n«a\r\nb\r\n»c") == "x\r\n\\begin{satz}\n  a\n  b\n\\end{satz}|\r\nc")
        #expect(inserting("theorem.satz", into: "x«\r\na»\r\nc") == "x\r\n\\begin{satz}\n  a\n\\end{satz}|\r\nc")
        // Mehrzeilige Auswahl wird auch mit `\r\n` in Zeilen zerlegt (auf jeder Plattform).
        #expect(inserting("text.quote", into: "  «a\r\n    b»") == "  \\begin{quote}\n    a\n      b\n  \\end{quote}|")
        #expect(inserting("list.itemize", into: "«Äpfel\r\nBirnen»")
            == "\\begin{itemize}\n  \\item Äpfel\n  \\item Birnen\n  \\item «•»\n\\end{itemize}")
    }

    /// Der Rest einer Kommentarzeile darf nach dem Aufteilen nicht plötzlich gesetzt werden.
    @Test func splittingACommentKeepsTheRestCommented() {
        #expect(inserting("heading.section", into: "% Kom|mentar") == "% Kom\n\\section{«•»}\n% mentar")
        #expect(inserting("text.newPage", into: "  % Notiz| weiter") == "  % Notiz\n  \\newpage|\n  % weiter")
        #expect(inserting("text.newPage", into: "50 \\% von| allem") == "50 \\% von\n\\newpage|\nallem")
        #expect(inserting("text.newPage", into: "a «b % c» d") == "a\n\\newpage|\n% d")
        #expect(inserting("theorem.satz", into: "a «b % c» d") == "a\n\\begin{satz}\n  b % c\n\\end{satz}|\n% d")
        #expect(inserting("text.newPage", into: "% a\nText| b") == "% a\nText\n\\newpage|\nb")
    }

    /// Endet die Auswahl mit einem Kommentar, darf er den Rest des Bausteins nicht auskommentieren.
    @Test func commentInTheSelectionDoesNotSwallowTheSnippet() {
        #expect(inserting("heading.section", into: "«Einleitung % TODO»") == "\\section{Einleitung} % TODO|")
        #expect(inserting("heading.section", into: "«Titel\n% Notiz»") == "\\section{Titel} % Notiz|")
        #expect(inserting("heading.section", into: "«% nur eine Notiz»") == "\\section{«•»} % nur eine Notiz")
        #expect(inserting("heading.section", into: "«50 \\% Rabatt»") == "\\section{50 \\% Rabatt}|")
        #expect(inserting("display.alignUnnumbered", into: "«(a+b)^2 % binomisch»")
            == "\\begin{align*}\n  (a+b)^2 &= «•» \\\\ % binomisch\n  &= •\n\\end{align*}")
        #expect(inserting("theorem.satz", into: "«Aussage % Quelle»") == "\\begin{satz}\n  Aussage % Quelle\n\\end{satz}|")
        #expect(inserting("formula.fraction", into: "«a % b»") == "$\\frac{a}{«•»}$ % b")
        #expect(inserting("formula.squareRoot", into: "x «2 % zwei» y") == "x $\\sqrt{2}$ % zwei| y")
        #expect(inserting("text.label", into: "x «alt % Notiz» y") == "x \\label{«•»} % Notiz y")
        #expect(inserting("text.footnote", into: "«5 \\% mehr»") == "\\footnote{5 \\% mehr}|")
    }

    /// `\rVert` direkt vor einem Buchstaben ergäbe den unbekannten Befehl `\rVertx`.
    @Test func commandNamesDoNotRunIntoTheFollowingText() {
        #expect(inserting("formula.norm", into: "$«x»y$", inMath: true) == "$\\lVert x \\rVert |y$")
        #expect(inserting("formula.norm", into: "$|v$", inMath: true) == "$\\lVert «•» \\rVert v$")
        #expect(inserting("formula.norm", into: "$|ä$", inMath: true) == "$\\lVert «•» \\rVert ä$")    // XeLaTeX
        #expect(inserting("formula.norm", into: "$|2$", inMath: true) == "$\\lVert «•» \\rVert2$")
        #expect(inserting("formula.norm", into: "$| v$", inMath: true) == "$\\lVert «•» \\rVert v$")
        #expect(inserting("formula.norm", into: "|v") == "$\\lVert «•» \\rVert$v")
        let power = Snippet(id: "test.power", title: "Test", category: .formulas, body: "x^{•}", placement: .inline, requiresMath: true)
        #expect(inserting(power, into: "$\\alpha|$", inMath: true) == "$\\alpha x^{«•»}$")
        #expect(inserting(power, into: "$\\\\|$", inMath: true) == "$\\\\x^{«•»}$")      // `\\` ist kein Befehlsname
        #expect(inserting(power, into: "$\\alpha |$", inMath: true) == "$\\alpha x^{«•»}$")
    }

    @Test func emptyListItemGetsAPlaceholder() {
        #expect(inserting("list.itemize", into: "«\\item»") == "\\begin{itemize}\n  \\item «•»\n  \\item •\n\\end{itemize}")
        #expect(inserting("list.enumerate", into: "«\\item\n\\item b»")
            == "\\begin{enumerate}\n  \\item «•»\n  \\item b\n  \\item •\n\\end{enumerate}")
    }
}

@Suite("Bausteine: jede Bearbeitung ist gültig")
struct SnippetEditValidityTests {
    /// Ausgangslagen, die das Einfügen schwer machen.
    static let contexts = [
        "|", "|Text", "Te|xt", "Text|", "Text|\n", "\n|", "Text\n|", "  eingerückt|", "\teingerückt|\n\tweiter",
        "«Auswahl»", "a «b\n  c» d", "«\n»", "«ganze Zeile\n»Rest", "«\n\n»", "x«\n\n»y",
        "Zeile\r\n|\r\nweiter", "Text|\r\nmehr", "«a\r\nb»\r\nc", "x«\r\na\r\n»y",
        "😀|😀", "«😀»", "x 😀|", "😀«a\n😀»😀",
        "% Kommentar|", "% Kom|mentar", "a «b % c» d", "«Titel % Notiz»", "50 \\% |Rabatt", "«a \\\\% b»",
        "«a • b»", "«a ⟦⟧ b»", "«⟦⟧»", "«•»", "«\\item»", "«\\item a\n\\item»",
        "$x = |$", "$«a+b»$", "«$x$»", "$$|$$", "\\[\n  «a»\n\\]", "$x$|", "|$x$", "$$x$$|", "« $y$ »",
        "Übung: |\n\nNächster Absatz", "   |   ", "\t|", "«   »", "a\n«  \n»b",
    ]

    @Test(arguments: SnippetCatalog.all)
    func everyEditIsValid(_ snippet: Snippet) {
        for context in Self.contexts {
            let (text, selection) = parseMarked(context)
            let oldUnits = Array(text.utf16)
            let tokenizerSaysMath = LaTeXTokenizer.tokenize(oldUnits).isInsideMath(at: selection.lowerBound)
            for inMath in Set([tokenizerSaysMath, false, true]) {
                let edit = SnippetInserter.edit(inserting: snippet, in: oldUnits, selection: selection, inMath: inMath)
                let label = "\(snippet.id) in \(context.debugDescription), inMath: \(inMath)"
                // Ein zusammenhängender Bereich im alten Text …
                #expect(edit.range.lowerBound >= 0 && edit.range.upperBound <= oldUnits.count, "\(label)")
                let result = applying(edit, to: text)
                let units = Array(result.utf16)
                // … und eine Auswahl, die im neuen Text liegt.
                #expect(edit.selectionAfter.lowerBound >= 0 && edit.selectionAfter.upperBound <= units.count, "\(label)")
                guard edit.selectionAfter.upperBound <= units.count else { continue }

                let replacement = Array(edit.replacement.utf16)
                if let first = replacement.firstIndex(of: Placeholders.unit) {
                    // Der erste Platzhalter des eingefügten Textes ist ausgewählt.
                    #expect(edit.selectionAfter == (edit.range.lowerBound + first)..<(edit.range.lowerBound + first + 1), "\(label)")
                    #expect(units[edit.selectionAfter.lowerBound] == Placeholders.unit, "\(label)")
                } else {
                    // Sonst steht der Cursor hinter dem eingefügten Baustein.
                    #expect(edit.selectionAfter.isEmpty, "\(label)")
                    #expect(edit.selectionAfter.lowerBound > edit.range.lowerBound, "\(label)")
                    #expect(edit.selectionAfter.lowerBound <= edit.range.lowerBound + replacement.count, "\(label)")
                }
                // Hat der Baustein Platzhalter (oder ein ⟦⟧ ohne Auswahl), ist danach ein • ausgewählt.
                // Eine Auswahl nur aus Leerraum zählt als leer.
                let selected = oldUnits.string(in: selection)
                let selectionIsBlank = selected.utf16.allSatisfy(TeXChar.isWhitespace)
                let hasToken = snippet.body.contains(Snippet.selectionToken)
                if snippet.body.contains(Placeholders.marker) || (hasToken && selectionIsBlank) {
                    #expect(edit.selectionAfter.count == 1 && units[edit.selectionAfter.lowerBound] == Placeholders.unit, "\(label)")
                }
                // Nichts geht kaputt: keine halben Emoji, kein neuer Leerraum am Zeilenende, kein
                // übrig gebliebenes ⟦⟧ – aber eines im Text des Nutzers bleibt (ausser die Auswahl wird ersetzt).
                #expect(hasOnlyCompleteSurrogatePairs(units), "\(label)")
                func tokenCount(_ string: String) -> Int { string.components(separatedBy: Snippet.selectionToken).count - 1 }
                #expect(tokenCount(result) == tokenCount(text) - (hasToken ? 0 : tokenCount(selected)), "\(label)")
                #expect(linesWithTrailingWhitespace(result) <= linesWithTrailingWhitespace(text), "\(label)")
                // Formel-Bausteine stehen danach in einer Formel – auch direkt neben einem `$…$`
                // (`$x$$\frac{•}{•}$` sind für TeX wie für die Einfärbung zwei Formeln).
                if snippet.requiresMath, inMath == tokenizerSaysMath, !context.hasPrefix("%") {
                    let tokens = LaTeXTokenizer.tokenize(units)
                    let probe = edit.selectionAfter.isEmpty ? edit.range.lowerBound + 1 : edit.selectionAfter.lowerBound
                    #expect(tokens.isInsideMath(at: probe), "\(label)")
                }
                // Markierter Text landet im Baustein, sofern dieser eine Stelle dafür hat.
                if hasToken, !selected.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("$") {
                    #expect(isSubsequenceIgnoringWhitespace(selected, of: edit.replacement), "\(label)")
                }
                // Bausteine auf eigenen Zeilen beginnen am Zeilenanfang und enden am Zeilenende.
                if snippet.placement == .block {
                    let start = edit.range.lowerBound + (edit.replacement.hasPrefix("\n") ? 1 : 0)
                    #expect(units.string(in: units.lineStart(before: start)..<start).allSatisfy { $0 == " " || $0 == "\t" }, "\(label)")
                    if edit.selectionAfter.isEmpty {
                        let next = units.unit(at: edit.selectionAfter.lowerBound)
                        #expect(next == nil || next == TeXChar.newline || next == TeXChar.carriageReturn, "\(label)")
                    }
                }
                // Tab erreicht alle Platzhalter des Bausteins der Reihe nach.
                if !selected.contains("\n"), !selected.contains(Placeholders.marker) {
                    var visited = edit.selectionAfter.isEmpty ? 0 : 1
                    var position = edit.selectionAfter.upperBound
                    let end = edit.range.lowerBound + replacement.count
                    while let next = Placeholders.next(in: units, from: position), next.upperBound <= end {
                        visited += 1
                        position = next.upperBound
                    }
                    #expect(visited == replacement.filter { $0 == Placeholders.unit }.count, "\(label)")
                }
            }
        }
    }
}

@Suite("Symbol-Kacheln")
struct MathSymbolTests {
    private var allSymbols: [MathSymbol] { MathSymbolGroup.allCases.flatMap(\.symbols) }

    @Test("Jedes Symbol hat Zeichen, Namen und einen LaTeX-Befehl")
    func symbolsAreComplete() {
        for symbol in allSymbols {
            #expect(!symbol.glyph.isEmpty)
            #expect(symbol.glyph.count == 1, "\(symbol.command): genau ein sichtbares Zeichen pro Kachel")
            #expect(!symbol.name.isEmpty)
            #expect(symbol.command.hasPrefix("\\"))
            #expect(!symbol.command.contains(Placeholders.marker), "\(symbol.command)")
        }
        for group in MathSymbolGroup.allCases {
            #expect(!group.symbols.isEmpty)
            #expect(group.symbols.contains { $0.glyph == group.representativeGlyph }, "\(group.title)")
        }
    }

    @Test("Befehle und Zeichen kommen nur einmal vor")
    func symbolsAreUnique() {
        #expect(Set(allSymbols.map(\.command)).count == allSymbols.count)
        #expect(Set(allSymbols.map(\.glyph)).count == allSymbols.count)
    }

    @Test("Im Fliesstext wird das Symbol in $…$ gesetzt")
    func insertsOutsideMath() {
        let alpha = MathSymbolGroup.greekLowercase.symbols[0]
        #expect(inserting(alpha.snippet(inMath: false), into: "Winkel | gross") == #"Winkel $\alpha$| gross"#)
        let reals = MathSymbolGroup.numberSets.symbols.first { $0.command == #"\mathbb{R}"# }!
        #expect(inserting(reals.snippet(inMath: false), into: "x aus |") == #"x aus $\mathbb{R}$|"#)
        #expect(reals.snippet(inMath: false).requirements.map(\.name) == ["amssymb"])
    }

    @Test("In einer Formel folgt einem Befehlsnamen ein Leerzeichen")
    func insertsInsideMath() {
        let alpha = MathSymbolGroup.greekLowercase.symbols[0]
        #expect(inserting(alpha.snippet(inMath: true), into: "$2|$", inMath: true) == #"$2\alpha |$"#)
        let leq = MathSymbolGroup.relations.symbols.first { $0.command == #"\leq"# }!
        #expect(inserting(leq.snippet(inMath: true), into: "$a | b$", inMath: true) == #"$a \leq | b$"#)
        let reals = MathSymbolGroup.numberSets.symbols.first { $0.command == #"\mathbb{R}"# }!
        #expect(inserting(reals.snippet(inMath: true), into: "$x \\in |$", inMath: true) == #"$x \in \mathbb{R}|$"#)
    }
}
