import Foundation
import Testing
@testable import ObjCSyntaxInk
@testable import SyntaxInk

@Test func objcHeaderTokenizationClassifiesRepresentativeTokens() async throws {
    let tokens = ObjCGrammar().tokenize(objcHeaderSource)

    #expect(tokens.map(\.text).joined() == objcHeaderSource)
    #expect(tokenStyle("/// Greeter interface", in: tokens) == .documentationMarkup)
    #expect(tokenStyle("@interface", in: tokens) == .keywords)
    #expect(tokenStyle("SYNGreeter", in: tokens) == .typeDeclarations)
    #expect(tokenStyle("NSObject", in: tokens) == .otherClassNames)
    #expect(tokenStyle("NSCopying", in: tokens) == .otherClassNames)
    #expect(styleAtSubstring("NSString", inOccurrenceOf: "@property (nonatomic, copy) NSString *name;", source: objcHeaderSource, tokens: tokens) == .otherClassNames)
    #expect(tokenStyleExactOccurrence("name", occurrence: 1, in: tokens) == .otherPropertiesAndGlobals)
    #expect(tokenStyle("#import", in: tokens) == .preprocessorStatements)
}

@Test func objcImplementationTokenizationClassifiesRepresentativeTokens() async throws {
    let tokens = ObjCGrammar().tokenize(objcImplementationSource)

    #expect(tokens.map(\.text).joined() == objcImplementationSource)
    #expect(tokenStyle("@implementation", in: tokens) == .keywords)
    #expect(tokenStyle("SYNGreeter", after: "@implementation", in: tokens) == .plainText)
    #expect(tokenStyle("instancetype", in: tokens) == .keywords)
    #expect(styleAtSubstring("NSString", inOccurrenceOf: "- (NSString *)description", source: objcImplementationSource, tokens: tokens) == .otherClassNames)
    #expect(tokenStyle("initWithName", in: tokens) == .otherDeclarations)
    #expect(tokenStyle("description", in: tokens) == .otherDeclarations)
    #expect(tokenStyle("SYN-", in: tokens) == .string)
    #expect(tokenStyle("7", in: tokens) == .numbers)
    #expect(tokenStyle("self", in: tokens) == .keywords)
    #expect(tokenStyle("super", in: tokens) == .keywords)
    #expect(tokenStyleExact("init", afterExact: "super", in: tokens) == .otherFunctionAndMethodNames)
    #expect(styleAtSubstring("NSString", inOccurrenceOf: "[NSString stringWithFormat", source: objcImplementationSource, tokens: tokens) == .otherClassNames)
    #expect(tokenStyleExact("stringWithFormat", afterExact: "NSString", in: tokens) == .otherFunctionAndMethodNames)
    #expect(tokenStyle("_name", in: tokens) == .otherPropertiesAndGlobals)
    #expect(tokenStyle("name", after: "_name", in: tokens) == .otherPropertiesAndGlobals)
    #expect(tokenStyle("description", after: "7", in: tokens) == .otherFunctionAndMethodNames)
}

@Test func objcImplementationOpaqueStructTypedefSeparatesStructTagAndAliasStyles() async throws {
    let tokens = ObjCGrammar().tokenize(objcImplementationSample)

    #expect(tokens.map(\.text).joined() == objcImplementationSample)
    #expect(styleAtSubstring("OpaqueWKFrameHandle", inOccurrenceOf: "typedef const struct OpaqueWKFrameHandle *WKFrameHandleRef;", source: objcImplementationSample, tokens: tokens) == .projectClassNames)
    #expect(styleAtSubstring("WKFrameHandleRef", inOccurrenceOf: "typedef const struct OpaqueWKFrameHandle *WKFrameHandleRef;", source: objcImplementationSample, tokens: tokens) == .typeDeclarations)
    #expect(styleAtSubstring("OpaqueWKPage", inOccurrenceOf: "typedef const struct OpaqueWKPage *WKPageRef;", source: objcImplementationSample, tokens: tokens) == .projectClassNames)
    #expect(styleAtSubstring("WKPageRef", inOccurrenceOf: "typedef const struct OpaqueWKPage *WKPageRef;", source: objcImplementationSample, tokens: tokens) == .typeDeclarations)
    #expect(styleAtSubstring("Getter", inOccurrenceOf: "typedef id (*Getter)(id, SEL);", source: objcImplementationSample, tokens: tokens) == .typeDeclarations)
    #expect(styleAtSubstring("Setter", inOccurrenceOf: "typedef void (*Setter)(id, SEL, NSInteger, BOOL);", source: objcImplementationSample, tokens: tokens) == .typeDeclarations)
}

@Test func objcBuiltInFunctionLikeCapturesStayHighlighted() async throws {
    let tokens = ObjCGrammar().tokenize(objcBuiltInSource)

    #expect(tokens.map(\.text).joined() == objcBuiltInSource)
    #expect(tokenStyle("@available", in: tokens) == .keywords)
    #expect(tokenStyle("asm", in: tokens) == .keywords)
    #expect(tokenStyle("__real", in: tokens) == .keywords)
}

