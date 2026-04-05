import SwiftUI

package enum XcodeThemeName: CaseIterable {
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

package struct XcodeColorThemeDefinition {
    package let backgroundColor: SyntaxColor
    package let rawStyles: [String: SyntaxStyle]

    package func style<StyleKind: Equatable>(for kind: StyleKind, styleKeyMap: [(StyleKind, [String])]) -> SyntaxStyle {
        let plainTextStyle = rawStyles["xcode.syntax.plain"]!
        guard let keys = styleKeyMap.first(where: { $0.0 == kind })?.1 else {
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

extension SyntaxStyle {
    package func mergingBuiltInThemeStyle(_ themeStyle: SyntaxStyle) -> SyntaxStyle {
        var style = self
        style.color = themeStyle.color
        if let fontName = themeStyle.font.name {
            style.font.name = fontName
        }
        style.font.weight = themeStyle.font.weight
        return style
    }
}
