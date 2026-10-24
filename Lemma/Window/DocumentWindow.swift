import LaTeXKit
import SwiftUI

/// Das Dokumentfenster: Seitenleiste | Editor | PDF-Vorschau.
struct DocumentWindow: View {
    let fileURL: URL?
    @State private var workspace: DocumentWorkspace

    init(document: TeXDocument, fileURL: URL?) {
        self.fileURL = fileURL
        _workspace = State(initialValue: DocumentWorkspace(document: document, fileURL: fileURL))
    }

    var body: some View {
        NavigationSplitView {
            OutlineSidebar(workspace: workspace)
                .navigationSplitViewColumnWidth(min: 160, ideal: 220, max: 340)
        } detail: {
            HSplitView {
                EditorPane(workspace: workspace)
                    .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
                if workspace.showsPreview {
                    PreviewPane(workspace: workspace)
                        .frame(minWidth: 240, maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .frame(minWidth: 760, minHeight: 480)
        .inspector(isPresented: $workspace.showsInspector) {
            DocumentInspector(workspace: workspace)
                .inspectorColumnWidth(min: 230, ideal: 270, max: 340)
        }
        .toolbar {
            DocumentToolbar(workspace: workspace)
        }
        .focusedSceneValue(\.workspace, workspace)
        .sheet(isPresented: $workspace.isShowingLog) {
            LogView(log: workspace.lastLog ?? "")
        }
        .onChange(of: fileURL) { _, newURL in
            workspace.fileURL = newURL
        }
        .task {
            // Ein geöffnetes Dokument gleich einmal kompilieren, damit die Vorschau erscheint.
            if AppSettings.autoCompile && workspace.status == .idle {
                workspace.compile()
            }
        }
    }
}

/// Symbolleiste des Dokumentfensters.
struct DocumentToolbar: ToolbarContent {
    let workspace: DocumentWorkspace

    var body: some ToolbarContent {
        ToolbarItem(placement: .status) {
            CompileStatusView(workspace: workspace)
        }

        ToolbarItem(placement: .primaryAction) {
            Button {
                workspace.compile()
            } label: {
                Label("Kompilieren", systemImage: "play.fill")
            }
            .help("Dokument kompilieren (⌘↩)")
        }

        ToolbarItem(placement: .primaryAction) {
            Toggle(isOn: Binding(
                get: { workspace.showsPreview },
                set: { workspace.showsPreview = $0 }
            )) {
                Label("PDF-Vorschau", systemImage: "doc.richtext")
            }
            .help("PDF-Vorschau ein- oder ausblenden (⌥⌘P)")
        }

        ToolbarItem(placement: .primaryAction) {
            Toggle(isOn: Binding(
                get: { workspace.showsInspector },
                set: { workspace.showsInspector = $0 }
            )) {
                Label("Inspektor", systemImage: "sidebar.trailing")
            }
            .help("Schrift und Seite des Dokuments einstellen (⌥⌘I)")
        }
    }
}
