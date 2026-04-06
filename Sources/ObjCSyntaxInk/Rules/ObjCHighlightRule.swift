import Foundation

protocol ObjCHighlightRule: Sendable {
    func resolve(_ context: ObjCHighlightingContext) -> ObjCTokenResolution?
}

struct ObjCTokenResolution: Sendable {
    let resolvedKind: ObjCResolvedKind?
    let origin: ObjCSymbolOrigin?
    let referenceStyleKind: ObjCReferenceStyleKind?
}

struct ObjCHighlightingContext: Sendable {
    let source: String
    let text: String
    let range: NSRange
    let semantic: ObjCSemanticMatch?
    let fallback: ObjCResolvedToken?
    let localSymbols: ObjCLocalSymbolIndex

    var semanticResolution: ObjCTokenResolution? {
        guard let semantic else { return nil }
        if let overridden = overriddenSemanticResolution(for: semantic) {
            return overridden
        }

        switch semantic.classification.rawKind {
        case .macro:
            return .init(resolvedKind: .macro, origin: semanticReferenceOrigin(for: semantic), referenceStyleKind: nil)
        case .keyword:
            return .init(resolvedKind: .keyword, origin: nil, referenceStyleKind: nil)
        case .comment:
            return .init(resolvedKind: .comment, origin: nil, referenceStyleKind: nil)
        case .documentationComment:
            return .init(resolvedKind: .documentationComment, origin: nil, referenceStyleKind: nil)
        case .string:
            return .init(resolvedKind: .string, origin: nil, referenceStyleKind: nil)
        case .number:
            return .init(resolvedKind: .number, origin: nil, referenceStyleKind: nil)
        case .className, .interfaceName, .structName:
            return typeResolution(for: semantic, referenceStyleKind: .className)
        case .typeName, .enumName:
            return typeResolution(for: semantic, referenceStyleKind: .typeName)
        case .functionName, .methodName:
            if semantic.isDeclarationLike {
                return .init(resolvedKind: .methodDeclaration, origin: .project, referenceStyleKind: .callable)
            }
            return .init(resolvedKind: .methodCall, origin: semanticReferenceOrigin(for: semantic), referenceStyleKind: .callable)
        case .parameterName:
            if fallback?.resolvedKind == .propertyName {
                return .init(resolvedKind: .propertyName, origin: nil, referenceStyleKind: nil)
            }
            return .init(resolvedKind: .parameterName, origin: nil, referenceStyleKind: nil)
        case .propertyName:
            return .init(resolvedKind: .propertyName, origin: nil, referenceStyleKind: nil)
        case .variableName:
            if semantic.classification.modifiers.contains("readonly"),
               semantic.classification.modifiers.contains("globalScope") || semantic.classification.modifiers.contains("fileScope") {
                return .init(resolvedKind: .globalReadonlyConstant, origin: nil, referenceStyleKind: nil)
            }
            return .init(resolvedKind: .variableName, origin: nil, referenceStyleKind: nil)
        case .enumMember:
            return .init(resolvedKind: .enumMember, origin: nil, referenceStyleKind: nil)
        }
    }

    func matchesLocalReference(for resolution: ObjCTokenResolution) -> Bool {
        guard resolution.origin != .system else { return false }

        switch resolution.resolvedKind {
        case .typeReference:
            return localSymbols.containsType(named: text)
        case .methodCall:
            guard isCallableReference else { return false }

            switch fallback?.receiverHint {
            case .self:
                return localSymbols.containsCallable(named: text, receiverHint: .self)
            case .typeName(let receiverType):
                return localSymbols.containsType(named: receiverType) &&
                    localSymbols.containsCallable(named: text, receiverHint: .typeName(receiverType))
            case .super:
                return false
            case .other:
                return false
            case nil:
                return localSymbols.containsCallable(named: text, receiverHint: nil)
            }
        default:
            return false
        }
    }

    private var isCallableReference: Bool {
        if let semantic {
            switch semantic.classification.rawKind {
            case .functionName:
                return true
            case .methodName:
                return fallback?.receiverHint != nil
            default:
                break
            }
        }
        return fallback?.lexicalKind == .function ||
            fallback?.lexicalKind == .constructor ||
            fallback?.lexicalKind == .method
    }

    private func typeResolution(for semantic: ObjCSemanticMatch, referenceStyleKind: ObjCReferenceStyleKind) -> ObjCTokenResolution {
        if semantic.isDeclarationLike {
            if referenceStyleKind == .className, semantic.classification.modifiers.contains("definition") == false {
                let origin: ObjCSymbolOrigin?
                if fallback?.isForwardClassDeclaration == true {
                    origin = semanticReferenceOrigin(for: semantic)
                } else {
                    origin = semanticReferenceOrigin(for: semantic) ?? .project
                }
                return .init(
                    resolvedKind: .typeReference,
                    origin: origin,
                    referenceStyleKind: referenceStyleKind
                )
            }
            return .init(resolvedKind: .typeDeclaration, origin: .project, referenceStyleKind: referenceStyleKind)
        }
        return .init(
            resolvedKind: .typeReference,
            origin: semanticReferenceOrigin(for: semantic),
            referenceStyleKind: referenceStyleKind
        )
    }

