import AppKit
import LaTeXKit
import SwiftUI

/// Bindeglied zwischen SwiftUI und dem AppKit-Editor.
///
/// `NSViewRepresentable` ist Apples offizieller Weg, eine AppKit-Ansicht in
/// SwiftUI einzubetten. Die eigentliche Arbeit macht der `EditorCoordinator`.
struct EditorView: NSViewRepresentable {
    let workspace: DocumentWorkspace
    var fontSize: CGFloat
    var showLineNumbers: Bool
    var autoPairing: Bool
    var highlightCurrentLine: Bool
    var autoCompletion: Bool
    var spellChecking: Bool
    var mathPreview: Bool

    func makeCoordinator() -> EditorCoordinator {
        EditorCoordinator(workspace: workspace)
    }

    func makeNSView(context: Context) -> NSScrollView {
        context.coordinator.makeScrollView(fontSize: fontSize)
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let coordinator = context.coordinator
        coordinator.apply(fontSize: fontSize)
        coordinator.setLineNumbersVisible(showLineNumbers)
        coordinator.textView.autoPairingEnabled = autoPairing
        coordinator.textView.highlightsCurrentLine = highlightCurrentLine
        coordinator.completion.showsWhileTyping = autoCompletion
        coordinator.setSpellChecking(spellChecking)
        coordinator.setMathPreviewEnabled(mathPreview)
        coordinator.updateIssues(workspace.issueSeverityByLine)
    }

    static func dismantleNSView(_ scrollView: NSScrollView, coordinator: EditorCoordinator) {
        coordinator.hideFloatingPanels()
    }
}

/// Baut den Editor auf und verbindet ihn mit dem Arbeitsbereich.
@MainActor
final class EditorCoordinator: NSObject, NSTextViewDelegate, NSTextStorageDelegate, EditorControlling {
    let workspace: DocumentWorkspace
    private(set) var textView: LaTeXTextView!
    private var scrollView: NSScrollView!
    private var ruler: LineNumberRulerView!
    private var highlighter: SyntaxHighlighter!
    private var fontSize: CGFloat = 0
    /// Wurzel des TextKit-Objektgraphen. Beim selbst gebauten Aufbau besitzt nicht
    /// die Textansicht den Text, sondern umgekehrt – ohne diese Referenz würde
    /// der Text sofort wieder freigegeben.
    private var ownedTextStorage: NSTextStorage!

    /// Vorschlagsliste beim Tippen.
    private(set) var completion: CompletionController!
    /// Eingeklappte Abschnitte.
    private(set) var folding: FoldingController!
    /// Formelvorschau über der Formel am Cursor.
    private let mathPreview = MathPreviewController()
    private var mathPreviewEnabled = true
    private var mathPreviewTask: Task<Void, Never>?
    private var selectionCountTask: Task<Void, Never>?
    private var appliedSpellChecking: Bool?
    /// Zählt jede Textänderung – damit Zwischenergebnisse wissen, ob sie noch passen.
    private var editGeneration = 0
    private var proseCache: (generation: Int, ranges: [Range<Int>])?
    private var macroCache: (generation: Int, macros: [MathPreviewSource.Macro])?
    private weak var observedWindow: NSWindow?
    private var windowObservers: [NSObjectProtocol] = []

    init(workspace: DocumentWorkspace) {
        self.workspace = workspace
        super.init()
    }

    // MARK: - Aufbau

