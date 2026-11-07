import AppKit
import LaTeXKit
import SwiftUI

/// Autovervollständigung im Editor: zeigt beim Tippen passende Befehle unter dem Cursor.
///
/// - Erscheint nach `\` und einem Buchstaben, nach `\begin{`, `\ref{`, `\cite{` …
/// - ↑ ↓ wählen, ↩ oder ⇥ fügt ein, esc schliesst. esc ohne Liste öffnet sie.
/// - Die Regeln (was passt, was eingefügt wird) stehen in `CompletionEngine` (LaTeXKit).
@MainActor
final class CompletionController {
    private weak var textView: LaTeXTextView?
    private let model = CompletionListModel()
    private var panelStorage: FloatingPanel?
    private(set) var context: CompletionContext?

    /// Beim Tippen automatisch zeigen (Einstellungen). esc zeigt die Liste immer.
    var showsWhileTyping = true
    /// Ordner des Dokuments – dort liegen die `.bib`-Dateien.
    var documentDirectory: () -> URL? = { nil }
    /// Führt die Einfügung aus und ergänzt benötigte Pakete in der Präambel.
    var perform: (TextEdit, [PackageRequirement]) -> Void = { _, _ in }

    private var bibliographyCache: [URL: (date: Date, entries: [BibliographyEntry])] = [:]

    static let width: CGFloat = 430
    static let visibleRows = 8

    init(textView: LaTeXTextView) {
        self.textView = textView
        model.onAccept = { [weak self] index in self?.accept(at: index) }
    }

    var isVisible: Bool { context != nil && panelStorage?.isVisible == true }

    /// Das Fenster entsteht erst, wenn es zum ersten Mal gebraucht wird.
    private var panel: FloatingPanel {
        if let panelStorage { return panelStorage }
        let created = FloatingPanel(content: FirstMouseHostingView(rootView: CompletionListView(model: model)), material: .menu)
        panelStorage = created
        return created
    }

    // MARK: - Auslöser

    /// Nach jedem getippten Zeichen (`typed`) bzw. nach dem Löschen (`nil`).
    func textDidChange(typed: String?) {
        if typed == nil {
            // Beim Löschen nur eine schon offene Liste nachführen.
            if isVisible { update(explicit: false) }
            return
        }
        guard showsWhileTyping || isVisible else { return }
        update(explicit: false)
    }

    /// esc bzw. ⌥esc: Liste auch ohne getippten Buchstaben zeigen.
    func showExplicitly() {
        update(explicit: true)
        if context == nil { NSSound.beep() }
    }

    func hide() {
        context = nil
        panelStorage?.hide()
    }

    /// Nach dem Scrollen: Liste mitführen oder ausblenden, wenn die Stelle nicht mehr zu sehen ist.
    func reposition() {
        guard isVisible, let context else { return }
        if !place(at: context.range.lowerBound) { hide() }
    }

    // MARK: - Tasten

    /// Tasten, die bei offener Liste ihr gehören. `true` = erledigt.
    func handle(_ selector: Selector) -> Bool {
        guard isVisible, let context, !model.items.isEmpty else { return false }
        switch selector {
        case #selector(NSResponder.moveDown(_:)):
            model.selectedIndex = min(model.selectedIndex + 1, model.items.count - 1)
            return true
        case #selector(NSResponder.moveUp(_:)):
            model.selectedIndex = max(model.selectedIndex - 1, 0)
            return true
        case #selector(NSResponder.pageDown(_:)), #selector(NSResponder.scrollPageDown(_:)):
            model.selectedIndex = min(model.selectedIndex + Self.visibleRows, model.items.count - 1)
            return true
        case #selector(NSResponder.pageUp(_:)), #selector(NSResponder.scrollPageUp(_:)):
            model.selectedIndex = max(model.selectedIndex - Self.visibleRows, 0)
            return true
        case #selector(NSResponder.insertNewline(_:)):
            // `\item` schon ganz getippt oder `\begin{list}` statt des Vorschlags `itemize`:
            // ↩ beginnt eine neue Zeile (bei \begin{…} samt passendem \end{…}).
            if !CompletionEngine.returnAccepts(model.items[model.selectedIndex], context: context) {
                hide()
                return false
            }
            accept(at: model.selectedIndex)
            return true
        case #selector(NSResponder.insertTab(_:)):
            accept(at: model.selectedIndex)
            return true
        case #selector(NSResponder.cancelOperation(_:)):
            hide()
            return true
        case #selector(NSResponder.moveLeft(_:)), #selector(NSResponder.moveRight(_:)),
             #selector(NSResponder.moveToBeginningOfLine(_:)), #selector(NSResponder.moveToEndOfLine(_:)),
             #selector(NSResponder.moveToBeginningOfDocument(_:)), #selector(NSResponder.moveToEndOfDocument(_:)):
            hide()
            return false
        default:
            return false
        }
    }

