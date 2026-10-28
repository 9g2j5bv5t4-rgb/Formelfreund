import Foundation
import Testing
@testable import LaTeXKit

@Suite("Bausteine in freier Grösse")
struct StructureGeneratorTests {
    /// Zeilen des Bausteins, die Zellen enthalten (Platzhalter •).
    private func cellRows(_ snippet: Snippet) -> [String] {
        snippet.body.components(separatedBy: "\n").filter { $0.contains("•") && $0.contains("&") }
    }

    @Test("Tabelle: Zeilen, Spalten und Linien")
    func tableShape() {
        let grid = StructureGenerator.table(TableOptions(rows: 4, columns: 3))
        #expect(cellRows(grid).count == 4)
        #expect(cellRows(grid).allSatisfy { $0.components(separatedBy: "&").count == 3 })
        #expect(grid.body.contains("\\begin{tabular}{|c|c|c|}"))
        #expect(grid.body.components(separatedBy: "\\hline").count - 1 == 5)
        #expect(cellRows(grid)[0].contains("\\textbf{•}"))
        #expect(grid.body.hasPrefix("\\begin{table}[htbp]"))
        #expect(grid.body.contains("\\caption{•}"))
        #expect(grid.placement == .block)
        #expect(grid.requirements.isEmpty)

        let book = StructureGenerator.table(TableOptions(rows: 3, columns: 2, style: .booktabs, alignment: .left, hasHeader: true, hasCaption: false))
        #expect(book.body.contains("\\begin{tabular}{ll}"))
        #expect(book.body.contains("\\toprule") && book.body.contains("\\midrule") && book.body.contains("\\bottomrule"))
        #expect(book.body.hasPrefix("\\begin{center}"))
        #expect(book.requirements.map(\.name) == ["booktabs"])

        let plain = StructureGenerator.table(TableOptions(rows: 2, columns: 5, style: .plain, hasHeader: false))
        #expect(!plain.body.contains("\\hline") && !plain.body.contains("rule"))
        #expect(!plain.body.contains("\\textbf"))
        #expect(plain.title == "Tabelle 2 × 5")
    }

    @Test("Grössen werden auf 1 bis 20 begrenzt")
    func clamping() {
        let tiny = StructureGenerator.table(TableOptions(rows: 0, columns: -3))
        #expect(tiny.title == "Tabelle 1 × 1")
        let huge = StructureGenerator.matrix(rows: 99, columns: 40, delimiter: .brackets, displayed: true)
        #expect(huge.title == "Matrix 20 × 20")
        #expect(cellRows(huge).count == 20)
    }

    @Test("Matrix: abgesetzt oder kompakt in einer Formel")
    func matrixShape() {
        let displayed = StructureGenerator.matrix(rows: 2, columns: 3, delimiter: .parentheses, displayed: true)
        #expect(displayed.body == "\\[\n  \\begin{pmatrix}\n    • & • & • \\\\\n    • & • & •\n  \\end{pmatrix}\n\\]")
        #expect(displayed.placement == .block && !displayed.requiresMath)

        let inline = StructureGenerator.matrix(rows: 2, columns: 2, delimiter: .bars, displayed: false)
        #expect(inline.body == "\\begin{vmatrix} • & • \\\\ • & • \\end{vmatrix}")
        #expect(inline.placement == .inline && inline.requiresMath)
        #expect(inline.title == "Determinante 2 × 2")
        #expect(inline.requirements.map(\.name) == ["amsmath"])
        #expect(Set(MatrixDelimiter.allCases.map(\.environment)).count == MatrixDelimiter.allCases.count)
    }

    @Test("Vektor, Gleichungssystem, Fälle, ausgerichtete Zeilen, Listen")
    func otherStructures() {
        #expect(StructureGenerator.vector(components: 3).body == "\\begin{pmatrix} • \\\\ • \\\\ • \\end{pmatrix}")

        let system = StructureGenerator.equationSystem(equations: 3)
        #expect(system.body.components(separatedBy: "• = •").count - 1 == 3)
        #expect(system.body.components(separatedBy: "\\\\").count - 1 == 2)

        let cases = StructureGenerator.cases(3)
        #expect(cases.body.components(separatedBy: "\\text{falls } •").count - 1 == 2)
        #expect(cases.body.contains("• & \\text{sonst}\n"))
        #expect(!StructureGenerator.cases(1).body.contains("sonst"))

        let aligned = StructureGenerator.alignedEquations(4, numbered: true)
        #expect(aligned.body.hasPrefix("\\begin{align}\n  ⟦⟧ &= • \\\\"))
        #expect(aligned.body.components(separatedBy: "&= •").count - 1 == 4)
        #expect(StructureGenerator.alignedEquations(2, numbered: false).body.hasPrefix("\\begin{align*}"))

        let list = StructureGenerator.list(.enumerate, items: 5)
        #expect(list.body.components(separatedBy: "\\item").count - 1 == 5)
        #expect(list.body.contains("\\item ⟦⟧\n  \\item •"))
    }

    @Test("Eingefügt wird wie jeder andere Baustein, mit dem ersten Platzhalter ausgewählt")
    func insertion() {
        let snippet = StructureGenerator.matrix(rows: 2, columns: 2, delimiter: .parentheses, displayed: false)
        let text = Array("$A = $".utf16)
        let edit = SnippetInserter.edit(inserting: snippet, in: text, selection: 5..<5, inMath: true)
        #expect(edit.replacement == "\\begin{pmatrix} • & • \\\\ • & • \\end{pmatrix}")
        #expect(edit.selectionAfter == (5 + 16)..<(5 + 17))
    }

    /// Schreibt alle Varianten als LaTeX-Dokument – zum Prüfen mit pdfLaTeX/XeLaTeX
    /// (nur mit `LEMMA_DUMP_LATEX=Pfad`).
    @Test("Beispieldokument für die Übersetzungsprobe")
    func dumpForCompilation() throws {
        guard let path = ProcessInfo.processInfo.environment["LEMMA_DUMP_LATEX"] else { return }
        var snippets: [Snippet] = []
        for style in TableLineStyle.allCases {
            for header in [true, false] {
                for caption in [true, false] {
                    snippets.append(StructureGenerator.table(TableOptions(rows: 3, columns: 4, style: style, alignment: .right, hasHeader: header, hasCaption: caption)))
                }
            }
        }
        for delimiter in MatrixDelimiter.allCases {
            snippets.append(StructureGenerator.matrix(rows: 3, columns: 2, delimiter: delimiter, displayed: true))
        }
        snippets += [
            StructureGenerator.equationSystem(equations: 4),
            StructureGenerator.cases(1), StructureGenerator.cases(3),
            StructureGenerator.alignedEquations(3, numbered: true),
            StructureGenerator.alignedEquations(1, numbered: false),
            StructureGenerator.list(.itemize, items: 3),
            StructureGenerator.list(.enumerate, items: 2)
        ]
        var body = snippets.map { $0.body }.joined(separator: "\n\n")
        body += "\n\nInline $A = " + StructureGenerator.matrix(rows: 2, columns: 2, delimiter: .bars, displayed: false).body
            + "$ und $v = " + StructureGenerator.vector(components: 3).body + "$.\n"
        body = body.replacingOccurrences(of: "•", with: "x").replacingOccurrences(of: Snippet.selectionToken, with: "f(x)")
        let document = "\\documentclass{article}\n\\usepackage{amsmath}\n\\usepackage{booktabs}\n\\begin{document}\n\(body)\n\\end{document}\n"
        try document.write(toFile: path, atomically: true, encoding: .utf8)
    }
}
