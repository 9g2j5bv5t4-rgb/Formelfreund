import AppKit
import LaTeXKit
import SwiftUI

// Einträge für die Menüleiste (Menüs „Format“ und „Einfügen“) und für das
// Menü „Bausteine“ in der Symbolleiste.

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
