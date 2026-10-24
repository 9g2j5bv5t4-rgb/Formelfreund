import AppKit
import LaTeXKit

/// Die Textansicht des Editors (AppKit).
///
/// SwiftUIs eigenes `TextEditor` ist für einen Code-Editor zu eingeschränkt:
/// Es fehlen Zeilennummern, schnelles Einfärben und die Kontrolle über
/// einzelne Tastendrücke. Deshalb verwenden wir hier `NSTextView` – dieselbe
/// Komponente, die auch TextEdit und viele Apple-Apps nutzen.
///
/// Diese Klasse kümmert sich um das „Tippgefühl“: Klammern schliessen,
/// Einrücken, Zeilen hervorheben. Die Regeln selbst stehen in
/// `EditingAssistant` (LaTeXKit) und sind dort getestet.
final class LaTeXTextView: NSTextView {
    /// Klammern, `$` und `\begin…\end` automatisch ergänzen.
    var autoPairingEnabled = true

    /// Zeile mit dem Cursor leicht hinterlegen.
    var highlightsCurrentLine = true {
        didSet { if oldValue != highlightsCurrentLine { needsDisplay = true } }
    }

    /// Zeilen mit Fehlern oder Warnungen (1-basiert).
    var issueLines: [Int: CompileIssue.Severity] = [:] {
        didSet { if oldValue != issueLines { needsDisplay = true } }
    }

    /// Liefert die aktuelle Zeilenstruktur (aus der Hintergrund-Analyse).
    var lineIndexProvider: (() -> LineIndex?)?

    /// ⌘-Klick in den Text: Position im PDF zeigen.
    var onCommandClick: ((Int) -> Void)?

    private var lastCurrentLineRect: NSRect = .zero

    /// Text als `UTF16Source` für die Regeln in LaTeXKit – ohne Kopie.
    private var source: NSStringSource {
        NSStringSource(textStorage?.mutableString ?? NSMutableString())
    }

    private var selectionRange: Range<Int> {
        let range = selectedRange()
        return range.location..<(range.location + range.length)
    }

    // MARK: - Tippen

    override func insertText(_ string: Any, replacementRange: NSRange) {
        // Ist genau ein Platzhalter • ausgewählt, ersetzt das Getippte ihn –
        // auch eine Klammer soll ihn ersetzen und nicht „einpacken“.
        if replacementRange.location == NSNotFound, !hasMarkedText(), isPlaceholderSelected {
            let range = selectedRange()
            perform(TextEdit(range: range.location..<(range.location + 1), replacement: "", selectionAfter: range.location..<range.location))
        }
        guard autoPairingEnabled,
              replacementRange.location == NSNotFound,
              !hasMarkedText(),
              selectedRanges.count == 1,
              let typed = (string as? String) ?? (string as? NSAttributedString)?.string,
              let edit = EditingAssistant.editForTyping(typed, in: source, selection: selectionRange)
        else {
            super.insertText(string, replacementRange: replacementRange)
            return
        }
        perform(edit)
    }

    override func insertNewline(_ sender: Any?) {
        if autoPairingEnabled, selectedRanges.count == 1,
           let edit = EditingAssistant.editForNewline(in: source, selection: selectionRange) {
            perform(edit)
        } else {
            super.insertNewline(sender)
        }
    }

    /// Tab springt zum nächsten Platzhalter • im Absatz – sonst normaler Tabulator.
    override func insertTab(_ sender: Any?) {
        if selectedRanges.count == 1, let next = Placeholders.next(in: source, from: selectionRange.upperBound) {
            selectPlaceholder(next)
        } else {
            super.insertTab(sender)
        }
    }

    /// ⇧Tab springt zum vorherigen Platzhalter.
    override func insertBacktab(_ sender: Any?) {
        if selectedRanges.count == 1, let previous = Placeholders.previous(in: source, before: selectionRange.lowerBound) {
            selectPlaceholder(previous)
        } else {
            super.insertBacktab(sender)
        }
    }

    private func selectPlaceholder(_ range: Range<Int>) {
        let nsRange = NSRange(location: range.lowerBound, length: range.count)
        setSelectedRange(nsRange)
        scrollRangeToVisible(nsRange)
    }

    /// Ist genau ein Platzhalter • ausgewählt?
    private var isPlaceholderSelected: Bool {
        let range = selectedRange()
        guard selectedRanges.count == 1, range.length == 1, let storage = textStorage, range.location < storage.length else { return false }
        return storage.mutableString.character(at: range.location) == Placeholders.unit
    }

