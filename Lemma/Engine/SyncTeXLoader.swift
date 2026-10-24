import Foundation
import LaTeXKit

/// Liest eine `.synctex`- oder `.synctex.gz`-Datei ein.
enum SyncTeXLoader {
    static func load(from url: URL) -> SyncTeXIndex? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let text: String
        if url.pathExtension == "gz" {
            // gzip = Kopf + Deflate-Daten + Prüfsumme. NSData entpackt den
            // Deflate-Teil mit Apples Compression-Framework.
            guard let payload = Gzip.deflatePayload(of: data),
                  let inflated = try? (payload as NSData).decompressed(using: .zlib) as Data else {
                return nil
            }
            text = String(decoding: inflated, as: UTF8.self)
        } else {
            text = String(decoding: data, as: UTF8.self)
        }
        return SyncTeXIndex(text: text)
    }
}
