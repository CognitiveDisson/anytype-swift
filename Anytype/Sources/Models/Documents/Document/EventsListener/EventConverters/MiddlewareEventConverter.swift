import ProtobufMessages
import BlocksModels
import AnytypeCore
import SwiftProtobuf

final class MiddlewareEventConverter {
    private let updater: BlockUpdater
    private let blocksContainer: BlockContainerModelProtocol
    private let detailsStorage: ObjectDetailsStorageProtocol
    private let informationCreator: BlockInformationCreator
    
    init(
        blocksContainer: BlockContainerModelProtocol,
        detailsStorage: ObjectDetailsStorageProtocol,
        informationCreator: BlockInformationCreator
    ) {
        self.updater = BlockUpdater(blocksContainer)
        self.blocksContainer = blocksContainer
        self.detailsStorage = detailsStorage
        self.informationCreator = informationCreator
    }
    
    func convert(_ event: Anytype_Event.Message.OneOf_Value) -> EventsListenerUpdate? {
        switch event {
        case let .threadStatus(status):
            return SyncStatus(status.summary.status).flatMap { .syncStatus($0) }
        case let .blockSetFields(fields):
            updater.update(entry: fields.id) { block in
                var block = block

                block.information = block.information.updated(with: fields.fields.toFieldTypeMap())
            }
            return .blocks(blockIds: [fields.id])
        case let .blockAdd(value):
            value.blocks
                .compactMap(BlockInformationConverter.convert(block:))
                .map(BlockModel.init)
                .forEach { block in
                    updater.insert(block: block)
                }
            // Because blockAdd message will always come together with blockSetChildrenIds
            // and it is easier to create update from those message
            return nil
        
        case let .blockDelete(value):
            value.blockIds.forEach { blockId in
                blocksContainer.remove(blockId)
            }
            // Because blockDelete message will always come together with blockSetChildrenIds
            // and it is easier to create update from those message
            return nil
    
        case let .blockSetChildrenIds(value):
            updater.set(children: value.childrenIds, parent: value.id)
            return .general
        case let .blockSetText(newData):
            return blockSetTextUpdate(newData)
        case let .blockSetBackgroundColor(updateData):
            updater.update(entry: updateData.id, update: { block in
                var block = block
                block.information = block.information.updated(
                    with: MiddlewareColor(rawValue: updateData.backgroundColor)
                )
            })
            return .blocks(blockIds: [updateData.id])
            
        case let .blockSetAlign(value):
            let blockId = value.id
            let alignment = value.align
            guard let modelAlignment = alignment.asBlockModel else {
                anytypeAssertionFailure("We cannot parse alignment: \(value)")
                return .general
            }
            
            updater.update(entry: blockId, update: { (value) in
                var value = value
                value.information.alignment = modelAlignment
            })
            return .blocks(blockIds: [blockId])
        
        case let .objectDetailsAmend(amend):
            guard amend.details.isNotEmpty else { return nil }
            
            let id = amend.id
            
            guard let currentDetails = detailsStorage.get(id: id) else {
                return nil
            }
            
            let updatedDetails = currentDetails.updated(by: amend.details.asDetailsDictionary)
            detailsStorage.add(details: updatedDetails, id: id)
            
            // change layout from `todo` to `basic` should trigger update title
            // in order to remove chackmark
            guard currentDetails.layout == updatedDetails.layout else {
                return .general
            }
            
            return .details(id: id)
            
        case let .objectDetailsUnset(payload):
            let id = payload.id
            
            guard let currentDetails = detailsStorage.get(id: id) else {
                return nil
            }
            
            let updatedDetails = currentDetails.removed(keys: payload.keys)
            detailsStorage.add(details: updatedDetails, id: id)
            
            // change layout from `todo` to `basic` should trigger update title
            // in order to remove chackmark
            guard currentDetails.layout == updatedDetails.layout else {
                return .general
            }
            
            return .details(id: id)
            
        case let .objectDetailsSet(value):
            guard value.hasDetails else {
                return .general
            }
            
            let id = value.id
            
            let details = ObjectDetails(
                id: id,
                values: value.details.fields
            )
            
            detailsStorage.add(
                details: details,
                id: id
            )
            
            return .details(id: id)

        case let .blockSetFile(newData):
            guard newData.hasState else {
                return .general
            }
            
            updater.update(entry: newData.id, update: { block in
                var block = block
                
                switch block.information.content {
                case let .file(fileData):
                    var fileData = fileData
                    
                    if newData.hasType {
                        if let contentType = FileContentType(newData.type.value) {
                            fileData.contentType = contentType
                        }
                    }

                    if newData.hasState {
                        if let state = BlockFileStateConverter.asModel(newData.state.value) {
                            fileData.state = state
                        }
                    }
                    
                    if newData.hasName {
                        fileData.metadata.name = newData.name.value
                    }
                    
                    if newData.hasHash {
                        fileData.metadata.hash = newData.hash.value
                    }
                    
                    if newData.hasMime {
                        fileData.metadata.mime = newData.mime.value
                    }
                    
                    if newData.hasSize {
                        fileData.metadata.size = newData.size.value
                    }
                    
                    block.information.content = .file(fileData)
                default: return
                }
            })
            return .blocks(blockIds: [newData.id])
        case let .blockSetBookmark(value):
            
            let blockId = value.id
            let newUpdate = value
            
            updater.update(entry: blockId, update: { (value) in
                var block = value
                switch value.information.content {
                case let .bookmark(value):
                    var value = value
                    
                    if newUpdate.hasURL {
                        value.url = newUpdate.url.value
                    }
                    
                    if newUpdate.hasTitle {
                        value.title = newUpdate.title.value
                    }

                    if newUpdate.hasDescription_p {
                        value.theDescription = newUpdate.description_p.value
                    }

                    if newUpdate.hasImageHash {
                        value.imageHash = newUpdate.imageHash.value
                    }

                    if newUpdate.hasFaviconHash {
                        value.faviconHash = newUpdate.faviconHash.value
                    }

                    if newUpdate.hasType {
                        if let type = BlocksModelsParserBookmarkTypeEnumConverter.asModel(newUpdate.type.value) {
                            value.type = type
                        }
                    }
                    
                    block.information.content = .bookmark(value)

                default: return
                }
            })
            return .blocks(blockIds: [blockId])
            
        case let .blockSetDiv(value):
            guard value.hasStyle else {
                return .general
            }
            
            let blockId = value.id
            let newUpdate = value
            
            updater.update(entry: blockId, update: { (value) in
                var block = value
                switch value.information.content {
                case let .divider(value):
                    var value = value
                                        
                    if let style = BlockDivider.Style(newUpdate.style.value) {
                        value.style = style
                    }
                    
                    block.information.content = .divider(value)
                    
                default: return
                }
            })
            return .blocks(blockIds: [value.id])
        
        /// Special case.
        /// After we open document, we would like to receive all blocks of opened page.
        /// For that, we send `blockShow` event to `eventHandler`.
        ///
        case .objectShow:
            return .general
        default: return nil
        }
    }
    
