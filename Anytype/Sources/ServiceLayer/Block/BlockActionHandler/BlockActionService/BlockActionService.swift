import Combine
import Services
import UIKit
import Logger
import ProtobufMessages
import AnytypeCore

final class BlockActionService: BlockActionServiceProtocol {
    private let documentId: BlockId

    private let singleService: BlockActionsServiceSingleProtocol
    private let objectActionService: ObjectActionsServiceProtocol
    private let textService = TextService()
    private let listService: BlockListServiceProtocol
    private let bookmarkService: BookmarkServiceProtocol
    private let fileService = FileActionsService()
    private let cursorManager: EditorCursorManager
    
    private weak var modelsHolder: EditorMainItemModelsHolder?

    init(
        documentId: String,
        listService: BlockListServiceProtocol,
        singleService: BlockActionsServiceSingleProtocol,
        objectActionService: ObjectActionsServiceProtocol,
        modelsHolder: EditorMainItemModelsHolder,
        bookmarkService: BookmarkServiceProtocol,
        cursorManager: EditorCursorManager
    ) {
        self.documentId = documentId
        self.listService = listService
        self.singleService = singleService
        self.objectActionService = objectActionService
        self.modelsHolder = modelsHolder
        self.bookmarkService = bookmarkService
        self.cursorManager = cursorManager
    }

    // MARK: Actions

    func addChild(info: BlockInformation, parentId: BlockId) {
        add(info: info, targetBlockId: parentId, position: .inner)
    }

    func add(info: BlockInformation, targetBlockId: BlockId, position: BlockPosition, setFocus: Bool) {
        guard let blockId = singleService
            .add(contextId: documentId, targetId: targetBlockId, info: info, position: position) else { return }
        
        if setFocus {
            cursorManager.blockFocus = .init(id: blockId, position: .beginning)
        }
    }

    func split(
        _ string: NSAttributedString,
        blockId: BlockId,
        mode: Anytype_Rpc.Block.Split.Request.Mode,
        range: NSRange,
        newBlockContentType: BlockText.Style
    ) {
        guard let blockId = textService.split(
            contextId: documentId,
            blockId: blockId,
            range: range,
            style: newBlockContentType,
            mode: mode
        ) else { return }

        cursorManager.blockFocus = .init(id: blockId, position: .beginning)
    }

    func duplicate(blockId: BlockId) {        
        singleService
            .duplicate(contextId: documentId, targetId: blockId, blockIds: [blockId], position: .bottom)
    }


    func createPage(targetId: BlockId, type: ObjectTypeId, position: BlockPosition) -> BlockId? {
        guard let newBlockId = objectActionService.createPage(
            contextId: documentId,
            targetId: targetId,
            details: [.name(""), .type(type)],
            position: position,
            templateId: ""
        ) else { return nil }

        return newBlockId
    }

    func turnInto(_ style: BlockText.Style, blockId: BlockId) {
        textService.setStyle(contextId: documentId, blockId: blockId, style: style)
    }
    
    func turnIntoPage(blockId: BlockId) -> BlockId? {
        return objectActionService.convertChildrenToPages(contextID: documentId, blocksIds: [blockId], typeId: "")?.first
    }
    
    func checked(blockId: BlockId, newValue: Bool) {
        textService.checked(contextId: documentId, blockId: blockId, newValue: newValue)
    }
    
    func merge(secondBlockId: BlockId) {
        guard
            let previousBlock = modelsHolder?.findModel(
                beforeBlockId: secondBlockId,
                acceptingTypes: BlockContentType.allTextTypes
            ),
            previousBlock.content != .unsupported
        else {
            delete(blockIds: [secondBlockId])
            return
        }
        
        if textService.merge(contextId: documentId, firstBlockId: previousBlock.blockId, secondBlockId: secondBlockId) {
            setFocus(model: previousBlock)
        }
    }
    
    func delete(blockIds: [BlockId]) {
        _ = singleService.delete(contextId: documentId, blockIds: blockIds)
    }
    
    func setText(contextId: BlockId, blockId: BlockId, middlewareString: MiddlewareString) {
        textService.setText(contextId: contextId, blockId: blockId, middlewareString: middlewareString)
    }

    func setTextForced(contextId: BlockId, blockId: BlockId, middlewareString: MiddlewareString) {
        textService.setTextForced(contextId: contextId, blockId: blockId, middlewareString: middlewareString)
    }
    
    func setObjectTypeId(_ objectTypeId: String) {
        objectActionService.setObjectType(objectId: documentId, objectTypeId: objectTypeId)
    }

    func setObjectSetType() async throws {
        try await objectActionService.setObjectSetType(objectId: documentId)
    }
    
    func setObjectCollectionType() async throws {
        try await objectActionService.setObjectCollectionType(objectId: documentId)
    }

    private func setFocus(model: BlockViewModelProtocol) {
        if case let .text(text) = model.info.content {
            model.set(focus: .at(text.endOfTextRangeWithMention))
        }
    }
}

// MARK: - BookmarkFetch

extension BlockActionService {
    func bookmarkFetch(blockId: BlockId, url: AnytypeURL) {
        bookmarkService.fetchBookmark(contextID: self.documentId, blockID: blockId, url: url.absoluteString)
    }

    func createAndFetchBookmark(
        contextID: BlockId,
        targetID: BlockId,
        position: BlockPosition,
        url: AnytypeURL
    ) {
        bookmarkService.createAndFetchBookmark(
            contextID: contextID,
            targetID: targetID,
            position: position,
            url: url.absoluteString
        )
    }
}

// MARK: - SetBackgroundColor

extension BlockActionService {
    func setBackgroundColor(blockIds: [BlockId], color: BlockBackgroundColor) {
        setBackgroundColor(blockIds: blockIds, color: color.middleware)
    }
    
    func setBackgroundColor(blockIds: [BlockId], color: MiddlewareColor) {
        listService.setBackgroundColor(objectId: documentId, blockIds: blockIds, color: color)
    }
}

// MARK: - UploadFile

extension BlockActionService {
    func upload(blockId: BlockId, filePath: String) async throws {
        try await fileService.uploadDataAt(source: .path(filePath), contextID: documentId, blockID: blockId)
    }
}
