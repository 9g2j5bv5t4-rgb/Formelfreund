import Foundation
import Testing
@testable import LaTeXKit

@Suite("Fehler erklären und beheben")
struct ErrorAdvisorTests {
    /// Erster Fehler aus einem echten Log samt Quelltext.
    private func firstError(_ name: String) throws -> (issue: CompileIssue, source: String) {
        let issue = try #require(TeXLogParser.parse(log: fixture("logs/\(name).log")).first { $0.severity == .error })
        return (issue, try fixture("logs/\(name).tex"))
    }

    private func advice(_ name: String) throws -> (advice: IssueAdvice, issue: CompileIssue, source: String) {
        let (issue, source) = try firstError(name)
        let advice = try #require(ErrorAdvisor.advice(for: issue, lines: source.components(separatedBy: "\n")))
        return (advice, issue, source)
    }

    private func applying(_ fix: QuickFix, to source: String) -> String? {
        guard let edit = ErrorAdvisor.edit(applying: fix, in: Array(source.utf16)) else { return nil }
        return (source as NSString).replacingCharacters(
            in: NSRange(location: edit.range.lowerBound, length: edit.range.count), with: edit.replacement)
    }

    @Test("Jeder Fehler aus den Beispiel-Logs bekommt eine Erklärung", arguments: [
        "undefined_command", "unknown_env", "mismatched_end", "missing_package", "misplaced_ampersand",
        "missing_item", "double_superscript", "extra_brace", "missing_brace", "missing_dollar", "missing_file",
        "unclosed_env", "display_unclosed"
    ])
    func everyFixtureIsExplained(name: String) throws {
        let result = try advice(name)
        #expect(!result.advice.explanation.isEmpty)
        #expect(!result.advice.suggestion.isEmpty)
        #expect(!result.advice.explanation.contains("ß") && !result.advice.suggestion.contains("ß"))
    }

    @Test("Falsches \\end wird korrigiert")
    func mismatchedEnd() throws {
        let result = try advice("mismatched_end")
        let fix = try #require(result.advice.fix)
        #expect(fix.title == "\\end{enumerate} durch \\end{itemize} ersetzen")
        let fixed = try #require(applying(fix, to: result.source))
        #expect(fixed.contains("\\item a\n\\end{itemize}\n\\end{document}"))
    }

    @Test("Tippfehler in einer Umgebung: beide Enden umbenennen")
    func misspelledEnvironment() throws {
        let result = try advice("unknown_env")
        #expect(result.advice.suggestion == "Meintest du „align“?")
        let fix = try #require(result.advice.fix)
        let fixed = try #require(applying(fix, to: result.source))
        #expect(fixed.contains("\\begin{align} a &= b \\end{align}"))
    }

    @Test("& im Text wird zu \\&")
    func ampersand() throws {
        let result = try advice("misplaced_ampersand")
        let fix = try #require(result.advice.fix)
        let fixed = try #require(applying(fix, to: result.source))
        #expect(fixed.contains("a \\& b"))
    }

    @Test("Unbekannte Befehle: Paket laden, Abkürzung ersetzen, Tippfehler erkennen")
    func undefinedCommands() throws {
        func advise(_ context: String, line: Int = 4) -> IssueAdvice? {
            ErrorAdvisor.advice(for: CompileIssue(severity: .error, message: "Undefined control sequence.", contextBefore: context, line: line))
        }
        let mathbb = try #require(advise("Die Menge $\\mathbb"))
        #expect(mathbb.fix == .loadPackage(PackageRequirement("amssymb")))
        let source = "\\documentclass{article}\n\\usepackage{amsmath}\n\\begin{document}\n$\\mathbb{R}$\n\\end{document}\n"
        let packageFix = try #require(mathbb.fix)
        let loaded = try #require(applying(packageFix, to: source))
        #expect(loaded.contains("\\usepackage{amsmath}\n\\usepackage{amssymb}\n"))

        let reals = try #require(advise("$x \\in \\R"))
        #expect(reals.fix == .replace(line: 4, old: "\\R", new: "\\mathbb{R}"))
        let realsSource = "\\documentclass{article}\n\\begin{document}\n\n$x \\in \\R$ und \\Rightarrow\n\\end{document}\n"
        let realsFix = try #require(reals.fix)
        #expect(applying(realsFix, to: realsSource)?.contains("$x \\in \\mathbb{R}$ und \\Rightarrow") == true)

        let typo = try #require(advise("$\\alpah"))
        #expect(typo.suggestion == "Meintest du \\alpha?")
        let unknown = try #require(advise("Text \\foo"))
        #expect(unknown.fix == nil)
    }

    @Test("Theorem-Umgebungen werden in der Präambel definiert")
    func theoremEnvironment() throws {
        let advice = try #require(ErrorAdvisor.advice(for: CompileIssue(severity: .error, message: "LaTeX Error: Environment satz undefined.", line: 4)))
        let fix = try #require(advice.fix)
        #expect(fix.title == "In der Präambel definieren")
        let source = "\\documentclass{article}\n\\begin{document}\n\\begin{satz}\nX\n\\end{satz}\n\\end{document}\n"
        let fixed = try #require(applying(fix, to: source))
        #expect(fixed.contains("\\newtheorem{satz}"))
    }

    @Test("Abstand zwischen Wörtern")
    func distance() {
        #expect(ErrorAdvisor.editDistance("alpah", "alpha") == 1)
        #expect(ErrorAdvisor.editDistance("", "abc") == 3)
        #expect(ErrorAdvisor.editDistance("frac", "frac") == 0)
        #expect(ErrorAdvisor.closestKnownCommand(to: "\\sqtr") == nil || ErrorAdvisor.closestKnownCommand(to: "\\sqtr") == "\\sqrt")
        #expect(ErrorAdvisor.closestKnownCommand(to: "\\fracc") == "\\frac")
    }
}
