import Foundation
import Testing
@testable import LaTeXKit

@Suite("Bausteine an der passenden Stelle einfügen")
struct InsertionPlannerTests {
    private let document = """
    \\documentclass{article}
    \\usepackage{amsmath}
    \\begin{document}
    Text mit $a + b$ im Satz.
    \\[
      x^2
    \\]
    \\begin{itemize}
      \\item Punkt
    \\end{itemize}
    \\begin{table}[htbp]
      \\begin{tabular}{cc}
        1 & 2 \\\\
      \\end{tabular}
    \\end{table}
    \\end{document}
    """

    private func snippet(_ id: String) -> Snippet {
        SnippetCatalog.snippet(withID: id)!
    }

    /// Plant das Einfügen mit dem Cursor direkt vor `marker` (erstes Vorkommen).
    private func plan(_ id: String, before marker: String, selecting length: Int = 0) -> (offset: Int, plan: InsertionPlanner.Plan) {
        let text = document as NSString
        let offset = text.range(of: marker).location
        let units = Array(document.utf16)
        return (offset, InsertionPlanner.plan(for: snippet(id), in: units, selection: offset..<(offset + length)))
    }

    private func offset(after marker: String) -> Int {
        let range = (document as NSString).range(of: marker)
        return range.location + range.length
    }

    private func lineStart(of marker: String) -> Int {
        let units = Array(document.utf16)
        return units.lineStart(before: (document as NSString).range(of: marker).location)
    }

    @Test("Textteil liegt zwischen \\begin{document} und \\end{document}")
    func bodyRange() {
        let body = InsertionPlanner.bodyRange(in: Array(document.utf16))
        #expect(body == lineStart(of: "Text mit")..<lineStart(of: "\\end{document}"))
        #expect(InsertionPlanner.bodyRange(in: Array("Nur ein Kapitel $x$".utf16)) == nil)
    }

    @Test("Aus der Präambel an den Anfang des Textteils")
    func fromPreamble() {
        let result = plan("display.matrix2", before: "\\usepackage")
        #expect(result.plan.selection == lineStart(of: "Text mit")..<lineStart(of: "Text mit"))
        #expect(result.plan.note != nil)
        // Auch Bausteine im Fliesstext gehören nicht in die Präambel.
        #expect(plan("formula.fraction", before: "\\usepackage").plan.selection.lowerBound == lineStart(of: "Text mit"))
    }

    @Test("Nach \\end{document} wird davor eingefügt")
    func afterEnd() {
        let units = Array((document + "\nNotiz").utf16)
        let plan = InsertionPlanner.plan(for: snippet("list.itemize"), in: units, selection: units.count..<units.count)
        #expect(plan.selection.lowerBound == lineStart(of: "\\end{document}"))
    }

    @Test("Abgesetzte Formel nicht in einer Formel, sondern dahinter")
    func outOfMath() {
        let inline = plan("display.matrix2", before: " + b$")
        #expect(inline.plan.selection.lowerBound == offset(after: "$a + b$"))
        let display = plan("display.matrix2", before: "x^2")
        #expect(display.plan.selection.lowerBound == offset(after: "x^2\n\\]"))
        // Ein Bruch gehört dagegen genau dorthin.
        let fraction = plan("formula.fraction", before: " + b$")
        #expect(fraction.plan.selection.lowerBound == fraction.offset)
        #expect(fraction.plan.note == nil)
    }

    @Test("Tabelle nicht in einer Tabelle, Überschrift nicht in einer Liste")
    func outOfEnvironments() {
        let table = plan("table.2x2", before: "1 & 2")
        #expect(table.plan.selection.lowerBound == offset(after: "\\end{table}"))
        let heading = plan("heading.section", before: "Punkt")
        #expect(heading.plan.selection.lowerBound == offset(after: "\\end{itemize}"))
        // Eine Liste darf in einer Liste stehen.
        let list = plan("list.enumerate", before: "Punkt")
        #expect(list.plan.selection.lowerBound == list.offset)
    }

    @Test("Formel im Text nicht in einer Formel")
    func inlineFormula() {
        let formula = Snippet(id: "test.inline", title: "Formel", category: .formulas, body: "$⟦⟧$", placement: .inline)
        let units = Array(document.utf16)
        let inside = (document as NSString).range(of: " + b$").location
        let plan = InsertionPlanner.plan(for: formula, in: units, selection: inside..<inside)
        #expect(plan.selection.lowerBound == offset(after: "$a + b$"))
    }

    @Test("Eine Auswahl im Textteil bleibt, wo sie ist")
    func keepsSelection() {
        let result = plan("display.unnumbered", before: "x^2", selecting: 3)
        #expect(result.plan.selection == result.offset..<(result.offset + 3))
        #expect(result.plan.note == nil)
    }

    @Test("Fügt man den Baustein am geplanten Ort ein, steht er auf eigenen Zeilen")
    func endToEnd() {
        let result = plan("display.matrix2", before: " + b$")
        let units = Array(document.utf16)
        let edit = SnippetInserter.edit(inserting: snippet("display.matrix2"), in: units, selection: result.plan.selection, inMath: false)
        let output = (document as NSString).replacingCharacters(
            in: NSRange(location: edit.range.lowerBound, length: edit.range.count), with: edit.replacement)
        #expect(output.contains("Text mit $a + b$\n\\[\n  \\begin{pmatrix}"))
        #expect(output.contains("\\end{pmatrix}\n\\]\nim Satz."))
    }
}
