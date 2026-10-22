import Foundation

/// Welche Engine übersetzt das Dokument?
public enum EngineKind: String, Sendable, CaseIterable, Codable, Identifiable {
    /// Tectonic: eigenständig, lädt fehlende Pakete automatisch (Standard).
    case tectonic
    /// latexmk aus einer vorhandenen MacTeX-Installation (pdfLaTeX).
    case latexmk

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .tectonic: return "Tectonic"
        case .latexmk: return "latexmk (MacTeX)"
        }
    }
}

/// Ein Auftrag zum Übersetzen.
///
/// Übersetzt wird immer der aktuelle Text aus dem Editor – auch wenn das
/// Dokument noch nicht gesichert ist. Er wird dazu in einen eigenen
/// Arbeitsordner geschrieben, damit neben der `.tex`-Datei des Nutzers keine
/// Hilfsdateien (`.aux`, `.log`, …) entstehen. Bilder und `\input`-Dateien
/// werden trotzdem im Ordner des Dokuments gefunden (`documentDirectory`).
public struct CompileJob: Sendable {
    public var source: String
    public var buildDirectory: URL
    public var documentDirectory: URL?
    public var mainFileName: String

    public init(source: String, buildDirectory: URL, documentDirectory: URL?, mainFileName: String = "main.tex") {
        self.source = source
        self.buildDirectory = buildDirectory
        self.documentDirectory = documentDirectory
        self.mainFileName = mainFileName
    }

    public var sourceURL: URL { buildDirectory.appendingPathComponent(mainFileName) }
    public var baseName: String { (mainFileName as NSString).deletingPathExtension }
    public var pdfURL: URL { buildDirectory.appendingPathComponent(baseName + ".pdf") }
    public var logURL: URL { buildDirectory.appendingPathComponent(baseName + ".log") }

    /// SyncTeX-Datei, komprimiert (`.synctex.gz`) oder unkomprimiert.
    public var synctexURL: URL? {
        let fm = FileManager.default
        for name in [baseName + ".synctex.gz", baseName + ".synctex"] {
            let url = buildDirectory.appendingPathComponent(name)
            if fm.fileExists(atPath: url.path) { return url }
        }
        return nil
    }

    /// Legt den Arbeitsordner an, schreibt den Quelltext und entfernt alte Ergebnisse.
    func prepare() throws {
        let fm = FileManager.default
        try fm.createDirectory(at: buildDirectory, withIntermediateDirectories: true)
        for url in [pdfURL, logURL,
                    buildDirectory.appendingPathComponent(baseName + ".synctex.gz"),
                    buildDirectory.appendingPathComponent(baseName + ".synctex")] {
            try? fm.removeItem(at: url)
        }
        try source.write(to: sourceURL, atomically: true, encoding: .utf8)
    }
}

/// Ergebnis eines Übersetzungslaufs.
public struct CompileOutput: Sendable {
    public var engine: EngineKind
    /// `true`, wenn ein neues PDF ohne Fehler entstanden ist.
    public var succeeded: Bool
    public var pdfURL: URL?
    public var synctexURL: URL?
    /// Inhalt der `.log`-Datei (kann leer sein, wenn LaTeX gar nicht starten konnte).
    public var log: String
    /// Konsolenausgabe des Programms.
    public var console: String
    public var issues: [CompileIssue]
    public var duration: TimeInterval

    public init(engine: EngineKind, succeeded: Bool, pdfURL: URL?, synctexURL: URL?, log: String, console: String, issues: [CompileIssue], duration: TimeInterval) {
        self.engine = engine
        self.succeeded = succeeded
        self.pdfURL = pdfURL
        self.synctexURL = synctexURL
        self.log = log
        self.console = console
        self.issues = issues
        self.duration = duration
    }

    public var errors: [CompileIssue] { issues.filter { $0.severity == .error } }
}

/// Gemeinsame Schnittstelle aller Engines.
public protocol TeXEngine: Sendable {
    var kind: EngineKind { get }
    /// Übersetzt den Auftrag. Bricht ab (und beendet den Prozess), wenn die Task abgebrochen wird.
    /// - Parameter progress: Kurze Statusmeldungen, z. B. „Lade amsmath.sty …“.
    func compile(_ job: CompileJob, progress: (@Sendable (String) -> Void)?) async throws -> CompileOutput
}

// MARK: - Tectonic

public struct TectonicEngine: TeXEngine {
    public let executableURL: URL
    public var kind: EngineKind { .tectonic }

    public init(executableURL: URL) {
        self.executableURL = executableURL
    }

    func arguments(for job: CompileJob) -> [String] {
        var arguments = [
            "--synctex",
            "--keep-logs",
            "--color", "never",
            "--outdir", job.buildDirectory.path,
            // Tectonic nimmt sonst US-Letter als Standard-Papierformat.
            "-Z", "paper-size=a4"
        ]
        if let directory = job.documentDirectory {
            // Bilder und \input-Dateien im Ordner des Dokuments finden.
            arguments += ["-Z", "search-path=\(directory.path)"]
        }
        arguments.append(job.mainFileName)
        return arguments
    }

