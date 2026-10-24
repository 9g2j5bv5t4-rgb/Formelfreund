import Foundation
import Testing
@testable import LaTeXKit

// Schreibweise in diesen Tests:
// `|` markiert den Cursor, `«…»` eine Auswahl – im Text vorher wie nachher.

/// Zerlegt einen markierten Text in reinen Text und Auswahl (UTF-16-Offsets).
private func parseMarked(_ marked: String) -> (text: String, selection: Range<Int>) {
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
private func marking(_ selection: Range<Int>, in text: String) -> String {
    let string = text as NSString
    if selection.isEmpty {
        return string.replacingCharacters(in: NSRange(location: selection.lowerBound, length: 0), with: "|")
    }
    let closed = string.replacingCharacters(in: NSRange(location: selection.upperBound, length: 0), with: "»") as NSString
    return closed.replacingCharacters(in: NSRange(location: selection.lowerBound, length: 0), with: "«")
}

/// Führt eine Bearbeitung aus und liefert den neuen Text (ohne Markierungen).
private func applying(_ edit: TextEdit, to text: String) -> String {
    (text as NSString).replacingCharacters(
        in: NSRange(location: edit.range.lowerBound, length: edit.range.count),
        with: edit.replacement
    )
}

/// Jede Bearbeitung muss *ein* zusammenhängender Bereich im alten Text sein und
/// eine Auswahl liefern, die im neuen Text liegt.
private func checkValid(
    _ edit: TextEdit, oldLength: Int, sourceLocation: SourceLocation = #_sourceLocation
) {
    #expect(edit.range.lowerBound >= 0 && edit.range.upperBound <= oldLength, sourceLocation: sourceLocation)
    let newLength = oldLength + edit.lengthDelta
    #expect(edit.selectionAfter.lowerBound >= 0, sourceLocation: sourceLocation)
    #expect(edit.selectionAfter.upperBound <= newLength, sourceLocation: sourceLocation)
}

/// Führt eine Formatierung auf markiertem Text aus und liefert das markierte Ergebnis.
private func run(
    _ marked: String,
    sourceLocation: SourceLocation = #_sourceLocation,
    _ action: ([UInt16], Range<Int>) -> TextEdit
) -> String {
    let (text, selection) = parseMarked(marked)
    let units = Array(text.utf16)
    let edit = action(units, selection)
    checkValid(edit, oldLength: units.count, sourceLocation: sourceLocation)
    return marking(edit.selectionAfter, in: applying(edit, to: text))
}

private func toggle(_ style: InlineStyle, _ marked: String, sourceLocation: SourceLocation = #_sourceLocation) -> String {
    run(marked, sourceLocation: sourceLocation) { InlineFormatter.toggle(style, in: $0, selection: $1) }
}

private func size(_ size: FontSize, _ marked: String, sourceLocation: SourceLocation = #_sourceLocation) -> String {
    run(marked, sourceLocation: sourceLocation) { InlineFormatter.setFontSize(size, in: $0, selection: $1) }
}

private func color(_ color: TextColor?, _ marked: String, sourceLocation: SourceLocation = #_sourceLocation) -> String {
    run(marked, sourceLocation: sourceLocation) { InlineFormatter.setColor(color, in: $0, selection: $1) }
}

private func inlineState(_ marked: String) -> FormattingState {
    let (text, selection) = parseMarked(marked)
    return InlineFormatter.state(in: Array(text.utf16), selection: selection)
}

private func heading(
    _ style: ParagraphStyle, _ marked: String, scheme: HeadingScheme = .article,
    sourceLocation: SourceLocation = #_sourceLocation
) -> String {
    run(marked, sourceLocation: sourceLocation) { ParagraphFormatter.apply(style, in: $0, selection: $1, scheme: scheme) }
}

private func align(_ alignment: TextAlignment, _ marked: String, sourceLocation: SourceLocation = #_sourceLocation) -> String {
    run(marked, sourceLocation: sourceLocation) { ParagraphFormatter.align(alignment, in: $0, selection: $1) }
}

private func list(_ kind: ListKind, _ marked: String, sourceLocation: SourceLocation = #_sourceLocation) -> String {
    run(marked, sourceLocation: sourceLocation) { ParagraphFormatter.toggleList(kind, in: $0, selection: $1) }
}

private func paragraphState(_ marked: String, scheme: HeadingScheme = .article) -> ParagraphState {
    let (text, selection) = parseMarked(marked)
    return ParagraphFormatter.state(in: Array(text.utf16), selection: selection, scheme: scheme)
}

private func scheme(_ text: String) -> HeadingScheme {
    HeadingScheme.detect(in: Array(text.utf16))
}

// MARK: - Zeichenformat

@Suite("Zeichenformat umschalten")
struct InlineToggleTests {
    @Test func wrapsAndUnwrapsSelection() {
        #expect(toggle(.bold, "Das ist «wichtig».") == "Das ist \\textbf{«wichtig»}.")
        #expect(toggle(.bold, "Das ist \\textbf{«wichtig»}.") == "Das ist «wichtig».")
        #expect(toggle(.bold, "Das ist «\\textbf{wichtig}».") == "Das ist «wichtig».")
    }

    @Test func everyStyleRoundTrips() {
        for style in InlineStyle.allCases {
            let wrapped = toggle(style, "Ein «Wort» hier")
            #expect(wrapped == "Ein \\\(style.command){«Wort»} hier")
            #expect(toggle(style, wrapped) == "Ein «Wort» hier")
            #expect(inlineState(wrapped).styles == [style])
        }
    }

    @Test func cursorInsideGroupUnwraps() {
        #expect(toggle(.bold, "\\textbf{wic|htig}") == "wic|htig")
        #expect(toggle(.bold, "\\textbf{|wichtig}") == "|wichtig")
        #expect(toggle(.bold, "\\textbf{wichtig|}") == "wichtig|")
        #expect(toggle(.bold, "\\textbf{|}") == "|")
        #expect(toggle(.italic, "Ein \\textit{schönes} Wo|rt") == "Ein \\textit{schönes} \\textit{Wo|rt}")
        // Nur die passende Gruppe wird entfernt, auch wenn sie nicht die innerste ist.
        #expect(toggle(.bold, "\\textbf{Hallo \\textit{We|lt}}") == "Hallo \\textit{We|lt}")
    }

    @Test func cursorInWordWrapsWord() {
        #expect(toggle(.bold, "Hallo We|lt") == "Hallo \\textbf{We|lt}")
        #expect(toggle(.bold, "Müs|li und Äpfel") == "\\textbf{Müs|li} und Äpfel")
        #expect(toggle(.italic, "Ä|pfel") == "\\textit{Ä|pfel}")
        #expect(toggle(.bold, "Raum 1|01") == "Raum \\textbf{1|01}")
        #expect(toggle(.bold, "\\textit{Hal|lo}") == "\\textit{\\textbf{Hal|lo}}")
        // Emoji gehören nicht zum Wort, die Position im Wort stimmt trotzdem.
        #expect(toggle(.bold, "😀 Wo|rt") == "😀 \\textbf{Wo|rt}")
        #expect(toggle(.bold, "Wo|rt😀") == "\\textbf{Wo|rt}😀")
    }

    @Test func cursorOutsideWordInsertsEmptyCommand() {
        #expect(toggle(.bold, "|") == "\\textbf{|}")
        #expect(toggle(.bold, "Hallo |Welt") == "Hallo \\textbf{|}Welt")
        #expect(toggle(.bold, "Hallo| Welt") == "Hallo\\textbf{|} Welt")
        #expect(toggle(.bold, "|Wort") == "\\textbf{|}Wort")
        #expect(toggle(.bold, "Wort|") == "Wort\\textbf{|}")
        #expect(toggle(.bold, "Hallo 😀|Welt") == "Hallo 😀\\textbf{|}Welt")
        #expect(toggle(.underline, "a |") == "a \\underline{|}")
    }

    @Test func neverInsertsIntoCommandNames() {
        #expect(toggle(.bold, "\\tex|tit{x}") == "\\textbf{|}\\textit{x}")
        #expect(toggle(.bold, "\\|section{x}") == "\\textbf{|}\\section{x}")
        #expect(toggle(.bold, "5 \\|%") == "5 \\textbf{|}\\%")
        // Am Ende eines Befehlsnamens darf eingefügt werden (Backslash trennt).
        #expect(toggle(.bold, "\\LaTeX| ist") == "\\LaTeX\\textbf{|} ist")
        // `\\` ist ein Zeilenumbruch, danach beginnt ein normales Wort.
        #expect(toggle(.bold, "a\\\\Wo|rt") == "a\\\\\\textbf{Wo|rt}")
    }

    @Test func selectionInsideFormattedTextIsTakenOut() {
        #expect(toggle(.bold, "\\textbf{Hallo «Welt»}") == "\\textbf{Hallo }«Welt»")
        #expect(toggle(.bold, "\\textbf{eins «zwei» drei}") == "\\textbf{eins }«zwei»\\textbf{ drei}")
        #expect(toggle(.bold, "\\textbf{«Hallo» Welt}") == "«Hallo»\\textbf{ Welt}")
        // Nur Leerraum daneben: keine leeren Gruppen.
        #expect(toggle(.bold, "\\textbf{ «Welt»}") == " «Welt»")
        // Durch ein anderes Format hindurch.
        #expect(toggle(.bold, "\\textbf{Hallo \\textit{«Welt»}}") == "\\textbf{Hallo }\\textit{«Welt»}")
    }

    @Test func nestedFormatsAreRecognised() {
        #expect(toggle(.bold, "\\textbf{\\textit{«x»}}") == "\\textit{«x»}")
        #expect(toggle(.italic, "\\textbf{\\textit{«x»}}") == "\\textbf{«x»}")
        #expect(toggle(.italic, "«\\textbf{\\textit{x}}»") == "«\\textbf{x}»")
        #expect(toggle(.bold, "«\\textbf{\\textit{x}}»") == "«\\textit{x}»")
        #expect(toggle(.underline, "«\\textbf{x}»") == "\\underline{«\\textbf{x}»}")
    }

    @Test func selectionEdgesAreCleanedUp() {
        // Leerraum am Rand bleibt draussen.
        #expect(toggle(.bold, "«Wort »weiter") == "\\textbf{«Wort»} weiter")
        #expect(toggle(.bold, "«Zeile\n»Neu") == "\\textbf{«Zeile»}\nNeu")
        // Befehle werden nicht zerschnitten.
        #expect(toggle(.bold, "\\te«xtit{x}»") == "\\textbf{«\\textit{x}»}")
        #expect(toggle(.italic, "\\te«xtit{x}»") == "«x»")
        #expect(toggle(.bold, "«a \\»%") == "\\textbf{«a \\%»}")
        // Nur Leerraum ausgewählt: wird trotzdem eingepackt.
        #expect(toggle(.bold, "a« »b") == "a\\textbf{« »}b")
    }

    @Test func selectionSpanningLines() {
        #expect(toggle(.bold, "«Zeile eins\nZeile zwei»") == "\\textbf{«Zeile eins\nZeile zwei»}")
        #expect(toggle(.bold, "\\textbf{«Zeile eins\nZeile zwei»}") == "«Zeile eins\nZeile zwei»")
    }

    @Test func commentsAreRespected() {
        // Klammern im Kommentar zählen nicht.
        #expect(toggle(.bold, "\\textbf{a % kommentar }\nb|c}") == "a % kommentar }\nb|c")
        #expect(toggle(.bold, "Text % \\textbf{x\nWo|rt") == "Text % \\textbf{x\n\\textbf{Wo|rt}")
        // Auswahl endet im Kommentar: Klammer vor dem Kommentar schliessen.
        #expect(toggle(.bold, "«Text % Notiz»") == "\\textbf{«Text»} % Notiz")
        // Auswahl beginnt im Kommentar: erst auf der nächsten Zeile einpacken.
        #expect(toggle(.bold, "% No«tiz\nText»") == "% Notiz\n\\textbf{«Text»}")
        // Ganz im Kommentar: harmlos einpacken.
        #expect(toggle(.bold, "% «Notiz»") == "% \\textbf{«Notiz»}")
        // Nur das Prozentzeichen: nichts tun, sonst stünde eine Klammer im Kommentar.
        #expect(toggle(.bold, "a «%» b") == "a «%» b")
    }

    @Test func escapedBracesAreIgnored() {
        #expect(toggle(.bold, "\\textbf{a \\{ b|c}") == "a \\{ b|c")
        #expect(toggle(.bold, "\\{Wo|rt\\}") == "\\{\\textbf{Wo|rt}\\}")
        #expect(inlineState("\\textbf\\{a|\\}").styles.isEmpty)
    }

    @Test func onlyCurrentParagraph() {
        // Über eine Leerzeile hinweg gibt es keine Gruppe.
        #expect(inlineState("\\textbf{a\n\nb|c}").styles.isEmpty)
        #expect(toggle(.bold, "\\textbf{a\n\nb|c}") == "\\textbf{a\n\n\\textbf{b|c}}")
    }

    @Test func commandsDoNotMergeAfterUnwrapping() {
        #expect(toggle(.bold, "\\LaTeX\\textbf{i|st}") == "\\LaTeX{}i|st")
        #expect(toggle(.bold, "\\textbf{\\LaTe|X}ist") == "\\LaTe|X{}ist")
        #expect(toggle(.bold, "\\textbf{\\LaTeX} |ist") == "\\textbf{\\LaTeX} \\textbf{|}ist")
    }

    @Test func emojiSelections() {
        #expect(toggle(.bold, "«😀»") == "\\textbf{«😀»}")
        #expect(toggle(.bold, "\\textbf{«😀»}") == "«😀»")
        // Auswahl mitten im Ersatzpaar wird auf das ganze Emoji erweitert.
        let units = Array("a😀b".utf16)
        let edit = InlineFormatter.toggle(.bold, in: units, selection: 2..<3)
        checkValid(edit, oldLength: units.count)
        #expect(applying(edit, to: "a😀b") == "a\\textbf{😀}b")
        #expect(edit.selectionAfter == 9..<11)
    }

    @Test func worksOnNSString() {
        let source = NSStringSource("Hallo Welt" as NSString)
        let edit = InlineFormatter.toggle(.bold, in: source, selection: 8..<8)
        #expect(edit == TextEdit(range: 6..<10, replacement: "\\textbf{Welt}", selectionAfter: 16..<16))
    }
}

@Suite("Zeichenformat-Zustand")
struct InlineStateTests {
    @Test func stylesAtCursor() {
        #expect(inlineState("\\textbf{\\textit{a|b}}").styles == [.bold, .italic])
        #expect(inlineState("\\textbf{|a}").styles == [.bold])
        #expect(inlineState("\\textbf{a|}").styles == [.bold])
        #expect(inlineState("\\textbf{a}|b").styles.isEmpty)
        #expect(inlineState("|\\textbf{a}").styles.isEmpty)
        #expect(inlineState("\\text|bf{a}").styles.isEmpty)
        #expect(inlineState("\\emph{\\underline{\\textsc{\\texttt{\\textsf{x|}}}}}").styles
            == [.emphasis, .underline, .smallCaps, .monospace, .sansSerif])
        #expect(inlineState("|") == FormattingState())
        #expect(inlineState("% \\textbf{a|b}").styles.isEmpty)
    }

    @Test func stylesOfSelection() {
        #expect(inlineState("«\\textbf{a}»").styles == [.bold])
        #expect(inlineState("«\\textbf{\\textit{a}}»").styles == [.bold, .italic])
        #expect(inlineState("\\textbf{«a» b}").styles == [.bold])
        #expect(inlineState("«a \\textbf{b}»").styles.isEmpty)
        #expect(inlineState("\\textbf{a «b}c»").styles.isEmpty)
    }

    @Test func fontSize() {
        #expect(inlineState("{\\large Te|xt}").fontSize == .large)
        #expect(inlineState("{  \\Huge a {\\small b|}}").fontSize == .small)
        #expect(inlineState("{\\Huge a {\\small b} c|}").fontSize == .Huge)
        #expect(inlineState("\\textbf{\\LARGE x|}").fontSize == .LARGE)
        #expect(inlineState("«{\\footnotesize x}»").fontSize == .footnotesize)
        #expect(inlineState("{\\largeish x|}").fontSize == nil)
        #expect(inlineState("{\\large x}|").fontSize == nil)
    }

    @Test func color() {
        #expect(inlineState("\\textcolor{red}{ro|t}").color == .red)
        #expect(inlineState("\\textcolor{ green!50!black }{x|}").color == .green)
        #expect(inlineState("\\textcolor{magenta}{x|}").color == nil)
        #expect(inlineState("\\textcolor{re|d}{x}").color == nil)
        #expect(inlineState("\\textcolor{red}{a \\textcolor{pink}{b|}}").color == nil)
        #expect(inlineState("\\textcolor{pink}{a \\textcolor{blue}{b|}}").color == .blue)
        #expect(inlineState("«\\textcolor{teal}{x}»").color == .teal)
        #expect(inlineState("\\textcolor[rgb]{1,0,0}{x|}").color == nil)
        for textColor in TextColor.allCases {
            #expect(inlineState("\\textcolor{\(textColor.latexName)}{|}").color == textColor)
        }
    }

    @Test func combined() {
        let state = inlineState("\\textcolor{gray}{{\\small \\textbf{Wo|rt}}}")
        #expect(state == FormattingState(styles: [.bold], fontSize: .small, color: .gray))
    }
}

