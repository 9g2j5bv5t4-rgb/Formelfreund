import AppKit
import Foundation

/// Automatischer Belastungstest für die CI (GitHub Actions).
///
/// Ist nur aktiv, wenn die Umgebungsvariable `LEMMA_SELFTEST` gesetzt ist. Sie
/// enthält den Pfad einer Protokolldatei. Der Test macht, was ein ungeduldiger
/// Mensch macht: Er blendet PDF-Vorschau und Inspektor in schneller Folge ein
/// und aus und startet viele Kompilierläufe hintereinander. Am Ende steht
/// „FERTIG“ im Protokoll. Fehlt die Zeile, ist die App abgestürzt oder hängt,
/// und die CI schlägt fehl.
///
/// Für normale Nutzer ändert sich nichts: Ohne die Variable passiert hier nichts.
@MainActor
enum SelfTest {
    /// Protokolldatei, falls der Selbsttest eingeschaltet ist.
    static let logURL: URL? = ProcessInfo.processInfo.environment["LEMMA_SELFTEST"]
        .map { URL(fileURLWithPath: $0) }

    private static var hasStarted = false

    /// Beim Start der App aufrufen: Beendet die App spätestens nach acht Minuten,
    /// auch wenn kein Fenster aufgeht oder der Hauptthread hängt.
    static func startWatchdog() {
        guard let logURL else { return }
        write("Start", to: logURL)
        DispatchQueue.global().asyncAfter(deadline: .now() + 480) {
            write("ZEITÜBERSCHREITUNG – die App hängt oder es ging kein Fenster auf", to: logURL)
            exit(3)
        }
    }

    /// Führt den Test im ersten geöffneten Dokumentfenster aus und beendet danach die App.
    static func runIfEnabled(_ workspace: DocumentWorkspace) async {
        guard let logURL, !hasStarted else { return }
        hasStarted = true
        let directory = logURL.deletingLastPathComponent()
        log("Fenster offen: \(windowDescription)")

        // 1. Erster Lauf – lädt beim ersten Mal Tectonic und die Pakete herunter.
        if workspace.status == .idle { workspace.compile() }
        await waitUntilFinished(workspace, timeout: 300)
        log("Erster Lauf: \(workspace.status), \(workspace.errors.count) Fehler, \(workspace.warnings.count) Warnungen, PDF-Seiten: \(workspace.pdfDocument?.pageCount ?? 0)")
        for issue in workspace.issues.prefix(5) {
            log("  Meldung: \(issue.severity) Zeile \(issue.line.map { "\($0)" } ?? "–"): \(issue.message)")
        }
        if let latexLog = workspace.lastLog {
            try? latexLog.write(to: directory.appendingPathComponent("latex.log"), atomically: true, encoding: .utf8)
        }
        try? await Task.sleep(for: .seconds(1))
        snapshot("fenster", in: directory)

        // 2. Schnell hintereinander klicken – jede Aktion einzeln, dann gemischt.
        await repeatAction("PDF-Vorschau ein/aus", times: 30) { workspace.showsPreview.toggle() }
        await repeatAction("Inspektor ein/aus", times: 30) { workspace.showsInspector.toggle() }
        await repeatAction("Kompilieren", times: 30) { workspace.compile() }
        await waitUntilFinished(workspace, timeout: 120)
        log("Nach schnellem Kompilieren: \(workspace.status)")

        let actions: [@MainActor () -> Void] = [
            { workspace.showsPreview.toggle() },
            { workspace.showsInspector.toggle() },
            { workspace.compile() }
        ]
        await repeatAction("Gemischt", times: 90) { actions.randomElement()!() }
        await waitUntilFinished(workspace, timeout: 120)

        // 3. Endzustand mit allen Bereichen zeigen.
        workspace.showsPreview = true
        workspace.showsInspector = true
        try? await Task.sleep(for: .seconds(1.5))
        snapshot("inspektor", in: directory)
        log("Endzustand: \(workspace.status), \(windowDescription)")

        log("FERTIG")
        exit(0)
    }

    // MARK: - Hilfen

    /// Führt eine Aktion mehrmals aus, mit wechselnden, teils sehr kurzen Pausen.
    private static func repeatAction(_ name: String, times: Int, _ action: () -> Void) async {
        log("Beginne: \(name) (\(times)×)")
        let pauses: [Double] = [0.05, 0.12, 0.3, 0.08, 0.5, 0.02]
        for index in 0..<times {
            action()
            try? await Task.sleep(for: .seconds(pauses[index % pauses.count]))
        }
        log("Überstanden: \(name)")
    }

    private static func waitUntilFinished(_ workspace: DocumentWorkspace, timeout: TimeInterval) async {
        let deadline = Date().addingTimeInterval(timeout)
        // Kurz warten, damit ein eben gestarteter Lauf seinen Status setzen kann.
        try? await Task.sleep(for: .seconds(0.5))
        while workspace.isBusy || workspace.status == .idle, Date() < deadline {
            try? await Task.sleep(for: .seconds(0.25))
        }
    }

    private static var documentWindow: NSWindow? {
        NSApp.windows.first { $0.isVisible && $0.toolbar != nil }
    }

    private static var windowDescription: String {
        guard let window = documentWindow else { return "kein Fenster" }
        let screen = window.screen?.visibleFrame.size ?? .zero
        return "Fenster \(Int(window.frame.width))×\(Int(window.frame.height)), Bildschirm \(Int(screen.width))×\(Int(screen.height))"
    }

    /// Bild des ganzen Fensters (inklusive Symbolleiste) als PNG.
    private static func snapshot(_ name: String, in directory: URL) {
        guard let frameView = documentWindow?.contentView?.superview,
              let rep = frameView.bitmapImageRepForCachingDisplay(in: frameView.bounds) else {
            log("Kein Bild möglich: \(name)")
            return
        }
        frameView.cacheDisplay(in: frameView.bounds, to: rep)
        try? rep.representation(using: .png, properties: [:])?
            .write(to: directory.appendingPathComponent(name + ".png"))
    }

    private static func log(_ message: String) {
        guard let logURL else { return }
        write(message, to: logURL)
    }

    /// Hängt eine Zeile an (auch von Hintergrund-Threads aus nutzbar).
    private nonisolated static func write(_ message: String, to url: URL) {
        let line = Data((message + "\n").utf8)
        if let handle = try? FileHandle(forWritingTo: url) {
            _ = try? handle.seekToEnd()
            try? handle.write(contentsOf: line)
            try? handle.close()
        } else {
            try? line.write(to: url)
        }
    }
}
