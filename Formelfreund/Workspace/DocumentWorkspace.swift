import AppKit
import LaTeXKit
import Observation
import PDFKit
import UniformTypeIdentifiers

/// Zustand und Abläufe eines Dokumentfensters – die „Schaltzentrale“.
///
/// Hier laufen die Fäden zusammen: Text ändert sich → nach einer Tipp-Pause
/// kompilieren → PDF und Meldungen anzeigen → Sprünge zwischen Quelltext und
/// PDF. Die Ansichten (SwiftUI) lesen nur den Zustand und rufen Methoden auf;
/// sie enthalten selbst keine Logik.
@MainActor
@Observable
final class DocumentWorkspace {
    /// Zustand des Kompilierens, wie er in der Symbolleiste angezeigt wird.
    enum CompileStatus: Equatable {
        /// Noch nie kompiliert.
        case idle
        /// Tectonic wird beim ersten Mal eingerichtet.
        case preparingEngine
        case compiling
        case succeeded(duration: TimeInterval)
        case failed
        /// Es gibt keine startklare LaTeX-Engine (z. B. Download fehlgeschlagen).
        case engineUnavailable(String)
    }

    let document: TeXDocument
    let engines: EngineManager

    /// Speicherort der `.tex`-Datei (nil, solange das Dokument nicht gesichert ist).
    var fileURL: URL?

    private(set) var status: CompileStatus = .idle
    /// Kurze Fortschrittsmeldung während des Kompilierens („Lade amsmath.sty …“).
    private(set) var progressMessage: String?
    /// Meldungen des letzten Laufs, die zum Dokument gehören.
    private(set) var issues: [CompileIssue] = []
    /// Das zuletzt erfolgreich erzeugte PDF.
    private(set) var pdfDocument: PDFDocument?
    private(set) var pdfData: Data?
    /// Zählt hoch, sobald ein neues PDF da ist (damit die Vorschau es übernimmt).
    private(set) var pdfRevision = 0
    /// Ist das angezeigte PDF älter als der Quelltext (letzter Lauf fehlgeschlagen)?
    private(set) var isPDFOutdated = false
    private(set) var syncTeX: SyncTeXIndex?
    /// Inhalt des LaTeX-Protokolls (`.log`) des letzten Laufs.
    private(set) var lastLog: String?
    /// Gliederung für die Seitenleiste (vom Editor im Hintergrund berechnet).
    private(set) var outline: DocumentOutline = .empty

    /// PDF-Vorschau sichtbar? Wird für neue Fenster gemerkt.
    var showsPreview: Bool {
        get { previewVisible }
        set {
            previewVisible = newValue
            UserDefaults.standard.set(newValue, forKey: AppSettings.Keys.showPreview)
        }
    }
    private var previewVisible = UserDefaults.standard.bool(forKey: AppSettings.Keys.showPreview)
    /// Protokoll-Fenster sichtbar?
    var isShowingLog = false

    @ObservationIgnored weak var editor: (any EditorControlling)?
    @ObservationIgnored weak var pdfViewer: (any PDFViewerControlling)?
    @ObservationIgnored private var compileTask: Task<Void, Never>?
    @ObservationIgnored private var autoCompileTask: Task<Void, Never>?
    @ObservationIgnored private var hasEdits = false

    /// Eigener Arbeitsordner für Hilfsdateien – wird erst beim ersten Kompilieren angelegt.
    private let buildDirectory: URL
    static let mainFileName = "main.tex"

    init(document: TeXDocument, fileURL: URL?, engines: EngineManager = .shared) {
        self.document = document
        self.fileURL = fileURL
        self.engines = engines
        buildDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Formelfreund", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: buildDirectory)
    }

    // MARK: - Abgeleitete Werte

    var errors: [CompileIssue] { issues.filter { $0.severity == .error } }
    var warnings: [CompileIssue] { issues.filter { $0.severity == .warning } }

    /// Für Zeilenmarkierungen im Editor: schwerste Meldung je Zeile.
    var issueSeverityByLine: [Int: CompileIssue.Severity] {
        var result: [Int: CompileIssue.Severity] = [:]
        for issue in issues where issue.severity != .badBox {
            guard let line = issue.line else { continue }
            if let existing = result[line], existing <= issue.severity { continue }
            result[line] = issue.severity
        }
        return result
    }

    var canSynchronize: Bool { syncTeX != nil && pdfDocument != nil }

    var isBusy: Bool {
        switch status {
        case .compiling, .preparingEngine: return true
        default: return false
        }
    }

    // MARK: - Rückmeldungen vom Editor

    /// Der Nutzer hat getippt.
    func textDidChange() {
        hasEdits = true
        scheduleAutoCompile()
    }

    /// Neue Gliederung aus der Hintergrund-Analyse.
    func update(outline newOutline: DocumentOutline) {
        if newOutline != outline { outline = newOutline }
    }

    // MARK: - Kompilieren