@Test func objcSemanticAndFallbackTokenizationMatchPlaygroundHeaderExpectations() async throws {
    let source = try playgroundSample(named: "objcHeaderSample")
    let tokens = ObjCGrammar().tokenize(source)

    #expect(tokens.map(\.text).joined() == source)
    #expect(tokenStyle("TARGET_OS_OSX", in: tokens) == .preprocessorStatements)
    #expect(tokenStyle("FOUNDATION_EXPORT", in: tokens) == .preprocessorStatements)
    #expect(tokenStyle("NS_ERROR_ENUM", in: tokens) == .preprocessorStatements)
    #expect(tokenStyle("nullable", in: tokens) == .keywords)
    #expect(tokenStyle("BOOL", in: tokens) == .keywords)
    #expect(tokenStyle("NSObject", after: "@interface", in: tokens) == .otherClassNames)
    #expect(tokenStyle("WKRuntimeBridge", after: "@interface", in: tokens) == .typeDeclarations)
    #expect(tokenStyle("objectResultFromTarget", in: tokens) == .otherDeclarations)
    #expect(tokenStyle("selectorName", after: "target", in: tokens) == .otherDeclarations)
    #expect(tokenStyleExactOccurrence("selectorName", occurrence: 2, in: tokens) == .otherPropertiesAndGlobals)
    #expect(styleAtSubstring("+", inOccurrenceOf: "objectResultFromTarget", source: source, tokens: tokens) == .plainText)
    #expect(styleAtSubstring(":", inOccurrenceOf: "objectResultFromTarget:", source: source, tokens: tokens) == .plainText)
}

@Test func objcLiteralLikeMacrosPreferKeywordStylingOverPreprocessor() async throws {
    let source = try playgroundSample(named: "objcImplementationSample")
    let tokens = ObjCGrammar().tokenize(source)
    let headerSource = try playgroundSample(named: "objcHeaderSample")
    let headerTokens = ObjCGrammar().tokenize(headerSource)

    #expect(tokens.map(\.text).joined() == source)
    #expect(tokenStyle("NULL", in: tokens) == .keywords)
    #expect(tokenStyle("nil", in: tokens) == .keywords)
    #expect(tokenStyle("Nil", in: tokens) == .keywords)
    #expect(tokenStyle("YES", in: tokens) == .keywords)
    #expect(tokenStyle("NO", in: tokens) == .keywords)
    #expect(tokenStyle("return", in: tokens) == .keywords)
    #expect(tokenStyle("TARGET_OS_OSX", in: headerTokens) == .preprocessorStatements)
    #expect(tokenStyle("FOUNDATION_EXPORT", in: headerTokens) == .preprocessorStatements)
    #expect(tokenStyle("NS_ERROR_ENUM", in: headerTokens) == .preprocessorStatements)
}

@Test func objcDirectiveLiteralLikeMacrosDoNotUseKeywordOverride() async throws {
    let source = """
#if NO
#define FLAG \\
    NO
#endif
"""
    let tokens = ObjCGrammar().tokenize(source)

    #expect(tokens.map(\.text).joined() == source)
    #expect(styleAtSubstring("NO", inOccurrenceOf: "#if NO", source: source, tokens: tokens) == .preprocessorStatements)
    #expect(styleAtSubstring("NO", inOccurrenceOf: "    NO", source: source, tokens: tokens) != .keywords)
}

@Test func objcBuiltinAndTypeFamilyIdentifiersMatchXcodeBuckets() async throws {
    let source = objcBuiltinTypeSource
    let tokens = ObjCGrammar().tokenize(source)

    #expect(tokens.map(\.text).joined() == source)
    #expect(styleAtSubstring("SYNBridgeErrorCode", inOccurrenceOf: "NS_ERROR_ENUM(", source: source, tokens: tokens) == .typeDeclarations)
    #expect(tokenStyle("SYNBridgeRuntime", after: "@interface", in: tokens) == .typeDeclarations)
    #expect(tokenStyle("SYNBridgeRuntime", after: "@implementation", in: tokens) == .plainText)
    #expect(tokenStyleExactOccurrence("void", occurrence: 1, in: tokens) == .keywords)
    #expect(tokenStyleExactOccurrence("void", occurrence: 2, in: tokens) == .keywords)
    #expect(tokenStyleExactOccurrence("BOOL", occurrence: 1, in: tokens) == .keywords)
    #expect(styleAtSubstring("NSInteger", inOccurrenceOf: "stateRawValue:(NSInteger)stateRawValue", source: source, tokens: tokens) == .otherTypeNames)
    #expect(styleAtSubstring("NSErrorDomain", inOccurrenceOf: "FOUNDATION_EXPORT NSErrorDomain const SYNBridgeErrorDomain;", source: source, tokens: tokens) == .otherTypeNames)
    #expect(styleAtSubstring("NSObject", inOccurrenceOf: "+ (BOOL)invokeActionStateOnTarget:(NSObject *)target", source: source, tokens: tokens) == .otherClassNames)
    #expect(styleAtSubstring("WKWebView", inOccurrenceOf: "+ (void)frameInfosForWebView:(WKWebView *)webView", source: source, tokens: tokens) == .otherClassNames)
    #expect(styleAtSubstring("NSArray", inOccurrenceOf: "completionHandler:(void (^)(NSArray<WKFrameInfo *> * _Nullable frameInfos))completionHandler;", source: source, tokens: tokens) == .otherClassNames)
    #expect(styleAtSubstring("WKFrameInfo", inOccurrenceOf: "completionHandler:(void (^)(NSArray<WKFrameInfo *> * _Nullable frameInfos))completionHandler;", source: source, tokens: tokens) == .otherClassNames)
    #expect(styleAtSubstring("WKContentWorld", inOccurrenceOf: "contentWorld:(WKContentWorld *)contentWorld", source: source, tokens: tokens) == .otherClassNames)
    #expect(tokenStyle("frameInfosForWebView", in: tokens) == .otherDeclarations)
    #expect(styleAtSubstring("completionHandler", inOccurrenceOf: "completionHandler:", source: source, tokens: tokens) == .otherDeclarations)
    #expect(styleAtSubstring(":", inOccurrenceOf: "completionHandler:", source: source, tokens: tokens) == .plainText)
    #expect(styleAtSubstring("id", inOccurrenceOf: "delegate:", source: source, tokens: tokens) == .keywords)
    #expect(styleAtSubstring("id", inOccurrenceOf: "buffer:", source: source, tokens: tokens) == .keywords)
    #expect(tokenStyle("nullable", in: tokens) == .keywords)
}

