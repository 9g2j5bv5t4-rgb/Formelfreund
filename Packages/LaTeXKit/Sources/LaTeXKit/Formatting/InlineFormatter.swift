import Foundation

/// Zeichenformate wie in Word – jeweils ein LaTeX-Befehl mit einem Argument.
public enum InlineStyle: String, CaseIterable, Sendable, Identifiable {
    case bold          // \textbf
    case italic        // \textit
    case underline     // \underline
    case emphasis      // \emph
    case sansSerif     // \textsf
    case monospace     // \texttt
    case smallCaps     // \textsc

    public var id: String { rawValue }

    /// Befehlsname ohne Backslash, z. B. `textbf`.
    public var command: String {
        switch self {
        case .bold: return "textbf"
        case .italic: return "textit"
        case .underline: return "underline"
        case .emphasis: return "emph"
        case .sansSerif: return "textsf"
        case .monospace: return "texttt"
        case .smallCaps: return "textsc"
        }
    }

    public var title: String {
        switch self {
        case .bold: return "Fett"
        case .italic: return "Kursiv"
        case .underline: return "Unterstrichen"
        case .emphasis: return "Hervorgehoben"
        case .sansSerif: return "Serifenlos"
        case .monospace: return "Schreibmaschine"
        case .smallCaps: return "Kapitälchen"
        }
    }

    /// SF-Symbol für Knöpfe und Menüs.
    public var symbol: String {
        switch self {
        case .bold: return "bold"
        case .italic: return "italic"
        case .underline: return "underline"
        case .emphasis: return "textformat.abc.dottedunderline"
        case .sansSerif: return "textformat"
        case .monospace: return "chevron.left.forwardslash.chevron.right"
        case .smallCaps: return "textformat.size.smaller"
        }
    }
}

/// LaTeX-Schriftgrössen, von klein nach gross.
public enum FontSize: String, CaseIterable, Sendable, Identifiable {
    case tiny, scriptsize, footnotesize, small, normalsize, large, Large, LARGE, huge, Huge

    public var id: String { rawValue }
    /// Befehlsname ohne Backslash (`large`).
    public var command: String { rawValue }

    public var title: String {
        switch self {
        case .tiny: return "Winzig"
        case .scriptsize: return "Sehr klein"
        case .footnotesize: return "Fussnotengrösse"
        case .small: return "Klein"
        case .normalsize: return "Normal"
        case .large: return "Gross"
        case .Large: return "Grösser"
        case .LARGE: return "Sehr gross"
        case .huge: return "Riesig"
        case .Huge: return "Gigantisch"
        }
    }

    /// Ungefährer Skalierungsfaktor zur Normalgrösse (für die Vorschau im Menü).
    public var relativeScale: Double {
        switch self {
        case .tiny: return 0.5
        case .scriptsize: return 0.7
        case .footnotesize: return 0.8
        case .small: return 0.9
        case .normalsize: return 1.0
        case .large: return 1.2
        case .Large: return 1.44
        case .LARGE: return 1.73
        case .huge: return 2.07
        case .Huge: return 2.49
        }
    }
}

/// Textfarben (benötigen das Paket `xcolor`).
public enum TextColor: String, CaseIterable, Sendable, Identifiable {
    case red, blue, green, orange, violet, teal, gray

    public var id: String { rawValue }

    /// Farbname für `\textcolor{…}` – nur Namen, die `xcolor` ohne Optionen kennt.
    public var latexName: String {
        switch self {
        case .red: return "red"
        case .blue: return "blue"
        case .green: return "green!50!black"
        case .orange: return "orange"
        case .violet: return "violet"
        case .teal: return "teal"
        case .gray: return "gray"
        }
    }

    public var title: String {
        switch self {
        case .red: return "Rot"
        case .blue: return "Blau"
        case .green: return "Grün"
        case .orange: return "Orange"
        case .violet: return "Violett"
        case .teal: return "Petrol"
        case .gray: return "Grau"
        }
    }

    /// Farbwert (0…1) für das Farbfeld im Menü – entspricht der Darstellung im PDF.
    public var rgb: (red: Double, green: Double, blue: Double) {
        switch self {
        case .red: return (1, 0, 0)
        case .blue: return (0, 0, 1)
        case .green: return (0, 0.5, 0)
        case .orange: return (1, 0.5, 0)
        case .violet: return (0.5, 0, 0.5)
        case .teal: return (0, 0.5, 0.5)
        case .gray: return (0.5, 0.5, 0.5)
        }
    }
}

/// Zeichenformat an der Cursorposition – damit die Knöpfe der Format-Leiste den Zustand anzeigen.
public struct FormattingState: Equatable, Sendable {
    /// Alle Stile, in deren Argument der Cursor bzw. die ganze Auswahl steht.
    public var styles: Set<InlineStyle>
    /// Innerste Grössenangabe (`{\large …}`), falls vorhanden.
    public var fontSize: FontSize?
    /// Innerste Textfarbe (`\textcolor{…}{…}`), falls vorhanden und bekannt.
    public var color: TextColor?

    public init(styles: Set<InlineStyle> = [], fontSize: FontSize? = nil, color: TextColor? = nil) {
        self.styles = styles
        self.fontSize = fontSize
        self.color = color
    }
}

/// Zeichenformatierung per Klick – wie in Word, aber als LaTeX-Befehle.
///
/// Verhalten (wie in Word):
/// - Mit Auswahl: Auswahl wird eingepackt (`\textbf{Auswahl}`) und bleibt ausgewählt.
///   Ist die Auswahl schon genau so formatiert, wird die Formatierung entfernt.
/// - Ohne Auswahl im Argument eines passenden Befehls: Formatierung entfernen.
/// - Ohne Auswahl mitten in einem Wort: das Wort wird formatiert.
/// - Sonst: `\textbf{}` einfügen, Cursor zwischen die Klammern.
///
/// Gesucht wird nur im aktuellen Absatz; Kommentare und maskierte Klammern zählen nicht.
public enum InlineFormatter {
    public static func state<S: UTF16Source>(in text: S, selection: Range<Int>) -> FormattingState {
        fatalError("Noch nicht umgesetzt")
    }

    public static func toggle<S: UTF16Source>(_ style: InlineStyle, in text: S, selection: Range<Int>) -> TextEdit {
        fatalError("Noch nicht umgesetzt")
    }

    /// `{\large Auswahl}`. Innerhalb einer bestehenden Grössengruppe wird der Befehl ersetzt;
    /// `.normalsize` entfernt die Gruppe.
    public static func setFontSize<S: UTF16Source>(_ size: FontSize, in text: S, selection: Range<Int>) -> TextEdit {
        fatalError("Noch nicht umgesetzt")
    }

    /// `\textcolor{red}{Auswahl}`. Innerhalb einer bestehenden Farbe wird die Farbe ersetzt;
    /// `nil` entfernt sie. Benötigt `PackageRequirement.xcolor`.
    public static func setColor<S: UTF16Source>(_ color: TextColor?, in text: S, selection: Range<Int>) -> TextEdit {
        fatalError("Noch nicht umgesetzt")
    }
}
