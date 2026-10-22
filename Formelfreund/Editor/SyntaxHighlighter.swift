import AppKit
import LaTeXKit

/// Ergebnis der Hintergrund-Analyse eines Textstands.
struct TextAnalysis: Sendable {
    var tokenized: TokenizedText
    var lines: LineIndex
    var outline: DocumentOutline
    var length: Int
}

/// Färbt den Quelltext ein – ohne den Hauptthread zu blockieren.
///
/// Ablauf bei jedem Tastendruck:
/// 1. Auf dem Hauptthread wird der Text als UTF-16-Puffer kopiert (ein schnelles `memcpy`).
/// 2. Ein Hintergrund-Task analysiert den Puffer: Tokens, Formeln, Zeilen, Gliederung.
/// 3. Zurück auf dem Hauptthread wird nur der Bereich neu eingefärbt, der sich
///    tatsächlich geändert hat (`HighlightDiff`).
///
/// Eingefärbt wird mit „temporären Attributen“ des Layout-Managers. Diese ändern
/// den Text selbst nicht – deshalb lösen sie weder „Dokument bearbeitet“ noch
/// Einträge in der Rückgängig-Liste aus und sind sehr schnell.
@MainActor
final class SyntaxHighlighter {
    private weak var textView: NSTextView?

    /// Tokens, die gerade im Editor sichtbar angewendet sind.
    private var appliedTokens: [HighlightToken] = []
    /// Seit der letzten Anwendung bearbeiteter Bereich und Längenänderung.
    private var pendingEdit: Range<Int>?
    private var pendingDelta = 0
    private var generation = 0
    private var analysisTask: Task<Void, Never>?

    /// Wird nach jeder abgeschlossenen Analyse aufgerufen.
    var onAnalysis: ((TextAnalysis) -> Void)?
    /// Letztes Analyseergebnis.
    private(set) var latest: TextAnalysis?

    init(textView: NSTextView) {
        self.textView = textView
    }

    /// Vom Text-Storage gemeldete Änderung (wird gesammelt, bis die nächste Analyse fertig ist).
    func noteEdit(range: NSRange, changeInLength: Int) {
        let edited = range.location..<(range.location + range.length)
        pendingEdit = HighlightDiff.union(previous: pendingEdit, editedRange: edited, changeInLength: changeInLength)
        pendingDelta += changeInLength
    }

    /// Alles neu einfärben (z. B. nach dem Laden).
    func invalidateAll() {
        guard let storage = textView?.textStorage else { return }
        // Ohne „alte“ Tokens und mit dem ganzen Text als bearbeitetem Bereich
        // wird beim nächsten Anwenden alles neu eingefärbt.
        appliedTokens = []
        pendingEdit = 0..<storage.length
        pendingDelta = 0
        scheduleAnalysis()
    }

    /// Startet eine Analyse des aktuellen Textes im Hintergrund.
    func scheduleAnalysis() {
        guard let storage = textView?.textStorage else { return }
        generation += 1
        let currentGeneration = generation
        let buffer = Self.copyUTF16(from: storage)

        analysisTask?.cancel()
        analysisTask = Task { [weak self] in
            let analysis = await Self.analyze(buffer)
            guard let self, !Task.isCancelled, currentGeneration == self.generation else { return }
            self.apply(analysis)
        }
    }

    /// Kopiert den Text als UTF-16-Puffer (direkter Speicherzugriff, kein Zeichen-für-Zeichen-Lesen).
    static func copyUTF16(from storage: NSTextStorage) -> [UInt16] {
        let string = storage.mutableString
        let length = string.length
        var buffer = [UInt16](repeating: 0, count: length)
        if length > 0 {
            buffer.withUnsafeMutableBufferPointer { pointer in
                string.getCharacters(pointer.baseAddress!, range: NSRange(location: 0, length: length))
            }
        }
        return buffer
    }

    /// Die eigentliche Analyse – läuft nicht auf dem Hauptthread.
    private nonisolated static func analyze(_ buffer: [UInt16]) async -> TextAnalysis {
        let tokenized = LaTeXTokenizer.tokenize(buffer)
        let lines = LineIndex(buffer)
        let outline = DocumentOutline.parse(buffer, tokenized: tokenized, lines: lines)
        return TextAnalysis(tokenized: tokenized, lines: lines, outline: outline, length: buffer.count)
    }

    private func apply(_ analysis: TextAnalysis) {
        guard let textView, let layoutManager = textView.layoutManager, let storage = textView.textStorage else { return }
        let length = storage.length
        guard analysis.length == length else { return }

        let tokens = analysis.tokenized.tokens
        if let dirty = HighlightDiff.dirtyRange(
            old: appliedTokens,
            new: tokens,
            lengthDelta: pendingDelta,
            edited: pendingEdit,
            textLength: length
        ) {
            let dirtyRange = NSRange(location: dirty.lowerBound, length: dirty.count)
            layoutManager.removeTemporaryAttribute(.foregroundColor, forCharacterRange: dirtyRange)
            // Erstes Token, das in den Bereich hineinragt (binäre Suche).
            var low = 0
            var high = tokens.count
            while low < high {
                let mid = (low + high) / 2
                if tokens[mid].end <= dirty.lowerBound { low = mid + 1 } else { high = mid }
            }
            var index = low
            while index < tokens.count, tokens[index].location < dirty.upperBound {
                let token = tokens[index]
                let start = max(token.location, dirty.lowerBound)
                let end = min(token.end, dirty.upperBound)
                if start < end {
                    layoutManager.addTemporaryAttribute(
                        .foregroundColor,
                        value: SyntaxTheme.color(for: token.kind),
                        forCharacterRange: NSRange(location: start, length: end - start)
                    )
                }
                index += 1
            }
        }

        appliedTokens = tokens
        pendingEdit = nil
        pendingDelta = 0
        latest = analysis
        onAnalysis?(analysis)
    }
}
