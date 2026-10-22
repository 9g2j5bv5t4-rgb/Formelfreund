import Foundation

/// Eine Textänderung, die der Editor ausführen soll.
///
/// Die Logik (z. B. automatisches Schliessen von Klammern) berechnet nur, *was*
/// geändert werden soll. Der Editor führt die Änderung aus, damit Rückgängig
/// machen (⌘Z) und Markierung korrekt funktionieren.
public struct TextEdit: Equatable, Sendable {
    /// Zu ersetzender Bereich (UTF-16-Offsets im Text *vor* der Änderung).
    public var range: Range<Int>
    /// Neuer Text für den Bereich.
    public var replacement: String
    /// Auswahl/Cursor *nach* der Änderung (UTF-16-Offsets im neuen Text).
    public var selectionAfter: Range<Int>

    public init(range: Range<Int>, replacement: String, selectionAfter: Range<Int>) {
        self.range = range
        self.replacement = replacement
        self.selectionAfter = selectionAfter
    }

    /// Nur den Cursor bewegen, ohne Text zu ändern.
    public static func moveCursor(to position: Int) -> TextEdit {
        TextEdit(range: position..<position, replacement: "", selectionAfter: position..<position)
    }

    /// Ändert diese Bearbeitung den Text überhaupt?
    public var changesText: Bool { !range.isEmpty || !replacement.isEmpty }

    /// Längenänderung des Textes durch diese Bearbeitung (UTF-16-Einheiten).
    public var lengthDelta: Int { replacement.utf16.count - range.count }

    /// Rechnet eine Auswahl aus dem Text *vor* der Änderung in den Text danach um.
    /// Auswahlen vor der Änderung bleiben, solche dahinter verschieben sich,
    /// überlappende werden auf das Ende des neuen Textes gesetzt.
    public func mapping(_ selection: Range<Int>) -> Range<Int> {
        func map(_ position: Int) -> Int {
            if position <= range.lowerBound { return position }
            if position >= range.upperBound { return position + lengthDelta }
            return range.lowerBound + replacement.utf16.count
        }
        let lower = map(selection.lowerBound)
        return lower..<max(lower, map(selection.upperBound))
    }

    /// Dieselbe Änderung, aber die bisherige Auswahl bleibt (verschoben) erhalten.
    public func preservingSelection(_ selection: Range<Int>) -> TextEdit {
        TextEdit(range: range, replacement: replacement, selectionAfter: mapping(selection))
    }
}
