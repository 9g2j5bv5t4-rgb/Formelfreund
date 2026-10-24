import AppKit
import SwiftUI

/// Editor | PDF-Vorschau | Inspektor nebeneinander – als native AppKit-Spaltenansicht.
///
/// Warum nicht SwiftUIs `HSplitView` und `.inspector`? Beim schnellen Ein- und
/// Ausblenden gaben sich deren Spalten gegenseitig wechselnde Mindestgrössen
/// weiter: Das Fenster wurde bei jedem Öffnen des Inspektors breiter (bis über
/// den Bildschirmrand hinaus), und auf kleinen Bildschirmen beendete macOS die
/// App wegen einer endlosen Layout-Schleife.
///
/// `NSSplitViewController` (wie in Mail oder Xcode) hat feste Mindestbreiten,
/// und beim Ein- und Ausblenden machen die Nachbarspalten Platz – das Fenster
/// behält seine Grösse. Ausgeblendete Spalten bleiben erhalten, die PDF-Ansicht
/// muss also nicht jedes Mal neu aufgebaut werden.
struct DocumentSplitView: NSViewControllerRepresentable {
    let workspace: DocumentWorkspace
    var showsPreview: Bool
    var showsInspector: Bool

    enum Metrics {
        static let editorMinWidth: CGFloat = 280
        static let previewMinWidth: CGFloat = 220
        static let inspectorMinWidth: CGFloat = 220
        static let inspectorIdealWidth: CGFloat = 250
        static let inspectorMaxWidth: CGFloat = 320
        static let minHeight: CGFloat = 200
    }

    func makeNSViewController(context: Context) -> DocumentSplitViewController {
        DocumentSplitViewController(workspace: workspace, showsPreview: showsPreview, showsInspector: showsInspector)
    }

    func updateNSViewController(_ controller: DocumentSplitViewController, context: Context) {
        controller.setPreviewVisible(showsPreview)
        controller.setInspectorVisible(showsInspector)
    }

    /// Mindestgrösse je nach sichtbaren Spalten – unabhängig vom Inhalt, damit
    /// sich nichts aufschaukeln kann. Nach oben ist die Grösse frei.
    func sizeThatFits(_ proposal: ProposedViewSize, nsViewController: DocumentSplitViewController, context: Context) -> CGSize? {
        var minWidth = Metrics.editorMinWidth
        if showsPreview { minWidth += Metrics.previewMinWidth + 1 }
        if showsInspector { minWidth += Metrics.inspectorMinWidth + 1 }
        let width = max(proposal.width ?? minWidth, minWidth)
        let height = max(proposal.height ?? Metrics.minHeight, Metrics.minHeight)
        return CGSize(width: width, height: height)
    }
}

/// Die eigentliche Spaltenansicht. Jede Spalte ist eine SwiftUI-Ansicht in
/// einem eigenen `NSHostingController`.
final class DocumentSplitViewController: NSSplitViewController {
    private let workspace: DocumentWorkspace
    private let editorItem: NSSplitViewItem
    private let previewItem: NSSplitViewItem
    private let inspectorItem: NSSplitViewItem

    /// Gewünschter Zustand (bei laufender Animation zeigt `isCollapsed` evtl. noch den alten).
    private var previewVisible: Bool
    private var inspectorVisible: Bool
    /// Laufende Ein-/Ausblend-Animationen.
    private var runningAnimations = 0

