import SyntaxInk

extension ObjCTheme {
    public static let bare = ObjCBuiltInThemeFactory.exactTheme(.bare)
    public static func bare(_ base: SyntaxStyle) -> ObjCTheme { ObjCBuiltInThemeFactory.mergedTheme(.bare, base: base) }

    public static let basic = ObjCBuiltInThemeFactory.exactTheme(.basic)
    public static func basic(_ base: SyntaxStyle) -> ObjCTheme { ObjCBuiltInThemeFactory.mergedTheme(.basic, base: base) }

    public static let civic = ObjCBuiltInThemeFactory.exactTheme(.civic)
    public static func civic(_ base: SyntaxStyle) -> ObjCTheme { ObjCBuiltInThemeFactory.mergedTheme(.civic, base: base) }

    public static let classicDark = ObjCBuiltInThemeFactory.exactTheme(.classicDark)
    public static func classicDark(_ base: SyntaxStyle) -> ObjCTheme { ObjCBuiltInThemeFactory.mergedTheme(.classicDark, base: base) }

    public static let classicLight = ObjCBuiltInThemeFactory.exactTheme(.classicLight)
    public static func classicLight(_ base: SyntaxStyle) -> ObjCTheme { ObjCBuiltInThemeFactory.mergedTheme(.classicLight, base: base) }

    public static let `default` = ObjCBuiltInThemeFactory.exactTheme(.default)
    public static func `default`(_ base: SyntaxStyle) -> ObjCTheme { ObjCBuiltInThemeFactory.mergedTheme(.default, base: base) }

    public static let defaultDark = ObjCBuiltInThemeFactory.exactTheme(.defaultDark)
    public static func defaultDark(_ base: SyntaxStyle) -> ObjCTheme { ObjCBuiltInThemeFactory.mergedTheme(.defaultDark, base: base) }

    public static let dusk = ObjCBuiltInThemeFactory.exactTheme(.dusk)
    public static func dusk(_ base: SyntaxStyle) -> ObjCTheme { ObjCBuiltInThemeFactory.mergedTheme(.dusk, base: base) }

    public static let highContrastDark = ObjCBuiltInThemeFactory.exactTheme(.highContrastDark)
    public static func highContrastDark(_ base: SyntaxStyle) -> ObjCTheme { ObjCBuiltInThemeFactory.mergedTheme(.highContrastDark, base: base) }

    public static let highContrastLight = ObjCBuiltInThemeFactory.exactTheme(.highContrastLight)
    public static func highContrastLight(_ base: SyntaxStyle) -> ObjCTheme { ObjCBuiltInThemeFactory.mergedTheme(.highContrastLight, base: base) }

    public static let lowKey = ObjCBuiltInThemeFactory.exactTheme(.lowKey)
    public static func lowKey(_ base: SyntaxStyle) -> ObjCTheme { ObjCBuiltInThemeFactory.mergedTheme(.lowKey, base: base) }

    public static let midnight = ObjCBuiltInThemeFactory.exactTheme(.midnight)
    public static func midnight(_ base: SyntaxStyle) -> ObjCTheme { ObjCBuiltInThemeFactory.mergedTheme(.midnight, base: base) }

    public static let presentationDark = ObjCBuiltInThemeFactory.exactTheme(.presentationDark)
    public static func presentationDark(_ base: SyntaxStyle) -> ObjCTheme { ObjCBuiltInThemeFactory.mergedTheme(.presentationDark, base: base) }

    public static let presentationLight = ObjCBuiltInThemeFactory.exactTheme(.presentationLight)
    public static func presentationLight(_ base: SyntaxStyle) -> ObjCTheme { ObjCBuiltInThemeFactory.mergedTheme(.presentationLight, base: base) }

    public static let presentationLargeDark = ObjCBuiltInThemeFactory.exactTheme(.presentationLargeDark)
    public static func presentationLargeDark(_ base: SyntaxStyle) -> ObjCTheme { ObjCBuiltInThemeFactory.mergedTheme(.presentationLargeDark, base: base) }

    public static let presentationLargeLight = ObjCBuiltInThemeFactory.exactTheme(.presentationLargeLight)
    public static func presentationLargeLight(_ base: SyntaxStyle) -> ObjCTheme { ObjCBuiltInThemeFactory.mergedTheme(.presentationLargeLight, base: base) }

    public static let printing = ObjCBuiltInThemeFactory.exactTheme(.printing)
    public static func printing(_ base: SyntaxStyle) -> ObjCTheme { ObjCBuiltInThemeFactory.mergedTheme(.printing, base: base) }

    public static let spartan = ObjCBuiltInThemeFactory.exactTheme(.spartan)
    public static func spartan(_ base: SyntaxStyle) -> ObjCTheme { ObjCBuiltInThemeFactory.mergedTheme(.spartan, base: base) }

    public static let sunset = ObjCBuiltInThemeFactory.exactTheme(.sunset)
    public static func sunset(_ base: SyntaxStyle) -> ObjCTheme { ObjCBuiltInThemeFactory.mergedTheme(.sunset, base: base) }
}
