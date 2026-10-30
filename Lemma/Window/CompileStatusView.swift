import LaTeXKit
import SwiftUI

/// Kompakte Statusanzeige in der Symbolleiste. Ein Klick zeigt alle Meldungen.
struct CompileStatusView: View {
    let workspace: DocumentWorkspace
    @State private var showsIssues = false

    var body: some View {
        Button {
            showsIssues.toggle()
        } label: {
            HStack(spacing: 6) {
                icon
                Text(title)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .monospacedDigit()
            }
            .font(.callout)
            .padding(.horizontal, 4)
            // Feste Breite: Die Symbolleiste soll nicht bei jeder Statusänderung
            // neu angeordnet werden (das löste zusammen mit dem Fenster-Layout
            // unnötige Layout-Durchgänge aus).
            .frame(width: 200)
        }
        .buttonStyle(.borderless)
        .help("Meldungen anzeigen")
        .popover(isPresented: $showsIssues, arrowEdge: .bottom) {
            IssueListView(workspace: workspace) {
                showsIssues = false
            }
        }
    }

    @ViewBuilder
    private var icon: some View {
        switch workspace.status {
        case .idle:
            Image(systemName: "circle.dashed")
                .foregroundStyle(.secondary)
        case .preparingEngine, .compiling:
            ProgressView()
                .controlSize(.small)
        case .succeeded:
            if workspace.warnings.isEmpty {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
            }
        case .failed:
            Image(systemName: "xmark.octagon.fill")
                .foregroundStyle(.red)
        case .engineUnavailable:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
        }
    }

    private var title: String {
        switch workspace.status {
        case .idle:
            return "Noch nicht kompiliert"
        case .preparingEngine:
            if let progress = workspace.engines.setupProgress {
                return "LaTeX wird eingerichtet … \(Int(progress * 100)) %"
            }
            return "LaTeX wird eingerichtet …"
        case .compiling:
            return workspace.progressMessage ?? "Kompiliere …"
        case .succeeded(let duration):
            let seconds = duration.formatted(.number.precision(.fractionLength(1)))
            let warnings = workspace.warnings.count
            if warnings > 0 {
                return warnings == 1 ? "Kompiliert · 1 Warnung" : "Kompiliert · \(warnings) Warnungen"
            }
            return "Kompiliert in \(seconds) s"
        case .failed:
            let count = workspace.errors.count
            return count == 1 ? "1 Fehler" : "\(count) Fehler"
        case .engineUnavailable:
            return "LaTeX nicht verfügbar"
        }
    }
}