@Suite("Schriftgrösse")
struct FontSizeTests {
    @Test func wrapsSelectionAndWord() {
        #expect(size(.large, "«Text»") == "{\\large «Text»}")
        #expect(size(.Huge, "Hallo We|lt") == "Hallo {\\Huge We|lt}")
        #expect(size(.small, "Hallo |") == "Hallo {\\small |}")
        #expect(size(.tiny, "|") == "{\\tiny |}")
    }

    @Test func replacesExistingSize() {
        #expect(size(.Huge, "{\\large Te|xt}") == "{\\Huge Te|xt}")
        #expect(size(.small, "{\\large «Text»}") == "{\\small «Text»}")
        #expect(size(.small, "«{\\large Text}»") == "«{\\small Text}»")
        #expect(size(.Large, "{\\lar|ge Text}") == "{\\Large| Text}")
        #expect(size(.large, "{\\large Te|xt}") == "{\\large Te|xt}")
    }

    @Test func normalsizeRemovesGroup() {
        #expect(size(.normalsize, "{\\large Te|xt}") == "Te|xt")
        #expect(size(.normalsize, "«{\\large Text}»") == "«Text»")
        #expect(size(.normalsize, "{\\large «Text»}") == "«Text»")
        #expect(size(.normalsize, "{\\large |}") == "|")
        // Ohne Grössengruppe: nichts zu tun.
        #expect(size(.normalsize, "Hal|lo") == "Hal|lo")
        #expect(size(.normalsize, "«Hallo»") == "«Hallo»")
    }

