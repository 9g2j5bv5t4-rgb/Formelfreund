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
}
