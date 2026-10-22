import Foundation

/// Berechnet, welcher Textbereich nach einer Änderung neu eingefärbt werden muss.
///
/// Das Einfärben selbst muss auf dem Hauptthread passieren (AppKit). Damit der
/// Editor auch bei langen Dokumenten flüssig bleibt, vergleichen wir die alte
/// mit der neuen Token-Liste und färben nur den Bereich dazwischen neu ein –
/// beim normalen Tippen sind das meist nur wenige Zeichen.
public enum HighlightDiff {
    /// - Parameters:
    ///   - old: Tokens, die aktuell im Editor angezeigt werden (alte Positionen).
    ///   - new: Frisch berechnete Tokens (neue Positionen).
    ///   - lengthDelta: Längenänderung des Textes seit `old` (neu − alt).
    ///   - edited: Bereich im neuen Text, der seit `old` bearbeitet wurde.
    ///   - textLength: Länge des neuen Textes.
    /// - Returns: Bereich im neuen Text, der neu eingefärbt werden muss, oder `nil`.
    public static func dirtyRange(
        old: [HighlightToken],
        new: [HighlightToken],
        lengthDelta: Int,
        edited: Range<Int>?,
        textLength: Int
    ) -> Range<Int>? {
        // 1. Gemeinsamer Anfang: identische Tokens an identischer Position.
        var prefix = 0
        let maxPrefix = min(old.count, new.count)
        while prefix < maxPrefix && old[prefix] == new[prefix] {
            prefix += 1
        }

        // 2. Gemeinsames Ende: identische Tokens, nur um `lengthDelta` verschoben.
        var oldIndex = old.count - 1
        var newIndex = new.count - 1
        while oldIndex >= prefix && newIndex >= prefix {
            var shifted = old[oldIndex]
            shifted.location += lengthDelta
            guard shifted == new[newIndex] else { break }
            oldIndex -= 1
            newIndex -= 1
        }

        let tokensUnchanged = prefix == old.count && prefix == new.count
        if tokensUnchanged && edited == nil { return nil }

        // 3. Neu einfärben: vom ersten bis zum letzten abweichenden Token
        //    (alte Tokens in neue Positionen umgerechnet).
        var start = Int.max
        var end = Int.min
        if !tokensUnchanged {
            if prefix < old.count { start = min(start, old[prefix].location) }
            if prefix < new.count { start = min(start, new[prefix].location) }
            if oldIndex >= prefix { end = max(end, old[oldIndex].end + lengthDelta) }
            if newIndex >= prefix { end = max(end, new[newIndex].end) }
            // Sicherheitshalber nie in die unveränderten Tokens hineinreichen.
            if prefix > 0 { start = max(start, new[prefix - 1].end) }
            if newIndex + 1 < new.count { end = min(end, new[newIndex + 1].location) }
            if end < start { end = start }
        }
        if let edited {
            start = min(start, edited.lowerBound)
            end = max(end, edited.upperBound)
        }
        start = max(0, min(start, textLength))
        end = max(start, min(end, textLength))
        return start < end ? start..<end : nil
    }

    /// Fasst zwei Bearbeitungsbereiche zusammen. `previous` liegt in den
    /// Koordinaten *vor* der neuen Änderung und wird entsprechend verschoben.
    ///
    /// - Parameters:
    ///   - previous: Bisher gesammelter Bereich (oder `nil`).
    ///   - editedRange: Bereich der neuen Änderung im neuen Text.
    ///   - changeInLength: Längenänderung durch die neue Änderung.
    public static func union(previous: Range<Int>?, editedRange: Range<Int>, changeInLength: Int) -> Range<Int> {
        guard let previous else { return editedRange }
        // Ende des ersetzten Bereichs im *alten* Text.
        let oldEditEnd = editedRange.upperBound - changeInLength
        var lower = previous.lowerBound
        var upper = previous.upperBound
        if lower >= oldEditEnd { lower += changeInLength } else if lower > editedRange.lowerBound { lower = editedRange.lowerBound }
        if upper >= oldEditEnd { upper += changeInLength } else if upper > editedRange.lowerBound { upper = editedRange.upperBound }
        lower = min(lower, editedRange.lowerBound)
        upper = max(upper, editedRange.upperBound)
        return max(0, lower)..<max(max(0, lower), upper)
    }
}