    /// Startet nach der eingestellten Tipp-Pause einen Lauf.
    func scheduleAutoCompile() {
        autoCompileTask?.cancel()
        guard AppSettings.autoCompile else { return }
        let delay = AppSettings.autoCompileDelay
        autoCompileTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            self?.compile()
        }
    }

    /// Kompiliert den aktuellen Text. Ein laufender Lauf wird abgebrochen,
    /// denn sein Ergebnis wäre ohnehin veraltet.
    func compile() {
        autoCompileTask?.cancel()
        compileTask?.cancel()
        let job = CompileJob(
            source: document.text,
            buildDirectory: buildDirectory,
            documentDirectory: fileURL?.deletingLastPathComponent(),
            mainFileName: Self.mainFileName
        )
        compileTask = Task { [weak self] in
            await self?.run(job)
        }
    }

    private func run(_ job: CompileJob) async {
        // 1. Engine bereitstellen (lädt Tectonic beim ersten Mal herunter).
        let engine: any TeXEngine
        do {
            if engines.needsSetup { status = .preparingEngine }
            engine = try await engines.engineForCompiling()
        } catch {
            if Task.isCancelled { return }
            status = .engineUnavailable(error.localizedDescription)
            return
        }
        guard !Task.isCancelled else { return }

        // 2. Übersetzen (läuft im Hintergrund, der Editor bleibt bedienbar).
        status = .compiling
        progressMessage = nil
        do {
            let output = try await engine.compile(job, progress: { message in
                Task { @MainActor in self.progressMessage = message }
            })
            guard !Task.isCancelled else { return }
            await apply(output)
        } catch is CancellationError {
            // Ein neuerer Lauf hat übernommen.
        } catch {
            guard !Task.isCancelled else { return }
            issues = [CompileIssue(severity: .error, message: error.localizedDescription)]
            status = .failed
            isPDFOutdated = pdfDocument != nil
        }
        progressMessage = nil
    }

    private func apply(_ output: CompileOutput) async {
        lastLog = output.log.isEmpty ? output.console : output.log
        issues = output.issues
            .filter { $0.belongs(toMainFile: Self.mainFileName) }
            .sorted { ($0.severity, $0.line ?? .max) < ($1.severity, $1.line ?? .max) }

        guard output.succeeded, let pdfURL = output.pdfURL else {
            status = .failed
            isPDFOutdated = pdfDocument != nil
            return
        }

        // PDF und SyncTeX im Hintergrund einlesen.
        let artifacts = await Self.loadArtifacts(pdf: pdfURL, synctex: output.synctexURL)
        guard !Task.isCancelled else { return }
        if let data = artifacts.pdf, let pdf = PDFDocument(data: data) {
            pdfData = data
            pdfDocument = pdf
            pdfRevision += 1
            isPDFOutdated = false
        }
        syncTeX = artifacts.syncTeX
        status = .succeeded(duration: output.duration)
    }

    private nonisolated static func loadArtifacts(pdf: URL, synctex: URL?) async -> (pdf: Data?, syncTeX: SyncTeXIndex?) {
        let data = try? Data(contentsOf: pdf)
        let index = synctex.flatMap(SyncTeXLoader.load(from:))
        return (data, index)
    }

    /// Nach fehlgeschlagener Einrichtung erneut versuchen.
    func retryEngineSetup() {
        engines.refresh()
        compile()
    }

    // MARK: - Navigation

    /// Springt im Editor zu einer Zeile.
    func reveal(line: Int) {
        editor?.reveal(line: line)
    }

    /// Springt zur ersten Fehlerstelle.
    func revealFirstError() {
        if let line = errors.first(where: { $0.line != nil })?.line {
            reveal(line: line)
        }
    }

    /// Vorwärtssuche: Zeile im Editor → Stelle im PDF.
    func showInPDF(line: Int) {
        guard let syncTeX, let position = syncTeX.forwardSearch(line: line, fileName: Self.mainFileName) else {
            NSSound.beep()
            return
        }
        if !showsPreview { showsPreview = true }
        pdfViewer?.reveal(position)
    }

    func showCursorInPDF() {
        guard let line = editor?.cursorLine else { return }
        showInPDF(line: line)
    }

    /// Rückwärtssuche: Klick im PDF → Zeile im Editor.
    /// - Parameters:
    ///   - pageIndex: 0-basierte Seite.
    ///   - point: Punkt in PDF-Koordinaten der Seite (Ursprung unten links).
    ///   - pageBounds: Medienrahmen der Seite.
    func showSource(pageIndex: Int, point: CGPoint, pageBounds: CGRect) {
        guard let syncTeX else { return }
        let x = point.x - pageBounds.minX
        let yFromTop = pageBounds.maxY - point.y
        guard let location = syncTeX.backwardSearch(page: pageIndex + 1, x: x, y: yFromTop),
              (location.file as NSString).lastPathComponent == Self.mainFileName else {
            NSSound.beep()
            return
        }
        editor?.reveal(line: location.line)
        editor?.focus()
    }

    // MARK: - Export

    /// Name für das exportierte PDF, abgeleitet vom Dokumentnamen.
    var suggestedPDFName: String {
        let base = fileURL?.deletingPathExtension().lastPathComponent ?? "Dokument"
        return base + ".pdf"
    }

    /// Sichert das aktuelle PDF an einem frei wählbaren Ort.
    func exportPDF() {
        guard let pdfData else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = suggestedPDFName
        panel.directoryURL = fileURL?.deletingLastPathComponent()
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try pdfData.write(to: url, options: .atomic)
        } catch {
            NSAlert(error: error).runModal()
        }
    }
}
