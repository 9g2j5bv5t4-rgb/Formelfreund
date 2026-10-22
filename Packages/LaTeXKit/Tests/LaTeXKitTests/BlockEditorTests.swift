import Foundation
import Testing
@testable import LaTeXKit

// Schreibweise in diesen Tests:
// `|` markiert den Cursor, `«…»` eine Auswahl – im Text vorher wie nachher.

/// Zerlegt einen markierten Text in reinen Text und Auswahl (UTF-16-Offsets).
private func parseBlockMarks(_ marked: String) -> (text: String, selection: Range<Int>) {
    let string = marked as NSString
    let open = string.range(of: "«")
    if open.location != NSNotFound {
        let close = string.range(of: "»")
        let text = marked.replacingOccurrences(of: "«", with: "").replacingOccurrences(of: "»", with: "")
        return (text, open.location..<(close.location - 1))
    }
    let cursor = string.range(of: "|").location
    return (marked.replacingOccurrences(of: "|", with: ""), cursor..<cursor)
}

/// Setzt die Markierungen für eine Auswahl in einen Text.
private func markBlock(_ selection: Range<Int>, in text: String) -> String {
    let string = text as NSString
    if selection.isEmpty {
        return string.replacingCharacters(in: NSRange(location: selection.lowerBound, length: 0), with: "|")
    }
    let closed = string.replacingCharacters(in: NSRange(location: selection.upperBound, length: 0), with: "»") as NSString
    return closed.replacingCharacters(in: NSRange(location: selection.lowerBound, length: 0), with: "«")
}

/// Führt eine Bearbeitung aus und liefert den neuen Text (ohne Markierungen).
private func applyBlockEdit(_ edit: TextEdit, to text: String) -> String {
    (text as NSString).replacingCharacters(
        in: NSRange(location: edit.range.lowerBound, length: edit.range.count),
        with: edit.replacement
    )
}

/// Prüft die Grundregeln jeder Bearbeitung und liefert den neuen Text, `nil` wenn sie verletzt sind:
/// Bereich im alten Text, Auswahl danach im neuen Text.
private func checkedText(
    _ edit: TextEdit, on text: String, sourceLocation: SourceLocation = #_sourceLocation
) -> String? {
    let oldLength = text.utf16.count
    guard edit.range.lowerBound >= 0, edit.range.upperBound <= oldLength else {
        Issue.record(Comment(rawValue: "Bereich \(edit.range) ausserhalb des Textes (Länge \(oldLength))"), sourceLocation: sourceLocation)
        return nil
    }
    let new = applyBlockEdit(edit, to: text)
    let newLength = new.utf16.count
    #expect(newLength == oldLength + edit.lengthDelta, sourceLocation: sourceLocation)
    guard edit.selectionAfter.lowerBound >= 0, edit.selectionAfter.upperBound <= newLength else {
        Issue.record(Comment(rawValue: "Auswahl \(edit.selectionAfter) ausserhalb des neuen Textes (Länge \(newLength))"), sourceLocation: sourceLocation)
        return nil
    }
    return new
}

/// Ergebnis einer Bearbeitung mit Markierungen (oder `nil`, wenn es keine gibt).
private func outcome(
    _ edit: TextEdit?, on text: String, sourceLocation: SourceLocation = #_sourceLocation
) -> String? {
    guard let edit else { return nil }
    guard let new = checkedText(edit, on: text, sourceLocation: sourceLocation) else { return "UNGÜLTIG" }
    return markBlock(edit.selectionAfter, in: new)
}

private func units(_ text: String) -> [UInt16] { Array(text.utf16) }

// MARK: - Kurzformen für die einzelnen Werkzeuge

private func expanded(_ marked: String) -> String {
    let (text, selection) = parseBlockMarks(marked)
    return markBlock(BlockEditor.expandSelection(in: units(text), selection: selection), in: text)
}

/// Mehrmals „Block auswählen“: die ausgewählten Texte Schritt für Schritt.
private func expansionSteps(_ marked: String, _ steps: Int, sourceLocation: SourceLocation = #_sourceLocation) -> [String] {
    let (text, selection) = parseBlockMarks(marked)
    let source = units(text)
    var current = selection
    var result: [String] = []
    for _ in 0..<steps {
        let next = BlockEditor.expandSelection(in: source, selection: current)
        #expect(next.lowerBound <= current.lowerBound && next.upperBound >= current.upperBound, sourceLocation: sourceLocation)
        #expect(next.lowerBound >= 0 && next.upperBound <= source.count, sourceLocation: sourceLocation)
        current = next
        result.append(source.string(in: current))
    }
    return result
}

private func renamed(_ marked: String, to name: String, sourceLocation: SourceLocation = #_sourceLocation) -> String? {
    let (text, selection) = parseBlockMarks(marked)
    guard let block = BlockEditor.enclosingEnvironment(in: units(text), at: selection.lowerBound) else { return nil }
    let edit = BlockEditor.renameEnvironment(block, to: name, in: units(text), selection: selection)
    #expect(edit.range == block.beginRange.lowerBound..<block.endRange.upperBound, sourceLocation: sourceLocation)
    return outcome(edit, on: text, sourceLocation: sourceLocation)
}

private func numbering(_ marked: String, sourceLocation: SourceLocation = #_sourceLocation) -> String? {
    let (text, selection) = parseBlockMarks(marked)
    return outcome(BlockEditor.toggleNumbering(in: units(text), selection: selection), on: text, sourceLocation: sourceLocation)
}

private func unwrapped(
    _ marked: String, named names: Set<String>? = nil, sourceLocation: SourceLocation = #_sourceLocation
) -> String? {
    let (text, selection) = parseBlockMarks(marked)
    guard let block = BlockEditor.enclosingEnvironment(in: units(text), at: selection.lowerBound, named: names) else { return nil }
    return outcome(BlockEditor.unwrapEnvironment(block, in: units(text), selection: selection), on: text, sourceLocation: sourceLocation)
}

