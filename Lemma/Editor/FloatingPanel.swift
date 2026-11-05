import AppKit
import SwiftUI

/// Kleines schwebendes Fenster über dem Editor – für die Vorschlagsliste und die
/// Formelvorschau.
///
/// Es wird nie zum aktiven Fenster: Der Cursor bleibt im Editor, man tippt
/// einfach weiter. Als „Kindfenster“ wandert es mit, wenn man das Dokumentfenster
/// verschiebt, und verschwindet, wenn man zu einer anderen App wechselt.
final class FloatingPanel: NSPanel {
    private let effectView = NSVisualEffectView()

    init(content: NSView, material: NSVisualEffectView.Material = .popover) {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 100, height: 40), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        hidesOnDeactivate = true
        becomesKeyOnlyIfNeeded = true
        isReleasedWhenClosed = false
        animationBehavior = .none

        // Hintergrund wie bei Menüs und Popovers von macOS, mit runden Ecken.
        effectView.material = material
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.maskImage = Self.roundedMask(radius: 10)
        effectView.autoresizingMask = [.width, .height]
        content.frame = effectView.bounds
        content.autoresizingMask = [.width, .height]
        effectView.addSubview(content)
        contentView = effectView
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) wird nicht unterstützt")
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    /// Zeigt das Fenster an `frame` (Bildschirmkoordinaten) über `parentWindow`.
    func show(frame: NSRect, over parentWindow: NSWindow) {
        setFrame(frame, display: true)
        if parent !== parentWindow {
            parent?.removeChildWindow(self)
            parentWindow.addChildWindow(self, ordered: .above)
        }
        if !isVisible { orderFront(nil) }
        invalidateShadow()
    }

    func hide() {
        guard isVisible || parent != nil else { return }
        parent?.removeChildWindow(self)
        orderOut(nil)
    }

    /// Lage für ein Fenster der Grösse `size` unter (oder, wenn kein Platz ist, über) `anchor`.
    static func frame(size: NSSize, below anchor: NSRect, preferAbove: Bool = false, gap: CGFloat = 4) -> NSRect {
        let screen = NSScreen.screens.first { $0.frame.intersects(anchor) }?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        var x = anchor.minX
        x = min(x, screen.maxX - size.width - 4)
        x = max(x, screen.minX + 4)
        let below = anchor.minY - gap - size.height
        let above = anchor.maxY + gap
        var y: CGFloat
        if preferAbove {
            y = above + size.height <= screen.maxY ? above : below
        } else {
            y = below >= screen.minY ? below : above
        }
        y = min(max(y, screen.minY), screen.maxY - size.height)
        return NSRect(origin: NSPoint(x: x, y: y), size: size)
    }

    /// Maske mit runden Ecken, die sich beliebig strecken lässt.
    private static func roundedMask(radius: CGFloat) -> NSImage {
        let edge = radius * 2 + 1
        let image = NSImage(size: NSSize(width: edge, height: edge), flipped: false) { rect in
            NSColor.black.setFill()
            NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
            return true
        }
        image.capInsets = NSEdgeInsets(top: radius, left: radius, bottom: radius, right: radius)
        image.resizingMode = .stretch
        return image
    }
}

/// SwiftUI-Inhalt, der schon auf den ersten Klick reagiert – auch wenn sein
/// Fenster nicht aktiv ist.
final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