    public func compile(_ job: CompileJob, progress: (@Sendable (String) -> Void)?) async throws -> CompileOutput {
        let start = Date()
        try job.prepare()
        let result = try await ProcessRunner.run(
            executable: executableURL,
            arguments: arguments(for: job),
            currentDirectory: job.buildDirectory,
            onOutputLine: { line in
                if let message = TectonicEngine.progressMessage(for: line) { progress?(message) }
            }
        )
        let console = result.standardOutput + result.standardError
        let log = (try? String(contentsOf: job.logURL, encoding: .utf8))
            ?? (try? String(contentsOf: job.logURL, encoding: .isoLatin1))
            ?? ""
        var issues = TeXLogParser.parse(log: log)
        // Die Konsole meldet Dinge, die nicht im Log stehen (z. B. Netzwerkprobleme).
        let consoleIssues = TeXLogParser.parse(tectonicConsole: console)
        if issues.filter({ $0.severity == .error }).isEmpty {
            issues += consoleIssues.filter { $0.severity == .error }
        }
        let pdfExists = FileManager.default.fileExists(atPath: job.pdfURL.path)
        if result.exitCode != 0 && issues.allSatisfy({ $0.severity != .error }) {
            issues.append(CompileIssue(severity: .error, message: Self.lastMeaningfulLine(of: console) ?? "Tectonic wurde mit Fehlercode \(result.exitCode) beendet."))
        }
        let succeeded = result.exitCode == 0 && pdfExists
        return CompileOutput(
            engine: .tectonic,
            succeeded: succeeded,
            pdfURL: pdfExists ? job.pdfURL : nil,
            synctexURL: job.synctexURL,
            log: log,
            console: console,
            issues: issues,
            duration: Date().timeIntervalSince(start)
        )
    }

    /// Übersetzt Tectonic-Statusmeldungen in kurze deutsche Hinweise.
    static func progressMessage(for line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("note: downloading ") {
            let file = trimmed.dropFirst("note: downloading ".count)
            return "Lade \(file) …"
        }
        if trimmed.hasPrefix("note: Running TeX") { return "Setze Dokument …" }
        if trimmed.hasPrefix("note: Rerunning TeX") { return "Setze erneut (Verweise) …" }
        if trimmed.hasPrefix("note: Running xdvipdfmx") { return "Erzeuge PDF …" }
        return nil
    }

    static func lastMeaningfulLine(of console: String) -> String? {
        console.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .last { !$0.isEmpty && !$0.hasPrefix("note:") && !$0.hasPrefix("stack backtrace") && !$0.first!.isNumber }
    }
}

// MARK: - latexmk

public struct LatexmkEngine: TeXEngine {
    public let executableURL: URL
    public var kind: EngineKind { .latexmk }

    public init(executableURL: URL) {
        self.executableURL = executableURL
    }

    func arguments(for job: CompileJob) -> [String] {
        [
            "-pdf",
            "-synctex=1",
            "-interaction=nonstopmode",
            "-file-line-error",
            "-outdir=\(job.buildDirectory.path)",
            job.mainFileName
        ]
    }

    func environment(for job: CompileJob) -> [String: String] {
        var environment = ProcessInfo.processInfo.environment
        // Programme der TeX-Distribution (pdflatex, bibtex …) müssen im PATH liegen.
        let binDirectory = executableURL.deletingLastPathComponent().path
        environment["PATH"] = [binDirectory, "/Library/TeX/texbin", environment["PATH"] ?? "/usr/bin:/bin"].joined(separator: ":")
        if let directory = job.documentDirectory {
            // Der abschliessende Doppelpunkt hängt die Standard-Suchpfade an.
            environment["TEXINPUTS"] = directory.path + ":"
            environment["BIBINPUTS"] = directory.path + ":"
        }
        return environment
    }

    public func compile(_ job: CompileJob, progress: (@Sendable (String) -> Void)?) async throws -> CompileOutput {
        let start = Date()
        try job.prepare()
        progress?("Setze Dokument mit latexmk …")
        let result = try await ProcessRunner.run(
            executable: executableURL,
            arguments: arguments(for: job),
            currentDirectory: job.buildDirectory,
            environment: environment(for: job)
        )
        let console = result.standardOutput + result.standardError
        let log = (try? String(contentsOf: job.logURL, encoding: .utf8))
            ?? (try? String(contentsOf: job.logURL, encoding: .isoLatin1))
            ?? ""
        var issues = TeXLogParser.parse(log: log)
        if result.exitCode != 0 && issues.allSatisfy({ $0.severity != .error }) {
            issues.append(CompileIssue(severity: .error, message: "latexmk wurde mit Fehlercode \(result.exitCode) beendet."))
        }
        let pdfExists = FileManager.default.fileExists(atPath: job.pdfURL.path)
        return CompileOutput(
            engine: .latexmk,
            succeeded: result.exitCode == 0 && pdfExists,
            pdfURL: pdfExists ? job.pdfURL : nil,
            synctexURL: job.synctexURL,
            log: log,
            console: console,
            issues: issues,
            duration: Date().timeIntervalSince(start)
        )
    }
}

// MARK: - Suche nach installierten Programmen

public enum EngineLocator {
    /// Übliche Orte für ein bereits installiertes Tectonic (Homebrew).
    public static let tectonicCandidates = [
        "/opt/homebrew/bin/tectonic",
        "/usr/local/bin/tectonic"
    ]

    /// Übliche Orte für latexmk (MacTeX legt `/Library/TeX/texbin` an).
    public static let latexmkCandidates = [
        "/Library/TeX/texbin/latexmk",
        "/opt/homebrew/bin/latexmk",
        "/usr/local/bin/latexmk",
        "/usr/bin/latexmk"
    ]

    /// Erster ausführbarer Pfad aus der Liste.
    public static func firstExecutable(in candidates: [String]) -> URL? {
        let fm = FileManager.default
        return candidates.first { fm.isExecutableFile(atPath: $0) }.map { URL(fileURLWithPath: $0) }
    }
}
