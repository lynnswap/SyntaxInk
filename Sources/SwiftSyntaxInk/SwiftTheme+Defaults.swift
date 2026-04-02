import SyntaxInk

extension SwiftTheme {
    public static let bare = BuiltInThemeFactory.exactTheme(.bare)
    public static func bare(_ base: SyntaxStyle) -> SwiftTheme { BuiltInThemeFactory.mergedTheme(.bare, base: base) }

    public static let basic = BuiltInThemeFactory.exactTheme(.basic)
    public static func basic(_ base: SyntaxStyle) -> SwiftTheme { BuiltInThemeFactory.mergedTheme(.basic, base: base) }

    public static let civic = BuiltInThemeFactory.exactTheme(.civic)
    public static func civic(_ base: SyntaxStyle) -> SwiftTheme { BuiltInThemeFactory.mergedTheme(.civic, base: base) }

    public static let classicDark = BuiltInThemeFactory.exactTheme(.classicDark)
    public static func classicDark(_ base: SyntaxStyle) -> SwiftTheme { BuiltInThemeFactory.mergedTheme(.classicDark, base: base) }

    public static let classicLight = BuiltInThemeFactory.exactTheme(.classicLight)
    public static func classicLight(_ base: SyntaxStyle) -> SwiftTheme { BuiltInThemeFactory.mergedTheme(.classicLight, base: base) }

    public static let `default` = BuiltInThemeFactory.exactTheme(.default)
    public static func `default`(_ base: SyntaxStyle) -> SwiftTheme { BuiltInThemeFactory.mergedTheme(.default, base: base) }

    public static let defaultDark = BuiltInThemeFactory.exactTheme(.defaultDark)
    public static func defaultDark(_ base: SyntaxStyle) -> SwiftTheme { BuiltInThemeFactory.mergedTheme(.defaultDark, base: base) }

    public static let dusk = BuiltInThemeFactory.exactTheme(.dusk)
    public static func dusk(_ base: SyntaxStyle) -> SwiftTheme { BuiltInThemeFactory.mergedTheme(.dusk, base: base) }

    public static let highContrastDark = BuiltInThemeFactory.exactTheme(.highContrastDark)
    public static func highContrastDark(_ base: SyntaxStyle) -> SwiftTheme { BuiltInThemeFactory.mergedTheme(.highContrastDark, base: base) }

    public static let highContrastLight = BuiltInThemeFactory.exactTheme(.highContrastLight)
    public static func highContrastLight(_ base: SyntaxStyle) -> SwiftTheme { BuiltInThemeFactory.mergedTheme(.highContrastLight, base: base) }

    public static let lowKey = BuiltInThemeFactory.exactTheme(.lowKey)
    public static func lowKey(_ base: SyntaxStyle) -> SwiftTheme { BuiltInThemeFactory.mergedTheme(.lowKey, base: base) }

    public static let midnight = BuiltInThemeFactory.exactTheme(.midnight)
    public static func midnight(_ base: SyntaxStyle) -> SwiftTheme { BuiltInThemeFactory.mergedTheme(.midnight, base: base) }

    public static let presentationDark = BuiltInThemeFactory.exactTheme(.presentationDark)
    public static func presentationDark(_ base: SyntaxStyle) -> SwiftTheme { BuiltInThemeFactory.mergedTheme(.presentationDark, base: base) }

    public static let presentationLight = BuiltInThemeFactory.exactTheme(.presentationLight)
    public static func presentationLight(_ base: SyntaxStyle) -> SwiftTheme { BuiltInThemeFactory.mergedTheme(.presentationLight, base: base) }

    public static let presentationLargeDark = BuiltInThemeFactory.exactTheme(.presentationLargeDark)
    public static func presentationLargeDark(_ base: SyntaxStyle) -> SwiftTheme { BuiltInThemeFactory.mergedTheme(.presentationLargeDark, base: base) }

    public static let presentationLargeLight = BuiltInThemeFactory.exactTheme(.presentationLargeLight)
    public static func presentationLargeLight(_ base: SyntaxStyle) -> SwiftTheme { BuiltInThemeFactory.mergedTheme(.presentationLargeLight, base: base) }

    public static let printing = BuiltInThemeFactory.exactTheme(.printing)
    public static func printing(_ base: SyntaxStyle) -> SwiftTheme { BuiltInThemeFactory.mergedTheme(.printing, base: base) }

    public static let spartan = BuiltInThemeFactory.exactTheme(.spartan)
    public static func spartan(_ base: SyntaxStyle) -> SwiftTheme { BuiltInThemeFactory.mergedTheme(.spartan, base: base) }

    public static let sunset = BuiltInThemeFactory.exactTheme(.sunset)
    public static func sunset(_ base: SyntaxStyle) -> SwiftTheme { BuiltInThemeFactory.mergedTheme(.sunset, base: base) }
}