private func wrapped(_ marked: String, in name: String, sourceLocation: SourceLocation = #_sourceLocation) -> String? {
    let (text, selection) = parseBlockMarks(marked)
    return outcome(BlockEditor.wrap(selection: selection, inEnvironment: name, in: units(text)), on: text, sourceLocation: sourceLocation)
}

private func moved(_ marked: String, up: Bool, sourceLocation: SourceLocation = #_sourceLocation) -> String? {
    let (text, selection) = parseBlockMarks(marked)
    return outcome(BlockEditor.moveLines(in: units(text), selection: selection, up: up), on: text, sourceLocation: sourceLocation)
}

private func commented(_ marked: String, sourceLocation: SourceLocation = #_sourceLocation) -> String? {
    let (text, selection) = parseBlockMarks(marked)
    return outcome(BlockEditor.toggleComment(in: units(text), selection: selection), on: text, sourceLocation: sourceLocation)
}

private func shifted(_ marked: String, outdent: Bool = false, sourceLocation: SourceLocation = #_sourceLocation) -> String? {
    let (text, selection) = parseBlockMarks(marked)
    return outcome(
        BlockEditor.shiftIndentation(in: units(text), selection: selection, outdent: outdent),
        on: text, sourceLocation: sourceLocation
    )
}

private func displayToggled(_ marked: String, sourceLocation: SourceLocation = #_sourceLocation) -> String? {
    let (text, selection) = parseBlockMarks(marked)
    return outcome(BlockEditor.toggleDisplayMath(in: units(text), selection: selection), on: text, sourceLocation: sourceLocation)
}

// MARK: - Block auswählen

@Suite("Block auswählen")
struct ExpandSelectionTests {
    @Test func selectsWord() {
        #expect(expanded("Hallo We|lt und") == "Hallo «Welt» und")
        #expect(expanded("Hallo Welt| und") == "Hallo «Welt» und")
        #expect(expanded("Hallo |Welt") == "Hallo «Welt»")
        #expect(expanded("Hallo «We»lt") == "Hallo «Welt»")
        #expect(expanded("Der Schrö|dinger ist") == "Der «Schrödinger» ist")
        #expect(expanded("😀Wort|") == "😀«Wort»")
        // Befehle samt Backslash.
        #expect(expanded("\\fr|ac{a}{b}") == "«\\frac»{a}{b}")
        // `\\` ist ein Zeilenumbruch, kein Befehl vor dem Wort.
        #expect(expanded("a \\\\x|y") == "a \\\\«xy»")
    }

    @Test func emojiIsNoWord() {
        #expect(expanded("Hallo 😀| Welt\n\nZweiter") == "«Hallo 😀 Welt»\n\nZweiter")
    }

    @Test func progressionThroughNestedBlocks() {
        let source = "\\documentclass{article}\n\\begin{document}\nText davor\n\\begin{center}\n  \\textbf{fett und| mehr}\n\\end{center}\nText danach\n\nNeuer Absatz\n\\end{document}\n"
        let (text, _) = parseBlockMarks(source)
        let steps = expansionSteps(source, 9)
        #expect(steps == [
            "und",
            "fett und mehr",
            "  \\textbf{fett und mehr}",
            "\\begin{center}\n  \\textbf{fett und mehr}\n\\end{center}",
            "Text davor\n\\begin{center}\n  \\textbf{fett und mehr}\n\\end{center}\nText danach",
            "Text davor\n\\begin{center}\n  \\textbf{fett und mehr}\n\\end{center}\nText danach\n\nNeuer Absatz",
            "\\begin{document}\nText davor\n\\begin{center}\n  \\textbf{fett und mehr}\n\\end{center}\nText danach\n\nNeuer Absatz\n\\end{document}",
            text,
            text
        ])
    }

    @Test func formulasAreBlocksToo() {
        #expect(expansionSteps("Es gilt $a + b|c$ hier.", 4) == [
            "bc", "a + bc", "$a + bc$", "Es gilt $a + bc$ hier."
        ])
    }

    @Test func nestedBraces() {
        #expect(expansionSteps("\\frac{1}{\\sqrt{x|}}", 3) == ["x", "\\sqrt{x}", "\\frac{1}{\\sqrt{x}}"])
    }

    @Test func escapedBracesAndCommentsDoNotCount() {
        #expect(expansionSteps("Menge \\{x|\\} und {y}\n\nNext", 3) == [
            "x", "Menge \\{x\\} und {y}", "Menge \\{x\\} und {y}\n\nNext"
        ])
        #expect(expansionSteps("{a % }\nb|}", 3) == ["b", "a % }\nb", "{a % }\nb}"])
    }

    @Test func paragraphStaysInsideEnvironment() {
        let source = "\\begin{proof}\n  Erster Absatz.\n\n  Zweiter| Absatz.\n\\end{proof}"
        #expect(expansionSteps(source, 4) == [
            "Zweiter",
            "  Zweiter Absatz.",
            "  Erster Absatz.\n\n  Zweiter Absatz.",
            "\\begin{proof}\n  Erster Absatz.\n\n  Zweiter Absatz.\n\\end{proof}"
        ])
    }

    @Test func environmentContentSkipsArguments() {
        let source = "\\begin{figure}[htbp]\n  \\centering\n  Bi|ld\n\\end{figure}"
        #expect(expansionSteps(source, 3) == [
            "Bild",
            "  \\centering\n  Bild",
            "\\begin{figure}[htbp]\n  \\centering\n  Bild\n\\end{figure}"
        ])
    }

    @Test func selectionSpanningLines() {
        #expect(expanded("\\begin{itemize}\n  \\item «a\n  \\item» b\n\\end{itemize}")
            == "\\begin{itemize}\n«  \\item a\n  \\item b»\n\\end{itemize}")
    }

    @Test func cursorInBeginToken() {
        #expect(expansionSteps("\\begin{cen|ter}x\\end{center}", 3) == [
            "center", "\\begin{center}x\\end{center}", "\\begin{center}x\\end{center}"
        ])
    }

    @Test func nothingLargerReturnsInput() {
        #expect(expanded("|") == "|")
        #expect(expanded("«abc»") == "«abc»")
        // Ausserhalb des Textes: unverändert zurück.
        #expect(BlockEditor.expandSelection(in: units("ab"), selection: 5..<7) == 5..<7)
    }

    @Test func worksOnNSString() {
        let source = NSStringSource(NSString(string: "Grüsse an Wel|t"))
        let cursor = 13
        #expect(BlockEditor.expandSelection(in: source, selection: cursor..<cursor) == 10..<14)
    }
}

