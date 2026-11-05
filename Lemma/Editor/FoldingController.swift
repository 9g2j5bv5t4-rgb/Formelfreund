import AppKit
import LaTeXKit

/// Einklappen von Abschnitten, Umgebungen und der Präambel.
///
/// Der Text selbst bleibt unverändert (Speichern, Kompilieren und Suchen sehen
/// alles). Ausgeblendet wird nur in der Darstellung: Der Layout-Manager zeichnet
/// die Zeichen eines eingeklappten Bereichs nicht und setzt an seinen Anfang
/// eine kleine Kapsel „⋯“. Ein Klick darauf – oder auf das Dreieck neben der
/// Zeilennummer – klappt wieder auf. Steht der Cursor (etwa nach einer Suche)
/// in einem eingeklappten Bereich, klappt er automatisch auf.
@MainActor
final class FoldingController: NSObject, NSLayoutManagerDelegate {
    private weak var textView: NSTextView?
    /// Eingeklappte Bereiche – sortiert, ohne Überlappung.
    private(set) var folds: [Range<Int>] = []
    /// Was sich einklappen lässt (aus der Hintergrund-Analyse).
    var regions: [FoldingRegion] = [] {
        didSet { if oldValue != regions { onChange?() } }
    }
    /// Nach jeder Änderung (Zeilennummern neu zeichnen).
    var onChange: (() -> Void)?

    /// Breite der Kapsel „⋯“ am Anfang eines eingeklappten Bereichs.
    nonisolated static let markerWidth: CGFloat = 34

    init(textView: NSTextView) {
        self.textView = textView
        super.init()
    }

    // MARK: - Abfragen

    /// Eingeklappter Bereich, der die Position enthält.
    func fold(containing position: Int) -> Range<Int>? {
        Self.fold(containing: position, in: folds)
    }

    /// Binäre Suche in sortierten, nicht überlappenden Bereichen.
    nonisolated static func fold(containing position: Int, in folds: [Range<Int>]) -> Range<Int>? {
        var low = 0
        var high = folds.count - 1
        while low <= high {
            let mid = (low + high) / 2
            let fold = folds[mid]
            if position < fold.lowerBound {
                high = mid - 1
            } else if position >= fold.upperBound {
                low = mid + 1
            } else {
                return fold
            }
        }
        return nil
    }

    /// Ist die Zeile, die bei `lineStart` beginnt, im eingeklappten Bereich darüber verschwunden?
    func isLineHidden(startingAt lineStart: Int) -> Bool {
        lineStart > 0 && fold(containing: lineStart - 1) != nil
    }

    func isFolded(_ region: FoldingRegion) -> Bool {
        folds.contains(region.hiddenRange)
    }

    // MARK: - Ein- und Ausklappen

    /// Klappt den Bereich in Zeile `line` ein bzw. wieder auf. `false`, wenn dort keiner beginnt.
    @discardableResult
    func toggle(line: Int) -> Bool {
        guard let region = FoldingRegions.region(startingAt: line, in: regions) else { return false }
        if let existing = folds.first(where: { $0.lowerBound == region.hiddenRange.lowerBound }) {
            unfold(existing)
        } else {
            fold(region.hiddenRange)
        }
        return true
    }

    func fold(_ range: Range<Int>) {
        guard let length = textView?.textStorage?.length, range.lowerBound >= 0, range.upperBound <= length, !range.isEmpty else { return }
        // Liegt schon in einem eingeklappten Bereich.
        if folds.contains(where: { $0.lowerBound <= range.lowerBound && range.upperBound <= $0.upperBound }) { return }
        // Innere eingeklappte Bereiche gehen im äusseren auf; teilweise Überlappung wird aufgelöst.
        folds.removeAll { $0.overlaps(range) }
        folds.append(range)
        folds.sort { $0.lowerBound < $1.lowerBound }
        invalidate(range)
    }

    func unfold(_ range: Range<Int>) {
        guard let index = folds.firstIndex(of: range) else { return }
        folds.remove(at: index)
        invalidate(range)
    }