    @Test func normalsizeKeepsOtherDeclarations() {
        #expect(size(.normalsize, "{\\large \\bfseries Te|xt}") == "{\\bfseries Te|xt}")
        #expect(size(.normalsize, "\\textbf{\\large Te|xt}") == "\\textbf{Te|xt}")
        #expect(size(.normalsize, "x^{\\large 2|3}") == "x^{2|3}")
        #expect(toggle(.bold, "\\textbf{\\large Te|xt}") == "{\\large Te|xt}")
    }

    @Test func partOfSizedText() {
        #expect(size(.normalsize, "{\\large Hallo «Welt»}") == "{\\large Hallo }«Welt»")
        #expect(size(.huge, "{\\large Hallo «Welt»}") == "{\\large Hallo {\\huge «Welt»}}")
        #expect(size(.large, "{\\large Hallo «Welt»}") == "{\\large Hallo «Welt»}")
    }

    @Test func stateRoundTrip() {
        for fontSize in FontSize.allCases where fontSize != .normalsize {
            let sized = size(fontSize, "ein «Wort»")
            #expect(inlineState(sized).fontSize == fontSize)
            #expect(size(.normalsize, sized) == "ein «Wort»")
        }
    }
}

@Suite("Textfarbe")
struct ColorTests {
    @Test func wrapsSelectionAndWord() {
        #expect(color(.red, "«Text»") == "\\textcolor{red}{«Text»}")
        #expect(color(.green, "«Text»") == "\\textcolor{green!50!black}{«Text»}")
        #expect(color(.blue, "Wo|rt") == "\\textcolor{blue}{Wo|rt}")
        #expect(color(.red, "|") == "\\textcolor{red}{|}")
    }

    @Test func replacesAndRemovesColor() {
        #expect(color(.blue, "\\textcolor{red}{Te|xt}") == "\\textcolor{blue}{Te|xt}")
        #expect(color(.violet, "\\textcolor{red}{«Text»}") == "\\textcolor{violet}{«Text»}")
        #expect(color(.violet, "«\\textcolor{red}{Text}»") == "«\\textcolor{violet}{Text}»")
        #expect(color(nil, "\\textcolor{red}{Te|xt}") == "Te|xt")
        #expect(color(nil, "\\textcolor{red}{«Text»}") == "«Text»")
        #expect(color(nil, "«\\textcolor{red}{Text}»") == "«Text»")
        #expect(color(nil, "\\textcolor[rgb]{1,0,0}{x|}") == "x|")
        // Gleiche Farbe bzw. keine Farbe: nichts zu tun.
        #expect(color(.red, "\\textcolor{red}{Te|xt}") == "\\textcolor{red}{Te|xt}")
        #expect(color(nil, "Te|xt") == "Te|xt")
    }

