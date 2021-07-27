import BlocksModels
import ProtobufMessages
import AnytypeCore

final class LocalEventConverter {
    private weak var container: RootBlockContainer?
    private let blockValidator = BlockValidator(restrictionsFactory: BlockRestrictionsFactory())
    
    init(container: RootBlockContainer?) {
        self.container = container
    }
    
    func convert(_ event: LocalEvent) -> EventHandlerUpdate? {
        switch event {
        case let .setFocus(blockId, position):
            setFocus(blockId: blockId, position: position)
            return nil
        case let .setTextMerge(blockId):
            guard (container?.blocksContainer.model(id: blockId)) != nil else {
                anytypeAssertionFailure("setTextMerge. We can't find model by id \(blockId)")
                return nil
            }
            return .general
        case .setToggled:
            return .general
        case let .setText(blockId: blockId, text: text):
            return blockSetTextUpdate(blockId: blockId, text: text)
        case .setLoadingState(blockId: let blockId):
            guard var model = container?.blocksContainer.model(id: blockId) else {
                anytypeAssertionFailure("setLoadingState. Can't find model by id \(blockId)")
                return nil
            }
            guard case var .file(content) = model.information.content else {
                anytypeAssertionFailure("Not file content of block \(blockId) for setLoading action")
                return nil
            }
            
            content.state = .uploading
            model.information.content = .file(content)
            return .update(blockIds: [blockId])
        case .reload(blockId: let blockId):
            return .update(blockIds: [blockId])
        }
    }
    
    // simplified version of inner converter method
    // func blockSetTextUpdate(_ newData: Anytype_Event.Block.Set.Text)
    // only text is changed
    private func blockSetTextUpdate(blockId: BlockId, text: String) -> EventHandlerUpdate {
        typealias TextConverter = MiddlewareModelsModule.Parsers.Text.AttributedText.Converter
        
        guard var blockModel = container?.blocksContainer.model(id: blockId) else {
            anytypeAssertionFailure("Block model with id \(blockId) not found in container")
            return .general
        }
        guard case let .text(oldText) = blockModel.information.content else {
            anytypeAssertionFailure("Block model doesn't support text:\n \(blockModel.information)")
            return .general
        }
        
        let middleContent = Anytype_Model_Block.Content.Text(
            text: text,
            style: BlockTextContentTypeConverter.asMiddleware(oldText.contentType),
            marks: TextConverter.asMiddleware(attributedText: oldText.attributedText).marks,
            checked: oldText.checked,
            color: oldText.color?.rawValue ?? ""
        )
        
        guard var textContent = ContentTextConverter().textContent(middleContent) else {
            anytypeAssertionFailure("We cannot block content from: \(middleContent)")
            return .general
        }

        textContent.contentType = oldText.contentType
        textContent.number = oldText.number
        
        blockModel.information.content = .text(textContent)
        blockModel.information = blockValidator.validated(information: blockModel.information)
        
        return .update(blockIds: [blockId])
    }
    
    private func setFocus(blockId: BlockId, position: BlockFocusPosition) {
        guard var model = container?.blocksContainer.model(id: blockId) else {
            anytypeAssertionFailure("setFocus. We can't find model by id \(blockId)")
            return
        }
        model.isFirstResponder = true
        model.focusAt = position
    }
}