@Test func objcImplementationBodyExternalTypesUseSystemReferenceStyles() async throws {
    let source = try playgroundSample(named: "objcImplementationSample")
    let tokens = ObjCGrammar().tokenize(source)

    #expect(styleAtSubstring("NSString", inOccurrenceOf: "for (NSString *setterName in setters)", source: source, tokens: tokens) == .otherClassNames)
    #expect(styleAtSubstring("WKContentWorld", inOccurrenceOf: "Class worldClass = [WKContentWorld class];", source: source, tokens: tokens) == .otherClassNames)
}

@Test func objcImplementationMethodSignatureMatchesXcodeBuckets() async throws {
    let source = try playgroundSample(named: "objcImplementationSample")
    let tokens = ObjCGrammar().tokenize(source)

    #expect(styleAtSubstring("boolResultFromTarget", inOccurrenceOf: "boolResultFromTarget:(NSObject *)target selectorName:(NSString *)selectorName", source: source, tokens: tokens) == .otherDeclarations)
    #expect(styleAtSubstringOccurrence("selectorName", occurrence: 1, inOccurrenceOf: "boolResultFromTarget:(NSObject *)target selectorName:(NSString *)selectorName", source: source, tokens: tokens) == .otherDeclarations)
    #expect(styleAtSubstringOccurrence("selectorName", occurrence: 2, inOccurrenceOf: "boolResultFromTarget:(NSObject *)target selectorName:(NSString *)selectorName", source: source, tokens: tokens) == .otherPropertiesAndGlobals)
    #expect(styleAtSubstring("+", inOccurrenceOf: "boolResultFromTarget:(NSObject *)target selectorName:(NSString *)selectorName", source: source, tokens: tokens) == .plainText)
    #expect(styleAtSubstring(":", inOccurrenceOf: "boolResultFromTarget:(NSObject *)target selectorName:(NSString *)selectorName", source: source, tokens: tokens) == .plainText)
}

@Test func objcBuiltInThemesExposeRepresentativeStyles() async throws {
    assertStyle(ObjCTheme.default.configuration.styleResolver(.plainText), equals: themeExpectations.defaultTheme.plain)
    assertStyle(ObjCTheme.defaultDark.configuration.styleResolver(.keywords), equals: themeExpectations.defaultDarkKeyword)
    assertStyle(ObjCTheme.presentationDark.configuration.styleResolver(.string), equals: themeExpectations.presentationDarkTheme.string)
    assertStyle(ObjCTheme.default.configuration.styleResolver(.projectFunctionAndMethodNames), equals: themeExpectations.defaultTheme.projectIdentifier)
    assertStyle(ObjCTheme.default.configuration.styleResolver(.otherFunctionAndMethodNames), equals: themeExpectations.defaultTheme.systemIdentifier)
    assertStyle(ObjCTheme.default.configuration.styleResolver(.projectClassNames), equals: themeExpectations.defaultTheme.projectReference)
    assertStyle(ObjCTheme.default.configuration.styleResolver(.otherClassNames), equals: themeExpectations.defaultTheme.systemReference)
    assertStyle(ObjCTheme.default.configuration.styleResolver(.projectTypeNames), equals: themeExpectations.defaultTheme.projectReference)
    assertStyle(ObjCTheme.default.configuration.styleResolver(.otherPropertiesAndGlobals), equals: themeExpectations.defaultTheme.plain)
    assertStyle(ObjCTheme.default.configuration.styleResolver(.typeDeclarations), equals: themeExpectations.defaultTheme.typeDeclaration)
    assertStyle(ObjCTheme.default.configuration.styleResolver(.otherTypeNames), equals: themeExpectations.defaultTheme.systemReference)
}

@Test func objcThemeBaseOverloadPreservesPlainTextBase() async throws {
    let base = SyntaxStyle(
        font: .custom(name: "Menlo", size: 24.0, weight: .thin),
        color: SyntaxColor(red: 10.0, green: 20.0, blue: 30.0)
    )

    let theme = ObjCTheme.presentationDark(base)
    assertStyle(theme.configuration.styleResolver(.plainText), equals: base)

    var expectedKeyword = base
    expectedKeyword.color = themeExpectations.presentationDarkTheme.keyword.color
    expectedKeyword.font.weight = themeExpectations.presentationDarkTheme.keyword.font.weight
    assertStyle(theme.configuration.styleResolver(.keywords), equals: expectedKeyword)
}

