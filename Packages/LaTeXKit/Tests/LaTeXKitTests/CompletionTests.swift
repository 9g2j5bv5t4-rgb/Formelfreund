import Foundation
import Testing
@testable import LaTeXKit

/// `|` markiert den Cursor.
private func context(_ textWithCursor: String, inMath: Bool = false) -> (CompletionContext?, [UInt16]) {
    let cursor = (textWithCursor as NSString).range(of: "|").location
    let text = Array(textWithCursor.replacingOccurrences(of: "|", with: "").utf16)
    return (CompletionEngine.context(in: text, cursor: cursor, inMath: inMath), text)
}

/// Wendet den Vorschlag an; `|` markiert danach Cursor bzw. Auswahlanfang, `^` das Auswahlende.
private func accept(_ item: CompletionItem, in textWithCursor: String, inMath: Bool = false) throws -> String {
    let (found, text) = context(textWithCursor, inMath: inMath)
    let context = try #require(found)
    let edit = CompletionEngine.edit(applying: item, context: context, in: text)
    let string = String(decoding: text, as: UTF16.self) as NSString
    let replaced = string.replacingCharacters(in: NSRange(location: edit.range.lowerBound, length: edit.range.count), with: edit.replacement) as NSString
    if edit.selectionAfter.isEmpty {
        return replaced.replacingCharacters(in: NSRange(location: edit.selectionAfter.lowerBound, length: 0), with: "|")
    }
    let withEnd = replaced.replacingCharacters(in: NSRange(location: edit.selectionAfter.upperBound, length: 0), with: "^") as NSString
    return withEnd.replacingCharacters(in: NSRange(location: edit.selectionAfter.lowerBound, length: 0), with: "|")
}

private func suggestions(_ textWithCursor: String, inMath: Bool = false) throws -> [CompletionItem] {
    let (found, text) = context(textWithCursor, inMath: inMath)
    let context = try #require(found)
    return CompletionEngine.suggestions(
        for: context,
        symbols: DocumentSymbols.scan(text),
        openEnvironment: CompletionEngine.openEnvironment(in: text, before: context.range.lowerBound)
    )
}

