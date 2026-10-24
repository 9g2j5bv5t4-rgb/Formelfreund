import LaTeXKit
import SwiftUI

/// Rechte Seitenleiste („Inspektor“): Schrift und Seite des ganzen Dokuments.
///
/// Wie „Dokument“ in Pages – nur dass jede Änderung als lesbare Zeile in der
/// Präambel landet (z. B. `\usepackage[margin=2.5cm]{geometry}`). So bleibt
/// die Datei mit Overleaf und TeXShop kompatibel.
struct DocumentInspector: View {
    let workspace: DocumentWorkspace

    private var settings: DocumentSettings { workspace.documentSettings }

    var body: some View {
        Form {
            if settings.documentClass == nil {
                Section {
                    Text("Dieses Dokument hat keine Präambel mit \\documentclass. Lege ein neues Dokument an oder füge eine Präambel ein, um Schrift und Seite hier einzustellen.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Schrift") {
                Picker("Schriftart", selection: binding(\.font)) {
                    ForEach(DocumentFont.allCases) { font in
                        Text(font.title).tag(font)
                    }
                }
                Text(settings.font.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Grundgrösse", selection: binding(\.baseFontSize)) {
                    Text("Standard (10 pt)").tag(Int?.none)
                    Text("10 pt").tag(Int?.some(10))
                    Text("11 pt").tag(Int?.some(11))
                    Text("12 pt").tag(Int?.some(12))
                }
            }

            Section("Seite") {
                Picker("Papier", selection: binding(\.paperSize)) {
                    Text("Standard").tag(PaperSize?.none)
                    ForEach(PaperSize.allCases) { size in
                        Text(size.title).tag(PaperSize?.some(size))
                    }
                }
                Picker("Ränder", selection: binding(\.margins)) {
                    ForEach(PageMargins.allCases) { margins in
                        Text(margins.title).tag(margins)
                    }
                }
                Picker("Zeilenabstand", selection: binding(\.lineSpacing)) {
                    ForEach(LineSpacing.allCases) { spacing in
                        Text(spacing.title).tag(spacing)
                    }
                }
            }

            Section {
                if let documentClass = settings.documentClass {
                    LabeledContent("Dokumentklasse") {
                        Text(verbatim: documentClass)
                            .font(.system(.body, design: .monospaced))
                    }
                }
            } footer: {
                Text("Änderungen werden als einzelne Zeilen in die Präambel geschrieben und lassen sich mit ⌘Z rückgängig machen.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .disabled(settings.documentClass == nil)
    }

    /// Bindung an eine Einstellung: Lesen aus der Präambel, Schreiben über den Arbeitsbereich.
    private func binding<Value>(_ keyPath: WritableKeyPath<DocumentSettings, Value>) -> Binding<Value> {
        Binding(
            get: { workspace.documentSettings[keyPath: keyPath] },
            set: { newValue in
                var updated = workspace.documentSettings
                updated[keyPath: keyPath] = newValue
                workspace.applyDocumentSettings(updated)
            }
        )
    }
}
