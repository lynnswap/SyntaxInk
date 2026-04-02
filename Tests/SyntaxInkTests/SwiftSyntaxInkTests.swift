import AppKit
import SwiftUI
import Testing
@testable import SyntaxInk
@testable import SwiftSyntaxInk

@Test func builtInThemesExposeExpectedPlainKeywordAndStringStyles() async throws {
    for expectation in themeExpectations {
        assertStyle(expectation.theme.configuration.styleResolver(.plainText), equals: expectation.plain)
        assertStyle(expectation.theme.configuration.styleResolver(.keywords), equals: expectation.keyword)
        assertStyle(expectation.theme.configuration.styleResolver(.string), equals: expectation.string)
    }
}

@Test func builtInThemesExposeExpectedBackgroundColors() async throws {
    for expectation in themeExpectations {
        assertBackgroundColor(expectation.backgroundColor, equals: expectation.expectedBackground)
    }
}

@Test func builtInThemeBaseOverloadsPreserveBaseFontCharacteristics() async throws {
    let base = SyntaxStyle(
        font: .custom(name: "Menlo", size: 22.0, weight: .thin),
        color: SyntaxColor(red: 1.0, green: 2.0, blue: 3.0)
    )

    for expectation in themeExpectations {
        let themed = expectation.themeWithBase(base)
        assertStyle(themed.configuration.styleResolver(.plainText), equals: base)
        assertStyle(themed.configuration.styleResolver(.keywords), equals: merged(base: base, themed: expectation.keyword))
        assertStyle(themed.configuration.styleResolver(.string), equals: merged(base: base, themed: expectation.string))
    }
}

@Test func defaultHighlighterAppliesExpectedStyles() async throws {
    let highlighted = SwiftSyntaxHighlighter(theme: .default).highlight(sampleCode)
    let expectation = themeExpectations.first { $0.name == "default" }!

    #expect(String(highlighted.characters) == sampleCode)

    assertTokenAttributes(theme: .default, tokenText: "let", containing: "/// Doc comment", equals: defaultDocumentationMarkup)
    assertTokenAttributes(theme: .default, tokenText: "let", containing: "let", equals: expectation.keyword)
    assertTokenAttributes(theme: .default, tokenText: "Hello", containing: "Hello", equals: expectation.string)
    assertTokenAttributes(theme: .default, tokenText: "42", containing: "42", equals: defaultNumberStyle)
}

@Test func presentationDarkHighlighterAppliesExpectedStyles() async throws {
    let highlighted = SwiftSyntaxHighlighter(theme: .presentationDark).highlight(sampleCode)
    let expectation = themeExpectations.first { $0.name == "presentationDark" }!

    #expect(String(highlighted.characters) == sampleCode)

    assertTokenAttributes(theme: .presentationDark, tokenText: "let", containing: "/// Doc comment", equals: presentationDarkDocumentationMarkup)
    assertTokenAttributes(theme: .presentationDark, tokenText: "let", containing: "let", equals: expectation.keyword)
    assertTokenAttributes(theme: .presentationDark, tokenText: "Hello", containing: "Hello", equals: expectation.string)
    assertTokenAttributes(theme: .presentationDark, tokenText: "42", containing: "42", equals: presentationDarkNumberStyle)
}

private func assertTokenAttributes(theme: SwiftTheme, tokenText: String, containing text: String, equals expected: SyntaxStyle) {
    let token = SwiftGrammar().tokenize(sampleCode).first(where: { $0.text == tokenText })
    guard let token else {
        Issue.record("Could not find token \(tokenText)")
        return
    }

    let attributed = theme.attributes(for: token)
    assertRenderedRun(in: attributed, containing: text, equals: expected)
}

private func assertRun(in attributedString: AttributedString, containing text: String, equals expected: SyntaxStyle) {
    for run in attributedString.runs {
        guard let style = style(from: run) else {
            continue
        }
        let runText = String(attributedString[run.range].characters)
        if runText.contains(text) {
            assertStyle(style, equals: expected)
            return
        }
    }

    Issue.record("Could not find attributed run containing \(text)")
}

private func assertRenderedRun(in attributedString: AttributedString, containing text: String, equals expected: SyntaxStyle) {
    for run in attributedString.runs {
        guard let style = style(from: run) else {
            continue
        }
        let runText = String(attributedString[run.range].characters)
        if runText.contains(text) {
            assertRenderedStyle(style, equals: expected)
            return
        }
    }

    Issue.record("Could not find attributed run containing \(text)")
}

