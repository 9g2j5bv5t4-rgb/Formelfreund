import LaTeXKit
import SwiftUI

/// Rechte Spalte: PDF-Vorschau oder ein hilfreicher Platzhalter.
struct PreviewPane: View {
    let workspace: DocumentWorkspace

    var body: some View {
        ZStack(alignment: .top) {
            if workspace.pdfDocument != nil {
                PDFPreviewView(workspace: workspace)
                if workspace.isPDFOutdated {
                    OutdatedBadge(errorCount: workspace.errors.count) {
                        workspace.revealFirstError()
                    }
                    .padding(.top, 10)
                    .transition(.opacity)
                }
            } else {
                placeholder
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(nsColor: .underPageBackgroundColor))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: workspace.isPDFOutdated)
    }

    @ViewBuilder
    private var placeholder: some View {
        switch workspace.status {
        case .preparingEngine:
            EngineSetupView(engines: workspace.engines)
        case .compiling:
            VStack(spacing: 12) {
                ProgressView()
                Text(workspace.progressMessage ?? "Kompiliere …")
                    .foregroundStyle(.secondary)
            }
        case .failed:
            ContentUnavailableView {
                Label("Das Dokument enthält Fehler", systemImage: "exclamationmark.triangle")
            } description: {
                Text(workspace.errors.first?.message ?? "LaTeX konnte kein PDF erzeugen.")
            } actions: {
                Button("Zur Fehlerstelle") { workspace.revealFirstError() }
                    .disabled(workspace.errors.first?.line == nil)
            }
        case .engineUnavailable(let message):
            ContentUnavailableView {
                Label("LaTeX ist nicht verfügbar", systemImage: "wifi.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                Button("Erneut versuchen") { workspace.retryEngineSetup() }
                    .buttonStyle(.borderedProminent)
            }
        case .idle, .succeeded:
            ContentUnavailableView {
                Label("Noch keine Vorschau", systemImage: "doc.richtext")
            } description: {
                Text("Kompiliere das Dokument mit ⌘↩. Danach aktualisiert sich die Vorschau beim Tippen automatisch.")
            } actions: {
                Button("Jetzt kompilieren") { workspace.compile() }
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

/// Hinweis über dem PDF, wenn der letzte Lauf fehlgeschlagen ist.
private struct OutdatedBadge: View {
    let errorCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(
                errorCount == 1 ? "Vorschau veraltet – 1 Fehler" : "Vorschau veraltet – \(errorCount) Fehler",
                systemImage: "exclamationmark.triangle.fill"
            )
            .font(.callout)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(.separator))
        .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
        .help("Zur ersten Fehlerstelle springen")
    }
}

/// Wird beim allerersten Kompilieren gezeigt, während Tectonic geladen wird.
struct EngineSetupView: View {
    let engines: EngineManager

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "shippingbox")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.tint)
            Text("LaTeX wird eingerichtet")
                .font(.title3.weight(.semibold))
            Text("Beim ersten Mal lädt Formelfreund die LaTeX-Engine Tectonic (ca. 22 MB). Danach werden fehlende Pakete bei Bedarf automatisch nachgeladen.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 320)
            if let progress = engines.setupProgress {
                ProgressView(value: progress)
                    .frame(width: 220)
            } else {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(32)
    }
}
