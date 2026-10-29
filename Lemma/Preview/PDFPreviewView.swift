import AppKit
import LaTeXKit
import PDFKit
import SwiftUI

/// PDF-Vorschau mit PDFKit (dieselbe Technik wie in der App „Vorschau“).
struct PDFPreviewView: NSViewRepresentable {
    let workspace: DocumentWorkspace

    func makeCoordinator() -> PDFPreviewCoordinator {
        PDFPreviewCoordinator(workspace: workspace)
    }

    func makeNSView(context: Context) -> SyncPDFView {
        let view = SyncPDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displaysPageBreaks = true
        view.pageShadowsEnabled = true
        view.backgroundColor = .underPageBackgroundColor
        // Etwas Luft um die Seiten – ruhiger, wie in der App „Vorschau“.
        view.pageBreakMargins = NSEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
        view.setAccessibilityLabel("PDF-Vorschau")
        view.onCommandClick = { [weak workspace] pageIndex, point, bounds in
            workspace?.showSource(pageIndex: pageIndex, point: point, pageBounds: bounds)
        }
        context.coordinator.attach(to: view)
        workspace.pdfViewer = context.coordinator
        return view
    }

    func updateNSView(_ view: SyncPDFView, context: Context) {
        context.coordinator.show(workspace.pdfDocument, revision: workspace.pdfRevision)
        if let pending = workspace.pendingPDFReveal {
            workspace.pendingPDFReveal = nil
            let coordinator = context.coordinator
            // Einen Moment warten, bis PDFKit das Dokument angeordnet hat.
            Task { @MainActor in coordinator.reveal(pending) }
        }
    }
}

/// Lädt neue PDFs, ohne dass die Ansicht an den Anfang springt.
@MainActor
final class PDFPreviewCoordinator: PDFViewerControlling {
    let workspace: DocumentWorkspace
    private(set) weak var view: SyncPDFView?
    private var shownRevision = -1
    private var observers: [NSObjectProtocol] = []
    /// PDFKit zeichnet Seiten im Hintergrund. Das vorige Dokument bleibt deshalb
    /// bis zum nächsten Wechsel erhalten, statt mitten im Zeichnen zu verschwinden.
    private var previousDocument: PDFDocument?

    init(workspace: DocumentWorkspace) {
        self.workspace = workspace
    }

    /// Verbindet die Ansicht und meldet Zoom und Seite an den Arbeitsbereich
    /// (für die Bedienleiste unter der Vorschau).
    func attach(to view: SyncPDFView) {
        self.view = view
        for observer in observers { NotificationCenter.default.removeObserver(observer) }
        observers = [Notification.Name.PDFViewScaleChanged, .PDFViewPageChanged, .PDFViewDocumentChanged].map { name in
            NotificationCenter.default.addObserver(forName: name, object: view, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.publishState() }
            }
        }
        publishState()
    }

    private func publishState() {
        guard let view else { return }
        let percent = Int((view.scaleFactor * 100).rounded())
        if workspace.pdfScalePercent != percent { workspace.pdfScalePercent = percent }
        if workspace.pdfAutoScales != view.autoScales { workspace.pdfAutoScales = view.autoScales }
        var page = 0
        if let document = view.document, let current = view.currentPage {
            page = document.index(for: current) + 1
        }
        if workspace.pdfPageNumber != page { workspace.pdfPageNumber = page }
    }

    func zoom(by factor: Double) {
        guard let view else { return }
        view.zoom(to: view.scaleFactor * factor, around: NSPoint(x: view.bounds.midX, y: view.bounds.midY))
        publishState()
    }

    func fitWidth() {
        view?.autoScales = true
        publishState()
    }

    func show(_ document: PDFDocument?, revision: Int) {
        guard let view, revision != shownRevision else { return }
        shownRevision = revision

        // Bisherige Scrollposition und Zoom merken …
        let scrollView = view.documentView?.enclosingScrollView
        let previousOrigin = scrollView?.contentView.bounds.origin
        let hadDocument = view.document != nil
        let autoScales = view.autoScales
        let scale = view.scaleFactor

        previousDocument = view.document
        view.document = document

        // … und nach dem Austausch wiederherstellen.
        guard hadDocument, let scrollView, let previousOrigin else { return }
        if !autoScales { view.scaleFactor = scale }
        view.layoutDocumentView()
        scrollView.contentView.scroll(to: previousOrigin)
        scrollView.reflectScrolledClipView(scrollView.contentView)
    }

    func reveal(_ position: SyncTeXPosition) {
        guard let view, let document = view.document,
              position.page >= 1, position.page <= document.pageCount,
              let page = document.page(at: position.page - 1) else { return }
        let bounds = page.bounds(for: .mediaBox)
        // SyncTeX misst von oben, PDF von unten.
        let rect = CGRect(
            x: bounds.minX + position.x,
            y: bounds.maxY - position.y - position.height,
            width: max(position.width, 20),
            height: max(position.height, 10)
        )
        view.go(to: rect.insetBy(dx: 0, dy: -60), on: page)

        // Stelle kurz hervorheben.
        let highlight = PDFAnnotation(bounds: rect.insetBy(dx: -2, dy: -2), forType: .highlight, withProperties: nil)
        highlight.color = NSColor.controlAccentColor.withAlphaComponent(0.35)
        page.addAnnotation(highlight)
        Task { @MainActor [weak page] in
            try? await Task.sleep(for: .seconds(1.5))
            page?.removeAnnotation(highlight)
        }
    }
}

