#if os(macOS)
import AppKit
import Darwin
import Foundation
import ObjCXcodeBridge

@MainActor
public enum ObjCXcodeRuntimeShim {
    public static func makeEditorHostView(
        source: String,
        fileName: String,
        themeDisplayName: String,
        previewMode: Bool
    ) throws -> NSView {
        try installManifestIfNeeded()
        let view = try SIXObjCXcodeBridge.makeEditorHostView(
            withSource: source,
            fileName: fileName,
            themeDisplayName: themeDisplayName,
            previewMode: previewMode
        )
        return view
    }

    public static func updateEditorHostView(
        _ view: NSView,
        source: String,
        fileName: String,
        themeDisplayName: String,
        previewMode: Bool
    ) throws {
        try installManifestIfNeeded()
        try SIXObjCXcodeBridge.updateEditorHostView(
            view,
            source: source,
            fileName: fileName,
            themeDisplayName: themeDisplayName,
            previewMode: previewMode
        )
    }

    public static func refreshEditorHostView(_ view: NSView, active: Bool) {
        SIXObjCXcodeBridge.refreshEditorHostView(view, active: active)
    }

    private static func installManifestIfNeeded() throws {
        try ManifestInstaller.shared.installIfNeeded()
    }
}

private enum ObjCXcodeRuntimeShimError: LocalizedError {
    case bridge(String)

    var errorDescription: String? {
        switch self {
        case let .bridge(message):
            message
        }
    }
}

@MainActor
private final class ManifestInstaller {
    static let shared = ManifestInstaller()

    private var installed = false

    private init() {}

    func installIfNeeded() throws {
        if installed {
            return
        }

        let manifest = try XcodePrivateFrameworkManifest.makeDefaultManifest()
        try MachOSymbolVerifier.verify(manifest: manifest)

        let data = try JSONEncoder().encode(manifest)
        try SIXObjCXcodeBridge.installRuntimeManifestData(data)

        self.installed = true
    }
}

struct XcodePrivateFrameworkManifest: Codable, Sendable {
    struct Framework: Codable, Sendable {
        let path: String
        let requiredSymbols: [String]
    }

    let frameworks: [Framework]
}

extension ProcessInfo {
    var isRunningUnderXCTest: Bool {
        let environment = environment
        return environment["XCTestConfigurationFilePath"] != nil
            || environment["XCInjectBundleInto"] != nil
            || environment["XCTestSessionIdentifier"] != nil
    }
}
#endif
