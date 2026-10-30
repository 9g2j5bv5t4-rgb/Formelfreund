import LaTeXKit
import SwiftUI

// Kleine Bausteine, die Symbolleiste, Format-Seitenleiste und Auswahlfenster
// gemeinsam nutzen. Wo es geht, verwendet Lemma die Standard-Bedienelemente
// von macOS; eigene Elemente gibt es nur für Dinge, die das System nicht hat
// (Formelzeichen-Kacheln, Farbkreise, Raster zum Aufziehen).

/// Symbol eines Bausteins: ein SF-Symbol oder ein Schriftzeichen wie „∫“.
enum ItemIcon {
    case symbol(String)
    case glyph(String)

    @ViewBuilder
    func image(size: CGFloat) -> some View {
        switch self {
        case .symbol(let name):
            Image(systemName: name)
                .font(.system(size: size, weight: .regular))
        case .glyph(let text):
            Text(verbatim: text)
                .font(.system(size: size + 2, weight: .regular, design: .serif))
                .lineLimit(1)
                .minimumScaleFactor(0.4)
        }
    }
}

/// Symbol für einen Baustein ohne eigenes SF-Symbol.
enum SnippetIcon {
    private static let glyphs: [String: String] = [
        "formula.nthRoot": "ⁿ√",
        "formula.integral": "∫",
        "formula.limit": "lim",
        "formula.binomial": "(ⁿₖ)",
        "formula.norm": "‖x‖",
        "formula.parentheses": "( )",
        "formula.derivative": "d/dx",
        "formula.partialDerivative": "∂/∂x",
        "formula.set": "{ | }",
        "display.align": "(1)",
        "heading.subsubsection": "§",
        "heading.sectionUnnumbered": "§",
        "text.eqref": "(1)"
    ]

    static func icon(for snippet: Snippet) -> ItemIcon {
        if let symbol = snippet.symbol { return .symbol(symbol) }
        if let glyph = glyphs[snippet.id] { return .glyph(glyph) }
        return .symbol("square.dashed")
    }
}

/// Ruhiger Knopfstil ohne Rahmen: beim Darüberfahren ein leichter Hintergrund,
/// eingeschaltet in der Akzentfarbe (für Knöpfe auf schwebenden Leisten).
struct QuietButtonStyle: ButtonStyle {
    var isOn = false

    func makeBody(configuration: Configuration) -> some View {
        QuietButtonBody(configuration: configuration, isOn: isOn)
    }
}

private struct QuietButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let isOn: Bool
    @State private var isHovered = false
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        configuration.label
            .foregroundStyle(isOn ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
            .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(fill))
            .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .opacity(isEnabled ? 1 : 0.35)
            .onHover { isHovered = $0 }
    }

    private var fill: Color {
        guard isEnabled else { return .clear }
        if configuration.isPressed { return Color.primary.opacity(0.14) }
        if isOn { return Color.accentColor.opacity(isHovered ? 0.22 : 0.15) }
        if isHovered { return Color.primary.opacity(0.08) }
        return .clear
    }
}

// MARK: - Kacheln

/// Kachel mit Symbol und kurzer Beschriftung – für die Bausteine in der Seitenleiste.
struct ItemTile: View {
    let title: String
    let icon: ItemIcon
    var help: String?
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                icon.image(size: 17)
                    .frame(height: 22)
                Text(title)
                    .font(.system(size: 10))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.primary.opacity(isHovered ? 0.09 : 0.04))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help(help ?? title)
        .accessibilityLabel(title)
    }
}

/// Kachel mit einem mathematischen Zeichen. Ein Klick fügt es ein.
struct SymbolTile: View {
    let symbol: MathSymbol
    var size: CGFloat = 30
    let insert: (MathSymbol) -> Void
    @State private var isHovered = false

    var body: some View {
        Button {
            insert(symbol)
        } label: {
            Text(verbatim: symbol.glyph)
                .font(.system(size: size * 0.55, design: .serif))
                .frame(width: size, height: size)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isHovered ? Color.accentColor.opacity(0.2) : Color.primary.opacity(0.05))
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help("\(symbol.name) – LaTeX: \(symbol.command)")
        .accessibilityLabel(symbol.name)
    }
}

// MARK: - Farben

extension TextColor {
    var swiftUIColor: Color {
        let value = rgb
        return Color(red: value.red, green: value.green, blue: value.blue)
    }
}

/// Farbkreise für die Textfarbe – mit Namen für VoiceOver und Hilfetext.
struct ColorSwatchRow: View {
    let current: TextColor?
    let choose: (TextColor?) -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(TextColor.allCases) { color in
                Button {
                    choose(color)
                } label: {
                    Circle()
                        .fill(color.swiftUIColor)
                        .frame(width: 18, height: 18)
                        .overlay(Circle().strokeBorder(Color.primary.opacity(0.2)))
                        .padding(2)
                        .overlay(Circle().strokeBorder(current == color ? Color.accentColor : Color.clear, lineWidth: 2))
                        .frame(width: 24, height: 24)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .help(color.title)
                .accessibilityLabel(color.title)
                .accessibilityAddTraits(current == color ? .isSelected : [])
            }
            Button {
                choose(nil)
            } label: {
                Image(systemName: "circle.slash")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Keine Farbe")
            .accessibilityLabel("Keine Farbe")
        }
    }
}