    @Test func partOfColoredText() {
        #expect(color(nil, "\\textcolor{red}{rot «blau» rot}") == "\\textcolor{red}{rot }«blau»\\textcolor{red}{ rot}")
        #expect(color(.blue, "\\textcolor{red}{rot «blau»}") == "\\textcolor{red}{rot \\textcolor{blue}{«blau»}}")
        #expect(color(.red, "\\textcolor{red}{rot «rot»}") == "\\textcolor{red}{rot «rot»}")
        // Durch eine fremde Gruppe hindurch lässt sich nichts herauslösen: Farbe ganz entfernen.
        #expect(color(nil, "\\textcolor{red}{a \\footnote{«b»}}") == "a \\footnote{«b»}")
    }

    @Test func roundTripForEveryColor() {
        for textColor in TextColor.allCases {
            let colored = color(textColor, "ein «Wort»")
            #expect(inlineState(colored).color == textColor)
            #expect(color(nil, colored) == "ein «Wort»")
        }
    }
}

// MARK: - Absatzformat

@Suite("Überschriften-Schema")
struct HeadingSchemeTests {
    @Test func detectsDocumentClass() {
        #expect(scheme("\\documentclass{article}") == .article)
        #expect(scheme("\\documentclass[12pt,a4paper]{scrreprt}") == .book)
        #expect(scheme("\\documentclass{book}\n\\begin{document}") == .book)
        #expect(scheme("\\documentclass{report}") == .book)
        #expect(scheme("\\documentclass{scrbook}") == .book)
        #expect(scheme("\\documentclass{ memoir }") == .book)
        #expect(scheme("\\documentclass{scrartcl}") == .article)
        #expect(scheme("\\documentclass{beamer}") == .article)
        #expect(scheme("") == .article)
        #expect(scheme("Nur Text") == .article)
    }

    @Test func ignoresCommentsAndBody() {
        #expect(scheme("% \\documentclass{book}\n\\documentclass{article}") == .article)
        #expect(scheme("%\\documentclass{book}") == .article)
        #expect(scheme("\\begin{document}\n\\documentclass{book}") == .article)
        #expect(scheme("\\documentclassx{book}") == .article)
    }

    @Test func multilineOptions() {
        let text = "\\documentclass[\n  12pt, % Schrift ]\n  a4paper\n]\n  {report}\n\\begin{document}"
        #expect(scheme(text) == .book)
    }

    @Test func worksOnNSString() {
        #expect(HeadingScheme.detect(in: NSStringSource("\\documentclass{book}" as NSString)) == .book)
    }
}

@Suite("Absatz-Zustand")
struct ParagraphStateTests {
    @Test func headingStyle() {
        #expect(paragraphState("\\section{Einl|eitung}").style == .heading1)
        #expect(paragraphState("\\section{Einl|eitung}", scheme: .book).style == .heading2)
        #expect(paragraphState("\\chapter{X|}", scheme: .book).style == .heading1)
        #expect(paragraphState("\\chapter{X|}").style == .body)
        #expect(paragraphState("\\subsubsection*{X|}").style == .heading3)
        #expect(paragraphState("\\paragraph{X}|").style == .heading4)
        #expect(paragraphState("\\paragraph{X}|", scheme: .book).style == .body)
        #expect(paragraphState("\\subsubsection{X}|", scheme: .book).style == .heading4)
        #expect(paragraphState("\\part{X|}").style == .body)
        #expect(paragraphState("  \\section{Ti|tel} % Kommentar").style == .heading1)
        #expect(paragraphState("\\section[Kurz]{Ti|tel}").style == .heading1)
        #expect(paragraphState("% \\section{X|}").style == .body)
        #expect(paragraphState("\\sectionmark|").style == .body)
        #expect(paragraphState("\\section|").style == .body)
        #expect(paragraphState("Text \\section{X|}").style == .body)
        #expect(paragraphState("|") == ParagraphState())
    }

    @Test func alignmentAndList() {
        #expect(paragraphState("\\begin{center}\nTe|xt\n\\end{center}").alignment == .center)
        #expect(paragraphState("\\begin{flushleft}\nTe|xt\n\\end{flushleft}").alignment == .left)
        #expect(paragraphState("\\begin{flushright}\nTe|xt\n\\end{flushright}").alignment == .right)
        #expect(paragraphState("\\begin{center}\n\\begin{flushright}\nx|\n\\end{flushright}\n\\end{center}").alignment == .right)
        #expect(paragraphState("Te|xt").alignment == .standard)
        #expect(paragraphState("|\\begin{center}\nText\n\\end{center}").alignment == .center)
        #expect(paragraphState("\\begin{center}\nText\n\\end{center}|").alignment == .center)
        #expect(paragraphState("\\begin{itemize}\n  \\item A|\n\\end{itemize}").list == .itemize)
        #expect(paragraphState("\\begin{itemize}\n  \\begin{enumerate}\n    \\item A|\n  \\end{enumerate}\n\\end{itemize}").list == .enumerate)
        #expect(paragraphState("\\begin{itemize}\n  \\item A\n\\end{itemize}\nText|").list == nil)
        #expect(paragraphState("% \\begin{itemize}\nText|").list == nil)
    }
}

@Suite("Überschrift anwenden")
struct ApplyHeadingTests {
    @Test func bodyBecomesHeading() {
        #expect(heading(.heading1, "Einl|eitung") == "\\section{Einl|eitung}")
        #expect(heading(.heading1, "Einl|eitung", scheme: .book) == "\\chapter{Einl|eitung}")
        #expect(heading(.heading4, "Einl|eitung") == "\\paragraph{Einl|eitung}")
        #expect(heading(.heading1, "  Einleitung|") == "  \\section{Einleitung|}")
        #expect(heading(.heading1, "|Einleitung") == "\\section{|Einleitung}")
        #expect(heading(.heading2, "Hallo 😀 Wel|t") == "\\subsection{Hallo 😀 Wel|t}")
        #expect(heading(.heading1, "Erste\nZwei|te\nDritte") == "Erste\n\\section{Zwei|te}\nDritte")
    }

    @Test func headingChangesLevel() {
        #expect(heading(.heading2, "\\section{Einl|eitung}") == "\\subsection{Einl|eitung}")
        #expect(heading(.heading3, "\\section*{Einleitung}\\label{sec:ein}|") == "\\subsubsection*{Einleitung}\\label{sec:ein}|")
        #expect(heading(.heading2, "\\section[Kurz]{Lang|er Titel}") == "\\subsection[Kurz]{Lang|er Titel}")
        #expect(heading(.heading1, "\\subsection{X|}", scheme: .book) == "\\chapter{X|}")
        #expect(heading(.heading1, "\\part{Te|il}") == "\\section{Te|il}")
        #expect(heading(.heading1, "\\sec|tion{X}") == "\\sec|tion{X}")
        #expect(heading(.heading2, "\\sec|tion{X}") == "\\subsection|{X}")
    }

    @Test func headingBecomesBody() {
        #expect(heading(.body, "\\section{Einl|eitung}\\label{sec:ein}") == "Einl|eitung\\label{sec:ein}")
        #expect(heading(.body, "  \\section*{Ti|tel} % Notiz") == "  Ti|tel % Notiz")
        #expect(heading(.body, "\\section[Kurz]{Lang|er Titel}") == "Lang|er Titel")
        #expect(heading(.body, "\\sec|tion{Titel}") == "|Titel")
        #expect(heading(.body, "\\section{Titel}|") == "Titel|")
        #expect(heading(.body, "\\section{\\LaTeX}ist|") == "\\LaTeX{}ist|")
        // \part gehört nicht zum Schema: bleibt.
        #expect(heading(.body, "\\part{Te|il}") == "\\part{Te|il}")
    }