private func style(from run: AttributedString.Runs.Run) -> SyntaxStyle? {
    guard let color = run.swiftUI.foregroundColor,
          let font = run.swiftUI.font,
          let syntaxColor = syntaxColor(from: color),
          let syntaxFont = syntaxFont(from: font) else {
        return nil
    }

    return SyntaxStyle(font: syntaxFont, color: syntaxColor)
}

private func assertBackgroundColor(_ actual: Color, equals expected: SyntaxColor) {
    guard let nsColor = NSColor(actual).usingColorSpace(.deviceRGB) else {
        Issue.record("Could not convert background color to device RGB")
        return
    }

    assertApproximatelyEqual(Double(nsColor.redComponent), expected.red / 255.0)
    assertApproximatelyEqual(Double(nsColor.greenComponent), expected.green / 255.0)
    assertApproximatelyEqual(Double(nsColor.blueComponent), expected.blue / 255.0)
    assertApproximatelyEqual(Double(nsColor.alphaComponent), expected.alpha)
}

private func syntaxColor(from color: Color) -> SyntaxColor? {
    guard let nsColor = NSColor(color).usingColorSpace(.deviceRGB) else {
        return nil
    }

    return SyntaxColor(
        red: nsColor.redComponent * 255.0,
        green: nsColor.greenComponent * 255.0,
        blue: nsColor.blueComponent * 255.0,
        alpha: nsColor.alphaComponent
    )
}

private func syntaxFont(from font: Font) -> SyntaxFont? {
    guard let provider = child(named: "provider", in: font),
          let base = child(named: "base", in: provider) else {
        return nil
    }

    let baseTypeName = String(describing: type(of: base))
    if baseTypeName.contains("SystemProvider") {
        guard let size = child(named: "size", in: base) as? CGFloat else {
            return nil
        }

        let weight = unwrapOptional(child(named: "weight", in: base)) as? Font.Weight ?? .regular
        let design = unwrapOptional(child(named: "design", in: base)) as? Font.Design ?? .default
        return .system(size: size, weight: weight, design: design)
    }

    if baseTypeName.contains("ModifierProvider"),
       let baseFont = child(named: "base", in: base) as? Font,
       let modifier = child(named: "modifier", in: base),
       let weight = child(named: "weight", in: modifier) as? Font.Weight,
       let namedProviderBox = child(named: "provider", in: baseFont),
       let namedProvider = child(named: "base", in: namedProviderBox),
       let name = child(named: "name", in: namedProvider) as? String,
       let size = child(named: "size", in: namedProvider) as? CGFloat {
        return .custom(name: name, size: size, weight: weight)
    }

    return nil
}

private func child(named name: String, in value: Any) -> Any? {
    Mirror(reflecting: value).children.first(where: { $0.label == name })?.value
}

private func unwrapOptional(_ value: Any?) -> Any? {
    guard let value else { return nil }
    let mirror = Mirror(reflecting: value)
    if mirror.displayStyle != .optional {
        return value
    }
    return mirror.children.first?.value
}

private func assertApproximatelyEqual(_ actual: Double, _ expected: Double, tolerance: Double = 0.001) {
    #expect(abs(actual - expected) < tolerance)
}

private func assertStyle(_ actual: SyntaxStyle, equals expected: SyntaxStyle) {
    assertApproximatelyEqual(actual.color.red, expected.color.red)
    assertApproximatelyEqual(actual.color.green, expected.color.green)
    assertApproximatelyEqual(actual.color.blue, expected.color.blue)
    assertApproximatelyEqual(actual.color.alpha, expected.color.alpha)

    switch (actual.font, expected.font) {
    case let (.system(actualSize, actualWeight, actualDesign), .system(expectedSize, expectedWeight, expectedDesign)):
        #expect(actualSize == expectedSize)
        #expect(actualWeight == expectedWeight)
        #expect(actualDesign == expectedDesign)
    case let (.custom(actualName, actualSize, actualWeight), .custom(expectedName, expectedSize, expectedWeight)):
        #expect(actualName == expectedName)
        #expect(actualSize == expectedSize)
        #expect(actualWeight == expectedWeight)
    default:
        Issue.record("Font mismatch: \(actual.font) != \(expected.font)")
    }
}