// MARK: - Umbenennen

@Suite("Umgebung umbenennen")
struct RenameEnvironmentTests {
    @Test func renamesBeginAndEnd() {
        #expect(renamed("\\begin{itemize}\n  \\item A|pfel\n\\end{itemize}", to: "enumerate")
            == "\\begin{enumerate}\n  \\item A|pfel\n\\end{enumerate}")
        #expect(renamed("\\begin{quote}«Text»\\end{quote}", to: "quotation")
            == "\\begin{quotation}«Text»\\end{quotation}")
    }

    @Test func cursorInsideNameStays() {
        #expect(renamed("\\begin{ali|gn}x\\end{align}", to: "align*") == "\\begin{ali|gn*}x\\end{align*}")
    }

    @Test func nestedSameNameRenamesOuter() {
        #expect(renamed("\\begin{itemize}\\begin{itemize}a\\end{itemize}|b\\end{itemize}", to: "enumerate")
            == "\\begin{enumerate}\\begin{itemize}a\\end{itemize}|b\\end{enumerate}")
    }

    @Test func umlautsAndEmojiShiftCorrectly() {
        #expect(renamed("\\begin{center}\n😀 Grüsse|\n\\end{center}", to: "flushleft")
            == "\\begin{flushleft}\n😀 Grüsse|\n\\end{flushleft}")
    }

    @Test func spaceBeforeBrace() {
        #expect(renamed("\\begin {center}x|\\end {center}", to: "flushright")
            == "\\begin {flushright}x|\\end {flushright}")
    }

    @Test func selectionAfterBlockMoves() {
        let text = "\\begin{center}a\\end{center} Ende"
        let block = BlockEditor.enclosingEnvironment(in: units(text), at: 15)!
        let end = text.utf16.count
        let edit = BlockEditor.renameEnvironment(block, to: "quote", in: units(text), selection: end..<end)
        #expect(outcome(edit, on: text) == "\\begin{quote}a\\end{quote} Ende|")
    }

    @Test func staleBlockChangesNothing() {
        let block = EnvironmentBlock(name: "center", range: 0..<40, beginRange: 0..<14, endRange: 28..<40, contentRange: 14..<28)
        let edit = BlockEditor.renameEnvironment(block, to: "quote", in: units("kurz"), selection: 1..<1)
        #expect(!edit.changesText)
        #expect(edit.selectionAfter == 1..<1)
    }

    @Test func roundTrip() {
        let start = "\\begin{center}\n  T|ext\n\\end{center}"
        let there = renamed(start, to: "flushleft")!
        #expect(renamed(there, to: "center") == start)
    }
}

// MARK: - Nummerierung

@Suite("Nummerierung umschalten")
struct ToggleNumberingTests {
    @Test func togglesStar() {
        #expect(numbering("\\begin{equation}\n  a = b|\n\\end{equation}")
            == "\\begin{equation*}\n  a = b|\n\\end{equation*}")
        #expect(numbering("\\begin{align*}\n  a &= b|\n\\end{align*}")
            == "\\begin{align}\n  a &= b|\n\\end{align}")
        #expect(numbering("\\begin{gather}x|\\end{gather}") == "\\begin{gather*}x|\\end{gather*}")
        #expect(numbering("\\begin{multline*}x|\\end{multline*}") == "\\begin{multline}x|\\end{multline}")
        #expect(numbering("\\begin{flalign}x|\\end{flalign}") == "\\begin{flalign*}x|\\end{flalign*}")
        #expect(numbering("\\begin{alignat}{2}\n  a &= b|\n\\end{alignat}")
            == "\\begin{alignat*}{2}\n  a &= b|\n\\end{alignat*}")
    }

    @Test func innerMathEnvironmentUsesOuterFormula() {
        #expect(numbering("\\begin{equation}\n  \\begin{aligned}\n    a &= b|\n  \\end{aligned}\n\\end{equation}")
            == "\\begin{equation*}\n  \\begin{aligned}\n    a &= b|\n  \\end{aligned}\n\\end{equation*}")
    }

    @Test func cursorOnBeginToken() {
        #expect(numbering("\\begin{equ|ation}a\\end{equation}") == "\\begin{equ|ation*}a\\end{equation*}")
    }

    @Test func displayBracketsBecomeEquation() {
        #expect(numbering("Es gilt\n\\[\n  x^2|\n\\]\nfertig")
            == "Es gilt\n\\begin{equation}\n  x^2|\n\\end{equation}\nfertig")
        #expect(numbering("$$x|$$") == "\\begin{equation}x|\\end{equation}")
        #expect(numbering("\\[ «a + b» \\]") == "\\begin{equation} «a + b» \\end{equation}")
    }

    @Test func roundTrip() {
        let start = "\\begin{align}\n  a &= 1 \\\\\n  b &= 2|\n\\end{align}"
        #expect(numbering(numbering(start)!) == start)
    }

    @Test func nilOutsideNumberedFormulas() {
        #expect(numbering("Text|") == nil)
        #expect(numbering("|") == nil)
        #expect(numbering("\\begin{center}|\\end{center}") == nil)
        #expect(numbering("Es gilt $x|$.") == nil)
        #expect(numbering("% \\begin{equation}\nx|\n% \\end{equation}") == nil)
        #expect(numbering("\\begin{equation}a\\end{equation} danach|") == nil)
    }
}

