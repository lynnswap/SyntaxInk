#!/usr/bin/swift

import Foundation

struct Manifest: Encodable {
    struct Framework: Encodable {
        let path: String
        let requiredSymbols: [String]
    }

    let frameworks: [Framework]
}

enum ManifestResolver {
    private static let xcodeContentsPath = "/Applications/Xcode.app/Contents"

    private static let seedPaths = [
        "/Applications/Xcode.app/Contents/SharedFrameworks/SourceEditor.framework/Versions/A/SourceEditor",
        "/Applications/Xcode.app/Contents/SharedFrameworks/SourceEditorSwiftSupport.framework/Versions/A/SourceEditorSwiftSupport",
        "/Applications/Xcode.app/Contents/SharedFrameworks/SourceEditorRegExSupport.framework/Versions/A/SourceEditorRegExSupport",
        "/Applications/Xcode.app/Contents/SharedFrameworks/_CodeCompletionFoundation.framework/Versions/A/_CodeCompletionFoundation",
        "/Applications/Xcode.app/Contents/SharedFrameworks/CodeCompletionFoundation.framework/Versions/A/CodeCompletionFoundation",
        "/Applications/Xcode.app/Contents/SharedFrameworks/CodeCompletionKit.framework/Versions/A/CodeCompletionKit",
        "/Applications/Xcode.app/Contents/SharedFrameworks/SymbolCache.framework/Versions/A/SymbolCache",
        "/Applications/Xcode.app/Contents/SharedFrameworks/SymbolCacheSupport.framework/Versions/A/SymbolCacheSupport",
        "/Applications/Xcode.app/Contents/SharedFrameworks/SourceModel.framework/Versions/A/SourceModel",
        "/Applications/Xcode.app/Contents/SharedFrameworks/SourceModelSupport.framework/Versions/A/SourceModelSupport",
        "/Applications/Xcode.app/Contents/SharedFrameworks/DVTFoundation.framework/Versions/A/DVTFoundation",
        "/Applications/Xcode.app/Contents/SharedFrameworks/DVTKit.framework/Versions/A/DVTKit",
        "/Applications/Xcode.app/Contents/SharedFrameworks/DVTViewControllerKit.framework/Versions/A/DVTViewControllerKit",
        "/Applications/Xcode.app/Contents/SharedFrameworks/DVTLibraryKit.framework/Versions/A/DVTLibraryKit",
        "/Applications/Xcode.app/Contents/SharedFrameworks/DVTStructuredLayoutKit.framework/Versions/A/DVTStructuredLayoutKit",
        "/Applications/Xcode.app/Contents/SharedFrameworks/DVTCocoaAdditionsKit.framework/Versions/A/DVTCocoaAdditionsKit",
        "/Applications/Xcode.app/Contents/SharedFrameworks/DVTUserInterfaceKit.framework/Versions/A/DVTUserInterfaceKit",
        "/Applications/Xcode.app/Contents/SharedFrameworks/DVTIconKit.framework/Versions/A/DVTIconKit",
        "/Applications/Xcode.app/Contents/SharedFrameworks/DVTCoreGlyphs.framework/Versions/A/DVTCoreGlyphs",
        "/Applications/Xcode.app/Contents/SharedFrameworks/DVTDocumentation.framework/Versions/A/DVTDocumentation",
        "/Applications/Xcode.app/Contents/SharedFrameworks/DVTMarkup.framework/Versions/A/DVTMarkup",
        "/Applications/Xcode.app/Contents/SharedFrameworks/DNTDocumentationModel.framework/Versions/A/DNTDocumentationModel",
        "/Applications/Xcode.app/Contents/SharedFrameworks/DNTDocumentationSupport.framework/Versions/A/DNTDocumentationSupport",
        "/Applications/Xcode.app/Contents/SharedFrameworks/DNTSourceKitSupport.framework/Versions/A/DNTSourceKitSupport",
        "/Applications/Xcode.app/Contents/SharedFrameworks/DNTTransformer.framework/Versions/A/DNTTransformer",
        "/Applications/Xcode.app/Contents/SharedFrameworks/DVTSourceEditor.framework/Versions/A/DVTSourceEditor",
        "/Applications/Xcode.app/Contents/SharedFrameworks/MarkupSupport.framework/Versions/A/MarkupSupport",
        "/Applications/Xcode.app/Contents/SharedFrameworks/SourceKit.framework/Versions/A/SourceKit",
        "/Applications/Xcode.app/Contents/SharedFrameworks/SourceKitSupport.framework/Versions/A/SourceKitSupport",
        "/Applications/Xcode.app/Contents/Developer/Library/Frameworks/XcodeKit.framework/Versions/A/XcodeKit",
        "/Applications/Xcode.app/Contents/Frameworks/IDEFoundation.framework/Versions/A/IDEFoundation",
        "/Applications/Xcode.app/Contents/Frameworks/IDEKit.framework/Versions/A/IDEKit",
        "/Applications/Xcode.app/Contents/Frameworks/IDELanguageModelKit.framework/Versions/A/IDELanguageModelKit",
        "/Applications/Xcode.app/Contents/Frameworks/IDENoticesFoundation.framework/Versions/A/IDENoticesFoundation",
        "/Applications/Xcode.app/Contents/PlugIns/IDESourceEditor.framework/Versions/A/IDESourceEditor",
        "/Applications/Xcode.app/Contents/Frameworks/libclang.dylib",
    ]