    @Test func roundTrip() {
        for style in [ParagraphStyle.heading1, .heading2, .heading3, .heading4] {
            for headingScheme in [HeadingScheme.article, .book] {
                let applied = heading(style, "Ein «Titel»", scheme: headingScheme)
                #expect(applied == "\\\(headingScheme.command(for: style)!){Ein «Titel»}")
                #expect(paragraphState(applied, scheme: headingScheme).style == style)
                #expect(heading(.body, applied, scheme: headingScheme) == "Ein «Titel»")
            }
        }
    }

    @Test func emptyLineGetsEmptyHeading() {
        #expect(heading(.heading1, "|") == "\\section{|}")
        #expect(heading(.heading2, "  |") == "  \\subsection{|}")
        #expect(heading(.heading1, "Text\n|\nMehr") == "Text\n\\section{|}\nMehr")
        #expect(heading(.body, "|") == "|")
    }

    @Test func sameStyleChangesNothing() {
        let edit = ParagraphFormatter.apply(.heading1, in: Array("\\section{A}".utf16), selection: 3..<3, scheme: .article)
        #expect(!edit.changesText)
        #expect(edit.selectionAfter == 3..<3)
        #expect(heading(.body, "Te|xt") == "Te|xt")
    }

    @Test func severalLines() {
        #expect(heading(.heading2, "«Eins\nZwei»") == "\\subsection{«Eins}\n\\subsection{Zwei»}")
        #expect(heading(.heading2, "«\\section{A}\nB\n\nC»") == "«\\subsection{A}\n\\subsection{B}\n\n\\subsection{C»}")
        #expect(heading(.body, "«\\section{A}\nB»") == "«A\nB»")
        // Endet die Auswahl am Zeilenanfang, gehört diese Zeile nicht dazu.
        #expect(heading(.heading1, "«Eins\n»Zwei") == "\\section{«Eins}\n»Zwei")
    }

    @Test func commentsAndStructureStayIntact() {
        #expect(heading(.heading1, "Einleitung % TODO|") == "\\section{Einleitung} % TODO|")
        #expect(heading(.heading1, "% Notiz|") == "% Notiz|")
        #expect(heading(.heading1, "\\begin{itemize}|") == "\\begin{itemize}|")
        #expect(heading(.heading1, "\\item Pun|kt") == "\\item Pun|kt")
        // Nicht geschlossene Klammer: lieber nichts tun als kaputt machen.
        #expect(heading(.heading1, "Text \\textbf{fett|") == "Text \\textbf{fett|")
        #expect(heading(.heading1, "«Eins\n\\begin{center}»") == "\\section{«Eins}\n\\begin{center}»")
    }

    @Test func multilineTitles() {
        #expect(heading(.body, "\\section{Ein\nTi|tel}") == "Ein\nTi|tel")
        #expect(heading(.heading2, "\\section{Ein\nTi|tel}") == "\\subsection{Ein\nTi|tel}")
        // Auswahl berührt nur die erste Zeile: die ganze Überschrift wird bearbeitet.
        #expect(heading(.body, "\\section{E|in\nTitel}\nText") == "E|in\nTitel\nText")
        // Zweite Zeile allein ist keine Überschrift und wird nicht verändert.
        #expect(heading(.heading1, "\\section{Ein\nTi|tel}") == "\\section{Ein\nTi|tel}")
    }
}

@Suite("Ausrichtung")
struct AlignmentTests {
    @Test func wrapsParagraph() {
        #expect(align(.center, "Te|xt") == "\\begin{center}\n  Te|xt\n\\end{center}")
        #expect(align(.left, "Te|xt") == "\\begin{flushleft}\n  Te|xt\n\\end{flushleft}")
        #expect(align(.right, "Te|xt") == "\\begin{flushright}\n  Te|xt\n\\end{flushright}")
        #expect(align(.center, "Absatz eins\nzwei|\n\nAnderer") == "\\begin{center}\n  Absatz eins\n  zwei|\n\\end{center}\n\nAnderer")
        #expect(align(.center, "  Text|") == "  \\begin{center}\n    Text|\n  \\end{center}")
        #expect(align(.center, "Äpfel 😀 und Bir|nen") == "\\begin{center}\n  Äpfel 😀 und Bir|nen\n\\end{center}")
    }

    @Test func wrapsSelectedLines() {
        #expect(align(.center, "Eins\n«Zwei\nDrei»\nVier") == "Eins\n\\begin{center}\n  «Zwei\n  Drei»\n\\end{center}\nVier")
        #expect(align(.center, "Ei«ns\n\nZw»ei") == "\\begin{center}\n  Ei«ns\n\n  Zw»ei\n\\end{center}")
    }

    @Test func changesOrRemovesExistingAlignment() {
        let centered = "\\begin{center}\n  Te|xt\n\\end{center}"
        #expect(align(.right, centered) == "\\begin{flushright}\n  Te|xt\n\\end{flushright}")
        #expect(align(.standard, centered) == "Te|xt")
        #expect(align(.center, centered) == centered)
        #expect(align(.standard, "\\begin{center}|\n  Text\n\\end{center}") == "|Text")
        #expect(align(.standard, "\\begin{flushright}\n  Zeile 1\n    eingerückt|\n\\end{flushright}\nDanach")
            == "Zeile 1\n  eingerückt|\nDanach")
        #expect(align(.standard, "a\n\\begin{center}|\n\\end{center}\nb") == "a\n|b")
        #expect(align(.left, "\\begin{center}Te|xt\\end{center}") == "\\begin{flushleft}Te|xt\\end{flushleft}")
        #expect(align(.standard, "\\begin{center}Te|xt\\end{center}") == "Te|xt")
        // Mit Auswahl innerhalb der Umgebung.
        #expect(align(.standard, "\\begin{center}\n  «Zeile»\n\\end{center}") == "«Zeile»")
    }

    @Test func roundTrip() {
        let original = "Vorher\n\nEin Absatz\nmit zwei Zei|len\n\nNachher"
        let centered = align(.center, original)
        #expect(centered == "Vorher\n\n\\begin{center}\n  Ein Absatz\n  mit zwei Zei|len\n\\end{center}\n\nNachher")
        #expect(paragraphState(centered).alignment == .center)
        #expect(align(.standard, centered) == original)
    }

    @Test func standardOutsideChangesNothing() {
        let units = Array("Text".utf16)
        let edit = ParagraphFormatter.align(.standard, in: units, selection: 1..<3)
        #expect(edit == TextEdit(range: 1..<1, replacement: "", selectionAfter: 1..<3))
    }

    @Test func emptyLineGetsEmptyEnvironment() {
        #expect(align(.center, "Text\n\n|\n\nMehr") == "Text\n\n\\begin{center}\n  |\n\\end{center}\n\nMehr")
        #expect(align(.center, "|") == "\\begin{center}\n  |\n\\end{center}")
    }

    @Test func respectsStructure() {
        // Überschrift gehört nicht zum Absatz.
        #expect(align(.center, "\\section{Titel}\nText|") == "\\section{Titel}\n\\begin{center}\n  Text|\n\\end{center}")
        // Nie das ganze Dokument einpacken.
        #expect(align(.center, "\\begin{document}\nText|\n\\end{document}")
            == "\\begin{document}\n\\begin{center}\n  Text|\n\\end{center}\n\\end{document}")
        #expect(align(.center, "\\begin{document}|\nText\n\\end{document}") == "\\begin{document}|\nText\n\\end{document}")
        // In einer Tabelle: die ganze Tabelle ausrichten.
        #expect(align(.center, "\\begin{tabular}{cc}\n  a & b|\n\\end{tabular}")
            == "\\begin{center}\n  \\begin{tabular}{cc}\n    a & b|\n  \\end{tabular}\n\\end{center}")
        // In einer Formel: die ganze Formel.
        #expect(align(.right, "\\begin{equation}\n  x = 1|\n\\end{equation}")
            == "\\begin{flushright}\n  \\begin{equation}\n    x = 1|\n  \\end{equation}\n\\end{flushright}")
        // Auswahl schneidet eine Umgebung an: die ganze Umgebung kommt dazu.
        #expect(align(.center, "«Text\n\\begin{itemize}\n  \\item A»\n\\end{itemize}")
            == "\\begin{center}\n  «Text\n  \\begin{itemize}\n    \\item A»\n  \\end{itemize}\n\\end{center}")
        // Auf der \begin-Zeile einer Liste: die ganze Liste.
        #expect(align(.center, "\\begin{itemize}|\n  \\item A\n\\end{itemize}")
            == "\\begin{center}\n  \\begin{itemize}|\n    \\item A\n  \\end{itemize}\n\\end{center}")
        // Im Listenpunkt: nur der Text des Punktes ab der Fortsetzungszeile.
        #expect(align(.center, "\\begin{itemize}\n  \\item A\n  wei|ter\n\\end{itemize}")
            == "\\begin{itemize}\n  \\item A\n  \\begin{center}\n    wei|ter\n  \\end{center}\n\\end{itemize}")
    }
}

