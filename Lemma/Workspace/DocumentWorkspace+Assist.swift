import AppKit
import LaTeXKit

/// Kurze Rückmeldung unten im Fenster („Gespeichert“, „PDF exportiert“ …).
struct Notice: Identifiable, Equatable {
    enum Style {
        case success
        case info
        case warning
    }

    let id = UUID()
    var message: String
    var symbol: String
    var style: Style
    /// Datei, die der Knopf „Im Finder zeigen“ öffnet.
    var revealURL: URL?

    init(_ message: String, symbol: String? = nil, style: Style = .info, revealURL: URL? = nil) {
        self.message = message
        self.style = style
        self.revealURL = revealURL
        switch style {
        case .success: self.symbol = symbol ?? "checkmark.circle.fill"
        case .info: self.symbol = symbol ?? "info.circle.fill"
        case .warning: self.symbol = symbol ?? "exclamationmark.triangle.fill"
        }
    }
}

/// Für welchen Teil gelten Ränder und Zeilenabstand?
enum LayoutScope: String, CaseIterable, Identifiable {
    case document
    case page

    var id: String { rawValue }

    var title: String {
        switch self {
        case .document: return "Ganzes Dokument"
        case .page: return "Diese Seite"
        }
    }
}

extension DocumentWorkspace {
    // MARK: - Rückmeldungen

    /// Zeigt eine kurze Meldung, die nach ein paar Sekunden von selbst verschwindet.
    func show(_ notice: Notice) {
        self.notice = notice
        noticeTask?.cancel()
        noticeTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(notice.revealURL == nil ? 3 : 5))
            guard !Task.isCancelled, let self, self.notice?.id == notice.id else { return }
            self.notice = nil
        }
    }

    func dismissNotice() {
        noticeTask?.cancel()
        notice = nil
    }

    // MARK: - Layout: ganzes Dokument oder nur diese Seite

    func applyMargins(_ margins: PageMargins) {
        switch layoutScope {
        case .document:
            var settings = documentSettings
            settings.margins = margins
            applyDocumentSettings(settings)
        case .page:
            guard let region = localLayoutRegion() else { return NSSound.beep() }
            let changed = performEdit(
                "Ränder dieser Seite",
                requirements: margins == .standard ? [] : [LocalLayout.geometryRequirement]
            ) { source, _ in
                LocalLayout.margins(margins, region: region, in: source)
            }
            if changed && margins != .standard {
                show(Notice("Die Ränder gelten für diesen Abschnitt – er beginnt dafür auf einer neuen Seite.", symbol: "doc.text"))
            }
        }
    }

    func applyLineSpacing(_ spacing: LineSpacing) {
        switch layoutScope {
        case .document:
            var settings = documentSettings
            settings.lineSpacing = spacing
            applyDocumentSettings(settings)
        case .page:
            guard let region = localLayoutRegion() else { return NSSound.beep() }
            performEdit("Zeilenabstand dieser Seite", requirements: [LocalLayout.setspaceRequirement]) { source, _ in
                LocalLayout.spacing(spacing, region: region, in: source)
            }
        }
    }

    /// Bereich für „Diese Seite“: die Auswahl, sonst die Absätze der PDF-Seite mit
    /// dem Cursor (über SyncTeX), sonst der Absatz am Cursor.
    private func localLayoutRegion() -> Range<Int>? {
        guard let editor else { return nil }
        let source = editor.source
        let selection = editor.selection
        if !selection.isEmpty {
            return LocalLayout.region(in: source, around: selection)
        }
        if let syncTeX,
           let position = syncTeX.forwardSearch(line: editor.cursorLine, fileName: Self.mainFileName),
           let lines = syncTeX.lineRange(onPage: position.page, fileName: Self.mainFileName),
           let region = LocalLayout.region(in: source, lines: lines) {
            return region
        }
        return LocalLayout.region(in: source, around: selection)
    }

    // MARK: - Speichern

    /// Speichert das Dokument (bei einem neuen Dokument mit Dialog) und bestätigt es.
    /// - Parameter asNewFile: „Speichern unter …“: immer mit Dialog, unter neuem Namen.
    func saveDocument(asNewFile: Bool = false) {
        guard let window = editor?.window,
              let document = NSDocumentController.shared.document(for: window) else {
            // Notlösung: den normalen Weg über die Responder-Kette gehen.
            NSApp.sendAction(NSSelectorFromString(asNewFile ? "saveDocumentAs:" : "saveDocument:"), to: nil, from: nil)
            return
        }
        let callback = SaveCallback { [weak self, weak document] saved in
            guard saved, let self, let document else { return }
            let name = document.fileURL?.lastPathComponent ?? document.displayName
            self.show(Notice("„\(name)“ gespeichert", style: .success, revealURL: document.fileURL))
        }
        let selector = #selector(SaveCallback.document(_:didSave:contextInfo:))
        if asNewFile {
            document.runModalSavePanel(for: .saveAsOperation, delegate: callback, didSave: selector, contextInfo: nil)
        } else {
            document.save(withDelegate: callback, didSave: selector, contextInfo: nil)
        }
    }

    // MARK: - Fehler beheben

    func advice(for issue: CompileIssue) -> IssueAdvice? {
        issueAdvice[issue.id]
    }

    /// Führt eine Behebung aus; das Dokument wird danach wie nach jeder Änderung neu kompiliert.
    func applyFix(_ fix: QuickFix) {
        let isPackage: Bool
        if case .loadPackage = fix { isPackage = true } else { isPackage = false }
        let changed = performEdit(fix.title) { source, selection in
            let edit = ErrorAdvisor.edit(applying: fix, in: source)
            // Ein Paket kommt in die Präambel – der Cursor bleibt, wo er ist.
            return isPackage ? edit?.preservingSelection(selection) : edit
        }
        if changed {
            show(Notice("Erledigt: \(fix.title)", style: .success))
        } else {
            show(Notice("Die Stelle hat sich inzwischen geändert – bitte von Hand beheben.", style: .warning))
        }
    }

    // MARK: - Weiterleitungen für die Leiste

    func showFindBar() {
        editor?.showFindBar()
    }

    func zoomPDF(by factor: Double) {
        pdfViewer?.zoom(by: factor)
    }

    func fitPDFWidth() {
        pdfViewer?.fitWidth()
    }
}

/// Empfängt das Ergebnis eines Speichervorgangs von `NSDocument` (Objective-C-Rückruf)
/// und hält sich selbst am Leben, bis er eintrifft.
@MainActor
final class SaveCallback: NSObject {
    private let completion: (Bool) -> Void
    private var keepAlive: SaveCallback?

    init(completion: @escaping (Bool) -> Void) {
        self.completion = completion
        super.init()
        keepAlive = self
    }

    @objc func document(_ document: NSDocument, didSave: Bool, contextInfo: UnsafeMutableRawPointer?) {
        keepAlive = nil
        completion(didSave)
    }
}
