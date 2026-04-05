import SyntaxInk

enum ObjCBuiltInThemeFactory {
    private static let styleKeyMap: [(ObjCTheme.StyleKind, [String])] = [
        (.plainText, ["xcode.syntax.plain"]),
        (.keywords, ["xcode.syntax.keyword"]),
        (.comments, ["xcode.syntax.comment"]),
        (.documentationMarkup, ["xcode.syntax.comment.doc"]),
        (.string, ["xcode.syntax.string"]),
        (.numbers, ["xcode.syntax.number"]),
        (.preprocessorStatements, ["xcode.syntax.preprocessor"]),
        // Xcode uses declaration/type buckets for Objective-C interface and typedef heads,
        // while implementation heads are handled separately in the grammar and left plain.
        (.typeDeclarations, ["xcode.syntax.declaration.type"]),
        (.otherDeclarations, ["xcode.syntax.declaration.other"]),
        (.otherClassNames, ["xcode.syntax.identifier.class.system", "xcode.syntax.identifier.class"]),
        (.otherFunctionAndMethodNames, ["xcode.syntax.plain"]),
        (.otherTypeNames, ["xcode.syntax.identifier.type.system", "xcode.syntax.identifier.type"]),
        (.otherPropertiesAndGlobals, ["xcode.syntax.plain"]),
    ]

    static func exactTheme(_ name: XcodeThemeName) -> ObjCTheme {
        let definition = BuiltInXcodeThemes.definition(for: name)
        return ObjCTheme { kind in
            definition.style(for: kind, styleKeyMap: styleKeyMap)
        }
    }

    static func mergedTheme(_ name: XcodeThemeName, base: SyntaxStyle) -> ObjCTheme {
        let definition = BuiltInXcodeThemes.definition(for: name)
        return ObjCTheme { kind in
            guard kind != .plainText else { return base }
            return base.mergingBuiltInThemeStyle(definition.style(for: kind, styleKeyMap: styleKeyMap))
        }
    }
}
