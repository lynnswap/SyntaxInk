import SyntaxInk

enum XcodeThemeName: CaseIterable {
    case bare
    case basic
    case civic
    case classicDark
    case classicLight
    case `default`
    case defaultDark
    case dusk
    case highContrastDark
    case highContrastLight
    case lowKey
    case midnight
    case presentationDark
    case presentationLight
    case presentationLargeDark
    case presentationLargeLight
    case printing
    case spartan
    case sunset
}

struct XcodeColorThemeDefinition {
    let backgroundColor: SyntaxColor
    let rawStyles: [String: SyntaxStyle]

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
        // The current highlighter does not distinguish system symbols from project symbols.
        // Keep the raw `*.system` entries in the generated registry, but resolve only the
        // generic variants until token classification becomes more precise.
        (.otherClassNames, ["xcode.syntax.identifier.class"]),
        (.otherFunctionAndMethodNames, ["xcode.syntax.identifier.function"]),
        (.otherTypeNames, ["xcode.syntax.identifier.type"]),
        (.otherPropertiesAndGlobals, [
            "xcode.syntax.identifier.variable",
            "xcode.syntax.identifier.constant",
        ]),
    ]

    func style(for kind: SwiftTheme.StyleKind) -> SyntaxStyle {
        let plainTextStyle = rawStyles["xcode.syntax.plain"]!
        guard let keys = Self.styleKeyMap.first(where: { $0.0 == kind })?.1 else {
            return plainTextStyle
        }

        for key in keys {
            if let style = rawStyles[key] {
                return style
            }
        }
        return plainTextStyle
    }
}

enum BuiltInThemeFactory {
    static func exactTheme(_ name: XcodeThemeName) -> SwiftTheme {
        let definition = BuiltInXcodeThemes.definition(for: name)
        return SwiftTheme { kind in
            definition.style(for: kind)
        }
    }

    static func mergedTheme(_ name: XcodeThemeName, base: SyntaxStyle) -> SwiftTheme {
        let definition = BuiltInXcodeThemes.definition(for: name)
        return SwiftTheme { kind in
            guard kind != .plainText else { return base }
            return base.mergingBuiltInThemeStyle(definition.style(for: kind))
        }
    }

    static func backgroundColor(for name: XcodeThemeName) -> SyntaxColor {
        BuiltInXcodeThemes.definition(for: name).backgroundColor
    }
}

extension SyntaxStyle {
    func mergingBuiltInThemeStyle(_ themeStyle: SyntaxStyle) -> SyntaxStyle {
        var style = self
        style.color = themeStyle.color
        if let fontName = themeStyle.font.name {
            style.font.name = fontName
        }
        style.font.weight = themeStyle.font.weight
        return style
    }
}
