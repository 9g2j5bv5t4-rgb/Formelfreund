import AppKit
import LaTeXKit
import SwiftUI

/// Merkt sich, mit welcher Vorlage das nächste neue Dokument beginnt.
///
/// `DocumentGroup` legt neue Dokumente selbst an (über `NSDocumentController`).
/// Die Galerie hinterlegt deshalb den Text hier und bittet dann um ein neues
/// Dokument; `LemmaApp` holt ihn beim Anlegen ab. Ein liegengebliebener Text
/// verfällt nach wenigen Sekunden, damit ⌘N danach wieder leer beginnt.
final class PendingTemplate: @unchecked Sendable {
    static let shared = PendingTemplate()

    private let lock = NSLock()
    private var text: String?
    private var date = Date.distantPast

    func set(_ text: String) {
        lock.withLock {
            self.text = text
            date = Date()
        }
    }

    /// Text für das neue Dokument (nur einmal abholbar).
    func take() -> String? {
        lock.withLock {
            defer { text = nil }
            return Date().timeIntervalSince(date) < 5 ? text : nil
        }
    }

    /// Neues Dokument mit diesem Inhalt öffnen.
    @MainActor
    static func newDocument(with template: DocumentTemplate) {
        shared.set(template.text)
        NSDocumentController.shared.newDocument(nil)
    }
}

/// „Ablage → Neu aus Vorlage …“: Vorlagen mit Vorschau der ersten Seite – wie in Pages.
struct TemplateGallery: View {
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var selection: DocumentTemplate.ID? = DocumentTemplate.exercise.id

    private let columns = [GridItem(.adaptive(minimum: 150, maximum: 190), spacing: 20, alignment: .top)]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Wähle eine Vorlage")
                        .font(.title2.weight(.semibold))
                    Text("Jede Vorlage ist ein vollständiges Dokument mit Erklärungen, wo du deine Angaben einträgst.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding([.horizontal, .top], 24)

                LazyVGrid(columns: columns, spacing: 22) {
                    ForEach(DocumentTemplate.all) { template in
                        TemplateCard(template: template, isSelected: selection == template.id)
                            .onTapGesture(count: 2) { create(template) }
                            .onTapGesture { selection = template.id }
                    }
                }
                .padding(24)
            }

            Divider()
            HStack {
                if let selected {
                    Text(selected.subtitle)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Button("Abbrechen", role: .cancel) { dismissWindow(id: Self.windowID) }
                    .keyboardShortcut(.cancelAction)
                Button("Erstellen") {
                    if let selected { create(selected) }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selected == nil)
            }
            .padding(16)
        }
        .frame(minWidth: 640, minHeight: 520)
    }

    static let windowID = "templates"

    private var selected: DocumentTemplate? {
        DocumentTemplate.all.first { $0.id == selection }
    }

    private func create(_ template: DocumentTemplate) {
        dismissWindow(id: Self.windowID)
        PendingTemplate.newDocument(with: template)
    }
}

/// Eine Vorlage: Vorschau der ersten Seite, Name darunter.
private struct TemplateCard: View {
    let template: DocumentTemplate
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 10) {
            preview
                .frame(height: 200)
            VStack(spacing: 2) {
                Text(template.title)
                    .font(.headline)
                Text(template.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2, reservesSpace: true)
            }
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.accentColor.opacity(0.14) : .clear)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 2)
        }
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint("Doppelklick erstellt ein neues Dokument")
    }

    /// Erste Seite der Vorlage als Bild auf einem „Blatt Papier“.
    private var preview: some View {
        Image(template.previewImageName)
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fit)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
            .overlay {
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(.black.opacity(0.08), lineWidth: 0.5)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
