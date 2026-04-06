@_exported import SyntaxInk

public typealias ObjCSyntaxHighlighter = SyntaxHighlighter<ObjCGrammar, ObjCTheme>

extension ObjCSyntaxHighlighter {
    public init(theme: ObjCTheme = .default) {
        self.init(grammar: ObjCGrammar(), theme: theme)
    }
}