    // MARK: - Liste berechnen

    private func update(explicit: Bool) {
        guard let textView, let storage = textView.textStorage,
              textView.selectedRanges.count == 1, textView.selectedRange().length == 0 else {
            hide()
            return
        }
        let cursor = textView.selectedRange().location
        let text = SyntaxHighlighter.copyUTF16(from: storage)
        guard var found = CompletionEngine.context(in: text, cursor: cursor, inMath: false) else {
            hide()
            return
        }
        if found.kind == .command {
            // Erst ab dem ersten Buchstaben – nach `\\` oder `\,` soll nichts aufgehen.
            if found.prefix.isEmpty && !explicit && !isVisible {
                hide()
                return
            }
            found.inMath = LaTeXTokenizer.tokenize(text).isInsideMath(at: cursor)
        }
        let symbols = DocumentSymbols.scan(text)
        let bibliography = found.kind == .citation ? loadBibliography(symbols.bibliographyFiles) : []
        let openEnvironment = found.kind == .environment(isEnd: true)
            ? CompletionEngine.openEnvironment(in: text, before: found.commandStart)
            : nil
        let items = CompletionEngine.suggestions(for: found, symbols: symbols, bibliography: bibliography, openEnvironment: openEnvironment)
        // Nichts Passendes – oder nur genau das, was schon dasteht.
        guard !items.isEmpty,
              explicit || items.count > 1 || !CompletionEngine.isAlreadyComplete(items[0], context: found) else {
            hide()
            return
        }
        // Bisher gewählter Eintrag (falls die Liste schon offen war).
        let previous: String? = context != nil && model.items.indices.contains(model.selectedIndex)
            ? model.items[model.selectedIndex].id
            : nil
        context = found
        model.items = items
        model.prefix = found.prefix
        // Auswahl beibehalten, wenn der Eintrag weiter passt.
        model.selectedIndex = previous.flatMap { id in items.firstIndex { $0.id == id } } ?? 0
        if !place(at: found.range.lowerBound) { hide() }
    }

    /// Setzt die Liste unter die Stelle; `false`, wenn sie nicht sichtbar ist.
    @discardableResult
    private func place(at position: Int) -> Bool {
        guard let textView, let window = textView.window else { return false }
        let caret = textView.firstRect(forCharacterRange: NSRange(location: position, length: 0), actualRange: nil)
        guard caret != .zero else { return false }
        // Ist die Stelle im sichtbaren Teil des Editors?
        let caretInWindow = window.convertFromScreen(caret)
        let caretInView = textView.convert(caretInWindow, from: nil)
        guard textView.visibleRect.insetBy(dx: -2, dy: -2).intersects(caretInView) else { return false }

        let rows = min(model.items.count, Self.visibleRows)
        let size = NSSize(width: Self.width, height: CGFloat(rows) * CompletionListView.rowHeight + CompletionListView.chromeHeight)
        // Befehle in der Liste stehen genau unter dem Getippten.
        let anchor = caret.offsetBy(dx: -CompletionListView.labelInset, dy: 0)
        panel.show(frame: FloatingPanel.frame(size: size, below: anchor), over: window)
        return true
    }

    // MARK: - Einfügen

    private func accept(at index: Int) {
        guard let context, let textView, let storage = textView.textStorage, model.items.indices.contains(index) else { return }
        let item = model.items[index]
        let edit = CompletionEngine.edit(applying: item, context: context, in: NSStringSource(storage.mutableString))
        hide()
        perform(edit, item.requirements)
        if item.continuesCompletion {
            // `\begin{` → gleich die Umgebungen zeigen.
            DispatchQueue.main.async { [weak self] in self?.update(explicit: true) }
        }
    }

