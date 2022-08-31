import BlocksModels

enum RelationItemModel: Hashable {
    case text(Relation.Text)
    case number(Relation.Text)
    case status(Relation.Status)
    case date(DateModel)
    case object(Relation.Object)
    case checkbox(Relation.Checkbox)
    case url(Relation.Text)
    case email(Relation.Text)
    case phone(Relation.Text)
    case tag(Relation.Tag)
    case file(Relation.File)
    case unknown(Relation.Unknown)

    init(relation: Relation) {
        switch relation {
        case .text(let text):
            self = .text(text)
        case .number(let text):
            self = .number(text)
        case .status(let status):
            self = .status(status)
        case .date(let date):
            self = .date(
                .init(
                    id: date.id,
                    name: date.name,
                    textValue: date.value?.text,
                    isEditable: relation.isEditable
                )
            )
        case .object(let object):
            self = .object(object)
        case .checkbox(let checkbox):
            self = .checkbox(checkbox)
        case .url(let text):
            self = .url(text)
        case .email(let text):
            self = .email(text)
        case .phone(let text):
            self = .phone(text)
        case .tag(let tag):
            self = .tag(tag)
        case .file(let file):
            self = .file(file)
        case .unknown(let unknown):
            self = .unknown(unknown)
        }
    }

    var hint: String {
        switch self {
        case .text: return Loc.enterText
        case .number: return Loc.enterNumber
        case .date: return Loc.enterDate
        case .object:
            switch id {
            case BundledRelationKey.setOf.rawValue:
                return Loc.Set.FeaturedRelations.source
            default:
                return Loc.selectObjects
            }
        case .url: return Loc.enterURL
        case .email: return Loc.enterEMail
        case .phone: return Loc.enterPhone
        case .status: return Loc.selectStatus
        case .tag: return Loc.selectTags
        case .file: return Loc.selectFiles
        case .checkbox: return ""
        case .unknown: return Loc.enterValue
        }
    }

    var isEditable: Bool {
        switch self {
        case .text(let text): return text.isEditable
        case .number(let text): return text.isEditable
        case .status(let status): return status.isEditable
        case .date(let date): return date.isEditable
        case .object(let object): return object.isEditable
        case .checkbox(let checkbox): return checkbox.isEditable
        case .url(let text): return text.isEditable
        case .email(let text): return text.isEditable
        case .phone(let text): return text.isEditable
        case .tag(let tag): return tag.isEditable
        case .file(let file): return file.isEditable
        case .unknown(let unknown): return unknown.isEditable
        }
    }

    var name: String {
        switch self {
        case .text(let text): return text.name
        case .number(let text): return text.name
        case .status(let status): return status.name
        case .date(let date): return date.name
        case .object(let object): return object.name
        case .checkbox(let checkbox): return checkbox.name
        case .url(let text): return text.name
        case .email(let text): return text.name
        case .phone(let text): return text.name
        case .tag(let tag): return tag.name
        case .file(let file): return file.name
        case .unknown(let unknown): return unknown.name
        }
    }

    var id: String {
        switch self {
        case .text(let text): return text.id
        case .number(let text): return text.id
        case .status(let status): return status.id
        case .date(let date): return date.id
        case .object(let object): return object.id
        case .checkbox(let checkbox): return checkbox.id
        case .url(let text): return text.id
        case .email(let text): return text.id
        case .phone(let text): return text.id
        case .tag(let tag): return tag.id
        case .file(let file): return file.id
        case .unknown(let unknown): return unknown.id
        }
    }
}

extension RelationItemModel {
    struct DateModel: Hashable {
        let id: String
        let name: String
        let textValue: String?
        let isEditable: Bool
    }
}