@Suite("Listen")
struct ListTests {
    @Test func linesBecomeItems() {
        #expect(list(.itemize, "Eins|") == "\\begin{itemize}\n  \\item Eins|\n\\end{itemize}")
        #expect(list(.enumerate, "|Eins") == "\\begin{enumerate}\n  \\item |Eins\n\\end{enumerate}")
        #expect(list(.itemize, "«Eins\nZwei»") == "\\begin{itemize}\n  \\item «Eins\n  \\item Zwei»\n\\end{itemize}")
        #expect(list(.itemize, "«\\item Eins\n\nZwei»") == "\\begin{itemize}\n  «\\item Eins\n\n  \\item Zwei»\n\\end{itemize}")
        #expect(list(.itemize, "  «Eins\n    Zwei»") == "  \\begin{itemize}\n    \\item «Eins\n      \\item Zwei»\n  \\end{itemize}")
        #expect(list(.itemize, "«Äpfel 🍎\nBirnen»") == "\\begin{itemize}\n  \\item «Äpfel 🍎\n  \\item Birnen»\n\\end{itemize}")
        #expect(list(.itemize, "«Eins\n% Notiz\nZwei»") == "\\begin{itemize}\n  \\item «Eins\n  % Notiz\n  \\item Zwei»\n\\end{itemize}")
        // Nur die Cursorzeile, nicht der ganze Absatz.
        #expect(list(.itemize, "Eins\nZw|ei\nDrei") == "Eins\n\\begin{itemize}\n  \\item Zw|ei\n\\end{itemize}\nDrei")
    }

    @Test func emptyLineGetsEmptyList() {
        #expect(list(.itemize, "|") == "\\begin{itemize}\n  \\item |\n\\end{itemize}")
        #expect(list(.enumerate, "  |") == "  \\begin{enumerate}\n    \\item |\n  \\end{enumerate}")
        #expect(list(.itemize, "Text\n|\nMehr") == "Text\n\\begin{itemize}\n  \\item |\n\\end{itemize}\nMehr")
    }

    @Test func dissolvesListOfSameKind() {
        #expect(list(.itemize, "\\begin{itemize}\n  \\item Ei|ns\n  \\item Zwei\n\\end{itemize}") == "Ei|ns\nZwei")
        #expect(list(.enumerate, "\\begin{enumerate}\n  \\item[a)] Ers|tens\n\\end{enumerate}") == "Ers|tens")
        #expect(list(.enumerate, "\\begin{enumerate}[label=(\\alph*)]\n  \\item A|\n\\end{enumerate}") == "A|")
        #expect(list(.itemize, "\\begin{itemize}\n  \\item\n  Text|\n\\end{itemize}") == "Text|")
        #expect(list(.itemize, "\\begin{itemize}\n  \\item A\n\\end{itemize}|") == "A|")
        #expect(list(.itemize, "|\\begin{itemize}\n  \\item A\n\\end{itemize}") == "|A")
        #expect(list(.itemize, "\\begin{itemize}\\item A|\\end{itemize}") == "A|")
        #expect(list(.itemize, "Vorher\n\\begin{itemize}\n  \\item |\n\\end{itemize}\nNachher") == "Vorher\n|Nachher")
    }

    @Test func dissolvingKeepsNestedLists() {
        #expect(list(.itemize, "\\begin{itemize}\n  \\item A|\n  \\begin{enumerate}\n    \\item B\n  \\end{enumerate}\n\\end{itemize}")
            == "A|\n\\begin{enumerate}\n  \\item B\n\\end{enumerate}")
        #expect(list(.enumerate, "\\begin{itemize}\n  \\item A\n  \\begin{enumerate}\n    \\item B|\n  \\end{enumerate}\n\\end{itemize}")
            == "\\begin{itemize}\n  \\item A\n  B|\n\\end{itemize}")
    }

    @Test func switchesKind() {
        #expect(list(.enumerate, "\\begin{itemize}\n  \\item Ei|ns\n  \\item Zwei\n\\end{itemize}")
            == "\\begin{enumerate}\n  \\item Ei|ns\n  \\item Zwei\n\\end{enumerate}")
        #expect(list(.itemize, "\\begin{enumerate}\n  \\item «Eins»\n\\end{enumerate}")
            == "\\begin{itemize}\n  \\item «Eins»\n\\end{itemize}")
    }

    @Test func roundTrip() {
        let original = "Vorher\n«Eins\nZwei\nDrei»\nNachher"
        let listed = list(.enumerate, original)
        #expect(listed == "Vorher\n\\begin{enumerate}\n  \\item «Eins\n  \\item Zwei\n  \\item Drei»\n\\end{enumerate}\nNachher")
        #expect(paragraphState(listed).list == .enumerate)
        #expect(list(.enumerate, listed) == original)
    }

    @Test func environmentsInsideBecomeOneItem() {
        #expect(list(.itemize, "«Text\n\\begin{equation}\n  x = 1\n\\end{equation}»")
            == "\\begin{itemize}\n  \\item «Text\n  \\item \\begin{equation}\n    x = 1\n  \\end{equation}»\n\\end{itemize}")
        // Auswahl schneidet die Formel an: die ganze Formel kommt dazu.
        #expect(list(.itemize, "«Text\n\\begin{equation}»\n  x = 1\n\\end{equation}")
            == "\\begin{itemize}\n  \\item «Text\n  \\item \\begin{equation}»\n    x = 1\n  \\end{equation}\n\\end{itemize}")
    }

    @Test func neverWrapsDocument() {
        #expect(list(.itemize, "\\begin{document}|") == "\\begin{document}|")
        #expect(list(.itemize, "\\begin{document}\nA|\n\\end{document}") == "\\begin{document}\n\\begin{itemize}\n  \\item A|\n\\end{itemize}\n\\end{document}")
    }
}

