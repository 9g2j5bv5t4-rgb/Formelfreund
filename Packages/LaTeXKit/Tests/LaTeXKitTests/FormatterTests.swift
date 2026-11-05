import Foundation
import Testing
@testable import LaTeXKit

private func formatted(_ text: String) -> String {
    LaTeXFormatter.format(text).text
}

@Suite("Formatieren")
struct FormatterTests {
    @Test func indentsEnvironmentsButNotDocument() {
        let input = """
            \\documentclass{article}
            \\begin{document}
               Text
            \\begin{itemize}
            \\item Eins
            \\item Zwei
            \\begin{enumerate}
            \\item Innen
            \\end{enumerate}
            \\end{itemize}
            \\end{document}
            """
        let expected = """
            \\documentclass{article}
            \\begin{document}
            Text
            \\begin{itemize}
              \\item Eins
              \\item Zwei
                    \\begin{enumerate}
                      \\item Innen
                    \\end{enumerate}
            \\end{itemize}
            \\end{document}

            """
        #expect(formatted(input) == expected)
    }

    @Test func itemContinuationAndDisplayMathAndBraces() {
        let input = """
            \\begin{enumerate}
            \\item Zeige:
            \\[
            a = b
            \\]
            \\end{enumerate}
            \\newcommand{\\foo}{%
            bar
            }
            """
        let expected = """
            \\begin{enumerate}
              \\item Zeige:
                    \\[
                      a = b
                    \\]
            \\end{enumerate}
            \\newcommand{\\foo}{%
              bar
            }

            """
        #expect(formatted(input) == expected)
    }

    @Test func alignsTablesAtAmpersands() {
        let input = """
            \\begin{tabular}{lcr}
            \\hline
            Name&Wert&Einheit\\\\
            Länge & 1{,}5 & m \\\\ \\hline
            T&2&s\\\\
            \\end{tabular}
            """
        let expected = """
            \\begin{tabular}{lcr}
              \\hline
              Name  & Wert  & Einheit \\\\
              Länge & 1{,}5 & m \\\\ \\hline
              T     & 2     & s \\\\
            \\end{tabular}

            """
        #expect(formatted(input) == expected)
    }

    @Test func alignsEquationsWithAmpersandBeforeRelation() {
        let input = """
            \\begin{align*}
            (a+b)^2&=a^2+2ab+b^2\\\\
            &\\geq 0
            \\end{align*}
            """
        let expected = """
            \\begin{align*}
              (a+b)^2 &=a^2+2ab+b^2 \\\\
                      &\\geq 0
            \\end{align*}

            """
        #expect(formatted(input) == expected)
    }

    @Test func matricesInsideDisplayMath() {
        let input = "\\[\n\\begin{pmatrix}\n1&10\\\\\n100&2\n\\end{pmatrix}\n\\]"
        let expected = "\\[\n  \\begin{pmatrix}\n    1   & 10 \\\\\n    100 & 2\n  \\end{pmatrix}\n\\]\n"
        #expect(formatted(input) == expected)
    }

    @Test func blankLinesAndTrailingSpaces() {
        let input = "\n\nEins   \n\n\n\nZwei\t\n\\section{Neu}\nText\n\n\n"
        let expected = "Eins\n\nZwei\n\n\\section{Neu}\nText\n"
        #expect(formatted(input) == expected)
    }

    @Test func noBlankLineBetweenHeadingsOrAfterBegin() {
        let input = "\\begin{document}\n\\section{A}\n\\subsection{B}\n% Kommentar\n\\section{C}\n\\end{document}"
        #expect(formatted(input) == input + "\n")
    }

    @Test func verbatimStaysUntouched() {
        let input = "\\begin{itemize}\n\\item x\n\\begin{verbatim}\n   genau   so  \n\\end{verbatim}\n\\end{itemize}"
        let expected = "\\begin{itemize}\n  \\item x\n        \\begin{verbatim}\n   genau   so  \n\\end{verbatim}\n\\end{itemize}\n"
        #expect(formatted(input) == expected)
    }

    @Test func escapedAmpersandsAndBracesAreIgnored() {
        let input = "\\begin{tabular}{ll}\nA \\& B & \\{x\\} \\\\\nC & D\n\\end{tabular}"
        let expected = "\\begin{tabular}{ll}\n  A \\& B & \\{x\\} \\\\\n  C      & D\n\\end{tabular}\n"
        #expect(formatted(input) == expected)
    }

    @Test func alreadyFormattedGivesNoEdit() {
        let text = Array("\\begin{center}\n  Text\n\\end{center}\n".utf16)
        #expect(LaTeXFormatter.edit(in: text, selection: 0..<0) == nil)
    }

    @Test func editIsMinimalAndKeepsCursorInContent() throws {
        let string = "Kopf\n\\begin{center}\nTe|xt\n\\end{center}\nFuss\n"
        let cursor = (string as NSString).range(of: "|").location
        let text = Array(string.replacingOccurrences(of: "|", with: "").utf16)
        let edit = try #require(LaTeXFormatter.edit(in: text, selection: cursor..<cursor))
        #expect(edit.range == 20..<20)
        #expect(edit.replacement == "  ")
        // Der Cursor bleibt zwischen „Te“ und „xt“.
        #expect(edit.selectionAfter == (cursor + 2)..<(cursor + 2))
    }

    @Test func selectionFormatsOnlySelectedLines() throws {
        let string = "\\begin{itemize}\n\\item a\n\\item b\n\\end{itemize}\n"
        let text = Array(string.utf16)
        // Nur die zweite Zeile („\item a“) auswählen.
        let start = (string as NSString).range(of: "\\item a").location
        let edit = try #require(LaTeXFormatter.edit(in: text, selection: start..<(start + 3)))
        let result = (string as NSString).replacingCharacters(in: NSRange(location: edit.range.lowerBound, length: edit.range.count), with: edit.replacement)
        #expect(result == "\\begin{itemize}\n  \\item a\n\\item b\n\\end{itemize}\n")
    }

    @Test func templatesAreAlreadyTidy() {
        // Eine neue Vorlage ist schon formatiert: ⌥⌘L ändert daran nichts.
        for template in DocumentTemplate.all {
            #expect(formatted(template.text) == template.text, "\(template.id) ist nicht formatiert")
        }
    }
}
