#!/usr/bin/env swift

import Foundation

private let sourceDirectory = try resolveSourceDirectory()
private let repositoryRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
private let outputURL = repositoryRoot.appending(path: "Sources/SwiftSyntaxInk/XcodeThemes+Generated.swift")

private let themeNames: [(displayName: String, caseName: String)] = [
    ("Bare", "bare"),
    ("Basic", "basic"),
    ("Civic", "civic"),
    ("Classic (Dark)", "classicDark"),
    ("Classic (Light)", "classicLight"),
    ("Default (Light)", "default"),
    ("Default (Dark)", "defaultDark"),
    ("Dusk", "dusk"),
    ("High Contrast (Dark)", "highContrastDark"),
    ("High Contrast (Light)", "highContrastLight"),
    ("Low Key", "lowKey"),
    ("Midnight", "midnight"),
    ("Presentation (Dark)", "presentationDark"),
    ("Presentation (Light)", "presentationLight"),
    ("Presentation Large (Dark)", "presentationLargeDark"),
    ("Presentation Large (Light)", "presentationLargeLight"),
    ("Printing", "printing"),
    ("Spartan", "spartan"),
    ("Sunset", "sunset"),
]

private struct ThemeData {
    let backgroundColor: String
    let rawStyles: [(key: String, fontLiteral: String, colorLiteral: String)]
}

private let styleKeys = [
    "xcode.syntax.attribute",
    "xcode.syntax.character",
    "xcode.syntax.comment",
    "xcode.syntax.comment.doc",
    "xcode.syntax.comment.doc.keyword",
    "xcode.syntax.declaration.other",
    "xcode.syntax.declaration.type",
    "xcode.syntax.identifier.class",
    "xcode.syntax.identifier.class.system",
    "xcode.syntax.identifier.constant",
    "xcode.syntax.identifier.constant.system",
    "xcode.syntax.identifier.function",
    "xcode.syntax.identifier.function.system",
    "xcode.syntax.identifier.macro",
    "xcode.syntax.identifier.macro.system",
    "xcode.syntax.identifier.type",
    "xcode.syntax.identifier.type.system",
    "xcode.syntax.identifier.variable",
    "xcode.syntax.identifier.variable.system",
    "xcode.syntax.keyword",
    "xcode.syntax.mark",
    "xcode.syntax.markup.aside.kind",
    "xcode.syntax.markup.code",
    "xcode.syntax.number",
    "xcode.syntax.plain",
    "xcode.syntax.preprocessor",
    "xcode.syntax.string",
    "xcode.syntax.url",
]

private func resolveSourceDirectory() throws -> URL {
    if let developerDirectory = ProcessInfo.processInfo.environment["DEVELOPER_DIR"], !developerDirectory.isEmpty {
        return themesDirectory(forDeveloperDirectory: developerDirectory)
    }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/xcode-select")
    process.arguments = ["-p"]

    let output = Pipe()
    process.standardOutput = output
    try process.run()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
        throw NSError(domain: "generate_xcode_themes", code: 10, userInfo: [NSLocalizedDescriptionKey: "xcode-select -p failed"])
    }

    let data = output.fileHandleForReading.readDataToEndOfFile()
    guard let developerDirectory = String(data: data, encoding: .utf8)?
        .trimmingCharacters(in: .whitespacesAndNewlines),
          !developerDirectory.isEmpty else {
        throw NSError(domain: "generate_xcode_themes", code: 11, userInfo: [NSLocalizedDescriptionKey: "Could not resolve developer directory"])
    }

    return themesDirectory(forDeveloperDirectory: developerDirectory)
}

private func themesDirectory(forDeveloperDirectory developerDirectory: String) -> URL {
    let contentsDirectory = URL(fileURLWithPath: developerDirectory, isDirectory: true).deletingLastPathComponent()
    return contentsDirectory
        .appending(path: "SharedFrameworks")
        .appending(path: "DVTUserInterfaceKit.framework")
        .appending(path: "Versions/A/Resources/FontAndColorThemes", directoryHint: .isDirectory)
}