// MARK: - Umgebung auflösen

@Suite("Umgebung auflösen")
struct UnwrapEnvironmentTests {
    @Test func removesLinesAndDedents() {
        #expect(unwrapped("Vorher\n\\begin{center}\n  Zentriert|\n  Zeile 2\n\\end{center}\nNachher")
            == "Vorher\nZentriert|\nZeile 2\nNachher")
    }

    @Test func removesOptionalArguments() {
        #expect(unwrapped("\\begin{figure}[htbp]\n  \\centering\n  \\includegraphics{bild}|\n\\end{figure}")
            == "\\centering\n\\includegraphics{bild}|")
        #expect(unwrapped("\\begin{tabular}{cc}\n  a & b \\\\|\n\\end{tabular}\n") == "a & b \\\\|\n")
        #expect(unwrapped("\\begin{satz}[Pythagoras]\n  a^2 + b^2 = c^2|\n\\end{satz}") == "a^2 + b^2 = c^2|")
        #expect(unwrapped("\\begin{minipage}[t]{0.5\\textwidth}\n  Text|\n\\end{minipage}") == "Text|")
        #expect(unwrapped("\\begin{figure} [h]\n  Bild|\n\\end{figure}") == "Bild|")
    }

    @Test func multiLineOptions() {
        #expect(unwrapped("\\begin{tikzpicture}[\n  scale=2\n]\n  \\draw (0,0) -- (1,1);|\n\\end{tikzpicture}")
            == "\\draw (0,0) -- (1,1);|")
    }

    @Test func contentThatLooksLikeArgumentsStays() {
        #expect(unwrapped("\\begin{equation}[0,1] \\subset \\mathbb{R}|\\end{equation}") == "[0,1] \\subset \\mathbb{R}|")
        #expect(unwrapped("\\begin{center}{\\large Titel}|\\end{center}") == "{\\large Titel}|")
    }

    @Test func sameLine() {
        #expect(unwrapped("Ein \\begin{center}zen|triert\\end{center} Wort") == "Ein zen|triert Wort")
        #expect(unwrapped("Ein \\begin{center} zen|triert \\end{center} Wort") == "Ein zen|triert Wort")
    }

    @Test func textNextToBeginAndEnd() {
        #expect(unwrapped("\\begin{center} Titel|\n  Zeile\n\\end{center}") == "Titel|\nZeile")
        #expect(unwrapped("\\begin{center}\n  Zeile|\n  Ende \\end{center}") == "Zeile|\nEnde")
        #expect(unwrapped("\\begin{center}\n  Zeile|\n\\end{center} danach") == "Zeile|\ndanach")
        #expect(unwrapped("\\begin{center} % zentriert\n  Text|\n\\end{center}") == "% zentriert\nText|")
    }

    @Test func nestedInnerEnvironment() {
        #expect(unwrapped("\\begin{itemize}\n  \\item a\n  \\begin{center}\n    x|\n  \\end{center}\n\\end{itemize}")
            == "\\begin{itemize}\n  \\item a\n  x|\n\\end{itemize}")
    }

    @Test func outerEnvironmentDedentsEverything() {
        #expect(unwrapped("\\begin{itemize}\n  \\item a|\n  \\begin{center}\n    x\n  \\end{center}\n\\end{itemize}", named: ["itemize"])
            == "\\item a|\n\\begin{center}\n  x\n\\end{center}")
    }

    @Test func tabsAndSingleSpaces() {
        #expect(unwrapped("\\begin{quote}\n\tZitat|\n\\end{quote}") == "Zitat|")
        #expect(unwrapped("\\begin{quote}\n Zitat|\n\\end{quote}") == "Zitat|")
        #expect(unwrapped("\\begin{quote}\n    Zitat|\n\\end{quote}") == "  Zitat|")
        #expect(unwrapped("\\begin{quote}\nZitat|\n\\end{quote}") == "Zitat|")
    }

    @Test func verbatimContentKeepsIndentation() {
        #expect(unwrapped("\\begin{center}\n  \\begin{verbatim}\n    code|\n  \\end{verbatim}\n\\end{center}", named: ["center"])
            == "\\begin{verbatim}\n    code|\n\\end{verbatim}")
    }

    @Test func emptyEnvironment() {
        #expect(unwrapped("Vorher\n\\begin{center}|\n\\end{center}\nNachher") == "Vorher\n|Nachher")
        #expect(unwrapped("Vorher\n  \\begin{center}|\\end{center}\nNachher") == "Vorher\n|Nachher")
        #expect(unwrapped("Vorher\n\\begin{center}|\\end{center}") == "Vorher|")
    }

    @Test func selectionStaysOnContent() {
        #expect(unwrapped("\\begin{center}\n  «ab\n  cd»\n\\end{center}") == "«ab\ncd»")
        #expect(unwrapped("\\begin{quote}\n  Grüsse 😀|\n\\end{quote}") == "Grüsse 😀|")
    }

    @Test func staleBlockChangesNothing() {
        let block = EnvironmentBlock(name: "center", range: 0..<40, beginRange: 0..<14, endRange: 28..<40, contentRange: 14..<28)
        let edit = BlockEditor.unwrapEnvironment(block, in: units("kurz"), selection: 2..<2)
        #expect(!edit.changesText)
    }

    @Test func wrapThenUnwrapRestoresText() {
        let start = "Vorher\n«Zeile 1\n  Zeile 2»\nNachher"
        let wrappedText = wrapped(start, in: "quote")!
        #expect(wrappedText == "Vorher\n\\begin{quote}\n«  Zeile 1\n    Zeile 2»\n\\end{quote}\nNachher")
        #expect(unwrapped(wrappedText) == "Vorher\n«Zeile 1\n  Zeile 2»\nNachher")
    }
}

