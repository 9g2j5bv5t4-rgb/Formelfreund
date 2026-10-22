import Foundation

/// Platzhalter `•` in eingefügten Bausteinen.
///
/// Tab springt zum nächsten, ⇧Tab zum vorherigen Platzhalter – aber nur
/// innerhalb des aktuellen Absatzes (bis zur nächsten Leerzeile). So bleibt
/// Tab in normalem Text weiterhin Tab.
public enum Placeholders {
    /// Das Platzhalterzeichen.
    public static let marker = "•"
    /// UTF-16-Wert von `•` (U+2022).
    public static let unit: UInt16 = 0x2022

    /// Nächster Platzhalter ab `position` (einschliesslich) bis zum Ende des Absatzes.
    public static func next<S: UTF16Source>(in text: S, from position: Int) -> Range<Int>? {
        fatalError("Noch nicht umgesetzt")
    }

    /// Vorheriger Platzhalter vor `position` (ausschliesslich) bis zum Anfang des Absatzes.
    public static func previous<S: UTF16Source>(in text: S, before position: Int) -> Range<Int>? {
        fatalError("Noch nicht umgesetzt")
    }

    /// 1-basierte Zeilennummern aller Zeilen, die noch Platzhalter enthalten (Kommentare ausgenommen).
    public static func lines<S: UTF16Source>(in text: S) -> [Int] {
        fatalError("Noch nicht umgesetzt")
    }
}

/// Fügt einen Baustein passend ein.
public enum SnippetInserter {
    /// Berechnet die Einfügung eines Bausteins.
    ///
    /// - `inline`: an der Cursorposition; eine Auswahl wird ersetzt bzw. landet an `Snippet.selectionToken`.
    /// - `block`: auf eigenen Zeilen. Steht in der aktuellen Zeile schon Text, wird davor bzw.
    ///   danach ein Zeilenumbruch ergänzt. Jede Zeile bekommt die Einrückung der aktuellen Zeile.
    /// - `requiresMath` und `inMath == false`: in `$…$` eingepackt.
    /// - Danach ist der erste Platzhalter ausgewählt; gibt es keinen, steht der Cursor am Ende.
    ///
    /// - Parameter inMath: Steht der Cursor bereits in einer Formel? (`TokenizedText.isInsideMath`)
    public static func edit<S: UTF16Source>(
        inserting snippet: Snippet,
        in text: S,
        selection: Range<Int>,
        inMath: Bool
    ) -> TextEdit {
        fatalError("Noch nicht umgesetzt")
    }
}
