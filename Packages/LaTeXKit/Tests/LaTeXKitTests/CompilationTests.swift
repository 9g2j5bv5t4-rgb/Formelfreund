import Foundation
import Testing
@testable import LaTeXKit

/// Lädt eine Testdatei aus `Fixtures/`.
func fixture(_ path: String) throws -> String {
    let url = try #require(Bundle.module.url(forResource: "Fixtures/" + path, withExtension: nil))
    return try String(contentsOf: url, encoding: .utf8)
}

func fixtureData(_ path: String) throws -> Data {
    let url = try #require(Bundle.module.url(forResource: "Fixtures/" + path, withExtension: nil))
    return try Data(contentsOf: url)
}

@Suite("Log-Auswertung (echte XeLaTeX-Logs)")
struct LogParserTests {
    private func errors(_ name: String) throws -> [CompileIssue] {
        try TeXLogParser.parse(log: fixture("logs/\(name).log")).filter { $0.severity == .error }
    }

    @Test func undefinedCommand() throws {
        let issues = try errors("undefined_command")
        #expect(issues.count == 1)
        #expect(issues[0].message == "Undefined control sequence.")
        #expect(issues[0].line == 4)
        #expect(issues[0].contextBefore == "Text \\foo")
        #expect(issues[0].contextAfter == "{x}.")
        #expect(issues[0].file?.hasSuffix("undefined_command.tex") == true)
    }

    @Test func missingDollar() throws {
        let issues = try errors("missing_dollar")
        #expect(issues.first?.message == "Missing $ inserted.")
        #expect(issues.first?.line == 4)
    }

    @Test func latexErrorsWithHelpText() throws {
        let issues = try errors("mismatched_end")
        #expect(issues.count == 1)
        #expect(issues[0].message == "LaTeX Error: \\begin{itemize} on input line 4 ended by \\end{enumerate}.")
        #expect(issues[0].line == 6)
    }

    @Test func unknownEnvironment() throws {
        let issues = try errors("unknown_env")
        #expect(issues.map(\.message).contains("LaTeX Error: Environment allign undefined."))
        #expect(issues.allSatisfy { $0.line == 4 })
    }

    @Test func missingPackage() throws {
        let issues = try errors("missing_package")
        #expect(issues.map(\.message) == ["LaTeX Error: File `nichtda.sty' not found."])
    }

    @Test func emergencyStopIsSkipped() throws {
        let issues = try errors("unclosed_env")
        #expect(issues.map(\.message) == ["LaTeX Error: \\begin{align} on input line 4 ended by \\end{document}."])
        #expect(issues[0].line == 5)
    }

    @Test func warningsAndBadBoxes() throws {
        let warnings = try TeXLogParser.parse(log: fixture("logs/undefined_ref.log")).filter { $0.severity == .warning }
        #expect(warnings.map(\.message) == [
            "Reference `fig:x' on page 1 undefined on input line 4.",
            "Citation `knuth' on page 1 undefined on input line 4."
        ])
        #expect(warnings.allSatisfy { $0.line == 4 })

        let badBoxes = try TeXLogParser.parse(log: fixture("logs/overfull.log")).filter { $0.severity == .badBox }
        #expect(badBoxes.count == 1)
        #expect(badBoxes[0].line == 4)
    }

    @Test func fileLineErrorStyle() throws {
        let issues = try TeXLogParser.parse(log: fixture("logs/pdflatex_file_line_error.log")).filter { $0.severity == .error }
        #expect(issues.count == 1)
        #expect(issues[0].file == "./main.tex")
        #expect(issues[0].line == 9)
        #expect(issues[0].message == "Undefined control sequence.")
        #expect(issues[0].contextBefore == "\\foo")
    }

    @Test func allFixturesHaveLineNumbersForErrors() throws {
        // Ausnahme: „File ended while scanning use of \\frac“ (missing_brace) nennt keine
        // Zeile – TeX merkt den Fehler erst am Dateiende.
        let names = ["undefined_command", "missing_dollar", "extra_brace", "unknown_env",
                     "mismatched_end", "misplaced_ampersand", "double_superscript", "missing_item",
                     "unclosed_env", "display_unclosed", "missing_file"]
        for name in names {
            let issues = try errors(name)
            #expect(!issues.isEmpty, "\(name): keine Fehler gefunden")
            #expect(issues.contains { $0.line != nil }, "\(name): keine Zeilennummer")
        }
    }

    @Test func tectonicConsole() {
        let console = """
        note: Running TeX ...
        error: main.tex:9: Undefined control sequence
        warning: main.tex:12: Overfull \\hbox (3.0pt too wide) in paragraph at lines 12--12
        error: halted on potentially-recoverable error as specified
        """
        let issues = TeXLogParser.parse(tectonicConsole: console)
        #expect(issues.count == 2)
        #expect(issues[0].severity == .error)
        #expect(issues[0].line == 9)
        #expect(issues[0].file == "main.tex")
        #expect(issues[0].message == "Undefined control sequence")
    }

    @Test func tectonicProgressMessages() {
        #expect(TectonicEngine.progressMessage(for: "note: downloading amsmath.sty") == "Lade amsmath.sty …")
        #expect(TectonicEngine.progressMessage(for: "irgendwas") == nil)
    }
}

