import Foundation

struct ObjCSemanticToken: Sendable {
    let text: String
    let range: NSRange
    let tokenType: String
    let tokenModifiers: Set<String>
}

struct ObjCSemanticClassification: Sendable, Equatable {
    let rawKind: ObjCRawSemanticKind
    let modifiers: Set<String>
}

enum ObjCRawSemanticKind: Sendable, Equatable {
    case macro
    case keyword
    case comment
    case documentationComment
    case string
    case number
    case className
    case interfaceName
    case structName
    case typeName
    case enumName
    case functionName
    case methodName
    case parameterName
    case propertyName
    case variableName
    case enumMember
}

enum ObjCFileKind: String, Sendable {
    case header = "SemanticInput.h"
    case implementation = "SemanticInput.m"

    static func infer(from source: String) -> Self {
        source.contains("@implementation") ? .implementation : .header
    }

    var clangLanguage: String {
        switch self {
        case .header:
            return "objective-c-header"
        case .implementation:
            return "objective-c"
        }
    }
}

enum ObjCSemanticClassifier {
    static func classify(_ token: ObjCSemanticToken) -> ObjCSemanticClassification? {
        let modifiers = token.tokenModifiers

        // Xcode internals expose distinct buckets like `xcode.syntax.typedef`,
        // `xcode.syntax.name.type`, `xcode.syntax.name.other`, `xcode.syntax.keyword`,
        // and `xcode.syntax.identifier.type(.system)`. This layer intentionally keeps
        // only the raw semantic token kind/modifiers. Visual bucket decisions belong
        // to the ObjCGrammar stage.
        let rawKind: ObjCRawSemanticKind
        switch token.tokenType {
        case "macro":
            rawKind = .macro
        case "keyword", "modifier":
            rawKind = .keyword
        case "comment":
            rawKind = modifiers.contains("documentation") ? .documentationComment : .comment
        case "string":
            rawKind = .string
        case "number":
            rawKind = .number
        case "class":
            rawKind = .className
        case "interface":
            rawKind = .interfaceName
        case "struct":
            rawKind = .structName
        case "type":
            rawKind = .typeName
        case "enum":
            rawKind = .enumName
        case "function":
            rawKind = .functionName
        case "method":
            rawKind = .methodName
        case "parameter":
            rawKind = .parameterName
        case "property":
            rawKind = .propertyName
        case "variable":
            rawKind = .variableName
        case "enumMember":
            rawKind = .enumMember
        default:
            return nil
        }

        return ObjCSemanticClassification(rawKind: rawKind, modifiers: modifiers)
    }
}
