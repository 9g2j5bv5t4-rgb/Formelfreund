import AppKit
import LaTeXKit

/// Farben und Schrift des Editors.
///
/// Es werden ausschliesslich *System*farben verwendet (`.systemPurple` usw.).
/// Diese passen sich automatisch an hellen und dunklen Modus sowie an
/// „Kontrast erhöhen“ in den Bedienungshilfen an.
enum SyntaxTheme {
    static func color(for kind: TokenKind) -> NSColor {
        switch kind {
        case .keyword: return .systemPink
        case .command: return .systemPurple
        case .environmentName: return .systemGreen
        case .mathDelimiter: return .systemBlue
        case .math: return .systemBlue
        case .mathCommand: return .systemTeal
        case .comment: return .secondaryLabelColor
        case .brace: return .secondaryLabelColor
        case .special: return .systemOrange
        case .placeholder: return .controlAccentColor
        }
    }

    /// SF Mono in der gewünschten Grösse.
    static func font(size: CGFloat) -> NSFont {
        .monospacedSystemFont(ofSize: size, weight: .regular)
    }

    /// Grundattribute für den gesamten Text.
    static func baseAttributes(fontSize: CGFloat) -> [NSAttributedString.Key: Any] {
        let font = font(size: fontSize)
        let paragraph = NSMutableParagraphStyle()
        // Tabulator = 4 Zeichen breit.
        let characterWidth = ("M" as NSString).size(withAttributes: [.font: font]).width
        paragraph.tabStops = []
        paragraph.defaultTabInterval = characterWidth * 4
        return [
            .font: font,
            .foregroundColor: NSColor.textColor,
            .paragraphStyle: paragraph
        ]
    }

    /// Hintergrund für zusammengehörige Klammern.
    static var bracketMatchColor: NSColor { NSColor.controlAccentColor.withAlphaComponent(0.28) }
    /// Hintergrund der Zeile mit dem Cursor.
    static var currentLineColor: NSColor { NSColor.labelColor.withAlphaComponent(0.045) }

    /// Hintergrund für Zeilen mit Fehlern bzw. Warnungen.
    static func issueLineColor(_ severity: CompileIssue.Severity) -> NSColor {
        switch severity {
        case .error: return NSColor.systemRed.withAlphaComponent(0.13)
        case .warning: return NSColor.systemYellow.withAlphaComponent(0.13)
        case .badBox: return .clear
        }
    }
}
