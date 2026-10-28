import LaTeXKit
import SwiftUI

/// Registerkarten der Multifunktionsleiste.
enum RibbonTab: String, CaseIterable, Identifiable {
    case start
    case insert
    case math
    case layout
    case blocks

    var id: String { rawValue }

    var title: String {
        switch self {
        case .start: return "Start"
        case .insert: return "Einfügen"
        case .math: return "Formeln"
        case .layout: return "Layout"
        case .blocks: return "Blöcke"
        }
    }
}

/// Wie viel die Leiste zeigt – je nach verfügbarer Breite.
enum RibbonDensity {
    /// Alles, inklusive Formatvorlagen-Kacheln und Schnellsymbolen.
    case full
    /// Ohne die breiten Extras (sie bleiben über Knöpfe erreichbar).
    case medium
    /// Grosse Knöpfe nur noch mit Symbol.
    case compact
}

extension EnvironmentValues {
    @Entry var ribbonDensity = RibbonDensity.full
}

/// Multifunktionsleiste über Editor und Vorschau – wie in Word.
///
/// Oben die Registerkarten, darunter die Knöpfe der gewählten Karte in
/// Gruppen mit Überschrift. Wird es eng, verschwinden zuerst die breiten
/// Extras, dann die Beschriftungen; erst danach lässt sich die Leiste seitlich
/// scrollen. Die Höhe ist immer gleich: So springt der Editor beim Umschalten
/// nicht, und es kann sich keine Layout-Schleife bilden (siehe DocumentSplitView).
struct Ribbon: View {
    let workspace: DocumentWorkspace
    @AppStorage("ribbonTab") private var selectedTab: RibbonTab = .start
    @AppStorage("ribbonCollapsed") private var isCollapsed = false

    static let tabBarHeight: CGFloat = 30
    static let contentHeight: CGFloat = 86

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            if !isCollapsed {
                ViewThatFits(in: .horizontal) {
                    content(.full)
                    content(.medium)
                    content(.compact)
                    ScrollView(.horizontal, showsIndicators: false) {
                        content(.compact)
                    }
                }
                .frame(height: Self.contentHeight)
            }
        }
        .background(.bar)
        .overlay(alignment: .bottom) { Divider() }
    }

    // MARK: - Registerkarten

    private var tabBar: some View {
        HStack(spacing: 2) {
            ForEach(RibbonTab.allCases) { tab in
                RibbonTabButton(title: tab.title, isSelected: tab == selectedTab && !isCollapsed) {
                    selectedTab = tab
                    isCollapsed = false
                }
            }
            Spacer(minLength: 8)
            Button {
                isCollapsed.toggle()
            } label: {
                Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                    .font(.system(size: 10, weight: .semibold))
                    .frame(width: 26, height: 22)
            }
            .buttonStyle(RibbonButtonStyle())
            .help(isCollapsed ? "Leiste ausklappen" : "Leiste einklappen – nur die Registerkarten bleiben sichtbar")
            .accessibilityLabel(isCollapsed ? "Leiste ausklappen" : "Leiste einklappen")
        }
        .padding(.horizontal, 8)
        .frame(height: Self.tabBarHeight)
    }

    // MARK: - Inhalt

    private func content(_ density: RibbonDensity) -> some View {
        HStack(spacing: 0) {
            switch selectedTab {
            case .start: StartTab(workspace: workspace)
            case .insert: InsertTab(workspace: workspace)
            case .math: MathTab(workspace: workspace)
            case .layout: LayoutTab(workspace: workspace)
            case .blocks: BlocksTab(workspace: workspace)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
        .padding(.top, 2)
        .environment(\.ribbonDensity, density)
        .environment(\.ribbonIsCompact, density == .compact)
        .fixedSize(horizontal: true, vertical: false)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Eine Registerkarte: Text mit Akzentstrich darunter, wenn ausgewählt.
private struct RibbonTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // Platzhalter in fetter Schrift: Die Breite ändert sich beim Auswählen nicht.
                Text(title).font(.system(size: 12, weight: .semibold)).hidden()
                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
            }
            .padding(.horizontal, 10)
            .frame(height: 24)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isHovered && !isSelected ? Color.primary.opacity(0.06) : Color.clear)
            )
            .overlay(alignment: .bottom) {
                Capsule()
                    .fill(Color.accentColor)
                    .frame(height: 2.5)
                    .padding(.horizontal, 10)
                    .offset(y: 3)
                    .opacity(isSelected ? 1 : 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
