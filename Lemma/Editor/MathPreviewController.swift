import AppKit
import LaTeXKit
@preconcurrency import WebKit

/// Formelvorschau: Steht der Cursor in einer Formel, schwebt die fertig gesetzte
/// Formel über ihr – so sieht man beim Tippen, was herauskommt, ohne zu kompilieren.
///
/// Gesetzt wird mit MathJax in einer kleinen Webansicht (`MathPreview.html`,
/// vollständig in der App enthalten, funktioniert ohne Internet). Die Vorschau
/// nimmt keine Klicks an und lässt den Cursor im Editor.
@MainActor
final class MathPreviewController: NSObject, WKNavigationDelegate {
    private var panelStorage: FloatingPanel?
    private var webView: WKWebView?
    private var isLoaded = false
    /// Was angezeigt werden soll, sobald die Seite geladen ist.
    private var pending: (request: MathPreviewRequest, anchor: NSRect, window: NSWindow)?
    private var shown: MathPreviewRequest?
    private var renderTask: Task<Void, Never>?

    static let maximumSize = NSSize(width: 640, height: 360)

    var isVisible: Bool { panelStorage?.isVisible == true }

    /// Zeigt `request` über `anchor` (Bildschirmkoordinaten der ersten Formelzeile).
    func show(_ request: MathPreviewRequest, above anchor: NSRect, in window: NSWindow) {
        pending = (request, anchor, window)
        prepare()
        guard isLoaded else { return }
        render()
    }

    func hide() {
        pending = nil
        shown = nil
        renderTask?.cancel()
        panelStorage?.hide()
    }

    // MARK: - Aufbau

    private func prepare() {
        guard webView == nil else { return }
        let configuration = WKWebViewConfiguration()
        configuration.suppressesIncrementalRendering = true
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 200, height: 60), configuration: configuration)
        // Durchsichtig, damit der Hintergrund des schwebenden Fensters zu sehen ist.
        // Dafür gibt es keine offizielle Einstellung; nur setzen, wenn es sie gibt.
        if webView.responds(to: NSSelectorFromString("setDrawsBackground:"))
            || webView.responds(to: NSSelectorFromString("_setDrawsBackground:")) {
            webView.setValue(false, forKey: "drawsBackground")
        }
        webView.underPageBackgroundColor = .clear
        webView.navigationDelegate = self
        webView.setAccessibilityLabel("Formelvorschau")
        self.webView = webView

        let panel = FloatingPanel(content: webView)
        panel.ignoresMouseEvents = true
        panelStorage = panel

        guard let url = Bundle.main.url(forResource: "MathPreview", withExtension: "html") else { return }
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }

    nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        MainActor.assumeIsolated {
            self.isLoaded = true
            self.render()
        }
    }

    // MARK: - Setzen

    private func render() {
        guard let pending, let webView, let panel = panelStorage else { return }
        let request = pending.request
        // Gleiche Formel: nur die Lage nachführen.
        if request == shown, panel.isVisible {
            place(size: panel.frame.size, anchor: pending.anchor, window: pending.window)
            return
        }
        renderTask?.cancel()
        renderTask = Task { [weak self] in
            let result = try? await webView.callAsyncJavaScript(
                "return await lemmaRender(tex, display);",
                arguments: ["tex": request.tex, "display": request.display],
                contentWorld: .page
            )
            guard let self, !Task.isCancelled, let current = self.pending, current.request == request else { return }
            guard let numbers = result as? [NSNumber], numbers.count == 2 else { return }
            let size = NSSize(
                width: min(max(CGFloat(numbers[0].doubleValue), 24), Self.maximumSize.width),
                height: min(max(CGFloat(numbers[1].doubleValue), 20), Self.maximumSize.height)
            )
            self.shown = request
            self.place(size: size, anchor: current.anchor, window: current.window)
        }
    }

    private func place(size: NSSize, anchor: NSRect, window: NSWindow) {
        guard let panel = panelStorage else { return }
        let frame = FloatingPanel.frame(size: size, below: anchor.offsetBy(dx: -10, dy: 0), preferAbove: true, gap: 6)
        panel.show(frame: frame, over: window)
    }
}
