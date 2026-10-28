import LaTeXKit
import SwiftUI

// Bausteine der Multifunktionsleiste (siehe Ribbon.swift): Knöpfe in zwei
// Grössen, Gruppen mit Überschrift und die Auswahlfenster (Popover), die
// sich unter einem Knopf öffnen. Alles hier ist reine Darstellung – die
// Aktionen kommen von aussen.

extension EnvironmentValues {
    /// Schmale Darstellung: Grosse Knöpfe zeigen nur ihr Symbol, ohne Beschriftung.
    @Entry var ribbonIsCompact = false
}

/// Symbol eines Knopfs: ein SF-Symbol oder ein Schriftzeichen wie „∫“.
enum RibbonIcon {
    case symbol(String)
    case glyph(String)

    @ViewBuilder
    func image(size: CGFloat) -> some View {
        switch self {
        case .symbol(let name):
            Image(systemName: name)
                .font(.system(size: size, weight: .regular))
                .symbolRenderingMode(.hierarchical)
        case .glyph(let text):
            Text(verbatim: text)
                .font(.system(size: size + 2, weight: .regular, design: .serif))
                .lineLimit(1)
                .minimumScaleFactor(0.4)
        }
    }
}

// MARK: - Knopfstil

/// Ruhiger Stil wie in Pages oder Word: kein Rahmen, beim Darüberfahren ein
/// leichter Hintergrund, eingeschaltet in der Akzentfarbe.
struct RibbonButtonStyle: ButtonStyle {
    var isOn = false

    func makeBody(configuration: Configuration) -> some View {
        RibbonButtonBody(configuration: configuration, isOn: isOn)
    }
}

private struct RibbonButtonBody: View {
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
        if isHovered { return Color.primary.opacity(0.07) }
        return .clear
    }
}

// MARK: - Grosse Knöpfe

/// Inhalt eines grossen Knopfs: Symbol oben, Beschriftung darunter.
struct RibbonLargeLabel: View {
    let title: String
    let icon: RibbonIcon
    var showsChevron = false
    @Environment(\.ribbonIsCompact) private var isCompact

    var body: some View {
        VStack(spacing: 3) {
            icon.image(size: isCompact ? 18 : 21)
                .frame(height: 26)
            if isCompact {
                if showsChevron { chevron }
            } else {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(title)
                        .font(.system(size: 11))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    if showsChevron { chevron }
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .frame(minWidth: isCompact ? 32 : 46, maxWidth: isCompact ? 44 : 84, minHeight: 58, alignment: .top)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
    }

    private var chevron: some View {
        Image(systemName: "chevron.down")
            .font(.system(size: 7, weight: .bold))
            .foregroundStyle(.secondary)
    }
}

/// Grosser Knopf mit Symbol und Beschriftung.
struct RibbonButton: View {
    let title: String
    let icon: RibbonIcon
    var isOn = false
    var help: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            RibbonLargeLabel(title: title, icon: icon)
        }
        .buttonStyle(RibbonButtonStyle(isOn: isOn))
        .help(help ?? title)
    }
}

/// Grosser Knopf, der ein Auswahlfenster öffnet.
struct RibbonMenuButton<Content: View>: View {
    let title: String
    let icon: RibbonIcon
    var isOn = false
    var help: String?
    private let content: () -> Content
    @State private var isPresented = false

    init(
        _ title: String,
        icon: RibbonIcon,
        isOn: Bool = false,
        help: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.isOn = isOn
        self.help = help
        self.content = content
    }

    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            RibbonLargeLabel(title: title, icon: icon, showsChevron: true)
        }
        .buttonStyle(RibbonButtonStyle(isOn: isOn || isPresented))
        .help(help ?? title)
        .popover(isPresented: $isPresented, arrowEdge: .bottom) {
            content()
        }
    }
}

// MARK: - Kleine Knöpfe

/// Kleiner Knopf nur mit Symbol (z. B. Fett, Kursiv).
struct RibbonSmallButton: View {
    let title: String
    let systemImage: String
    var isOn = false
    var help: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13))
                .frame(width: 26, height: 24)
        }
        .buttonStyle(RibbonButtonStyle(isOn: isOn))
        .help(help ?? title)
        .accessibilityLabel(title)
    }
}

/// Kleiner Knopf mit Symbol und Text (für seltener gebrauchte Bausteine).
struct RibbonSmallTextButton: View {
    let title: String
    let systemImage: String
    var help: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.system(size: 12))
                    .frame(width: 16)
                Text(title)
                    .font(.system(size: 11.5))
                    .lineLimit(1)
                    .fixedSize()
            }
            .padding(.horizontal, 5)
            .frame(height: 24)
        }
        .buttonStyle(RibbonButtonStyle())
        .help(help ?? title)
    }
}

/// Kleiner Knopf, der ein Auswahlfenster öffnet (z. B. Schriftgrösse).
struct RibbonSmallMenuButton<Label: View, Content: View>: View {
    var help: String
    private let label: () -> Label
    private let content: () -> Content
    @State private var isPresented = false

