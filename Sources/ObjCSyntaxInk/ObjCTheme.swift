import Foundation
import SyntaxInk

@available(iOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
@available(tvOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
@available(watchOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
@available(visionOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
public struct ObjCTheme: Theme {
    public typealias Token = ObjCToken
    public var configuration: Configuration

    public init(_ styleResolver: @escaping @Sendable (StyleKind) -> SyntaxStyle) {
        self.configuration = Configuration(styleResolver: styleResolver)
    }

    public func attributes(for token: ObjCToken) -> AttributedString {
        AttributedString(token.text)
            .applying(configuration.style(for: token.styleKind))
    }
}

extension ObjCTheme {
    public enum StyleKind: Sendable {
        case plainText
        case keywords
        case comments
        case documentationMarkup
        case string
        case numbers
        case preprocessorStatements
        case typeDeclarations
        case otherDeclarations
        case otherClassNames
        case otherFunctionAndMethodNames
        case otherTypeNames
        case otherPropertiesAndGlobals
    }

    public struct Configuration: Sendable {
        public var styleResolver: @Sendable (StyleKind) -> SyntaxStyle

        func style(for kind: StyleKind) -> SyntaxStyle {
            styleResolver(kind)
        }
    }
}