@Test func objcHighlighterPreservesSourceAndUsesThemeStyles() async throws {
    let highlighted = ObjCSyntaxHighlighter(theme: .default).highlight(objcImplementationSource)
    #expect(String(highlighted.characters) == objcImplementationSource)

    let tokens = ObjCGrammar().tokenize(objcImplementationSource)
    let methodToken = tokens.first { $0.text == "description" && $0.styleKind == .otherDeclarations }
    let stringToken = tokens.first { $0.text.contains("SYN-") }

    #expect(methodToken != nil)
    #expect(stringToken != nil)
    assertStyle(ObjCTheme.default.configuration.styleResolver(methodToken!.styleKind), equals: themeExpectations.defaultTheme.declaration)
    assertStyle(ObjCTheme.default.configuration.styleResolver(stringToken!.styleKind), equals: themeExpectations.defaultTheme.string)
    assertStyle(ObjCTheme.default.configuration.styleResolver(.projectFunctionAndMethodNames), equals: themeExpectations.defaultTheme.projectIdentifier)
    assertStyle(ObjCTheme.default.configuration.styleResolver(.otherFunctionAndMethodNames), equals: themeExpectations.defaultTheme.systemIdentifier)
    assertStyle(ObjCTheme.default.configuration.styleResolver(.keywords), equals: themeExpectations.defaultTheme.keyword)
}

@Test func objcSameFileTypeReferencesUseProjectClassStyles() async throws {
    let tokens = ObjCGrammar().tokenize(objcLocalOriginSource)

    #expect(tokens.map(\.text).joined() == objcLocalOriginSource)
    #expect(tokenStyle("SYNLocalThing", in: tokens) == .typeDeclarations)
    #expect(styleAtSubstring("SYNLocalThing", inOccurrenceOf: "+ (SYNLocalThing *)makeThing", source: objcLocalOriginSource, tokens: tokens) == .projectClassNames)
    #expect(styleAtSubstring("SYNLocalThing", inOccurrenceOf: "[SYNLocalThing makeThing]", source: objcLocalOriginSource, tokens: tokens) == .projectClassNames)
    #expect(styleAtSubstring("NSObject", inOccurrenceOf: "@interface SYNLocalThing : NSObject", source: objcLocalOriginSource, tokens: tokens) == .otherClassNames)
    #expect(styleAtSubstring("NSString", inOccurrenceOf: "+ (NSString *)runWithTarget", source: objcLocalOriginSource, tokens: tokens) == .otherClassNames)
}

@Test func objcSameFileMethodReferencesUseProjectFunctionStyles() async throws {
    let tokens = ObjCGrammar().tokenize(objcLocalOriginSource)

    #expect(tokens.map(\.text).joined() == objcLocalOriginSource)
    #expect(styleAtSubstring("makeThing", inOccurrenceOf: "+ (SYNLocalThing *)makeThing", source: objcLocalOriginSource, tokens: tokens) == .otherDeclarations)
    #expect(styleAtSubstring("makeThing", inOccurrenceOf: "[self makeThing]", source: objcLocalOriginSource, tokens: tokens) == .projectFunctionAndMethodNames)
    #expect(styleAtSubstring("makeThing", inOccurrenceOf: "[SYNLocalThing makeThing]", source: objcLocalOriginSource, tokens: tokens) == .projectFunctionAndMethodNames)
}

@Test func objcSameFileConstructorReferencesUseProjectFunctionStyles() async throws {
    let tokens = ObjCGrammar().tokenize(objcLocalConstructorOriginSource)

    #expect(tokens.map(\.text).joined() == objcLocalConstructorOriginSource)
    #expect(styleAtSubstring("init", inOccurrenceOf: "- (instancetype)init", source: objcLocalConstructorOriginSource, tokens: tokens) == .otherDeclarations)
    #expect(styleAtSubstring("init", inOccurrenceOf: "[self init]", source: objcLocalConstructorOriginSource, tokens: tokens) == .projectFunctionAndMethodNames)
}

@Test func objcImportedSdkMethodReferencesStaySystemScoped() async throws {
    let tokens = ObjCGrammar().tokenize(objcLocalOriginSource)

    #expect(tokens.map(\.text).joined() == objcLocalOriginSource)
    #expect(styleAtSubstring("respondsToSelector", inOccurrenceOf: "[target respondsToSelector:selector]", source: objcLocalOriginSource, tokens: tokens) == .otherFunctionAndMethodNames)
    #expect(styleAtSubstring("methodForSelector", inOccurrenceOf: "[target methodForSelector:selector]", source: objcLocalOriginSource, tokens: tokens) == .otherFunctionAndMethodNames)
}

@Test func objcFallbackMethodCallWithSelfReceiverUsesLocalCallableLookup() async throws {
    let declaration = ObjCResolvedToken(
        text: "makeThing",
        range: NSRange(location: 0, length: 9),
        lexicalKind: .method,
        resolvedKind: .methodDeclaration,
        origin: .project,
        referenceStyleKind: .callable,
        receiverHint: nil,
        isForwardClassDeclaration: false
    )
    let call = ObjCResolvedToken(
        text: "makeThing",
        range: NSRange(location: 10, length: 9),
        lexicalKind: .method,
        resolvedKind: .methodCall,
        origin: nil,
        referenceStyleKind: .callable,
        receiverHint: .self,
        isForwardClassDeclaration: false
    )
    let localSymbols = ObjCLocalSymbolIndex(semanticMatches: [], fallbackTokens: [declaration, call])
    let context = ObjCHighlightingContext(
        source: "[self makeThing]",
        text: "makeThing",
        range: call.range,
        semantic: nil,
        fallback: call,
        localSymbols: localSymbols
    )

    #expect(
        context.matchesLocalReference(
            for: .init(
                resolvedKind: .methodCall,
                origin: nil,
                referenceStyleKind: .callable
            )
        )
    )
}

