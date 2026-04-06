import Foundation
import SyntaxInk

public struct ObjCToken: Sendable {
    public let text: String
    public let range: NSRange
    public let styleKind: ObjCTheme.StyleKind
}

public struct ObjCGrammar: Grammar {
    public typealias Token = ObjCToken

    private let highlightRules: [any ObjCHighlightRule]

    public init() {
        self.highlightRules = [
            ObjCImplementationTypeNameHighlightRule(),
            ObjCFallbackHighlightRule(),
        ]
    }

    public func tokenize(_ code: String) -> [ObjCToken] {
        resolvedTokens(code).map {
            ObjCToken(text: $0.text, range: $0.range, styleKind: $0.styleKind)
        }
    }

    func resolvedTokens(_ code: String) -> [ObjCResolvedToken] {
        guard code.isEmpty == false else { return [] }

        let fallbackTokens = ObjCFallbackCaptureRule.resolvedTokens(in: code)
        return mergeTokens(fallbackTokens, in: code)
    }

    private func mergeTokens(
        _ fallbackTokens: [ObjCResolvedToken],
        in source: String
    ) -> [ObjCResolvedToken] {
        var tokens: [ObjCResolvedToken] = []
        for fallback in fallbackTokens {
            let context = ObjCHighlightingContext(
                source: source,
                text: fallback.text,
                range: fallback.range,
                fallback: fallback
            )
            let resolution = highlightRules.lazy
                .compactMap { $0.resolve(context) }
                .first

            let token = ObjCResolvedToken(
                text: context.text,
                range: context.range,
                lexicalKind: fallback.lexicalKind,
                resolvedKind: resolution?.resolvedKind ?? fallback.resolvedKind,
                origin: resolution?.origin ?? fallback.origin,
                referenceStyleKind: resolution?.referenceStyleKind ?? fallback.referenceStyleKind,
                callableScope: fallback.callableScope,
                receiverHint: fallback.receiverHint,
                isForwardClassDeclaration: fallback.isForwardClassDeclaration
            )

            if var last = tokens.last, last.styleKind == token.styleKind, NSMaxRange(last.range) == token.range.location {
                tokens.removeLast()
                last = ObjCResolvedToken(
                    text: last.text + token.text,
                    range: NSRange(location: last.range.location, length: last.range.length + token.range.length),
                    lexicalKind: last.lexicalKind ?? token.lexicalKind,
                    resolvedKind: last.resolvedKind ?? token.resolvedKind,
                    origin: last.origin ?? token.origin,
                    referenceStyleKind: last.referenceStyleKind ?? token.referenceStyleKind,
                    callableScope: last.callableScope ?? token.callableScope,
                    receiverHint: last.receiverHint ?? token.receiverHint,
                    isForwardClassDeclaration: last.isForwardClassDeclaration || token.isForwardClassDeclaration
                )
                tokens.append(last)
            } else {
                tokens.append(token)
            }
        }

        return tokens
    }
}