private func assertRenderedStyle(_ actual: SyntaxStyle, equals expected: SyntaxStyle) {
    let renderedExpectedColor = renderedColor(from: expected.color)
    assertApproximatelyEqual(actual.color.red, renderedExpectedColor.red)
    assertApproximatelyEqual(actual.color.green, renderedExpectedColor.green)
    assertApproximatelyEqual(actual.color.blue, renderedExpectedColor.blue)
    assertApproximatelyEqual(actual.color.alpha, renderedExpectedColor.alpha)

    switch (actual.font, expected.font) {
    case let (.system(actualSize, actualWeight, actualDesign), .system(expectedSize, expectedWeight, expectedDesign)):
        #expect(actualSize == expectedSize)
        #expect(actualWeight == expectedWeight)
        #expect(actualDesign == expectedDesign)
    case let (.custom(actualName, actualSize, actualWeight), .custom(expectedName, expectedSize, expectedWeight)):
        #expect(actualName == expectedName)
        #expect(actualSize == expectedSize)
        #expect(actualWeight == expectedWeight)
    default:
        Issue.record("Font mismatch: \(actual.font) != \(expected.font)")
    }
}

private func renderedColor(from color: SyntaxColor) -> SyntaxColor {
    syntaxColor(
        from: Color(
            cgColor: CGColor(
                red: color.red / 255.0,
                green: color.green / 255.0,
                blue: color.blue / 255.0,
                alpha: color.alpha
            )
        )
    )!
}

private func merged(base: SyntaxStyle, themed: SyntaxStyle) -> SyntaxStyle {
    var style = base
    style.color = themed.color
    style.font.weight = themed.font.weight
    return style
}

private let sampleCode = """
/// Doc comment
let value = "Hello" + 42
"""

private let defaultDocumentationMarkup = SyntaxStyle(
    font: .custom(name: "HelveticaNeue", size: 12.0, weight: .regular),
    color: SyntaxColor(red: 93.1413, green: 107.579145, blue: 121.16427, alpha: 1.0)
)

private let defaultNumberStyle = SyntaxStyle(
    font: .system(size: 12.0, weight: .regular, design: .monospaced),
    color: SyntaxColor(red: 28.05, green: 0.0, blue: 206.55, alpha: 1.0)
)

private let presentationDarkDocumentationMarkup = SyntaxStyle(
    font: .custom(name: "Helvetica", size: 18.0, weight: .regular),
    color: SyntaxColor(red: 107.999895, green: 120.999945, blue: 134.99994, alpha: 1.0)
)

private let presentationDarkNumberStyle = SyntaxStyle(
    font: .system(size: 18.0, weight: .regular, design: .monospaced),
    color: SyntaxColor(red: 255.0, green: 230.917545, blue: 109.088745, alpha: 1.0)
)

private struct ThemeExpectation: Sendable {
    let name: String
    let theme: SwiftTheme
    let themeWithBase: @Sendable (SyntaxStyle) -> SwiftTheme
    let backgroundColor: Color
    let expectedBackground: SyntaxColor
    let plain: SyntaxStyle
    let keyword: SyntaxStyle
    let string: SyntaxStyle
}

