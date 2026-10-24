import Foundation
import Testing
@testable import LaTeXKit

// MARK: - Hilfen

/// Die Präambel eines neuen Dokuments in Lemma.
private let starter = """
\\documentclass[a4paper,11pt]{article}
\\usepackage[ngerman]{babel}
\\usepackage{amsmath,amssymb,amsthm}

\\begin{document}

\\section{Erster Abschnitt}
Hier beginnt dein Text. Eine Formel im Fliesstext: $a^2 + b^2 = c^2$.

\\end{document}

"""

/// Eine typische, von Hand geschriebene Präambel aus einer Vorlage.
private let handWritten = """
% !TEX program = pdflatex
\\documentclass[12pt, a4paper]{scrartcl}   % KOMA-Script
\\usepackage[utf8]{inputenc}
\\usepackage[T1]{fontenc}
\\usepackage[ngerman]{babel}
\\usepackage{amsmath, amssymb}
\\usepackage{graphicx}
% \\usepackage{newtxtext} (ausprobiert, gefällt mir nicht)
\\usepackage{hyperref}

\\title{Übungsblatt 3 – Größen und Maße}
\\author{Jörg Müller}
\\newcommand{\\R}{\\mathbb{R}}

\\begin{document}
\\maketitle
Äpfel und Öl. \\usepackage{nichtinderpraeambel}
\\end{document}
"""

private func parse(_ text: String) -> [UInt16] { Array(text.utf16) }

/// Führt eine Bearbeitung aus und prüft dabei, dass sie gültig ist.
private func applying(_ edit: TextEdit, to text: String, sourceLocation: SourceLocation = #_sourceLocation) -> String {
    let old = text.utf16.count
    #expect(edit.range.lowerBound >= 0 && edit.range.upperBound <= old, "Bereich ausserhalb des Textes", sourceLocation: sourceLocation)
    let result = (text as NSString).replacingCharacters(
        in: NSRange(location: edit.range.lowerBound, length: edit.range.count),
        with: edit.replacement
    )
    let new = result.utf16.count
    #expect(new == old + edit.lengthDelta, sourceLocation: sourceLocation)
    #expect(edit.selectionAfter.lowerBound >= 0, sourceLocation: sourceLocation)
    #expect(edit.selectionAfter.upperBound <= new, "Auswahl ausserhalb des neuen Textes", sourceLocation: sourceLocation)
    #expect(edit.selectionAfter == (edit.range.lowerBound + edit.replacement.utf16.count)..<(edit.range.lowerBound + edit.replacement.utf16.count),
            sourceLocation: sourceLocation)
    return result
}

/// Schreibt Einstellungen; `nil`, wenn sich nichts ändert.
private func applied(_ settings: DocumentSettings, to text: String, sourceLocation: SourceLocation = #_sourceLocation) -> String? {
    guard let edit = PreambleEditor.apply(settings, in: parse(text)) else { return nil }
    return applying(edit, to: text, sourceLocation: sourceLocation)
}

/// Ergänzt Pakete; `nil`, wenn nichts fehlt.
private func ensured(_ requirements: [PackageRequirement], in text: String, sourceLocation: SourceLocation = #_sourceLocation) -> String? {
    guard let edit = PreambleEditor.ensure(requirements, in: parse(text)) else { return nil }
    return applying(edit, to: text, sourceLocation: sourceLocation)
}

private func settings(_ text: String) -> DocumentSettings {
    PreambleEditor.settings(in: parse(text))
}

/// Alles ab `\begin{document}` – darf sich durch Präambel-Änderungen nie ändern.
private func body(_ text: String) -> Substring {
    guard let range = text.range(of: "\\begin{document}") else { return Substring(text) }
    return text[range.lowerBound...]
}

private func lines(_ text: String) -> [String] {
    text.components(separatedBy: "\n")
}

/// Index der ersten Zeile, die `fragment` enthält.
private func lineIndex(of fragment: String, in text: String) -> Int? {
    lines(text).firstIndex { $0.contains(fragment) }
}

// MARK: - Schriften

@Suite("Präambel: Schriften")
struct DocumentFontTests {
    @Test func metadataForTheMenu() {
        #expect(Set(DocumentFont.allCases.map(\.title)).count == DocumentFont.allCases.count)
        for font in DocumentFont.allCases {
            #expect(!font.title.isEmpty)
            #expect(!font.subtitle.isEmpty)
            #expect(!font.previewFontName.isEmpty)
            // Schweizer Rechtschreibung.
            #expect(!(font.title + font.subtitle).contains("\u{00DF}"), "\(font)")
        }
        #expect(DocumentFont.times.title == "Times")
        #expect(DocumentFont.helvetica.previewFontName == "Helvetica")
    }

    /// Die Zeilen sind genau die, die mit pdfLaTeX und XeLaTeX getestet wurden.
    @Test func preambleLinesAreTheTestedOnes() {
        #expect(DocumentFont.times.preambleLines == ["\\usepackage[T1]{fontenc}", "\\usepackage{newtxtext,newtxmath}"])
        #expect(DocumentFont.charter.preambleLines == ["\\usepackage{XCharter}", "\\usepackage[xcharter,noOT1]{newtxmath}"])
        #expect(DocumentFont.latinModern.preambleLines == [
            "\\usepackage{iftex}",
            "\\ifPDFTeX\\usepackage[T1]{fontenc}\\else\\usepackage{fontspec}\\fi",
            "\\usepackage{lmodern}"
        ])
        #expect(DocumentFont.palatino.preambleLines.last == "\\usepackage{newpxtext,newpxmath}")
        #expect(DocumentFont.libertinus.preambleLines.contains("\\usepackage{libertinus}"))
        #expect(DocumentFont.helvetica.preambleLines.last == "\\renewcommand{\\familydefault}{\\sfdefault}")
    }

    @Test func preambleLinesAreWellFormed() {
        for font in DocumentFont.allCases {
            let lines = font.preambleLines
            #expect(!lines.isEmpty, "\(font)")
            let joined = lines.joined(separator: "\n")
            #expect(joined.filter { $0 == "{" }.count == joined.filter { $0 == "}" }.count, "\(font)")
            #expect(joined.filter { $0 == "[" }.count == joined.filter { $0 == "]" }.count, "\(font)")
            // \ifPDFTeX braucht iftex; jedes \if… hat sein \fi.
            if joined.contains("\\ifPDFTeX") {
                #expect(lines.first == "\\usepackage{iftex}", "\(font)")
                #expect(joined.components(separatedBy: "\\ifPDFTeX").count == joined.components(separatedBy: "\\fi").count, "\(font)")
            }
            // Keine Systemschriften über ihren Namen: Tectonic findet nur Dateien.
            #expect(!joined.contains("\\setmainfont{TeX Gyre"), "\(font)")
            #expect(!joined.contains("%"), "Kommentare setzt der Editor selbst: \(font)")
        }
    }
}

