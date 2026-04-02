@_exported import SyntaxInk
import SwiftUI

public typealias SwiftSyntaxHighlighter = SyntaxHighlighter<SwiftGrammar, SwiftTheme>

extension SwiftSyntaxHighlighter {
    public init(theme: SwiftTheme = .default) {
        self.init(grammar: SwiftGrammar(), theme: theme)
    }
}
