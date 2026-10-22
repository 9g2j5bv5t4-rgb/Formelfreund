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
        view.setAccessibilityLabel("PDF-Vorschau")
        view.onCommandClick = { [weak workspace] pageIndex, point, bounds in
            workspace?.showSource(pageIndex: pageIndex, point: point, pageBounds: bounds)
        }
        context.coordinator.view = view
        workspace.pdfViewer = context.coordinator
        return view
    }

    func updateNSView(_ view: SyncPDFView, context: Context) {
        context.coordinator.show(workspace.pdfDocument, revision: workspace.pdfRevision)
    }
}

/// Lädt neue PDFs, ohne dass die Ansicht an den Anfang springt.
@MainActor
final class PDFPreviewCoordinator: PDFViewerControlling {
    let workspace: DocumentWorkspace
    weak var view: SyncPDFView?
    private var shownRevision = -1

    init(workspace: DocumentWorkspace) {
        self.workspace = workspace
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

/// `PDFView` mit ⌘-Klick für den Sprung zur Quelltextzeile.
final class SyncPDFView: PDFView {
    /// Seite (0-basiert), Punkt in Seitenkoordinaten, Medienrahmen der Seite.
    var onCommandClick: ((Int, CGPoint, CGRect) -> Void)?

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
}
