import AppKit
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
                .frame(minHeight: DocumentSplitView.Metrics.minHeight, maxHeight: .infinity)
                .navigationSplitViewColumnWidth(min: 150, ideal: 200, max: 320)
        } detail: {
            // Editor, Vorschau und Format-Seitenleiste in einer AppKit-Spaltenansicht
            // (Begründung siehe DocumentSplitView). Alle Spalten zusammen
            // passen auch auf Bildschirme mit 1024 Punkten Breite.
            DocumentSplitView(
                workspace: workspace,
                showsPreview: workspace.showsPreview,
                showsInspector: workspace.showsInspector
            )
        }
        .frame(minHeight: 400)
        .overlay(alignment: .bottom) {
            // Kurze Rückmeldungen („Gespeichert“, „PDF exportiert“ …).
            if let notice = workspace.notice {
                NoticeBanner(notice: notice) {
                    workspace.dismissNotice()
                }
                .padding(.bottom, 22)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.35), value: workspace.notice)
        // Anpassbare Symbolleiste wie in Pages (Darstellung → Symbolleiste anpassen).
        .toolbar(id: "lemma.document") {
            DocumentToolbar(workspace: workspace)
        }
        .toolbarRole(.editor)
        .focusedSceneValue(\.workspace, workspace)
        .sheet(isPresented: $workspace.isShowingLog) {
            LogView(log: workspace.lastLog ?? "")
        }
        // Bausteine in freier Grösse aus der Menüleiste (Tabelle …, Matrix … usw.).
        .sheet(item: $workspace.structureSheet) { structure in
            StructurePickerView(structure: structure, workspace: workspace)
                .environment(\.pickerIsSheet, true)
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

/// Schwebende Meldung unten im Fenster, verschwindet nach ein paar Sekunden.
private struct NoticeBanner: View {
    let notice: Notice
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: notice.symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
            Text(notice.message)
                .font(.callout)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            if let url = notice.revealURL {
                Button("Im Finder zeigen") {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                    dismiss()
                }
                .buttonStyle(.link)
                .font(.callout)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: 520)
        // Schwebt über dem Inhalt (funktionale Ebene): Liquid Glass.
        .glassEffect(.regular, in: Capsule())
        .onTapGesture(perform: dismiss)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }

    private var tint: Color {
        switch notice.style {
        case .success: return .green
        case .info: return .accentColor
        case .warning: return .orange
        }
    }
}
