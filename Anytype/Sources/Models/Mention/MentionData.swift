import BlocksModels

struct MentionData: Equatable {
    let image: ObjectIconImage?
    let blockId: BlockId
    let isDeleted: Bool
    let isArchived: Bool
    
    static func noDetails(blockId: BlockId) -> MentionData {
        return MentionData(image: nil, blockId: blockId, isDeleted: false, isArchived: false)
    }
}

extension MentionData {
    init(details: ObjectDetails) {
        self.init(
            image: details.objectIconImage,
            blockId: details.id,
            isDeleted: details.isDeleted,
            isArchived: details.isArchived
        )
    }
}