    /// Innersten Bereich am Cursor einklappen.
    func foldAtCursor(line: Int) {
        guard let textView else { return }
        let position = textView.selectedRange().location
        guard let region = FoldingRegions.innermostRegion(containing: position, line: line, in: regions) else {
            NSSound.beep()
            return
        }
        fold(region.hiddenRange)
        // Der Cursor darf nicht im Ausgeblendeten stehen.
        if region.hiddenRange.contains(position) {
            textView.setSelectedRange(NSRange(location: region.hiddenRange.lowerBound, length: 0))
        }
    }

    /// Eingeklappten Bereich in der Zeile des Cursors aufklappen.
    func unfoldAtCursor() {
        guard let textView, let storage = textView.textStorage else { return }
        let source = NSStringSource(storage.mutableString)
        let position = textView.selectedRange().location
        let lineEnd = source.lineEnd(after: position)
        if let fold = folds.first(where: { $0.lowerBound == lineEnd }) ?? fold(containing: position) {
            unfold(fold)
        } else {
            NSSound.beep()
        }
    }

    func foldAll() {
        let outermost = FoldingRegions.outermost(regions)
        guard !outermost.isEmpty else {
            NSSound.beep()
            return
        }
        folds = outermost.map(\.hiddenRange)
        invalidateAll()
        if let textView, fold(containing: textView.selectedRange().location) != nil {
            textView.setSelectedRange(NSRange(location: 0, length: 0))
        }
    }

    func unfoldAll() {
        guard !folds.isEmpty else { return }
        folds = []
        invalidateAll()
    }

    // MARK: - Mitführen

    /// Vom Text-Storage gemeldete Änderung (`editedRange` im neuen Text).
    /// Bereiche davor bleiben, dahinter verschieben sie sich, berührte klappen auf.
    func noteEdit(editedRange: NSRange, changeInLength delta: Int) {
        guard !folds.isEmpty else { return }
        let start = editedRange.location
        let oldEnd = editedRange.location + editedRange.length - delta
        var removed: [Range<Int>] = []
        folds = folds.compactMap { fold in
            if fold.upperBound <= start { return fold }
            if fold.lowerBound >= oldEnd { return (fold.lowerBound + delta)..<(fold.upperBound + delta) }
            removed.append(fold)
            return nil
        }
        if !removed.isEmpty {
            // Nicht während der Bearbeitung des Text-Storage neu layouten.
            DispatchQueue.main.async { [weak self] in self?.invalidateAll() }
        }
    }

    /// Steht die Auswahl in einem eingeklappten Bereich, wird er aufgeklappt.
    func reveal(_ selection: NSRange) {
        guard !folds.isEmpty else { return }
        let lower = selection.location
        let upper = selection.location + selection.length
        let hit = folds.filter { fold in
            (fold.lowerBound < lower && lower < fold.upperBound)
                || (fold.lowerBound < upper && upper < fold.upperBound)
                || (lower <= fold.lowerBound && fold.upperBound <= upper && selection.length > 0)
        }
        for fold in hit { unfold(fold) }
    }

    // MARK: - Darstellung

    /// Rechteck der Kapsel „⋯“ in Koordinaten der Textansicht.
    func markerRect(for fold: Range<Int>) -> NSRect? {
        guard let textView, let layoutManager = textView.layoutManager,
              let length = textView.textStorage?.length, fold.lowerBound < length else { return nil }
        let glyph = layoutManager.glyphIndexForCharacter(at: fold.lowerBound)
        let line = layoutManager.lineFragmentRect(forGlyphAt: glyph, effectiveRange: nil)
        let location = layoutManager.location(forGlyphAt: glyph)
        let origin = textView.textContainerOrigin
        return NSRect(
            x: line.minX + location.x + origin.x + 5,
            y: line.minY + origin.y + 2,
            width: Self.markerWidth - 10,
            height: max(line.height - 4, 8)
        )
    }