/// `PDFView` mit ⌘-Klick für den Sprung zur Quelltextzeile und Zoomen mit
/// zwei Fingern auf dem Trackpad (wie in der App „Vorschau“).
final class SyncPDFView: PDFView {
    /// Seite (0-basiert), Punkt in Seitenkoordinaten, Medienrahmen der Seite.
    var onCommandClick: ((Int, CGPoint, CGRect) -> Void)?

    static let minimumZoom: CGFloat = 0.25
    static let maximumZoom: CGFloat = 8

    /// Beobachter für Zoom-Gesten im Fenster (siehe `updateGestureMonitor`).
    private var gestureMonitor: Any?

    override func mouseDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command),
           let document,
           let onCommandClick {
            let viewPoint = convert(event.locationInWindow, from: nil)
            if let page = page(for: viewPoint, nearest: true) {
                let pagePoint = convert(viewPoint, to: page)
                onCommandClick(document.index(for: page), pagePoint, page.bounds(for: .mediaBox))
                return
            }
        }
        super.mouseDown(with: event)
    }

    // MARK: - Zoomen

    /// Zoomen mit dem Trackpad: zwei Finger auseinander- bzw. zusammenziehen,
    /// zweimal mit zwei Fingern tippen wechselt zwischen Seitenbreite und doppelter Grösse.
    ///
    /// Die Gesten werden für das ganze Fenster abgefangen, bevor eine Ansicht sie
    /// sieht, und hier verarbeitet, sobald der Zeiger über der Vorschau steht.
    /// Sonst landen sie je nach Stelle bei PDFKits inneren Ansichten, die selbst
    /// (oder gar nicht) zoomen – das machte das Zoomen unzuverlässig.
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        updateGestureMonitor()
    }

    private func updateGestureMonitor() {
        if let gestureMonitor {
            NSEvent.removeMonitor(gestureMonitor)
            self.gestureMonitor = nil
        }
        guard window != nil else { return }
        gestureMonitor = NSEvent.addLocalMonitorForEvents(matching: [.magnify, .smartMagnify]) { [weak self] event in
            // Lokale Beobachter laufen immer auf dem Hauptthread.
            let handled = MainActor.assumeIsolated { self?.handleZoomGesture(event) ?? false }
            return handled ? nil : event
        }
    }

    /// Verarbeitet eine Zoom-Geste, wenn sie über dieser Ansicht stattfindet.
    /// - Returns: `true`, wenn die Geste verbraucht wurde.
    private func handleZoomGesture(_ event: NSEvent) -> Bool {
        guard let window, event.window === window, document != nil, !isHiddenOrHasHiddenAncestor else { return false }
        let location = convert(event.locationInWindow, from: nil)
        guard bounds.contains(location) else { return false }
        switch event.type {
        case .magnify:
            // `magnification` ist die Änderung seit dem letzten Ereignis der Geste.
            zoom(to: scaleFactor * (1 + event.magnification), around: location)
        case .smartMagnify:
            if autoScales {
                zoom(to: scaleFactor * 2, around: location)
            } else {
                autoScales = true
            }
        default:
            return false
        }
        return true
    }

    /// Ändert die Grösse so, dass die Stelle unter den Fingern an ihrem Platz bleibt.
    /// - Parameter location: Punkt in Koordinaten dieser Ansicht.
    func zoom(to newScale: CGFloat, around location: NSPoint) {
        guard document != nil else { return }
        let scale = min(max(newScale, Self.minimumZoom), Self.maximumZoom)
        guard abs(scale - scaleFactor) > 0.0001 else { return }

        // Stelle unter den Fingern merken (in Seitenkoordinaten, unabhängig von der Grösse).
        let anchorPage = page(for: location, nearest: true)
        let anchor = anchorPage.map { convert(location, to: $0) }

        // Wer zoomt, will die feste Grösse behalten – auch nach dem nächsten Kompilieren.
        autoScales = false
        scaleFactor = scale

        // So scrollen, dass die gemerkte Stelle wieder unter den Fingern liegt.
        guard let anchorPage, let anchor,
              let clipView = documentView?.enclosingScrollView?.contentView else { return }
        layoutDocumentView()
        let current = clipView.convert(convert(anchor, from: anchorPage), from: self)
        let target = clipView.convert(location, from: self)
        var origin = clipView.bounds.origin
        origin.x += current.x - target.x
        origin.y += current.y - target.y
        let visible = clipView.constrainBoundsRect(NSRect(origin: origin, size: clipView.bounds.size))
        clipView.scroll(to: visible.origin)
        clipView.enclosingScrollView?.reflectScrolledClipView(clipView)
    }
}