    func makeScrollView(fontSize: CGFloat) -> NSScrollView {
        self.fontSize = fontSize
        let attributes = SyntaxTheme.baseAttributes(fontSize: fontSize)

        // Klassischer TextKit-Aufbau: Text → Layout → Container → Ansicht.
        let storage = NSTextStorage(string: workspace.document.text, attributes: attributes)
        ownedTextStorage = storage
        let layoutManager = NSLayoutManager()
        // Nur sichtbare Bereiche sofort layouten – wichtig für lange Dokumente.
        layoutManager.allowsNonContiguousLayout = true
        storage.addLayoutManager(layoutManager)
        let container = NSTextContainer(size: NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
        container.widthTracksTextView = true
        layoutManager.addTextContainer(container)

        let textView = LaTeXTextView(frame: .zero, textContainer: container)
        configure(textView, attributes: attributes)
        self.textView = textView

        let folding = FoldingController(textView: textView)
        layoutManager.delegate = folding
        textView.folding = folding
        self.folding = folding

        let completion = CompletionController(textView: textView)
        completion.documentDirectory = { [weak self] in
            self?.workspace.fileURL?.deletingLastPathComponent()
        }
        completion.perform = { [weak self] edit, requirements in
            _ = self?.workspace.performEdit("Vervollständigen", requirements: requirements) { _, _ in edit }
        }
        textView.completion = completion
        self.completion = completion

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = true
        scrollView.backgroundColor = .textBackgroundColor
        self.scrollView = scrollView

        let ruler = LineNumberRulerView(textView: textView)
        ruler.fontSize = fontSize
        ruler.lineIndex = LineIndex(SyntaxHighlighter.copyUTF16(from: storage))
        scrollView.verticalRulerView = ruler
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true
        ruler.folding = folding
        folding.onChange = { [weak ruler] in ruler?.needsDisplay = true }
        self.ruler = ruler

        storage.delegate = self
        textView.delegate = self

        let highlighter = SyntaxHighlighter(textView: textView)
        highlighter.onAnalysis = { [weak self] analysis in
            self?.analysisDidFinish(analysis)
        }
        self.highlighter = highlighter
        highlighter.invalidateAll()

        // Zeilennummern beim Scrollen mitführen.
        scrollView.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clipViewDidScroll(_:)),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )

