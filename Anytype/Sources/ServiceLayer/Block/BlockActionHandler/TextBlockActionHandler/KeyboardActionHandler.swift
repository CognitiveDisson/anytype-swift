import BlocksModels
import Combine
import AnytypeCore
import Foundation
import ProtobufMessages

protocol KeyboardActionHandlerProtocol {
    func handle(info: BlockInformation, action: CustomTextView.KeyboardAction)
}

final class KeyboardActionHandler: KeyboardActionHandlerProtocol {
    
    private let service: BlockActionServiceProtocol
    private let toggleStorage: ToggleStorage
    
    init(
        service: BlockActionServiceProtocol,
        toggleStorage: ToggleStorage
    ) {
        self.service = service
        self.toggleStorage = toggleStorage
    }

    func handle(info: BlockInformation, action: CustomTextView.KeyboardAction) {
        guard case let .text(text) = info.content else {
            anytypeAssertionFailure("Only text block may send keyboard action", domain: .textBlockActionHandler)
            return
        }
        
        switch action {
        case let .enterInside(string, position):
            service.split(
                string,
                blockId: info.id,
                mode: splitMode(info),
                position: position,
                newBlockContentType: contentTypeForSplit(text.contentType, blockId: info.id)
            )

        case .enterAtTheEnd(let string):
            onEnterAtTheEndOfContent(info: info, text: text, action: action, newString: string)

        case .deleteAtTheBegining:
            guard text.delitable else { return }
            service.merge(secondBlockId: info.id)

        case .deleteForEmpty:
            service.delete(blockId: info.id)
        }
    }
    
    private func onEnterAtTheEndOfContent(
        info: BlockInformation,
        text: BlockText,
        action: CustomTextView.KeyboardAction,
        newString: NSAttributedString
    ) {
        let enterInEmptyList = text.contentType.isList && newString.string.isEmpty
        guard !enterInEmptyList else {
            service.turnInto(.text, blockId: info.id)
            return
        }

        let needChildForToggle = text.contentType == .toggle && toggleStorage.isToggled(blockId: info.id)
        let needChildForList = text.contentType != .toggle && text.contentType.isList && info.childrenIds.isNotEmpty
        
        if needChildForToggle {
            if info.childrenIds.isEmpty {
                service.addChild(info: BlockInformation.emptyText, parentId: info.id)
            } else {
                let firstChildId = info.childrenIds[0]
                service.add(info: BlockInformation.emptyText, targetBlockId: firstChildId, position: .top)
            }
        } else if needChildForList {
            let firstChildId = info.childrenIds[0]
            service.add(
                info: BlockInformation.emptyText,
                targetBlockId: firstChildId,
                position: .top
            )
        } else {
            let type = text.contentType.isList ? text.contentType : .text

            service.split(
                newString,
                blockId: info.id,
                mode: splitMode(info),
                position: newString.string.count,
                newBlockContentType: type
            )
        }
    }
}


// MARK: - Extensions
private extension KeyboardActionHandler {
    // We do want to create regular text block when splitting title block
    func contentTypeForSplit(_ style: BlockText.Style, blockId: BlockId) -> BlockText.Style {
        if style == .title {
            return .text
        }
        
        if style == .toggle {
            return toggleStorage.isToggled(blockId: blockId) ? .text : .toggle
        }
        
        return style
    }

    func splitMode(_ info: BlockInformation) -> Anytype_Rpc.Block.Split.Request.Mode {
        if info.content.isToggle {
            return toggleStorage.isToggled(blockId: info.id) ? .inner : .bottom
        } else {
            return info.childrenIds.isNotEmpty ? .inner : .bottom
        }
    }
}

private extension BlockText {
    var delitable: Bool {
        contentType != .description
    }
}