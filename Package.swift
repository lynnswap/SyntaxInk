// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SyntaxInk",
    platforms: [.macOS(.v12), .iOS(.v15), .tvOS(.v15), .watchOS(.v8), .visionOS(.v1)],
    products: [
        .library(name: "SwiftSyntaxInk", targets: ["SwiftSyntaxInk"]),
        .library(name: "ObjCSyntaxInk", targets: ["ObjCSyntaxInk"]),
        .library(name: "SyntaxInk", targets: ["SyntaxInk"]),
    ],
    dependencies: [
        .package(url: "https://github.com/p-x9/MachOKit.git", from: "0.48.0"),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "601.0.0"),
        .package(url: "https://github.com/ChimeHQ/SwiftTreeSitter", from: "0.8.0"),
        .package(url: "https://github.com/tree-sitter-grammars/tree-sitter-objc", from: "3.0.2"),
    ],
    targets: [
        .target(
            name: "ObjCXcodeBridge",
            publicHeadersPath: "include",
            linkerSettings: [
                .linkedFramework("Cocoa", .when(platforms: [.macOS])),
            ]
        ),
        .target(
            name: "ObjCXcodeRuntimeShim",
            dependencies: [
                "ObjCXcodeBridge",
                .product(name: "MachOKit", package: "MachOKit"),
            ]
        ),
        .target(
            name: "SwiftSyntaxInk",
            dependencies: [
                "SyntaxInk",
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax")
            ]
        ),
        .target(
            name: "ObjCSyntaxInk",
            dependencies: [
                "SyntaxInk",
                .target(name: "ObjCXcodeRuntimeShim", condition: .when(platforms: [.macOS])),
                .product(name: "SwiftTreeSitter", package: "SwiftTreeSitter"),
                .product(name: "TreeSitterObjc", package: "tree-sitter-objc"),
            ]
        ),
        .target(name: "SyntaxInk"),
        .testTarget(
            name: "SyntaxInkTests",
            dependencies: ["SyntaxInk", "SwiftSyntaxInk", "ObjCSyntaxInk", "ObjCXcodeRuntimeShim"],
            exclude: ["Fixtures"]
        ),
    ]
)