    private static let searchRoots = [
        "SharedFrameworks",
        "Frameworks",
        "PlugIns",
        "Developer/Library/Frameworks",
        "Developer/Library/PrivateFrameworks",
        "Developer/usr/lib",
        "Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks",
        "Developer/Platforms/MacOSX.platform/Developer/Library/PrivateFrameworks",
        "Developer/Platforms/MacOSX.platform/Developer/usr/lib",
        "Developer/Platforms/MacOSX.platform/Developer/iOSSupport/Library/PrivateFrameworks",
        "Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib",
        "SharedFrameworks/SourceKit.framework/Versions/A/XPCServices/com.apple.dt.SKAgent.xpc/Contents/Frameworks",
    ]

    private static let testFamilySuffixes = [
        "XCTest.framework/Versions/A/XCTest",
        "XCUIAutomation.framework/Versions/A/XCUIAutomation",
        "XCTestCore.framework/Versions/A/XCTestCore",
        "XCTestSupport.framework/Versions/A/XCTestSupport",
        "XCTAutomationSupport.framework/Versions/A/XCTAutomationSupport",
        "XCTHarness.framework/Versions/A/XCTHarness",
        "XCTDaemonControl.framework/Versions/A/XCTDaemonControl",
        "Testing.framework/Versions/A/Testing",
        "_Testing_Foundation.framework/Versions/A/_Testing_Foundation",
        "XCUnit.framework/Versions/A/XCUnit",
        "libXCTestSwiftSupport.dylib",
        "libXCTestBundleInject.dylib",
        "lib_TestingInterop.dylib",
    ]

    static func resolveManifest(includeTestSupport: Bool) throws -> Manifest {
        var queue = try seedPaths.map(normalize(path:))
        var scheduled = Set(queue)
        var visited = Set<String>()
        var orderedPaths: [String] = []
        var index = 0

        while index < queue.count {
            let path = queue[index]
            index += 1

            if visited.contains(path) {
                continue
            }
            if path.hasPrefix("\(xcodeContentsPath)/") == false {
                continue
            }
            if includeTestSupport == false && isTestFamilyPath(path) {
                continue
            }

            visited.insert(path)
            orderedPaths.append(path)

            for reference in try loadDependencyReferences(for: path) {
                guard let dependencyPath = resolveDependencyPath(reference, relativeTo: path) else {
                    continue
                }

                let normalizedDependency = try normalize(path: dependencyPath)
                if normalizedDependency.hasPrefix("\(xcodeContentsPath)/") == false {
                    continue
                }
                if includeTestSupport == false && isTestFamilyPath(normalizedDependency) {
                    continue
                }
                if scheduled.insert(normalizedDependency).inserted {
                    queue.append(normalizedDependency)
                }
            }
        }

        return Manifest(frameworks: orderedPaths.map { path in
            Manifest.Framework(path: path, requiredSymbols: requiredSymbols(for: path))
        })
    }