    override func deleteBackward(_ sender: Any?) {
        if autoPairingEnabled, selectedRanges.count == 1,
           let edit = EditingAssistant.editForDeleteBackward(in: source, selection: selectionRange) {
            perform(edit)
        } else {
            super.deleteBackward(sender)
        }
    }

    /// Führt eine berechnete Änderung so aus, dass Rückgängig (⌘Z) funktioniert.
    func perform(_ edit: TextEdit) {
        if edit.changesText {
            let range = NSRange(location: edit.range.lowerBound, length: edit.range.count)
            guard shouldChangeText(in: range, replacementString: edit.replacement) else { return }
            textStorage?.replaceCharacters(
                in: range,
                with: NSAttributedString(string: edit.replacement, attributes: typingAttributes)
            )
            didChangeText()
        }
        let selection = NSRange(location: edit.selectionAfter.lowerBound, length: edit.selectionAfter.count)
        setSelectedRange(selection)
        scrollRangeToVisible(selection)
    }

    // MARK: - Maus

    override func mouseDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command), let onCommandClick {
            let point = convert(event.locationInWindow, from: nil)
            let index = characterIndexForInsertion(at: point)
            setSelectedRange(NSRange(location: index, length: 0))
            onCommandClick(index)
            return
        }
        super.mouseDown(with: event)
    }

    // MARK: - Hervorhebungen im Hintergrund

    override func setSelectedRanges(_ ranges: [NSValue], affinity: NSSelectionAffinity, stillSelecting: Bool) {
        super.setSelectedRanges(ranges, affinity: affinity, stillSelecting: stillSelecting)
        guard highlightsCurrentLine else { return }
        let newRect = currentLineRect()
        if newRect != lastCurrentLineRect {
            setNeedsDisplay(lastCurrentLineRect.insetBy(dx: 0, dy: -1))
            setNeedsDisplay(newRect.insetBy(dx: 0, dy: -1))
            lastCurrentLineRect = newRect
        }
    }

    override func drawBackground(in rect: NSRect) {
        super.drawBackground(in: rect)

        // Zeilen mit Fehlern/Warnungen
        if !issueLines.isEmpty, let lines = lineIndexProvider?() {
            let length = textStorage?.length ?? 0
            for (line, severity) in issueLines {
                guard let range = lines.range(ofLine: line), range.upperBound <= length else { continue }
                let lineRect = rectForCharacters(NSRange(location: range.lowerBound, length: range.count))
                guard lineRect.intersects(rect) else { continue }
                SyntaxTheme.issueLineColor(severity).setFill()
                lineRect.fill(using: .sourceOver)
            }
        }

        // Zeile mit dem Cursor
        if highlightsCurrentLine, selectedRange().length == 0 {
            let lineRect = currentLineRect()
            if lineRect.intersects(rect) {
                SyntaxTheme.currentLineColor.setFill()
                lineRect.fill(using: .sourceOver)
            }
        }
    }

    /// Rechteck der (sichtbaren) Zeile, in der der Cursor steht.
    private func currentLineRect() -> NSRect {
        guard selectedRange().length == 0 else { return .zero }
        return rectForCharacters(NSRange(location: selectedRange().location, length: 0))
    }

    /// Volle Breite der Zeile(n), die einen Zeichenbereich enthalten.
    func rectForCharacters(_ characterRange: NSRange) -> NSRect {
        guard let layoutManager, let textStorage else { return .zero }
        var rect: NSRect
        let isAtEnd = characterRange.location >= textStorage.length
        if isAtEnd {
            // Cursor am Textende: eigene (evtl. leere) letzte Zeile.
            if !layoutManager.extraLineFragmentRect.isEmpty {
                rect = layoutManager.extraLineFragmentRect
            } else if textStorage.length > 0 {
                let glyph = layoutManager.glyphIndexForCharacter(at: textStorage.length - 1)
                rect = layoutManager.lineFragmentRect(forGlyphAt: glyph, effectiveRange: nil)
            } else {
                return .zero
            }
        } else {
            let firstGlyph = layoutManager.glyphIndexForCharacter(at: characterRange.location)
            rect = layoutManager.lineFragmentRect(forGlyphAt: firstGlyph, effectiveRange: nil)
            if characterRange.length > 0 {
                let lastCharacter = min(NSMaxRange(characterRange) - 1, textStorage.length - 1)
                let lastGlyph = layoutManager.glyphIndexForCharacter(at: lastCharacter)
                rect = rect.union(layoutManager.lineFragmentRect(forGlyphAt: lastGlyph, effectiveRange: nil))
            }
        }
        rect.origin.x = 0
        rect.size.width = bounds.width
        rect.origin.y += textContainerOrigin.y
        return rect
    }
}