    /// Zeichnet die Kapseln aller sichtbaren eingeklappten Bereiche.
    func drawMarkers(in dirtyRect: NSRect) {
        for fold in folds {
            guard let rect = markerRect(for: fold), rect.intersects(dirtyRect) else { continue }
            let path = NSBezierPath(roundedRect: rect, xRadius: rect.height / 2, yRadius: rect.height / 2)
            NSColor.controlAccentColor.withAlphaComponent(0.16).setFill()
            path.fill()
            let label = "⋯" as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: max(rect.height - 4, 9), weight: .bold),
                .foregroundColor: NSColor.controlAccentColor
            ]
            let size = label.size(withAttributes: attributes)
            label.draw(at: NSPoint(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2), withAttributes: attributes)
        }
    }

    /// Eingeklappter Bereich, dessen Kapsel an `point` (Textansicht) liegt.
    func fold(atMarker point: NSPoint) -> Range<Int>? {
        folds.first { markerRect(for: $0)?.insetBy(dx: -3, dy: -2).contains(point) == true }
    }

    private func invalidate(_ range: Range<Int>) {
        guard let textView, let layoutManager = textView.layoutManager, let length = textView.textStorage?.length else { return }
        let start = max(0, min(range.lowerBound, length))
        let end = min(length, range.upperBound + 1)
        let characters = NSRange(location: start, length: max(0, end - start))
        layoutManager.invalidateGlyphs(forCharacterRange: characters, changeInLength: 0, actualCharacterRange: nil)
        layoutManager.invalidateLayout(forCharacterRange: characters, actualCharacterRange: nil)
        textView.needsDisplay = true
        onChange?()
    }

    private func invalidateAll() {
        guard let length = textView?.textStorage?.length else { return }
        invalidate(0..<length)
    }

    // MARK: - NSLayoutManagerDelegate
    //
    // Der Layout-Manager ruft diese Methoden auf dem Hauptthread auf. Gelesen wird
    // dort nur die Liste der eingeklappten Bereiche; alles andere passiert hier.

    /// Zeichen in eingeklappten Bereichen werden unsichtbar (ausser dem ersten, dort sitzt die Kapsel).
    nonisolated func layoutManager(
        _ layoutManager: NSLayoutManager,
        shouldGenerateGlyphs glyphs: UnsafePointer<CGGlyph>,
        properties props: UnsafePointer<NSLayoutManager.GlyphProperty>,
        characterIndexes charIndexes: UnsafePointer<Int>,
        font aFont: NSFont,
        forGlyphRange glyphRange: NSRange
    ) -> Int {
        let folds = MainActor.assumeIsolated { self.folds }
        let count = glyphRange.length
        guard count > 0, !folds.isEmpty else { return 0 }
        let first = charIndexes[0]
        let last = charIndexes[count - 1]
        guard folds.contains(where: { $0.lowerBound <= last && $0.upperBound > first }) else { return 0 }
        var properties = [NSLayoutManager.GlyphProperty](repeating: [], count: count)
        for index in 0..<count {
            var property = props[index]
            let character = charIndexes[index]
            if let fold = Self.fold(containing: character, in: folds), character != fold.lowerBound,
               !property.contains(.controlCharacter) {
                property.insert(.null)
            }
            properties[index] = property
        }
        properties.withUnsafeBufferPointer { buffer in
            layoutManager.setGlyphs(glyphs, properties: buffer.baseAddress!, characterIndexes: charIndexes, font: aFont, forGlyphRange: glyphRange)
        }
        return count
    }

    /// Zeilenumbrüche im eingeklappten Bereich zählen nicht; der erste wird zum Platz für die Kapsel.
    nonisolated func layoutManager(
        _ layoutManager: NSLayoutManager,
        shouldUse action: NSLayoutManager.ControlCharacterAction,
        forControlCharacterAt charIndex: Int
    ) -> NSLayoutManager.ControlCharacterAction {
        let folds = MainActor.assumeIsolated { self.folds }
        guard let fold = Self.fold(containing: charIndex, in: folds) else { return action }
        return charIndex == fold.lowerBound ? .whitespace : .zeroAdvancement
    }

    nonisolated func layoutManager(
        _ layoutManager: NSLayoutManager,
        boundingBoxForControlGlyphAt glyphIndex: Int,
        for textContainer: NSTextContainer,
        proposedLineFragment proposedRect: NSRect,
        glyphPosition: NSPoint,
        characterIndex charIndex: Int
    ) -> NSRect {
        NSRect(x: glyphPosition.x, y: glyphPosition.y, width: Self.markerWidth, height: proposedRect.height)
    }
}