@Suite("SyncTeX (echte XeLaTeX-Daten)")
struct SyncTeXTests {
    // Quelle: Fixtures/synctex/main.tex
    //   Zeile 5: „Erste Zeile Text.“   (laut pdftotext: x ab 124.80 pt, y 149.6–159.5 pt von oben)
    //   Zeile 7: „Zweiter Absatz hier.“ (y 161.5–171.5 pt)
    //   Zeile 8: \[ a^2 + b^2 = c^2 \]
    // TeX ordnet die Box einer Absatzzeile der Zeile zu, in der der Absatz endet
    // (Zeile 6 bzw. 8); die Einträge *in* der Box tragen die genauen Zeilen.

    @Test func parsesHeaderAndInputs() throws {
        let index = try #require(SyncTeXIndex(text: fixture("synctex/xelatex.synctex")))
        #expect(index.tag(forFileNamed: "main.tex") == 1)
        #expect(!index.records.isEmpty)
    }

    @Test func forwardSearchMatchesPDFText() throws {
        let index = try #require(SyncTeXIndex(text: fixture("synctex/xelatex.synctex")))
        let box = try #require(index.forwardSearch(line: 6, fileName: "main.tex"))
        #expect(box.page == 1)
        #expect(abs(box.x - 124.80) < 0.5)
        #expect(box.y <= 152)
        #expect(box.y + box.height >= 157)

        let text = try #require(index.forwardSearch(line: 5, fileName: "main.tex"))
        #expect(text.page == 1)
        #expect(text.y > 140 && text.y < 160)
    }

    @Test func backwardSearchFindsLines() throws {
        let index = try #require(SyncTeXIndex(text: fixture("synctex/xelatex.synctex")))
        // Klick auf „Erste“
        #expect(index.backwardSearch(page: 1, x: 130, y: 155)?.line == 5)
        // Klick auf „Zweiter“
        #expect(index.backwardSearch(page: 1, x: 150, y: 167)?.line == 7)
        // Klick auf die Formel in der Mitte der Seite
        let formula = index.backwardSearch(page: 1, x: 290, y: 180)
        #expect(formula?.line == 8)
        #expect(formula.map { ($0.file as NSString).lastPathComponent } == "main.tex")
    }

    @Test func unknownLineFallsBackToNearbyLine() throws {
        let index = try #require(SyncTeXIndex(text: fixture("synctex/xelatex.synctex")))
        // Zeile 3 (\begin{document}) erzeugt keine Box → nächste Zeile mit Inhalt.
        #expect(index.forwardSearch(line: 3, fileName: "main.tex")?.page == 1)
    }

    @Test func gzipHeaderIsStripped() throws {
        let data = try fixtureData("synctex/xelatex.synctex.gz")
        let payload = try #require(Gzip.deflatePayload(of: data))
        #expect(payload.count < data.count)
        #expect(payload.count > 100)
        let text = try fixture("synctex/xelatex.synctex")
        #expect(Gzip.uncompressedSize(of: data) == text.utf8.count)
        #expect(Gzip.deflatePayload(of: Data("kein gzip".utf8)) == nil)
    }
}

// Nacheinander: Unter Linux erben parallel gestartete Kindprozesse fremde
// Pipe-Enden (macOS verhindert das), was die Tests dort ausbremsen würde.
@Suite("Externe Programme", .serialized)
struct ProcessRunnerTests {
    @Test func capturesOutputAndExitCode() async throws {
        let result = try await ProcessRunner.run(
            executable: URL(fileURLWithPath: "/bin/sh"),
            arguments: ["-c", "echo hallo; echo fehler >&2; exit 3"]
        )
        #expect(result.exitCode == 3)
        #expect(result.standardOutput == "hallo\n")
        #expect(result.standardError == "fehler\n")
    }

    @Test func largeOutputDoesNotBlock() async throws {
        let result = try await ProcessRunner.run(
            executable: URL(fileURLWithPath: "/bin/sh"),
            arguments: ["-c", "i=0; while [ $i -lt 20000 ]; do echo Zeile $i; i=$((i+1)); done"]
        )
        #expect(result.standardOutput.split(separator: "\n").count == 20000)
    }

    @Test func reportsLines() async throws {
        let collector = LineCollector()
        _ = try await ProcessRunner.run(
            executable: URL(fileURLWithPath: "/bin/sh"),
            arguments: ["-c", "echo a; echo b"],
            onOutputLine: { collector.add($0) }
        )
        #expect(collector.lines == ["a", "b"])
    }

    @Test func cancellationTerminatesProcess() async throws {
        let task = Task {
            try await ProcessRunner.run(executable: URL(fileURLWithPath: "/bin/sleep"), arguments: ["30"])
        }
        try await Task.sleep(for: .milliseconds(200))
        let clock = ContinuousClock()
        let start = clock.now
        task.cancel()
        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(clock.now - start < .seconds(5))
    }

    @Test func missingExecutableThrows() async {
        await #expect(throws: ProcessRunner.RunError.self) {
            try await ProcessRunner.run(executable: URL(fileURLWithPath: "/gibt/es/nicht"), arguments: [])
        }
    }
}

final class LineCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String] = []
    func add(_ line: String) { lock.withLock { storage.append(line) } }
    var lines: [String] { lock.withLock { storage } }
}