@Test func objcFallbackConstructorCallsCaptureReceiverHints() async throws {
    let tokens = ObjCFallbackCaptureRule.resolvedTokens(in: objcLocalConstructorOriginSource)

    #expect(tokens.first { $0.text == "init" && $0.receiverHint == .self } != nil)
    #expect(tokens.first { $0.text == "init" && $0.receiverHint == .typeName("SYNLocalInitThing") } != nil)
}

@Test func objcFallbackConstructorCallWithTypeReceiverUsesLocalCallableLookup() async throws {
    let typeDeclaration = ObjCResolvedToken(
        text: "SYNLocalInitThing",
        range: NSRange(location: 0, length: 16),
        lexicalKind: .type,
        resolvedKind: .typeDeclaration,
        origin: .project,
        referenceStyleKind: .className,
        receiverHint: nil,
        isForwardClassDeclaration: false
    )
    let declaration = ObjCResolvedToken(
        text: "init",
        range: NSRange(location: 17, length: 4),
        lexicalKind: .method,
        resolvedKind: .methodDeclaration,
        origin: .project,
        referenceStyleKind: .callable,
        receiverHint: nil,
        isForwardClassDeclaration: false
    )
    let call = ObjCResolvedToken(
        text: "init",
        range: NSRange(location: 22, length: 4),
        lexicalKind: .constructor,
        resolvedKind: .methodCall,
        origin: nil,
        referenceStyleKind: .callable,
        receiverHint: .typeName("SYNLocalInitThing"),
        isForwardClassDeclaration: false
    )
    let localSymbols = ObjCLocalSymbolIndex(
        semanticMatches: [],
        fallbackTokens: [typeDeclaration, declaration, call]
    )
    let context = ObjCHighlightingContext(
        source: "[SYNLocalInitThing init]",
        text: "init",
        range: call.range,
        semantic: nil,
        fallback: call,
        localSymbols: localSymbols
    )

    #expect(
        context.matchesLocalReference(
            for: .init(
                resolvedKind: .methodCall,
                origin: nil,
                referenceStyleKind: .callable
            )
        )
    )
}

@Test func objcImplementationBodyTypeReferencesStayTypeReferencesInFallback() async throws {
    let source = try playgroundSample(named: "objcImplementationSample")
    let tokens = ObjCFallbackCaptureRule.resolvedTokens(in: source)

    #expect(
        resolvedKindAtSubstring(
            "NSString",
            inOccurrenceOf: "for (NSString *setterName in setters)",
            source: source,
            tokens: tokens
        ) == .typeReference
    )
    #expect(
        resolvedKindAtSubstring(
            "WKContentWorld",
            inOccurrenceOf: "Class worldClass = [WKContentWorld class];",
            source: source,
            tokens: tokens
        ) == .typeReference
    )
}

@Test func objcFallbackMethodSignatureUsesFunctionLexicalBuckets() async throws {
    let source = try playgroundSample(named: "objcImplementationSample")
    let tokens = ObjCFallbackCaptureRule.resolvedTokens(in: source)

    #expect(lexicalKindAtSubstring("boolResultFromTarget", inOccurrenceOf: "boolResultFromTarget:(NSObject *)target selectorName:(NSString *)selectorName", source: source, tokens: tokens) == .function)
    #expect(lexicalKindAtSubstringOccurrence("selectorName", occurrence: 1, inOccurrenceOf: "boolResultFromTarget:(NSObject *)target selectorName:(NSString *)selectorName", source: source, tokens: tokens) == .function)
}

@Test func objcNilReceiverLookupDoesNotMatchClassScopedCallables() async throws {
    let classMethod = ObjCResolvedToken(
        text: "foo",
        range: NSRange(location: 0, length: 3),
        lexicalKind: .method,
        resolvedKind: .methodDeclaration,
        origin: .project,
        referenceStyleKind: .callable,
        receiverHint: nil,
        isForwardClassDeclaration: false
    )
    let globalFunction = ObjCResolvedToken(
        text: "bar",
        range: NSRange(location: 4, length: 3),
        lexicalKind: .function,
        resolvedKind: .methodDeclaration,
        origin: .project,
        referenceStyleKind: .callable,
        receiverHint: nil,
        isForwardClassDeclaration: false
    )
    let localSymbols = ObjCLocalSymbolIndex(semanticMatches: [], fallbackTokens: [classMethod, globalFunction])

    #expect(localSymbols.containsCallable(named: "foo", receiverHint: nil) == false)
    #expect(localSymbols.containsCallable(named: "foo", receiverHint: .self))
    #expect(localSymbols.containsCallable(named: "bar", receiverHint: nil))
}

@Test func objcSystemForwardDeclarationsDoNotSeedProjectOrigin() async throws {
    let tokens = ObjCGrammar().tokenize(objcSystemForwardDeclarationSource)

    #expect(tokens.map(\.text).joined() == objcSystemForwardDeclarationSource)
    #expect(styleAtSubstring("NSObject", inOccurrenceOf: "@class NSObject;", source: objcSystemForwardDeclarationSource, tokens: tokens) == .otherClassNames)
    #expect(styleAtSubstring("NSObject", inOccurrenceOf: "[NSObject class]", source: objcSystemForwardDeclarationSource, tokens: tokens) == .otherClassNames)
}