    /// Einträge aus den `.bib`-Dateien neben dem Dokument (zwischengespeichert, bis sich die Datei ändert).
    private func loadBibliography(_ files: [String]) -> [BibliographyEntry] {
        guard let directory = documentDirectory() else { return [] }
        var entries: [BibliographyEntry] = []
        for file in files {
            let url = directory.appendingPathComponent(file)
            guard let date = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date else { continue }
            if let cached = bibliographyCache[url], cached.date == date {
                entries += cached.entries
                continue
            }
            guard let data = try? Data(contentsOf: url) else { continue }
            let parsed = BibliographyParser.entries(in: TeXDocument.decode(data))
            bibliographyCache[url] = (date, parsed)
            entries += parsed
        }
        return entries
    }
}

// MARK: - Darstellung

@MainActor
@Observable
final class CompletionListModel {
    var items: [CompletionItem] = []
    var selectedIndex = 0
    var prefix = ""
    @ObservationIgnored var onAccept: (@MainActor (Int) -> Void)?
}

/// Die Liste – aufgebaut wie ein Menü von macOS: Zeichen bzw. Symbol, Befehl, Erklärung.
struct CompletionListView: View {
    let model: CompletionListModel

    static let rowHeight: CGFloat = 26
    /// Innenabstand oben/unten plus Fusszeile.
    static let chromeHeight: CGFloat = 8 + 23
    /// Abstand vom linken Rand bis zum Befehlstext (damit er unter dem Getippten steht).
    static let labelInset: CGFloat = 4 + 8 + 22 + 8

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(model.items.enumerated()), id: \.offset) { index, item in
                            CompletionRow(item: item, isSelected: index == model.selectedIndex)
                                .id(index)
                                .contentShape(Rectangle())
                                .onTapGesture { model.onAccept?(index) }
                        }
                    }
                    .padding(4)
                }
                .scrollIndicators(.automatic)
                .onChange(of: model.selectedIndex) { _, index in
                    proxy.scrollTo(index)
                }
            }
            Divider()
            footer
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if let requirements = selectedItem?.requirements, !requirements.isEmpty {
                Label("Lädt \(requirements.map(\.name).joined(separator: ", "))", systemImage: "shippingbox")
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Text("↩ einfügen")
            Text("esc schliessen")
        }
        .font(.system(size: 10.5))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .frame(height: 22)
    }

    private var selectedItem: CompletionItem? {
        model.items.indices.contains(model.selectedIndex) ? model.items[model.selectedIndex] : nil
    }
}

private struct CompletionRow: View {
    let item: CompletionItem
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            badge
            Text(item.label)
                .font(.system(size: 12.5, design: .monospaced))
                .lineLimit(1)
                .layoutPriority(1)
            Spacer(minLength: 8)
            Text(item.detail)
                .font(.system(size: 11))
                .foregroundStyle(isSelected ? AnyShapeStyle(Color.white.opacity(0.85)) : AnyShapeStyle(.secondary))
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.horizontal, 8)
        .frame(height: CompletionListView.rowHeight)
        .foregroundStyle(isSelected ? AnyShapeStyle(Color.white) : AnyShapeStyle(.primary))
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 6).fill(Color.accentColor)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// Farbiges Kästchen wie in Xcode – mit dem Zeichen selbst bei Symbolen.
    private var badge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(tint.gradient)
            if let glyph = item.glyph {
                Text(verbatim: glyph)
                    .font(.system(size: 13, design: .serif))
                    .minimumScaleFactor(0.5)
            } else {
                Image(systemName: symbol)
                    .font(.system(size: 10.5, weight: .semibold))
            }
        }
        .foregroundStyle(.white)
        .frame(width: 22, height: 20)
    }

    private var symbol: String {
        switch item.kind {
        case .command, .symbol: return item.isMath ? "x.squareroot" : "chevron.left.forwardslash.chevron.right"
        case .environment: return "square.stack"
        case .userCommand: return "star"
        case .reference: return "link"
        case .citation: return "quote.opening"
        case .package: return "shippingbox"
        case .documentClass: return "doc"
        }
    }

    private var tint: Color {
        switch item.kind {
        case .command: return item.isMath ? .teal : .blue
        case .symbol: return .teal
        case .environment: return .purple
        case .userCommand: return .green
        case .reference: return .orange
        case .citation: return .brown
        case .package: return .indigo
        case .documentClass: return .gray
        }
    }
}
