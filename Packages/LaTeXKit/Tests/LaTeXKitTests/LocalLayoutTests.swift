import Foundation
import Testing
@testable import LaTeXKit

private func apply(_ edit: TextEdit?, to text: String) -> String? {
    guard let edit else { return nil }
    return (text as NSString).replacingCharacters(
        in: NSRange(location: edit.range.lowerBound, length: edit.range.count), with: edit.replacement)
}

private func settings(_ text: String) -> DocumentSettings {
    PreambleEditor.settings(in: Array(text.utf16))
}

private func applying(_ settings: DocumentSettings, to text: String) -> String? {
    apply(PreambleEditor.apply(settings, in: Array(text.utf16)), to: text)
}

@Suite("Eigene Ränder und Zeilenabstände")
struct CustomLayoutTests {
    private let plain = "\\documentclass{article}\n\\usepackage{amsmath}\n\\begin{document}\nText\n\\end{document}\n"

    @Test("Eigene Ränder schreiben und wieder lesen")
    func customMargins() throws {
        var target = settings(plain)
        target.margins = .custom(MarginSizes(uniform: 1.8))
        let uniform = try #require(applying(target, to: plain))
        #expect(uniform.contains("\\usepackage[margin=1.8cm]{geometry} % Seitenränder\n"))
        #expect(settings(uniform).margins == .custom(MarginSizes(uniform: 1.8)))

        target.margins = .custom(MarginSizes(top: 2, bottom: 2.5, left: 3, right: 2))
        let sides = try #require(applying(target, to: uniform))
        #expect(sides.contains("\\usepackage[top=2cm,bottom=2.5cm,left=3cm,right=2cm]{geometry} % Seitenränder"))
        #expect(settings(sides).margins == target.margins)

        // Gleichmässig 2,5 cm ist die Voreinstellung „Normal“.
        #expect(PageMargins(sizes: MarginSizes(uniform: 2.5)) == .normal)
        target.margins = .standard
        #expect(applying(target, to: sides) == plain)
    }

    @Test("Eigener Zeilenabstand mit \\setstretch")
    func customSpacing() throws {
        var target = settings(plain)
        target.lineSpacing = .custom(1.3)
        let stretched = try #require(applying(target, to: plain))
        #expect(stretched.contains("\\usepackage{setspace} % Zeilenabstand\n\\setstretch{1.3} % Zeilenabstand\n"))
        #expect(settings(stretched).lineSpacing == .custom(1.3))

        target.lineSpacing = .custom(1.75)
        let changed = try #require(applying(target, to: stretched))
        #expect(changed.contains("\\setstretch{1.75} % Zeilenabstand"))
        #expect(!changed.contains("1.3"))

        target.lineSpacing = .onehalf
        let preset = try #require(applying(target, to: changed))
        #expect(settings(preset).lineSpacing == .onehalf)
        #expect(!preset.contains("setstretch"))

        target.lineSpacing = .single
        #expect(applying(target, to: preset) == plain)
    }

    @Test("Zahlen im LaTeX-Format")
    func numbers() {
        #expect(latexNumber(2) == "2")
        #expect(latexNumber(2.5) == "2.5")
        #expect(latexNumber(1.25) == "1.25")
        #expect(latexNumber(1.333) == "1.33")
        #expect(MarginSizes(uniform: 2.25).summary == "2,25 cm")
    }

    @Test("„pass“ weicht neuen Rändern; ohne eigene Ränder bleibt geometry für \\newgeometry")
    func passOption() throws {
        let local = "\\documentclass{article}\n\\usepackage[pass]{geometry}\n\\begin{document}\n\\newgeometry{margin=1cm}\nA\n\\restoregeometry\n\\end{document}\n"
        #expect(settings(local).margins == .standard)
        var target = settings(local)
        target.margins = .narrow
        let narrow = try #require(applying(target, to: local))
        #expect(narrow.contains("\\usepackage[margin=2cm]{geometry}\n"))
        #expect(!narrow.contains("pass"))
        target.margins = .standard
        let back = try #require(applying(target, to: narrow))
        #expect(back.contains("\\usepackage[pass]{geometry}\n"))
    }
}

@Suite("Nur diese Seite")
struct LocalLayoutTests {
    private let document = """
    \\documentclass{article}
    \\begin{document}
    Erster Absatz.

    Zweiter Absatz,
    über zwei Zeilen.
    \\begin{align*}
      a &= b
    \\end{align*}
    Danach.

    Letzter Absatz.
    \\end{document}

    """

    private func offset(of marker: String) -> Int {
        (document as NSString).range(of: marker).location
    }

    @Test("Absatz am Cursor ohne Auswahl")
    func paragraphRegion() throws {
        let units = Array(document.utf16)
        let cursor = offset(of: "über")
        let region = try #require(LocalLayout.region(in: units, around: cursor..<cursor))
        let text = (document as NSString).substring(with: NSRange(location: region.lowerBound, length: region.count))
        #expect(text == "Zweiter Absatz,\nüber zwei Zeilen.\n\\begin{align*}\n  a &= b\n\\end{align*}\nDanach.\n")
    }

