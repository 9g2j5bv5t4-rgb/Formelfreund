import Foundation
import LaTeXKit

/// Alles, was die Format-Leiste über die Cursorposition wissen muss.
///
/// Wird nach jeder Cursorbewegung im Hintergrund neu berechnet, damit die
/// Knöpfe (Fett, Überschrift, Ausrichtung …) den richtigen Zustand zeigen.
struct FormatState: Equatable, Sendable {
    var inline = FormattingState()
    var paragraph = ParagraphState()
    /// Innerste Umgebung am Cursor (z. B. `align*`), für das Block-Menü.
    var environment: String?
    /// Steht der Cursor in einer Formel?
    var inMath = false

    /// Kann die Nummerierung der Formel am Cursor umgeschaltet werden?
    var canToggleNumbering: Bool {
        guard let environment else { return false }
        let base = environment.hasSuffix("*") ? String(environment.dropLast()) : environment
        return ["equation", "align", "gather", "multline", "flalign", "alignat"].contains(base)
    }

    /// Berechnet den Zustand – reine Funktion, läuft im Hintergrund.
    static func compute(
        text: [UInt16],
        selection: Range<Int>,
        scheme: HeadingScheme,
        analysis: TokenizedText?
    ) -> FormatState {
        let upper = min(selection.upperBound, text.count)
        let lower = min(selection.lowerBound, upper)
        let range = lower..<upper
        var state = FormatState()
        state.inline = InlineFormatter.state(in: text, selection: range)
        state.paragraph = ParagraphFormatter.state(in: text, selection: range, scheme: scheme)
        state.environment = BlockEditor.enclosingEnvironment(in: text, at: lower)?.name
        state.inMath = analysis?.isInsideMath(at: lower) ?? false
        return state
    }
}
