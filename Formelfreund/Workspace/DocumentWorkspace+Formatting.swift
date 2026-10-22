import AppKit
import LaTeXKit
import UniformTypeIdentifiers

/// Formatieren, Bausteine einfügen und Blöcke bearbeiten.
///
/// Jede Aktion berechnet mit LaTeXKit eine `TextEdit` und lässt sie den
/// Editor ausführen – als *ein* Schritt, den ⌘Z wieder rückgängig macht.
/// Braucht eine Formatierung ein Paket (z. B. Farbe → `xcolor`), wird es im
/// selben Schritt in der Präambel ergänzt.
extension DocumentWorkspace {
    // MARK: - Grundbaustein

    /// Führt eine Bearbeitung aus und ergänzt danach fehlende Pakete.
    /// - Returns: `false`, wenn nichts zu tun war (z. B. Cursor in keiner Formel).
    @discardableResult
    func performEdit(
        _ actionName: String,
        requirements: [PackageRequirement] = [],
        _ makeEdit: (NSStringSource, Range<Int>) -> TextEdit?
    ) -> Bool {
        guard let editor else { return false }
        var changed = false
        editor.groupEdits(named: actionName) {
            if let edit = makeEdit(editor.source, editor.selection) {
                editor.apply(edit)
                changed = true
            }
            if changed, !requirements.isEmpty,
               let ensure = PreambleEditor.ensure(requirements, in: editor.source) {
                editor.apply(ensure.preservingSelection(editor.selection))
            }
        }
        if !changed { NSSound.beep() }
        editor.focus()
        return changed
    }

    // MARK: - Zeichenformat

    func toggle(_ style: InlineStyle) {
        performEdit(style.title) { source, selection in
            InlineFormatter.toggle(style, in: source, selection: selection)
        }
    }

    func setFontSize(_ size: FontSize) {
        performEdit("Schriftgrösse") { source, selection in
            InlineFormatter.setFontSize(size, in: source, selection: selection)
        }
    }

    func setColor(_ color: TextColor?) {
        performEdit("Textfarbe", requirements: color == nil ? [] : [.xcolor]) { source, selection in
            InlineFormatter.setColor(color, in: source, selection: selection)
        }
    }

    // MARK: - Absatzformat

    func applyParagraphStyle(_ style: ParagraphStyle) {
        let scheme = headingScheme
        performEdit(style.title) { source, selection in
            ParagraphFormatter.apply(style, in: source, selection: selection, scheme: scheme)
        }
    }

    func align(_ alignment: TextAlignment) {
        performEdit(alignment.title) { source, selection in
            ParagraphFormatter.align(alignment, in: source, selection: selection)
        }
    }

    func toggleList(_ kind: ListKind) {
        performEdit(kind.title) { source, selection in
            ParagraphFormatter.toggleList(kind, in: source, selection: selection)
        }
    }

    func shiftIndentation(outdent: Bool) {
        performEdit(outdent ? "Ausrücken" : "Einrücken") { source, selection in
            BlockEditor.shiftIndentation(in: source, selection: selection, outdent: outdent)
        }
    }

    // MARK: - Bausteine

    func insert(_ snippet: Snippet) {
        let inMath = editor.map { editor in
            editor.currentAnalysis?.isInsideMath(at: editor.selection.lowerBound) ?? false
        } ?? false
        performEdit(snippet.title, requirements: snippet.requirements) { source, selection in
            SnippetInserter.edit(inserting: snippet, in: source, selection: selection, inMath: inMath)
        }
    }

    /// Wählt ein Bild aus, legt es in den Ordner „Bilder“ neben dem Dokument
    /// und fügt eine Abbildung mit Beschriftung ein.
    func insertImageFromFile() {
        guard let documentDirectory = fileURL?.deletingLastPathComponent() else {
            let alert = NSAlert()
            alert.messageText = "Bitte sichere das Dokument zuerst"
            alert.informativeText = "Formelfreund legt Bilder im Ordner „Bilder“ neben deinem Dokument ab. Dafür muss das Dokument einen Speicherort haben (Ablage → Sichern)."
            alert.runModal()
            return
        }

        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .pdf]
        panel.allowsMultipleSelection = false
        panel.message = "Bild für die Abbildung auswählen"
        panel.prompt = "Einfügen"
        guard panel.runModal() == .OK, let source = panel.url else { return }

        let relativePath: String
        do {
            relativePath = try Self.copyIntoDocumentFolder(source, documentDirectory: documentDirectory)
        } catch {
            NSAlert(error: error).runModal()
            return
        }

