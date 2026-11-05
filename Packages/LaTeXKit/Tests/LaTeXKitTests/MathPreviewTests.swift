import Foundation
import Testing
@testable import LaTeXKit

private func previewRequest(_ string: String, at marker: String) -> MathPreviewRequest? {
    let text = Array(string.utf16)
    let position = (string as NSString).range(of: marker).location
    let tokenized = LaTeXTokenizer.tokenize(text)
    guard let region = tokenized.mathRegion(containing: position) else { return nil }
    return MathPreviewSource.request(for: region, in: text, macros: MathPreviewSource.macros(in: text))
}

@Suite("Formelvorschau")
struct MathPreviewTests {
    @Test func inlineAndDisplay() throws {
        let inline = try #require(previewRequest("Es gilt $a^2 + b^2$ hier.", at: "a^2"))
        #expect(inline.tex == "a^2 + b^2")
        #expect(!inline.display)
        let display = try #require(previewRequest("\\[ \\frac{1}{2} \\]", at: "frac"))
        #expect(display.tex == "\\frac{1}{2}")
        #expect(display.display)
    }

    @Test func environmentsArePassedWhole() throws {
        let request = try #require(previewRequest("\\begin{align*}\n  x &= 1 \\\\\n  y &= 2\n\\end{align*}", at: "x &="))
        #expect(request.tex == "\\begin{align*}\n  x &= 1 \\\\\n  y &= 2\n\\end{align*}")
        #expect(request.display)
    }

    @Test func emptyFormulaHasNoPreview() {
        #expect(previewRequest("Text $ $ weiter", at: " $ w") == nil)
    }

    @Test func onlyUsedMacrosAreIncluded() throws {
        let text = """
            \\newcommand{\\R}{\\mathbb{R}}
            \\newcommand\\N{\\mathbb{N}}
            \\newcommand{\\abs}[1]{\\left|#1\\right|}
            \\newcommand{\\norm}[1]{\\abs{#1}_2}
            \\DeclareMathOperator{\\Bild}{Bild}
            \\DeclareMathOperator*{\\argmax}{arg\\,max}
            % \\newcommand{\\Kommentar}{nicht}
            \\def\\eps{\\varepsilon}
            Formel: $\\norm{x} \\in \\R, \\Bild f, \\eps, \\Rightarrow$
            """
        let macros = MathPreviewSource.macros(in: Array(text.utf16))
        #expect(macros.map(\.name) == ["R", "N", "abs", "norm", "Bild", "argmax", "eps"])
        #expect(macros[1].definition == "\\newcommand{\\N}{\\mathbb{N}}")
        #expect(macros[4].definition == "\\newcommand{\\Bild}{\\operatorname{Bild}}")
        #expect(macros[5].definition == "\\newcommand{\\argmax}{\\operatorname*{arg\\,max}}")
        let request = try #require(previewRequest(text, at: "\\norm{x}"))
        // \norm braucht \abs; \Rightarrow ist nicht \R; \N und \argmax kommen nicht vor.
        #expect(request.tex.hasPrefix("\\newcommand{\\R}{\\mathbb{R}} \\newcommand{\\abs}[1]{\\left|#1\\right|} \\newcommand{\\norm}[1]{\\abs{#1}_2} \\newcommand{\\Bild}{\\operatorname{Bild}} \\def\\eps{\\varepsilon} "))
        #expect(request.tex.hasSuffix("\\norm{x} \\in \\R, \\Bild f, \\eps, \\Rightarrow"))
    }
}

@Suite("Vorlagen")
struct TemplateTests {
    @Test func everyTemplateIsACompleteDocument() {
        #expect(DocumentTemplate.all.count == 7)
        #expect(Set(DocumentTemplate.all.map(\.id)).count == 7)
        for template in DocumentTemplate.all {
            let text = template.text
            #expect(text.hasPrefix("\\documentclass"), "\(template.id)")
            #expect(text.contains("\\begin{document}"), "\(template.id)")
            #expect(text.hasSuffix("\\end{document}\n"), "\(template.id)")
            #expect(!text.contains("\t"), "\(template.id)")
            // Keine Platzhalter-Zeichen aus Bausteinen.
            #expect(!text.contains(Placeholders.marker), "\(template.id)")
        }
    }

    @Test func exerciseSheetHasHeaderFields() {
        let text = DocumentTemplate.exercise.text
        #expect(text.contains("\\newcommand{\\matrikel}{12345678}"))
        #expect(text.contains("\\begin{enumerate}[label=(\\alph*)]"))
    }
}