@Test func objcBuiltInThemesExposeProjectAndSystemReferenceStyles() async throws {
    assertStyle(ObjCTheme.default.configuration.styleResolver(.projectClassNames), equals: themeExpectations.defaultTheme.projectReference)
    assertStyle(ObjCTheme.default.configuration.styleResolver(.projectTypeNames), equals: themeExpectations.defaultTheme.projectReference)
    assertStyle(ObjCTheme.default.configuration.styleResolver(.otherClassNames), equals: themeExpectations.defaultTheme.systemReference)
    assertStyle(ObjCTheme.default.configuration.styleResolver(.otherTypeNames), equals: themeExpectations.defaultTheme.systemReference)
    assertStyle(ObjCTheme.default.configuration.styleResolver(.projectFunctionAndMethodNames), equals: themeExpectations.defaultTheme.projectIdentifier)
    assertStyle(ObjCTheme.default.configuration.styleResolver(.otherFunctionAndMethodNames), equals: themeExpectations.defaultTheme.systemIdentifier)
}

@Test func objcSemanticFixturesStayInSyncWithPlaygroundSamples() async throws {
    let header = try String(contentsOf: fixtureURL(named: "WKRuntimeBridge.h"), encoding: .utf8)
    let implementation = try String(contentsOf: fixtureURL(named: "WKRuntimeBridge.m"), encoding: .utf8)
    let playgroundHeader = try playgroundSample(named: "objcHeaderSample")
    let playgroundImplementation = try playgroundSample(named: "objcImplementationSample")

    #expect(header == playgroundHeader)
    #expect(implementation == playgroundImplementation)
}

@Test func objcRawSemanticKindsMatchSemanticFixturePlaygroundHeader() async throws {
    try assertSemanticFixtureMatchesRawSemanticKinds(semanticFile: "WKRuntimeBridge.h.semantic-tokens.json")
}

@Test func objcRawSemanticKindsMatchSemanticFixturePlaygroundImplementation() async throws {
    try assertSemanticFixtureMatchesRawSemanticKinds(semanticFile: "WKRuntimeBridge.m.semantic-tokens.json")
}

private func tokenStyle(_ text: String, in tokens: [ObjCToken]) -> ObjCTheme.StyleKind? {
    tokens.first(where: { $0.text.contains(text) })?.styleKind
}

private func tokenStyle(_ text: String, after prefix: String, in tokens: [ObjCToken]) -> ObjCTheme.StyleKind? {
    guard let startIndex = tokens.firstIndex(where: { $0.text.contains(prefix) }) else {
        return nil
    }

    return tokens[startIndex...].first(where: { $0.text.contains(text) })?.styleKind
}

private func tokenStyleExact(_ text: String, afterExact prefix: String, in tokens: [ObjCToken]) -> ObjCTheme.StyleKind? {
    guard let startIndex = tokens.firstIndex(where: { $0.text == prefix }) else {
        return nil
    }

    return tokens[(startIndex + 1)...].first(where: { $0.text == text })?.styleKind
}

private func tokenStyleExactOccurrence(_ text: String, occurrence: Int, in tokens: [ObjCToken]) -> ObjCTheme.StyleKind? {
    guard occurrence > 0 else { return nil }
    let matches = tokens.filter { $0.text == text }
    guard occurrence <= matches.count else { return nil }
    return matches[occurrence - 1].styleKind
}

private struct SemanticFixture: Decodable {
    struct Token: Decodable {
        let line: Int
        let column: Int
        let length: Int
        let text: String
        let tokenType: String
        let tokenModifiers: [String]
    }

    let source: String
    let tokens: [Token]
}

private func assertSemanticFixtureMatchesRawSemanticKinds(semanticFile: String) throws {
    let semanticURL = fixtureURL(named: semanticFile)

    let fixture = try JSONDecoder().decode(SemanticFixture.self, from: Data(contentsOf: semanticURL))

    for token in fixture.tokens {
        guard let expectedKind = expectedRawSemanticKind(for: token) else { continue }
        let semanticToken = ObjCSemanticToken(
            text: token.text,
            range: NSRange(location: 0, length: token.length),
            tokenType: token.tokenType,
            tokenModifiers: Set(token.tokenModifiers)
        )
        let classification = ObjCSemanticClassifier.classify(semanticToken)

        #expect(classification != nil)
        if let classification {
            if classification.rawKind != expectedKind {
                Issue.record("Semantic mismatch for \(token.text) @ \(token.line):\(token.column): expected \(expectedKind), got \(classification.rawKind)")
            }
            #expect(classification.rawKind == expectedKind)
            #expect(classification.modifiers == Set(token.tokenModifiers))
        }
    }
}

private func expectedRawSemanticKind(for token: SemanticFixture.Token) -> ObjCRawSemanticKind? {
    let modifiers = Set(token.tokenModifiers)

    switch token.tokenType {
    case "macro":
        return .macro
    case "keyword", "modifier":
        return .keyword
    case "comment":
        return modifiers.contains("documentation") ? .documentationComment : .comment
    case "string":
        return .string
    case "number":
        return .number
    case "class":
        return .className
    case "interface":
        return .interfaceName
    case "struct":
        return .structName
    case "type":
        return .typeName
    case "enum":
        return .enumName
    case "enumMember":
        return .enumMember
    case "function", "method":
        return token.tokenType == "function" ? .functionName : .methodName
    case "parameter":
        return .parameterName
    case "property":
        return .propertyName
    case "variable":
        return .variableName
    default:
        return nil
    }
}

