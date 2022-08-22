import Foundation
import BlocksModels

extension BundledRelationsValueProvider {
    
    var pageCellTitle: String {
        switch layout {
        case .note:
            return snippet
        default:
            return name
        }
    }

    var title: String {
        if isDeleted {
            return Loc.nonExistentObject
        }
        
        let title: String

        switch layout {
        case .note:
            title = snippet
        default:
            title = name
        }

        return title.isEmpty ? Loc.untitled : title
    }
    
    var homeLayout: HomeCellData.TitleLayout {
        switch objectIconImage {
        case .todo, .icon(.bookmark):
            return .horizontal
        default:
            return .vertical
        }
    }
    
    var mentionTitle: String {
        String(title.prefix(30)).replacingOccurrences(of: "\n", with: " ")
    }
}