    private func semanticReferenceOrigin(for semantic: ObjCSemanticMatch) -> ObjCSymbolOrigin? {
        semantic.classification.modifiers.contains("defaultLibrary") ? .system : nil
    }

    private func overriddenSemanticResolution(for semantic: ObjCSemanticMatch) -> ObjCTokenResolution? {
        if semantic.classification.rawKind == .macro,
           ObjCFallbackCaptureRule.literalLikeMacroIdentifiers.contains(semantic.token.text) {
            if ObjCFallbackCaptureRule.isInPreprocessorDirective(semantic.token.range, in: source) {
                return .init(resolvedKind: .preprocessor, origin: nil, referenceStyleKind: nil)
            }

            if fallback?.resolvedKind != .preprocessor {
                return .init(resolvedKind: .keyword, origin: nil, referenceStyleKind: nil)
            }
        }

        if ObjCFallbackCaptureRule.keywordBuiltinTypeIdentifiers.contains(semantic.token.text),
           isTypeLike(semanticRawKind: semantic.classification.rawKind) {
            return .init(resolvedKind: .keyword, origin: nil, referenceStyleKind: nil)
        }

        if ObjCFallbackCaptureRule.sdkTypedefTypeIdentifiers.contains(semantic.token.text),
           isTypeLike(semanticRawKind: semantic.classification.rawKind) {
            return .init(
                resolvedKind: .typeReference,
                origin: semanticReferenceOrigin(for: semantic),
                referenceStyleKind: .typeName
            )
        }

        return nil
    }

    private func isTypeLike(semanticRawKind: ObjCRawSemanticKind) -> Bool {
        switch semanticRawKind {
        case .className, .interfaceName, .structName, .typeName, .enumName:
            return true
        default:
            return fallback?.resolvedKind == .typeReference || fallback?.resolvedKind == .keyword
        }
    }
}

private extension ObjCSemanticMatch {
    var isDeclarationLike: Bool {
        classification.modifiers.contains("declaration") || classification.modifiers.contains("definition")
    }
}

private extension ObjCResolvedToken {
    var resolution: ObjCTokenResolution {
        .init(
            resolvedKind: resolvedKind,
            origin: origin,
            referenceStyleKind: referenceStyleKind
        )
    }
}

struct ObjCImplementationTypeNameHighlightRule: ObjCHighlightRule {
    func resolve(_ context: ObjCHighlightingContext) -> ObjCTokenResolution? {
        guard context.fallback?.resolvedKind == .plain else { return nil }
        return context.fallback?.resolution
    }
}

struct ObjCSemanticIntrinsicHighlightRule: ObjCHighlightRule {
    func resolve(_ context: ObjCHighlightingContext) -> ObjCTokenResolution? {
        guard let resolution = context.semanticResolution else { return nil }

        switch resolution.resolvedKind {
        case .typeReference, .methodCall:
            return resolution.origin == .system ? resolution : nil
        default:
            return resolution
        }
    }
}

struct ObjCLocalReferenceHighlightRule: ObjCHighlightRule {
    func resolve(_ context: ObjCHighlightingContext) -> ObjCTokenResolution? {
        let resolution = context.semanticResolution ?? context.fallback?.resolution
        guard let resolution, context.matchesLocalReference(for: resolution) else {
            return nil
        }

        return .init(
            resolvedKind: resolution.resolvedKind,
            origin: .project,
            referenceStyleKind: resolution.referenceStyleKind
        )
    }
}

struct ObjCSemanticReferenceHighlightRule: ObjCHighlightRule {
    func resolve(_ context: ObjCHighlightingContext) -> ObjCTokenResolution? {
        guard let resolution = context.semanticResolution else { return nil }

        switch resolution.resolvedKind {
        case .typeReference, .methodCall:
            guard resolution.origin != .system else { return nil }
            return .init(
                resolvedKind: resolution.resolvedKind,
                origin: resolution.origin ?? .external,
                referenceStyleKind: resolution.referenceStyleKind
            )
        default:
            return nil
        }
    }
}

struct ObjCFallbackHighlightRule: ObjCHighlightRule {
    func resolve(_ context: ObjCHighlightingContext) -> ObjCTokenResolution? {
        guard let fallback = context.fallback else { return nil }
        var resolution = fallback.resolution

        switch resolution.resolvedKind {
        case .typeReference, .methodCall:
            if context.matchesLocalReference(for: resolution) {
                resolution = .init(
                    resolvedKind: resolution.resolvedKind,
                    origin: .project,
                    referenceStyleKind: resolution.referenceStyleKind
                )
            } else if resolution.origin == nil {
                resolution = .init(
                    resolvedKind: resolution.resolvedKind,
                    origin: .external,
                    referenceStyleKind: resolution.referenceStyleKind
                )
            }
        default:
            break
        }

        return resolution
    }
}
