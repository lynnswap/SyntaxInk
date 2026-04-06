import Foundation
import SyntaxInk

@available(iOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
@available(tvOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
@available(watchOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
@available(visionOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
public struct ObjCToken: Sendable {
    public let text: String
    public let range: NSRange
    public let styleKind: ObjCTheme.StyleKind
}

@available(iOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
@available(tvOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
@available(watchOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
@available(visionOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
public struct ObjCGrammar: Grammar {
    public typealias Token = ObjCToken

    private let highlightRules: [any ObjCHighlightRule]

    public init() {
        self.highlightRules = [
            ObjCImplementationTypeNameHighlightRule(),
            ObjCSemanticIntrinsicHighlightRule(),
            ObjCLocalReferenceHighlightRule(),
            ObjCSemanticReferenceHighlightRule(),
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
        let semanticMatches = semanticClassifications(in: code) ?? []
        let localSymbols = ObjCLocalSymbolIndex(
            semanticMatches: semanticMatches,
            fallbackTokens: fallbackTokens
        )

        return mergeTokens(
            semanticMatches,
            fallbackTokens: fallbackTokens,
            localSymbols: localSymbols,
            in: code
        )
    }

    private func semanticClassifications(in code: String) -> [ObjCSemanticMatch]? {
        guard let semanticTokens = ObjCSemanticTokenProvider.semanticTokens(for: code) else {
            return nil
        }

        return semanticTokens.compactMap { token in
            guard let classification = ObjCSemanticClassifier.classify(token) else {
                return nil
            }
            return ObjCSemanticMatch(token: token, classification: classification)
        }
    }

    private func mergeTokens(
        _ semanticMatches: [ObjCSemanticMatch],
        fallbackTokens: [ObjCResolvedToken],
        localSymbols: ObjCLocalSymbolIndex,
        in source: String
    ) -> [ObjCResolvedToken] {
        let utf16Length = source.utf16.count
        let boundaries = Set(
            [0, utf16Length] +
            semanticMatches.flatMap { [$0.token.range.location, NSMaxRange($0.token.range)] } +
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

            let semantic = semanticMatches.first { ObjCFallbackCaptureRule.contains($0.token.range, interval: range) }
            let fallback = fallbackTokens.first { ObjCFallbackCaptureRule.contains($0.range, interval: range) }
            let context = ObjCHighlightingContext(
                source: source,
                text: String(source[stringRange]),
                range: range,
                semantic: semantic,
                fallback: fallback,
                localSymbols: localSymbols
            )
            let resolution = highlightRules.lazy
                .compactMap { $0.resolve(context) }
                .first

            let token = ObjCResolvedToken(
                text: context.text,
                range: range,
                lexicalKind: fallback?.lexicalKind,
                resolvedKind: resolution?.resolvedKind ?? fallback?.resolvedKind,
                origin: resolution?.origin ?? fallback?.origin,
                referenceStyleKind: resolution?.referenceStyleKind ?? fallback?.referenceStyleKind,
                callableScope: fallback?.callableScope,
                receiverHint: fallback?.receiverHint,
                isForwardClassDeclaration: fallback?.isForwardClassDeclaration ?? false
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
