import AppKit
import LaTeXKit

/// Zeilennummern am linken Rand des Editors.
///
/// Gezeichnet werden nur die sichtbaren Zeilen. Zeilen mit Fehlern bekommen
/// eine rote, Zeilen mit Warnungen eine gelbe Markierung – wie in Xcode.
final class LineNumberRulerView: NSRulerView {
    private weak var textView: NSTextView?

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
        let thickness = ceil(width + 20)
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

        while line <= lastLine {
            let lineStart = lineIndex.lineStarts[line - 1]
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
            draw(line: line, y: y, height: lineRect.height, isCurrent: line == cursorLine)
            line += 1
        }
    }

    private func draw(line: Int, y: CGFloat, height: CGFloat, isCurrent: Bool) {
        let label = "\(line)" as NSString
        var attributes: [NSAttributedString.Key: Any] = [
            .font: numberFont,
            .foregroundColor: isCurrent ? NSColor.labelColor : NSColor.tertiaryLabelColor
        ]
        let size = label.size(withAttributes: attributes)
        let x = ruleThickness - size.width - 8
        let textY = y + (height - size.height) / 2

        if let severity = issueLines[line], severity != .badBox {
            // Kapsel hinter der Nummer, wie eine Markierung in Xcode.
            let badge = NSRect(x: 3, y: y + 1, width: ruleThickness - 6, height: max(height - 2, size.height))
            let color: NSColor = severity == .error ? .systemRed : .systemYellow
            color.setFill()
            NSBezierPath(roundedRect: badge, xRadius: 4, yRadius: 4).fill()
            attributes[.foregroundColor] = severity == .error ? NSColor.white : NSColor.black
        }
        label.draw(at: NSPoint(x: x, y: textY), withAttributes: attributes)
    }
}