// MARK: - Präambel finden und Pakete erkennen

@Suite("Präambel: Lesen")
struct PreambleReadingTests {
    @Test func preambleEnd() {
        let text = "\\documentclass{article}\n% \\begin{document} nur ein Kommentar\n\\begin{document}\nx\n\\end{document}"
        let expected = (text as NSString).range(of: "\\begin{document}\nx").location
        #expect(PreambleEditor.preambleEnd(in: parse(text)) == expected)
        #expect(PreambleEditor.preambleEnd(in: parse("\\documentclass{article}\n\\begin {document}")) == 24)
        #expect(PreambleEditor.preambleEnd(in: parse("\\documentclass{article}\nText")) == nil)
        #expect(PreambleEditor.preambleEnd(in: parse("\\begin{documents}")) == nil)
        #expect(PreambleEditor.preambleEnd(in: parse("100\\% sicher\n\\begin{document}")) == 13)
        #expect(PreambleEditor.preambleEnd(in: parse("")) == nil)
        // Umlaute davor: UTF-16-Positionen.
        let umlauts = "% Präambel für Übungen 😀\n\\begin{document}"
        #expect(PreambleEditor.preambleEnd(in: parse(umlauts)) == ("% Präambel für Übungen 😀\n" as NSString).length)
    }

    @Test func isLoaded() {
        let text = """
        \\documentclass{article}
        \\usepackage[ngerman]{babel}
        \\usepackage{amsmath, amssymb,
          amsthm} % Mathe
        \\RequirePackage{xcolor}
        % \\usepackage{graphicx}
        \\usepackage[margin=2cm]{geometry}[2020/01/01]
        \\begin{document}
        \\usepackage{booktabs}
        \\end{document}
        """
        let units = parse(text)
        for name in ["babel", "amsmath", "amssymb", "amsthm", "xcolor", "geometry"] {
            #expect(PreambleEditor.isLoaded(package: name, in: units), "\(name)")
        }
        for name in ["graphicx", "booktabs", "ngerman", "amsmat", "margin=2cm"] {
            #expect(!PreambleEditor.isLoaded(package: name, in: units), "\(name)")
        }
        // Ohne \begin{document} gilt der ganze Text als Präambel.
        #expect(PreambleEditor.isLoaded(package: "xcolor", in: parse("\\documentclass{article}\n\\usepackage{xcolor}")))
        #expect(!PreambleEditor.isLoaded(package: "xcolor", in: parse("")))
    }

    @Test func starterSettings() {
        #expect(settings(starter) == DocumentSettings(
            documentClass: "article", baseFontSize: 11, paperSize: .a4paper,
            font: .latinModern, margins: .standard, lineSpacing: .single
        ))
        #expect(settings("Nur Text") == DocumentSettings())
        #expect(settings("\\documentclass{book}\n\\begin{document}\n\\end{document}") == DocumentSettings(documentClass: "book"))
    }

    @Test func handWrittenPreamble() {
        let read = settings(handWritten)
        #expect(read.documentClass == "scrartcl")
        #expect(read.baseFontSize == 12)
        #expect(read.paperSize == .a4paper)
        #expect(read.font == .latinModern)   // newtxtext steht nur im Kommentar
        #expect(read.margins == .standard)
        #expect(read.lineSpacing == .single)
    }

    @Test(arguments: [
        ("\\usepackage{newtxtext,newtxmath}", DocumentFont.times),
        ("\\usepackage{mathptmx}", .times),
        ("\\usepackage{newtxmath}\n\\usepackage{newtxtext}", .times),
        ("\\usepackage{mathpazo}", .palatino),
        ("\\usepackage{newpxtext}\n\\usepackage{newpxmath}", .palatino),
        ("\\usepackage{XCharter}", .charter),
        ("\\usepackage[charter]{mathdesign}", .charter),
        ("\\usepackage{XCharter}\n\\usepackage[xcharter]{newtxmath}", .charter),
        ("\\usepackage{libertinus}", .libertinus),
        ("\\usepackage[scaled]{helvet}\n\\renewcommand{\\familydefault}{\\sfdefault}", .helvetica),
        ("\\usepackage{helvet}\n\\renewcommand*\\familydefault\\sfdefault", .helvetica),
        ("\\usepackage{helvet}", .latinModern),                 // nur die serifenlose Nebenschrift
        ("\\usepackage{lmodern}", .latinModern),
        ("\\usepackage{kpfonts}", .latinModern),                // unbekannt: Standard
        ("\\usepackage{fontspec}\n\\setmainfont{TeX Gyre Termes}", .times),
        ("\\usepackage{fontspec}\n\\setmainfont{Palatino Linotype}[Ligatures=TeX]", .palatino),
        ("\\usepackage{fontspec}\n\\setmainfont[Scale=1]{texgyreheros-regular.otf}", .helvetica),
        ("% \\usepackage{mathptmx}\n\\usepackage{amsmath}", .latinModern),
        ("\\usepackage{mathptmx}\n\\usepackage{mathpazo}", .palatino),   // die letzte zählt
        ("\\usepackage{amsmath,newtxtext}", .times)
    ])
    func recognisesHandWrittenFonts(lines: String, expected: DocumentFont) {
        let text = "\\documentclass{article}\n\(lines)\n\\begin{document}\n\\end{document}\n"
        #expect(settings(text).font == expected)
    }

    @Test(arguments: [
        ("\\usepackage[margin=2cm]{geometry}", PageMargins.narrow),
        ("\\usepackage[a4paper, margin = 2.5cm]{geometry}", .normal),
        ("\\usepackage[margin=25mm]{geometry}", .normal),
        ("\\usepackage[left=3.5cm,right=3.5cm,top=3.5cm,bottom=3.5cm]{geometry}", .wide),
        ("\\usepackage[hmargin=2cm,vmargin=2cm]{geometry}", .narrow),
        ("\\usepackage{geometry}\n\\geometry{margin=2cm}", .narrow),
        ("\\usepackage[margin=2cm]{geometry}\n\\geometry{margin=3.5cm}", .wide),
        ("\\usepackage[margin=3cm]{geometry}", .standard),
        ("\\usepackage[left=2cm,right=3cm,top=2cm,bottom=2cm]{geometry}", .standard),
        ("\\usepackage[margin=2cm,textwidth=15cm]{geometry}", .standard),
        ("\\usepackage{geometry}", .standard),
        ("% \\usepackage[margin=2cm]{geometry}", .standard),
        ("\\geometry{margin=2cm}", .standard)                     // geometry gar nicht geladen
    ])
    func recognisesMargins(lines: String, expected: PageMargins) {
        let text = "\\documentclass{article}\n\(lines)\n\\begin{document}\n\\end{document}\n"
        #expect(settings(text).margins == expected)
    }

    @Test(arguments: [
        ("\\usepackage{setspace}\n\\onehalfspacing", LineSpacing.onehalf),
        ("\\usepackage[onehalfspacing]{setspace}", .onehalf),
        ("\\usepackage[doublespacing]{setspace}", .double),
        ("\\usepackage{setspace}\n\\doublespacing\n\\singlespacing", .single),
        ("\\linespread{1.3}", .onehalf),
        ("\\linespread{1.6}", .double),
        ("\\linespread{1}", .single),
        ("\\usepackage{setspace}\n\\setstretch{1.5}", .onehalf),
        ("\\usepackage{setspace}\n% \\onehalfspacing", .single)
    ])
    func recognisesLineSpacing(lines: String, expected: LineSpacing) {
        let text = "\\documentclass{article}\n\(lines)\n\\begin{document}\n\\end{document}\n"
        #expect(settings(text).lineSpacing == expected)
    }

    @Test func documentClassOptions() {
        func read(_ line: String) -> DocumentSettings { settings(line + "\n\\begin{document}\n\\end{document}") }
        #expect(read("\\documentclass[10pt]{report}").baseFontSize == 10)
        #expect(read("\\documentclass[11pt,12pt]{report}").baseFontSize == 12)
        #expect(read("\\documentclass[14pt]{extarticle}").baseFontSize == nil)
        #expect(read("\\documentclass[fontsize=11pt, paper=a5]{scrartcl}").baseFontSize == 11)
        #expect(read("\\documentclass[fontsize=11pt, paper=a5]{scrartcl}").paperSize == .a5paper)
        #expect(read("\\documentclass[letterpaper]{article}").paperSize == .letterpaper)
        #expect(read("\\documentclass[b5paper]{article}").paperSize == nil)
        #expect(read("\\documentclass[\n  a4paper, % Papier\n  12pt\n]{article}") == DocumentSettings(documentClass: "article", baseFontSize: 12, paperSize: .a4paper))
        #expect(read("% \\documentclass[12pt]{book}\n\\documentclass{article}").documentClass == "article")
    }
}

