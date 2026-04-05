@_exported import SyntaxInk

@available(iOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
@available(tvOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
@available(watchOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
@available(visionOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
public typealias ObjCSyntaxHighlighter = SyntaxHighlighter<ObjCGrammar, ObjCTheme>

extension ObjCSyntaxHighlighter {
    public init(theme: ObjCTheme = .default) {
        self.init(grammar: ObjCGrammar(), theme: theme)
    }
}