    init(
        help: String,
        @ViewBuilder label: @escaping () -> Label,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.help = help
        self.label = label
        self.content = content
    }

    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            HStack(spacing: 3) {
                label()
                Image(systemName: "chevron.down")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 5)
            .frame(height: 24)
        }
        .buttonStyle(RibbonButtonStyle(isOn: isPresented))
        .help(help)
        .popover(isPresented: $isPresented, arrowEdge: .bottom) {
            content()
        }
    }
}

// MARK: - Gruppen

/// Gruppe mit Überschrift unten, wie in Word („Schrift“, „Absatz“ …).
struct RibbonGroup<Content: View>: View {
    let title: String
    private let content: () -> Content

    init(_ title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 1) {
                content()
            }
            .frame(maxHeight: .infinity, alignment: .top)
            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .fixedSize()
                .padding(.bottom, 3)
        }
        .padding(.horizontal, 5)
    }
}

/// Senkrechte Trennlinie zwischen zwei Gruppen.
struct RibbonSeparator: View {
    var body: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.1))
            .frame(width: 1)
            .padding(.vertical, 8)
    }
}

// MARK: - Auswahlfenster

/// Liste im Auswahlfenster – sieht aus wie ein Menü, darf aber Untertitel,
/// Vorschauen und Abschnitte enthalten.
struct RibbonMenu<Content: View>: View {
    var minWidth: CGFloat = 230
    private let content: () -> Content

    init(minWidth: CGFloat = 230, @ViewBuilder content: @escaping () -> Content) {
        self.minWidth = minWidth
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            content()
        }
        .padding(6)
        .frame(minWidth: minWidth, alignment: .leading)
    }
}

/// Abschnittsüberschrift im Auswahlfenster.
struct RibbonMenuHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.top, 6)
            .padding(.bottom, 2)
    }
}

/// Eintrag im Auswahlfenster. Ein Klick führt die Aktion aus und schliesst das Fenster.
struct RibbonMenuRow<Title: View>: View {
    var subtitle: String?
    var icon: RibbonIcon?
    var isChecked = false
    var shortcut: String?
    var help: String?
    let action: () -> Void
    private let title: () -> Title

    @Environment(\.dismiss) private var dismiss
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false

    init(
        subtitle: String? = nil,
        icon: RibbonIcon? = nil,
        isChecked: Bool = false,
        shortcut: String? = nil,
        help: String? = nil,
        action: @escaping () -> Void,
        @ViewBuilder title: @escaping () -> Title
    ) {
        self.subtitle = subtitle
        self.icon = icon
        self.isChecked = isChecked
        self.shortcut = shortcut
        self.help = help
        self.action = action
        self.title = title
    }

    var body: some View {
        Button {
            dismiss()
            action()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .opacity(isChecked ? 1 : 0)
                    .frame(width: 10)
                if let icon {
                    icon.image(size: 13)
                        .frame(width: 26)
                }
                VStack(alignment: .leading, spacing: 1) {
                    title()
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 11))
                            .opacity(0.7)
                            .lineLimit(2)
                    }
                }
                Spacer(minLength: 16)
                if let shortcut {
                    Text(shortcut)
                        .font(.system(size: 12))
                        .opacity(0.6)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, subtitle == nil ? 4 : 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(isHovered ? AnyShapeStyle(Color.white) : AnyShapeStyle(.primary))
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(isHovered ? Color.accentColor : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.4)
        .onHover { isHovered = $0 && isEnabled }
        .help(help ?? "")
    }
}

extension RibbonMenuRow where Title == Text {
    init(
        _ title: String,
        subtitle: String? = nil,
        icon: RibbonIcon? = nil,
        isChecked: Bool = false,
        shortcut: String? = nil,
        help: String? = nil,
        action: @escaping () -> Void
    ) {
        self.init(
            subtitle: subtitle,
            icon: icon,
            isChecked: isChecked,
            shortcut: shortcut,
            help: help,
            action: action
        ) {
            Text(title)
        }
    }
}

/// Trennlinie im Auswahlfenster.
struct RibbonMenuDivider: View {
    var body: some View {
        Divider().padding(.vertical, 4).padding(.horizontal, 8)
    }
}

// MARK: - Symbol-Kacheln

/// Eine Kachel mit einem mathematischen Zeichen. Bleibt beim Klicken offen,
/// damit man mehrere Zeichen nacheinander einfügen kann.
struct SymbolTile: View {
    let symbol: MathSymbol
    var size: CGFloat = 34
    let insert: (MathSymbol) -> Void
    @State private var isHovered = false

    var body: some View {
        Button {
            insert(symbol)
        } label: {
            Text(verbatim: symbol.glyph)
                .font(.system(size: size * 0.52, design: .serif))
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

/// Alle Symbole nach Gruppen – das Auswahlfenster hinter „Alle Symbole“.
struct SymbolPalette: View {
    let insert: (MathSymbol) -> Void

    private var columns: [GridItem] {
        Array(repeating: GridItem(.fixed(34), spacing: 4), count: 9)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(MathSymbolGroup.allCases) { group in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(group.title)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                        LazyVGrid(columns: columns, alignment: .leading, spacing: 4) {
                            ForEach(group.symbols) { symbol in
                                SymbolTile(symbol: symbol, insert: insert)
                            }
                        }
                    }
                }
                Text("Ein Klick fügt das Zeichen ein, das Fenster bleibt offen.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(12)
        }
        .frame(width: 370, height: 420)
    }
}