    init(workspace: DocumentWorkspace, showsPreview: Bool, showsInspector: Bool) {
        self.workspace = workspace
        previewVisible = showsPreview
        inspectorVisible = showsInspector
        editorItem = NSSplitViewItem(viewController: Self.host(EditorPane(workspace: workspace), width: 500))
        previewItem = NSSplitViewItem(viewController: Self.host(PreviewPane(workspace: workspace), width: 500))
        inspectorItem = NSSplitViewItem(viewController: Self.host(
            DocumentInspector(workspace: workspace),
            width: DocumentSplitView.Metrics.inspectorIdealWidth
        ))
        super.init(nibName: nil, bundle: nil)

        typealias Metrics = DocumentSplitView.Metrics
        editorItem.minimumThickness = Metrics.editorMinWidth
        editorItem.canCollapse = false

        previewItem.minimumThickness = Metrics.previewMinWidth
        previewItem.canCollapse = true
        previewItem.collapseBehavior = .preferResizingSiblingsWithFixedSplitView

        inspectorItem.minimumThickness = Metrics.inspectorMinWidth
        inspectorItem.maximumThickness = Metrics.inspectorMaxWidth
        inspectorItem.canCollapse = true
        inspectorItem.collapseBehavior = .preferResizingSiblingsWithFixedSplitView
        // Beim Vergrössern des Fensters behält der Inspektor seine Breite;
        // Editor und Vorschau bekommen den Platz.
        inspectorItem.holdingPriority = NSLayoutConstraint.Priority(260)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        addSplitViewItem(editorItem)
        addSplitViewItem(previewItem)
        addSplitViewItem(inspectorItem)
        previewItem.isCollapsed = !previewVisible
        inspectorItem.isCollapsed = !inspectorVisible

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(splitViewResized(_:)),
            name: NSSplitView.didResizeSubviewsNotification,
            object: splitView
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) wird nicht unterstützt")
    }

    /// SwiftUI-Ansicht als Spalte. `sizingOptions = []`: Die Spalte richtet sich
    /// nach der Spaltenansicht, nicht umgekehrt – so kann sich nichts aufschaukeln.
    private static func host<Content: View>(_ view: Content, width: CGFloat) -> NSViewController {
        let controller = NSHostingController(rootView: view)
        controller.sizingOptions = []
        controller.view.frame = NSRect(x: 0, y: 0, width: width, height: 600)
        return controller
    }

    // MARK: - Ein- und Ausblenden

    func setPreviewVisible(_ visible: Bool) {
        guard visible != previewVisible else { return }
        previewVisible = visible
        setCollapsed(previewItem, !visible)
    }

    func setInspectorVisible(_ visible: Bool) {
        guard visible != inspectorVisible else { return }
        inspectorVisible = visible
        setCollapsed(inspectorItem, !visible)
    }

    private func setCollapsed(_ item: NSSplitViewItem, _ collapsed: Bool) {
        // Ohne Fenster (noch nicht angezeigt) gibt es nichts zu animieren.
        guard isViewLoaded, view.window != nil else {
            item.isCollapsed = collapsed
            return
        }
        runningAnimations += 1
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.allowsImplicitAnimation = true
            item.animator().isCollapsed = collapsed
        } completionHandler: {
            Task { @MainActor [weak self] in
                self?.animationDidFinish()
            }
        }
    }

    private func animationDidFinish() {
        runningAnimations -= 1
        if runningAnimations == 0 { syncAfterUserChange() }
    }

    // MARK: - Zuklappen per Trennlinie

    @objc private func splitViewResized(_ notification: Notification) {
        if runningAnimations == 0 { syncAfterUserChange() }
    }

    /// Hat der Nutzer eine Spalte per Trennlinie zu- oder aufgeklappt, zeigen die
    /// Knöpfe in der Symbolleiste danach den richtigen Zustand.
    private func syncAfterUserChange() {
        let previewShown = !previewItem.isCollapsed
        let inspectorShown = !inspectorItem.isCollapsed
        guard previewShown != previewVisible || inspectorShown != inspectorVisible else { return }
        previewVisible = previewShown
        inspectorVisible = inspectorShown
        // Nicht mitten im Layout-Durchgang den SwiftUI-Zustand ändern.
        Task { @MainActor [workspace] in
            if workspace.showsPreview != previewShown { workspace.showsPreview = previewShown }
            if workspace.showsInspector != inspectorShown { workspace.showsInspector = inspectorShown }
        }
    }
}
