import Foundation

/// Schrift für das ganze Dokument.
///
/// Jede Variante muss mit pdfLaTeX (Overleaf, latexmk) *und* XeTeX (Tectonic)
/// funktionieren und Umlaute korrekt setzen.
public enum DocumentFont: String, CaseIterable, Sendable, Identifiable {
    case latinModern
    case times
    case palatino
    case charter
    case libertinus
    case helvetica

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .latinModern: return "Latin Modern"
        case .times: return "Times"
        case .palatino: return "Palatino"
        case .charter: return "Charter"
        case .libertinus: return "Libertinus"
        case .helvetica: return "Helvetica"
        }
    }

    /// Kurzbeschreibung für das Menü („klassisch, wie in Word“ …).
    public var subtitle: String {
        switch self {
        case .latinModern: return "Der LaTeX-Klassiker, wie in Mathe-Skripten"
        case .times: return "Klassisch, wie in Word und Zeitungen"
        case .palatino: return "Elegant und gut lesbar, auch bei langen Texten"
        case .charter: return "Kräftig und klar, gut lesbar am Bildschirm"
        case .libertinus: return "Freundlich und modern, mit passenden Formeln"
        case .helvetica: return "Ohne Serifen (Füsschen), sachlich und modern"
        }
    }

    /// Präambel-Zeilen für diese Schrift (leer für die Standardschrift).
    ///
    /// Ein leeres Dokument ohne Schrift-Zeilen gilt als Latin Modern. Wählt man
    /// Latin Modern ausdrücklich (z. B. zurück von Times), schreibt Lemma
    /// trotzdem drei Zeilen: Unter pdfLaTeX braucht es die Kodierung T1, sonst
    /// werden Wörter mit Umlauten nicht getrennt und lassen sich aus dem PDF
    /// nicht richtig kopieren.
    ///
    /// Alle Varianten sind mit pdfLaTeX und XeLaTeX (wie Tectonic) getestet,
    /// inklusive Umlauten und Formeln. Unter XeTeX werden die Schriften als Datei
    /// aus der TeX-Distribution geladen, nicht über installierte Systemschriften.
    /// `\ifPDFTeX` (aus dem Paket `iftex`) unterscheidet die beiden Welten.
    public var preambleLines: [String] {
        switch self {
        case .latinModern:
            return [
                "\\usepackage{iftex}",
                "\\ifPDFTeX\\usepackage[T1]{fontenc}\\else\\usepackage{fontspec}\\fi",
                "\\usepackage{lmodern}"
            ]
        case .times:
            // newtxtext lädt unter XeTeX selbst fontspec mit „TeX Gyre Termes X“.
            return [
                "\\usepackage[T1]{fontenc}",
                "\\usepackage{newtxtext,newtxmath}"
            ]
        case .palatino:
            // [no-math]: sonst stehen die Ziffern in Formeln unter XeTeX in Latin Modern.
            return [
                "\\usepackage{iftex}",
                "\\ifPDFTeX\\usepackage[T1]{fontenc}\\else\\usepackage[no-math]{fontspec}\\fi",
                "\\usepackage{newpxtext,newpxmath}"
            ]
        case .charter:
            // noOT1: Ziffern und \sin in Formeln kommen auch unter XeTeX aus Charter.
            return [
                "\\usepackage{XCharter}",
                "\\usepackage[xcharter,noOT1]{newtxmath}"
            ]
        case .libertinus:
            // Unter XeTeX bringt libertinus die Formelschrift selbst mit.
            return [
                "\\usepackage{iftex}",
                "\\usepackage[T1]{fontenc}",
                "\\usepackage{libertinus}",
                "\\ifPDFTeX\\usepackage{libertinust1math}\\fi"
            ]
        case .helvetica:
            // Fliesstext serifenlos; Formeln bleiben in der klassischen Formelschrift.
            return [
                "\\usepackage{iftex}",
                "\\ifPDFTeX",
                "  \\usepackage[T1]{fontenc}",
                "  \\usepackage{helvet}",
                "\\else",
                "  \\usepackage{fontspec}",
                "  \\setsansfont{texgyreheros}[Extension=.otf, UprightFont=*-regular, BoldFont=*-bold, ItalicFont=*-italic, BoldItalicFont=*-bolditalic]",
                "\\fi",
                "\\renewcommand{\\familydefault}{\\sfdefault}"
            ]
        }
    }

    /// Name einer ähnlichen macOS-Schrift für die Vorschau im Menü.
    public var previewFontName: String {
        switch self {
        case .latinModern: return "Baskerville"
        case .times: return "Times New Roman"
        case .palatino: return "Palatino"
        case .charter: return "Charter"
        case .libertinus: return "Hoefler Text"
        case .helvetica: return "Helvetica"
        }
    }
}

/// Seitenränder über das Paket `geometry`.
public enum PageMargins: String, CaseIterable, Sendable, Identifiable {
    /// Ränder der Dokumentklasse (kein geometry).
    case standard
    case narrow
    case normal
    case wide

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .standard: return "Standard der Dokumentklasse"
        case .narrow: return "Schmal (2 cm)"
        case .normal: return "Normal (2,5 cm)"
        case .wide: return "Breit (3,5 cm)"
        }
    }

    /// Optionen für `\usepackage[…]{geometry}`, `nil` für `.standard`.
    public var geometryOptions: String? {
        switch self {
        case .standard: return nil
        case .narrow: return "margin=2cm"
        case .normal: return "margin=2.5cm"
        case .wide: return "margin=3.5cm"
        }
    }
}

/// Zeilenabstand über das Paket `setspace`.
public enum LineSpacing: String, CaseIterable, Sendable, Identifiable {
    case single
    case onehalf
    case double

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .single: return "Einfach"
        case .onehalf: return "1,5-fach"
        case .double: return "Doppelt"
        }
    }
}

/// Papierformat (Option von `\documentclass`).
public enum PaperSize: String, CaseIterable, Sendable, Identifiable {
    case a4paper
    case a5paper
    case letterpaper

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .a4paper: return "A4"
        case .a5paper: return "A5"
        case .letterpaper: return "US Letter"
        }
    }
}

/// Seiten- und Schrifteinstellungen, wie sie die Präambel beschreibt.
public struct DocumentSettings: Equatable, Sendable {
    /// Name der Dokumentklasse (`article` …), `nil` ohne `\documentclass`.
    public var documentClass: String?
    /// Grundschriftgrösse in pt (10, 11 oder 12); `nil` = Standard der Klasse.
    public var baseFontSize: Int?
    public var paperSize: PaperSize?
    public var font: DocumentFont
    public var margins: PageMargins
    public var lineSpacing: LineSpacing

    public init(
        documentClass: String? = nil,
        baseFontSize: Int? = nil,
        paperSize: PaperSize? = nil,
        font: DocumentFont = .latinModern,
        margins: PageMargins = .standard,
        lineSpacing: LineSpacing = .single
    ) {
        self.documentClass = documentClass
        self.baseFontSize = baseFontSize
        self.paperSize = paperSize
        self.font = font
        self.margins = margins
        self.lineSpacing = lineSpacing
    }
}

/// Liest und ändert die Präambel (alles vor `\begin{document}`).
///
/// Änderungen sind minimal und nachvollziehbar: Lemma ergänzt bzw.
/// ersetzt einzelne Zeilen und markiert verwaltete Zeilen mit einem kurzen
/// Kommentar (z. B. `% Schrift: Times`). Von Hand geschriebene Präambeln
/// bleiben ansonsten unangetastet und mit Overleaf/TeXShop kompatibel.
public enum PreambleEditor {
    /// Position von `\begin{document}` (nicht in Kommentaren), falls vorhanden.
    public static func preambleEnd<S: UTF16Source>(in text: S) -> Int? {
        var i = 0
        while i < text.count {
            let u = text[i]
            if u == TeXChar.percent && !text.isEscaped(at: i) {
                i = text.lineEnd(after: i)
                continue
            }
            if u == TeXChar.backslash && !text.isEscaped(at: i),
               let token = BlockEditor.environmentToken(in: text, at: i) {
                if token.isBegin && token.name == "document" { return i }
                i = token.range.upperBound
                continue
            }
            i += 1
        }
        return nil
    }