private func loadTheme(named name: String) throws -> ThemeData {
    let url = sourceDirectory.appending(path: "\(name).xccolortheme")
    let data = try Data(contentsOf: url)
    let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
    guard let dictionary = plist as? [String: Any],
          let colors = dictionary["DVTSourceTextSyntaxColors"] as? [String: String],
          let fonts = dictionary["DVTSourceTextSyntaxFonts"] as? [String: String],
          let background = dictionary["DVTSourceTextBackground"] as? String else {
        throw NSError(domain: "generate_xcode_themes", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid theme format: \(name)"])
    }

    let rawStyles = try styleKeys.map { key in
        guard let font = fonts[key], let color = colors[key] else {
            throw NSError(domain: "generate_xcode_themes", code: 2, userInfo: [NSLocalizedDescriptionKey: "Missing key \(key) in \(name)"])
        }

        return (
            key: key,
            fontLiteral: try parseFontLiteral(font),
            colorLiteral: try parseColorLiteral(color)
        )
    }

    return ThemeData(
        backgroundColor: try parseColorLiteral(background),
        rawStyles: rawStyles
    )
}

private func parseColorLiteral(_ value: String) throws -> String {
    let components = value.split(whereSeparator: \.isWhitespace).compactMap { Double($0) }
    guard components.count == 4 else {
        throw NSError(domain: "generate_xcode_themes", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid color: \(value)"])
    }

    return """
    SyntaxColor(red: \(format(components[0] * 255.0)), green: \(format(components[1] * 255.0)), blue: \(format(components[2] * 255.0)), alpha: \(format(components[3])))
    """
}

private func parseFontLiteral(_ value: String) throws -> String {
    let pieces = value.components(separatedBy: " - ")
    guard pieces.count == 2, let size = Double(pieces[1]) else {
        throw NSError(domain: "generate_xcode_themes", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invalid font: \(value)"])
    }

    let descriptor = pieces[0]
    let weights: [(String, String)] = [
        ("Black", ".black"),
        ("Heavy", ".heavy"),
        ("Bold", ".bold"),
        ("Semibold", ".semibold"),
        ("Medium", ".medium"),
        ("Regular", ".regular"),
        ("Light", ".light"),
        ("Thin", ".thin"),
        ("Ultralight", ".ultraLight"),
    ]

    for (suffix, weight) in weights {
        let marker = "-\(suffix)"
        if descriptor.hasSuffix(marker) {
            let family = String(descriptor.dropLast(marker.count))
            if family == "SFMono" {
                return ".system(size: \(format(size)), weight: \(weight), design: .monospaced)"
            }
            return ".custom(name: \(quoted(family)), size: \(format(size)), weight: \(weight))"
        }
    }

    return ".custom(name: \(quoted(descriptor)), size: \(format(size)), weight: .regular)"
}

private func format(_ value: Double) -> String {
    var string = String(format: "%.6f", locale: Locale(identifier: "en_US_POSIX"), value)
    while string.contains(".") && (string.hasSuffix("0") || string.hasSuffix(".")) {
        string.removeLast()
        if string.hasSuffix(".") {
            string.append("0")
            break
        }
    }
    return string
}

private func quoted(_ string: String) -> String {
    let escaped = string.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
    return "\"\(escaped)\""
}

private let themes = try themeNames.map { themeName in
    (themeName.caseName, try loadTheme(named: themeName.displayName))
}

var output = """
// Generated by Scripts/generate_xcode_themes.swift. Do not edit by hand.

import SyntaxInk
import SwiftUI

enum BuiltInXcodeThemes {
    static func definition(for name: XcodeThemeName) -> XcodeColorThemeDefinition {
        definitions[name]!
    }

    private static let definitions: [XcodeThemeName: XcodeColorThemeDefinition] = [
"""

for (caseName, theme) in themes {
    output += """

        .\(caseName == "default" ? "`default`" : caseName): XcodeColorThemeDefinition(
            backgroundColor: \(theme.backgroundColor),
            rawStyles: [
"""

    for style in theme.rawStyles {
        output += """

                \(quoted(style.key)): SyntaxStyle(
                    font: \(style.fontLiteral),
                    color: \(style.colorLiteral)
                ),
"""
    }

    output += """

            ]
        ),
"""
}

output += """

    ]
}
"""

try output.write(to: outputURL, atomically: true, encoding: .utf8)
