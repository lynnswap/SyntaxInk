#if os(macOS)
import Foundation

extension XcodePrivateFrameworkManifest {
    static func makeDefaultManifest() throws -> XcodePrivateFrameworkManifest {
        try JSONDecoder().decode(
            XcodePrivateFrameworkManifest.self,
            from: Data(embeddedManifestJSON.utf8)
        )
    }

    private static let embeddedManifestJSON = #"""
{
  "frameworks" : [
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/SourceEditor.framework\/Versions\/A\/SourceEditor",
      "requiredSymbols" : [
        "_OBJC_CLASS_$__TtC12SourceEditor16SourceEditorView"
      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/SourceEditorSwiftSupport.framework\/Versions\/A\/SourceEditorSwiftSupport",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/SourceEditorRegExSupport.framework\/Versions\/A\/SourceEditorRegExSupport",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/_CodeCompletionFoundation.framework\/Versions\/A\/_CodeCompletionFoundation",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/CodeCompletionFoundation.framework\/Versions\/A\/CodeCompletionFoundation",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/CodeCompletionKit.framework\/Versions\/A\/CodeCompletionKit",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/SymbolCache.framework\/Versions\/A\/SymbolCache",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/SymbolCacheSupport.framework\/Versions\/A\/SymbolCacheSupport",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/SourceModel.framework\/Versions\/A\/SourceModel",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/SourceModelSupport.framework\/Versions\/A\/SourceModelSupport",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/DVTFoundation.framework\/Versions\/A\/DVTFoundation",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/DVTKit.framework\/Versions\/A\/DVTKit",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/DVTViewControllerKit.framework\/Versions\/A\/DVTViewControllerKit",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/DVTLibraryKit.framework\/Versions\/A\/DVTLibraryKit",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/DVTStructuredLayoutKit.framework\/Versions\/A\/DVTStructuredLayoutKit",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/DVTCocoaAdditionsKit.framework\/Versions\/A\/DVTCocoaAdditionsKit",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/DVTUserInterfaceKit.framework\/Versions\/A\/DVTUserInterfaceKit",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/DVTIconKit.framework\/Versions\/A\/DVTIconKit",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/DVTCoreGlyphs.framework\/Versions\/A\/DVTCoreGlyphs",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/DVTDocumentation.framework\/Versions\/A\/DVTDocumentation",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/DVTMarkup.framework\/Versions\/A\/DVTMarkup",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/DNTDocumentationModel.framework\/Versions\/A\/DNTDocumentationModel",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/DNTDocumentationSupport.framework\/Versions\/A\/DNTDocumentationSupport",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/DNTSourceKitSupport.framework\/Versions\/A\/DNTSourceKitSupport",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/DNTTransformer.framework\/Versions\/A\/DNTTransformer",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/DVTSourceEditor.framework\/Versions\/A\/DVTSourceEditor",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/MarkupSupport.framework\/Versions\/A\/MarkupSupport",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/SourceKit.framework\/Versions\/A\/SourceKit",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/SourceKitSupport.framework\/Versions\/A\/SourceKitSupport",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/Developer\/Library\/Frameworks\/XcodeKit.framework\/Versions\/A\/XcodeKit",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/Frameworks\/IDEFoundation.framework\/Versions\/A\/IDEFoundation",
      "requiredSymbols" : [
        "_IDEInitialize",
        "_IDESetSafeToLoadDeveloperSystemFrameworks"
      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/Frameworks\/IDEKit.framework\/Versions\/A\/IDEKit",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/Frameworks\/IDELanguageModelKit.framework\/Versions\/A\/IDELanguageModelKit",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/Frameworks\/IDENoticesFoundation.framework\/Versions\/A\/IDENoticesFoundation",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/PlugIns\/IDESourceEditor.framework\/Versions\/A\/IDESourceEditor",
      "requiredSymbols" : [
        "_OBJC_CLASS_$__TtC15IDESourceEditor18SourceCodeDocument",
        "_OBJC_CLASS_$__TtC15IDESourceEditor16SourceCodeEditor"
      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/Developer\/Toolchains\/XcodeDefault.xctoolchain\/usr\/lib\/libclang.dylib",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/SymbolCacheIndexing.framework\/Versions\/A\/SymbolCacheIndexing",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/SymbolicationDT.framework\/Versions\/A\/SymbolicationDT",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/DebugSymbolsDT.framework\/Versions\/A\/DebugSymbolsDT",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/CoreSymbolicationDT.framework\/Versions\/A\/CoreSymbolicationDT",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/DVTInstrumentsFoundation.framework\/Versions\/A\/DVTInstrumentsFoundation",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/Frameworks\/DVTNFASupport.framework\/Versions\/A\/DVTNFASupport",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/DVTKeychain.framework\/Versions\/A\/DVTKeychain",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/DVTKeychainService.framework\/Versions\/A\/DVTKeychainService",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/DTXConnectionServices.framework\/Versions\/A\/DTXConnectionServices",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/PackedPaths.framework\/Versions\/A\/PackedPaths",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/DVTExplorableKit.framework\/Versions\/A\/DVTExplorableKit",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/DVTDeviceKit.framework\/Versions\/A\/DVTDeviceKit",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/DVTFeedbackReporting.framework\/Versions\/A\/DVTFeedbackReporting",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/XCTest.framework\/Versions\/A\/XCTest",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/CoreDocumentation.framework\/Versions\/A\/CoreDocumentation",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/IndexStoreDB_Support.framework\/Versions\/A\/IndexStoreDB_Support",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/IndexStoreDB_LLVMSupport.framework\/Versions\/A\/IndexStoreDB_LLVMSupport",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/SourceKit.framework\/Versions\/A\/XPCServices\/com.apple.dt.SKAgent.xpc\/Contents\/Frameworks\/SKToolchain.dylib",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/SourceKit.framework\/Versions\/A\/XPCServices\/com.apple.dt.SKAgent.xpc\/Contents\/Frameworks\/SKIPC.dylib",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/SourceKit.framework\/Versions\/A\/XPCServices\/com.apple.dt.SKAgent.xpc\/Contents\/Frameworks\/SKSupport.dylib",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/XCResultKit.framework\/Versions\/A\/XCResultKit",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/DVTMacroFoundation.framework\/Versions\/A\/DVTMacroFoundation",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/Testing.framework\/Versions\/A\/Testing",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/XCSourceControl.framework\/Versions\/A\/XCSourceControl",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/DTDeviceServices.framework\/Versions\/A\/DTDeviceServices",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/XCTHarness.framework\/Versions\/A\/XCTHarness",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/BuildServerProtocol.framework\/Versions\/A\/BuildServerProtocol",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/LanguageServerProtocol.framework\/Versions\/A\/LanguageServerProtocol",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/DVTPortal.framework\/Versions\/A\/DVTPortal",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/libXCTestSwiftSupport.dylib",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/XCTDaemonControl.framework\/Versions\/A\/XCTDaemonControl",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/DVTDeviceFoundation.framework\/Versions\/A\/DVTDeviceFoundation",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/DVTSystemPrerequisites.framework\/Versions\/A\/DVTSystemPrerequisites",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/DVTInstrumentsUtilities.framework\/Versions\/A\/DVTInstrumentsUtilities",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/XCStringsParser.framework\/Versions\/A\/XCStringsParser",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/Localization.framework\/Versions\/A\/Localization",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/DVTSourceControl.framework\/Versions\/A\/DVTSourceControl",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/IDEResultKit.framework\/Versions\/A\/IDEResultKit",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/DVTSmartSearch.framework\/Versions\/A\/DVTSmartSearch",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/DVTSystemPrerequisitesUI.framework\/Versions\/A\/DVTSystemPrerequisitesUI",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/DTGraphKit.framework\/Versions\/A\/DTGraphKit",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/MallocStackLoggingDT.framework\/Versions\/A\/MallocStackLoggingDT",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/kperfdataDT.framework\/Versions\/A\/kperfdataDT",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/ktraceDT.framework\/Versions\/A\/ktraceDT",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/RecountDT.framework\/Versions\/A\/RecountDT",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/DVTKeychainUtilities.framework\/Versions\/A\/DVTKeychainUtilities",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/XCTestCore.framework\/Versions\/A\/XCTestCore",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/XCUIAutomation.framework\/Versions\/A\/XCUIAutomation",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/XCTAutomationSupport.framework\/Versions\/A\/XCTAutomationSupport",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/lib_TestingInterop.dylib",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/DVTServices.framework\/Versions\/A\/DVTServices",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/_Testing_Foundation.framework\/Versions\/A\/_Testing_Foundation",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/XCTestSupport.framework\/Versions\/A\/XCTestSupport",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/SwiftSyntax.framework\/Versions\/A\/SwiftSyntax",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/SwiftParser.framework\/Versions\/A\/SwiftParser",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/DTGTTimeline.framework\/Versions\/A\/DTGTTimeline",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/ResultDataPublisher.framework\/Versions\/A\/ResultDataPublisher",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/SwiftSyntaxCShims.framework\/Versions\/A\/SwiftSyntaxCShims",
      "requiredSymbols" : [

      ]
    },
    {
      "path" : "\/Applications\/Xcode.app\/Contents\/SharedFrameworks\/DTGanache.framework\/Versions\/A\/DTGanache",
      "requiredSymbols" : [

      ]
    }
  ]
}
"""#
}
#endif
