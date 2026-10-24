import Foundation
import LaTeXKit
import Observation

/// Verwaltet die verfügbaren LaTeX-Engines für die ganze App.
///
/// - Tectonic ist der Standard. Ist es noch nicht vorhanden, wird es beim
///   ersten Kompilieren automatisch heruntergeladen (einmalig, ~22 MB).
/// - Ist MacTeX installiert, kann in den Einstellungen `latexmk` gewählt werden.
@MainActor
@Observable
final class EngineManager {
    static let shared = EngineManager()

    enum TectonicState: Equatable {
        case notInstalled
        case downloading(Double)
        case installing
        case ready(URL)
        case failed(String)
    }

    private(set) var tectonicState: TectonicState = .notInstalled
    private(set) var latexmkURL: URL?

    /// Gewählte Engine (in den Einstellungen änderbar).
    var preferredEngine: EngineKind {
        get { storedPreferredEngine }
        set {
            storedPreferredEngine = newValue
            AppSettings.preferredEngine = newValue
        }
    }
    private var storedPreferredEngine: EngineKind

    @ObservationIgnored private var installTask: Task<URL, Error>?

    private init() {
        storedPreferredEngine = AppSettings.preferredEngine
        refresh()
    }

    /// Sucht erneut nach installierten Programmen.
    func refresh() {
        latexmkURL = EngineLocator.firstExecutable(in: EngineLocator.latexmkCandidates)
        if let url = TectonicInstaller.installedExecutable()
            ?? EngineLocator.firstExecutable(in: EngineLocator.tectonicCandidates) {
            tectonicState = .ready(url)
        } else if case .ready = tectonicState {
            tectonicState = .notInstalled
        }
    }

    /// Engine, mit der tatsächlich kompiliert wird.
    var effectiveEngine: EngineKind {
        preferredEngine == .latexmk && latexmkURL != nil ? .latexmk : .tectonic
    }

    /// Muss vor dem Kompilieren noch etwas heruntergeladen werden?
    var needsSetup: Bool {
        guard effectiveEngine == .tectonic else { return false }
        if case .ready = tectonicState { return false }
        return true
    }

    /// Fortschritt der Einrichtung (0…1), falls gerade heruntergeladen wird.
    var setupProgress: Double? {
        switch tectonicState {
        case .downloading(let value): return value
        case .installing: return 1
        default: return nil
        }
    }

    /// Liefert eine startklare Engine; lädt Tectonic bei Bedarf herunter.
    func engineForCompiling() async throws -> any TeXEngine {
        if effectiveEngine == .latexmk, let url = latexmkURL {
            return LatexmkEngine(executableURL: url)
        }
        return TectonicEngine(executableURL: try await ensureTectonic())
    }

    /// Stellt sicher, dass Tectonic installiert ist. Mehrere gleichzeitige
    /// Aufrufe (z. B. zwei offene Dokumente) teilen sich denselben Download.
    @discardableResult
    func ensureTectonic() async throws -> URL {
        if case .ready(let url) = tectonicState { return url }
        if let installTask { return try await installTask.value }

        tectonicState = .downloading(0)
        let task = Task { () throws -> URL in
            try await TectonicInstaller.install(progress: { value in
                Task { @MainActor in
                    EngineManager.shared.updateDownloadProgress(value)
                }
            })
        }
        installTask = task
        defer { installTask = nil }
        do {
            let url = try await task.value
            tectonicState = .ready(url)
            return url
        } catch {
            tectonicState = .failed(error.localizedDescription)
            throw error
        }
    }

    private func updateDownloadProgress(_ value: Double) {
        // Späte Meldungen dürfen einen fertigen Zustand nicht überschreiben.
        if case .downloading = tectonicState {
            tectonicState = value >= 1 ? .installing : .downloading(value)
        }
    }
}
