@_exported import SyntaxInk
import Foundation

@available(iOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
@available(tvOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
@available(watchOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
@available(visionOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
struct ObjCExactTheme: Theme {
    typealias Token = ObjCToken
    let configuration: ObjCTheme.Configuration

    init(theme: ObjCTheme) {
        self.configuration = theme.configuration
    }

    func attributes(for token: ObjCToken) -> AttributedString {
        AttributedString(token.text)
            .applying(configuration.style(for: token.styleKind))
    }
}

typealias ObjCInternalExactHighlighter = SyntaxHighlighter<ObjCGrammar, ObjCExactTheme>

enum ObjCExactRenderer {
    static func highlight(_ code: String, theme: ObjCTheme = .default) -> AttributedString {
        ObjCInternalExactHighlighter(grammar: ObjCGrammar(), theme: ObjCExactTheme(theme: theme))
            .highlight(code)
    }
}
