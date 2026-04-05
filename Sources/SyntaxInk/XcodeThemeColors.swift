import SwiftUI

private enum XcodeThemeColorFactory {
    static func makeColor(from syntaxColor: SyntaxColor) -> Color {
        Color(
            .sRGB,
            red: syntaxColor.red / 255.0,
            green: syntaxColor.green / 255.0,
            blue: syntaxColor.blue / 255.0,
            opacity: syntaxColor.alpha
        )
    }

    static func backgroundColor(for name: XcodeThemeName) -> Color {
        makeColor(from: BuiltInXcodeThemes.definition(for: name).backgroundColor)
    }
}

extension SwiftUI.Color {
    public static let xcodeBackgroundBareColor = XcodeThemeColorFactory.backgroundColor(for: .bare)
    public static let xcodeBackgroundBasicColor = XcodeThemeColorFactory.backgroundColor(for: .basic)
    public static let xcodeBackgroundCivicColor = XcodeThemeColorFactory.backgroundColor(for: .civic)
    public static let xcodeBackgroundClassicDarkColor = XcodeThemeColorFactory.backgroundColor(for: .classicDark)
    public static let xcodeBackgroundClassicLightColor = XcodeThemeColorFactory.backgroundColor(for: .classicLight)
    public static let xcodeBackgroundDefaultColor = XcodeThemeColorFactory.backgroundColor(for: .default)
    public static let xcodeBackgroundDefaultDarkColor = XcodeThemeColorFactory.backgroundColor(for: .defaultDark)
    public static let xcodeBackgroundDuskColor = XcodeThemeColorFactory.backgroundColor(for: .dusk)
    public static let xcodeBackgroundHighContrastDarkColor = XcodeThemeColorFactory.backgroundColor(for: .highContrastDark)
    public static let xcodeBackgroundHighContrastLightColor = XcodeThemeColorFactory.backgroundColor(for: .highContrastLight)
    public static let xcodeBackgroundLowKeyColor = XcodeThemeColorFactory.backgroundColor(for: .lowKey)
    public static let xcodeBackgroundMidnightColor = XcodeThemeColorFactory.backgroundColor(for: .midnight)
    public static let xcodeBackgroundPresentationDarkColor = XcodeThemeColorFactory.backgroundColor(for: .presentationDark)
    public static let xcodeBackgroundPresentationLightColor = XcodeThemeColorFactory.backgroundColor(for: .presentationLight)
    public static let xcodeBackgroundPresentationLargeDarkColor = XcodeThemeColorFactory.backgroundColor(for: .presentationLargeDark)
    public static let xcodeBackgroundPresentationLargeLightColor = XcodeThemeColorFactory.backgroundColor(for: .presentationLargeLight)
    public static let xcodeBackgroundPrintingColor = XcodeThemeColorFactory.backgroundColor(for: .printing)
    public static let xcodeBackgroundSpartanColor = XcodeThemeColorFactory.backgroundColor(for: .spartan)
    public static let xcodeBackgroundSunsetColor = XcodeThemeColorFactory.backgroundColor(for: .sunset)
}