// MARK: - Schutz vor kaputtem LaTeX

@Suite("Formatierung zerstört keine Struktur")
struct FormattingSafetyTests {
    @Test func noFormattingInsideKeyArguments() {
        #expect(toggle(.bold, "\\label{sec:ei|n}") == "\\textbf{|}\\label{sec:ein}")
        #expect(toggle(.bold, "\\begin{cen|ter}") == "\\textbf{|}\\begin{center}")
        #expect(toggle(.bold, "\\begin{tabular}{c|c}") == "\\textbf{|}\\begin{tabular}{cc}")
        #expect(toggle(.bold, "\\textcolor{re|d}{x}") == "\\textbf{|}\\textcolor{red}{x}")
        #expect(toggle(.italic, "\\includegraphics[width=5cm]{bi|ld}") == "\\textit{|}\\includegraphics[width=5cm]{bild}")
        #expect(size(.large, "Siehe \\ref{fi|g}") == "Siehe {\\large |}\\ref{fig}")
        #expect(color(.red, "\\cite{kn|uth}") == "\\textcolor{red}{|}\\cite{knuth}")
        #expect(toggle(.bold, "\\label{«sec»}") == "\\label{«sec»}")
        #expect(color(.blue, "\\textcolor{«red»}{x}") == "\\textcolor{«red»}{x}")
        // Text-Argumente dürfen formatiert werden.
        #expect(toggle(.bold, "\\section{Ti|tel}") == "\\section{\\textbf{Ti|tel}}")
        #expect(toggle(.bold, "\\href{https://x.ch}{Te|xt}") == "\\href{https://x.ch}{\\textbf{Te|xt}}")
        #expect(toggle(.bold, "\\footnote{«Hinweis»}") == "\\footnote{\\textbf{«Hinweis»}}")
    }

    @Test func selectionsAreCompletedToWholeCommands() {
        #expect(toggle(.bold, "«Hallo \\textit{We»lt}") == "\\textbf{«Hallo \\textit{Welt}»}")
        #expect(toggle(.bold, "«Siehe \\ref{fi»g}") == "\\textbf{«Siehe \\ref{fig}»}")
        #expect(toggle(.bold, "\\frac{«a»}{b}") == "\\frac{\\textbf{«a»}}{b}")
        #expect(toggle(.bold, "«\\frac{a}»{b}") == "\\textbf{«\\frac{a}{b}»}")
        #expect(toggle(.bold, "\\frac{a}«{b}»") == "\\textbf{«\\frac{a}{b}»}")
        #expect(toggle(.bold, "«\\textbf»{x}") == "«x»")
        #expect(color(nil, "«\\textcolor{red}»{x}") == "«x»")
    }

    @Test func selectionsAcrossStructureAreLeftAlone() {
        #expect(toggle(.bold, "«Text\n\\begin{itemize}»") == "«Text\n\\begin{itemize}»")
        #expect(toggle(.bold, "«\\begin{cen»ter}") == "«\\begin{cen»ter}")
        #expect(toggle(.bold, "«a $x» + y$") == "«a $x» + y$")
        #expect(toggle(.bold, "«a \\(x» + y\\)") == "«a \\(x» + y\\)")
        #expect(toggle(.bold, "«a \\[x» \\]") == "«a \\[x» \\]")
        #expect(size(.large, "«a $x» + y$") == "«a $x» + y$")
        // Ganze Formeln und Umgebungen sind kein Problem.
        #expect(toggle(.bold, "«$x$ und \\$ $y$»") == "\\textbf{«$x$ und \\$ $y$»}")
        #expect(toggle(.bold, "«\\begin{center}x\\end{center}»") == "\\textbf{«\\begin{center}x\\end{center}»}")
        #expect(toggle(.bold, "«a\\\\[2mm] b»") == "\\textbf{«a\\\\[2mm] b»}")
    }

    @Test func paragraphFormattingSkipsPreamble() {
        let document = "\\documentclass{article}\nTi|tel\n\\begin{document}\nText\n\\end{document}"
        #expect(heading(.heading1, document) == document)
        #expect(align(.center, document) == document)
        #expect(list(.itemize, document) == document)
        // Im Dokument selbst geht es.
        #expect(heading(.heading1, "\\documentclass{article}\n\\begin{document}\nTi|tel\n\\end{document}")
            == "\\documentclass{article}\n\\begin{document}\n\\section{Ti|tel}\n\\end{document}")
    }

    @Test func noHeadingsInFormulasAndTables() {
        #expect(heading(.heading1, "\\[\n  x = |1\n\\]") == "\\[\n  x = |1\n\\]")
        #expect(heading(.heading1, "\\[|\n  x = 1\n\\]") == "\\[|\n  x = 1\n\\]")
        #expect(heading(.heading1, "\\begin{equation}\n  x|\n\\end{equation}") == "\\begin{equation}\n  x|\n\\end{equation}")
        #expect(heading(.heading1, "\\begin{tabular}{cc}\n  a & b|\n\\end{tabular}") == "\\begin{tabular}{cc}\n  a & b|\n\\end{tabular}")
        #expect(heading(.heading1, "«Text\n\\[\nx\n\\]»") == "\\section{«Text}\n\\[\nx\n\\]»")
        #expect(heading(.heading1, "\\section*|\n{Titel}") == "\\section*|\n{Titel}")
        #expect(heading(.heading1, "Es gilt $x$|") == "\\section{Es gilt $x$|}")
    }

    @Test func verbatimContentStaysUntouched() {
        // Befehle in wörtlichen Umgebungen wären nur Text.
        let code = "\\begin{verbatim}\nWo|rt\n\\end{verbatim}"
        #expect(toggle(.bold, code) == code)
        #expect(size(.large, code) == code)
        #expect(color(.red, code) == code)
        // Beim Einpacken und Auflösen wird wörtlicher Inhalt nicht ein- oder ausgerückt.
        #expect(align(.center, "«Text\n\\begin{verbatim}\n  code\n\\end{verbatim}»")
            == "\\begin{center}\n  «Text\n  \\begin{verbatim}\n  code\n\\end{verbatim}»\n\\end{center}")
        #expect(list(.itemize, "«Text\n\\begin{lstlisting}\nx = 1\n\\end{lstlisting}»")
            == "\\begin{itemize}\n  \\item «Text\n  \\item \\begin{lstlisting}\nx = 1\n\\end{lstlisting}»\n\\end{itemize}")
        #expect(list(.itemize, "\\begin{itemize}\n  \\item A|\n  \\begin{verbatim}\n  \\item x\n\\end{verbatim}\n\\end{itemize}")
            == "A|\n\\begin{verbatim}\n  \\item x\n\\end{verbatim}")
        #expect(align(.standard, "\\begin{center}\n  Te|xt\n  \\begin{verbatim}\n    code\n\\end{verbatim}\n\\end{center}")
            == "Te|xt\n\\begin{verbatim}\n    code\n\\end{verbatim}")
    }

    @Test func colorNameUnderCursor() {
        #expect(color(.blue, "\\textcolor{re|d}{x}") == "\\textcolor{blue|}{x}")
        #expect(color(nil, "\\textcolor{re|d}{x}") == "|x")
    }

    @Test func noEmptyHeadingInsideFormulas() {
        #expect(heading(.heading1, "\\begin{equation}\n|\n\\end{equation}") == "\\begin{equation}\n|\n\\end{equation}")
        #expect(heading(.heading1, "\\begin{tabular}{c}\n|\n\\end{tabular}") == "\\begin{tabular}{c}\n|\n\\end{tabular}")
    }

    @Test func alignAndListTakeWholeFormulasAndTables() {
        #expect(align(.center, "\\begin{tabular}{cc}\n  «a & b \\\\»\n\\end{tabular}")
            == "\\begin{center}\n  \\begin{tabular}{cc}\n    «a & b \\\\»\n  \\end{tabular}\n\\end{center}")
        #expect(align(.center, "\\[\n  \\begin{aligned}\n    x|\n  \\end{aligned}\n\\]")
            == "\\begin{center}\n  \\[\n    \\begin{aligned}\n      x|\n    \\end{aligned}\n  \\]\n\\end{center}")
        #expect(list(.itemize, "\\begin{equation}\n  x|\n\\end{equation}")
            == "\\begin{itemize}\n  \\item \\begin{equation}\n    x|\n  \\end{equation}\n\\end{itemize}")
        #expect(list(.itemize, "\\[\n  x|\n\\]") == "\\begin{itemize}\n  \\item \\[\n    x|\n  \\]\n\\end{itemize}")
    }
}

