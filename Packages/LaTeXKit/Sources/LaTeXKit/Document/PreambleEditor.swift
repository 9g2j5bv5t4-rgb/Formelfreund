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
        fatalError("Noch nicht umgesetzt")
    }

    /// Kurzbeschreibung für das Menü („klassisch, wie in Word“ …).
    public var subtitle: String {
        fatalError("Noch nicht umgesetzt")
    }

    /// Präambel-Zeilen für diese Schrift (leer für die Standardschrift).
    public var preambleLines: [String] {
        fatalError("Noch nicht umgesetzt")
    }

    /// Name einer ähnlichen macOS-Schrift für die Vorschau im Menü.
    public var previewFontName: String {
        fatalError("Noch nicht umgesetzt")
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
/// Änderungen sind minimal und nachvollziehbar: Formelfreund ergänzt bzw.
/// ersetzt einzelne Zeilen und markiert verwaltete Zeilen mit einem kurzen
/// Kommentar (z. B. `% Schrift: Times`). Von Hand geschriebene Präambeln
/// bleiben ansonsten unangetastet und mit Overleaf/TeXShop kompatibel.
public enum PreambleEditor {
    /// Position von `\begin{document}` (nicht in Kommentaren), falls vorhanden.
    public static func preambleEnd<S: UTF16Source>(in text: S) -> Int? {
        fatalError("Noch nicht umgesetzt")
    }

    /// Ist das Paket (ausserhalb von Kommentaren) in der Präambel geladen?
    /// Berücksichtigt Mehrfachangaben wie `\usepackage{amsmath,amssymb}`.
    public static func isLoaded<S: UTF16Source>(package: String, in text: S) -> Bool {
        fatalError("Noch nicht umgesetzt")
    }

    /// Aktuelle Einstellungen aus der Präambel.
    public static func settings<S: UTF16Source>(in text: S) -> DocumentSettings {
        fatalError("Noch nicht umgesetzt")
    }

    /// Schreibt die Einstellungen in die Präambel. `nil`, wenn es keine Präambel gibt
    /// oder sich nichts ändert. Die `TextEdit` ersetzt nur den Präambel-Bereich;
    /// `selectionAfter` ist auf das Ende der Ersetzung gesetzt (der Aufrufer nutzt
    /// `preservingSelection`, um die Auswahl des Nutzers zu behalten).
    public static func apply<S: UTF16Source>(_ settings: DocumentSettings, in text: S) -> TextEdit? {
        fatalError("Noch nicht umgesetzt")
    }

    /// Ergänzt fehlende Pakete und Präambel-Zeilen direkt vor `\begin{document}`
    /// (bzw. nach dem letzten `\usepackage`). `nil`, wenn nichts fehlt oder es keine Präambel gibt.
    public static func ensure<S: UTF16Source>(_ requirements: [PackageRequirement], in text: S) -> TextEdit? {
        fatalError("Noch nicht umgesetzt")
    }
}