        workspace.editor = self
        return scrollView
    }

    private func configure(_ textView: LaTeXTextView, attributes: [NSAttributedString.Key: Any]) {
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true
        // Keine „intelligenten“ Ersetzungen – sie würden LaTeX-Code verfälschen.
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.isGrammarCheckingEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.isAutomaticTextCompletionEnabled = false
        textView.smartInsertDeleteEnabled = false
        textView.allowsDocumentBackgroundColorChange = false

        textView.typingAttributes = attributes
        textView.font = attributes[.font] as? NSFont
        textView.textColor = .textColor
        textView.backgroundColor = .textBackgroundColor
        textView.drawsBackground = true
        textView.textContainerInset = NSSize(width: 6, height: 10)

        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.setAccessibilityLabel("LaTeX-Quelltext")

        textView.lineIndexProvider = { [weak self] in
            self?.highlighter?.latest?.lines
        }
        textView.onCommandClick = { [weak self] index in
            self?.showInPDF(characterIndex: index)
        }
        textView.proseFilter = { [weak self] range in
            self?.isProse(range) ?? true
        }
        textView.onImageFiles = { [weak self] files in
            self?.workspace.insertImageFiles(files)
        }
        textView.onImageData = { [weak self] data in
            self?.workspace.insertPastedImage(data)
        }
        textView.onWindowChange = { [weak self] window in
            self?.observe(window)
        }
    }

    // MARK: - Fenster

    /// Schwebende Fenster ausblenden, wenn das Dokumentfenster nicht mehr vorne ist.
    private func observe(_ window: NSWindow?) {
        guard window !== observedWindow else { return }
        for observer in windowObservers { NotificationCenter.default.removeObserver(observer) }
        windowObservers = []
        observedWindow = window
        guard let window else {
            hideFloatingPanels()
            return
        }
        let center = NotificationCenter.default
        windowObservers.append(center.addObserver(forName: NSWindow.didResignKeyNotification, object: window, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.hideFloatingPanels() }
        })
        windowObservers.append(center.addObserver(forName: NSWindow.didBecomeKeyNotification, object: window, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.scheduleMathPreview() }
        })
        windowObservers.append(center.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.observe(nil) }
        })
    }

    func hideFloatingPanels() {
        completion?.hide()
        mathPreview.hide()
        mathPreviewTask?.cancel()
    }

    // MARK: - Aktualisierung aus SwiftUI

    func apply(fontSize newSize: CGFloat) {
        guard newSize != fontSize, let storage = textView.textStorage else { return }
        fontSize = newSize
        let attributes = SyntaxTheme.baseAttributes(fontSize: newSize)
        storage.beginEditing()
        storage.addAttributes(attributes, range: NSRange(location: 0, length: storage.length))
        storage.endEditing()
        textView.typingAttributes = attributes
        ruler.fontSize = newSize
    }

    func setLineNumbersVisible(_ visible: Bool) {
        if scrollView.rulersVisible != visible {
            scrollView.rulersVisible = visible
        }
    }

    /// Rechtschreibprüfung nur umschalten, wenn sich die Einstellung ändert – über
    /// „Bearbeiten → Rechtschreibung“ darf man sie zwischendurch selbst umstellen.
    func setSpellChecking(_ enabled: Bool) {
        guard enabled != appliedSpellChecking else { return }
        appliedSpellChecking = enabled
        textView.isContinuousSpellCheckingEnabled = enabled
    }

    func setMathPreviewEnabled(_ enabled: Bool) {
        guard enabled != mathPreviewEnabled else { return }
        mathPreviewEnabled = enabled
        if enabled { scheduleMathPreview() } else { mathPreview.hide() }
    }

    func updateIssues(_ issues: [Int: CompileIssue.Severity]) {
        textView.issueLines = issues
        ruler.issueLines = issues
    }

    // MARK: - Ereignisse

    func textDidChange(_ notification: Notification) {
        workspace.document.text = textView.string
        highlighter.scheduleAnalysis()
        workspace.textDidChange()
        updateBracketHighlight()
    }

    func textViewDidChangeSelection(_ notification: Notification) {
        folding.reveal(textView.selectedRange())
        updateBracketHighlight()
        ruler.needsDisplay = true
        workspace.selectionDidChange()
        scheduleMathPreview()
        scheduleSelectionCount()
    }

    /// Rechtschreibprüfung: Treffer ausserhalb des Fliesstexts verwerfen
    /// (zusätzlich zum Filter in `LaTeXTextView`).
    func textView(
        _ view: NSTextView,
        didCheckTextIn range: NSRange,
        types checkingTypes: NSTextCheckingTypes,
        options: [NSSpellChecker.OptionKey: Any],
        results: [NSTextCheckingResult],
        orthography: NSOrthography,
        wordCount: Int
    ) -> [NSTextCheckingResult] {
        textView.filteredCheckingResults(results)
    }

    nonisolated func textStorage(
        _ textStorage: NSTextStorage,
        didProcessEditing editedMask: NSTextStorageEditActions,
        range editedRange: NSRange,
        changeInLength delta: Int
    ) {
        guard editedMask.contains(.editedCharacters) else { return }
        // Texteingaben passieren immer auf dem Hauptthread.
        MainActor.assumeIsolated {
            highlighter?.noteEdit(range: editedRange, changeInLength: delta)
            folding?.noteEdit(editedRange: editedRange, changeInLength: delta)
            editGeneration += 1
        }
    }

    @objc private func clipViewDidScroll(_ notification: Notification) {
        ruler.needsDisplay = true
        completion.reposition()
        if mathPreview.isVisible { scheduleMathPreview() }
    }

    private func analysisDidFinish(_ analysis: TextAnalysis) {
        ruler.lineIndex = analysis.lines
        folding.regions = analysis.folds
        workspace.update(outline: analysis.outline, settings: analysis.settings, scheme: analysis.headingScheme)
        workspace.update(wordCount: analysis.wordCount)
        scheduleSelectionCount()
        scheduleMathPreview()
        // Der Format-Zustand hängt u. a. von der Dokumentklasse ab.
        workspace.selectionDidChange()
        if !textView.issueLines.isEmpty {
            textView.needsDisplay = true
        }
    }

    // MARK: - Fliesstext (Rechtschreibung, Wortzählung)

    /// Liegt `range` ganz im Fliesstext?
    private func isProse(_ range: NSRange) -> Bool {
        let ranges = currentProseRanges()
        var low = 0
        var high = ranges.count - 1
        while low <= high {
            let mid = (low + high) / 2
            let prose = ranges[mid]
            if range.location < prose.lowerBound {
                high = mid - 1
            } else if range.location >= prose.upperBound {
                low = mid + 1
            } else {
                return range.location + range.length <= prose.upperBound
            }
        }
        return false
    }

    /// Fliesstext-Bereiche zum aktuellen Text (bei Bedarf frisch berechnet).
    private func currentProseRanges() -> [Range<Int>] {
        if let proseCache, proseCache.generation == editGeneration { return proseCache.ranges }
        let buffer = snapshot()
        let ranges = ProseScanner.proseRanges(in: buffer, tokenized: LaTeXTokenizer.tokenize(buffer))
        proseCache = (editGeneration, ranges)
        return ranges
    }

    /// Wörter in der Auswahl – kurz verzögert, damit Ziehen mit der Maus flüssig bleibt.
    private func scheduleSelectionCount() {
        selectionCountTask?.cancel()
        let selection = textView.selectedRange()
        guard selection.length > 0 else {
            workspace.selectionWordCount = nil
            return
        }
        selectionCountTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(120))
            guard let self, !Task.isCancelled else { return }
            guard let storage = self.textView.textStorage,
                  let analysis = self.highlighter.latest, analysis.length == storage.length else { return }
            let range = self.textView.selectedRange()
            guard range.length > 0 else {
                self.workspace.selectionWordCount = nil
                return
            }
            self.workspace.selectionWordCount = WordCounter.count(
                in: NSStringSource(storage.mutableString),
                prose: analysis.proseRanges,
                tokenized: analysis.tokenized,
                selection: range.location..<(range.location + range.length)
            )
        }
    }

    // MARK: - Formelvorschau

    private func scheduleMathPreview() {
        mathPreviewTask?.cancel()
        guard mathPreviewEnabled else {
            mathPreview.hide()
            return
        }
        mathPreviewTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(120))
            guard !Task.isCancelled else { return }
            self?.updateMathPreview()
        }
    }

    private func updateMathPreview() {
        guard mathPreviewEnabled, let window = textView.window, window.isKeyWindow,
              window.firstResponder === textView, textView.selectedRanges.count == 1,
              let storage = textView.textStorage else {
            mathPreview.hide()
            return
        }
        let selection = textView.selectedRange()
        guard selection.length == 0 else {
            mathPreview.hide()
            return
        }
        // Erst wenn die Analyse zum aktuellen Text passt (sie folgt gleich).
        guard let analysis = highlighter.latest, analysis.length == storage.length else { return }
        guard analysis.tokenized.isInsideMath(at: selection.location),
              let region = analysis.tokenized.mathRegion(containing: selection.location) else {
            mathPreview.hide()
            return
        }
        let source = NSStringSource(storage.mutableString)
        guard let request = MathPreviewSource.request(for: region, in: source, macros: currentMacros()),
              let anchor = previewAnchor(regionStart: region.range.lowerBound, cursor: selection.location) else {
            mathPreview.hide()
            return
        }
        mathPreview.show(request, above: anchor, in: window)
    }

    /// Über dem Anfang der Formel – oder über dem Cursor, wenn der Anfang nicht zu sehen ist.
    private func previewAnchor(regionStart: Int, cursor: Int) -> NSRect? {
        guard let window = textView.window else { return nil }
        for position in [regionStart, cursor] {
            let rect = textView.firstRect(forCharacterRange: NSRange(location: position, length: 0), actualRange: nil)
            guard rect != .zero else { continue }
            let inView = textView.convert(window.convertFromScreen(rect), from: nil)
            if textView.visibleRect.intersects(inView.insetBy(dx: -1, dy: -1)) { return rect }
        }
        return nil
    }

    private func currentMacros() -> [MathPreviewSource.Macro] {
        if let macroCache, macroCache.generation == editGeneration { return macroCache.macros }
        let macros = MathPreviewSource.macros(in: snapshot())
        macroCache = (editGeneration, macros)
        return macros
    }

    // MARK: - Klammerpaare

    private func updateBracketHighlight() {
        guard let layoutManager = textView.layoutManager,
              let storage = textView.textStorage else { return }
        // Alte Markierungen im ganzen Text entfernen – die Gegenklammer kann
        // weit ausserhalb des sichtbaren Bereichs liegen. Das ist günstig, weil
        // nur Hintergrund-Attribute entfernt werden und kein Layout nötig ist.
        layoutManager.removeTemporaryAttribute(.backgroundColor, forCharacterRange: NSRange(location: 0, length: storage.length))

        let selection = textView.selectedRange()
        guard selection.length == 0 else { return }
        let source = NSStringSource(storage.mutableString)
        guard let match = BracketMatcher.match(in: source, cursor: selection.location) else { return }
        for position in [match.open, match.close] {
            layoutManager.addTemporaryAttribute(
                .backgroundColor,
                value: SyntaxTheme.bracketMatchColor,
                forCharacterRange: NSRange(location: position, length: 1)
            )
        }
    }

    // MARK: - EditorControlling

    private func freshLineIndex() -> LineIndex? {
        guard let storage = textView.textStorage else { return nil }
        return LineIndex(SyntaxHighlighter.copyUTF16(from: storage))
    }

    func reveal(line: Int) {
        guard let lines = freshLineIndex(), let range = lines.range(ofLine: min(max(line, 1), lines.lineCount)) else { return }
        let lineRange = NSRange(location: range.lowerBound, length: range.count)
        textView.setSelectedRange(NSRange(location: range.lowerBound, length: 0))
        scrollToCenter(lineRange)
        if lineRange.length > 0 {
            textView.showFindIndicator(for: lineRange)
        }
    }

    var cursorLine: Int {
        freshLineIndex()?.line(at: textView.selectedRange().location) ?? 1
    }

    func focus() {
        textView.window?.makeFirstResponder(textView)
    }

    var selection: Range<Int> {
        let range = textView.selectedRange()
        return range.location..<(range.location + range.length)
    }

    var source: NSStringSource {
        NSStringSource(textView.textStorage?.mutableString ?? NSMutableString())
    }

    func snapshot() -> [UInt16] {
        guard let storage = textView.textStorage else { return [] }
        return SyntaxHighlighter.copyUTF16(from: storage)
    }

    var currentAnalysis: TokenizedText? {
        guard let latest = highlighter.latest, latest.length == textView.textStorage?.length else { return nil }
        return latest.tokenized
    }

    func apply(_ edit: TextEdit) {
        textView.perform(edit)
    }

    func groupEdits(named actionName: String, _ body: () -> Void) {
        // Getipptes nicht mit der Formatierung zu einem Rückgängig-Schritt verschmelzen.
        textView.breakUndoCoalescing()
        let undoManager = textView.undoManager
        undoManager?.beginUndoGrouping()
        body()
        undoManager?.setActionName(actionName)
        undoManager?.endUndoGrouping()
    }

    var window: NSWindow? { textView.window }

    func showFindBar() {
        focus()
        let item = NSMenuItem()
        item.tag = NSTextFinder.Action.showFindInterface.rawValue
        textView.performTextFinderAction(item)
    }

    func select(_ range: Range<Int>) {
        let nsRange = NSRange(location: range.lowerBound, length: range.count)
        textView.setSelectedRange(nsRange)
        textView.scrollRangeToVisible(nsRange)
    }

    func foldAtCursor() {
        folding.foldAtCursor(line: cursorLine)
    }

    func unfoldAtCursor() {
        folding.unfoldAtCursor()
    }

    func foldAll() {
        folding.foldAll()
    }

    func unfoldAll() {
        folding.unfoldAll()
    }

    func showCompletions() {
        focus()
        completion.showExplicitly()
    }

    private func showInPDF(characterIndex: Int) {
        guard let lines = freshLineIndex() else { return }
        workspace.showInPDF(line: lines.line(at: characterIndex))
    }

    private func scrollToCenter(_ range: NSRange) {
        guard let layoutManager = textView.layoutManager, let container = textView.textContainer else { return }
        layoutManager.ensureLayout(forCharacterRange: range)
        let glyphs = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        var rect = layoutManager.boundingRect(forGlyphRange: glyphs, in: container)
        rect.origin.y += textView.textContainerOrigin.y
        let visibleHeight = scrollView.contentView.bounds.height
        textView.scroll(NSPoint(x: 0, y: max(0, rect.midY - visibleHeight / 2)))
    }
}