// MARK: - Robustheit

/// Kleiner Zufallsgenerator mit festem Startwert, damit die Tests reproduzierbar bleiben.
private struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

/// Gehen alle geschweiften Klammern ausserhalb von Kommentaren auf?
private func bracesBalanced(_ text: String) -> Bool {
    let units = Array(text.utf16)
    return FormattingText.isBalanced(units, 0..<units.count)
}

/// Gleich viele `\begin{` wie `\end{` ausserhalb von Kommentaren?
private func environmentsBalanced(_ text: String) -> Bool {
    var begins = 0
    var ends = 0
    for line in text.components(separatedBy: "\n") {
        let units = Array(line.utf16)
        let code = units.commentStart(inLineStartingAt: 0).map { units.string(in: 0..<$0) } ?? line
        begins += code.components(separatedBy: "\\begin{").count - 1
        ends += code.components(separatedBy: "\\end{").count - 1
    }
    return begins == ends
}

@Suite("Robustheit")
struct FormattingRobustnessTests {
    static let sample = """
    \\documentclass{article}
    \\usepackage{xcolor}
    \\begin{document}
    \\section*{Einführung}\\label{sec:ein}
    Hallo \\textbf{fette \\textit{Wörter}} und {\\large grosse 😀 Schrift}.
    % Kommentar mit \\textbf{ und {
    \\textcolor{red}{Rot} \\% kein Kommentar \\{ x \\} \\LaTeX\\textbf{ist}
    \\begin{center}
      Zentriert $a^{2}$ \\textcolor{green!50!black}{grün}
    \\end{center}

    \\begin{itemize}
      \\item Erster Punkt
      \\item[b)] Zweiter
      \\begin{enumerate}
        \\item Innen
      \\end{enumerate}
    \\end{itemize}
    \\begin{tabular}{cc}
      a & b \\\\
    \\end{tabular}
    \\subsection{Mehrzeiliger
      Titel}
    Ende
    \\end{document}
    """

    /// Jede Funktion an jeder Position: kein Absturz, gültige Bearbeitung,
    /// Klammern und Umgebungen bleiben ausgeglichen.
    @Test func everyPositionAndSelection() {
        let text = Self.sample
        let units = Array(text.utf16)
        #expect(bracesBalanced(text))
        #expect(environmentsBalanced(text))
        var generator = SeededGenerator(state: 42)
        var selections: [Range<Int>] = []
        for position in 0...units.count {
            selections.append(position..<position)
            let length = Int.random(in: 1...40, using: &generator)
            selections.append(position..<min(units.count, position + length))
        }
        for selection in selections {
            var inline: [TextEdit] = InlineStyle.allCases.map { InlineFormatter.toggle($0, in: units, selection: selection) }
            inline += [FontSize.large, .normalsize, .tiny].map { InlineFormatter.setFontSize($0, in: units, selection: selection) }
            inline += [TextColor.red, nil].map { InlineFormatter.setColor($0, in: units, selection: selection) }
            for edit in inline {
                checkValid(edit, oldLength: units.count)
                let result = applying(edit, to: text)
                #expect(bracesBalanced(result), "Klammern nach \(edit) bei \(selection)")
            }

            var paragraph: [TextEdit] = []
            for headingScheme in [HeadingScheme.article, .book] {
                paragraph += ParagraphStyle.allCases.map {
                    ParagraphFormatter.apply($0, in: units, selection: selection, scheme: headingScheme)
                }
            }
            paragraph += TextAlignment.allCases.map { ParagraphFormatter.align($0, in: units, selection: selection) }
            paragraph += ListKind.allCases.map { ParagraphFormatter.toggleList($0, in: units, selection: selection) }
            for edit in paragraph {
                checkValid(edit, oldLength: units.count)
                let result = applying(edit, to: text)
                #expect(bracesBalanced(result), "Klammern nach \(edit) bei \(selection)")
                #expect(environmentsBalanced(result), "Umgebungen nach \(edit) bei \(selection)")
            }

            _ = InlineFormatter.state(in: units, selection: selection)
            _ = ParagraphFormatter.state(in: units, selection: selection, scheme: .article)
        }
    }

    /// Auch ganz ungewöhnliche Eingaben dürfen nicht abstürzen.
    @Test func oddInputs() {
        let inputs = ["", "\\", "{", "}", "%", "\\begin{", "\\end{itemize}", "\\section{", "😀", "\n\n", "\\item", "{\\large", "\\textcolor{red}{"]
        for input in inputs {
            let units = Array(input.utf16)
            for selection in [0..<0, 0..<units.count, units.count..<units.count, -5..<100] {
                var edits: [TextEdit] = [
                    InlineFormatter.toggle(.bold, in: units, selection: selection),
                    InlineFormatter.setFontSize(.normalsize, in: units, selection: selection),
                    InlineFormatter.setFontSize(.large, in: units, selection: selection),
                    InlineFormatter.setColor(nil, in: units, selection: selection),
                    InlineFormatter.setColor(.blue, in: units, selection: selection),
                    ParagraphFormatter.align(.center, in: units, selection: selection),
                    ParagraphFormatter.align(.standard, in: units, selection: selection),
                    ParagraphFormatter.toggleList(.itemize, in: units, selection: selection)
                ]
                edits += ParagraphStyle.allCases.map {
                    ParagraphFormatter.apply($0, in: units, selection: selection, scheme: .article)
                }
                for edit in edits { checkValid(edit, oldLength: units.count) }
                _ = InlineFormatter.state(in: units, selection: selection)
                _ = ParagraphFormatter.state(in: units, selection: selection, scheme: .book)
                _ = HeadingScheme.detect(in: units)
            }
        }
    }
}
