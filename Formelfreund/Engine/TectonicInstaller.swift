import CryptoKit
import Foundation
import LaTeXKit

/// Lädt Tectonic beim ersten Kompilieren herunter und installiert es in
/// `~/Library/Application Support/Formelfreund/Tectonic/<Version>/`.
///
/// Sicherheit: Die Version ist fest eingetragen und die Datei wird vor dem
/// Entpacken über ihre SHA-256-Prüfsumme geprüft. Eine manipulierte oder
/// beschädigte Datei wird nie ausgeführt.
enum TectonicInstaller {
    static let version = "0.17.0"

    struct Asset {
        let url: URL
        let sha256: String
    }

    /// Offizielle Release-Datei von GitHub für diese Mac-Architektur.
    static var asset: Asset {
        #if arch(arm64)
        Asset(
            url: URL(string: "https://github.com/tectonic-typesetting/tectonic/releases/download/tectonic%400.17.0/tectonic-0.17.0-aarch64-apple-darwin.tar.gz")!,
            sha256: "a3f1cac7c5678f01661a92212f58480ae3b0634115d880dbc59e2953ded45667"
        )
        #else
        Asset(
            url: URL(string: "https://github.com/tectonic-typesetting/tectonic/releases/download/tectonic%400.17.0/tectonic-0.17.0-x86_64-apple-darwin.tar.gz")!,
            sha256: "7c90ef5b6ddb1eb1937e4337add5237b79338e4b9676459fa91187d24d6cdf80"
        )
        #endif
    }

    enum InstallError: LocalizedError {
        case download(String)
        case checksumMismatch
        case extraction(String)
        case notRunnable(String)

        var errorDescription: String? {
            switch self {
            case .download(let reason):
                return "Tectonic konnte nicht heruntergeladen werden. Besteht eine Internetverbindung? (\(reason))"
            case .checksumMismatch:
                return "Die heruntergeladene Datei ist beschädigt (Prüfsumme stimmt nicht). Bitte erneut versuchen."
            case .extraction(let reason):
                return "Tectonic konnte nicht entpackt werden: \(reason)"
            case .notRunnable(let reason):
                return "Tectonic lässt sich nicht starten: \(reason)"
            }
        }
    }

    static var installDirectory: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return support
            .appendingPathComponent("Formelfreund", isDirectory: true)
            .appendingPathComponent("Tectonic", isDirectory: true)
            .appendingPathComponent(version, isDirectory: true)
    }

    static var executableURL: URL {
        installDirectory.appendingPathComponent("tectonic")
    }

    /// Bereits von Formelfreund installiertes Tectonic, falls vorhanden.
    static func installedExecutable() -> URL? {
        FileManager.default.isExecutableFile(atPath: executableURL.path) ? executableURL : nil
    }

    /// Lädt, prüft, entpackt und testet Tectonic.
    /// - Parameter progress: Download-Fortschritt von 0 bis 1.
    static func install(progress: @escaping @Sendable (Double) -> Void) async throws -> URL {
        let fm = FileManager.default
        let workDirectory = fm.temporaryDirectory.appendingPathComponent("Formelfreund-Tectonic-\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: workDirectory, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: workDirectory) }

        // 1. Herunterladen
        let archive = try await download(asset.url, to: workDirectory.appendingPathComponent("tectonic.tar.gz"), progress: progress)

        // 2. Prüfsumme kontrollieren
        let data = try Data(contentsOf: archive, options: .mappedIfSafe)
        let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        guard digest == asset.sha256 else { throw InstallError.checksumMismatch }

        // 3. Entpacken (mit dem in macOS eingebauten tar)
        let extractDirectory = workDirectory.appendingPathComponent("extracted", isDirectory: true)
        try fm.createDirectory(at: extractDirectory, withIntermediateDirectories: true)
        let tar = try await ProcessRunner.run(
            executable: URL(fileURLWithPath: "/usr/bin/tar"),
            arguments: ["-xzf", archive.path, "-C", extractDirectory.path]
        )
        let extracted = extractDirectory.appendingPathComponent("tectonic")
        guard tar.exitCode == 0, fm.fileExists(atPath: extracted.path) else {
            throw InstallError.extraction(tar.standardError.isEmpty ? "Unbekannter Fehler" : tar.standardError)
        }

        // 4. An den endgültigen Ort verschieben und ausführbar machen
        try fm.createDirectory(at: installDirectory, withIntermediateDirectories: true)
        if fm.fileExists(atPath: executableURL.path) {
            try fm.removeItem(at: executableURL)
        }
        try fm.moveItem(at: extracted, to: executableURL)
        try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executableURL.path)

        // 5. Probelauf
        let check = try await ProcessRunner.run(executable: executableURL, arguments: ["--version"])
        guard check.exitCode == 0 else {
            try? fm.removeItem(at: executableURL)
            throw InstallError.notRunnable(check.standardError)
        }
        return executableURL
    }

    /// Download mit Fortschrittsanzeige; bricht ab, wenn die Task abgebrochen wird.
    private static func download(_ url: URL, to destination: URL, progress: @escaping @Sendable (Double) -> Void) async throws -> URL {
        let box = DownloadBox()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
                let task = URLSession.shared.downloadTask(with: url) { location, response, error in
                    if let error {
                        continuation.resume(throwing: InstallError.download(error.localizedDescription))
                        return
                    }
                    guard let location, let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                        continuation.resume(throwing: InstallError.download("HTTP-Status \(code)"))
                        return
                    }
                    do {
                        // Die temporäre Datei verschwindet nach diesem Block – sofort verschieben.
                        try FileManager.default.moveItem(at: location, to: destination)
                        continuation.resume(returning: destination)
                    } catch {
                        continuation.resume(throwing: InstallError.download(error.localizedDescription))
                    }
                }
                box.set(task: task, observation: task.progress.observe(\.fractionCompleted) { value, _ in
                    progress(value.fractionCompleted)
                })
                task.resume()
            }
        } onCancel: {
            box.cancel()
        }
    }
}

/// Hält Download-Task und Fortschrittsbeobachtung am Leben (threadsicher).
private final class DownloadBox: @unchecked Sendable {
    private let lock = NSLock()
    private var task: URLSessionDownloadTask?
    private var observation: NSKeyValueObservation?

    func set(task: URLSessionDownloadTask, observation: NSKeyValueObservation) {
        lock.withLock {
            self.task = task
            self.observation = observation
        }
    }

    func cancel() {
        let task = lock.withLock { self.task }
        task?.cancel()
    }
}