// MARK: - Einpacken

@Suite("In Umgebung einpacken")
struct WrapTests {
    @Test func wrapsWholeLines() {
        #expect(wrapped("Vorher\n«Zeile 1\nZeile 2»\nNachher", in: "center")
            == "Vorher\n\\begin{center}\n«  Zeile 1\n  Zeile 2»\n\\end{center}\nNachher")
        // Auch eine Auswahl mitten in der Zeile nimmt die ganze Zeile.
        #expect(wrapped("Es ist «wichtig» hier", in: "center")
            == "\\begin{center}\n  Es ist «wichtig» hier\n\\end{center}")
    }

    @Test func keepsIndentationOfFirstLine() {
        #expect(wrapped("\\begin{itemize}\n  \\item a\n  «Text»\n\\end{itemize}", in: "center")
            == "\\begin{itemize}\n  \\item a\n  \\begin{center}\n    «Text»\n  \\end{center}\n\\end{itemize}")
    }

    @Test func selectionEndingAtLineStart() {
        #expect(wrapped("«Zeile\n»Rest", in: "quote") == "\\begin{quote}\n«  Zeile»\n\\end{quote}\nRest")
    }

    @Test func blankLinesAtEdgesStayOutside() {
        #expect(wrapped("«\na\n\n»b", in: "center") == "\n\\begin{center}\n«  a»\n\\end{center}\n\nb")
        #expect(wrapped("«a\n\nb»", in: "center") == "\\begin{center}\n«  a\n\n  b»\n\\end{center}")
    }

    @Test func emptySelectionInsertsEmptyEnvironment() {
        #expect(wrapped("Text\n|\nMehr", in: "center") == "Text\n\\begin{center}\n  |\n\\end{center}\nMehr")
        #expect(wrapped("Hallo| Welt", in: "center") == "Hallo\n\\begin{center}\n  |\n\\end{center}\nWelt")
        #expect(wrapped("  ab|", in: "center") == "  ab\n  \\begin{center}\n    |\n  \\end{center}")
        #expect(wrapped("|Anfang", in: "quote") == "\\begin{quote}\n  |\n\\end{quote}\nAnfang")
        #expect(wrapped("|", in: "center") == "\\begin{center}\n  |\n\\end{center}")
        #expect(wrapped("«  »", in: "center") == "\\begin{center}\n  |\n\\end{center}")
    }

    @Test func listsGetItems() {
        #expect(wrapped("«Äpfel\nBirnen»", in: "itemize")
            == "\\begin{itemize}\n«  \\item Äpfel\n  \\item Birnen»\n\\end{itemize}")
        #expect(wrapped("«\\item a\nb»", in: "enumerate")
            == "\\begin{enumerate}\n«  \\item a\n  \\item b»\n\\end{enumerate}")
        #expect(wrapped("|", in: "itemize") == "\\begin{itemize}\n  \\item |\n\\end{itemize}")
        // Umgebungen und Kommentare werden nicht zu Punkten.
        #expect(wrapped("«\\begin{center}\nx\n\\end{center}»", in: "itemize")
            == "\\begin{itemize}\n«  \\begin{center}\n  x\n  \\end{center}»\n\\end{itemize}")
        #expect(wrapped("«% Notiz\nText»", in: "itemize")
            == "\\begin{itemize}\n«  % Notiz\n  \\item Text»\n\\end{itemize}")
    }

    @Test func minipageGetsWidth() {
        #expect(wrapped("«Text»", in: "minipage") == "\\begin{minipage}{0.45\\textwidth}\n  «Text»\n\\end{minipage}")
    }

    @Test func emojiAndUmlauts() {
        #expect(wrapped("«😀 Spass»", in: "quote") == "\\begin{quote}\n«  😀 Spass»\n\\end{quote}")
        #expect(wrapped("Grüsse 😀|", in: "center") == "Grüsse 😀\n\\begin{center}\n  |\n\\end{center}")
    }
}

// MARK: - Zeilen verschieben

@Suite("Zeilen verschieben")
struct MoveLinesTests {
    @Test func movesSingleLine() {
        #expect(moved("A\nB|\nC", up: true) == "B|\nA\nC")
        #expect(moved("A\nB|\nC", up: false) == "A\nC\nB|")
    }

    @Test func lastLineWithoutNewline() {
        #expect(moved("A\nB\nC|", up: true) == "A\nC|\nB")
        #expect(moved("A\nB\nC|", up: false) == nil)
        #expect(moved("A\nB|\nC", up: false) == "A\nC\nB|")
    }

    @Test func nilAtStartAndEnd() {
        #expect(moved("A|\nB", up: true) == nil)
        #expect(moved("A|\nB", up: false) == "B\nA|")
        #expect(moved("|", up: true) == nil)
        #expect(moved("|", up: false) == nil)
        #expect(moved("Nur| eine Zeile", up: false) == nil)
    }

    @Test func movesSeveralLines() {
        #expect(moved("A\n«B\nC»\nD", up: true) == "«B\nC»\nA\nD")
        #expect(moved("A\n«B\nC»\nD", up: false) == "A\nD\n«B\nC»")
    }

    @Test func selectionEndingAtLineStart() {
        #expect(moved("A\n«B\n»C\nD", up: false) == "A\nC\n«B\n»D")
        #expect(moved("A\n«B\n»C\nD", up: true) == "«B\n»A\nC\nD")
        // Der Block wird zur letzten Zeile: Der mitmarkierte Umbruch fällt weg.
        #expect(moved("A\n«B\n»C", up: false) == "A\nC\n«B»")
    }