// MARK: - Einstellungen schreiben

@Suite("Präambel: Einstellungen schreiben")
struct PreambleApplyTests {
    @Test func noPreambleOrNoChange() {
        #expect(PreambleEditor.apply(DocumentSettings(font: .times), in: parse("\\documentclass{article}\nText")) == nil)
        #expect(PreambleEditor.apply(DocumentSettings(font: .times), in: parse("")) == nil)
        #expect(applied(settings(starter), to: starter) == nil)
        #expect(applied(settings(handWritten), to: handWritten) == nil)
    }

    @Test func fontAfterTheLastPackage() throws {
        var target = settings(starter)
        target.font = .times
        let result = try #require(applied(target, to: starter))
        #expect(result == """
        \\documentclass[a4paper,11pt]{article}
        \\usepackage[ngerman]{babel}
        \\usepackage{amsmath,amssymb,amsthm}
        \\usepackage[T1]{fontenc} % Schrift: Times
        \\usepackage{newtxtext,newtxmath}

        \\begin{document}

        \\section{Erster Abschnitt}
        Hier beginnt dein Text. Eine Formel im Fliesstext: $a^2 + b^2 = c^2$.

        \\end{document}

        """)
        #expect(settings(result).font == .times)

        // Zurück zu Latin Modern: Der Times-Block wird ersetzt, nicht ergänzt.
        target.font = .latinModern
        let back = try #require(applied(target, to: result))
        #expect(!back.contains("newtx"))
        #expect(back.contains("\\usepackage{iftex} % Schrift: Latin Modern\n\\ifPDFTeX\\usepackage[T1]{fontenc}\\else\\usepackage{fontspec}\\fi\n\\usepackage{lmodern}\n\n\\begin{document}"))
        #expect(settings(back).font == .latinModern)
        #expect(applied(target, to: back) == nil)
    }

    @Test func everyFontReplacesTheBlockCompletely() throws {
        var text = starter
        for font in DocumentFont.allCases.reversed() + DocumentFont.allCases {
            var target = settings(text)
            guard target.font != font else { continue }
            target.font = font
            text = try #require(applied(target, to: text))
            #expect(settings(text) == target)
            #expect(applied(target, to: text) == nil)
            // Genau ein Schrift-Block, und zwar der richtige.
            #expect(text.components(separatedBy: "% Schrift:").count == 2, "\(font)")
            let blockLine = try #require(lineIndex(of: "% Schrift: \(font.title)", in: text))
            let amsLine = try #require(lineIndex(of: "\\usepackage{amsmath,amssymb,amsthm}", in: text))
            #expect(blockLine == amsLine + 1, "Schrift nach amsmath: \(font)")
            #expect(Array(lines(text)[blockLine..<(blockLine + font.preambleLines.count)])
                == [font.preambleLines[0] + " % Schrift: \(font.title)"] + font.preambleLines.dropFirst())
            #expect(body(text) == body(starter))
        }
    }

    @Test func classOptions() throws {
        var target = settings(starter)
        target.baseFontSize = 12
        #expect(try #require(applied(target, to: starter)).hasPrefix("\\documentclass[a4paper,12pt]{article}\n"))
        target.baseFontSize = nil
        #expect(try #require(applied(target, to: starter)).hasPrefix("\\documentclass[a4paper]{article}\n"))
        target.paperSize = nil
        #expect(try #require(applied(target, to: starter)).hasPrefix("\\documentclass{article}\n"))
        target.paperSize = .letterpaper
        target.baseFontSize = 10
        #expect(try #require(applied(target, to: starter)).hasPrefix("\\documentclass[letterpaper,10pt]{article}\n"))

        // Fehlende Optionen werden angehängt, andere bleiben.
        let plain = "\\documentclass[twocolumn, draft]{article}\n\\begin{document}\n\\end{document}"
        var plainTarget = settings(plain)
        plainTarget.paperSize = .a5paper
        plainTarget.baseFontSize = 11
        #expect(applied(plainTarget, to: plain) == "\\documentclass[twocolumn, draft, 11pt, a5paper]{article}\n\\begin{document}\n\\end{document}")

        // Ohne Optionen: Klammern neu.
        let bare = "\\documentclass{article}\n\\begin{document}\n\\end{document}"
        var bareTarget = settings(bare)
        bareTarget.paperSize = .a4paper
        #expect(applied(bareTarget, to: bare) == "\\documentclass[a4paper]{article}\n\\begin{document}\n\\end{document}")

        // KOMA-Script: Schreibweise der Klasse beibehalten.
        let koma = "\\documentclass[fontsize=11pt, paper=a5]{scrartcl}\n\\begin{document}\n\\end{document}"
        var komaTarget = settings(koma)
        komaTarget.baseFontSize = 12
        komaTarget.paperSize = .a4paper
        #expect(applied(komaTarget, to: koma) == "\\documentclass[fontsize=12pt, paper=a4]{scrartcl}\n\\begin{document}\n\\end{document}")

        // Klassenname
        var renamed = settings(starter)
        renamed.documentClass = "scrartcl"
        #expect(try #require(applied(renamed, to: starter)).hasPrefix("\\documentclass[a4paper,11pt]{scrartcl}\n"))
        // nil heisst „nicht ändern“.
        renamed.documentClass = nil
        #expect(applied(renamed, to: starter) == nil)
    }

    @Test func marginsAndSpacingInsertedLinesAndRemovedAgain() throws {
        var target = settings(starter)
        target.margins = .narrow
        target.lineSpacing = .onehalf
        let result = try #require(applied(target, to: starter))
        #expect(result.contains("""
        \\usepackage{amsmath,amssymb,amsthm}
        \\usepackage[margin=2cm]{geometry} % Seitenränder
        \\usepackage[onehalfspacing]{setspace} % Zeilenabstand

        \\begin{document}
        """))
        #expect(settings(result) == target)
        target.margins = .wide
        let wide = try #require(applied(target, to: result))
        #expect(wide.contains("\\usepackage[margin=3.5cm]{geometry} % Seitenränder\n"))
        target.margins = .standard
        target.lineSpacing = .single
        // Zurück auf Standard: genau der Ausgangstext.
        #expect(applied(target, to: wide) == starter)
    }

    @Test func newPackagesGoBeforeTheFontBlock() throws {
        var target = settings(starter)
        target.font = .palatino
        let palatino = try #require(applied(target, to: starter))
        target.margins = .normal
        target.lineSpacing = .double
        let result = try #require(applied(target, to: palatino))
        let geometry = try #require(lineIndex(of: "{geometry}", in: result))
        let spacing = try #require(lineIndex(of: "{setspace}", in: result))
        let font = try #require(lineIndex(of: "% Schrift: Palatino", in: result))
        #expect(geometry < spacing && spacing < font)
        #expect(settings(result) == target)
    }

    @Test func handWrittenGeometryIsChangedInPlace() throws {
        let text = """
        \\documentclass{article}
        \\usepackage[a4paper, margin=2cm, landscape]{geometry} % meine Ränder
        \\usepackage{amsmath}
        \\begin{document}
        \\end{document}
        """
        var target = settings(text)
        #expect(target.margins == .narrow)
        // Nur die Schrift ändern: geometry bleibt unberührt.
        target.font = .times
        let timesText = try #require(applied(target, to: text))
        #expect(timesText.contains("\\usepackage[a4paper, margin=2cm, landscape]{geometry} % meine Ränder\n"))

        target = settings(text)
        target.margins = .wide
        let wide = try #require(applied(target, to: text))
        #expect(wide.contains("\\usepackage[margin=3.5cm, a4paper, landscape]{geometry} % meine Ränder\n"))
        #expect(!wide.contains("Seitenränder"))
        #expect(settings(wide).margins == .wide)

        target.margins = .standard
        let standard = try #require(applied(target, to: text))
        #expect(standard.contains("\\usepackage[a4paper, landscape]{geometry} % meine Ränder\n"))
        #expect(settings(standard).margins == .standard)
        #expect(applied(target, to: standard) == nil)

        // Nur Ränder: die ganze Zeile fällt weg (samt Kommentar).
        let onlyMargins = "\\documentclass{article}\n\\usepackage[margin=2cm]{geometry} % schmal\n\\begin{document}\n\\end{document}"
        var onlyTarget = settings(onlyMargins)
        onlyTarget.margins = .standard
        #expect(applied(onlyTarget, to: onlyMargins) == "\\documentclass{article}\n\\begin{document}\n\\end{document}")
    }

    @Test func geometryCommandAndPackageList() throws {
        let command = """
        \\documentclass{article}
        \\usepackage{geometry}
        \\geometry{top=2cm, bottom=2cm, left=2cm, right=2cm}
        \\begin{document}
        \\end{document}
        """
        var target = settings(command)
        #expect(target.margins == .narrow)
        target.margins = .normal
        let normal = try #require(applied(target, to: command))
        #expect(normal == """
        \\documentclass{article}
        \\usepackage[margin=2.5cm]{geometry}
        \\begin{document}
        \\end{document}
        """)

        // geometry in einer Liste: herauslösen, sonst gibt es einen Optionen-Konflikt.
        let list = "\\documentclass{article}\n\\usepackage{xcolor, geometry}\n\\begin{document}\n\\end{document}"
        var listTarget = settings(list)
        listTarget.margins = .narrow
        #expect(applied(listTarget, to: list) == "\\documentclass{article}\n\\usepackage{xcolor}\n\\usepackage[margin=2cm]{geometry} % Seitenränder\n\\begin{document}\n\\end{document}")
    }

    @Test func paperSizeAlsoInGeometry() throws {
        let text = "\\documentclass[a4paper]{article}\n\\usepackage[a4paper,margin=2cm]{geometry}\n\\begin{document}\n\\end{document}"
        var target = settings(text)
        target.paperSize = .a5paper
        let result = try #require(applied(target, to: text))
        #expect(result == "\\documentclass[a5paper]{article}\n\\usepackage[a5paper,margin=2cm]{geometry}\n\\begin{document}\n\\end{document}")
        #expect(settings(result) == target)
    }

    @Test func handWrittenSpacingIsChangedInPlace() throws {
        let text = """
        \\documentclass{article}
        \\usepackage{setspace}
        \\onehalfspacing % wie verlangt
        \\begin{document}
        \\end{document}
        """
        var target = settings(text)
        #expect(target.lineSpacing == .onehalf)
        target.lineSpacing = .double
        #expect(applied(target, to: text) == text.replacingOccurrences(of: "\\onehalfspacing", with: "\\doublespacing"))
        target.lineSpacing = .single
        let single = try #require(applied(target, to: text))
        #expect(single == "\\documentclass{article}\n\\usepackage{setspace}\n\\begin{document}\n\\end{document}")
        #expect(applied(target, to: single) == nil)

        // \linespread wird durch setspace ersetzt.
        let spread = "\\documentclass{article}\n\\usepackage{amsmath}\n\\linespread{1.3}\n\\begin{document}\n\\end{document}"
        var spreadTarget = settings(spread)
        #expect(spreadTarget.lineSpacing == .onehalf)
        spreadTarget.lineSpacing = .double
        #expect(applied(spreadTarget, to: spread) == "\\documentclass{article}\n\\usepackage{amsmath}\n\\usepackage[doublespacing]{setspace} % Zeilenabstand\n\\begin{document}\n\\end{document}")

        // setspace in einer Liste: Befehl direkt danach.
        let list = "\\documentclass{article}\n\\usepackage{setspace,xcolor}\n\\begin{document}\n\\end{document}"
        var listTarget = settings(list)
        listTarget.lineSpacing = .onehalf
        let listResult = try #require(applied(listTarget, to: list))
        #expect(listResult == "\\documentclass{article}\n\\usepackage{setspace,xcolor}\n\\onehalfspacing % Zeilenabstand\n\\begin{document}\n\\end{document}")
        listTarget.lineSpacing = .single
        #expect(applied(listTarget, to: listResult) == list)
    }

    @Test func handWrittenFontsAreReplaced() throws {
        let text = """
        \\documentclass{article}
        \\usepackage[T1]{fontenc}
        \\usepackage{mathptmx} % Times
        \\usepackage{amsmath,newtxmath}
        \\usepackage{fontspec}
        \\setmainfont{Times New Roman}
        \\usepackage{graphicx}
        \\begin{document}
        \\end{document}
        """
        var target = settings(text)
        #expect(target.font == .times)
        target.font = .charter
        let result = try #require(applied(target, to: text))
        #expect(result == """
        \\documentclass{article}
        \\usepackage[T1]{fontenc}
        \\usepackage{amsmath}
        \\usepackage{fontspec}
        \\usepackage{graphicx}
        \\usepackage{XCharter} % Schrift: Charter
        \\usepackage[xcharter,noOT1]{newtxmath}
        \\begin{document}
        \\end{document}
        """)
        #expect(settings(result).font == .charter)
    }

    @Test func helveticaWrittenByHandBecomesTimes() throws {
        let text = """
        \\documentclass{article}
        \\usepackage[scaled]{helvet}
        \\renewcommand{\\familydefault}{\\sfdefault}
        \\usepackage{amsmath}
        \\begin{document}
        \\end{document}
        """
        var target = settings(text)
        #expect(target.font == .helvetica)
        target.font = .times
        let result = try #require(applied(target, to: text))
        #expect(result == """
        \\documentclass{article}
        \\usepackage{amsmath}
        \\usepackage[T1]{fontenc} % Schrift: Times
        \\usepackage{newtxtext,newtxmath}
        \\begin{document}
        \\end{document}
        """)
    }

    @Test func sansPackageStaysWhenItIsOnlyTheSansFont() throws {
        let text = "\\documentclass{article}\n\\usepackage{mathptmx}\n\\usepackage[scaled]{helvet}\n\\begin{document}\n\\end{document}"
        var target = settings(text)
        target.font = .palatino
        let result = try #require(applied(target, to: text))
        #expect(result.contains("\\usepackage[scaled]{helvet}\n"))
        #expect(!result.contains("mathptmx"))
    }

    @Test func editedFontBlockLinesAreKeptAndStillRecognised() throws {
        // Der Nutzer hat in den Block eine eigene Zeile eingefügt: Sie bleibt stehen.
        let text = """
        \\documentclass{article}
        \\usepackage[T1]{fontenc} % Schrift: Times
        \\usepackage{microtype}
        \\usepackage{newtxtext,newtxmath}
        \\begin{document}
        \\end{document}
        """
        var target = settings(text)
        #expect(target.font == .times)
        target.font = .libertinus
        let result = try #require(applied(target, to: text))
        #expect(result.contains("\\usepackage{microtype}\n"))
        #expect(!result.contains("newtx"))
        #expect(settings(result).font == .libertinus)
        #expect(result.components(separatedBy: "% Schrift:").count == 2)
    }

    @Test func commentsAreIgnored() throws {
        let text = """
        \\documentclass{article}
        % Schrift: Times – nur eine Notiz, kein Block
        % \\usepackage{newtxtext,newtxmath}
        % \\usepackage[margin=2cm]{geometry}
        \\usepackage{amsmath}
        \\begin{document}
        \\end{document}
        """
        var target = settings(text)
        #expect(target.font == .latinModern)
        #expect(target.margins == .standard)
        target.font = .times
        target.margins = .narrow
        let result = try #require(applied(target, to: text))
        // Die Kommentare bleiben, wie sie sind.
        #expect(result.hasPrefix("\\documentclass{article}\n% Schrift: Times – nur eine Notiz, kein Block\n% \\usepackage{newtxtext,newtxmath}\n% \\usepackage[margin=2cm]{geometry}\n\\usepackage{amsmath}\n"))
        #expect(settings(result) == target)
    }

    @Test func preambleWithoutPackages() throws {
        let text = "\\documentclass{article}\n\\title{Größen}\n\\begin{document}\nÄ\n\\end{document}"
        var target = settings(text)
        target.font = .times
        target.lineSpacing = .onehalf
        let result = try #require(applied(target, to: text))
        #expect(result == "\\documentclass{article}\n\\title{Größen}\n\\usepackage[onehalfspacing]{setspace} % Zeilenabstand\n\\usepackage[T1]{fontenc} % Schrift: Times\n\\usepackage{newtxtext,newtxmath}\n\\begin{document}\nÄ\n\\end{document}")
        #expect(settings(result) == target)
    }

    @Test func beginDocumentInTheMiddleOfALine() throws {
        let text = "\\documentclass{article}\\begin{document}Hallo\\end{document}"
        var target = settings(text)
        target.font = .times
        let result = try #require(applied(target, to: text))
        #expect(result == "\\documentclass{article}\n\\usepackage[T1]{fontenc} % Schrift: Times\n\\usepackage{newtxtext,newtxmath}\n\\begin{document}Hallo\\end{document}")
        #expect(settings(result).font == .times)
    }

    @Test func windowsLineBreaks() throws {
        let text = starter.replacingOccurrences(of: "\n", with: "\r\n")
        var target = settings(text)
        #expect(target == settings(starter))
        target.font = .helvetica
        target.margins = .normal
        let result = try #require(applied(target, to: text))
        #expect(!result.replacingOccurrences(of: "\r\n", with: "").contains("\n"))
        #expect(settings(result) == target)
        #expect(applied(target, to: result) == nil)
    }

    // MARK: Gefundene Schwachstellen (Selbstprüfung)

    @Test func neverInsertsIntoAConditional() throws {
        let text = """
        \\documentclass{article}
        \\usepackage{iftex}
        \\ifXeTeX
          \\usepackage{fontspec}
        \\else
          \\usepackage[utf8]{inputenc}
        \\fi
        \\begin{document}
        \\end{document}
        """
        var target = settings(text)
        target.font = .times
        target.margins = .narrow
        let result = try #require(applied(target, to: text))
        #expect(result == """
        \\documentclass{article}
        \\usepackage{iftex}
        \\usepackage[margin=2cm]{geometry} % Seitenränder
        \\ifXeTeX
          \\usepackage{fontspec}
        \\else
          \\usepackage[utf8]{inputenc}
        \\fi
        \\usepackage[T1]{fontenc} % Schrift: Times
        \\usepackage{newtxtext,newtxmath}
        \\begin{document}
        \\end{document}
        """)
        let conditional = "\\documentclass{article}\n\\ifPDFTeX\n  \\usepackage[utf8]{inputenc}\n\\fi\n\\begin{document}\n\\end{document}"
        #expect(ensured([.xcolor], in: conditional) == "\\documentclass{article}\n\\ifPDFTeX\n  \\usepackage[utf8]{inputenc}\n\\fi\n\\usepackage{xcolor}\n\\begin{document}\n\\end{document}")
        // Der eigene Helvetica-Block mit \ifPDFTeX … \fi über mehrere Zeilen wird nie zerteilt.
        var helvetica = settings(starter)
        helvetica.font = .helvetica
        let helveticaText = try #require(applied(helvetica, to: starter))
        let withSpacing = try #require(ensured([.xcolor, .hyperref], in: helveticaText))
        #expect(withSpacing.contains(DocumentFont.helvetica.preambleLines.dropFirst().joined(separator: "\n")))
        // Ein mit \newif erklärter Schalter ist keine Bedingung.
        let newif = "\\documentclass{article}\n\\newif\\ifloesung\n\\usepackage{amsmath}\n\\begin{document}\n\\end{document}"
        #expect(ensured([.xcolor], in: newif) == "\\documentclass{article}\n\\newif\\ifloesung\n\\usepackage{amsmath}\n\\usepackage{xcolor}\n\\begin{document}\n\\end{document}")
    }

    @Test func fontAndMarginsTouchTheSamePackageList() throws {
        let text = "\\documentclass{article}\n\\usepackage{amsmath}\n\\usepackage{geometry,mathptmx}\n\\begin{document}\n\\end{document}"
        var target = settings(text)
        #expect(target.font == .times)
        target.font = .palatino
        target.margins = .narrow
        let result = try #require(applied(target, to: text))
        #expect(result == """
        \\documentclass{article}
        \\usepackage{amsmath}
        \\usepackage[margin=2cm]{geometry} % Seitenränder
        \\usepackage{iftex} % Schrift: Palatino
        \\ifPDFTeX\\usepackage[T1]{fontenc}\\else\\usepackage[no-math]{fontspec}\\fi
        \\usepackage{newpxtext,newpxmath}
        \\begin{document}
        \\end{document}
        """)
        #expect(settings(result) == target)
    }

    @Test func commentInsideTheFontBlockStays() throws {
        var target = settings(starter)
        target.font = .helvetica
        let helvetica = try #require(applied(target, to: starter))
        let commented = helvetica.replacingOccurrences(of: "\\ifPDFTeX\n", with: "\\ifPDFTeX\n  % pdfLaTeX braucht T1 für Umlaute\n")
        target.font = .times
        let result = try #require(applied(target, to: commented))
        #expect(result.contains("% pdfLaTeX braucht T1 für Umlaute\n"))
        for line in DocumentFont.helvetica.preambleLines {
            #expect(!result.contains(line), "Rest des Blocks: \(line)")
        }
        #expect(settings(result).font == .times)
    }

    @Test func fractionalSizesAndKomaPaperOptions() throws {
        func read(_ line: String) -> DocumentSettings { settings(line + "\n\\begin{document}\n\\end{document}") }
        #expect(read("\\documentclass[fontsize=11.5pt]{scrartcl}").baseFontSize == nil)
        let koma = "\\documentclass[paper=landscape, paper=a4]{scrartcl}\n\\begin{document}\n\\end{document}"
        var target = settings(koma)
        #expect(target.paperSize == .a4paper)
        target.paperSize = .a5paper
        #expect(applied(target, to: koma) == "\\documentclass[paper=landscape, paper=a5]{scrartcl}\n\\begin{document}\n\\end{document}")
        target.paperSize = nil
        #expect(applied(target, to: koma) == "\\documentclass[paper=landscape]{scrartcl}\n\\begin{document}\n\\end{document}")
        let fractional = "\\documentclass[fontsize=11.5pt]{scrartcl}\n\\begin{document}\n\\end{document}"
        var fractionalTarget = settings(fractional)
        fractionalTarget.baseFontSize = 12
        #expect(applied(fractionalTarget, to: fractional) == "\\documentclass[fontsize=12pt]{scrartcl}\n\\begin{document}\n\\end{document}")
    }

    /// Alle Kombinationen auf mehreren Präambeln: Lesen ergibt das Geschriebene,
    /// ein zweites Schreiben ändert nichts, der Text nach \begin{document} bleibt.
    @Test(arguments: [starter, handWritten,
                      "\\documentclass{article}\n\\begin{document}\n\\end{document}",
                      "\\documentclass[12pt]{report}\n\\usepackage{setspace}\n\\usepackage[margin=2cm,a4paper]{geometry}\n\\usepackage{newpxtext,newpxmath}\n\\begin{document}\nÜ\n\\end{document}\n"])
    func roundTrips(base: String) throws {
        let original = settings(base)
        for font in DocumentFont.allCases {
            for margins in PageMargins.allCases {
                for spacing in LineSpacing.allCases {
                    for size in [nil, 10, 11, 12] as [Int?] {
                        for paper in [nil] + PaperSize.allCases.map(Optional.some) {
                            let target = DocumentSettings(
                                documentClass: original.documentClass, baseFontSize: size, paperSize: paper,
                                font: font, margins: margins, lineSpacing: spacing
                            )
                            guard let result = applied(target, to: base) else {
                                #expect(target == original)
                                continue
                            }
                            #expect(settings(result) == target, "\(target)")
                            #expect(PreambleEditor.apply(target, in: parse(result)) == nil, "nicht idempotent: \(target)")
                            #expect(body(result) == body(base))
                        }
                    }
                }
            }
        }
    }

    /// Mehrere Änderungen nacheinander und zurück: Ränder, Abstand, Grösse und Papier
    /// hinterlassen keine Spuren; die Schrift steht danach als Block da.
    @Test func changesAndBack() throws {
        var text = starter
        let steps: [(inout DocumentSettings) -> Void] = [
            { $0.margins = .narrow }, { $0.lineSpacing = .double }, { $0.baseFontSize = 12 },
            { $0.paperSize = .letterpaper }, { $0.margins = .wide }, { $0.lineSpacing = .onehalf }
        ]
        for step in steps {
            var target = settings(text)
            step(&target)
            text = try #require(applied(target, to: text))
            #expect(settings(text) == target)
        }
        #expect(applied(settings(starter), to: text) == starter)
    }
}

// MARK: - Pakete ergänzen

@Suite("Präambel: Pakete ergänzen")
struct PreambleEnsureTests {
    @Test func insertsAfterTheLastPackage() throws {
        let result = try #require(ensured([.xcolor], in: starter))
        #expect(result.contains("\\usepackage{amsmath,amssymb,amsthm}\n\\usepackage{xcolor}\n\n\\begin{document}"))
        #expect(ensured([.xcolor], in: result) == nil)
        #expect(ensured([.amsmath, .amssymb], in: starter) == nil)
        let table = try #require(ensured([PackageRequirement("xcolor", options: "table")], in: starter))
        #expect(table.contains("\\usepackage[table]{xcolor}\n"))
    }

    @Test func nilWithoutPreamble() {
        #expect(PreambleEditor.ensure([.xcolor], in: parse("Nur Text ohne Präambel")) == nil)
        #expect(PreambleEditor.ensure([], in: parse(starter)) == nil)
    }

    @Test func multiPackageLinesAndRequirePackage() {
        let text = "\\documentclass{article}\n\\usepackage[table, dvipsnames]{xcolor,graphicx}\n\\RequirePackage{booktabs}\n\\begin{document}\n\\end{document}"
        #expect(ensured([.xcolor, .graphicx, .booktabs], in: text) == nil)
    }

    @Test func commentedPackageIsNotLoaded() throws {
        let text = "\\documentclass{article}\n\\usepackage{amsmath}\n% \\usepackage{xcolor}\n\\begin{document}\n\\end{document}"
        let result = try #require(ensured([.xcolor], in: text))
        #expect(result == "\\documentclass{article}\n\\usepackage{amsmath}\n\\usepackage{xcolor}\n% \\usepackage{xcolor}\n\\begin{document}\n\\end{document}")
    }

    @Test func beforeBeginDocumentWithoutPackages() throws {
        let text = "\\documentclass{article}\n\\title{Übung}\n\n\\begin{document}\n\\end{document}"
        #expect(ensured([.hyperref], in: text) == "\\documentclass{article}\n\\title{Übung}\n\n\\usepackage{hyperref}\n\\begin{document}\n\\end{document}")
    }

    @Test func packagesGoBeforeFontsAndHyperref() throws {
        var target = settings(starter)
        target.font = .times
        var text = try #require(applied(target, to: starter))
        text = try #require(ensured([.hyperref], in: text))
        // amssymb nach newtxmath wäre ein Fehler („\Bbbk already defined“).
        let withoutAmssymb = text.replacingOccurrences(of: "amsmath,amssymb,amsthm", with: "amsmath,amsthm")
        let result = try #require(ensured([.amssymb, .xcolor], in: withoutAmssymb))
        let amssymb = try #require(lineIndex(of: "\\usepackage{amssymb}", in: result))
        let xcolor = try #require(lineIndex(of: "\\usepackage{xcolor}", in: result))
        let font = try #require(lineIndex(of: "% Schrift: Times", in: result))
        let hyperref = try #require(lineIndex(of: "{hyperref}", in: result))
        #expect(amssymb < font && xcolor < font && xcolor == amssymb + 1)
        #expect(amssymb < hyperref)

        // Ein von Hand geladenes Schrift-Paket zählt genauso.
        let hand = "\\documentclass{article}\n\\usepackage{amsmath}\n\\usepackage{newtxtext,newtxmath}\n\\begin{document}\n\\end{document}"
        #expect(ensured([.amssymb], in: hand) == "\\documentclass{article}\n\\usepackage{amsmath}\n\\usepackage{amssymb}\n\\usepackage{newtxtext,newtxmath}\n\\begin{document}\n\\end{document}")
        // Steht kein Paket davor, kommt das neue direkt vor das Schrift-Paket.
        let first = "\\documentclass{article}\n\\usepackage{mathptmx}\n\\begin{document}\n\\end{document}"
        #expect(ensured([.amsmath], in: first) == "\\documentclass{article}\n\\usepackage{amsmath}\n\\usepackage{mathptmx}\n\\begin{document}\n\\end{document}")
    }

    @Test func theoremDeclarations() throws {
        let result = try #require(ensured([.theorems], in: starter))
        // amsthm ist schon geladen: nur die Zeilen, direkt danach.
        let expectedLines = PackageRequirement.theorems.preambleLines.joined(separator: "\n")
        #expect(result.contains("\\usepackage{amsmath,amssymb,amsthm}\n" + expectedLines + "\n\n\\begin{document}"))
        #expect(ensured([.theorems], in: result) == nil)

        // Ohne amsthm: Paket und Zeilen.
        let bare = "\\documentclass{article}\n\\usepackage{amsmath}\n\\begin{document}\n\\end{document}"
        let withPackage = try #require(ensured([.theorems], in: bare))
        #expect(withPackage == "\\documentclass{article}\n\\usepackage{amsmath}\n\\usepackage{amsthm}\n" + expectedLines + "\n\\begin{document}\n\\end{document}")
    }

    @Test func existingTheoremDefinitionsCount() throws {
        let text = """
        \\documentclass{article}
        \\usepackage{amsthm}
        \\newtheorem{satz}{Theorem}
        \\newtheorem{lemma}[satz]{Hilfssatz}
        \\newtheorem*{bemerkung}{Anmerkung}
        \\begin{document}
        \\end{document}
        """
        let result = try #require(ensured([.theorems], in: text))
        #expect(result == """
        \\documentclass{article}
        \\usepackage{amsthm}
        \\newtheorem{satz}{Theorem}
        \\newtheorem{lemma}[satz]{Hilfssatz}
        \\newtheorem*{bemerkung}{Anmerkung}
        \\theoremstyle{plain}
        \\newtheorem{korollar}[satz]{Korollar}
        \\theoremstyle{definition}
        \\newtheorem{definition}[satz]{Definition}
        \\newtheorem{beispiel}[satz]{Beispiel}
        \\begin{document}
        \\end{document}
        """)
        #expect(ensured([.theorems], in: result) == nil)
    }

    @Test func missingSingleTheoremKeepsItsStyle() throws {
        let complete = try #require(ensured([.theorems], in: starter))
        let missing = complete.replacingOccurrences(of: "\\newtheorem*{bemerkung}{Bemerkung}\n", with: "")
        let result = try #require(ensured([.theorems], in: missing))
        #expect(result.contains("\\theoremstyle{remark}\n\\theoremstyle{remark}\n\\newtheorem*{bemerkung}{Bemerkung}\n"))
        #expect(ensured([.theorems], in: result) == nil)
    }

    /// Mehrere Anforderungen an dasselbe Paket: nur ein \usepackage, aber alle Zeilen.
    @Test func samePackageRequestedTwice() throws {
        let bare = "\\documentclass{article}\n\\usepackage{amsmath}\n\\begin{document}\n\\end{document}"
        let result = try #require(ensured([PackageRequirement("amsthm"), .theorems], in: bare))
        #expect(result.components(separatedBy: "\\usepackage{amsthm}").count == 2)
        for line in PackageRequirement.theorems.preambleLines {
            #expect(result.contains(line + "\n"), "\(line)")
        }
        #expect(ensured([.theorems, PackageRequirement("amsthm")], in: result) == nil)

        // Unterschiedliche Optionen: die ersten nicht leeren gelten.
        let colors = try #require(ensured([.xcolor, PackageRequirement("xcolor", options: "table"),
                                           PackageRequirement("xcolor", options: "dvipsnames")], in: bare))
        #expect(colors.contains("\\usepackage[table]{xcolor}\n"))
        #expect(colors.components(separatedBy: "{xcolor}").count == 2)

        // Doppelte Zeilen werden nur einmal eingefügt.
        let twice = try #require(ensured([.theorems, .theorems], in: bare))
        #expect(twice.components(separatedBy: "\\newtheorem{satz}").count == 2)
    }

    @Test func otherPreambleLinesByExactMatch() throws {
        let requirement = PackageRequirement("listings", preambleLines: ["\\lstset{basicstyle=\\ttfamily}"])
        let text = "\\documentclass{article}\n\\usepackage{listings}\n  \\lstset{basicstyle=\\ttfamily} % schon da\n\\begin{document}\n\\end{document}"
        #expect(ensured([requirement], in: text) == nil)
        let commented = "\\documentclass{article}\n\\usepackage{listings}\n% \\lstset{basicstyle=\\ttfamily}\n\\begin{document}\n\\end{document}"
        #expect(ensured([requirement], in: commented) == "\\documentclass{article}\n\\usepackage{listings}\n\\lstset{basicstyle=\\ttfamily}\n% \\lstset{basicstyle=\\ttfamily}\n\\begin{document}\n\\end{document}")
    }

    @Test func umlautsAndEmojiBeforeTheInsertion() throws {
        let text = "\\documentclass{article}\n% Übungsblatt für Jörg 😀\n\\usepackage{amsmath} % Größen\n\\begin{document}\nÄ 😀\n\\end{document}"
        let result = try #require(ensured([.xcolor, .theorems], in: text))
        #expect(result.hasPrefix("\\documentclass{article}\n% Übungsblatt für Jörg 😀\n\\usepackage{amsmath} % Größen\n\\usepackage{xcolor}\n\\usepackage{amsthm}\n\\theoremstyle{plain}"))
        #expect(body(result) == body(text))
        var target = settings(result)
        target.font = .libertinus
        target.margins = .narrow
        let styled = try #require(applied(target, to: result))
        #expect(settings(styled) == target)
        #expect(body(styled) == body(text))
    }

    @Test func beginDocumentInTheMiddleOfALine() throws {
        let text = "\\documentclass{article}\\usepackage{amsmath}\\begin{document}x\\end{document}"
        let result = try #require(ensured([.xcolor], in: text))
        #expect(result == "\\documentclass{article}\\usepackage{amsmath}\n\\usepackage{xcolor}\n\\begin{document}x\\end{document}")
        #expect(ensured([.xcolor], in: result) == nil)
    }
}
