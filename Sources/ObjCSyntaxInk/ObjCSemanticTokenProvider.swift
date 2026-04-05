import Foundation

enum ObjCSemanticTokenProvider {
    static func semanticTokens(for source: String) -> [ObjCSemanticToken]? {
#if os(macOS)
        SourceKitLSPClient.shared.semanticTokens(for: source, kind: .infer(from: source))
#else
        nil
#endif
    }
}