@Suite("Autovervollständigung: Kontext")
struct CompletionContextTests {
    @Test func commandAfterBackslash() throws {
        let (found, _) = context(#"Text \fra|"#)
        let context = try #require(found)
        #expect(context.kind == .command)
        #expect(context.prefix == "fra")
        #expect(context.range == 5..<9)
    }

    @Test func emptyCommandRightAfterBackslash() throws {
        let context = try #require(context(#"a \|"#).0)
        #expect(context.kind == .command)
        #expect(context.prefix == "")
    }

    @Test func noSuggestionsInCommentsOrMidWordOrAfterDoubleBackslash() {
        #expect(context(#"% \fra|"#).0 == nil)
        #expect(context(#"\fr|ac"#).0 == nil)
        #expect(context(#"a \\|"#).0 == nil)
        #expect(context("Hallo Welt|").0 == nil)
    }

    @Test func environmentAfterBegin() throws {
        let context = try #require(context(#"\begin{enu|}"#).0)
        #expect(context.kind == .environment(isEnd: false))
        #expect(context.prefix == "enu")
        #expect(context.closingBraceFollows)
        #expect(context.commandStart == 0)
    }

    @Test func referencesCitationsPackages() throws {
        #expect(context(#"siehe \ref{fig:|}"#).0?.kind == .reference)
        #expect(context(#"\eqref{|"#).0?.kind == .reference)
        #expect(context(#"\cite[S.~5]{mue|"#).0?.kind == .citation)
        let multiple = try #require(context(#"\cite{a, b|}"#).0)
        #expect(multiple.kind == .citation)
        #expect(multiple.prefix == "b")
        #expect(context(#"\usepackage[ngerman]{bab|}"#).0?.kind == .package)
        #expect(context(#"\documentclass{|}"#).0?.kind == .documentClass)
        // Gewöhnliche Argumente werden nicht vervollständigt.
        #expect(context(#"\section{Einl|}"#).0 == nil)
    }

    @Test func argumentRangeCoversWholeKey() throws {
        let context = try #require(context(#"\ref{fig:a|bc}"#).0)
        #expect(context.prefix == "fig:a")
        #expect(context.range == 5..<12)
    }
}

@Suite("Autovervollständigung: Vorschläge")
struct CompletionSuggestionTests {
    @Test func prefixMatchesFirst() throws {
        let items = try suggestions(#"\fra|"#, inMath: true)
        #expect(items.first?.name == "frac")
    }

    @Test func germanKeywordsFindCommands() throws {
        #expect(try suggestions(#"\bruch|"#).contains { $0.name == "frac" })
        #expect(try suggestions(#"\wurzel|"#).contains { $0.name == "sqrt" })
        #expect(try suggestions(#"\fett|"#).first?.name == "textbf")
    }

    @Test func mathContextPrefersMathCommands() throws {
        let inText = try suggestions(#"\s|"#)
        let inMath = try suggestions(#"\s|"#, inMath: true)
        #expect(inText.first?.name == "section")
        #expect(inMath.first?.isMath == true)
    }

    @Test func symbolsShowGlyph() throws {
        let alpha = try #require(try suggestions(#"\alp|"#, inMath: true).first)
        #expect(alpha.name == "alpha")
        #expect(alpha.glyph == "α")
    }

    @Test func userCommandsAreSuggested() throws {
        let text = #"\newcommand{\R}{\mathbb{R}}\newcommand{\abs}[1]{\lvert#1\rvert}\DeclareMathOperator{\Bild}{Bild} $\ab|"#
        let items = try suggestions(text, inMath: true)
        let abs = try #require(items.first { $0.name == "abs" })
        #expect(abs.label == #"\abs{…}"#)
        #expect(abs.kind == .userCommand)
    }

    @Test func environmentsWithBeginAndByName() throws {
        let items = try suggestions(#"\begin{it|}"#)
        #expect(items.first?.name == "itemize")
        // Schon beim Befehl: `\enum` bietet `\begin{enumerate}` an.
        let command = try suggestions(#"\enum|"#)
        #expect(command.contains { $0.label == #"\begin{enumerate}"# })
    }

    @Test func endSuggestsInnermostOpenEnvironment() throws {
        let items = try suggestions("\\begin{itemize}\n\\item a\n\\begin{center}\nx\n\\end{|")
        #expect(items.first?.name == "center")
    }

    @Test func labelsFromDocument() throws {
        let text = "\\section{A}\\label{sec:a}\n\\begin{figure}\\label{fig:kreis}\\end{figure}\nSiehe \\ref{fig|}"
        let items = try suggestions(text)
        #expect(items.first?.name == "fig:kreis")
        #expect(items.first?.detail == "Abbildung · Zeile 2")
        #expect(items.count == 1)
    }

    @Test func citationsFromBibitemsAndBibFiles() throws {
        let (found, text) = context("\\bibitem{knuth84} Knuth\n\\cite{|}")
        let context = try #require(found)
        let bib = BibliographyParser.entries(in: """
            @book{forster2016,
              author = {Forster, Otto},
              title = {Analysis {1}},
              year = 2016
            }
            @comment{nicht beachten}
            @article{ mueller20 , title = "Ein Artikel", author = "Anna Müller and Ben Meier", year = {2020}}
            """)
        #expect(bib.map(\.key) == ["forster2016", "mueller20"])
        #expect(bib[0].summary == "Forster (2016): Analysis 1")
        #expect(bib[1].summary == "Müller (2020): Ein Artikel")
        let items = CompletionEngine.suggestions(for: context, symbols: DocumentSymbols.scan(text), bibliography: bib)
        #expect(Set(items.map(\.name)) == ["forster2016", "mueller20", "knuth84"])
    }

    @Test func packagesAndClasses() throws {
        #expect(try suggestions(#"\usepackage{ams|}"#).map(\.name).prefix(2) == ["amsmath", "amssymb"])
        #expect(try suggestions(#"\documentclass{scr|}"#).first?.name == "scrartcl")
    }
}

@Suite("Autovervollständigung: Einfügen")
struct CompletionInsertTests {
    private func item(_ name: String, in list: [CompletionItem] = CompletionCatalog.commands) throws -> CompletionItem {
        try #require(list.first { $0.name == name })
    }

    @Test func commandWithPlaceholdersSelectsFirst() throws {
        #expect(try accept(item("frac"), in: #"$\fr|$"#, inMath: true) == #"$\frac{|•^}{•}$"#)
    }

    @Test func mathCommandOutsideMathGetsDollars() throws {
        #expect(try accept(item("frac"), in: #"Es gilt \fr|"#) == #"Es gilt $\frac{|•^}{•}$"#)
    }

    @Test func argumentCommandPutsCursorInsideBraces() throws {
        #expect(try accept(item("ref"), in: #"siehe \re|"#) == #"siehe \ref{|}"#)
        #expect(try item("ref").continuesCompletion)
    }

    @Test func symbolCompletes() throws {
        let alpha = try item("alpha")
        #expect(try accept(alpha, in: #"$\alp|$"#, inMath: true) == #"$\alpha|$"#)
        // Mitten in einem Namen gibt es keine Vorschläge (`\alpx` wäre ein anderer Befehl).
        #expect(context(#"$\alp|x$"#).0 == nil)
    }

    @Test func environmentGetsEndAndIndentation() throws {
        let itemize = try item("itemize", in: CompletionCatalog.environments)
        #expect(try accept(itemize, in: "  \\begin{ite|}") == "  \\begin{itemize}\n    \\item |\n  \\end{itemize}")
    }

    @Test func environmentWithExistingEndOnlyCompletesName() throws {
        let center = try item("center", in: CompletionCatalog.environments)
        #expect(try accept(center, in: "\\begin{cen|}\nx\n\\end{center}") == "\\begin{center}|\nx\n\\end{center}")
    }

    @Test func fullNameAlreadyTypedStillAddsEnd() throws {
        let center = try item("center", in: CompletionCatalog.environments)
        #expect(try accept(center, in: "\\begin{center|}") == "\\begin{center}\n  |\n\\end{center}")
    }

    @Test func endCompletesNameAndClosingBrace() throws {
        let itemize = try item("itemize", in: CompletionCatalog.environments)
        #expect(try accept(itemize, in: "\\end{it|") == "\\end{itemize}|")
    }

    @Test func referenceSkipsExistingBrace() throws {
        let label = CompletionItem(id: "l", kind: .reference, name: "fig:kreis", label: "fig:kreis", detail: "", body: "fig:kreis")
        #expect(try accept(label, in: #"\ref{fi|}"#) == #"\ref{fig:kreis}|"#)
        #expect(try accept(label, in: #"\ref{fi|"#) == #"\ref{fig:kreis}|"#)
    }

    @Test func environmentFromCommandContext() throws {
        let (found, text) = context(#"\enum|"#)
        let context = try #require(found)
        let items = CompletionEngine.suggestions(for: context, symbols: DocumentSymbols.scan(text))
        let enumerate = try #require(items.first { $0.label == #"\begin{enumerate}"# })
        #expect(try accept(enumerate, in: #"\enum|"#) == "\\begin{enumerate}\n  \\item |\n\\end{enumerate}")
    }

    @Test func alreadyCompleteLetsReturnThrough() throws {
        let context = try #require(context(#"\item|"#).0)
        #expect(CompletionEngine.isAlreadyComplete(try item("item"), context: context))
        #expect(!CompletionEngine.isAlreadyComplete(try item("frac"), context: context))
    }
}
