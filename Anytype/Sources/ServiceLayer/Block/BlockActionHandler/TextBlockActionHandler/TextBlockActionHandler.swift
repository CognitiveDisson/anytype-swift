import BlocksModels
import Combine
import AnytypeCore
import Foundation

final class TextBlockActionHandler {
    
    private let service: BlockActionServiceProtocol
    private let textService = TextService()
    private let contextId: String
    
    private weak var modelsHolder: ObjectContentViewModelsSharedHolder?

    init(
        contextId: String,
        service: BlockActionServiceProtocol,
        modelsHolder: ObjectContentViewModelsSharedHolder
    ) {
        self.service = service
        self.contextId = contextId
        self.modelsHolder = modelsHolder
    }

    func handlingTextViewAction(_ block: BlockModelProtocol, _ action: CustomTextView.UserAction) {
        switch action {
        case let .keyboardAction(value):
            handlingKeyboardAction(block, value)
        case let .changeText(attributedText):
            handleChangeText(block, text: attributedText)
        case .changeTextStyle, .changeLink:
            anytypeAssertionFailure("We handle this update in `BlockActionHandler`")
        case .changeCaretPosition, .showPage, .openURL:
            break
        case let .shouldChangeText(range, replacementText, mentionsHolder):
            mentionsHolder.removeMentionIfNeeded(
                replacementRange: range,
                replacementText: replacementText
            )
        }
    }
    
    private func handleChangeText(_ block: BlockModelProtocol, text: NSAttributedString) {
        guard case var .text(textContentType) = block.information.content else { return }
        var blockModel = block

        let middlewareString = AttributedTextConverter.asMiddleware(attributedText: text)
        textContentType.text = middlewareString.text
        textContentType.marks = middlewareString.marks

        let blockId = blockModel.information.id
        blockModel.information.content = .text(textContentType)

        EventsBunch(
            objectId: contextId,
            localEvents: [.setText(blockId: blockId, text: middlewareString.text)]
        ).send()

        textService.setText(contextId: contextId, blockId: blockId, middlewareString: middlewareString)
    }

    private func handlingKeyboardAction(_ block: BlockModelProtocol, _ action: CustomTextView.KeyboardAction) {
        switch action {
        // .enterWithPayload and .enterAtBeginning should be used with BlockSplit
        case let .enterInsideContent(topString, bottomString):
            if let newBlock = BlockBuilder.createInformation(block: block, action: action, textPayload: bottomString ?? "") {
                if let oldText = topString {
                    guard case let .text(text) = block.information.content else {
                        anytypeAssertionFailure("Only text block may send keyboard action")
                        return
                    }
                    self.service.split(
                        info: block.information,
                        oldText: oldText,
                        newBlockContentType: text.contentType.contentTypeForSplit
                    )
                }
                else {
                    self.service.add(
                        info: newBlock, targetBlockId: block.information.id, position: .bottom, shouldSetFocusOnUpdate: true
                    )
                }
            }

        case let .enterAtTheBeginingOfContent(payload): // we should assure ourselves about type of block.
            /// TODO: Fix it in TextView API.
            /// If payload is empty, so, handle it as .enter ( or .enter at the end )
            if payload.isEmpty == true {
                self.handlingKeyboardAction(block, .enterAtTheEndOfContent)
                return
            }
            if let newBlock = BlockBuilder.createInformation(block: block, action: action, textPayload: payload) {
                if case let .text(text) = block.information.content {
                    self.service.split(
                        info: block.information,
                        oldText: "",
                        newBlockContentType: text.contentType.contentTypeForSplit
                    )
                }
                else {
                    self.service.add(info: newBlock, targetBlockId: block.information.id, position: .bottom, shouldSetFocusOnUpdate: true)
                }
            }

        case .enterAtTheEndOfContent:
            // BUSINESS LOGIC:
            // We should check that if we are in `list` block and its text is `empty`, we should turn it into `.text`
            switch block.information.content {
            case let .text(value) where value.contentType.isList && value.text == "":
                // Turn Into empty text block.
                if let newContentType = BlockBuilder.createContentType(block: block, action: action, textPayload: value.text) {
                    /// TODO: Add focus on this block.
                    self.service.turnInto(
                        blockId: block.information.id,
                        type: newContentType.type,
                        shouldSetFocusOnUpdate: true
                    )
                }
            default:
                if let newBlock = BlockBuilder.createInformation(block: block, action: action, textPayload: "") {
                    switch block.information.content {
                    case let .text(payload):
                        let isListAndNotToggle = payload.contentType.isListAndNotToggle
                        let isToggleAndOpen = payload.contentType == .toggle && block.isToggled
                        // In case of return was tapped in list block (for toggle it should be open)
                        // and this block has children, we will insert new child block at the beginning
                        // of children list, otherwise we will create new block under current block
                        let childrenIds = block.information.childrenIds

                        switch (childrenIds.isEmpty, isToggleAndOpen, isListAndNotToggle) {
                        case (true, true, _):
                            self.service.addChild(info: newBlock, parentBlockId: block.information.id)
                        case (false, true, _), (false, _, true):
                            let firstChildId = childrenIds[0]
                            self.service.add(
                                info: newBlock,
                                targetBlockId: firstChildId,
                                position: .top,
                                shouldSetFocusOnUpdate: true
                            )
                        default:
                            let newContentType = payload.contentType.isList ? payload.contentType : .text

                            self.service.split(
                                info: block.information,
                                oldText: payload.text,
                                newBlockContentType: newContentType
                            )
                        }
                    default: return
                    }
                }
            }

        case .deleteAtTheBeginingOfContent:
            guard block.information.content.type != .text(.description) else { return }
            guard let previousModel = modelsHolder?.findModel(beforeBlockId: block.information.id) else {
                anytypeAssertionFailure("""
                    We can't find previous block to focus on at command .delete
                    Block: \(block.information.id)
                    Moving to .delete command.
                    """
                )
                self.handlingKeyboardAction(block, .deleteOnEmptyContent)
                return
            }
            guard previousModel.content != .unsupported else { return }
            
            let previousBlockId = previousModel.blockId
            
            var localEvents = [LocalEvent]()
            if case let .text(text) = previousModel.information.content {
                let nsText = NSString(string: text.text)
                let range = NSRange(location: nsText.length, length: 0)
                localEvents.append(contentsOf: [
                    .setFocus(blockId: previousBlockId, position: .at(range))
                ])
            }
            service.merge(firstBlockId: previousModel.blockId, secondBlockId: block.information.id, localEvents: localEvents)

        case .deleteOnEmptyContent:
            let blockId = block.information.id
            let previousModel = modelsHolder?.findModel(beforeBlockId: blockId)
            service.delete(blockId: blockId, previousBlockId: previousModel?.blockId)
        }
    }
}

extension BlockText.Style {
    // We do want to create regular text block when splitting title block
    var contentTypeForSplit: BlockText.Style {
        self == .title ? .text : self
    }
}