#if os(macOS)
import SwiftUI

@available(iOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
@available(tvOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
@available(watchOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
@available(visionOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
public struct ObjCSyntaxHighlighterView: View {
    public let source: String
    public let fileKind: ObjCFileKind
    public let theme: ObjCTheme
    public let fileName: String

    public init(
        source: String,
        fileKind: ObjCFileKind,
        theme: ObjCTheme = .default,
        fileName: String? = nil
    ) {
        self.source = source
        self.fileKind = fileKind
        self.theme = theme
        self.fileName = fileName ?? fileKind.defaultFileName
    }

    public var body: some View {
        ObjCSourceEditorView(
            source: source,
            theme: theme,
            fileName: fileName
        )
    }
}
#endif
