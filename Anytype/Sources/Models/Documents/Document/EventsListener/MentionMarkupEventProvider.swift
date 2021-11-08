import AnytypeCore
import BlocksModels
import ProtobufMessages

final class MentionMarkupEventProvider {
    
    private let objectId: BlockId
    private let blocksContainer: BlockContainerModelProtocol
    private let detailsStorage: ObjectDetailsStorageProtocol
        
    init(
        objectId: BlockId,
        blocksContainer: BlockContainerModelProtocol,
        detailsStorage: ObjectDetailsStorageProtocol
    ) {
        self.objectId = objectId
        self.blocksContainer = blocksContainer
        self.detailsStorage = detailsStorage
    }
    
    func updateMentionsEvent() -> EventsListenerUpdate {
        let blockIds = blocksContainer
            .children(of: objectId)
            .compactMap { blocksContainer.model(id: $0) }
            .compactMap { updateIfNeeded(model: $0) }
        
        return .blocks(blockIds: Set(blockIds))
    }
    
    func updateIfNeeded(model: BlockModelProtocol) -> BlockId? {
        guard case let .text(content) = model.information.content else { return nil }
        guard !content.marks.marks.isEmpty else { return nil }
        
        var string = content.text
        var sortedMarks = content.marks.marks
            .sorted { $0.range.from < $1.range.from }
        var needUpdate = false
        
        for offset in 0..<sortedMarks.count {
            let mark = sortedMarks[offset]
            guard mark.type == .mention && mark.param.isNotEmpty else { continue }
            
            guard let mentionRange = mentionRange(in: string, range: mark.range) else { continue }
            let mentionFrom = mark.range.from
            let mentionTo = mark.range.to
            let mentionName = string[mentionRange]
            
            let mentionBlockId = mark.param
            let details = detailsStorage.get(id: mentionBlockId)
            
            let mentionData = details.flatMap { MentionData(details: $0) } ?? .noDetails(blockId: mentionBlockId)
            
            guard let mentionNameInDetails = details?.mentionTitle else { return nil }
            
            // TODO: Update only mentions to updated pages
            let mentionChanged = true // mentionName != mentionNameInDetails
            
            if mentionChanged {
                needUpdate = true
                let countDelta = Int32(mentionName.count - mentionNameInDetails.count)

                string.replaceSubrange(mentionRange, with: mentionNameInDetails)
                
                if countDelta != 0 {
                    var mentionMark = mark
                    mentionMark.range.to -= countDelta
                    sortedMarks[offset] = mentionMark
                    
                    for counter in 0..<sortedMarks.count {
                        var mark = sortedMarks[counter]
                        if counter == offset || mark.range.to <= mentionFrom {
                            continue
                        }
                        
                        if mark.range.from >= mentionTo {
                            mark.range.from -= countDelta
                        }
                        mark.range.to -= countDelta
                        sortedMarks[counter] = mark
                    }
                }
            }
        }
        if needUpdate {
            update(model: model, string: string, marks: sortedMarks)
        }
        
        return needUpdate ? model.information.id : nil
    }
    
    private func mentionRange(in string: String, range: Anytype_Model_Range) -> Range<String.Index>? {
        guard range.from < string.count, range.to <= string.count else {
            anytypeAssertionFailure("Index out of bounds \(range) in \(string)")
            return nil
        }
        let from = string.index(string.startIndex, offsetBy: Int(range.from))
        let to = string.index(string.startIndex, offsetBy: Int(range.to))
        return from..<to
    }
    
    private func update(
        model: BlockModelProtocol,
        string: String,
        marks: [Anytype_Model_Block.Content.Text.Mark]) {
        if case var .text(content) = model.information.content {
            content.text = string
            content.marks = Anytype_Model_Block.Content.Text.Marks(marks: marks)
            var model = model
            model.information.content = .text(content)
        }
    }
}
