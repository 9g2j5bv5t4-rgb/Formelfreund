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
        coordinator.updateIssues(workspace.issueSeverityByLine)
    }
}

/// Baut den Editor auf und verbindet ihn mit dem Arbeitsbereich.
@MainActor
final class EditorCoordinator: NSObject, @preconcurrency NSTextViewDelegate, NSTextStorageDelegate, EditorControlling {
    let workspace: DocumentWorkspace
    private(set) var textView: LaTeXTextView!
    private var scrollView: NSScrollView!
    private var ruler: LineNumberRulerView!
    private var highlighter: SyntaxHighlighter!
    private var fontSize: CGFloat = 0

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
        updateBracketHighlight()
        ruler.needsDisplay = true
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
        }
    }

    @objc private func clipViewDidScroll(_ notification: Notification) {
        ruler.needsDisplay = true
    }

    private func analysisDidFinish(_ analysis: TextAnalysis) {
        ruler.lineIndex = analysis.lines
        workspace.update(outline: analysis.outline)
        if !textView.issueLines.isEmpty {
            textView.needsDisplay = true
        }
    }

    // MARK: - Klammerpaare

    private func updateBracketHighlight() {
        guard let layoutManager = textView.layoutManager,
              let storage = textView.textStorage,
              let container = textView.textContainer else { return }
        // Alte Markierungen im sichtbaren Bereich entfernen.
        let visibleGlyphs = layoutManager.glyphRange(forBoundingRect: textView.visibleRect, in: container)
        let visibleCharacters = layoutManager.characterRange(forGlyphRange: visibleGlyphs, actualGlyphRange: nil)
        layoutManager.removeTemporaryAttribute(.backgroundColor, forCharacterRange: visibleCharacters)

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
