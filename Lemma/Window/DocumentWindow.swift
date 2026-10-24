import LaTeXKit
import SwiftUI

/// Das Dokumentfenster: Seitenleiste | Editor | PDF-Vorschau.
struct DocumentWindow: View {
    let fileURL: URL?
    @State private var workspace: DocumentWorkspace

    /// Mindesthöhe jeder Spalte – unabhängig von ihrem Inhalt.
    private static let minColumnHeight: CGFloat = 200

    init(document: TeXDocument, fileURL: URL?) {
        self.fileURL = fileURL
        _workspace = State(initialValue: DocumentWorkspace(document: document, fileURL: fileURL))
    }

    // Wichtig für die Stabilität:
    // - Jede Spalte bekommt feste Mindest- *und* Höchstmasse in beiden
    //   Richtungen, damit ihre Mindestgrösse nicht vom Inhalt abhängt.
    // - Alle Spalten zusammen (Seitenleiste 150 + Editor 280 + Vorschau 220 +
    //   Inspektor 250) bleiben unter 1024 Punkten, passen also auch auf kleine
    //   Bildschirme. Wäre das Fenster mindestens breiter als der Bildschirm,
    //   schaukeln sich Fenster und Spalten gegenseitig auf, bis macOS die App
    //   wegen einer endlosen Layout-Schleife beendet („Update Constraints in Window“).
    var body: some View {
        NavigationSplitView {
            OutlineSidebar(workspace: workspace)
                .frame(minHeight: Self.minColumnHeight, maxHeight: .infinity)
                .navigationSplitViewColumnWidth(min: 150, ideal: 200, max: 320)
        } detail: {
            HSplitView {
                EditorPane(workspace: workspace)
                    .frame(minWidth: 280, maxWidth: .infinity, minHeight: Self.minColumnHeight, maxHeight: .infinity)
                if workspace.showsPreview {
                    PreviewPane(workspace: workspace)
                        .frame(minWidth: 220, maxWidth: .infinity, minHeight: Self.minColumnHeight, maxHeight: .infinity)
                }
            }
        }
        .frame(minHeight: 400)
        .inspector(isPresented: $workspace.showsInspector) {
            DocumentInspector(workspace: workspace)
                .frame(minHeight: Self.minColumnHeight, maxHeight: .infinity)
                .inspectorColumnWidth(min: 220, ideal: 250, max: 320)
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
            // Nur in der CI aktiv (siehe SelfTest).
            await SelfTest.runIfEnabled(workspace)
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
