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
    let fallback: ObjCResolvedToken?
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

struct ObjCFallbackHighlightRule: ObjCHighlightRule {
    func resolve(_ context: ObjCHighlightingContext) -> ObjCTokenResolution? {
        guard let fallback = context.fallback else { return nil }
        var resolution = fallback.resolution

        switch resolution.resolvedKind {
        case .typeReference, .methodCall:
            if resolution.origin == nil {
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