    @Test func trailingNewline() {
        #expect(moved("A|\n", up: false) == "\nA|")
        #expect(moved("\nA|", up: false) == nil)
        #expect(moved("\nA|", up: true) == "A|\n")
    }

    @Test func umlautsAndEmoji() {
        #expect(moved("Grüsse 😀|\nZweite", up: false) == "Zweite\nGrüsse 😀|")
        #expect(moved("Zweite\n«Grüsse» 😀", up: true) == "«Grüsse» 😀\nZweite")
    }

    @Test func downThenUpRestores() {
        for start in ["A\n«B\nC»\nD\nE", "Eins\nZw|ei\nDrei", "x\n«y\n»z", "a\n\n|b\n"] {
            let down = moved(start, up: false)!
            #expect(moved(down, up: true) == start)
        }
    }
}

// MARK: - Auskommentieren

@Suite("Auskommentieren")
struct ToggleCommentTests {
    @Test func commentsLine() {
        #expect(commented("Zeile|") == "% Zeile|")
        #expect(commented("ab|c") == "% ab|c")
        #expect(commented("  \\item a|") == "  % \\item a|")
        #expect(commented("😀|") == "% 😀|")
    }

    @Test func uncommentsLine() {
        #expect(commented("  % \\item a|") == "  \\item a|")
        #expect(commented("%Zeile|") == "Zeile|")
        #expect(commented("%  Zeile|") == " Zeile|")
        #expect(commented("% |Zeile") == "|Zeile")
        #expect(commented("%| Zeile") == "|Zeile")
    }

    @Test func mixedLinesAreCommented() {
        #expect(commented("«a\n% b»") == "«% a\n% % b»")
    }

    @Test func blankLinesAreSkipped() {
        #expect(commented("«a\n\nb»") == "«% a\n\n% b»")
        #expect(commented("«% a\n\n  % b»") == "«a\n\n  b»")
    }

    @Test func blankLineStartsComment() {
        #expect(commented("|") == "% |")
        #expect(commented("  |") == "  % |")
        #expect(commented("a\n|\nb") == "a\n% |\nb")
    }

    @Test func escapedPercentIsNoComment() {
        #expect(commented("\\% kein Kommentar|") == "% \\% kein Kommentar|")
    }

    @Test func selectionEndingAtLineStart() {
        #expect(commented("«a\n»b") == "«% a\n»b")
    }

    @Test func roundTrip() {
        for start in ["«a\n  b\n\nc»", "x|", "  ei|n\n  zwei", "«Grüsse 😀\n\\item {x}»", "a\n«b\n»c"] {
            let once = commented(start)!
            #expect(once != start)
            #expect(commented(once) == start)
        }
    }

    @Test func worksOnNSString() {
        let source = NSStringSource(NSString(string: "a\nb"))
        let edit = BlockEditor.toggleComment(in: source, selection: 0..<3)
        #expect(outcome(edit, on: "a\nb") == "«% a\n% b»")
    }
}

// MARK: - Einrücken

@Suite("Einrücken und Ausrücken")
struct ShiftIndentationTests {
    @Test func indents() {
        #expect(shifted("a|") == "  a|")
        #expect(shifted("|a") == "  |a")
        #expect(shifted("«a\nb»") == "«  a\n  b»")
        #expect(shifted("  «a\n  b»") == "    «a\n    b»")
    }

    @Test func outdents() {
        #expect(shifted("  a|", outdent: true) == "a|")
        #expect(shifted("\ta|", outdent: true) == "a|")
        #expect(shifted(" a|", outdent: true) == "a|")
        #expect(shifted("   a|", outdent: true) == " a|")
        #expect(shifted("«  a\n    b»", outdent: true) == "«a\n  b»")
        #expect(shifted("  |a", outdent: true) == "|a")
        #expect(shifted(" | a", outdent: true) == "|a")
    }

    @Test func nothingToOutdent() {
        let (text, selection) = parseBlockMarks("a|")
        let edit = BlockEditor.shiftIndentation(in: units(text), selection: selection, outdent: true)
        #expect(!edit.changesText)
        #expect(outcome(edit, on: text) == "a|")
    }

    @Test func blankLinesStayEmpty() {
        #expect(shifted("«a\n\nb»") == "«  a\n\n  b»")
        #expect(shifted("|") == "  |")
    }

    @Test func selectionEndingAtLineStart() {
        #expect(shifted("«a\n»b") == "«  a\n»b")
        #expect(shifted("«  a\n»  b", outdent: true) == "«a\n»  b")
    }

    @Test func umlautsAndEmoji() {
        #expect(shifted("Grü|sse 😀\n😀") == "  Grü|sse 😀\n😀")
    }

    @Test func roundTrip() {
        for start in ["«a\nb\n\nc»", "x|", "\tei|n\n  zwei", "«Grüsse 😀\n\\item {x}»"] {
            let indentedText = shifted(start)!
            #expect(shifted(indentedText, outdent: true) == start)
        }
    }
}

// MARK: - Formel im Text ↔ abgesetzt

@Suite("Formel abgesetzt ↔ im Text")
struct ToggleDisplayMathTests {
    @Test func inlineBecomesDisplay() {
        #expect(displayToggled("Es gilt $a^2 + b|^2$ immer") == "Es gilt\n\\[ a^2 + b|^2 \\]\nimmer")
        #expect(displayToggled("Text \\(y|\\) mehr") == "Text\n\\[ y| \\]\nmehr")
        #expect(displayToggled("$x|$") == "\\[ x| \\]")
        #expect(displayToggled("  $ x| $") == "  \\[ x| \\]")
        #expect(displayToggled("  Sei $f(x)|$ gegeben") == "  Sei\n  \\[ f(x)| \\]\n  gegeben")
    }

