import Foundation
import SyntaxInk

@available(iOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
@available(tvOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
@available(watchOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
@available(visionOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
public struct ObjCTheme: Sendable, Equatable {
    public let name: XcodeThemeName
    let configuration: Configuration

    init(name: XcodeThemeName, configuration: Configuration) {
        self.name = name
        self.configuration = configuration
    }

    public init(name: XcodeThemeName) {
        self = ObjCBuiltInThemeFactory.exactTheme(name)
    }

    public var displayName: String {
        name.displayName
    }

    public static func == (lhs: ObjCTheme, rhs: ObjCTheme) -> Bool {
        lhs.name == rhs.name
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

    struct Configuration: Sendable {
        let styleResolver: @Sendable (StyleKind) -> SyntaxStyle

        init(styleResolver: @escaping @Sendable (StyleKind) -> SyntaxStyle) {
            self.styleResolver = styleResolver
        }

        func style(for kind: StyleKind) -> SyntaxStyle {
            styleResolver(kind)
        }
    }
}