    private func blockSetTextUpdate(_ newData: Anytype_Event.Block.Set.Text) -> EventsListenerUpdate {
        guard var blockModel = blocksContainer.model(id: newData.id) else {
            anytypeAssertionFailure("Block model with id \(newData.id) not found in container")
            return .general
        }
        guard case let .text(oldText) = blockModel.information.content else {
            anytypeAssertionFailure("Block model doesn't support text:\n \(blockModel.information)")
            return .general
        }
        
        guard let newInformation = informationCreator.createBlockInformation(from: newData),
              case let .text(textContent) = newInformation.content else {
            return .general
        }
        blockModel.information = newInformation
        
        // If toggle changed style to another style or vice versa
        // we should rebuild all view to display/hide toggle's child blocks
        let isOldStyleToggle = oldText.contentType == .toggle
        let isNewStyleToggle = textContent.contentType == .toggle
        let toggleStyleChanged = isOldStyleToggle != isNewStyleToggle
        return toggleStyleChanged ? .general : .blocks(blockIds: [newData.id])
    }
}

private extension Array where Element == Anytype_Event.Object.Details.Amend.KeyValue {

    var asDetailsDictionary: [String: Google_Protobuf_Value] {
        reduce(
            into: [String: Google_Protobuf_Value]()
        ) { result, detail in
            result[detail.key] = detail.value
        }
    }
    
}