private func styleAtSubstring(
    _ needle: String,
    inOccurrenceOf anchor: String,
    source: String,
    tokens: [ObjCToken]
) -> ObjCTheme.StyleKind? {
    let string = source as NSString
    let anchorRange = string.range(of: anchor)
    guard anchorRange.location != NSNotFound else { return nil }

    let searchRange = string.lineRange(for: anchorRange)
    let needleRange = string.range(of: needle, options: [], range: searchRange)
    guard needleRange.location != NSNotFound else { return nil }

    return tokens.first { NSLocationInRange(needleRange.location, $0.range) }?.styleKind
}

private func styleAtSubstringOccurrence(
    _ needle: String,
    occurrence: Int,
    inOccurrenceOf anchor: String,
    source: String,
    tokens: [ObjCToken]
) -> ObjCTheme.StyleKind? {
    let string = source as NSString
    let anchorRange = string.range(of: anchor)
    guard anchorRange.location != NSNotFound else { return nil }
    let searchRange = string.lineRange(for: anchorRange)

    var currentRange = searchRange
    for index in 1...occurrence {
        let needleRange = string.range(of: needle, options: [], range: currentRange)
        guard needleRange.location != NSNotFound else { return nil }
        if index == occurrence {
            return tokens.first { NSLocationInRange(needleRange.location, $0.range) }?.styleKind
        }

        let nextLocation = NSMaxRange(needleRange)
        currentRange = NSRange(location: nextLocation, length: NSMaxRange(searchRange) - nextLocation)
    }

    return nil
}

private func resolvedKindAtSubstring(
    _ needle: String,
    inOccurrenceOf anchor: String,
    source: String,
    tokens: [ObjCResolvedToken]
) -> ObjCResolvedKind? {
    let string = source as NSString
    let anchorRange = string.range(of: anchor)
    guard anchorRange.location != NSNotFound else { return nil }

    let searchRange = string.lineRange(for: anchorRange)
    let needleRange = string.range(of: needle, options: [], range: searchRange)
    guard needleRange.location != NSNotFound else { return nil }

    return tokens.first { NSLocationInRange(needleRange.location, $0.range) }?.resolvedKind
}

private func lexicalKindAtSubstring(
    _ needle: String,
    inOccurrenceOf anchor: String,
    source: String,
    tokens: [ObjCResolvedToken]
) -> ObjCLexicalKind? {
    let string = source as NSString
    let anchorRange = string.range(of: anchor)
    guard anchorRange.location != NSNotFound else { return nil }

    let searchRange = string.lineRange(for: anchorRange)
    let needleRange = string.range(of: needle, options: [], range: searchRange)
    guard needleRange.location != NSNotFound else { return nil }

    return tokens.first { NSLocationInRange(needleRange.location, $0.range) }?.lexicalKind
}

private func lexicalKindAtSubstringOccurrence(
    _ needle: String,
    occurrence: Int,
    inOccurrenceOf anchor: String,
    source: String,
    tokens: [ObjCResolvedToken]
) -> ObjCLexicalKind? {
    let string = source as NSString
    let anchorRange = string.range(of: anchor)
    guard anchorRange.location != NSNotFound else { return nil }
    let searchRange = string.lineRange(for: anchorRange)

    var currentRange = searchRange
    for index in 1...occurrence {
        let needleRange = string.range(of: needle, options: [], range: currentRange)
        guard needleRange.location != NSNotFound else { return nil }
        if index == occurrence {
            return tokens.first { NSLocationInRange(needleRange.location, $0.range) }?.lexicalKind
        }

        let nextLocation = NSMaxRange(needleRange)
        currentRange = NSRange(location: nextLocation, length: NSMaxRange(searchRange) - nextLocation)
    }

    return nil
}

private func fixtureURL(named name: String) -> URL {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent("Fixtures")
        .appendingPathComponent("ObjCSemantic")
        .appendingPathComponent(name)
}