private let themeExpectations: [ThemeExpectation] = [
    .init(
        name: "bare",
        theme: .bare,
        themeWithBase: { SwiftTheme.bare($0) },
        backgroundColor: .xcodeBackgroundBareColor,
        expectedBackground: SyntaxColor(red: 255.0, green: 255.0, blue: 255.0, alpha: 1.0),
        plain: SyntaxStyle(font: .system(size: 11.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)),
        keyword: SyntaxStyle(font: .system(size: 11.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 0.0, green: 0.0, blue: 204.0, alpha: 1.0)),
        string: SyntaxStyle(font: .system(size: 11.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 255.0, green: 51.0, blue: 153.0, alpha: 1.0))
    ),
    .init(
        name: "basic",
        theme: .basic,
        themeWithBase: { SwiftTheme.basic($0) },
        backgroundColor: .xcodeBackgroundBasicColor,
        expectedBackground: SyntaxColor(red: 255.0, green: 255.0, blue: 255.0, alpha: 1.0),
        plain: SyntaxStyle(font: .system(size: 11.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)),
        keyword: SyntaxStyle(font: .system(size: 11.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 0.0, green: 0.0, blue: 255.0, alpha: 1.0)),
        string: SyntaxStyle(font: .system(size: 11.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 162.945, green: 20.91, blue: 20.91, alpha: 1.0))
    ),
    .init(
        name: "civic",
        theme: .civic,
        themeWithBase: { SwiftTheme.civic($0) },
        backgroundColor: .xcodeBackgroundCivicColor,
        expectedBackground: SyntaxColor(red: 31.000095, green: 31.99995, blue: 40.99992, alpha: 1.0),
        plain: SyntaxStyle(font: .system(size: 12.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 224.95335, green: 225.76476, blue: 230.588085, alpha: 1.0)),
        keyword: SyntaxStyle(font: .system(size: 12.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 215.214645, green: 0.0, blue: 142.747725, alpha: 1.0)),
        string: SyntaxStyle(font: .system(size: 12.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 211.000005, green: 35.000025, blue: 45.99996, alpha: 1.0))
    ),
    .init(
        name: "classicDark",
        theme: .classicDark,
        themeWithBase: { SwiftTheme.classicDark($0) },
        backgroundColor: .xcodeBackgroundClassicDarkColor,
        expectedBackground: SyntaxColor(red: 30.738465, green: 31.32522, blue: 36.03456, alpha: 1.0),
        plain: SyntaxStyle(font: .system(size: 12.0, weight: .medium, design: .monospaced), color: SyntaxColor(red: 255.0, green: 255.0, blue: 255.0, alpha: 0.85)),
        keyword: SyntaxStyle(font: .system(size: 12.0, weight: .bold, design: .monospaced), color: SyntaxColor(red: 252.04047, green: 95.25525, blue: 162.773895, alpha: 1.0)),
        string: SyntaxStyle(font: .system(size: 12.0, weight: .medium, design: .monospaced), color: SyntaxColor(red: 252.224835, green: 105.9729, blue: 93.24942, alpha: 1.0))
    ),
    .init(
        name: "classicLight",
        theme: .classicLight,
        themeWithBase: { SwiftTheme.classicLight($0) },
        backgroundColor: .xcodeBackgroundClassicLightColor,
        expectedBackground: SyntaxColor(red: 255.0, green: 255.0, blue: 255.0, alpha: 1.0),
        plain: SyntaxStyle(font: .system(size: 12.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.85)),
        keyword: SyntaxStyle(font: .system(size: 12.0, weight: .semibold, design: .monospaced), color: SyntaxColor(red: 154.93596, green: 35.06913, blue: 146.95242, alpha: 1.0)),
        string: SyntaxStyle(font: .system(size: 12.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 196.35, green: 26.01, blue: 21.93, alpha: 1.0))
    ),
    .init(
        name: "default",
        theme: .default,
        themeWithBase: { SwiftTheme.default($0) },
        backgroundColor: .xcodeBackgroundDefaultColor,
        expectedBackground: SyntaxColor(red: 255.0, green: 255.0, blue: 255.0, alpha: 1.0),
        plain: SyntaxStyle(font: .system(size: 12.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.85)),
        keyword: SyntaxStyle(font: .system(size: 12.0, weight: .semibold, design: .monospaced), color: SyntaxColor(red: 154.93596, green: 35.06913, blue: 146.95242, alpha: 1.0)),
        string: SyntaxStyle(font: .system(size: 12.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 196.35, green: 26.01, blue: 21.93, alpha: 1.0))
    ),
    .init(
        name: "defaultDark",
        theme: .defaultDark,
        themeWithBase: { SwiftTheme.defaultDark($0) },
        backgroundColor: .xcodeBackgroundDefaultDarkColor,
        expectedBackground: SyntaxColor(red: 30.738465, green: 31.32522, blue: 36.03456, alpha: 1.0),
        plain: SyntaxStyle(font: .system(size: 12.0, weight: .medium, design: .monospaced), color: SyntaxColor(red: 255.0, green: 255.0, blue: 255.0, alpha: 0.85)),
        keyword: SyntaxStyle(font: .system(size: 12.0, weight: .bold, design: .monospaced), color: SyntaxColor(red: 252.04047, green: 95.25525, blue: 162.773895, alpha: 1.0)),
        string: SyntaxStyle(font: .system(size: 12.0, weight: .medium, design: .monospaced), color: SyntaxColor(red: 252.224835, green: 105.9729, blue: 93.24942, alpha: 1.0))
    ),
    .init(
        name: "dusk",
        theme: .dusk,
        themeWithBase: { SwiftTheme.dusk($0) },
        backgroundColor: .xcodeBackgroundDuskColor,
        expectedBackground: SyntaxColor(red: 30.09, green: 31.875, blue: 40.035, alpha: 1.0),
        plain: SyntaxStyle(font: .system(size: 11.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 255.0, green: 255.0, blue: 255.0, alpha: 1.0)),
        keyword: SyntaxStyle(font: .system(size: 11.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 177.99, green: 24.225, blue: 136.68, alpha: 1.0)),
        string: SyntaxStyle(font: .system(size: 11.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 219.045, green: 43.605, blue: 55.845, alpha: 1.0))
    ),
    .init(
        name: "highContrastDark",
        theme: .highContrastDark,
        themeWithBase: { SwiftTheme.highContrastDark($0) },
        backgroundColor: .xcodeBackgroundHighContrastDarkColor,
        expectedBackground: SyntaxColor(red: 23.511153, green: 23.389671, blue: 27.053205, alpha: 1.0),
        plain: SyntaxStyle(font: .system(size: 12.0, weight: .medium, design: .monospaced), color: SyntaxColor(red: 255.0, green: 255.0, blue: 255.0, alpha: 1.0)),
        keyword: SyntaxStyle(font: .system(size: 12.0, weight: .bold, design: .monospaced), color: SyntaxColor(red: 252.18582, green: 107.389425, blue: 169.572705, alpha: 1.0)),
        string: SyntaxStyle(font: .system(size: 12.0, weight: .medium, design: .monospaced), color: SyntaxColor(red: 252.35004, green: 115.735575, blue: 103.140105, alpha: 1.0))
    ),
    .init(
        name: "highContrastLight",
        theme: .highContrastLight,
        themeWithBase: { SwiftTheme.highContrastLight($0) },
        backgroundColor: .xcodeBackgroundHighContrastLightColor,
        expectedBackground: SyntaxColor(red: 255.0, green: 255.0, blue: 255.0, alpha: 1.0),
        plain: SyntaxStyle(font: .system(size: 12.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)),
        keyword: SyntaxStyle(font: .system(size: 12.0, weight: .semibold, design: .monospaced), color: SyntaxColor(red: 136.27251, green: 0.0, blue: 126.41727, alpha: 1.0)),
        string: SyntaxStyle(font: .system(size: 12.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 154.88751, green: 4.950366, blue: 8.579526, alpha: 1.0))
    ),
    .init(
        name: "lowKey",
        theme: .lowKey,
        themeWithBase: { SwiftTheme.lowKey($0) },
        backgroundColor: .xcodeBackgroundLowKeyColor,
        expectedBackground: SyntaxColor(red: 255.0, green: 255.0, blue: 255.0, alpha: 1.0),
        plain: SyntaxStyle(font: .system(size: 11.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)),
        keyword: SyntaxStyle(font: .system(size: 11.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 37.995, green: 44.115, blue: 105.825, alpha: 1.0)),
        string: SyntaxStyle(font: .system(size: 11.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 112.2, green: 44.115, blue: 81.345, alpha: 1.0))
    ),
    .init(
        name: "midnight",
        theme: .midnight,
        themeWithBase: { SwiftTheme.midnight($0) },
        backgroundColor: .xcodeBackgroundMidnightColor,
        expectedBackground: SyntaxColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0),
        plain: SyntaxStyle(font: .system(size: 11.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 255.0, green: 255.0, blue: 255.0, alpha: 1.0)),
        keyword: SyntaxStyle(font: .system(size: 11.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 211.14, green: 24.225, blue: 148.665, alpha: 1.0)),
        string: SyntaxStyle(font: .system(size: 11.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 255.0, green: 43.605, blue: 55.845, alpha: 1.0))
    ),
    .init(
        name: "presentationDark",
        theme: .presentationDark,
        themeWithBase: { SwiftTheme.presentationDark($0) },
        backgroundColor: .xcodeBackgroundPresentationDarkColor,
        expectedBackground: SyntaxColor(red: 24.154314, green: 24.154314, blue: 28.05, alpha: 1.0),
        plain: SyntaxStyle(font: .system(size: 18.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 255.0, green: 255.0, blue: 255.0, alpha: 1.0)),
        keyword: SyntaxStyle(font: .system(size: 18.0, weight: .semibold, design: .monospaced), color: SyntaxColor(red: 241.6176, green: 35.68164, blue: 139.516875, alpha: 1.0)),
        string: SyntaxStyle(font: .system(size: 18.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 251.999925, green: 70.00005, blue: 80.999985, alpha: 1.0))
    ),
    .init(
        name: "presentationLight",
        theme: .presentationLight,
        themeWithBase: { SwiftTheme.presentationLight($0) },
        backgroundColor: .xcodeBackgroundPresentationLightColor,
        expectedBackground: SyntaxColor(red: 255.0, green: 255.0, blue: 255.0, alpha: 1.0),
        plain: SyntaxStyle(font: .system(size: 18.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)),
        keyword: SyntaxStyle(font: .system(size: 18.0, weight: .semibold, design: .monospaced), color: SyntaxColor(red: 179.99991, green: 0.0, blue: 98.00007, alpha: 0.8)),
        string: SyntaxStyle(font: .system(size: 18.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 186.00006, green: 0.0, blue: 17.000008, alpha: 1.0))
    ),
    .init(
        name: "presentationLargeDark",
        theme: .presentationLargeDark,
        themeWithBase: { SwiftTheme.presentationLargeDark($0) },
        backgroundColor: .xcodeBackgroundPresentationLargeDarkColor,
        expectedBackground: SyntaxColor(red: 23.999988, green: 23.999988, blue: 28.00002, alpha: 1.0),
        plain: SyntaxStyle(font: .system(size: 28.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 255.0, green: 255.0, blue: 255.0, alpha: 1.0)),
        keyword: SyntaxStyle(font: .system(size: 28.0, weight: .semibold, design: .monospaced), color: SyntaxColor(red: 241.6176, green: 35.68164, blue: 139.516875, alpha: 1.0)),
        string: SyntaxStyle(font: .system(size: 28.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 251.999925, green: 70.00005, blue: 80.999985, alpha: 1.0))
    ),
    .init(
        name: "presentationLargeLight",
        theme: .presentationLargeLight,
        themeWithBase: { SwiftTheme.presentationLargeLight($0) },
        backgroundColor: .xcodeBackgroundPresentationLargeLightColor,
        expectedBackground: SyntaxColor(red: 255.0, green: 255.0, blue: 255.0, alpha: 1.0),
        plain: SyntaxStyle(font: .system(size: 28.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)),
        keyword: SyntaxStyle(font: .system(size: 28.0, weight: .semibold, design: .monospaced), color: SyntaxColor(red: 179.99991, green: 0.0, blue: 98.00007, alpha: 0.8)),
        string: SyntaxStyle(font: .system(size: 28.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 186.00006, green: 0.0, blue: 17.000008, alpha: 1.0))
    ),
    .init(
        name: "printing",
        theme: .printing,
        themeWithBase: { SwiftTheme.printing($0) },
        backgroundColor: .xcodeBackgroundPrintingColor,
        expectedBackground: SyntaxColor(red: 254.98878, green: 254.98878, blue: 254.98878, alpha: 1.0),
        plain: SyntaxStyle(font: .system(size: 11.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)),
        keyword: SyntaxStyle(font: .system(size: 11.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 88.87311, green: 88.87311, blue: 88.87311, alpha: 1.0)),
        string: SyntaxStyle(font: .system(size: 11.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 93.149205, green: 93.149205, blue: 93.149205, alpha: 1.0))
    ),
    .init(
        name: "spartan",
        theme: .spartan,
        themeWithBase: { SwiftTheme.spartan($0) },
        backgroundColor: .xcodeBackgroundSpartanColor,
        expectedBackground: SyntaxColor(red: 255.0, green: 255.0, blue: 255.0, alpha: 1.0),
        plain: SyntaxStyle(font: .system(size: 11.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)),
        keyword: SyntaxStyle(font: .system(size: 11.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 210.885, green: 21.93, blue: 121.125, alpha: 1.0)),
        string: SyntaxStyle(font: .system(size: 11.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 102.0, green: 102.0, blue: 102.0, alpha: 1.0))
    ),
    .init(
        name: "sunset",
        theme: .sunset,
        themeWithBase: { SwiftTheme.sunset($0) },
        backgroundColor: .xcodeBackgroundSunsetColor,
        expectedBackground: SyntaxColor(red: 255.0, green: 251.94, blue: 228.99, alpha: 1.0),
        plain: SyntaxStyle(font: .system(size: 11.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)),
        keyword: SyntaxStyle(font: .system(size: 11.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 41.055, green: 66.045, blue: 119.085, alpha: 1.0)),
        string: SyntaxStyle(font: .system(size: 11.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 223.125, green: 6.885, blue: 0.0, alpha: 1.0))
    ),
]