        let label = (relativePath as NSString).lastPathComponent
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
            .lowercased()
        let snippet = Snippet(
            id: "figure-from-file",
            title: "Bild einfügen",
            category: .figures,
            body: """
            \\begin{figure}[htbp]
              \\centering
              \\includegraphics[width=0.8\\textwidth]{\(relativePath)}
              \\caption{•}
              \\label{fig:\(label)}
            \\end{figure}
            """,
            placement: .block,
            requirements: [.graphicx]
        )
        insert(snippet)
    }

    /// Kopiert ein Bild in `<Dokumentordner>/Bilder/` (falls es nicht schon im
    /// Dokumentordner liegt) und liefert den Pfad relativ zum Dokument.
    private static func copyIntoDocumentFolder(_ source: URL, documentDirectory: URL) throws -> String {
        let documentPath = documentDirectory.standardizedFileURL.path + "/"
        let sourcePath = source.standardizedFileURL.path
        if sourcePath.hasPrefix(documentPath) {
            return String(sourcePath.dropFirst(documentPath.count))
        }
        let fm = FileManager.default
        let folder = documentDirectory.appendingPathComponent("Bilder", isDirectory: true)
        try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        // LaTeX mag keine Leerzeichen in Dateinamen.
        let baseName = source.deletingPathExtension().lastPathComponent.replacingOccurrences(of: " ", with: "-")
        let ext = source.pathExtension.lowercased()
        var target = folder.appendingPathComponent(baseName).appendingPathExtension(ext)
        var counter = 2
        while fm.fileExists(atPath: target.path) {
            target = folder.appendingPathComponent("\(baseName)-\(counter)").appendingPathExtension(ext)
            counter += 1
        }
        try fm.copyItem(at: source, to: target)
        return "Bilder/" + target.lastPathComponent
    }

    // MARK: - Block-Werkzeuge

    func expandSelection() {
        guard let editor else { return }
        let range = BlockEditor.expandSelection(in: editor.source, selection: editor.selection)
        editor.select(range)
    }

    func toggleNumbering() {
        performEdit("Nummerierung") { source, selection in
            BlockEditor.toggleNumbering(in: source, selection: selection)
        }
    }

    func toggleDisplayMath() {
        performEdit("Formel umwandeln") { source, selection in
            BlockEditor.toggleDisplayMath(in: source, selection: selection)
        }
    }

    /// Wandelt die Umgebung am Cursor in eine andere um (z. B. Aufzählung → Nummerierung).
    func convertEnvironment(to newName: String) {
        performEdit("Umgebung umwandeln") { source, selection in
            guard let block = BlockEditor.enclosingEnvironment(in: source, at: selection.lowerBound) else { return nil }
            return BlockEditor.renameEnvironment(block, to: newName, in: source, selection: selection)
        }
    }

    /// Entfernt `\begin…\end` der Umgebung am Cursor, der Inhalt bleibt.
    func unwrapEnvironment() {
        performEdit("Umgebung auflösen") { source, selection in
            guard let block = BlockEditor.enclosingEnvironment(in: source, at: selection.lowerBound) else { return nil }
            return BlockEditor.unwrapEnvironment(block, in: source, selection: selection)
        }
    }

    func wrapSelection(inEnvironment name: String) {
        let requirements: [PackageRequirement] = Self.theoremEnvironments.contains(name) ? [.theorems] : []
        performEdit("In Umgebung einpacken", requirements: requirements) { source, selection in
            BlockEditor.wrap(selection: selection, inEnvironment: name, in: source)
        }
    }

    func moveLines(up: Bool) {
        performEdit(up ? "Zeilen nach oben" : "Zeilen nach unten") { source, selection in
            BlockEditor.moveLines(in: source, selection: selection, up: up)
        }
    }

    func toggleComment() {
        performEdit("Auskommentieren") { source, selection in
            BlockEditor.toggleComment(in: source, selection: selection)
        }
    }

    /// Umgebungen für „In Umgebung einpacken“, in Menü-Reihenfolge.
    static let wrappableEnvironments = [
        "center", "quote", "itemize", "enumerate", "definition", "satz", "beispiel", "bemerkung", "proof", "minipage"
    ]

    /// Diese Umgebungen brauchen die Satz-Definitionen in der Präambel.
    static let theoremEnvironments: Set<String> = ["definition", "satz", "lemma", "korollar", "beispiel", "bemerkung"]

    // MARK: - Dokument-Einstellungen

    func applyDocumentSettings(_ settings: DocumentSettings) {
        performEdit("Dokument-Einstellungen") { source, selection in
            PreambleEditor.apply(settings, in: source)?.preservingSelection(selection)
        }
    }

    // MARK: - Format-Zustand

    /// Der Cursor hat sich bewegt: Format-Zustand kurz darauf im Hintergrund neu berechnen.
    func selectionDidChange() {
        formatStateTask?.cancel()
        formatStateTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(60))
            guard let self, !Task.isCancelled, let editor = self.editor else { return }
            let text = editor.snapshot()
            let selection = editor.selection
            let scheme = self.headingScheme
            let analysis = editor.currentAnalysis
            let state = await Self.computeFormatState(text: text, selection: selection, scheme: scheme, analysis: analysis)
            guard !Task.isCancelled, state != self.formatState else { return }
            self.formatState = state
        }
    }

    private nonisolated static func computeFormatState(
        text: [UInt16],
        selection: Range<Int>,
        scheme: HeadingScheme,
        analysis: TokenizedText?
    ) async -> FormatState {
        FormatState.compute(text: text, selection: selection, scheme: scheme, analysis: analysis)
    }
}