    @Test("Zeilen einer Seite (SyncTeX) – keine Umgebung wird geteilt")
    func pageRegion() throws {
        let units = Array(document.utf16)
        // Zeilen 5 bis 8 schneiden die align*-Umgebung (Zeilen 7–9).
        let region = try #require(LocalLayout.region(in: units, lines: 5...8))
        let text = (document as NSString).substring(with: NSRange(location: region.lowerBound, length: region.count))
        #expect(text.hasPrefix("Zweiter Absatz,"))
        #expect(text.hasSuffix("\\end{align*}\n"))
        // Nie die Präambel oder \end{document}.
        let all = try #require(LocalLayout.region(in: units, lines: 1...20))
        let whole = (document as NSString).substring(with: NSRange(location: all.lowerBound, length: all.count))
        #expect(whole.hasPrefix("Erster Absatz.") && whole.hasSuffix("Letzter Absatz.\n"))
    }

    @Test("Ränder setzen, ändern und entfernen")
    func margins() throws {
        let units = Array(document.utf16)
        let cursor = offset(of: "Letzter")
        let region = try #require(LocalLayout.region(in: units, around: cursor..<cursor))
        let set = try #require(apply(LocalLayout.margins(.custom(MarginSizes(uniform: 1)), region: region, in: units), to: document))
        #expect(set.contains("\n\\newgeometry{margin=1cm}\nLetzter Absatz.\n\\restoregeometry\n\\end{document}"))

        // Noch einmal einstellen: ersetzt statt zu stapeln.
        let setUnits = Array(set.utf16)
        let again = (set as NSString).range(of: "Letzter").location
        let region2 = try #require(LocalLayout.region(in: setUnits, around: again..<again))
        let wide = try #require(apply(LocalLayout.margins(.wide, region: region2, in: setUnits), to: set))
        #expect(wide.components(separatedBy: "\\newgeometry").count == 2)
        #expect(wide.contains("\\newgeometry{margin=3.5cm}\nLetzter Absatz.\n\\restoregeometry\n"))

        // Standard entfernt das Paar wieder.
        let wideUnits = Array(wide.utf16)
        let third = (wide as NSString).range(of: "Letzter").location
        let region3 = try #require(LocalLayout.region(in: wideUnits, around: third..<third))
        #expect(apply(LocalLayout.margins(.standard, region: region3, in: wideUnits), to: wide) == document)
    }

    @Test("Zeilenabstand als Umgebung")
    func spacing() throws {
        let units = Array(document.utf16)
        let cursor = offset(of: "Erster")
        let region = try #require(LocalLayout.region(in: units, around: cursor..<cursor))
        let custom = try #require(apply(LocalLayout.spacing(.custom(1.4), region: region, in: units), to: document))
        #expect(custom.contains("\\begin{document}\n\\begin{spacing}{1.4}\nErster Absatz.\n\\end{spacing}\n\n"))

        let customUnits = Array(custom.utf16)
        let again = (custom as NSString).range(of: "Erster").location
        let region2 = try #require(LocalLayout.region(in: customUnits, around: again..<again))
        let double = try #require(apply(LocalLayout.spacing(.double, region: region2, in: customUnits), to: custom))
        #expect(double.contains("\\begin{doublespace}\nErster Absatz.\n\\end{doublespace}\n"))
        #expect(!double.contains("spacing}{1.4}"))
    }

    /// Schreibt ein Dokument mit allen Varianten – zum Übersetzen mit pdfLaTeX/XeLaTeX
    /// (nur mit `LEMMA_DUMP_LATEX=Pfad`).
    @Test("Beispieldokument für die Übersetzungsprobe")
    func dumpForCompilation() throws {
        guard let path = ProcessInfo.processInfo.environment["LEMMA_DUMP_LATEX"] else { return }
        var text = document
        func update(_ marker: String, _ change: ([UInt16], Range<Int>) -> TextEdit?) {
            let units = Array(text.utf16)
            let cursor = (text as NSString).range(of: marker).location
            guard let region = LocalLayout.region(in: units, around: cursor..<cursor) else { return }
            text = apply(change(units, region), to: text) ?? text
        }
        update("Erster") { LocalLayout.spacing(.custom(1.4), region: $1, in: $0) }
        update("über") { LocalLayout.margins(.custom(MarginSizes(top: 1, bottom: 1, left: 4, right: 1)), region: $1, in: $0) }
        update("Letzter") { LocalLayout.spacing(.double, region: $1, in: $0) }
        if let ensure = PreambleEditor.ensure([LocalLayout.geometryRequirement, LocalLayout.setspaceRequirement, PackageRequirement("amsmath")], in: Array(text.utf16)) {
            text = apply(ensure, to: text) ?? text
        }
        var whole = settings(text)
        whole.lineSpacing = .custom(1.2)
        whole.margins = .custom(MarginSizes(uniform: 2.2))
        text = applying(whole, to: text) ?? text
        try text.write(toFile: path, atomically: true, encoding: .utf8)
    }
}