    private static func requiredSymbols(for path: String) -> [String] {
        switch path {
        case let value where value.hasSuffix("SourceEditor.framework/Versions/A/SourceEditor"):
            return [
                "_OBJC_CLASS_$__TtC12SourceEditor16SourceEditorView",
            ]
        case let value where value.hasSuffix("IDEFoundation.framework/Versions/A/IDEFoundation"):
            return [
                "_IDEInitialize",
                "_IDESetSafeToLoadDeveloperSystemFrameworks",
            ]
        case let value where value.hasSuffix("IDESourceEditor.framework/Versions/A/IDESourceEditor"):
            return [
                "_OBJC_CLASS_$__TtC15IDESourceEditor18SourceCodeDocument",
                "_OBJC_CLASS_$__TtC15IDESourceEditor16SourceCodeEditor",
            ]
        default:
            return []
        }
    }

    private static func loadDependencyReferences(for path: String) throws -> [String] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/otool")
        process.arguments = ["-L", path]

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        let outputData = stdout.fileHandleForReading.readDataToEndOfFile()
        let errorData = stderr.fileHandleForReading.readDataToEndOfFile()

        guard process.terminationStatus == 0 else {
            let errorOutput = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            throw ResolverError.otoolFailed(path, errorOutput ?? "unknown error")
        }

        guard let output = String(data: outputData, encoding: .utf8) else {
            throw ResolverError.invalidUTF8(path)
        }

        var references: [String] = []
        var seen = Set<String>()
        for rawLine in output.split(whereSeparator: \.isNewline) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard line.isEmpty == false else {
                continue
            }
            guard rawLine.first?.isWhitespace == true else {
                continue
            }

            let reference = line.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true).first.map(String.init) ?? ""
            if reference.isEmpty || reference == path || seen.contains(reference) {
                continue
            }

            seen.insert(reference)
            references.append(reference)
        }
        return references
    }

    private static func resolveDependencyPath(_ reference: String, relativeTo binaryPath: String) -> String? {
        if reference.hasPrefix("\(xcodeContentsPath)/") {
            return reference
        }
        if reference.hasPrefix("@loader_path/") {
            let binaryDirectory = URL(fileURLWithPath: binaryPath).deletingLastPathComponent()
            let relativePath = String(reference.dropFirst("@loader_path/".count))
            return binaryDirectory.appendingPathComponent(relativePath).standardizedFileURL.path
        }
        if reference.hasPrefix("@executable_path/") {
            let executableDirectory = URL(fileURLWithPath: "\(xcodeContentsPath)/MacOS/Xcode").deletingLastPathComponent()
            let relativePath = String(reference.dropFirst("@executable_path/".count))
            return executableDirectory.appendingPathComponent(relativePath).standardizedFileURL.path
        }
        if reference.hasPrefix("@rpath/") == false {
            return nil
        }

        let candidateSuffix = String(reference.dropFirst("@rpath/".count))
        let exactPath = "\(xcodeContentsPath)/\(candidateSuffix)"
        if FileManager.default.fileExists(atPath: exactPath) {
            return exactPath
        }

        for searchRoot in searchRoots {
            let candidatePath = "\(xcodeContentsPath)/\(searchRoot)/\(candidateSuffix)"
            if FileManager.default.fileExists(atPath: candidatePath) {
                return candidatePath
            }
        }

        return nil
    }

    private static func normalize(path: String) throws -> String {
        URL(fileURLWithPath: path).standardizedFileURL.resolvingSymlinksInPath().path
    }

    private static func isTestFamilyPath(_ path: String) -> Bool {
        testFamilySuffixes.contains { suffix in
            path.hasSuffix(suffix)
        }
    }
}

enum ResolverError: LocalizedError {
    case invalidUTF8(String)
    case otoolFailed(String, String)

    var errorDescription: String? {
        switch self {
        case let .invalidUTF8(path):
            "Failed to decode otool output for \(path)"
        case let .otoolFailed(path, reason):
            "otool -L failed for \(path): \(reason)"
        }
    }
}

let includeTestSupport = !CommandLine.arguments.contains("--xcuitest")
let manifest = try ManifestResolver.resolveManifest(includeTestSupport: includeTestSupport)

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
let data = try encoder.encode(manifest)
FileHandle.standardOutput.write(data)
