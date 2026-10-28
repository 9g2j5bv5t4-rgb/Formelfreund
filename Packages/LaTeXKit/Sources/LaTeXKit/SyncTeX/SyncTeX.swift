import Foundation

/// Position im PDF (in PDF-Punkten, Ursprung **oben links** der Seite).
public struct SyncTeXPosition: Equatable, Sendable {
    /// 1-basierte Seitennummer.
    public var page: Int
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(page: Int, x: Double, y: Double, width: Double, height: Double) {
        self.page = page
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

/// Position im Quelltext.
public struct SyncTeXSourceLocation: Equatable, Sendable {
    /// Pfad der Datei, so wie er in der SyncTeX-Datei steht.
    public var file: String
    /// 1-basierte Zeile.
    public var line: Int
}

/// Ausgewertete SyncTeX-Daten: Verknüpfung zwischen Quelltextzeilen und PDF-Stellen.
///
/// SyncTeX schreibt beim Setzen für jede Box auf jeder Seite mit, aus welcher
/// Datei und Zeile sie stammt. Damit springen wir
/// - vom Editor ins PDF (*Vorwärtssuche*) und
/// - von einem Klick im PDF zur Zeile im Editor (*Rückwärtssuche*).
public struct SyncTeXIndex: Sendable {
    /// Ein Eintrag der SyncTeX-Datei, bereits in PDF-Punkte umgerechnet.
    public struct Record: Sendable, Equatable {
        public enum Kind: UInt8, Sendable {
            case vbox, hbox, voidVBox, voidHBox, kern, glue, math, current
        }
        public var kind: Kind
        public var page: Int
        public var tag: Int
        public var line: Int
        /// Linke Kante.
        public var h: Double
        /// Grundlinie (von oben gemessen).
        public var v: Double
        public var width: Double
        public var height: Double
        public var depth: Double

        var isBox: Bool { kind == .hbox || kind == .voidHBox }
        var top: Double { v - height }
        var bottom: Double { v + max(depth, 0) }
    }

    /// Eingabedateien: Nummer → Pfad.
    public private(set) var inputs: [Int: String] = [:]
    public private(set) var records: [Record] = []

    /// TeX rechnet in „scaled points“: 65 781,76 sp = 1 PDF-Punkt (1/72 Zoll).
    static let scaledPointsPerBigPoint = 65_781.76

    /// Liest den (bereits entpackten) Inhalt einer `.synctex`-Datei.
    public init?(text: String) {
        var unit = 1.0
        var magnification = 1000.0
        var xOffset = 0.0
        var yOffset = 0.0
        var page = 0
        var inContent = false
        var rawRecords: [(Record.Kind, Int, Int, Int, Int, Int, Int, Int, Int)] = []

        for line in text.split(separator: "\n", omittingEmptySubsequences: true) {
            guard let first = line.first else { continue }

            if line.hasPrefix("Input:") {
                // Input:3:/pfad/zur/datei.tex
                let rest = line.dropFirst("Input:".count)
                if let colon = rest.firstIndex(of: ":"), let tag = Int(rest[..<colon]) {
                    inputs[tag] = String(rest[rest.index(after: colon)...])
                }
                continue
            }
            if !inContent {
                if line.hasPrefix("Unit:") { unit = Double(line.dropFirst(5)) ?? 1 }
                else if line.hasPrefix("Magnification:") { magnification = Double(line.dropFirst(14)) ?? 1000 }
                else if line.hasPrefix("X Offset:") { xOffset = Double(line.dropFirst(9)) ?? 0 }
                else if line.hasPrefix("Y Offset:") { yOffset = Double(line.dropFirst(9)) ?? 0 }
                else if line.hasPrefix("Content:") { inContent = true }
                continue
            }
            if line.hasPrefix("Postamble:") { break }

            switch first {
            case "{":
                page = Int(line.dropFirst()) ?? page
                continue
            case "}", "]", ")", "!":
                continue
            default:
                break
            }

            let kind: Record.Kind
            switch first {
            case "[": kind = .vbox
            case "(": kind = .hbox
            case "v": kind = .voidVBox
            case "h": kind = .voidHBox
            case "k": kind = .kern
            case "g": kind = .glue
            case "$": kind = .math
            case "x": kind = .current
            default: continue
            }

            // Format: <art>tag,zeile[,spalte]:h,v[:breite[,höhe,tiefe]]
            let fields = line.dropFirst().split(separator: ":", omittingEmptySubsequences: false)
            guard fields.count >= 2 else { continue }
            let link = fields[0].split(separator: ",")
            let point = fields[1].split(separator: ",")
            guard link.count >= 2, point.count >= 2,
                  let tag = Int(link[0]), let lineNumber = Int(link[1]),
                  let h = Int(point[0]), let v = Int(point[1]) else { continue }
            var width = 0, height = 0, depth = 0
            if fields.count >= 3 {
                let size = fields[2].split(separator: ",")
                width = size.count > 0 ? Int(size[0]) ?? 0 : 0
                height = size.count > 1 ? Int(size[1]) ?? 0 : 0
                depth = size.count > 2 ? Int(size[2]) ?? 0 : 0
            }
            rawRecords.append((kind, page, tag, lineNumber, h, v, width, height, depth))
        }

        guard inContent else { return nil }

        // Umrechnung in PDF-Punkte. Die Koordinaten von pdfTeX und XeTeX enthalten
        // den TeX-Ursprung (1 Zoll vom Seitenrand) bereits.
        let factor = unit * (magnification / 1000.0) / Self.scaledPointsPerBigPoint
        records = rawRecords.map { raw in
            Record(
                kind: raw.0,
                page: raw.1,
                tag: raw.2,
                line: raw.3,
                h: (Double(raw.4) + xOffset) * factor,
                v: (Double(raw.5) + yOffset) * factor,
                width: Double(raw.6) * factor,
                height: Double(raw.7) * factor,
                depth: Double(raw.8) * factor
            )
        }
    }

    /// Nummer der Eingabedatei mit diesem Dateinamen (z. B. `main.tex`).
    public func tag(forFileNamed name: String) -> Int? {
        inputs
            .filter { ($0.value as NSString).lastPathComponent == name }
            .map(\.key)
            .min()
    }

    /// Erste und letzte Zeile einer Datei, die auf einer PDF-Seite (1-basiert) vorkommen –
    /// z. B. für „Ränder nur für diese Seite“.
    public func lineRange(onPage page: Int, fileName: String) -> ClosedRange<Int>? {
        guard let tag = tag(forFileNamed: fileName) else { return nil }
        let lines = records.filter { $0.tag == tag && $0.page == page && $0.line > 0 }.map(\.line)
        guard let first = lines.min(), let last = lines.max() else { return nil }
        return first...last
    }

    // MARK: - Vorwärtssuche: Zeile → PDF

    public func forwardSearch(line: Int, fileName: String) -> SyncTeXPosition? {
        guard let tag = tag(forFileNamed: fileName) else { return nil }
        let candidates = records.filter { $0.tag == tag && $0.line > 0 }
        guard !candidates.isEmpty else { return nil }

        // Exakte Zeile bevorzugen, sonst die nächstgelegene davor, sonst danach.
        let lines = Set(candidates.map(\.line))
        let target: Int
        if lines.contains(line) {
            target = line
        } else if let before = lines.filter({ $0 < line }).max() {
            target = before
        } else if let after = lines.filter({ $0 > line }).min() {
            target = after
        } else {
            return nil
        }

        let onLine = candidates.filter { $0.line == target }
        guard let page = onLine.map(\.page).min() else { return nil }
        let onPage = onLine.filter { $0.page == page }
        let boxes = onPage.filter { $0.isBox && $0.width > 0 }

        if !boxes.isEmpty {
            let minX = boxes.map(\.h).min()!
            let maxX = boxes.map { $0.h + $0.width }.max()!
            let minY = boxes.map(\.top).min()!
            let maxY = boxes.map(\.bottom).max()!
            return SyncTeXPosition(page: page, x: minX, y: minY, width: maxX - minX, height: max(maxY - minY, 8))
        }
        // Nur Punkte (Kerning, Leerraum): kleines Rechteck um den ersten Punkt.
        let first = onPage[0]
        return SyncTeXPosition(page: page, x: first.h, y: first.v - 10, width: 20, height: 12)
    }

    // MARK: - Rückwärtssuche: PDF → Zeile

    /// - Parameters:
    ///   - page: 1-basierte Seite.
    ///   - x, y: Klickposition in PDF-Punkten, Ursprung oben links.
    public func backwardSearch(page: Int, x: Double, y: Double) -> SyncTeXSourceLocation? {
        let onPage = records.filter { $0.page == page && $0.line > 0 }
        guard !onPage.isEmpty else { return nil }

        // 1. Kleinste horizontale Box, die den Punkt enthält.
        let containing = onPage.filter {
            $0.isBox && x >= $0.h && x <= $0.h + $0.width && y >= $0.top - 1 && y <= $0.bottom + 1
        }
        if let box = containing.min(by: { $0.width * ($0.height + $0.depth) < $1.width * ($1.height + $1.depth) }) {
            // 2. Innerhalb der Box: nächstgelegener Eintrag (Leerraum, Kerning) auf
            //    gleicher Grundlinie. Die Box selbst trägt die Zeile, in der TeX den
            //    Absatz beendet hat – oft die Leerzeile *nach* dem Text.
            let inner = onPage.filter {
                !$0.isBox && $0.kind != .vbox && $0.tag == box.tag
                    && abs($0.v - box.v) < 0.5 && $0.h >= box.h && $0.h <= box.h + box.width
            }
            let best = inner.min(by: { abs($0.h - x) < abs($1.h - x) }) ?? box
            return location(for: best)
        }

        // 3. Sonst: nächstgelegener Eintrag.
        let nearest = onPage.min { distance($0, x, y) < distance($1, x, y) }
        return nearest.flatMap(location(for:))
    }

    private func distance(_ record: Record, _ x: Double, _ y: Double) -> Double {
        let dx: Double
        if x < record.h { dx = record.h - x } else if x > record.h + record.width { dx = x - (record.h + record.width) } else { dx = 0 }
        let dy: Double
        if y < record.top { dy = record.top - y } else if y > record.bottom { dy = y - record.bottom } else { dy = 0 }
        return dx * dx + dy * dy
    }

    private func location(for record: Record) -> SyncTeXSourceLocation? {
        guard let file = inputs[record.tag] else { return nil }
        return SyncTeXSourceLocation(file: file, line: record.line)
    }
}

// MARK: - gzip

/// Hilfsfunktionen für gzip-Dateien (`.synctex.gz`).
///
/// Apples Compression-Framework entpackt nur den rohen „Deflate“-Datenstrom.
/// Eine gzip-Datei hat davor einen Kopf und danach eine Prüfsumme – diese
/// Funktion schneidet beides ab.
public enum Gzip {
    /// Liefert den Deflate-Datenstrom einer gzip-Datei, oder `nil`, wenn es kein gzip ist.
    public static func deflatePayload(of data: Data) -> Data? {
        let bytes = [UInt8](data)
        guard bytes.count > 18, bytes[0] == 0x1F, bytes[1] == 0x8B, bytes[2] == 8 else { return nil }
        let flags = bytes[3]
        var index = 10
        if flags & 0x04 != 0 {   // FEXTRA
            guard index + 2 <= bytes.count else { return nil }
            let length = Int(bytes[index]) | (Int(bytes[index + 1]) << 8)
            index += 2 + length
        }
        if flags & 0x08 != 0 {   // FNAME (nullterminiert)
            while index < bytes.count && bytes[index] != 0 { index += 1 }
            index += 1
        }
        if flags & 0x10 != 0 {   // FCOMMENT (nullterminiert)
            while index < bytes.count && bytes[index] != 0 { index += 1 }
            index += 1
        }
        if flags & 0x02 != 0 {   // FHCRC
            index += 2
        }
        let end = bytes.count - 8   // CRC32 + Grösse
        guard index < end else { return nil }
        return Data(bytes[index..<end])
    }

    /// Unkomprimierte Grösse laut gzip-Trailer (modulo 4 GB).
    public static func uncompressedSize(of data: Data) -> Int? {
        let bytes = [UInt8](data.suffix(4))
        guard bytes.count == 4 else { return nil }
        return Int(bytes[0]) | Int(bytes[1]) << 8 | Int(bytes[2]) << 16 | Int(bytes[3]) << 24
    }
}
