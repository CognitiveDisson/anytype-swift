import BlocksModels
import ProtobufMessages
import AnytypeCore

enum MarkStyleActionConverter {
    
    static func asModel(_ tuple: MiddlewareTuple) -> MarkStyleAction? {
        switch tuple.attribute {
        case .strikethrough:
            return .strikethrough(true)
        case .keyboard:
            return .keyboard(true)
        case .italic:
            return .italic(true)
        case .bold:
            return .bold(true)
        case .underscored:
            return .underscored(true)
        case .link:
            return .link(URL(string: tuple.value))

        case .textColor:
            guard let color = MiddlewareColor(rawValue: tuple.value)?.color(background: false) else {
                return nil
            }
            return .textColor(color)

        case .backgroundColor:
            guard let color = MiddlewareColor(rawValue: tuple.value)?.color(background: true) else {
                return nil
            }
            return .backgroundColor(color)
        case .mention:
            return .mention(tuple.value)
        case .UNRECOGNIZED:
            anytypeAssertionFailure("Unrecognized markup")
            return nil
        }
    }
}
