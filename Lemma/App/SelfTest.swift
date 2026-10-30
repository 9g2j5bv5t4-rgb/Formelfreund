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
    /// Gefundene Probleme, die keinen Absturz auslösen (z. B. zu breites Fenster).
    private static var problems: [String] = []

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
        await testPDFZoom()
        // Jedes Register der Format-Seitenleiste einmal zeigen.
        workspace.showsInspector = true
        for tab in InspectorTab.allCases {
            workspace.inspectorTab = tab
            try? await Task.sleep(for: .milliseconds(500))
            snapshot("format-\(tab.rawValue)", in: directory)
        }
        workspace.inspectorTab = .text
        workspace.showsInspector = false

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

        // 3. Kleines Fenster wie auf einem 13-Zoll-Bildschirm (macOS hält die Mindestgrösse ein).
        documentWindow?.setContentSize(NSSize(width: 700, height: 500))
        try? await Task.sleep(for: .seconds(0.5))
        log("Kleines Fenster: \(windowDescription)")
        await repeatAction("Gemischt im kleinen Fenster", times: 40) { actions.randomElement()!() }
        await waitUntilFinished(workspace, timeout: 120)

        // 4. Endzustand mit allen Bereichen zeigen.
        workspace.showsPreview = true
        workspace.showsInspector = true
        try? await Task.sleep(for: .seconds(1.5))
        snapshot("inspektor", in: directory)
        log("Endzustand: \(workspace.status), \(windowDescription)")

        checkWindowFitsScreen(after: "Endzustand")
        if problems.isEmpty {
            log("FERTIG")
            exit(0)
        }
        log("FEHLGESCHLAGEN: " + problems.joined(separator: "; "))
        exit(1)
    }

    /// Zoomen wie mit zwei Fingern: Die Stelle in der Mitte muss an ihrem Platz bleiben.
    private static func testPDFZoom() async {
        guard let pdfView = findView(SyncPDFView.self, in: documentWindow?.contentView?.superview),
              let page = pdfView.page(for: NSPoint(x: pdfView.bounds.midX, y: pdfView.bounds.midY), nearest: true) else {
            problems.append("PDF-Ansicht für den Zoom-Test nicht gefunden")
            return
        }
        let center = NSPoint(x: pdfView.bounds.midX, y: pdfView.bounds.midY)
        let before = pdfView.scaleFactor
        let anchorBefore = pdfView.convert(center, to: page)
        // Eine Geste in kleinen Schritten, wie das Trackpad sie meldet.
        for step in 1...10 {
            pdfView.zoom(to: before * (1 + CGFloat(step) * 0.1), around: center)
            try? await Task.sleep(for: .milliseconds(30))
        }
        let after = pdfView.scaleFactor
        let anchorAfter = pdfView.convert(center, to: page)
        let drift = hypot(anchorAfter.x - anchorBefore.x, anchorAfter.y - anchorBefore.y)
        log("PDF-Zoom: \(String(format: "%.2f", before)) → \(String(format: "%.2f", after)), Abweichung der Mitte \(String(format: "%.1f", drift)) pt")
        if after < before * 1.9 { problems.append("PDF-Zoom vergrössert nicht") }
        if drift > 3 { problems.append("PDF-Zoom hält die Stelle unter den Fingern nicht fest") }
        // Zurück auf Seitenbreite für die weiteren Tests.
        pdfView.autoScales = true
        try? await Task.sleep(for: .milliseconds(300))
    }

    // MARK: - Hilfen

    private static func findView<T: NSView>(_ type: T.Type, in view: NSView?) -> T? {
        guard let view else { return nil }
        if let match = view as? T { return match }
        for subview in view.subviews {
            if let match = findView(type, in: subview) { return match }
        }
        return nil
    }

    /// Führt eine Aktion mehrmals aus, mit wechselnden, teils sehr kurzen Pausen.
    private static func repeatAction(_ name: String, times: Int, _ action: () -> Void) async {
        log("Beginne: \(name) (\(times)×)")
        let pauses: [Double] = [0.05, 0.12, 0.3, 0.08, 0.5, 0.02]
        for index in 0..<times {
            action()
            try? await Task.sleep(for: .seconds(pauses[index % pauses.count]))
        }
        log("Überstanden: \(name) – \(windowDescription)")
        checkWindowFitsScreen(after: name)
    }

    private static func waitUntilFinished(_ workspace: DocumentWorkspace, timeout: TimeInterval) async {
        let deadline = Date().addingTimeInterval(timeout)
        // Kurz warten, damit ein eben gestarteter Lauf seinen Status setzen kann.
        try? await Task.sleep(for: .seconds(0.5))
        while workspace.isBusy || workspace.status == .idle, Date() < deadline {
            try? await Task.sleep(for: .seconds(0.25))
        }
    }

    /// Das Fenster darf nie breiter oder höher werden als der Bildschirm.
    private static func checkWindowFitsScreen(after phase: String) {
        guard let window = documentWindow, let screen = window.screen?.visibleFrame else { return }
        if window.frame.width > screen.width + 1 || window.frame.height > screen.height + 1 {
            problems.append("Fenster grösser als der Bildschirm nach „\(phase)“")
        }
    }

    private static var documentWindow: NSWindow? {
        NSApp.windows.first { $0.isVisible && $0.toolbar != nil }
    }

    private static var windowDescription: String {
        guard let window = documentWindow else { return "kein Fenster" }
        let screen = window.screen?.visibleFrame.size ?? .zero
        let minimum = window.contentMinSize
        return "Fenster \(Int(window.frame.width))×\(Int(window.frame.height)) (mindestens \(Int(minimum.width))×\(Int(minimum.height))), Bildschirm \(Int(screen.width))×\(Int(screen.height))"
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
