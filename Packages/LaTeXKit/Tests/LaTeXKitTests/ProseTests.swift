import Foundation
import Testing
@testable import LaTeXKit

/// Alle Wörter im Fliesstext, in der Reihenfolge des Textes.
private func proseWords(_ string: String) -> [String] {
    let text = Array(string.utf16)
    let ranges = ProseScanner.proseRanges(in: text, tokenized: LaTeXTokenizer.tokenize(text))
    return ranges.flatMap { range in
        text.string(in: range)
            .components(separatedBy: CharacterSet.letters.inverted)
            .filter { !$0.isEmpty }
    }
}

private func count(_ string: String, selection: Range<Int>? = nil) -> WordCount {
    let text = Array(string.utf16)
    let tokenized = LaTeXTokenizer.tokenize(text)
    let prose = ProseScanner.proseRanges(in: text, tokenized: tokenized)
    return WordCounter.count(in: text, prose: prose, tokenized: tokenized, selection: selection)
}

@Suite("Fliesstext erkennen")
struct ProseScannerTests {
    @Test func skipsCommandsMathAndComments() {
        let words = proseWords(#"Ein \textbf{fettes} Wort, $\alpha + x$ und \[ y \] % Kommentar hier"#)
        #expect(words == ["Ein", "fettes", "Wort", "und"])
    }

    @Test func skipsTechnicalArguments() {
        let text = #"""
            \documentclass[a4paper,11pt]{scrartcl}
            \usepackage[ngerman]{babel}
            \newcommand{\R}{\mathbb{R}}
            \newtheorem{satz}{Satz}[section]
            \begin{document}
            \section{Einleitung}\label{sec:einleitung}
            Siehe \ref{fig:kreis} und \cite[S.~5]{knuth}.
            \begin{figure}[htbp]
              \includegraphics[width=0.8\textwidth]{bilder/kreis.png}
              \caption{Ein Kreis}
            \end{figure}
            \begin{tabular}{lcr} Zelle \\[2pt] \end{tabular}
            \href{https://example.org}{Webseite} \textcolor{red}{rot}
            \vspace*{1cm} Ende
            \end{document}
            """#
        #expect(proseWords(text) == ["Einleitung", "Siehe", "und", "Ein", "Kreis", "Zelle", "Webseite", "rot", "Ende"])
    }

    @Test func proseOptionalArgumentsAndVerbatim() {
        let text = "\\item[Begriff] Erklärung \\verb|code hier| weiter\n\\begin{verbatim}\nnicht prüfen\n\\end{verbatim}\nZum Schluss"
        #expect(proseWords(text) == ["Begriff", "Erklärung", "weiter", "Zum", "Schluss"])
    }
}

@Suite("Wortzählung")
struct WordCountTests {
    @Test func countsOnlyTheBody() {
        let text = "\\documentclass{article}\n\\title{Titel hier}\n\\begin{document}\nDas ist ein Test mit $x^2$ Formel.\n\\[ a = b \\]\n\\end{document}\nNachher"
        let result = count(text)
        #expect(result.words == 6)
        #expect(result.formulas == 2)
        #expect(result.characters == "DasisteinTestmitFormel.".count)
    }

    @Test func hyphenatedWordsCountOnce() {
        #expect(count("Lern-Software geht's -- gut").words == 3)
    }

    @Test func selectionCountsPart() {
        let text = "Eins zwei drei vier"
        #expect(count(text, selection: 5..<14).words == 2)
    }

    @Test func emptyDocument() {
        #expect(count("").words == 0)
        #expect(count("\\begin{document}\n\\end{document}").words == 0)
    }
}
