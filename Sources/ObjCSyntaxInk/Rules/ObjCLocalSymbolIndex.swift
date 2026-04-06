import Foundation

enum ObjCSymbolScope: Sendable, Hashable {
    case global
    case `class`
}

private enum ObjCLocalSymbolKind: Sendable, Hashable {
    case type
    case callable
}

private struct ObjCLocalSymbolKey: Sendable, Hashable {
    let kind: ObjCLocalSymbolKind
    let name: String
    let scope: ObjCSymbolScope
}

struct ObjCLocalSymbolIndex: Sendable {
    private let entries: Set<ObjCLocalSymbolKey>

    init(semanticMatches: [ObjCSemanticMatch], fallbackTokens: [ObjCResolvedToken]) {
        var collected: Set<ObjCLocalSymbolKey> = []
        let forwardClassDeclarations = Set(
            fallbackTokens
                .filter(\.isForwardClassDeclaration)
                .map(\.text)
        )

        for match in semanticMatches {
            guard
                Self.isIdentifier(match.token.text),
                Self.isDeclarationLike(match.classification.modifiers),
                match.classification.modifiers.contains("defaultLibrary") == false,
                forwardClassDeclarations.contains(match.token.text) == false
            else {
                continue
            }

            let scope: ObjCSymbolScope = match.classification.modifiers.contains("classScope") ? .class : .global
            switch match.classification.rawKind {
            case .className, .interfaceName, .structName, .typeName, .enumName:
                collected.insert(.init(kind: .type, name: match.token.text, scope: scope))
            case .functionName, .methodName:
                collected.insert(.init(kind: .callable, name: match.token.text, scope: scope))
            default:
                break
            }
        }

        for token in fallbackTokens where Self.isIdentifier(token.text) {
            switch token.resolvedKind {
            case .typeDeclaration, .enumType:
                guard token.isForwardClassDeclaration == false else { continue }
                collected.insert(.init(kind: .type, name: token.text, scope: .global))
            case .methodDeclaration:
                let scope: ObjCSymbolScope
                switch token.callableScope {
                case .global:
                    scope = .global
                case .class:
                    scope = .class
                case nil:
                    scope = token.lexicalKind == .function ? .global : .class
                }
                collected.insert(.init(kind: .callable, name: token.text, scope: scope))
            default:
                break
            }
        }

        self.entries = collected
    }

    func containsType(named name: String) -> Bool {
        entries.contains(.init(kind: .type, name: name, scope: .global)) ||
        entries.contains(.init(kind: .type, name: name, scope: .class))
    }

    func containsCallable(named name: String, receiverHint: ObjCReceiverHint?) -> Bool {
        let candidateScopes: [ObjCSymbolScope]
        switch receiverHint {
        case .self, .typeName:
            candidateScopes = [.class]
        case .super:
            return false
        case .other:
            candidateScopes = []
        case nil:
            candidateScopes = [.global]
        }

        return candidateScopes.contains { scope in
            entries.contains(.init(kind: .callable, name: name, scope: scope))
        }
    }

    private static func isDeclarationLike(_ modifiers: Set<String>) -> Bool {
        modifiers.contains("declaration") || modifiers.contains("definition")
    }

    private static func isIdentifier(_ text: String) -> Bool {
        text.range(of: #"^[A-Za-z_][A-Za-z0-9_]*$"#, options: .regularExpression) != nil
    }
}
