import SyntaxInk
import SwiftUI

public typealias SwiftSyntaxHighlighter = SyntaxHighlighter<SwiftGrammar, SwiftTheme>

extension SwiftSyntaxHighlighter {
    public init(theme: SwiftTheme = .default) {
        self.init(grammar: SwiftGrammar(), theme: theme)
    }

    fileprivate static func makeColor(from syntaxColor: SyntaxColor) -> Color {
        Color(
            .sRGB,
            red: syntaxColor.red / 255.0,
            green: syntaxColor.green / 255.0,
            blue: syntaxColor.blue / 255.0,
            opacity: syntaxColor.alpha
        )
    }
}

extension SwiftUI.Color {
    public static let xcodeBackgroundBareColor = SwiftSyntaxHighlighter.makeColor(from: BuiltInThemeFactory.backgroundColor(for: .bare))
    public static let xcodeBackgroundBasicColor = SwiftSyntaxHighlighter.makeColor(from: BuiltInThemeFactory.backgroundColor(for: .basic))
    public static let xcodeBackgroundCivicColor = SwiftSyntaxHighlighter.makeColor(from: BuiltInThemeFactory.backgroundColor(for: .civic))
    public static let xcodeBackgroundClassicDarkColor = SwiftSyntaxHighlighter.makeColor(from: BuiltInThemeFactory.backgroundColor(for: .classicDark))
    public static let xcodeBackgroundClassicLightColor = SwiftSyntaxHighlighter.makeColor(from: BuiltInThemeFactory.backgroundColor(for: .classicLight))

    /// The background for default light theme of Xcode.
    public static let xcodeBackgroundDefaultColor = SwiftSyntaxHighlighter.makeColor(from: BuiltInThemeFactory.backgroundColor(for: .default))

    /// The background for default dark theme of Xcode.
    public static let xcodeBackgroundDefaultDarkColor = SwiftSyntaxHighlighter.makeColor(from: BuiltInThemeFactory.backgroundColor(for: .defaultDark))

    public static let xcodeBackgroundDuskColor = SwiftSyntaxHighlighter.makeColor(from: BuiltInThemeFactory.backgroundColor(for: .dusk))
    public static let xcodeBackgroundHighContrastDarkColor = SwiftSyntaxHighlighter.makeColor(from: BuiltInThemeFactory.backgroundColor(for: .highContrastDark))
    public static let xcodeBackgroundHighContrastLightColor = SwiftSyntaxHighlighter.makeColor(from: BuiltInThemeFactory.backgroundColor(for: .highContrastLight))
    public static let xcodeBackgroundLowKeyColor = SwiftSyntaxHighlighter.makeColor(from: BuiltInThemeFactory.backgroundColor(for: .lowKey))
    public static let xcodeBackgroundMidnightColor = SwiftSyntaxHighlighter.makeColor(from: BuiltInThemeFactory.backgroundColor(for: .midnight))
    public static let xcodeBackgroundPresentationDarkColor = SwiftSyntaxHighlighter.makeColor(from: BuiltInThemeFactory.backgroundColor(for: .presentationDark))
    public static let xcodeBackgroundPresentationLightColor = SwiftSyntaxHighlighter.makeColor(from: BuiltInThemeFactory.backgroundColor(for: .presentationLight))
    public static let xcodeBackgroundPresentationLargeDarkColor = SwiftSyntaxHighlighter.makeColor(from: BuiltInThemeFactory.backgroundColor(for: .presentationLargeDark))
    public static let xcodeBackgroundPresentationLargeLightColor = SwiftSyntaxHighlighter.makeColor(from: BuiltInThemeFactory.backgroundColor(for: .presentationLargeLight))
    public static let xcodeBackgroundPrintingColor = SwiftSyntaxHighlighter.makeColor(from: BuiltInThemeFactory.backgroundColor(for: .printing))
    public static let xcodeBackgroundSpartanColor = SwiftSyntaxHighlighter.makeColor(from: BuiltInThemeFactory.backgroundColor(for: .spartan))
    public static let xcodeBackgroundSunsetColor = SwiftSyntaxHighlighter.makeColor(from: BuiltInThemeFactory.backgroundColor(for: .sunset))
}
