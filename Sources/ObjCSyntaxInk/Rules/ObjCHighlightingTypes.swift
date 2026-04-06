import Foundation

enum ObjCSymbolOrigin: Sendable, Equatable {
    case project
    case external
    case system
}

enum ObjCReferenceStyleKind: Sendable, Equatable {
    case className
    case typeName
    case callable
}

enum ObjCReceiverHint: Sendable, Equatable {
    case `self`
    case `super`
    case typeName(String)
    case other
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

    func styleKind(origin: ObjCSymbolOrigin?, referenceStyleKind: ObjCReferenceStyleKind?) -> ObjCTheme.StyleKind {
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
            switch referenceStyleKind ?? .typeName {
            case .className:
                return origin == .project ? .projectClassNames : .otherClassNames
            case .typeName:
                return origin == .project ? .projectTypeNames : .otherTypeNames
            case .callable:
                return origin == .project ? .projectFunctionAndMethodNames : .otherFunctionAndMethodNames
            }
        case .methodDeclaration:
            return .otherDeclarations
        case .methodCall:
            return origin == .project ? .projectFunctionAndMethodNames : .otherFunctionAndMethodNames
        case .parameterName, .propertyName, .variableName, .enumMember, .globalReadonlyConstant, .otherName:
            return .otherPropertiesAndGlobals
        }
    }
}

struct ObjCResolvedToken: Sendable {
    let text: String
    let range: NSRange
    let lexicalKind: ObjCLexicalKind?
    let resolvedKind: ObjCResolvedKind?
    let origin: ObjCSymbolOrigin?
    let referenceStyleKind: ObjCReferenceStyleKind?
    let receiverHint: ObjCReceiverHint?
    let isForwardClassDeclaration: Bool

    var styleKind: ObjCTheme.StyleKind {
        resolvedKind?.styleKind(origin: origin, referenceStyleKind: referenceStyleKind) ?? .plainText
    }
}
