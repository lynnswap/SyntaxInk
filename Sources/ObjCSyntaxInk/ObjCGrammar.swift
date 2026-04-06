import Foundation
import SyntaxInk
import SwiftTreeSitter
import TreeSitterObjc

@available(iOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
@available(tvOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
@available(watchOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
@available(visionOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
public struct ObjCToken: Sendable {
    public let text: String
    public let range: NSRange
    public let styleKind: ObjCTheme.StyleKind
}

enum ObjCLexicalKind: Sendable, Equatable {
    case comment
    case string
    case number
    case preprocessor
    case keyword
    case attribute
    case type
    case namespace
    case method
    case function
    case constructor
    case property
    case variable
    case constant
    case parameter
}

enum ObjCResolvedKind: Sendable, Equatable {
    case plain
    case macro
    case keyword
    case preprocessor
    case comment
    case documentationComment
    case string
    case number
    case typeDeclaration
    case typeReference
    case methodDeclaration
    case methodCall
    case parameterName
    case propertyName
    case variableName
    case enumType
    case enumMember
    case globalReadonlyConstant
    case otherName
    case attribute

    var styleKind: ObjCTheme.StyleKind {
        switch self {
        case .plain:
            return .plainText
        case .keyword, .attribute:
            return .keywords
        case .macro, .preprocessor:
            return .preprocessorStatements
        case .comment:
            return .comments
        case .documentationComment:
            return .documentationMarkup
        case .string:
            return .string
        case .number:
            return .numbers
        case .typeDeclaration, .enumType:
            return .typeDeclarations
        case .typeReference:
            return .otherTypeNames
        case .methodDeclaration:
            return .otherDeclarations
        case .methodCall:
            return .otherFunctionAndMethodNames
        case .parameterName, .propertyName, .variableName, .enumMember, .globalReadonlyConstant, .otherName:
            return .otherPropertiesAndGlobals
        }
    }
}

private enum ObjCXcodeVisualBucket: Sendable, Equatable {
    case plain
    case macro
    case keyword
    case keywordBuiltinType
    case preprocessor
    case comment
    case documentationComment
    case string
    case number
    case interfaceTypeDeclaration
    case typedefTypeDeclaration
    case implementationTypeName
    case typeReference
    case otherDeclaration
    case methodCall
    case variableLikeName
    case propertyName
    case enumMember
    case globalReadonlyConstant
    case attribute

    var resolvedKind: ObjCResolvedKind {
        switch self {
        case .plain, .implementationTypeName:
            return .plain
        case .macro:
            return .macro
        case .keyword, .keywordBuiltinType:
            return .keyword
        case .preprocessor:
            return .preprocessor
        case .comment:
            return .comment
        case .documentationComment:
            return .documentationComment
        case .string:
            return .string
        case .number:
            return .number
        case .interfaceTypeDeclaration, .typedefTypeDeclaration:
            return .typeDeclaration
        case .typeReference:
            return .typeReference
        case .otherDeclaration:
            return .methodDeclaration
        case .methodCall:
            return .methodCall
        case .variableLikeName:
            return .variableName
        case .propertyName:
            return .propertyName
        case .enumMember:
            return .enumMember
        case .globalReadonlyConstant:
            return .globalReadonlyConstant
        case .attribute:
            return .attribute
        }
    }
}

struct ObjCResolvedToken: Sendable {
    let text: String
    let range: NSRange
    let lexicalKind: ObjCLexicalKind?
    let resolvedKind: ObjCResolvedKind?

    var styleKind: ObjCTheme.StyleKind {
        resolvedKind?.styleKind ?? .plainText
    }
}

@available(iOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
@available(tvOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
@available(watchOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
@available(visionOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
public struct ObjCGrammar: Grammar {
    public typealias Token = ObjCToken

    public init() {}

    public func tokenize(_ code: String) -> [ObjCToken] {
        resolvedTokens(code).map {
            ObjCToken(text: $0.text, range: $0.range, styleKind: $0.styleKind)
        }
    }

    func resolvedTokens(_ code: String) -> [ObjCResolvedToken] {
        guard code.isEmpty == false else { return [] }

        let fallbackTokens = fallbackResolvedTokens(code)
        guard let semanticTokens = semanticClassifications(in: code) else {
            return fallbackTokens
        }

        return mergeSemanticTokens(semanticTokens, fallbackTokens: fallbackTokens, in: code)
    }

    private func semanticClassifications(in code: String) -> [(token: ObjCSemanticToken, classification: ObjCSemanticClassification)]? {
        let semanticTokens = ObjCSemanticTokenProvider.semanticTokens(for: code)
        guard let semanticTokens else { return nil }

        return semanticTokens.compactMap { token in
            guard let classification = ObjCSemanticClassifier.classify(token) else {
                return nil
            }

            return (token: token, classification: classification)
        }
    }

    private func mergeSemanticTokens(
        _ semanticTokens: [(token: ObjCSemanticToken, classification: ObjCSemanticClassification)],
        fallbackTokens: [ObjCResolvedToken],
        in source: String
    ) -> [ObjCResolvedToken] {
        guard semanticTokens.isEmpty == false else {
            return fallbackTokens
        }

        let utf16Length = source.utf16.count
        let boundaries = Set(
            [0, utf16Length] +
            semanticTokens.flatMap { [$0.token.range.location, NSMaxRange($0.token.range)] } +
            fallbackTokens.flatMap { [$0.range.location, NSMaxRange($0.range)] }
        )
        .sorted()

        var tokens: [ObjCResolvedToken] = []
        for index in 0..<(boundaries.count - 1) {
            let lower = boundaries[index]
            let upper = boundaries[index + 1]
            guard lower < upper else { continue }

            let range = NSRange(location: lower, length: upper - lower)
            guard let stringRange = Range(range, in: source) else { continue }

            let semanticToken = semanticTokens.first { ObjCParserConfiguration.contains($0.token.range, interval: range) }
            let fallbackToken = fallbackTokens.first { ObjCParserConfiguration.contains($0.range, interval: range) }
            let resolvedKind = preferredResolvedKind(semantic: semanticToken, fallback: fallbackToken, in: source)

            let token = ObjCResolvedToken(
                text: String(source[stringRange]),
                range: range,
                lexicalKind: fallbackToken?.lexicalKind,
                resolvedKind: resolvedKind
            )

            if var last = tokens.last, last.styleKind == token.styleKind, NSMaxRange(last.range) == token.range.location {
                tokens.removeLast()
                last = ObjCResolvedToken(
                    text: last.text + token.text,
                    range: NSRange(location: last.range.location, length: last.range.length + token.range.length),
                    lexicalKind: last.lexicalKind ?? token.lexicalKind,
                    resolvedKind: last.resolvedKind ?? token.resolvedKind
                )
                tokens.append(last)
            } else {
                tokens.append(token)
            }
        }

        return tokens
    }

    private func preferredResolvedKind(
        semantic: (token: ObjCSemanticToken, classification: ObjCSemanticClassification)?,
        fallback: ObjCResolvedToken?,
        in source: String
    ) -> ObjCResolvedKind? {
        if let bucket = preferredVisualBucket(semantic: semantic, fallback: fallback, in: source) {
            return bucket.resolvedKind
        }
        return fallback?.resolvedKind
    }

    private func preferredVisualBucket(
        semantic: (token: ObjCSemanticToken, classification: ObjCSemanticClassification)?,
        fallback: ObjCResolvedToken?,
        in source: String
    ) -> ObjCXcodeVisualBucket? {
        if let fallback, fallback.resolvedKind == .plain {
            return .implementationTypeName
        }

        if let semantic {
            if let overridden = overriddenVisualBucket(
                for: semantic.token,
                classification: semantic.classification,
                fallback: fallback,
                in: source
            ) {
                return overridden
            }

            switch semantic.classification.rawKind {
            case .macro:
                return .macro
            case .keyword:
                return .keyword
            case .comment:
                return .comment
            case .documentationComment:
                return .documentationComment
            case .string:
                return .string
            case .number:
                return .number
            case .className, .interfaceName, .structName:
                return semantic.classification.modifiers.contains("declaration") || semantic.classification.modifiers.contains("definition")
                    ? .interfaceTypeDeclaration
                    : .typeReference
            case .typeName:
                return semantic.classification.modifiers.contains("declaration") || semantic.classification.modifiers.contains("definition")
                    ? .typedefTypeDeclaration
                    : .typeReference
            case .enumName:
                return semantic.classification.modifiers.contains("declaration") || semantic.classification.modifiers.contains("definition")
                    ? .typedefTypeDeclaration
                    : .typeReference
            case .functionName, .methodName:
                return semantic.classification.modifiers.contains("declaration") || semantic.classification.modifiers.contains("definition")
                    ? .otherDeclaration
                    : .methodCall
            case .parameterName:
                if fallback?.resolvedKind == .propertyName {
                    return .propertyName
                }
                return .variableLikeName
            case .propertyName:
                return .propertyName
            case .variableName:
                if semantic.classification.modifiers.contains("readonly"),
                   semantic.classification.modifiers.contains("globalScope") || semantic.classification.modifiers.contains("fileScope") {
                    return .globalReadonlyConstant
                }
                return .variableLikeName
            case .enumMember:
                return .enumMember
            }
        }

        if let fallback {
            switch fallback.resolvedKind {
            case nil:
                return .plain
            case .plain:
                return .plain
            case .macro:
                return .macro
            case .keyword:
                return .keyword
            case .preprocessor:
                return .preprocessor
            case .comment:
                return .comment
            case .documentationComment:
                return .documentationComment
            case .string:
                return .string
            case .number:
                return .number
            case .typeDeclaration:
                return .interfaceTypeDeclaration
            case .typeReference:
                return .typeReference
            case .methodDeclaration:
                return .otherDeclaration
            case .methodCall:
                return .methodCall
            case .parameterName, .variableName, .otherName:
                return .variableLikeName
            case .propertyName:
                return .propertyName
            case .enumType:
                return .typedefTypeDeclaration
            case .enumMember:
                return .enumMember
            case .globalReadonlyConstant:
                return .globalReadonlyConstant
            case .attribute:
                return .attribute
            }
        }

        return nil
    }

    private func overriddenVisualBucket(
        for token: ObjCSemanticToken,
        classification: ObjCSemanticClassification,
        fallback: ObjCResolvedToken?,
        in source: String
    ) -> ObjCXcodeVisualBucket? {
        if classification.rawKind == .macro,
           ObjCParserConfiguration.literalLikeMacroIdentifiers.contains(token.text) {
            if ObjCParserConfiguration.isInPreprocessorDirective(token.range, in: source) {
                return .preprocessor
            }

            if fallback?.resolvedKind != .preprocessor {
                return .keyword
            }
        }

        if ObjCParserConfiguration.keywordBuiltinTypeIdentifiers.contains(token.text),
           isTypeLike(semanticRawKind: classification.rawKind, fallback: fallback) {
            return .keywordBuiltinType
        }

        if ObjCParserConfiguration.sdkTypedefTypeIdentifiers.contains(token.text),
           isTypeLike(semanticRawKind: classification.rawKind, fallback: fallback) {
            return .typeReference
        }

        return nil
    }

    private func isTypeLike(semanticRawKind: ObjCRawSemanticKind, fallback: ObjCResolvedToken?) -> Bool {
        switch semanticRawKind {
        case .className, .interfaceName, .structName, .typeName, .enumName:
            return true
        default:
            return fallback?.resolvedKind == .typeReference || fallback?.resolvedKind == .keyword
        }
    }

    private func fallbackResolvedTokens(_ code: String) -> [ObjCResolvedToken] {
        let parser = Parser()
        do {
            try parser.setLanguage(ObjCParserConfiguration.language)
        } catch {
            return [ObjCResolvedToken(
                text: code,
                range: NSRange(location: 0, length: code.utf16.count),
                lexicalKind: nil,
                resolvedKind: nil
            )]
        }

        guard let tree = parser.parse(code) else {
            return [ObjCResolvedToken(
                text: code,
                range: NSRange(location: 0, length: code.utf16.count),
                lexicalKind: nil,
                resolvedKind: nil
            )]
        }

        var captures = ObjCParserConfiguration.query
            .execute(in: tree)
            .resolve(with: .init(string: code))
            .flatMap(\.captures)
            .sorted()
            .compactMap { capture -> ResolvedCapture? in
                guard let lexicalKind = ObjCParserConfiguration.lexicalKind(for: capture) else {
                    return nil
                }
                guard let resolvedKind = ObjCParserConfiguration.resolvedKind(for: capture, lexicalKind: lexicalKind, in: code) else {
                    return nil
                }

                return ResolvedCapture(
                    range: capture.range,
                    lexicalKind: lexicalKind,
                    resolvedKind: resolvedKind,
                    priority: ObjCParserConfiguration.capturePriority(for: resolvedKind)
                )
            }

        captures.append(contentsOf: ObjCParserConfiguration.syntheticSupplementalCaptures(in: code))

        return ObjCParserConfiguration.tokens(in: code, resolvedCaptures: captures)
    }
}

private struct ResolvedCapture {
    let range: NSRange
    let lexicalKind: ObjCLexicalKind
    let resolvedKind: ObjCResolvedKind
    let priority: Int
}

private enum ObjCParserConfiguration {
    static let language: Language = {
        Language(tree_sitter_objc())
    }()

    static let query: Query = {
        do {
            return try Query(language: language, data: Data(ObjCHighlightsQuery.source.utf8))
        } catch {
            fatalError("Failed to build Objective-C tree-sitter query: \(error)")
        }
    }()

    static func lexicalKind(for capture: QueryCapture) -> ObjCLexicalKind? {
        guard let head = capture.nameComponents.first else { return nil }

        switch head {
        case "comment":
            return .comment
        case "string":
            return .string
        case "number":
            return .number
        case "include", "preproc":
            return .preprocessor
        case "keyword", "exception", "storageclass":
            return .keyword
        case "attribute":
            return .attribute
        case "type":
            return .type
        case "namespace":
            return .namespace
        case "method":
            return .method
        case "function":
            return .function
        case "constructor":
            return .constructor
        case "property":
            return .property
        case "variable":
            return .variable
        case "constant":
            return .constant
        case "parameter":
            return .parameter
        default:
            return nil
        }
    }

    static func resolvedKind(for capture: QueryCapture, lexicalKind: ObjCLexicalKind, in source: String) -> ObjCResolvedKind? {
        let text = captureText(in: source, range: capture.range)

        switch lexicalKind {
        case .comment:
            return isDocumentationComment(capture.range, in: source) ? .documentationComment : .comment

        case .string:
            return .string

        case .number:
            return .number

        case .preprocessor:
            return .preprocessor

        case .keyword:
            if capture.nameComponents.contains("function"), text == "+" || text == "-" {
                return nil
            }
            return text.hasPrefix("#") ? .preprocessor : .keyword

        case .attribute:
            return .attribute

        case .namespace:
            return .typeReference

        case .type:
            if isKeywordLikeIdentifier(text) {
                return .keyword
            }
            if capture.nameComponents.dropFirst().first == "declaration", isImplementationTypeDeclarationName(capture.node) {
                return .plain
            }
            if isKeywordBuiltinTypeIdentifier(text) {
                return .keyword
            }
            if isSDKTypedefTypeIdentifier(text) {
                return .typeReference
            }
            if isMacroLikeIdentifier(text, node: capture.node, in: source) {
                return .macro
            }
            if isEnumTypeDefinitionName(capture.node, in: source) {
                return .enumType
            }
            if isTypeDeclarationName(capture, in: source) {
                return .typeDeclaration
            }
            if isTypeReference(capture.node, in: source) || isSupertypeName(capture.node) {
                return .typeReference
            }
            return .otherName

        case .method:
            if isMethodParameterName(capture.node) {
                return .parameterName
            }
            return isDeclaration(capture.node) ? .methodDeclaration : .methodCall

        case .function, .constructor:
            if capture.nameComponents.contains("builtin") || capture.nameComponents.contains("macro") || capture.nameComponents.contains("special") {
                return .keyword
            }
            if isMacroLikeFunctionCapture(capture, text: text, in: source) {
                return .macro
            }
            return isDeclaration(capture.node) ? .methodDeclaration : .methodCall

        case .property:
            if isTypeReference(capture.node, in: source) {
                return .typeReference
            }
            return isPropertyName(capture.node, in: source) ? .propertyName : .variableName

        case .parameter:
            return isTypeReference(capture.node, in: source) ? .typeReference : .parameterName

        case .constant, .variable:
            if isKeywordLikeIdentifier(text) {
                return .keyword
            }
            if literalLikeMacroIdentifiers.contains(text) {
                return isInPreprocessorDirective(capture.node.range, in: source) ? .preprocessor : .keyword
            }
            if isEnumMember(capture.node, in: source) {
                return .enumMember
            }
            if isMacroLikeIdentifier(text, node: capture.node, in: source) {
                return .macro
            }
            if isEnumTypeDefinitionName(capture.node, in: source) {
                return .enumType
            }
            if isTypeDeclarationName(capture, in: source) {
                return .typeDeclaration
            }
            if isTypeReference(capture.node, in: source) || isSupertypeName(capture.node) || (isMessageReceiver(capture.node) && looksLikeTypeName(text)) {
                return .typeReference
            }
            if isGlobalReadonlyConstant(capture.node, in: source) {
                return .globalReadonlyConstant
            }
            if isParameterName(capture.node) {
                return .parameterName
            }
            if matchesEnclosingMethodParameterName(text, node: capture.node, in: source) {
                return .parameterName
            }
            if text.hasPrefix("_") {
                return .propertyName
            }
            if isPropertyName(capture.node, in: source) {
                return .propertyName
            }
            if isMessageReceiver(capture.node) {
                return .otherName
            }
            return .variableName
        }
    }

    static func tokens(in source: String, resolvedCaptures: [ResolvedCapture]) -> [ObjCResolvedToken] {
        let utf16Length = source.utf16.count
        let boundaries = Set([0, utf16Length] + resolvedCaptures.flatMap { [$0.range.location, NSMaxRange($0.range)] })
            .sorted()

        var tokens: [ObjCResolvedToken] = []
        for index in 0..<(boundaries.count - 1) {
            let lower = boundaries[index]
            let upper = boundaries[index + 1]
            guard lower < upper else { continue }

            let range = NSRange(location: lower, length: upper - lower)
            guard let stringRange = Range(range, in: source) else { continue }

            let selectedCapture = resolvedCaptures
                .filter { contains($0.range, interval: range) }
                .max { lhs, rhs in
                    if lhs.priority == rhs.priority {
                        return lhs.range.length > rhs.range.length
                    }
                    return lhs.priority < rhs.priority
                }

            let text = String(source[stringRange])
            let token = ObjCResolvedToken(
                text: text,
                range: range,
                lexicalKind: selectedCapture?.lexicalKind,
                resolvedKind: selectedCapture?.resolvedKind
            )

            if var last = tokens.last, last.styleKind == token.styleKind, NSMaxRange(last.range) == range.location {
                tokens.removeLast()
                last = ObjCResolvedToken(
                    text: last.text + text,
                    range: NSRange(location: last.range.location, length: last.range.length + range.length),
                    lexicalKind: last.lexicalKind ?? token.lexicalKind,
                    resolvedKind: last.resolvedKind ?? token.resolvedKind
                )
                tokens.append(last)
            } else {
                tokens.append(token)
            }
        }

        return tokens
    }

    private static func captureText(in source: String, range: NSRange) -> String {
        guard let stringRange = Range(range, in: source) else { return "" }
        return String(source[stringRange])
    }

    static func syntheticSupplementalCaptures(in source: String) -> [ResolvedCapture] {
        syntheticMacroCaptures(in: source) +
        syntheticNullabilityCaptures(in: source)
    }

    private static func syntheticMacroCaptures(in source: String) -> [ResolvedCapture] {
        let pattern = #"\b[A-Z][A-Z0-9_]+\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

        return regex.matches(in: source, range: NSRange(location: 0, length: (source as NSString).length))
            .compactMap { match -> ResolvedCapture? in
                let text = captureText(in: source, range: match.range)
                guard
                    linePrefixHasHash(match.range, in: source) ||
                    text.hasSuffix("_BEGIN") ||
                    text.hasSuffix("_END") ||
                    text.hasSuffix("_EXPORT") ||
                    text.contains("_ENUM")
                else {
                    return nil
                }

                let resolvedKind: ObjCResolvedKind
                if literalLikeMacroIdentifiers.contains(text),
                   isInPreprocessorDirective(match.range, in: source) {
                    resolvedKind = .preprocessor
                } else {
                    resolvedKind = .macro
                }

                return ResolvedCapture(
                    range: match.range,
                    lexicalKind: .keyword,
                    resolvedKind: resolvedKind,
                    priority: capturePriority(for: resolvedKind) + 10
                )
            }
    }

    private static func syntheticNullabilityCaptures(in source: String) -> [ResolvedCapture] {
        let pattern = #"\b(nullable|nonnull)\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

        return regex.matches(in: source, range: NSRange(location: 0, length: (source as NSString).length)).map { match in
            ResolvedCapture(
                range: match.range,
                lexicalKind: .keyword,
                resolvedKind: .keyword,
                priority: capturePriority(for: .keyword) + 5
            )
        }
    }

    static func contains(_ range: NSRange, interval: NSRange) -> Bool {
        interval.location >= range.location && NSMaxRange(interval) <= NSMaxRange(range)
    }

    private static func isDocumentationComment(_ range: NSRange, in source: String) -> Bool {
        let text = captureText(in: source, range: range).trimmingCharacters(in: .whitespacesAndNewlines)
        return text.hasPrefix("///") || text.hasPrefix("//!") || text.hasPrefix("/**") || text.hasPrefix("/*!")
    }

    private static func isKeywordLikeIdentifier(_ text: String) -> Bool {
        text == "self" || text == "super" || text == "instancetype"
    }

    private static func isKeywordBuiltinTypeIdentifier(_ text: String) -> Bool {
        keywordBuiltinTypeIdentifiers.contains(text)
    }

    private static func isSDKTypedefTypeIdentifier(_ text: String) -> Bool {
        sdkTypedefTypeIdentifiers.contains(text)
    }

    static let keywordBuiltinTypeIdentifiers: Set<String> = [
        "void",
        "id",
        "Class",
        "SEL",
        "IMP",
        "BOOL",
        "instancetype",
    ]

    static let literalLikeMacroIdentifiers: Set<String> = [
        "nil",
        "Nil",
        "NULL",
        "YES",
        "NO",
    ]

    static let sdkTypedefTypeIdentifiers: Set<String> = [
        "NSInteger",
        "NSUInteger",
        "CGFloat",
        "NSTimeInterval",
        "NSErrorDomain",
    ]

    static func capturePriority(for resolvedKind: ObjCResolvedKind) -> Int {
        switch resolvedKind {
        case .plain:
            return 65
        case .documentationComment:
            return 95
        case .comment:
            return 90
        case .string, .number:
            return 80
        case .preprocessor, .macro, .keyword, .attribute:
            return 75
        case .typeDeclaration, .enumType:
            return 60
        case .methodDeclaration:
            return 50
        case .methodCall:
            return 45
        case .typeReference:
            return 40
        case .parameterName:
            return 39
        case .propertyName:
            return 38
        case .enumMember, .globalReadonlyConstant:
            return 37
        case .variableName:
            return 30
        case .otherName:
            return 20
        }
    }

    private static func isDeclaration(_ node: Node) -> Bool {
        hasAncestor(node, matching: [
            "message_expression",
            "call_expression",
        ], stoppingAtFirstMatchIn: [
            "method_definition",
            "method_declaration",
            "function_definition",
            "function_declarator",
        ]) == .declaration
    }

    private static func isParameterName(_ node: Node) -> Bool {
        isMethodParameterName(node) || hasAncestor(node, matching: ["method_parameter", "parameter_declaration"])
    }

    private static func isMethodParameterName(_ node: Node) -> Bool {
        guard node.parent?.nodeType == "keyword_declarator" else {
            return false
        }
        return node.previousNamedSibling != nil
    }

    private static func isPropertyName(_ node: Node, in source: String) -> Bool {
        guard hasAncestor(node, matching: ["property_declaration", "property_implementation"]) else {
            return false
        }

        return isTypeReference(node, in: source) == false
    }

    private static func isTypeDeclarationName(_ capture: QueryCapture, in source: String) -> Bool {
        if capture.nameComponents.dropFirst().first == "declaration" {
            return true
        }
        return isTypeDefinitionName(capture.node, in: source)
    }

    private static func isImplementationTypeDeclarationName(_ node: Node) -> Bool {
        hasAncestor(node, matching: ["class_implementation"])
    }

    private static func isTypeDefinitionName(_ node: Node, in source: String) -> Bool {
        guard hasAncestor(node, matching: ["type_definition"]) else {
            return false
        }
        return isTypeReference(node, in: source) == false &&
            isEnumMember(node, in: source) == false &&
            isPropertyName(node, in: source) == false &&
            isParameterName(node) == false &&
            isMacroLikeIdentifier(captureText(in: source, range: node.range), node: node, in: source) == false
    }

    private static func isEnumTypeDefinitionName(_ node: Node, in source: String) -> Bool {
        guard hasAncestor(node, matching: ["type_definition"]) else {
            return false
        }
        let line = lineText(node.range, in: source)
        let prefix = linePrefix(node.range, in: source)
        return (line.contains("NS_ENUM") || line.contains("NS_ERROR_ENUM") || line.contains("enum")) &&
            prefix.contains(",")
    }

    private static func isEnumMember(_ node: Node, in source: String) -> Bool {
        hasAncestor(node, matching: ["enumerator", "enumerator_list"]) ||
            ((hasAncestor(node, matching: ["enum_specifier"]) || hasAncestor(node, matching: ["type_definition"])) &&
                lineContainsAssignment(node.range, in: source))
    }

    private static func isGlobalReadonlyConstant(_ node: Node, in source: String) -> Bool {
        guard
            hasAncestor(node, matching: ["declaration"]),
            hasAncestor(node, matching: ["method_definition", "method_declaration", "function_definition"]) == false
        else {
            return false
        }

        let line = lineText(node.range, in: source)
        let prefix = linePrefix(node.range, in: source)
        return (line.contains(" const ") || line.contains("FOUNDATION_EXPORT")) && prefix.contains("const")
    }

    private static func isMacroLikeFunctionCapture(_ capture: QueryCapture, text: String, in source: String) -> Bool {
        return isMacroLikeIdentifier(text, node: capture.node, in: source)
    }

    private static func isMacroLikeIdentifier(_ text: String, node: Node, in source: String) -> Bool {
        guard text.range(of: #"^[A-Z][A-Z0-9_]+$"#, options: .regularExpression) != nil else {
            return false
        }

        if linePrefixHasHash(node.range, in: source) || text.hasSuffix("_BEGIN") || text.hasSuffix("_END") || text.hasSuffix("_EXPORT") || text.contains("_ENUM") {
            return true
        }

        if isEnumMember(node, in: source) || isTypeDefinitionName(node, in: source) || isTypeReference(node, in: source) || isPropertyName(node, in: source) || isParameterName(node) {
            return false
        }

        if isCallExpressionFunction(node) {
            return true
        }

        if hasAncestor(node, matching: ["declaration", "type_definition", "preproc_call", "preproc_function_def"]) {
            return true
        }

        return node.parent?.nodeType == "translation_unit"
    }

    private static func isCallExpressionFunction(_ node: Node) -> Bool {
        guard
            let call = nearestAncestor(of: node, matching: ["call_expression"]),
            let function = call.child(byFieldName: "function")
        else {
            return false
        }

        return contains(function.range, interval: node.range)
    }

    private static func isTypeReference(_ node: Node, in source: String) -> Bool {
        if hasAncestor(node, matching: [
            "method_type",
            "type_name",
            "parameterized_arguments",
            "protocol_reference_list",
            "type_cast_expression",
            "sizeof_expression",
            "encode_expression",
            "generic_specifier",
        ]) {
            return true
        }

        return isDeclarationTypeReference(node) || isStructDeclarationTypeReference(node) || isAtomicDeclarationTypeReference(node)
    }

    private static func isDeclarationTypeReference(_ node: Node) -> Bool {
        guard hasAncestor(node, matching: ["declaration", "parameter_declaration"]) else {
            return false
        }

        return hasAncestor(node, matching: [
            "init_declarator",
            "function_declarator",
            "pointer_declarator",
            "array_declarator",
            "parenthesized_declarator",
            "block_pointer_declarator",
            "keyword_declarator",
        ]) == false
    }

    private static func isStructDeclarationTypeReference(_ node: Node) -> Bool {
        guard hasAncestor(node, matching: ["struct_declaration"]) else {
            return false
        }

        return hasAncestor(node, matching: ["struct_declarator"]) == false
    }

    private static func isAtomicDeclarationTypeReference(_ node: Node) -> Bool {
        guard let declaration = nearestAncestor(of: node, matching: ["atomic_declaration"]) else {
            return false
        }

        for index in 0..<declaration.childCount {
            guard declaration.fieldNameForChild(at: index) == "type", let child = declaration.child(at: index) else {
                continue
            }
            return contains(child.range, interval: node.range)
        }

        return false
    }

    private static func isSupertypeName(_ node: Node) -> Bool {
        guard
            let ancestor = nearestAncestor(of: node, matching: ["class_interface", "class_implementation"]),
            let superclass = ancestor.child(byFieldName: "superclass")
        else {
            return false
        }

        return contains(superclass.range, interval: node.range)
    }

    private static func isMessageReceiver(_ node: Node) -> Bool {
        guard
            let message = nearestAncestor(of: node, matching: ["message_expression"]),
            let receiver = message.child(byFieldName: "receiver")
        else {
            return false
        }

        return contains(receiver.range, interval: node.range)
    }

    private enum AncestorClassification {
        case declaration
        case invocation
        case none
    }

    private static func hasAncestor(_ node: Node, matching types: Set<String>) -> Bool {
        nearestAncestor(of: node, matching: types) != nil
    }

    private static func hasAncestor(_ node: Node, matching invocationTypes: Set<String>, stoppingAtFirstMatchIn declarationTypes: Set<String>) -> AncestorClassification {
        var current: Node? = node
        while let candidate = current {
            if let nodeType = candidate.nodeType {
                if invocationTypes.contains(nodeType) {
                    return .invocation
                }
                if declarationTypes.contains(nodeType) {
                    return .declaration
                }
            }
            current = candidate.parent
        }
        return .none
    }

    private static func nearestAncestor(of node: Node, matching types: Set<String>) -> Node? {
        var current: Node? = node
        while let candidate = current {
            if let nodeType = candidate.nodeType, types.contains(nodeType) {
                return candidate
            }
            current = candidate.parent
        }
        return nil
    }

    static func linePrefixHasHash(_ range: NSRange, in source: String) -> Bool {
        let string = source as NSString
        let lineRange = string.lineRange(for: range)
        let prefixLength = max(0, range.location - lineRange.location)
        let prefix = string.substring(with: NSRange(location: lineRange.location, length: prefixLength))
            .trimmingCharacters(in: .whitespaces)
        return prefix.hasPrefix("#")
    }

    static func isInPreprocessorDirective(_ range: NSRange, in source: String) -> Bool {
        let string = source as NSString
        var directiveStartRange = string.lineRange(for: range)

        while directiveStartRange.location > 0 {
            let previousLineProbe = NSRange(location: directiveStartRange.location - 1, length: 0)
            let previousLineRange = string.lineRange(for: previousLineProbe)
            let previousLine = string.substring(with: previousLineRange)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard previousLine.hasSuffix("\\") else {
                break
            }

            directiveStartRange = previousLineRange
        }

        let directiveStartLine = string.substring(with: directiveStartRange)
            .trimmingCharacters(in: .whitespaces)
        return directiveStartLine.hasPrefix("#")
    }

    private static func looksLikeTypeName(_ text: String) -> Bool {
        guard let first = text.first else { return false }
        return first.isUppercase
    }

    private static func matchesEnclosingMethodParameterName(_ text: String, node: Node, in source: String) -> Bool {
        guard let method = nearestAncestor(of: node, matching: ["method_definition", "method_declaration"]) else {
            return false
        }

        let methodText = captureText(in: source, range: method.range)
        guard let regex = try? NSRegularExpression(pattern: #":\s*\([^)]*\)\s*([A-Za-z_][A-Za-z0-9_]*)"#) else {
            return false
        }

        let range = NSRange(location: 0, length: (methodText as NSString).length)
        return regex.matches(in: methodText, range: range).contains {
            guard $0.numberOfRanges > 1 else { return false }
            let candidate = (methodText as NSString).substring(with: $0.range(at: 1))
            return candidate == text
        }
    }

    private static func lineContainsAssignment(_ range: NSRange, in source: String) -> Bool {
        lineText(range, in: source).contains("=")
    }

    private static func lineText(_ range: NSRange, in source: String) -> String {
        let string = source as NSString
        let lineRange = string.lineRange(for: range)
        return string.substring(with: lineRange)
    }

    private static func linePrefix(_ range: NSRange, in source: String) -> String {
        let string = source as NSString
        let lineRange = string.lineRange(for: range)
        let prefixLength = max(0, range.location - lineRange.location)
        return string.substring(with: NSRange(location: lineRange.location, length: prefixLength))
    }
}