    /// Ist das Paket (ausserhalb von Kommentaren) in der Präambel geladen?
    /// Berücksichtigt Mehrfachangaben wie `\usepackage{amsmath,amssymb}`.
    public static func isLoaded<S: UTF16Source>(package: String, in text: S) -> Bool {
        // Ohne \begin{document} gilt der ganze Text als (noch unfertige) Präambel.
        let end = preambleEnd(in: text) ?? text.count
        return ParsedPreamble(units: prefix(of: text, upTo: end)).isLoaded(package)
    }

    /// Aktuelle Einstellungen aus der Präambel.
    public static func settings<S: UTF16Source>(in text: S) -> DocumentSettings {
        let end = preambleEnd(in: text) ?? text.count
        return ParsedPreamble(units: prefix(of: text, upTo: end)).settings
    }

    /// Schreibt die Einstellungen in die Präambel. `nil`, wenn es keine Präambel gibt
    /// oder sich nichts ändert. Die `TextEdit` ersetzt nur den Präambel-Bereich;
    /// `selectionAfter` ist auf das Ende der Ersetzung gesetzt (der Aufrufer nutzt
    /// `preservingSelection`, um die Auswahl des Nutzers zu behalten).
    public static func apply<S: UTF16Source>(_ settings: DocumentSettings, in text: S) -> TextEdit? {
        guard let end = preambleEnd(in: text) else { return nil }
        let preamble = ParsedPreamble(units: prefix(of: text, upTo: end))
        return preamble.edit(applying: settings)
    }

    /// Ergänzt fehlende Pakete und Präambel-Zeilen direkt vor `\begin{document}`
    /// (bzw. nach dem letzten `\usepackage`). `nil`, wenn nichts fehlt oder es keine Präambel gibt.
    public static func ensure<S: UTF16Source>(_ requirements: [PackageRequirement], in text: S) -> TextEdit? {
        guard let end = preambleEnd(in: text) else { return nil }
        let preamble = ParsedPreamble(units: prefix(of: text, upTo: end))
        return preamble.edit(ensuring: requirements)
    }

    /// Kopiert den Anfang des Textes (die Präambel ist kurz, das geht schnell).
    private static func prefix<S: UTF16Source>(of text: S, upTo end: Int) -> [UInt16] {
        var units: [UInt16] = []
        units.reserveCapacity(end)
        for i in 0..<end { units.append(text[i]) }
        return units
    }
}

// MARK: - Bausteine der Präambel

/// Ein `\usepackage[…]{…}` bzw. `\RequirePackage[…]{…}`.
private struct PreambleLoad {
    /// Der ganze Befehl, vom Backslash bis zur letzten Klammer.
    var range: Range<Int>
    /// `[…]` inklusive Klammern, falls Optionen angegeben sind.
    var bracketRange: Range<Int>?
    /// Die Optionen, ohne Kommentare und Leerraum.
    var options: [String]
    /// Inhalt von `{…}` (ohne Klammern).
    var namesRange: Range<Int>
    /// Die Paketnamen, z. B. `["amsmath", "amssymb"]`.
    var names: [String]
    /// Steht der Befehl in einem `\ifxetex … \fi`, reicht dieser Bereich über die
    /// ganze Bedingung – davor oder danach darf eingefügt werden, mittendrin nicht.
    var outer: Range<Int>
}

/// `\documentclass[…]{…}`.
private struct PreambleClass {
    var bracketRange: Range<Int>?
    var options: [String]
    /// Inhalt von `{…}` (ohne Klammern).
    var nameRange: Range<Int>
    var name: String
}

/// Weitere Befehle, die für die Einstellungen zählen.
private enum PreambleCommand {
    /// `\onehalfspacing`, `\doublespacing`, `\singlespacing` (Paket setspace).
    case spacingSwitch(LineSpacing)
    /// `\linespread{1.3}` bzw. `\setstretch{1.5}`.
    case stretch(Double)
    /// `\renewcommand{\familydefault}{\sfdefault}`: Fliesstext ohne Serifen.
    case sansDefault
    /// `\setmainfont{…}` (fontspec).
    case mainFont(String)
    /// `\setsansfont{…}` (fontspec).
    case sansFont(String)
    /// `\geometry{…}` mit dem Bereich und den Angaben in den Klammern.
    case geometry(content: Range<Int>, options: [String])
    /// Definition einer Umgebung: `\newtheorem{satz}`, `\newenvironment{…}` …
    case environmentDefinition(String)
    /// `\theoremstyle{…}` oder `\newtheoremstyle{…}`.
    case theoremStyle
}

private struct PreambleHit {
    var command: PreambleCommand
    var range: Range<Int>
}

/// Eine geplante Änderung im Text der Präambel.
private struct PreambleChange {
    /// Bereich im alten Text (leer = Einfügen).
    var range: Range<Int>
    var text: String
    /// Steht danach in der Zeile nur noch Leerraum (bzw. ein Kommentar), fällt die ganze Zeile weg.
    var dropsEmptyLine = false
    /// Reihenfolge, wenn mehreres an derselben Stelle eingefügt wird.
    var order = 0
}

// MARK: - Bekannte Pakete und Schriften

private enum FontCatalog {
    /// Kommentar am Anfang eines Schrift-Blocks („% Schrift: Times“).
    static let fontMarker = "Schrift:"
    static let marginsMarker = "Seitenränder"
    static let spacingMarker = "Zeilenabstand"

    /// Pakete, die nur die serifenlose Schrift ändern (zählen nur mit `\familydefault`).
    static let helveticaSansPackages: Set<String> = ["helvet", "tgheros", "nimbussans"]

    /// Weitere Schrift-Pakete: Beim Wechsel der Schrift werden sie entfernt,
    /// damit sich nicht zwei Schriften (und ihre Formelzeichen) in die Quere kommen.
    static let otherFontPackages: Set<String> = [
        "newtxmath", "newpxmath", "libertinust1math", "mathdesign", "kpfonts", "kpfonts-otf",
        "fourier", "fouriernc", "utopia", "tgschola", "tgbonum", "bookman", "newcent", "cmbright",
        "ebgaramond", "garamondx", "baskervillef", "cochineal", "erewhon", "stix", "stix2",
        "sourceserifpro", "crimson", "crimsonpro", "charis", "mlmodern", "mathptm", "mathpple"
    ]

    /// Pakete, die möglichst spät geladen werden sollen. Neue Pakete kommen davor.
    static let latePackages: Set<String> = ["hyperref", "cleveref", "fontspec", "unicode-math"]

    /// TeX-Bedingungen, die mit `\fi` enden (etoolbox-Befehle wie `\ifdef{…}` gehören nicht dazu).
    static let conditionals: Set<String> = [
        "if", "ifx", "ifnum", "ifdim", "ifodd", "ifcase", "ifdefined", "ifcsname", "iftrue", "iffalse",
        "ifmmode", "ifvmode", "ifhmode", "ifinner", "ifeof", "ifvoid", "ifhbox", "ifvbox", "iffontchar",
        "ifPDFTeX", "ifXeTeX", "ifLuaTeX", "iftutex", "ifTUTeX", "ifeTeX", "ifpTeX", "ifupTeX",
        "ifpdftex", "ifxetex", "ifluatex", "ifpdf", "ifptex", "ifuptex"
    ]

    /// Welche Schrift lädt dieses Paket (für den Fliesstext)?
    static func font(forPackage name: String, options: [String]) -> DocumentFont? {
        switch name {
        case "newtxtext", "newtx", "mathptmx", "times", "tgtermes", "txfonts":
            return .times
        case "newtxmath":
            // newtxmath passt mit Optionen auch zu anderen Schriften.
            let lowered = Set(options.map { $0.lowercased() })
            if !lowered.isDisjoint(with: ["charter", "xcharter"]) { return .charter }
            if !lowered.isDisjoint(with: ["libertine", "libertinus"]) { return .libertinus }
            let others: Set<String> = [
                "minion", "cochineal", "garamondx", "ebgaramond", "baskerville", "baskervillef",
                "baskervaldx", "utopia", "heuristica", "erewhon", "noto", "notosans"
            ]
            return lowered.isDisjoint(with: others) ? .times : nil
        case "newpxtext", "newpx", "mathpazo", "palatino", "tgpagella", "pxfonts", "newpxmath":
            return .palatino
        case "XCharter", "xcharter", "charter":
            return .charter
        case "mathdesign":
            return options.contains("charter") ? .charter : nil
        case "libertinus", "libertinus-type1", "libertinus-otf", "libertine":
            return .libertinus
        case "lmodern":
            return .latinModern
        default:
            return nil
        }
    }

