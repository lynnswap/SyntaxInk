import SyntaxInk

enum BuiltInThemeFactory {
    private static let styleKeyMap: [(SwiftTheme.StyleKind, [String])] = [
        (.plainText, ["xcode.syntax.plain"]),
        (.keywords, ["xcode.syntax.keyword"]),
        (.comments, ["xcode.syntax.comment"]),
        (.documentationMarkup, ["xcode.syntax.comment.doc"]),
        (.string, ["xcode.syntax.string"]),
        (.numbers, ["xcode.syntax.number"]),
        (.preprocessorStatements, ["xcode.syntax.preprocessor"]),
        (.typeDeclarations, ["xcode.syntax.declaration.type"]),
        (.otherDeclarations, ["xcode.syntax.declaration.other"]),
        (.otherClassNames, ["xcode.syntax.identifier.class"]),
        (.otherFunctionAndMethodNames, ["xcode.syntax.identifier.function"]),
        (.otherTypeNames, ["xcode.syntax.identifier.type"]),
        (.otherPropertiesAndGlobals, [
            "xcode.syntax.identifier.variable",
            "xcode.syntax.identifier.constant",
        ]),
    ]

    static func exactTheme(_ name: XcodeThemeName) -> SwiftTheme {
        let definition = BuiltInXcodeThemes.definition(for: name)
        return SwiftTheme { kind in
            definition.style(for: kind, styleKeyMap: styleKeyMap)
        }
    }

    static func mergedTheme(_ name: XcodeThemeName, base: SyntaxStyle) -> SwiftTheme {
        let definition = BuiltInXcodeThemes.definition(for: name)
        return SwiftTheme { kind in
            guard kind != .plainText else { return base }
            return base.mergingBuiltInThemeStyle(definition.style(for: kind, styleKeyMap: styleKeyMap))
        }
    }

    static func backgroundColor(for name: XcodeThemeName) -> SyntaxColor {
        BuiltInXcodeThemes.definition(for: name).backgroundColor
    }
}
