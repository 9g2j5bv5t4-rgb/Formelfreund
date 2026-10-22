import Foundation

/// Schnelle Umrechnung zwischen Textposition und Zeilennummer.
///
/// Speichert den Anfang jeder Zeile. Die Suche nach der Zeile zu einer Position
/// ist dann eine binäre Suche – auch bei 5000 Zeilen nur ~13 Vergleiche.
/// Zeilennummern sind wie in LaTeX-Fehlermeldungen 1-basiert.
public struct LineIndex: Sendable, Equatable {
    /// UTF-16-Offset des ersten Zeichens jeder Zeile. Immer mindestens `[0]`.
    public private(set) var lineStarts: [Int]
    /// Länge des Textes in UTF-16-Einheiten.
    public private(set) var length: Int

    public init<S: UTF16Source>(_ text: S) {
        var starts = [0]
        starts.reserveCapacity(text.count / 40 + 1)
        for i in 0..<text.count where text[i] == TeXChar.newline {
            starts.append(i + 1)
        }
        lineStarts = starts
        length = text.count
    }

    public init(_ string: String) {
        self.init(Array(string.utf16))
    }

    /// Anzahl Zeilen (ein leerer Text hat eine Zeile).
    public var lineCount: Int { lineStarts.count }

    /// 1-basierte Zeilennummer für eine Position.
    public func line(at offset: Int) -> Int {
        let clamped = min(max(0, offset), length)
        // Binäre Suche nach der letzten Zeile, deren Start <= offset ist.
        var low = 0
        var high = lineStarts.count - 1
        while low < high {
            let mid = (low + high + 1) / 2
            if lineStarts[mid] <= clamped {
                low = mid
            } else {
                high = mid - 1
            }
        }
        return low + 1
    }

    /// Bereich einer 1-basierten Zeile ohne Zeilenumbruch. `nil`, wenn es die Zeile nicht gibt.
    public func range(ofLine line: Int) -> Range<Int>? {
        guard line >= 1 && line <= lineStarts.count else { return nil }
        let start = lineStarts[line - 1]
        let end = line < lineStarts.count ? lineStarts[line] - 1 : length
        return start..<max(start, end)
    }

    /// Spalte (0-basiert, in UTF-16-Einheiten) einer Position innerhalb ihrer Zeile.
    public func column(at offset: Int) -> Int {
        let line = line(at: offset)
        return offset - lineStarts[line - 1]
    }
}
