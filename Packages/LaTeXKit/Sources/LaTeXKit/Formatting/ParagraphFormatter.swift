import Foundation

/// Absatzstile wie in Word („Überschrift 1“ …).
public enum ParagraphStyle: String, CaseIterable, Sendable, Identifiable {
    case body
    case heading1
    case heading2
    case heading3
    case heading4

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .body: return "Text"
        case .heading1: return "Überschrift 1"
        case .heading2: return "Überschrift 2"
        case .heading3: return "Überschrift 3"
        case .heading4: return "Überschrift 4"
        }
    }
}

/// Welche LaTeX-Befehle hinter „Überschrift 1–4“ stehen – abhängig von der Dokumentklasse.
public enum HeadingScheme: Sendable, Equatable {
    /// article, scrartcl …: 1 = \section, 2 = \subsection, 3 = \subsubsection, 4 = \paragraph
    case article
    /// report, book, scrreprt, scrbook …: 1 = \chapter, 2 = \section, 3 = \subsection, 4 = \subsubsection
    case book

    /// Liest `\documentclass{…}` aus dem Text; unbekannt → `.article`.
    public static func detect<S: UTF16Source>(in text: S) -> HeadingScheme {
        fatalError("Noch nicht umgesetzt")
    }

    /// Befehlsname ohne Backslash; `nil` für `.body`.
    public func command(for style: ParagraphStyle) -> String? {
        switch (self, style) {
        case (_, .body): return nil
        case (.article, .heading1): return "section"
        case (.article, .heading2): return "subsection"
        case (.article, .heading3): return "subsubsection"
        case (.article, .heading4): return "paragraph"
        case (.book, .heading1): return "chapter"
        case (.book, .heading2): return "section"
        case (.book, .heading3): return "subsection"
        case (.book, .heading4): return "subsubsection"
        }
    }
}

/// Absatzausrichtung über die Umgebungen `flushleft`, `center`, `flushright`.
public enum TextAlignment: String, CaseIterable, Sendable, Identifiable {
    /// Standard (Blocksatz bzw. linksbündig) – keine Umgebung.
    case standard
    case left
    case center
    case right

    public var id: String { rawValue }

    /// Umgebung, `nil` für `.standard`.
    public var environment: String? {
        switch self {
        case .standard: return nil
        case .left: return "flushleft"
        case .center: return "center"
        case .right: return "flushright"
        }
    }

    public var title: String {
        switch self {
        case .standard: return "Blocksatz"
        case .left: return "Linksbündig"
        case .center: return "Zentriert"
        case .right: return "Rechtsbündig"
        }
    }

    public var symbol: String {
        switch self {
        case .standard: return "text.justify"
        case .left: return "text.alignleft"
        case .center: return "text.aligncenter"
        case .right: return "text.alignright"
        }
    }
}

/// Listenarten.
public enum ListKind: String, CaseIterable, Sendable, Identifiable {
    case itemize
    case enumerate

    public var id: String { rawValue }
    public var environment: String { rawValue }

    public var title: String {
        switch self {
        case .itemize: return "Aufzählung"
        case .enumerate: return "Nummerierte Liste"
        }
    }

    public var symbol: String {
        switch self {
        case .itemize: return "list.bullet"
        case .enumerate: return "list.number"
        }
    }
}

/// Absatzformat an der Cursorposition (für die Format-Leiste).
public struct ParagraphState: Equatable, Sendable {
    public var style: ParagraphStyle
    public var alignment: TextAlignment
    /// Innerste Liste, in der der Cursor steht.
    public var list: ListKind?

    public init(style: ParagraphStyle = .body, alignment: TextAlignment = .standard, list: ListKind? = nil) {
        self.style = style
        self.alignment = alignment
        self.list = list
    }
}

/// Absatzformatierung: Überschriften, Ausrichtung, Listen.
public enum ParagraphFormatter {
    /// Zustand für die Zeile mit dem Cursor bzw. der Auswahl.
    public static func state<S: UTF16Source>(in text: S, selection: Range<Int>, scheme: HeadingScheme) -> ParagraphState {
        fatalError("Noch nicht umgesetzt")
    }

    /// Macht die aktuelle Zeile zur Überschrift (`\section{Zeilentext}`), ändert die Ebene
    /// oder macht sie wieder zu normalem Text. Sternform und `\label{…}` bleiben erhalten.
    public static func apply<S: UTF16Source>(_ style: ParagraphStyle, in text: S, selection: Range<Int>, scheme: HeadingScheme) -> TextEdit {
        fatalError("Noch nicht umgesetzt")
    }

    /// Richtet den Absatz bzw. die ausgewählten Zeilen aus (packt sie in `center` usw.,
    /// ändert eine bestehende Ausrichtungs-Umgebung oder entfernt sie bei `.standard`).
    public static func align<S: UTF16Source>(_ alignment: TextAlignment, in text: S, selection: Range<Int>) -> TextEdit {
        fatalError("Noch nicht umgesetzt")
    }

    /// Liste ein/aus/umschalten:
    /// - In einer Liste derselben Art: Liste auflösen (`\item ` entfernen).
    /// - In einer Liste der anderen Art: Art wechseln (`itemize` ↔ `enumerate`).
    /// - Sonst: jede nicht leere ausgewählte Zeile wird ein `\item`, alles in der Umgebung.
    ///   Ohne Text: leere Liste mit einem `\item ` und Cursor dahinter.
    public static func toggleList<S: UTF16Source>(_ kind: ListKind, in text: S, selection: Range<Int>) -> TextEdit {
        fatalError("Noch nicht umgesetzt")
    }
}
