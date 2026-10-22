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