private func playgroundSample(named name: String) throws -> String {
    let sourceURL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Sources")
        .appendingPathComponent("ObjCSyntaxInk")
        .appendingPathComponent("ObjCPlayground.swift")

    let source = try String(contentsOf: sourceURL, encoding: .utf8)
    let startMarker = "let \(name) = \"\"\"\n"

    guard let startRange = source.range(of: startMarker) else {
        throw NSError(domain: "ObjCSyntaxInkTests", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing sample \(name)"])
    }

    let remainder = source[startRange.upperBound...]
    guard let endRange = remainder.range(of: "\n\"\"\"") else {
        throw NSError(domain: "ObjCSyntaxInkTests", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unterminated sample \(name)"])
    }

    return String(remainder[..<endRange.lowerBound])
}

private func assertStyle(_ actual: SyntaxStyle, equals expected: SyntaxStyle) {
    #expect(actual.color.red == expected.color.red)
    #expect(actual.color.green == expected.color.green)
    #expect(actual.color.blue == expected.color.blue)
    #expect(actual.color.alpha == expected.color.alpha)

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

private let objcHeaderSource = """
#import <Foundation/Foundation.h>

/// Greeter interface
@interface SYNGreeter : NSObject <NSCopying>

@property (nonatomic, copy) NSString *name;

- (instancetype)initWithName:(NSString *)name;
@end
"""

private let objcImplementationSource = """
#import "SYNGreeter.h"

@implementation SYNGreeter

- (instancetype)initWithName:(NSString *)name {
    self = [super init];
    if (self) {
        _name = [name stringByAppendingString:@"-preview"];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"SYN-%02ld-%@", (long)7, [super description]];
}

@end
"""

private let objcBuiltInSource = """
void SYNCheck(double value) {
    if (@available(macOS 14.0, *)) {
        asm("nop");
        __real value;
    }
}
"""

private let objcBuiltinTypeSource = """
#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

FOUNDATION_EXPORT NSErrorDomain const SYNBridgeErrorDomain;

typedef NS_ERROR_ENUM(SYNBridgeErrorDomain, SYNBridgeErrorCode) {
    SYNBridgeErrorCodeInvalidInput = 1,
};

@interface SYNBridgeRuntime : NSObject
+ (void)frameInfosForWebView:(WKWebView *)webView
           completionHandler:(void (^)(NSArray<WKFrameInfo *> * _Nullable frameInfos))completionHandler;
+ (BOOL)invokeActionStateOnTarget:(NSObject *)target
                    selectorName:(NSString *)selectorName
                   stateRawValue:(NSInteger)stateRawValue
                 notifyObservers:(BOOL)notifyObservers;
+ (BOOL)invokeSetResourceLoadDelegateOnWebView:(WKWebView *)webView
                                  selectorName:(NSString *)selectorName
                                      delegate:(nullable id)delegate;
+ (BOOL)addBufferOnController:(WKUserContentController *)controller
                 selectorName:(NSString *)selectorName
                       buffer:(id)buffer
                         name:(NSString *)name
                 contentWorld:(WKContentWorld *)contentWorld
              isPublicSignature:(BOOL)isPublicSignature;
@end

@implementation SYNBridgeRuntime
@end
"""

private let objcLocalOriginSource = """
#import <Foundation/Foundation.h>

@interface SYNLocalThing : NSObject
+ (SYNLocalThing *)makeThing;
+ (NSString *)runWithTarget:(NSObject *)target;
@end

@implementation SYNLocalThing
+ (SYNLocalThing *)makeThing {
    return [self new];
}

+ (NSString *)runWithTarget:(NSObject *)target {
    SEL selector = NSSelectorFromString(@"description");
    [self makeThing];
    id value = [SYNLocalThing makeThing];
    if ([target respondsToSelector:selector]) {
        IMP implementation = [target methodForSelector:selector];
        if (implementation != NULL) {
            return [value description];
        }
    }
    return nil;
}
@end
"""

private let objcLocalConstructorOriginSource = """
#import <Foundation/Foundation.h>

@interface SYNLocalInitThing : NSObject
- (instancetype)init;
+ (instancetype)factory;
@end

@implementation SYNLocalInitThing
- (instancetype)init {
    return [self init];
}

+ (instancetype)factory {
    return [SYNLocalInitThing init];
}
@end
"""

private let objcSystemForwardDeclarationSource = """
#import <Foundation/Foundation.h>

@class NSObject;

@interface SYNSystemForwardDecl : NSObject
+ (Class)runtimeClass;
@end

@implementation SYNSystemForwardDecl
+ (Class)runtimeClass {
    return [NSObject class];
}
@end
"""

private enum themeExpectations {
    static let defaultTheme = (
        plain: SyntaxStyle(font: .system(size: 12.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.85)),
        keyword: SyntaxStyle(font: .system(size: 12.0, weight: .semibold, design: .monospaced), color: SyntaxColor(red: 154.93596, green: 35.06913, blue: 146.95242, alpha: 1.0)),
        string: SyntaxStyle(font: .system(size: 12.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 196.35, green: 26.01, blue: 21.93, alpha: 1.0)),
        declaration: SyntaxStyle(font: .system(size: 12.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 14.999992, green: 103.999965, blue: 160.000005, alpha: 1.0)),
        typeDeclaration: SyntaxStyle(font: .system(size: 12.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 11.000012, green: 79.00002, blue: 121.00005, alpha: 1.0)),
        projectReference: SyntaxStyle(font: .system(size: 12.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 28.00206, green: 69.554055, blue: 73.616205, alpha: 1.0)),
        systemReference: SyntaxStyle(font: .system(size: 12.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 57.258465, green: 0.0, blue: 160.147395, alpha: 1.0)),
        projectIdentifier: SyntaxStyle(font: .system(size: 12.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 49.51692, green: 109.483995, blue: 115.911015, alpha: 1.0)),
        systemIdentifier: SyntaxStyle(font: .system(size: 12.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 107.585265, green: 54.259665, blue: 169.265175, alpha: 1.0))
    )
    static let defaultDarkKeyword = SyntaxStyle(font: .system(size: 12.0, weight: .bold, design: .monospaced), color: SyntaxColor(red: 252.04047, green: 95.25525, blue: 162.773895, alpha: 1.0))
    static let presentationDarkTheme = (
        keyword: SyntaxStyle(font: .system(size: 18.0, weight: .semibold, design: .monospaced), color: SyntaxColor(red: 241.6176, green: 35.68164, blue: 139.516875, alpha: 1.0)),
        string: SyntaxStyle(font: .system(size: 18.0, weight: .regular, design: .monospaced), color: SyntaxColor(red: 251.999925, green: 70.00005, blue: 80.999985, alpha: 1.0))
    )
}