    /// Schrift zu einem Namen in `\setmainfont{…}` (Name oder Dateiname).
    static func font(forFontName name: String) -> DocumentFont? {
        let key = String(name.lowercased().unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) }.map(Character.init))
        let prefixes: [(String, DocumentFont)] = [
            ("texgyretermes", .times), ("timesnewroman", .times), ("times", .times), ("nimbusroman", .times),
            ("texgyrepagella", .palatino), ("palatino", .palatino), ("urwpalladio", .palatino),
            ("xcharter", .charter), ("bitstreamcharter", .charter), ("charter", .charter),
            ("libertinusserif", .libertinus), ("linuxlibertine", .libertinus),
            ("texgyreheros", .helvetica), ("helvetica", .helvetica), ("nimbussans", .helvetica),
            ("latinmodernroman", .latinModern), ("lmroman", .latinModern)
        ]
        return prefixes.first { key.hasPrefix($0.0) }?.1
    }

    /// Ist das ein Schrift-Paket, das beim Schriftwechsel weichen muss?
    static func isFontPackage(_ name: String, options: [String], includingSans: Bool) -> Bool {
        font(forPackage: name, options: options) != nil
            || otherFontPackages.contains(name)
            || (includingSans && helveticaSansPackages.contains(name))
    }

    /// Alle Zeilen aller Schrift-Blöcke (für Blöcke mit unbekanntem Titel).
    static let allBlockLines: Set<String> = Set(DocumentFont.allCases.flatMap { font in
        font.preambleLines.map { $0.trimmingCharacters(in: .whitespaces) }
    })

    /// Zeilenabstand zu einem Faktor aus `\linespread` bzw. `\setstretch`.
    static func spacing(forStretch value: Double) -> LineSpacing {
        if value < 1.15 { return .single }
        if value < 1.55 { return .onehalf }
        return .double
    }

    /// Länge in Zentimetern (`2cm`, `20mm`, `1in`, `56.9pt` …).
    static func centimeters(_ value: String) -> Double? {
        let text = value.trimmingCharacters(in: .whitespaces)
        let factors: [(String, Double)] = [("cm", 1), ("mm", 0.1), ("in", 2.54), ("bp", 2.54 / 72), ("pt", 2.54 / 72.27)]
        for (unit, factor) in factors where text.hasSuffix(unit) {
            let number = text.dropLast(unit.count).trimmingCharacters(in: .whitespaces)
            if let amount = Double(number) { return amount * factor }
        }
        return nil
    }

    /// Schlüssel von geometry, die die Grösse des Satzspiegels bzw. die Ränder festlegen.
    static let marginKeys: Set<String> = [
        "margin", "hmargin", "vmargin", "left", "right", "top", "bottom", "lmargin", "rmargin",
        "tmargin", "bmargin", "inner", "outer", "textwidth", "textheight", "width", "height",
        "total", "body", "text", "scale", "hscale", "vscale", "lines", "marginratio",
        "hmarginratio", "vmarginratio", "centering", "hcentering", "vcentering"
    ]

    /// Papierformat-Angaben von geometry bzw. der Dokumentklasse
    /// (`a4paper`, `paper=a4` – aber nicht `paper=landscape`).
    static func isPaperOption(_ option: String) -> Bool {
        let names: Set<String> = ["a3", "a4", "a5", "a6", "b4", "b5", "b6", "letter", "legal", "executive"]
        let key = optionKey(option)
        if key.hasSuffix("paper") && names.contains(String(key.dropLast("paper".count))) { return true }
        guard key == "paper" || key == "papername", var value = optionValue(option)?.lowercased() else { return false }
        if value.hasSuffix("paper") { value.removeLast("paper".count) }
        return names.contains(value)
    }

    /// `margin=2cm` → `margin`; `a4paper` → `a4paper`.
    static func optionKey(_ option: String) -> String {
        guard let equals = option.firstIndex(of: "=") else { return option }
        return option[..<equals].trimmingCharacters(in: .whitespaces)
    }

    /// `margin=2cm` → `2cm`.
    static func optionValue(_ option: String) -> String? {
        guard let equals = option.firstIndex(of: "=") else { return nil }
        return option[option.index(after: equals)...].trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - Zerlegte Präambel

/// Die Präambel als Folge von UTF-16-Einheiten, mit allem, was Lemma darin erkennt.
private struct ParsedPreamble {
    /// Der Text vom Anfang bis `\begin{document}` (ohne dieses).
    let units: [UInt16]
    /// Anfang der Zeile, in der `\begin{document}` steht. Alle Zeilen davor enden mit `\n`.
    let lineLimit: Int
    /// Steht `\begin{document}` am Zeilenanfang (nur Leerraum davor)?
    let beginsLine: Bool
    /// `\n` oder `\r\n`, wie im Dokument.
    let newline: String
    /// Die Zeilen vor `lineLimit` (ohne Zeilenumbruch).
    let lines: [Range<Int>]

    private(set) var documentClass: PreambleClass?
    private(set) var loads: [PreambleLoad] = []
    private(set) var hits: [PreambleHit] = []
    /// Zeilen der von Lemma geschriebenen Schrift-Blöcke (ganze Zeilen inklusive Zeilenumbruch).
    private(set) var fontBlockLines: [Range<Int>] = []
    /// Anfang jedes Schrift-Blocks (die Zeile mit „% Schrift: …“).
    private(set) var fontBlockStarts: [Int] = []

    var end: Int { units.count }

    init(units: [UInt16]) {
        self.units = units
        lineLimit = units.lineStart(before: units.count)
        beginsLine = (lineLimit..<units.count).allSatisfy { TeXChar.isWhitespace(units[$0]) }
        if let firstBreak = units.firstIndex(of: TeXChar.newline), firstBreak > 0,
           units[firstBreak - 1] == TeXChar.carriageReturn {
            newline = "\r\n"
        } else {
            newline = "\n"
        }
        var lines: [Range<Int>] = []
        var start = 0
        while start < lineLimit {
            let lineEnd = units.lineEnd(after: start)
            lines.append(start..<lineEnd)
            start = lineEnd + 1
        }
        self.lines = lines
        scanCommands()
        findFontBlocks()
    }

    // MARK: Lesen

    /// Text ohne Kommentare.
    func code(in range: Range<Int>) -> String {
        var result: [UInt16] = []
        var i = range.lowerBound
        while i < range.upperBound {
            if units[i] == TeXChar.percent && !units.isEscaped(at: i) {
                i = min(units.lineEnd(after: i), range.upperBound)
                continue
            }
            result.append(units[i])
            i += 1
        }
        return String(decoding: result, as: UTF16.self)
    }

    /// Teilt eine Liste an Kommas (nicht in geschweiften Klammern), ohne leere Einträge.
    static func splitList(_ list: String) -> [String] {
        var items: [String] = []
        var current = ""
        var depth = 0
        for character in list {
            switch character {
            case "{": depth += 1; current.append(character)
            case "}": depth -= 1; current.append(character)
            case "," where depth == 0:
                items.append(current)
                current = ""
            default: current.append(character)
            }
        }
        items.append(current)
        return items.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }

    /// Überspringt Leerraum und Kommentare.
    func skipSpace(from index: Int) -> Int {
        var i = index
        while i < end {
            let u = units[i]
            if TeXChar.isWhitespace(u) {
                i += 1
            } else if u == TeXChar.percent && !units.isEscaped(at: i) {
                i = units.lineEnd(after: i)
            } else {
                break
            }
        }
        return i
    }

    /// Eine Gruppe `{…}` oder `[…]` ab `index` (dort steht die öffnende Klammer).
    func group(at index: Int) -> (content: Range<Int>, end: Int)? {
        guard index < end else { return nil }
        let close: UInt16
        switch units[index] {
        case TeXChar.braceOpen: close = TeXChar.braceClose
        case TeXChar.bracketOpen: close = TeXChar.bracketClose
        default: return nil
        }
        var depth = 0
        var i = index + 1
        while i < end {
            let u = units[i]
            if u == TeXChar.backslash {
                i += 2
                continue
            }
            if u == TeXChar.percent {
                i = units.lineEnd(after: i)
                continue
            }
            if u == TeXChar.braceOpen {
                depth += 1
            } else if u == TeXChar.braceClose {
                if depth == 0 {
                    return close == TeXChar.braceClose ? ((index + 1)..<i, i + 1) : nil
                }
                depth -= 1
            } else if u == close && depth == 0 {
                return ((index + 1)..<i, i + 1)
            }
            i += 1
        }
        return nil
    }

    /// Name des Befehls ab dem Backslash an `index` und die Position dahinter.
    func commandName(at index: Int) -> (name: String, end: Int) {
        var i = index + 1
        while i < end && TeXChar.isASCIILetter(units[i]) { i += 1 }
        if i == index + 1 { return ("", min(end, index + 2)) }
        return (String(decoding: units[(index + 1)..<i], as: UTF16.self), i)
    }

    /// Ein Argument `{…}` nach Leerraum; liefert den Inhalt ohne Kommentare.
    func braceArgument(after index: Int) -> (content: Range<Int>, text: String, end: Int)? {
        let start = skipSpace(from: index)
        guard start < end, units[start] == TeXChar.braceOpen, let group = group(at: start) else { return nil }
        return (group.content, code(in: group.content).trimmingCharacters(in: .whitespacesAndNewlines), group.end)
    }

    /// Optionales `[…]` nach Leerraum.
    func optionalArgument(after index: Int) -> (range: Range<Int>, content: Range<Int>, end: Int)? {
        let start = skipSpace(from: index)
        guard start < end, units[start] == TeXChar.bracketOpen, let group = group(at: start) else { return nil }
        return (start..<group.end, group.content, group.end)
    }

    // MARK: Befehle finden

    private mutating func scanCommands() {
        // Verschachtelung von \if… \fi, damit nie mitten in eine Bedingung eingefügt wird.
        var depth = 0
        var conditionals = FontCatalog.conditionals
        var previous = ""
        var openings: [Int] = []                          // Beginn einer äussersten Bedingung
        var closings: [Int] = []                          // Ende des \fi, das sie schliesst
        var loadDepths: [Int] = []
        var i = 0
        while i < end {
            let u = units[i]
            if u == TeXChar.percent && !units.isEscaped(at: i) {
                i = units.lineEnd(after: i)
                continue
            }
            guard u == TeXChar.backslash else {
                i += 1
                continue
            }
            let (name, afterName) = commandName(at: i)
            if previous == "newif" {
                conditionals.insert(name)                 // \newif\ifentwurf: nur eine Erklärung
            } else if conditionals.contains(name) {
                if depth == 0 { openings.append(i) }
                depth += 1
            } else if name == "fi" && depth > 0 {
                depth -= 1
                if depth == 0 { closings.append(afterName) }
            }
            previous = name
            let loadCount = loads.count
            i = scanCommand(name, start: i, afterName: afterName) ?? afterName
            if loads.count > loadCount { loadDepths.append(depth) }
        }
        for index in loads.indices where loadDepths[index] > 0 {
            let load = loads[index]
            if let opening = openings.last(where: { $0 < load.range.lowerBound }),
               let closing = closings.first(where: { $0 >= load.range.upperBound }) {
                loads[index].outer = opening..<closing
            }
        }
    }

    /// Wertet einen Befehl aus; liefert die Position dahinter (oder `nil`, wenn er nicht zählt).
    private mutating func scanCommand(_ name: String, start: Int, afterName: Int) -> Int? {
        switch name {
        case "documentclass" where documentClass == nil:
            let options = optionalArgument(after: afterName)
            guard let argument = braceArgument(after: options?.end ?? afterName) else { return nil }
            documentClass = PreambleClass(
                bracketRange: options?.range,
                options: options.map { Self.splitList(code(in: $0.content)) } ?? [],
                nameRange: argument.content,
                name: argument.text
            )
            return argument.end
        case "usepackage", "RequirePackage":
            let options = optionalArgument(after: afterName)
            guard let argument = braceArgument(after: options?.end ?? afterName) else { return nil }
            var commandEnd = argument.end
            // Eine Versionsangabe wie [2020/01/01] gehört noch zum Befehl.
            var j = commandEnd
            while j < end && (units[j] == TeXChar.space || units[j] == TeXChar.tab) { j += 1 }
            if j < end, units[j] == TeXChar.bracketOpen, let date = group(at: j) { commandEnd = date.end }
            loads.append(PreambleLoad(
                range: start..<commandEnd,
                bracketRange: options?.range,
                options: options.map { Self.splitList(code(in: $0.content)) } ?? [],
                namesRange: argument.content,
                names: Self.splitList(argument.text),
                outer: start..<commandEnd
            ))
            return commandEnd
        case "onehalfspacing":
            hits.append(PreambleHit(command: .spacingSwitch(.onehalf), range: start..<afterName))
        case "doublespacing":
            hits.append(PreambleHit(command: .spacingSwitch(.double), range: start..<afterName))
        case "singlespacing":
            hits.append(PreambleHit(command: .spacingSwitch(.single), range: start..<afterName))
        case "linespread", "setstretch":
            guard let argument = braceArgument(after: afterName) else { return nil }
            if let value = Double(argument.text) {
                hits.append(PreambleHit(command: .stretch(value), range: start..<argument.end))
            }
            return argument.end
        case "renewcommand":
            return scanFamilyDefault(start: start, afterName: afterName)
        case "setmainfont", "setsansfont":
            let before = optionalArgument(after: afterName)
            guard let argument = braceArgument(after: before?.end ?? afterName) else { return nil }
            var commandEnd = argument.end
            // fontspec erlaubt die Optionen auch hinter dem Namen.
            let next = skipSpace(from: commandEnd)
            if next < end, units[next] == TeXChar.bracketOpen, let after = group(at: next) { commandEnd = after.end }
            let command: PreambleCommand = name == "setmainfont" ? .mainFont(argument.text) : .sansFont(argument.text)
            hits.append(PreambleHit(command: command, range: start..<commandEnd))
            return commandEnd
        case "geometry":
            guard let argument = braceArgument(after: afterName) else { return nil }
            hits.append(PreambleHit(
                command: .geometry(content: argument.content, options: Self.splitList(argument.text)),
                range: start..<argument.end
            ))
            return argument.end
        case "newtheorem", "declaretheorem", "newenvironment", "renewenvironment", "NewDocumentEnvironment":
            var j = afterName
            if j < end && units[j] == TeXChar.star { j += 1 }
            if let options = optionalArgument(after: j) { j = options.end }
            guard let argument = braceArgument(after: j) else { return nil }
            hits.append(PreambleHit(command: .environmentDefinition(argument.text), range: start..<argument.end))
            return argument.end
        case "theoremstyle", "newtheoremstyle":
            guard let argument = braceArgument(after: afterName) else { return nil }
            hits.append(PreambleHit(command: .theoremStyle, range: start..<argument.end))
            return argument.end
        default:
            return nil
        }
        return afterName
    }

    /// `\renewcommand{\familydefault}{\sfdefault}` (auch mit `*` oder ohne Klammern).
    private mutating func scanFamilyDefault(start: Int, afterName: Int) -> Int? {
        var j = afterName
        if j < end && units[j] == TeXChar.star { j += 1 }
        func macro(after index: Int) -> (name: String, end: Int)? {
            let position = skipSpace(from: index)
            guard position < end else { return nil }
            if units[position] == TeXChar.backslash {
                let command = commandName(at: position)
                return ("\\" + command.name, command.end)
            }
            guard let argument = braceArgument(after: position) else { return nil }
            return (argument.text, argument.end)
        }
        guard let target = macro(after: j), target.name == "\\familydefault",
              let value = macro(after: target.end), value.name == "\\sfdefault" else { return nil }
        hits.append(PreambleHit(command: .sansDefault, range: start..<value.end))
        return value.end
    }

    /// Sucht die Zeilen mit „% Schrift: …“ und die dazugehörigen Zeilen darunter.
    private mutating func findFontBlocks() {
        var index = 0
        while index < lines.count {
            let line = lines[index]
            guard let title = markerText(inLine: line, prefix: FontCatalog.fontMarker),
                  !code(in: line).trimmingCharacters(in: .whitespaces).isEmpty else {
                index += 1
                continue
            }
            let font = DocumentFont.allCases.first { $0.title == title }
            let expected = font?.preambleLines.map { $0.trimmingCharacters(in: .whitespaces) }
            fontBlockStarts.append(line.lowerBound)
            fontBlockLines.append(line.lowerBound..<(line.upperBound + 1))
            // Die übrigen Zeilen des Blocks der Reihe nach suchen. Kommentare und bis zu
            // zwei eigene Zeilen dazwischen bleiben stehen und gehören nicht zum Block –
            // so bleibt z. B. von einem \ifPDFTeX … \fi nie nur die Hälfte übrig.
            var nextExpected = 1
            var foreign = 0
            var next = index + 1
            let limit = min(lines.count, index + (expected?.count ?? 0) + 3)
            while next < lines.count {
                if let expected, nextExpected >= expected.count || next >= limit { break }
                let range = lines[next]
                guard markerText(inLine: range, prefix: FontCatalog.fontMarker) == nil else { break }
                let text = String(decoding: units[range], as: UTF16.self).trimmingCharacters(in: .whitespacesAndNewlines)
                let matches = expected.map { text == $0[nextExpected] } ?? FontCatalog.allBlockLines.contains(text)
                if matches {
                    fontBlockLines.append(range.lowerBound..<(range.upperBound + 1))
                    nextExpected += 1
                    foreign = 0
                } else if expected == nil {
                    break
                } else if !code(in: range).trimmingCharacters(in: .whitespaces).isEmpty {
                    foreign += 1
                    if foreign > 2 { break }
                }
                next += 1
            }
            index += 1
        }
    }

    /// Text des Kommentars einer Zeile nach `prefix` (z. B. „Times“ bei „% Schrift: Times“).
    func markerText(inLine line: Range<Int>, prefix: String) -> String? {
        guard let comment = units.commentStart(inLineStartingAt: line.lowerBound), comment < line.upperBound else { return nil }
        let text = String(decoding: units[(comment + 1)..<line.upperBound], as: UTF16.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.hasPrefix(prefix) else { return nil }
        return text.dropFirst(prefix.count).trimmingCharacters(in: .whitespaces)
    }

    func isInFontBlock(_ position: Int) -> Bool {
        fontBlockLines.contains { $0.contains(position) }
    }

    // MARK: Einstellungen lesen

    func isLoaded(_ package: String) -> Bool {
        loads.contains { $0.names.contains(package) }
    }

    var settings: DocumentSettings {
        var settings = DocumentSettings(documentClass: documentClass?.name)
        for option in documentClass?.options ?? [] {
            if let size = Self.fontSize(of: option), [10, 11, 12].contains(size) {
                settings.baseFontSize = size
            } else if Self.fontSize(of: option) != nil {
                settings.baseFontSize = nil
            }
            if let paper = Self.paperSize(of: option) {
                settings.paperSize = paper
            } else if FontCatalog.isPaperOption(option) {
                settings.paperSize = nil
            }
        }
        settings.font = currentFont
        settings.margins = currentMargins
        settings.lineSpacing = currentSpacing
        return settings
    }

    /// `11pt` bzw. `fontsize=11pt` → 11. Andere Grössen wie `11.5pt` → 0 (eine Grösse, aber keine der drei).
    static func fontSize(of option: String) -> Int? {
        var text = option
        if FontCatalog.optionKey(option) == "fontsize", let value = FontCatalog.optionValue(option) { text = value }
        guard text.hasSuffix("pt") else { return nil }
        let number = text.dropLast(2).trimmingCharacters(in: .whitespaces)
        if let size = Int(number) { return size }
        return Double(number) == nil ? nil : 0
    }

    /// `a4paper` bzw. `paper=a4` (KOMA-Script) → `.a4paper`.
    static func paperSize(of option: String) -> PaperSize? {
        if let paper = PaperSize(rawValue: option) { return paper }
        if FontCatalog.optionKey(option) == "paper", let value = FontCatalog.optionValue(option)?.lowercased() {
            return PaperSize(rawValue: value.hasSuffix("paper") ? value : value + "paper")
        }
        return nil
    }

    var currentFont: DocumentFont {
        var best: (position: Int, font: DocumentFont)?
        func consider(_ font: DocumentFont, at position: Int) {
            if best == nil || position >= best!.position { best = (position, font) }
        }
        var sansFont: Int?
        var sansDefault: Int?
        for load in loads {
            for name in load.names {
                if let font = FontCatalog.font(forPackage: name, options: load.options) {
                    consider(font, at: load.range.lowerBound)
                }
                if FontCatalog.helveticaSansPackages.contains(name) { sansFont = load.range.lowerBound }
            }
        }
        for hit in hits {
            switch hit.command {
            case .mainFont(let name):
                if let font = FontCatalog.font(forFontName: name) { consider(font, at: hit.range.lowerBound) }
            case .sansFont(let name):
                if FontCatalog.font(forFontName: name) == .helvetica { sansFont = hit.range.lowerBound }
            case .sansDefault:
                sansDefault = hit.range.lowerBound
            default:
                break
            }
        }
        // Helvetica als Hauptschrift: serifenlose Schrift ist Helvetica *und* Standard für den Text.
        if let sansDefault, let sansFont { consider(.helvetica, at: max(sansDefault, sansFont)) }
        return best?.font ?? .latinModern
    }

    /// Alle Stellen mit geometry-Angaben: das Paket selbst und `\geometry{…}`.
    var geometrySources: [(options: [String], position: Int)] {
        var sources: [(options: [String], position: Int)] = []
        for load in loads where load.names.contains("geometry") {
            sources.append((load.options, load.range.lowerBound))
        }
        for hit in hits {
            if case .geometry(_, let options) = hit.command { sources.append((options, hit.range.lowerBound)) }
        }
        return sources.sorted { $0.position < $1.position }
    }

    var currentMargins: PageMargins {
        guard isLoaded("geometry") else { return .standard }
        var left: Double?, right: Double?, top: Double?, bottom: Double?
        var custom = false
        for source in geometrySources {
            for option in source.options {
                let key = FontCatalog.optionKey(option)
                guard FontCatalog.marginKeys.contains(key) else { continue }
                let value = FontCatalog.optionValue(option).flatMap(FontCatalog.centimeters)
                switch key {
                case "margin": (left, right, top, bottom) = (value, value, value, value)
                case "hmargin": (left, right) = (value, value)
                case "vmargin": (top, bottom) = (value, value)
                case "left", "lmargin", "inner": left = value
                case "right", "rmargin", "outer": right = value
                case "top", "tmargin": top = value
                case "bottom", "bmargin": bottom = value
                default: custom = true
                }
            }
        }
        guard !custom, let left, let right, let top, let bottom,
              max(left, right, top, bottom) - min(left, right, top, bottom) < 0.01 else { return .standard }
        let candidates: [(Double, PageMargins)] = [(2, .narrow), (2.5, .normal), (3.5, .wide)]
        return candidates.first { abs($0.0 - left) < 0.01 }?.1 ?? .standard
    }

    /// Alle Angaben zum Zeilenabstand, in der Reihenfolge im Text.
    var spacingSources: [(spacing: LineSpacing, position: Int)] {
        var sources: [(spacing: LineSpacing, position: Int)] = []
        for load in loads where load.names.contains("setspace") {
            for option in load.options {
                if let spacing = Self.spacing(forSetspaceOption: option) { sources.append((spacing, load.range.lowerBound)) }
            }
        }
        for hit in hits {
            switch hit.command {
            case .spacingSwitch(let spacing): sources.append((spacing, hit.range.lowerBound))
            case .stretch(let value): sources.append((FontCatalog.spacing(forStretch: value), hit.range.lowerBound))
            default: break
            }
        }
        return sources.sorted { $0.position < $1.position }
    }

    static func spacing(forSetspaceOption option: String) -> LineSpacing? {
        switch option {
        case "singlespacing": return .single
        case "onehalfspacing": return .onehalf
        case "doublespacing": return .double
        default: return nil
        }
    }

    var currentSpacing: LineSpacing {
        spacingSources.last?.spacing ?? .single
    }

    // MARK: Einfügestellen

    /// Anfang der Zeile nach dem Befehl in `range`; `nil`, wenn der Befehl in der Zeile von `\begin{document}` endet.
    func lineStart(after range: Range<Int>) -> Int? {
        let lineEnd = units.lineEnd(after: max(range.lowerBound, range.upperBound - 1))
        guard lineEnd < lineLimit else { return nil }
        return lineEnd + 1
    }

    /// Direkt vor `\begin{document}`.
    var fallbackPosition: Int { beginsLine ? lineLimit : end }

    /// Gehört dieses Paket ans Ende der Pakete (Schriften, hyperref …)?
    func isLate(_ load: PreambleLoad) -> Bool {
        isInFontBlock(load.range.lowerBound) || load.names.contains { name in
            FontCatalog.latePackages.contains(name)
                || FontCatalog.isFontPackage(name, options: load.options, includingSans: true)
        }
    }

    /// Wohin neue Pakete kommen: nach dem letzten `\usepackage`, aber vor Schriften
    /// und hyperref. Schrift-Pakete wie newtxmath vertragen kein amssymb danach.
    var packageInsertionPoint: Int {
        let lateStarts = loads.filter(isLate).map(\.outer.lowerBound) + fontBlockStarts
        if let firstLate = lateStarts.min() {
            let earlier = loads.filter { !isLate($0) && $0.outer.upperBound <= firstLate }
            if let last = earlier.last, let position = lineStart(after: last.outer), position <= firstLate {
                return position
            }
            return min(units.lineStart(before: firstLate), fallbackPosition)
        }
        if let last = loads.last, let position = lineStart(after: last.outer) { return position }
        return fallbackPosition
    }

    /// Fügt ganze Zeilen an `position` ein.
    func insertion(_ newLines: [String], at position: Int, order: Int) -> PreambleChange {
        let text: String
        if position == end && !beginsLine {
            // \begin{document} steht mitten in einer Zeile: eigene Zeilen davor.
            text = newline + newLines.joined(separator: newline) + newline
        } else {
            text = newLines.map { $0 + newline }.joined()
        }
        return PreambleChange(range: position..<position, text: text, order: order)
    }

    /// Entfernt einen Befehl; bleibt die Zeile leer, verschwindet sie ganz.
    func removal(of range: Range<Int>) -> PreambleChange {
        PreambleChange(range: range, text: "", dropsEmptyLine: true)
    }

    /// Schreibt eine Optionsliste `[…]` neu (fügt sie ein bzw. entfernt sie, wenn sie leer wird).
    func optionsChange(bracket: Range<Int>?, before braceContent: Range<Int>, options: [String]) -> PreambleChange {
        let separator = bracket.map { String(decoding: units[$0], as: UTF16.self).contains(", ") ? ", " : "," } ?? ","
        let replacement = options.isEmpty ? "" : "[" + options.joined(separator: separator) + "]"
        if let bracket { return PreambleChange(range: bracket, text: replacement) }
        let brace = braceContent.lowerBound - 1
        return PreambleChange(range: brace..<brace, text: replacement)
    }

    /// Entfernt einzelne Namen aus `\usepackage{a,b,c}` (oder den ganzen Befehl).
    /// Wer mehrere Namen aus derselben Zeile entfernen will, sammelt sie zuerst
    /// (siehe `nameRemovals`), damit keine zwei Änderungen denselben Bereich treffen.
    func removingNames(_ names: Set<String>, from load: PreambleLoad) -> PreambleChange {
        let remaining = load.names.filter { !names.contains($0) }
        if remaining.isEmpty { return removal(of: load.range) }
        let original = String(decoding: units[load.namesRange], as: UTF16.self)
        return PreambleChange(range: load.namesRange, text: remaining.joined(separator: original.contains(", ") ? ", " : ","))
    }
}

// MARK: - Einstellungen schreiben

extension ParsedPreamble {
    /// Reihenfolge, wenn an derselben Stelle mehreres eingefügt wird.
    private enum InsertOrder {
        static let packages = 10
        static let spacing = 11
        static let font = 20
        static let lines = 30
    }

    func edit(applying target: DocumentSettings) -> TextEdit? {
        let current = settings
        var changes: [PreambleChange] = []
        // Paketnamen, die aus einer Liste wie \usepackage{geometry,mathptmx} wegfallen
        // (pro Zeile gesammelt, damit es nur eine Änderung pro Liste gibt).
        var nameRemovals: [Int: Set<String>] = [:]
        changes += classChanges(to: target, from: current)
        changes += geometryChanges(to: target, from: current, nameRemovals: &nameRemovals)
        changes += spacingChanges(to: target.lineSpacing, from: current.lineSpacing)
        changes += fontChanges(to: target.font, from: current.font, nameRemovals: &nameRemovals)
        for (index, names) in nameRemovals.sorted(by: { $0.key < $1.key }) {
            changes.append(removingNames(names, from: loads[index]))
        }
        return combine(changes)
    }

    /// Klassenname, Grundschriftgrösse und Papier in `\documentclass[…]{…}`.
    private func classChanges(to target: DocumentSettings, from current: DocumentSettings) -> [PreambleChange] {
        guard let declaration = documentClass else { return [] }
        var changes: [PreambleChange] = []
        if let name = target.documentClass, !name.isEmpty, name != declaration.name {
            changes.append(PreambleChange(range: declaration.nameRange, text: name))
        }
        var options = declaration.options
        if target.baseFontSize != current.baseFontSize {
            let isSize: (String) -> Bool = { Self.fontSize(of: $0) != nil }
            if let size = target.baseFontSize {
                if let first = options.firstIndex(where: isSize) {
                    options[first] = FontCatalog.optionKey(options[first]) == "fontsize" ? "fontsize=\(size)pt" : "\(size)pt"
                    options = options.enumerated().filter { $0.offset == first || !isSize($0.element) }.map(\.element)
                } else {
                    options.append("\(size)pt")
                }
            } else {
                options.removeAll { [10, 11, 12].contains(Self.fontSize(of: $0) ?? 0) }
            }
        }
        if target.paperSize != current.paperSize {
            let isPaper: (String) -> Bool = { Self.paperSize(of: $0) != nil }
            if let paper = target.paperSize {
                if let first = options.firstIndex(where: FontCatalog.isPaperOption) {
                    // KOMA-Script schreibt paper=a4, die Standardklassen a4paper.
                    options[first] = FontCatalog.optionKey(options[first]) == "paper"
                        ? "paper=" + paper.rawValue.dropLast("paper".count)
                        : paper.rawValue
                    options = options.enumerated().filter { $0.offset == first || !isPaper($0.element) }.map(\.element)
                } else {
                    options.append(paper.rawValue)
                }
            } else {
                options.removeAll(where: isPaper)
            }
        }
        if options != declaration.options {
            changes.append(optionsChange(bracket: declaration.bracketRange, before: declaration.nameRange, options: options))
        }
        return changes
    }

    /// Papierangabe in den geometry-Optionen anpassen (nur, wenn dort schon eine steht).
    private func adjustingPaper(_ options: [String], to paper: PaperSize?) -> [String] {
        guard let first = options.firstIndex(where: FontCatalog.isPaperOption) else { return options }
        guard let paper else { return options.filter { !FontCatalog.isPaperOption($0) } }
        var result = options
        let key = FontCatalog.optionKey(result[first])
        result[first] = key == "paper" || key == "papername" ? "\(key)=\(paper.rawValue)" : paper.rawValue
        return result.enumerated().filter { $0.offset == first || !FontCatalog.isPaperOption($0.element) }.map(\.element)
    }

    /// Seitenränder (und eine Papierangabe bei geometry, damit sie nicht der Klasse widerspricht).
    private func geometryChanges(
        to target: DocumentSettings,
        from current: DocumentSettings,
        nameRemovals: inout [Int: Set<String>]
    ) -> [PreambleChange] {
        let marginsChange = target.margins != current.margins
        let paperChange = documentClass != nil && target.paperSize != current.paperSize
        guard marginsChange || paperChange else { return [] }
        let isMarginOption: (String) -> Bool = { FontCatalog.marginKeys.contains(FontCatalog.optionKey($0)) }
        var changes: [PreambleChange] = []
        var marginWritten = false
        for load in loads where load.names.contains("geometry") {
            var options = load.options
            if marginsChange { options.removeAll(where: isMarginOption) }
            if paperChange { options = adjustingPaper(options, to: target.paperSize) }
            let canHoldOptions = load.names == ["geometry"] || load.bracketRange != nil
            if marginsChange, let margin = target.margins.geometryOptions, !marginWritten, canHoldOptions {
                options.insert(margin, at: 0)
                marginWritten = true
            }
            guard options != load.options else { continue }
            if options.isEmpty && marginsChange && load.names == ["geometry"] {
                // Standard-Ränder: geometry ganz weglassen.
                changes.append(removal(of: load.range))
            } else {
                changes.append(optionsChange(bracket: load.bracketRange, before: load.namesRange, options: options))
            }
        }
        for hit in hits {
            guard case .geometry(let content, let options) = hit.command else { continue }
            var adjusted = options
            if marginsChange { adjusted.removeAll(where: isMarginOption) }
            if paperChange { adjusted = adjustingPaper(adjusted, to: target.paperSize) }
            guard adjusted != options else { continue }
            if adjusted.isEmpty {
                changes.append(removal(of: hit.range))
            } else {
                let separator = String(decoding: units[content], as: UTF16.self).contains(", ") ? ", " : ","
                changes.append(PreambleChange(range: content, text: adjusted.joined(separator: separator)))
            }
        }
        if marginsChange, let margin = target.margins.geometryOptions, !marginWritten {
            // geometry steckt in einer Liste wie \usepackage{geometry,xcolor}: dort herausnehmen,
            // sonst gäbe es einen Optionen-Konflikt mit der neuen Zeile.
            for (index, load) in loads.enumerated() where load.names.contains("geometry") {
                nameRemovals[index, default: []].insert("geometry")
            }
            changes.append(insertion(
                ["\\usepackage[\(margin)]{geometry} % \(FontCatalog.marginsMarker)"],
                at: packageInsertionPoint,
                order: InsertOrder.packages
            ))
        }
        return changes
    }

    /// Steht in der Zeile von `position` der Kommentar `marker`?
    private func lineHasMarker(at position: Int, _ marker: String) -> Bool {
        let line = units.lineStart(before: position)..<units.lineEnd(after: position)
        return markerText(inLine: line, prefix: marker) != nil
    }

    /// Zeilenabstand über setspace.
    private func spacingChanges(to target: LineSpacing, from current: LineSpacing) -> [PreambleChange] {
        guard target != current else { return [] }
        var changes: [PreambleChange] = []
        var switches: [PreambleHit] = []
        for hit in hits {
            switch hit.command {
            case .spacingSwitch: switches.append(hit)
            case .stretch: changes.append(removal(of: hit.range))   // \linespread & Co. ersetzt setspace
            default: break
            }
        }
        let setspaceLoads = loads.filter { $0.names.contains("setspace") }
        /// Entfernt Abstands-Optionen wie [onehalfspacing] aus den setspace-Zeilen.
        func clearingOptions(except kept: PreambleLoad? = nil, removeManaged: Bool) -> [PreambleChange] {
            setspaceLoads.compactMap { load in
                guard load.range != kept?.range else { return nil }
                let options = load.options.filter { Self.spacing(forSetspaceOption: $0) == nil }
                guard options != load.options else { return nil }
                if removeManaged && options.isEmpty && load.names == ["setspace"]
                    && lineHasMarker(at: load.range.lowerBound, FontCatalog.spacingMarker) {
                    return removal(of: load.range)
                }
                return optionsChange(bracket: load.bracketRange, before: load.namesRange, options: options)
            }
        }
        if target == .single {
            changes += switches.map { removal(of: $0.range) }
            changes += clearingOptions(removeManaged: true)
            return changes
        }
        let command = target == .onehalf ? "\\onehalfspacing" : "\\doublespacing"
        let option = target == .onehalf ? "onehalfspacing" : "doublespacing"
        if let last = switches.last {
            // Von Hand geschriebenes \onehalfspacing: an Ort und Stelle austauschen.
            changes.append(PreambleChange(range: last.range, text: command))
            changes += switches.dropLast().map { removal(of: $0.range) }
            changes += clearingOptions(removeManaged: false)
        } else if let load = setspaceLoads.first(where: { $0.names == ["setspace"] || $0.bracketRange != nil }) {
            var options = load.options.filter { Self.spacing(forSetspaceOption: $0) == nil }
            options.insert(option, at: 0)
            changes.append(optionsChange(bracket: load.bracketRange, before: load.namesRange, options: options))
            changes += clearingOptions(except: load, removeManaged: false)
        } else if let load = setspaceLoads.first, let position = lineStart(after: load.outer) {
            // setspace steckt in einer Liste: den Befehl direkt danach setzen.
            changes.append(insertion(["\(command) % \(FontCatalog.spacingMarker)"], at: position, order: InsertOrder.spacing))
        } else {
            changes.append(insertion(
                ["\\usepackage[\(option)]{setspace} % \(FontCatalog.spacingMarker)"],
                at: packageInsertionPoint,
                order: InsertOrder.spacing
            ))
        }
        return changes
    }

    /// Schrift: alte Schrift-Zeilen entfernen, neuen Block nach dem letzten \usepackage einfügen.
    private func fontChanges(
        to target: DocumentFont,
        from current: DocumentFont,
        nameRemovals: inout [Int: Set<String>]
    ) -> [PreambleChange] {
        guard target != current else { return [] }
        var changes = fontBlockLines.map { PreambleChange(range: $0, text: "") }
        // Helvetica-Pakete nur entfernen, wenn sie die Hauptschrift stellen
        // (sonst wählen sie nur die serifenlose Nebenschrift, z. B. zu Times).
        let includeSans = current == .helvetica
        var removedLoads = Set<Int>()
        for (index, load) in loads.enumerated() where !isInFontBlock(load.range.lowerBound) {
            let fontNames = Set(load.names.filter {
                FontCatalog.isFontPackage($0, options: load.options, includingSans: includeSans)
            })
            guard !fontNames.isEmpty else { continue }
            nameRemovals[index, default: []].formUnion(fontNames)
            if nameRemovals[index, default: []].isSuperset(of: load.names) { removedLoads.insert(index) }
        }
        for hit in hits where !isInFontBlock(hit.range.lowerBound) {
            switch hit.command {
            case .mainFont, .sansDefault:
                changes.append(removal(of: hit.range))
            case .sansFont where includeSans:
                changes.append(removal(of: hit.range))
            default:
                break
            }
        }
        var block = target.preambleLines
        if !block.isEmpty {
            block[0] += " % \(FontCatalog.fontMarker) \(target.title)"
            // Nach dem letzten verbleibenden \usepackage: Schriften wie newtxmath
            // müssen nach amsmath/amssymb geladen werden.
            let surviving = loads.enumerated().filter {
                !isInFontBlock($0.element.range.lowerBound) && !removedLoads.contains($0.offset)
            }
            let position = surviving.last.flatMap { lineStart(after: $0.element.outer) } ?? fallbackPosition
            changes.append(insertion(block, at: position, order: InsertOrder.font))
        }
        return changes
    }

    // MARK: Pakete ergänzen

    func edit(ensuring requirements: [PackageRequirement]) -> TextEdit? {
        // Mehrere Anforderungen an dasselbe Paket zusammenfassen (z. B. amsthm für
        // den Beweis und amsthm mit Satz-Umgebungen): ein \usepackage, alle Zeilen.
        var merged: [PackageRequirement] = []
        for requirement in requirements {
            if let index = merged.firstIndex(where: { $0.name == requirement.name }) {
                if (merged[index].options ?? "").isEmpty, let options = requirement.options, !options.isEmpty {
                    merged[index].options = options
                }
                merged[index].preambleLines += requirement.preambleLines
            } else {
                merged.append(requirement)
            }
        }

        var defined = Set<String>()
        var definitionLineStarts: [Int] = []
        for hit in hits {
            switch hit.command {
            case .environmentDefinition(let name):
                defined.insert(name)
                if let position = lineStart(after: hit.range) { definitionLineStarts.append(position) }
            case .theoremStyle:
                if let position = lineStart(after: hit.range) { definitionLineStarts.append(position) }
            default:
                break
            }
        }
        var present = Set<String>()
        for line in lines {
            present.insert(String(decoding: units[line], as: UTF16.self).trimmingCharacters(in: .whitespacesAndNewlines))
            present.insert(code(in: line).trimmingCharacters(in: .whitespacesAndNewlines))
        }

        let packagePoint = packageInsertionPoint
        // Neue Satz-Definitionen kommen nach den vorhandenen, damit ein \theoremstyle
        // aus den neuen Zeilen die alten nicht verändert.
        let afterDefinitions = definitionLineStarts.max() ?? packagePoint
        var newPackages: [String] = []
        var lineGroups: [(position: Int, lines: [String])] = []
        for requirement in merged {
            var position = max(packagePoint, afterDefinitions)
            if let load = loads.first(where: { $0.names.contains(requirement.name) }) {
                if let after = lineStart(after: load.outer) { position = max(position, after) }
            } else {
                newPackages.append(requirement.usepackageLine)
            }
            let missing = missingLines(requirement.preambleLines, present: &present, defined: &defined)
            guard !missing.isEmpty else { continue }
            if let index = lineGroups.firstIndex(where: { $0.position == position }) {
                lineGroups[index].lines += missing
            } else {
                lineGroups.append((position, missing))
            }
        }

        var changes: [PreambleChange] = []
        if !newPackages.isEmpty {
            changes.append(insertion(newPackages, at: packagePoint, order: InsertOrder.packages))
        }
        for (offset, group) in lineGroups.enumerated() {
            changes.append(insertion(group.lines, at: group.position, order: InsertOrder.lines + offset))
        }
        return combine(changes)
    }

    /// Die fehlenden Präambel-Zeilen. Zu einer fehlenden Satz-Definition kommt der
    /// passende `\theoremstyle` mit, damit z. B. „Bemerkung“ ihren Stil behält.
    private func missingLines(_ wanted: [String], present: inout Set<String>, defined: inout Set<String>) -> [String] {
        var result: [String] = []
        var style: String?
        var styleWritten = false
        for raw in wanted {
            let line = raw.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { continue }
            if line.hasPrefix("\\theoremstyle") {
                style = raw
                styleWritten = false
                continue
            }
            if let name = Self.theoremName(in: line) {
                guard !defined.contains(name) else { continue }
                defined.insert(name)
            } else {
                guard !present.contains(line) else { continue }
            }
            present.insert(line)
            if let style, !styleWritten {
                result.append(style)
                styleWritten = true
            }
            result.append(raw)
        }
        return result
    }

    /// `\newtheorem{satz}{Satz}` bzw. `\newtheorem*{bemerkung}{…}` → Name der Umgebung.
    static func theoremName(in line: String) -> String? {
        guard line.hasPrefix("\\newtheorem") else { return nil }
        var rest = line.dropFirst("\\newtheorem".count)
        if rest.first == "*" { rest = rest.dropFirst() }
        rest = rest.drop { $0 == " " }
        guard rest.first == "{", let close = rest.firstIndex(of: "}") else { return nil }
        return rest[rest.index(after: rest.startIndex)..<close].trimmingCharacters(in: .whitespaces)
    }

    // MARK: Zu einer TextEdit zusammenfassen

    /// Fasst alle Änderungen zu *einer* zusammenhängenden Ersetzung zusammen.
    /// Zeilen, in denen nach dem Entfernen nur Leerraum (oder ein Kommentar) bleibt, fallen ganz weg.
    func combine(_ changes: [PreambleChange]) -> TextEdit? {
        guard !changes.isEmpty else { return nil }

        // 1. Betroffene Zeilen (vom Zeilenanfang bis zum Zeilenumbruch) der Änderungen,
        //    die eine Zeile leeren können – über mehrere Zeilen reichende Änderungen gehören dazu.
        func lineSpan(of range: Range<Int>) -> ClosedRange<Int> {
            units.lineStart(before: range.lowerBound)...units.lineEnd(after: max(range.lowerBound, range.upperBound - 1))
        }
        var spans = changes.filter(\.dropsEmptyLine).map { lineSpan(of: $0.range) }
        var grew = true
        while grew {
            grew = false
            spans.sort { $0.lowerBound < $1.lowerBound }
            var merged: [ClosedRange<Int>] = []
            for span in spans {
                if let last = merged.last, span.lowerBound <= last.upperBound {
                    merged[merged.count - 1] = last.lowerBound...max(last.upperBound, span.upperBound)
                } else {
                    merged.append(span)
                }
            }
            for index in merged.indices {
                for change in changes where !change.range.isEmpty {
                    let span = merged[index]
                    let overlaps = change.range.lowerBound <= span.upperBound && change.range.upperBound > span.lowerBound
                    let inside = change.range.lowerBound >= span.lowerBound && change.range.upperBound <= span.upperBound + 1
                    if overlaps && !inside {
                        let other = lineSpan(of: change.range)
                        merged[index] = min(span.lowerBound, other.lowerBound)...max(span.upperBound, other.upperBound)
                        grew = true
                    }
                }
            }
            spans = merged
        }

        // 2. Jede Zeilengruppe wird eine Änderung; bleibt nur Leerraum, fällt sie ganz weg.
        var final: [PreambleChange] = []
        var consumed = Set<Int>()
        for span in spans where span.upperBound < lineLimit {
            let whole = span.lowerBound..<(span.upperBound + 1)
            let members = changes.indices.filter { index in
                let range = changes[index].range
                if range.isEmpty { return range.lowerBound > whole.lowerBound && range.lowerBound < whole.upperBound }
                return range.lowerBound >= whole.lowerBound && range.upperBound <= whole.upperBound
            }
            consumed.formUnion(members)
            let applied = Self.applying(members.map { changes[$0] }, to: units, in: whole)
            let text = Self.isBlankCode(applied) ? "" : String(decoding: applied, as: UTF16.self)
            final.append(PreambleChange(range: whole, text: text))
        }
        final += changes.indices.filter { !consumed.contains($0) }.map { changes[$0] }

        // 3. Der Reihe nach zu einer Ersetzung verbinden.
        let accepted = Self.ordered(final)
        guard let lower = accepted.first?.range.lowerBound,
              let upper = accepted.map(\.range.upperBound).max() else { return nil }
        let replacement = Self.applying(accepted, to: units, in: lower..<upper)
        guard replacement != Array(units[lower..<upper]) else { return nil }
        let after = lower + replacement.count
        return TextEdit(
            range: lower..<upper,
            replacement: String(decoding: replacement, as: UTF16.self),
            selectionAfter: after..<after
        )
    }

    /// Sortiert Änderungen (Einfügen vor Ersetzen an derselben Stelle) und lässt
    /// überlappende weg – so etwas entsteht nur bei widersprüchlichen Angaben.
    static func ordered(_ changes: [PreambleChange]) -> [PreambleChange] {
        let sorted = changes.sorted {
            if $0.range.lowerBound != $1.range.lowerBound { return $0.range.lowerBound < $1.range.lowerBound }
            if $0.range.isEmpty != $1.range.isEmpty { return $0.range.isEmpty }
            return $0.order < $1.order
        }
        var accepted: [PreambleChange] = []
        var cursor = Int.min
        for change in sorted where change.range.lowerBound >= cursor {
            accepted.append(change)
            cursor = change.range.upperBound
        }
        return accepted
    }

    /// Wendet Änderungen auf einen Bereich an und liefert den neuen Text.
    static func applying(_ changes: [PreambleChange], to units: [UInt16], in range: Range<Int>) -> [UInt16] {
        var result: [UInt16] = []
        var position = range.lowerBound
        for change in ordered(changes) {
            result += units[position..<change.range.lowerBound]
            result += change.text.utf16
            position = change.range.upperBound
        }
        result += units[position..<range.upperBound]
        return result
    }

    /// Enthält der Text ausser Leerraum und Kommentaren nichts?
    static func isBlankCode(_ text: [UInt16]) -> Bool {
        var start = 0
        while start < text.count {
            let lineEnd = text.lineEnd(after: start)
            let codeEnd = text.commentStart(inLineStartingAt: start) ?? lineEnd
            if !(start..<codeEnd).allSatisfy({ TeXChar.isWhitespace(text[$0]) }) { return false }
            start = lineEnd + 1
        }
        return true
    }
}
