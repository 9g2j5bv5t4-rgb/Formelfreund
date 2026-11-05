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
    /// - Parameter bodyOnly: Nur im Textteil erlaubt (Formatierungen gehören nicht in die Präambel).
    @discardableResult
    func performEdit(
        _ actionName: String,
        requirements: [PackageRequirement] = [],
        bodyOnly: Bool = false,
        _ makeEdit: (NSStringSource, Range<Int>) -> TextEdit?
    ) -> Bool {
        guard let editor else { return false }
        if bodyOnly, let body = InsertionPlanner.bodyRange(in: editor.source),
           editor.selection.lowerBound < body.lowerBound || editor.selection.upperBound > body.upperBound {
            NSSound.beep()
            show(Notice("Formatierungen wirken nur im Textteil – setze den Cursor hinter \\begin{document}.", style: .warning))
            return false
        }
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
        performEdit(style.title, bodyOnly: true) { source, selection in
            InlineFormatter.toggle(style, in: source, selection: selection)
        }
    }

    func setFontSize(_ size: FontSize) {
        performEdit("Schriftgrösse", bodyOnly: true) { source, selection in
            InlineFormatter.setFontSize(size, in: source, selection: selection)
        }
    }

    func setColor(_ color: TextColor?) {
        performEdit("Textfarbe", requirements: color == nil ? [] : [.xcolor], bodyOnly: true) { source, selection in
            InlineFormatter.setColor(color, in: source, selection: selection)
        }
    }

    // MARK: - Absatzformat

    func applyParagraphStyle(_ style: ParagraphStyle) {
        let scheme = headingScheme
        performEdit(style.title, bodyOnly: true) { source, selection in
            ParagraphFormatter.apply(style, in: source, selection: selection, scheme: scheme)
        }
    }

    func align(_ alignment: TextAlignment) {
        performEdit(alignment.title, bodyOnly: true) { source, selection in
            ParagraphFormatter.align(alignment, in: source, selection: selection)
        }
    }

    func toggleList(_ kind: ListKind) {
        performEdit(kind.title, bodyOnly: true) { source, selection in
            ParagraphFormatter.toggleList(kind, in: source, selection: selection)
        }
    }

    func shiftIndentation(outdent: Bool) {
        performEdit(outdent ? "Ausrücken" : "Einrücken") { source, selection in
            BlockEditor.shiftIndentation(in: source, selection: selection, outdent: outdent)
        }
    }

    // MARK: - Bausteine

    /// Fügt einen Baustein ein – an der nächsten Stelle, an der er Sinn ergibt
    /// (siehe `InsertionPlanner`), und meldet, wenn er woanders gelandet ist.
    func insert(_ snippet: Snippet) {
        guard let editor else { return }
        let analysis = editor.currentAnalysis ?? LaTeXTokenizer.tokenize(editor.snapshot())
        let plan = InsertionPlanner.plan(for: snippet, in: editor.source, selection: editor.selection, analysis: analysis)
        let inMath = analysis.isInsideMath(at: plan.selection.lowerBound)
        let changed = performEdit(snippet.title, requirements: snippet.requirements) { source, _ in
            SnippetInserter.edit(inserting: snippet, in: source, selection: plan.selection, inMath: inMath)
        }
        if changed, let note = plan.note {
            show(Notice(note, symbol: "arrow.turn.down.right"))
        }
    }

    /// Fügt ein mathematisches Zeichen ein (ausserhalb einer Formel in `$…$`).
    func insert(_ symbol: MathSymbol) {
        guard let editor else { return }
        let analysis = editor.currentAnalysis ?? LaTeXTokenizer.tokenize(editor.snapshot())
        let plan = InsertionPlanner.plan(for: symbol.snippet(inMath: false), in: editor.source, selection: editor.selection, analysis: analysis)
        insert(symbol.snippet(inMath: analysis.isInsideMath(at: plan.selection.lowerBound)))
    }

    /// Wählt ein Bild aus, legt es in den Ordner „Bilder“ neben dem Dokument
    /// und fügt eine Abbildung mit Beschriftung ein.
    func insertImageFromFile() {
        guard requireDocumentDirectory() != nil else { return }
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .pdf]
        panel.allowsMultipleSelection = false
        panel.message = "Bild für die Abbildung auswählen"
        panel.prompt = "Einfügen"
        guard panel.runModal() == .OK, let source = panel.url else { return }
        insertImageFiles([source])
    }

    /// Bilder, die in den Editor gezogen oder eingesetzt wurden – an der Cursorposition.
    func insertImageFiles(_ files: [URL]) {
        guard let documentDirectory = requireDocumentDirectory() else { return }
        var copied: [String] = []
        for file in files {
            do {
                copied.append(try Self.copyIntoDocumentFolder(file, documentDirectory: documentDirectory))
            } catch {
                NSAlert(error: error).runModal()
            }
        }
        for relativePath in copied {
            insertFigure(relativePath: relativePath)
        }
        if copied.count > 1 {
            show(Notice("\(copied.count) Bilder eingefügt", symbol: "photo.on.rectangle"))
        }
    }

    /// Ein Bild aus der Zwischenablage (z. B. Bildschirmfoto mit ⌃⇧⌘4) als PNG ablegen und einfügen.
    func insertPastedImage(_ data: Data) {
        guard let documentDirectory = requireDocumentDirectory() else { return }
        guard let image = NSBitmapImageRep(data: data), let png = image.representation(using: .png, properties: [:]) else {
            NSSound.beep()
            return
        }
        let folder = documentDirectory.appendingPathComponent("Bilder", isDirectory: true)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let baseName = "Bild-" + formatter.string(from: Date())
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            var target = folder.appendingPathComponent(baseName).appendingPathExtension("png")
            var counter = 2
            while FileManager.default.fileExists(atPath: target.path) {
                target = folder.appendingPathComponent("\(baseName)-\(counter)").appendingPathExtension("png")
                counter += 1
            }
            try png.write(to: target)
            insertFigure(relativePath: "Bilder/" + target.lastPathComponent)
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    /// Ordner des Dokuments – oder eine Erklärung, warum erst gespeichert werden muss.
    private func requireDocumentDirectory() -> URL? {
        if let directory = fileURL?.deletingLastPathComponent() { return directory }
        let alert = NSAlert()
        alert.messageText = "Bitte speichere das Dokument zuerst"
        alert.informativeText = "Lemma legt Bilder im Ordner „Bilder“ neben deinem Dokument ab. Dafür braucht das Dokument einen Speicherort (Ablage → Speichern)."
        alert.addButton(withTitle: "Speichern …")
        alert.addButton(withTitle: "Abbrechen")
        if alert.runModal() == .alertFirstButtonReturn {
            saveDocument()
        }
        return nil
    }

    /// Abbildung mit Beschriftung und Marke für ein Bild im Dokumentordner.
    private func insertFigure(relativePath: String) {
        let label = (relativePath as NSString).deletingPathExtension
            .components(separatedBy: "/").last?
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
            .lowercased() ?? "bild"
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
    ///
    /// LaTeX verträgt in Dateinamen keine Leer- und Sonderzeichen wie `%` oder `#`.
    /// Solche Bilder werden deshalb unter einem bereinigten Namen kopiert.
    private static func copyIntoDocumentFolder(_ source: URL, documentDirectory: URL) throws -> String {
        let documentPath = documentDirectory.standardizedFileURL.path + "/"
        let sourcePath = source.standardizedFileURL.path
        if sourcePath.hasPrefix(documentPath) {
            let relative = String(sourcePath.dropFirst(documentPath.count))
            if relative.unicodeScalars.allSatisfy(isSafeInPath) { return relative }
        }
        let fm = FileManager.default
        let folder = documentDirectory.appendingPathComponent("Bilder", isDirectory: true)
        try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        let baseName = sanitizedFileName(source.deletingPathExtension().lastPathComponent)
        let ext = sanitizedFileName(source.pathExtension.lowercased())
        var target = folder.appendingPathComponent(baseName).appendingPathExtension(ext)
        var counter = 2
        while fm.fileExists(atPath: target.path) {
            target = folder.appendingPathComponent("\(baseName)-\(counter)").appendingPathExtension(ext)
            counter += 1
        }
        try fm.copyItem(at: source, to: target)
        return "Bilder/" + target.lastPathComponent
    }

    /// Nur ASCII-Buchstaben, Ziffern, `-`, `_`, `.` und `/` sind in LaTeX-Pfaden unproblematisch.
    private static func isSafeInPath(_ scalar: Unicode.Scalar) -> Bool {
        scalar.isASCII && (CharacterSet.alphanumerics.contains(scalar) || "-_./".unicodeScalars.contains(scalar))
    }

    /// Ersetzt alles ausser Buchstaben, Ziffern, `-` und `_` durch `-` (Umlaute: ä → ae …).
    private static func sanitizedFileName(_ name: String) -> String {
        let transliterated = name
            .replacingOccurrences(of: "ä", with: "ae").replacingOccurrences(of: "ö", with: "oe")
            .replacingOccurrences(of: "ü", with: "ue").replacingOccurrences(of: "Ä", with: "Ae")
            .replacingOccurrences(of: "Ö", with: "Oe").replacingOccurrences(of: "Ü", with: "Ue")
            .replacingOccurrences(of: "ß", with: "ss")
        let cleaned = String(String.UnicodeScalarView(transliterated.unicodeScalars.map { scalar in
            scalar.isASCII && (CharacterSet.alphanumerics.contains(scalar) || scalar == "-" || scalar == "_") ? scalar : "-"
        }))
        let collapsed = cleaned.split(separator: "-", omittingEmptySubsequences: true).joined(separator: "-")
        return collapsed.isEmpty ? "bild" : collapsed
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
