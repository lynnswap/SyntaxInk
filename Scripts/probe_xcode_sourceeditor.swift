#!/usr/bin/swift

import AppKit
import Foundation

let frameworkPaths = [
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
    "/Applications/Xcode.app/Contents/SharedFrameworks/DVTSourceEditor.framework/Versions/A/DVTSourceEditor",
    "/Applications/Xcode.app/Contents/Frameworks/IDEFoundation.framework/Versions/A/IDEFoundation",
    "/Applications/Xcode.app/Contents/Frameworks/IDEKit.framework/Versions/A/IDEKit",
    "/Applications/Xcode.app/Contents/PlugIns/IDESourceEditor.framework/Versions/A/IDESourceEditor",
]

for path in frameworkPaths {
    guard dlopen(path, RTLD_NOW | RTLD_GLOBAL) != nil else {
        fputs("dlopen failed: \(String(cString: dlerror()))\n", stderr)
        exit(1)
    }
}

let classes = [
    "SourceEditor.SourceEditorView",
    "SourceEditor.SourceEditorDataSource",
    "IDESourceEditor.SourceCodeDocument",
    "IDESourceEditor.SourceCodeEditor",
]

for name in classes {
    print("\(name): \(String(describing: NSClassFromString(name)))")
}
