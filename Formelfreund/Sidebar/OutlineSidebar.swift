import LaTeXKit
import SwiftUI

/// Linke Seitenleiste: Gliederung, Formeln und Bilder des Dokuments.
/// Ein Klick springt im Editor an die Stelle.
struct OutlineSidebar: View {
    let workspace: DocumentWorkspace

    @State private var selection: OutlineItem.ID?
    @SceneStorage("sidebar.sections") private var sectionsExpanded = true
    @SceneStorage("sidebar.formulas") private var formulasExpanded = true
    @SceneStorage("sidebar.images") private var imagesExpanded = true

    private var outline: DocumentOutline { workspace.outline }

    var body: some View {
        List(selection: $selection) {
            Section("Gliederung", isExpanded: $sectionsExpanded) {
                if outline.sections.isEmpty {
                    EmptyHint(text: "Noch keine Abschnitte. Beginne einen mit \\section{Titel}.")
                }
                ForEach(outline.sections) { item in
                    SectionRow(item: item, minimumLevel: outline.minimumSectionLevel)
                        .tag(item.id)
                        .simultaneousGesture(TapGesture().onEnded { reveal(item) })
                }
            }

            Section("Formeln", isExpanded: $formulasExpanded) {
                if outline.formulas.isEmpty {
                    EmptyHint(text: "Abgesetzte Formeln wie \\[ … \\] oder align erscheinen hier.")
                }
                ForEach(outline.formulas) { item in
                    FormulaRow(item: item)
                        .tag(item.id)
                        .simultaneousGesture(TapGesture().onEnded { reveal(item) })
                }
            }

            Section("Bilder", isExpanded: $imagesExpanded) {
                if outline.images.isEmpty {
                    EmptyHint(text: "Bilder aus \\includegraphics erscheinen hier.")
                }
                ForEach(outline.images) { item in
                    ImageRow(item: item, documentDirectory: workspace.fileURL?.deletingLastPathComponent())
                        .tag(item.id)
                        .simultaneousGesture(TapGesture().onEnded { reveal(item) })
                }
            }
        }
        .listStyle(.sidebar)
        .onChange(of: selection) { _, newValue in
            // Auch Pfeiltasten in der Liste springen mit.
            if let newValue, let item = item(withID: newValue) { reveal(item) }
        }
    }

    private func item(withID id: OutlineItem.ID) -> OutlineItem? {
        (outline.sections + outline.formulas + outline.images).first { $0.id == id }
    }

    private func reveal(_ item: OutlineItem) {
        workspace.reveal(line: item.line)
    }
}

private struct EmptyHint: View {
    let text: String

    var body: some View {
        Text(verbatim: text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .selectionDisabled()
    }
}

private struct SectionRow: View {
    let item: OutlineItem
    let minimumLevel: Int

    private var level: Int {
        if case .section(let level) = item.kind { return level }
        return minimumLevel
    }

    var body: some View {
        Label {
            Text(verbatim: item.title)
                .fontWeight(level == minimumLevel ? .medium : .regular)
                .lineLimit(1)
        } icon: {
            Image(systemName: level == minimumLevel ? "number" : "text.alignleft")
        }
        .padding(.leading, CGFloat(max(0, level - minimumLevel)) * 12)
        .help("Zeile \(item.line)")
    }
}

private struct FormulaRow: View {
    let item: OutlineItem

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: item.title)
                    .font(.system(.callout, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.tail)
                if let environment = item.detail {
                    Text(verbatim: environment)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        } icon: {
            Image(systemName: "function")
        }
        .help("Zeile \(item.line)")
    }
}

private struct ImageRow: View {
    let item: OutlineItem
    let documentDirectory: URL?

    /// Sucht die Bilddatei wie LaTeX: mit oder ohne Dateiendung.
    private var fileExists: Bool? {
        guard let documentDirectory else { return nil }
        let base = documentDirectory.appendingPathComponent(item.title)
        let candidates = [base] + ["pdf", "png", "jpg", "jpeg", "eps"].map { base.appendingPathExtension($0) }
        return candidates.contains { FileManager.default.fileExists(atPath: $0.path) }
    }

    var body: some View {
        Label {
            HStack {
                Text(verbatim: (item.title as NSString).lastPathComponent)
                    .lineLimit(1)
                    .truncationMode(.middle)
                if fileExists == false {
                    Spacer(minLength: 4)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                        .help("Datei nicht gefunden – liegt sie im selben Ordner wie das Dokument?")
                }
            }
        } icon: {
            Image(systemName: "photo")
        }
        .help(item.title)
    }
}
