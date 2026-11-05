import AppKit
import LaTeXKit

/// Zeilennummern am linken Rand des Editors.
///
/// Gezeichnet werden nur die sichtbaren Zeilen. Zeilen mit Fehlern bekommen
/// eine rote, Zeilen mit Warnungen eine gelbe Markierung – wie in Xcode.
/// Rechts neben den Nummern stehen die Dreiecke zum Einklappen: Sie erscheinen,
/// sobald die Maus über dem Rand ist; eingeklappte Stellen zeigen ihres immer.
final class LineNumberRulerView: NSRulerView {
    private weak var textView: NSTextView?
    /// Einklappen (Dreiecke, ausgeblendete Zeilen).
    weak var folding: FoldingController? {
        didSet { needsDisplay = true }
    }
    private var isHovering = false {
        didSet { if oldValue != isHovering { needsDisplay = true } }
    }
    private var hoverArea: NSTrackingArea?
    /// Breite der Spalte mit den Dreiecken.
    private let foldColumnWidth: CGFloat = 14

    var lineIndex: LineIndex? {
        didSet {
            updateThickness()
            needsDisplay = true
        }
    }

    var issueLines: [Int: CompileIssue.Severity] = [:] {
        didSet { if oldValue != issueLines { needsDisplay = true } }
    }

    var fontSize: CGFloat = 13 {
        didSet {
            updateThickness()
            needsDisplay = true
        }
    }

    init(textView: NSTextView) {
        self.textView = textView
        super.init(scrollView: textView.enclosingScrollView, orientation: .verticalRuler)
        clientView = textView
        updateThickness()
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) wird nicht unterstützt")
    }

    override var isFlipped: Bool { true }

    private var numberFont: NSFont {
        .monospacedDigitSystemFont(ofSize: max(fontSize - 2, 9), weight: .regular)
    }

    /// Breite so wählen, dass die grösste Zeilennummer Platz hat.
    private func updateThickness() {
        let digits = max(3, String(lineIndex?.lineCount ?? 1).count)
        let sample = String(repeating: "8", count: digits) as NSString
        let width = sample.size(withAttributes: [.font: numberFont]).width
        let thickness = ceil(width + 16 + foldColumnWidth)
        if abs(ruleThickness - thickness) > 0.5 {
            ruleThickness = thickness
        }
    }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer,
              let textStorage = textView.textStorage,
              let lineIndex else { return }

        NSColor.textBackgroundColor.setFill()
        bounds.fill()

        let textLength = textStorage.length
        // Sichtbarer Bereich in Koordinaten des Text-Containers (ohne Innenabstand).
        let origin = textView.textContainerOrigin
        let visibleRect = textView.visibleRect.offsetBy(dx: -origin.x, dy: -origin.y)
        let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
        let characterRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)

        let cursor = textView.selectedRange().location
        let cursorLine = lineIndex.line(at: cursor)

        var line = lineIndex.line(at: characterRange.location)
        let lastLine = lineIndex.line(at: NSMaxRange(characterRange))

        let foldStarts = Dictionary(
            (folding?.regions ?? []).map { ($0.line, $0) },
            uniquingKeysWith: { first, second in first.hiddenRange.count >= second.hiddenRange.count ? first : second }
        )

        while line <= lastLine {
            let lineStart = lineIndex.lineStarts[line - 1]
            // In einem eingeklappten Bereich verschwunden.
            if let folding, folding.isLineHidden(startingAt: lineStart) {
                line += 1
                continue
            }
            var lineRect: NSRect
            if lineStart < textLength {
                let glyph = layoutManager.glyphIndexForCharacter(at: lineStart)
                lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyph, effectiveRange: nil)
            } else if lineStart == textLength, !layoutManager.extraLineFragmentRect.isEmpty {
                lineRect = layoutManager.extraLineFragmentRect
            } else {
                break
            }
            lineRect.origin.y += textView.textContainerOrigin.y
            let y = convert(NSPoint(x: 0, y: lineRect.minY), from: textView).y
            let lineHeight = lineRect.height
            draw(line: line, y: y, height: lineHeight, isCurrent: line == cursorLine)
            if let region = foldStarts[line] {
                let folded = folding?.isFolded(region) == true
                if folded || isHovering {
                    drawFoldTriangle(y: y, height: lineHeight, folded: folded)
                }
            }
            line += 1
        }
    }

    private func drawFoldTriangle(y: CGFloat, height: CGFloat, folded: Bool) {
        let name = folded ? "chevron.right" : "chevron.down"
        let configuration = NSImage.SymbolConfiguration(pointSize: max(fontSize - 4, 8), weight: .semibold)
        guard let image = NSImage(systemSymbolName: name, accessibilityDescription: folded ? "Aufklappen" : "Einklappen")?
            .withSymbolConfiguration(configuration) else { return }
        let color: NSColor = folded ? .controlAccentColor : .tertiaryLabelColor
        let tinted = NSImage(size: image.size, flipped: false) { rect in
            image.draw(in: rect)
            color.set()
            rect.fill(using: .sourceAtop)
            return true
        }
        let x = ruleThickness - foldColumnWidth + (foldColumnWidth - image.size.width) / 2 - 2
        let rect = NSRect(x: x, y: y + (height - image.size.height) / 2, width: image.size.width, height: image.size.height)
        tinted.draw(in: rect)
    }

    // MARK: - Maus

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let hoverArea { removeTrackingArea(hoverArea) }
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect], owner: self)
        addTrackingArea(area)
        hoverArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        isHovering = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovering = false
    }

    /// Klick neben eine Zeilennummer: Bereich dort ein- oder ausklappen.
    override func mouseDown(with event: NSEvent) {
        guard let textView, let folding, let lineIndex else {
            super.mouseDown(with: event)
            return
        }
        let point = convert(event.locationInWindow, from: nil)
        let textPoint = textView.convert(point, from: self)
        let index = textView.characterIndexForInsertion(at: NSPoint(x: textView.textContainerOrigin.x + 1, y: textPoint.y))
        let line = lineIndex.line(at: index)
        if !folding.toggle(line: line) {
            super.mouseDown(with: event)
        }
    }

    private func draw(line: Int, y: CGFloat, height: CGFloat, isCurrent: Bool) {
        let label = "\(line)" as NSString
        var attributes: [NSAttributedString.Key: Any] = [
            .font: numberFont,
            .foregroundColor: isCurrent ? NSColor.labelColor : NSColor.tertiaryLabelColor
        ]
        let size = label.size(withAttributes: attributes)
        let x = ruleThickness - foldColumnWidth - size.width - 4
        let textY = y + (height - size.height) / 2

        if let severity = issueLines[line], severity != .badBox {
            // Kapsel hinter der Nummer, wie eine Markierung in Xcode.
            let badge = NSRect(x: 3, y: y + 1, width: ruleThickness - foldColumnWidth - 3, height: max(height - 2, size.height))
            let color: NSColor = severity == .error ? .systemRed : .systemYellow
            color.setFill()
            NSBezierPath(roundedRect: badge, xRadius: 4, yRadius: 4).fill()
            attributes[.foregroundColor] = severity == .error ? NSColor.white : NSColor.black
        }
        label.draw(at: NSPoint(x: x, y: textY), withAttributes: attributes)
    }
}
