import AppKit
import LaTeXKit
import SwiftUI

/// Die Format-Leiste über dem Editor – wie in Word oder Pages.
///
/// Jeder Knopf zeigt den Zustand an der Cursorposition (fett, Überschrift …)
/// und ruft beim Klicken eine Aktion des Arbeitsbereichs auf. Die Leiste
/// selbst enthält keine LaTeX-Logik.
struct FormatBar: View {
    let workspace: DocumentWorkspace

    private var state: FormatState { workspace.formatState }

    var body: some View {
        // Die Leiste passt sich der Breite der Editorspalte an – wie in Pages:
        // Ist wenig Platz, wandern Knöpfe gesammelt in ein Menü, statt
        // abgeschnitten zu werden. `ViewThatFits` nimmt die erste Variante,
        // die ganz hineinpasst.
        ViewThatFits(in: .horizontal) {
            fullLayout
            mediumLayout
            compactLayout
            // Menüs nur noch als Symbol (Name erscheint als Hilfetext).
            compactLayout.labelStyle(.iconOnly)
            // Notlösung für sehr schmale Spalten: seitlich scrollbar.
            ScrollView(.horizontal, showsIndicators: false) {
                compactLayout.labelStyle(.iconOnly)
            }
        }
        .background(.bar)
        .overlay(alignment: .bottom) { Divider() }
    }

    /// Alle Knöpfe einzeln sichtbar.
    private var fullLayout: some View {
        bar {
            paragraphStylePicker
            separator
            inlineStyleButtons
            FontMenu(workspace: workspace)
            separator
            alignmentPicker
            listButtons
            indentButtons
            separator
            InsertMenu(workspace: workspace)
            BlockMenu(workspace: workspace)
        }
    }

    /// Ausrichtung, Listen und Einrücken in einem Menü „Absatz“.
    private var mediumLayout: some View {
        bar {
            paragraphStylePicker
            separator
            inlineStyleButtons
            FontMenu(workspace: workspace)
            ParagraphMenu(workspace: workspace)
            separator
            InsertMenu(workspace: workspace)
            BlockMenu(workspace: workspace)
        }
    }

    /// Nur Fett/Kursiv/Unterstrichen direkt, alles andere im Menü „Format“.
    private var compactLayout: some View {
        bar {
            inlineStyleButtons
            CompactFormatMenu(workspace: workspace)
            separator
            InsertMenu(workspace: workspace)
            BlockMenu(workspace: workspace)
        }
    }