    @Test func punctuationMovesIntoDisplay() {
        #expect(displayToggled("Es gilt $x = 1|$.") == "Es gilt\n\\[ x = 1|. \\]")
        #expect(displayToggled("Für $x|$, und") == "Für\n\\[ x|, \\]\nund")
        // Kein Satzende: `.5` bleibt im Text.
        #expect(displayToggled("$x|$.5") == "\\[ x| \\]\n.5")
    }

    @Test func displayBecomesInline() {
        #expect(displayToggled("Es gilt\n\\[\n  a = b|\n\\]\nimmer") == "Es gilt\n$a = b|$\nimmer")
        #expect(displayToggled("\\[ a\n  + b|\n\\]") == "$a + b|$")
        #expect(displayToggled("$$x|$$") == "$x|$")
        #expect(displayToggled("\\[ x = 1|. \\]") == "$x = 1|$.")
        #expect(displayToggled("\\[ «a + b» \\]") == "$«a + b»$")
    }

    @Test func commentsInsideDisplay() {
        #expect(displayToggled("\\[\n  a % Notiz\n  + b|\n\\]") == "$a % Notiz\n+ b|$")
        #expect(displayToggled("\\[\n  a % Notiz|\n\\]") == "$a % Notiz|\n$")
        #expect(displayToggled("$a % c\n b|$") == "\\[ a % c\n b| \\]")
    }

    @Test func escapedCharacters() {
        #expect(displayToggled("Preis \\$5 und $x|$") == "Preis \\$5 und\n\\[ x| \\]")
        // Ein maskiertes Leerzeichen am Ende ist Inhalt und darf nicht verschwinden.
        #expect(displayToggled("\\[ a\\ | \\]") == "$a\\ |$")
        #expect(displayToggled("\\[ 5\\%| \\]") == "$5\\%|$")
    }

    @Test func emojiAroundFormula() {
        #expect(displayToggled("😀 $x|$ 😀") == "😀\n\\[ x| \\]\n😀")
        #expect(displayToggled("\\[ 😀| \\]") == "$😀|$")
    }

    @Test func cursorOnDelimiterStaysInFormula() {
        #expect(displayToggled("Text |$x$") == "Text\n\\[ |x \\]")
        #expect(displayToggled("\\[ x \\]|") == "$x|$")
    }

    @Test func emptyFormulas() {
        #expect(displayToggled("$ |$") == "\\[ | \\]")
        #expect(displayToggled("\\[ | \\]") == "$| $")
    }

    @Test func roundTrips() {
        #expect(displayToggled(displayToggled("Es gilt $x|$ und")!) == "Es gilt\n$x|$\nund")
        #expect(displayToggled(displayToggled("Es gilt $x = 1|$.")!) == "Es gilt\n$x = 1|$.")
        #expect(displayToggled(displayToggled("\\[ a + b| \\]")!) == "\\[ a + b| \\]")
    }

    @Test func nilOutsideFormulas() {
        #expect(displayToggled("Text|") == nil)
        #expect(displayToggled("|") == nil)
        #expect(displayToggled("\\begin{align}a|\\end{align}") == nil)
        #expect(displayToggled("Offen $x|") == nil)
        #expect(displayToggled("% $x|$") == nil)
        #expect(displayToggled("$a$ und| $b$") == nil)
    }
}

// MARK: - Umwandeln und Namen

@Suite("Umwandlungen und Anzeigenamen")
struct ConversionTests {
    @Test func conversionGroups() {
        #expect(BlockEditor.conversions(for: "align*") == [
            "equation", "equation*", "align", "gather", "gather*", "multline", "multline*"
        ])
        #expect(BlockEditor.conversions(for: "itemize") == ["enumerate", "description"])
        #expect(BlockEditor.conversions(for: "center") == ["flushleft", "flushright"])
        #expect(BlockEditor.conversions(for: "proof") == ["definition", "satz", "lemma", "korollar", "beispiel", "bemerkung"])
        #expect(BlockEditor.conversions(for: "pmatrix") == ["matrix", "bmatrix", "vmatrix", "Bmatrix", "Vmatrix"])
        #expect(BlockEditor.conversions(for: "quote") == ["quotation"])
    }

    @Test func unknownHasNoConversions() {
        #expect(BlockEditor.conversions(for: "minipage").isEmpty)
        #expect(BlockEditor.conversions(for: "").isEmpty)
        #expect(BlockEditor.conversions(for: "document").isEmpty)
    }

    @Test func displayNames() {
        #expect(BlockEditor.displayName(for: "align*") == "Ausgerichtete Formeln (ohne Nummer)")
        #expect(BlockEditor.displayName(for: "pmatrix") == "Matrix mit runden Klammern")
        #expect(BlockEditor.displayName(for: "proof") == "Beweis")
        #expect(BlockEditor.displayName(for: "itemize") == "Aufzählung")
        #expect(BlockEditor.displayName(for: "minipage") == "Minipage")
        #expect(BlockEditor.displayName(for: "meineUmgebung") == "meineUmgebung")
    }

    @Test func everyGroupMemberHasAUniqueGermanName() {
        let groups = [
            ["equation", "equation*", "align", "align*", "gather", "gather*", "multline", "multline*"],
            ["itemize", "enumerate", "description"],
            ["center", "flushleft", "flushright"],
            ["definition", "satz", "lemma", "korollar", "beispiel", "bemerkung", "proof"],
            ["matrix", "pmatrix", "bmatrix", "vmatrix", "Bmatrix", "Vmatrix"],
            ["quote", "quotation"]
        ]
        for group in groups {
            let names = group.map { BlockEditor.displayName(for: $0) }
            #expect(Set(names).count == names.count)
            for member in group {
                #expect(BlockEditor.conversions(for: member) == group.filter { $0 != member })
                if member.lowercased() != member || member.count > 6 {
                    #expect(BlockEditor.displayName(for: member) != member)
                }
            }
        }
        // Alles aus dem Menü „In Umgebung einpacken“ hat einen deutschen Namen.
        for name in ["center", "quote", "itemize", "enumerate", "definition", "satz", "beispiel", "bemerkung", "proof"] {
            #expect(BlockEditor.displayName(for: name) != name)
        }
    }
}

