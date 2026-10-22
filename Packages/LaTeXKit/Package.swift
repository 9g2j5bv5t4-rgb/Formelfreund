// swift-tools-version: 6.2
//
// LaTeXKit – die UI-freie Logik von Formelfreund.
//
// Alles, was nichts mit Fenstern, Knöpfen oder AppKit zu tun hat, lebt hier:
// Syntax-Analyse, Gliederung, Bearbeitungshilfen, Aufruf der TeX-Engines,
// Auswertung von Log-Dateien und SyncTeX. Das Paket hängt nur von Foundation ab
// und lässt sich deshalb auch ohne Xcode (z. B. unter Linux) bauen und testen.

import PackageDescription

let package = Package(
    name: "LaTeXKit",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .library(name: "LaTeXKit", targets: ["LaTeXKit"])
    ],
    targets: [
        .target(name: "LaTeXKit"),
        .testTarget(
            name: "LaTeXKitTests",
            dependencies: ["LaTeXKit"],
            resources: [.copy("Fixtures")]
        )
    ]
)
