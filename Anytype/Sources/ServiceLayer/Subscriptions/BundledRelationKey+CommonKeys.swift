import Foundation
import BlocksModels

extension BundledRelationKey {
    
    // Keys for object list screens
    static var objectListKeys: [String] {
        let keys: [BundledRelationKey] = [
            .id,
            .iconEmoji,
            .iconImage,
            .name,
            .snippet,
            .description,
            .type,
            .layout,
            .isArchived,
            .isDeleted,
            .done,
            .isFavorite
        ]
        return keys.map { $0.rawValue }
    }
}