// MARK: - Grundregeln für alle Werkzeuge

@Suite("Block-Werkzeuge: Grundregeln")
struct BlockEditorInvariantTests {
    static let samples = [
        "",
        "a",
        "\n",
        "Grüsse 😀\nZeile",
        "% Kommentar\n  Text mit \\% und \\{x\\}\n",
        "\\begin{center}\n  Zentriert 😀\n\\end{center}",
        "Vor $a+b$ nach\n\\[\n  x^2\n\\]\nEnde.",
        "\\begin{itemize}\n  \\item Äpfel\n\n  \\item {Birnen}\n\\end{itemize}\n",
        "\\begin{equation}\n  a = b % Notiz\n\\end{equation}\n\\begin{figure}[htbp]\n\t\\centering\n\\end{figure}"
    ]

    /// Liegt `offset` mitten in einem Emoji (zwischen den beiden UTF-16-Hälften)?
    private func splitsSurrogatePair(_ text: [UInt16], _ offset: Int) -> Bool {
        offset > 0 && offset < text.count && UTF16.isLeadSurrogate(text[offset - 1]) && UTF16.isTrailSurrogate(text[offset])
    }

    private func check(_ edit: TextEdit?, on text: String, selection: Range<Int>) {
        guard let edit, let new = checkedText(edit, on: text) else { return }
        let newUnits = units(new)
        if !text.contains("\u{FFFD}") { #expect(!new.contains("\u{FFFD}")) }
        if !splitsSurrogatePair(units(text), selection.lowerBound), !splitsSurrogatePair(units(text), selection.upperBound) {
            #expect(!splitsSurrogatePair(newUnits, edit.selectionAfter.lowerBound))
            #expect(!splitsSurrogatePair(newUnits, edit.selectionAfter.upperBound))
        }
    }

    @Test(arguments: samples)
    func everyEditIsValid(_ text: String) {
        let source = units(text)
        for lower in 0...source.count {
            for upper in lower...source.count {
                let selection = lower..<upper
                let expansion = BlockEditor.expandSelection(in: source, selection: selection)
                #expect(expansion.lowerBound >= 0 && expansion.upperBound <= source.count)
                #expect(expansion.lowerBound <= lower && expansion.upperBound >= upper)

                check(BlockEditor.toggleNumbering(in: source, selection: selection), on: text, selection: selection)
                check(BlockEditor.wrap(selection: selection, inEnvironment: "center", in: source), on: text, selection: selection)
                check(BlockEditor.wrap(selection: selection, inEnvironment: "itemize", in: source), on: text, selection: selection)
                check(BlockEditor.moveLines(in: source, selection: selection, up: true), on: text, selection: selection)
                check(BlockEditor.moveLines(in: source, selection: selection, up: false), on: text, selection: selection)
                check(BlockEditor.toggleComment(in: source, selection: selection), on: text, selection: selection)
                check(BlockEditor.shiftIndentation(in: source, selection: selection, outdent: false), on: text, selection: selection)
                check(BlockEditor.shiftIndentation(in: source, selection: selection, outdent: true), on: text, selection: selection)
                check(BlockEditor.toggleDisplayMath(in: source, selection: selection), on: text, selection: selection)
                if let block = BlockEditor.enclosingEnvironment(in: source, at: lower) {
                    check(BlockEditor.unwrapEnvironment(block, in: source, selection: selection), on: text, selection: selection)
                    check(BlockEditor.renameEnvironment(block, to: "quote", in: source, selection: selection), on: text, selection: selection)
                }
            }
        }
    }

    @Test(arguments: samples)
    func roundTripsRestoreText(_ text: String) {
        let source = units(text)
        for lower in 0...source.count {
            for upper in lower...source.count {
                let selection = lower..<upper

                // Zeilen runter und wieder rauf.
                if let down = BlockEditor.moveLines(in: source, selection: selection, up: false) {
                    let moved = applyBlockEdit(down, to: text)
                    if let back = BlockEditor.moveLines(in: units(moved), selection: down.selectionAfter, up: true) {
                        #expect(applyBlockEdit(back, to: moved) == text)
                    } else {
                        Issue.record("Zeilen liessen sich nicht zurückschieben")
                    }
                }

                // Aus- und wieder einkommentieren (nur ohne vorhandene Kommentare eindeutig).
                if !text.contains("%") {
                    let comment = BlockEditor.toggleComment(in: source, selection: selection)
                    let commentedText = applyBlockEdit(comment, to: text)
                    let uncomment = BlockEditor.toggleComment(in: units(commentedText), selection: comment.selectionAfter)
                    #expect(applyBlockEdit(uncomment, to: commentedText) == text)
                    #expect(uncomment.selectionAfter == selection || selection.isEmpty == false)
                }

                // Ein- und wieder ausrücken.
                let indent = BlockEditor.shiftIndentation(in: source, selection: selection, outdent: false)
                let indentedText = applyBlockEdit(indent, to: text)
                let outdent = BlockEditor.shiftIndentation(in: units(indentedText), selection: indent.selectionAfter, outdent: true)
                #expect(applyBlockEdit(outdent, to: indentedText) == text)

                // Nummerierung zweimal umschalten.
                if !text.contains("\\["), let toggle = BlockEditor.toggleNumbering(in: source, selection: selection) {
                    let toggled = applyBlockEdit(toggle, to: text)
                    let back = BlockEditor.toggleNumbering(in: units(toggled), selection: toggle.selectionAfter)
                    #expect(back.map { applyBlockEdit($0, to: toggled) } == text)
                }
            }
        }
    }
}