    private func bar<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        HStack(spacing: 8) {
            content()
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .fixedSize(horizontal: true, vertical: false)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var separator: some View {
        Divider().frame(height: 18)
    }

    // MARK: Absatzstil

    private var paragraphStylePicker: some View {
        Picker("Absatzstil", selection: Binding(
            get: { state.paragraph.style },
            set: { workspace.applyParagraphStyle($0) }
        )) {
            ForEach(ParagraphStyle.allCases) { style in
                Text(style.title).tag(style)
            }
        }
        .labelsHidden()
        .pickerStyle(.menu)
        .fixedSize()
        .help(paragraphHelp)
    }

    private var paragraphHelp: String {
        if let command = workspace.headingScheme.command(for: state.paragraph.style) {
            return "Absatzstil der aktuellen Zeile (LaTeX: \\\(command){…})"
        }
        return "Absatzstil der aktuellen Zeile"
    }

    // MARK: Fett, kursiv, unterstrichen

    private var inlineStyleButtons: some View {
        ControlGroup {
            styleToggle(.bold, shortcut: "⌘B")
            styleToggle(.italic, shortcut: "⌘I")
            styleToggle(.underline, shortcut: "⌘U")
        }
        .fixedSize()
    }

    private func styleToggle(_ style: InlineStyle, shortcut: String) -> some View {
        Toggle(isOn: Binding(
            get: { state.inline.styles.contains(style) },
            set: { _ in workspace.toggle(style) }
        )) {
            Label(style.title, systemImage: style.symbol)
        }
        .toggleStyle(.button)
        .labelStyle(.iconOnly)
        .help("\(style.title) (\(shortcut)) – LaTeX: \\\(style.command){…}")
    }

    // MARK: Ausrichtung, Listen, Einrücken

    private var alignmentPicker: some View {
        Picker("Ausrichtung", selection: Binding(
            get: { state.paragraph.alignment },
            set: { workspace.align($0) }
        )) {
            ForEach(TextAlignment.allCases) { alignment in
                Label(alignment.title, systemImage: alignment.symbol)
                    .labelStyle(.iconOnly)
                    .tag(alignment)
            }
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        .fixedSize()
        .help("Ausrichtung des Absatzes")
    }

    private var listButtons: some View {
        ControlGroup {
            ForEach(ListKind.allCases) { kind in
                Toggle(isOn: Binding(
                    get: { state.paragraph.list == kind },
                    set: { _ in workspace.toggleList(kind) }
                )) {
                    Label(kind.title, systemImage: kind.symbol)
                }
                .toggleStyle(.button)
                .labelStyle(.iconOnly)
                .help(kind.title)
            }
        }
        .fixedSize()
    }

    private var indentButtons: some View {
        ControlGroup {
            Button {
                workspace.shiftIndentation(outdent: true)
            } label: {
                Label("Ausrücken", systemImage: "decrease.indent")
            }
            .help("Ausrücken (⌘[)")
            Button {
                workspace.shiftIndentation(outdent: false)
            } label: {
                Label("Einrücken", systemImage: "increase.indent")
            }
            .help("Einrücken (⌘])")
        }
        .labelStyle(.iconOnly)
        .fixedSize()
    }
}

// MARK: - Absatz-Menü (schmale Leiste)

/// Ausrichtung, Listen und Einrücken als ein Menü.
struct ParagraphMenu: View {
    let workspace: DocumentWorkspace

    var body: some View {
        Menu {
            ParagraphMenuItems(workspace: workspace)
        } label: {
            Label("Absatz", systemImage: workspace.formatState.paragraph.alignment.symbol)
        }
        .fixedSize()
        .help("Ausrichtung, Listen und Einrücken")
    }
}

/// Einträge für Ausrichtung, Listen und Einrücken.
struct ParagraphMenuItems: View {
    let workspace: DocumentWorkspace

    private var state: FormatState { workspace.formatState }

    var body: some View {
        Section("Ausrichtung") {
            ForEach(TextAlignment.allCases) { alignment in
                Toggle(isOn: Binding(
                    get: { state.paragraph.alignment == alignment },
                    set: { _ in workspace.align(alignment) }
                )) {
                    Label(alignment.title, systemImage: alignment.symbol)
                }
            }
        }
        Section("Liste") {
            ForEach(ListKind.allCases) { kind in
                Toggle(isOn: Binding(
                    get: { state.paragraph.list == kind },
                    set: { _ in workspace.toggleList(kind) }
                )) {
                    Label(kind.title, systemImage: kind.symbol)
                }
            }
        }
        Section {
            Button {
                workspace.shiftIndentation(outdent: false)
            } label: {
                Label("Einrücken", systemImage: "increase.indent")
            }
            Button {
                workspace.shiftIndentation(outdent: true)
            } label: {
                Label("Ausrücken", systemImage: "decrease.indent")
            }
        }
    }
}

/// Absatzstil, Schrift und Absatz in einem Menü – für sehr schmale Spalten.
struct CompactFormatMenu: View {
    let workspace: DocumentWorkspace

    var body: some View {
        Menu {
            Picker("Absatzstil", selection: Binding(
                get: { workspace.formatState.paragraph.style },
                set: { workspace.applyParagraphStyle($0) }
            )) {
                ForEach(ParagraphStyle.allCases) { style in
                    Text(style.title).tag(style)
                }
            }
            Divider()
            FontMenuItems(workspace: workspace)
            Divider()
            ParagraphMenuItems(workspace: workspace)
        } label: {
            Label("Format", systemImage: "textformat")
        }
        .fixedSize()
        .help("Absatzstil, Schrift, Ausrichtung und Listen")
    }
}

// MARK: - Schrift-Menü

/// Schriftstil, Grösse und Farbe.
struct FontMenu: View {
    let workspace: DocumentWorkspace

    var body: some View {
        Menu {
            FontMenuItems(workspace: workspace)
        } label: {
            Label("Schrift", systemImage: "textformat")
        }
        .fixedSize()
        .help("Schriftstil, Schriftgrösse und Textfarbe")
    }
}

/// Einträge für Schriftstil, Grösse und Farbe.
struct FontMenuItems: View {
    let workspace: DocumentWorkspace

    private var state: FormatState { workspace.formatState }

    var body: some View {
        Section("Schriftstil") {
            ForEach([InlineStyle.emphasis, .sansSerif, .monospace, .smallCaps]) { style in
                Toggle(isOn: Binding(
                    get: { state.inline.styles.contains(style) },
                    set: { _ in workspace.toggle(style) }
                )) {
                    Label(style.title, systemImage: style.symbol)
                }
            }
        }
        Menu {
            ForEach(FontSize.allCases) { size in
                Toggle(size.title, isOn: Binding(
                    get: { (state.inline.fontSize ?? .normalsize) == size },
                    set: { _ in workspace.setFontSize(size) }
                ))
            }
        } label: {
            Label("Schriftgrösse", systemImage: "textformat.size")
        }
        Menu {
            ColorMenuItems(workspace: workspace)
        } label: {
            Label("Textfarbe", systemImage: "paintpalette")
        }
    }
}

/// Einträge für das Farbmenü (in der Leiste und in der Menüleiste).
struct ColorMenuItems: View {
    let workspace: DocumentWorkspace?

    var body: some View {
        Button("Keine Farbe") { workspace?.setColor(nil) }
        Divider()
        ForEach(TextColor.allCases) { color in
            Button {
                workspace?.setColor(color)
            } label: {
                Label {
                    Text(color.title)
                } icon: {
                    Image(nsImage: ColorSwatch.image(for: color))
                }
            }
        }
    }
}

/// Kleine farbige Kreise für Menüs. Menü-Symbole werden sonst einfarbig
/// dargestellt – ein Bild mit `isTemplate = false` behält seine Farbe.
enum ColorSwatch {
    @MainActor private static var cache: [TextColor: NSImage] = [:]

    @MainActor
    static func image(for color: TextColor) -> NSImage {
        if let cached = cache[color] { return cached }
        let rgb = color.rgb
        let nsColor = NSColor(srgbRed: rgb.red, green: rgb.green, blue: rgb.blue, alpha: 1)
        let image = NSImage(size: NSSize(width: 12, height: 12), flipped: false) { rect in
            nsColor.setFill()
            NSBezierPath(ovalIn: rect.insetBy(dx: 0.5, dy: 0.5)).fill()
            NSColor.black.withAlphaComponent(0.25).setStroke()
            NSBezierPath(ovalIn: rect.insetBy(dx: 0.5, dy: 0.5)).stroke()
            return true
        }
        image.isTemplate = false
        cache[color] = image
        return image
    }
}

// MARK: - Einfügen-Menü

/// Vordefinierte Bausteine, nach Gruppen sortiert.
struct InsertMenu: View {
    let workspace: DocumentWorkspace

    var body: some View {
        Menu {
            InsertMenuItems(workspace: workspace)
        } label: {
            Label("Einfügen", systemImage: "plus")
        }
        .fixedSize()
        .help("Baustein einfügen: Formeln, Überschriften, Listen, Bilder, Tabellen …")
    }
}

/// Einträge des Einfügen-Menüs (in der Leiste und in der Menüleiste).
struct InsertMenuItems: View {
    let workspace: DocumentWorkspace?

    var body: some View {
        ForEach(SnippetCategory.allCases) { category in
            Menu {
                ForEach(SnippetCatalog.snippets(in: category)) { snippet in
                    Button {
                        workspace?.insert(snippet)
                    } label: {
                        if let symbol = snippet.symbol {
                            Label(snippet.title, systemImage: symbol)
                        } else {
                            Text(snippet.title)
                        }
                    }
                    .help(snippet.help)
                }
            } label: {
                Label(category.title, systemImage: category.symbol)
            }
        }
        Divider()
        Button {
            workspace?.insertImageFromFile()
        } label: {
            Label("Bild aus Datei …", systemImage: "photo.badge.plus")
        }
    }
}

// MARK: - Block-Menü

/// Werkzeuge für ganze Blöcke – zeigt passende Umwandlungen für die Umgebung am Cursor.
struct BlockMenu: View {
    let workspace: DocumentWorkspace

    private var state: FormatState { workspace.formatState }

    var body: some View {
        Menu {
            Button("Block auswählen") { workspace.expandSelection() }

            if let environment = state.environment {
                let name = BlockEditor.displayName(for: environment)
                let conversions = BlockEditor.conversions(for: environment)
                if !conversions.isEmpty {
                    Menu("„\(name)“ umwandeln in") {
                        ForEach(conversions, id: \.self) { target in
                            Button(BlockEditor.displayName(for: target)) {
                                workspace.convertEnvironment(to: target)
                            }
                        }
                    }
                }
                if state.canToggleNumbering {
                    Button(environment.hasSuffix("*") ? "Formel nummerieren" : "Nummerierung entfernen") {
                        workspace.toggleNumbering()
                    }
                }
                Button("„\(name)“ auflösen (Inhalt behalten)") { workspace.unwrapEnvironment() }
            }

            if state.inMath {
                Button("Formel abgesetzt ↔ im Text") { workspace.toggleDisplayMath() }
            }

            Divider()
            WrapMenuItems(workspace: workspace)
            Divider()
            BlockLineItems(workspace: workspace)
        } label: {
            Label("Block", systemImage: "square.stack.3d.up")
        }
        .fixedSize()
        .help("Block-Werkzeuge: auswählen, umwandeln, einpacken, verschieben")
    }
}

/// „In Umgebung einpacken“.
struct WrapMenuItems: View {
    let workspace: DocumentWorkspace?

    var body: some View {
        Menu("In Umgebung einpacken") {
            ForEach(DocumentWorkspace.wrappableEnvironments, id: \.self) { name in
                Button(BlockEditor.displayName(for: name)) {
                    workspace?.wrapSelection(inEnvironment: name)
                }
            }
        }
    }
}

/// Zeilen verschieben und auskommentieren.
struct BlockLineItems: View {
    let workspace: DocumentWorkspace?

    var body: some View {
        Button("Zeilen nach oben") { workspace?.moveLines(up: true) }
        Button("Zeilen nach unten") { workspace?.moveLines(up: false) }
        Button("Auskommentieren ein/aus") { workspace?.toggleComment() }
    }
}
