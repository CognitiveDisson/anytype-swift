import BlocksModels
import Combine
import AnytypeCore

enum EditorEditingState {
    case editing
    case selecting(blocks: [BlockId])
    case moving(indexPaths: [IndexPath])
}

/// Blocks drag & drop protocol.
protocol EditorPageMovingManagerProtocol {
    var movingBlocksIndexPaths: [IndexPath] { get }

    func canPlaceDividerAtIndexPath(_ indexPath: IndexPath) -> Bool
    func canMoveItemsToObject(at indexPath: IndexPath) -> Bool

    func moveItem(at indexPath: IndexPath)

    func didSelectMovingIndexPaths(_ indexPaths: [IndexPath])
    func didSelectEditingMode()
}

protocol EditorPageSelectionManagerProtocol {
    var selectedBlocksIndexPaths: [IndexPath] { get }

    func canSelectBlock(at indexPath: IndexPath) -> Bool
    func didLongTap(at indexPath: IndexPath)
    func didUpdateSelectedIndexPaths(_ indexPaths: [IndexPath])
}

protocol EditorPageBlocksStateManagerProtocol: EditorPageSelectionManagerProtocol, EditorPageMovingManagerProtocol, AnyObject {
    var editorEditingState: AnyPublisher<EditorEditingState, Never> { get }
    var editorSelectedBlocks: AnyPublisher<[BlockId], Never> { get }
}

final class EditorPageBlocksStateManager: EditorPageBlocksStateManagerProtocol {
    private enum MovingDestination {
        case position(IndexPath)
        case object(BlockId)
    }

    var editorEditingState: AnyPublisher<EditorEditingState, Never> { $editingState.eraseToAnyPublisher() }
    var editorSelectedBlocks: AnyPublisher<[BlockId], Never> { $selectedBlocks.eraseToAnyPublisher() }

    @Published var editingState: EditorEditingState = .editing
    @Published var selectedBlocks = [BlockId]()

    private(set) var selectedBlocksIndexPaths = [IndexPath]()
    private(set) var movingBlocksIndexPaths = [IndexPath]()
    private var movingDestination: MovingDestination?

    // We need to store interspace between root and all childs to disable cursor moving between those indexPaths
    private var movingBlocksWithChildsIndexPaths = [[IndexPath]]()

    private let document: BaseDocumentProtocol
    private let modelsHolder: EditorMainItemModelsHolder
    private let blockActionsServiceSingle: BlockActionsServiceSingleProtocol
    private let actionHandler: BlockActionHandlerProtocol
    private let router: EditorRouterProtocol

    weak var blocksSelectionOverlayViewModel: BlocksSelectionOverlayViewModel?

    private var cancellables = [AnyCancellable]()

    init(
        document: BaseDocumentProtocol,
        modelsHolder: EditorMainItemModelsHolder,
        blocksSelectionOverlayViewModel: BlocksSelectionOverlayViewModel,
        blockActionsServiceSingle: BlockActionsServiceSingleProtocol,
        actionHandler: BlockActionHandlerProtocol,
        router: EditorRouterProtocol
    ) {
        self.document = document
        self.modelsHolder = modelsHolder
        self.blocksSelectionOverlayViewModel = blocksSelectionOverlayViewModel
        self.blockActionsServiceSingle = blockActionsServiceSingle
        self.actionHandler = actionHandler
        self.router = router

        setupEditingHandlers()
    }

    // MARK: - EditorPageSelectionManagerProtocol

    func canSelectBlock(at indexPath: IndexPath) -> Bool {
        guard let block = modelsHolder.blockViewModel(at: indexPath.row) else { return false }

        if block.content.type == .text(.title) ||
            block.content.type == .featuredRelations {
            return false
        }

        return true
    }

    func didLongTap(at indexPath: IndexPath) {
        guard canSelectBlock(at: indexPath) else { return }

        modelsHolder.blockViewModel(at: indexPath.row).map {
            didSelectEditingState(info: $0.info)
        }
    }

    func didUpdateSelectedIndexPaths(_ indexPaths: [IndexPath]) {
        selectedBlocksIndexPaths = indexPaths

        blocksSelectionOverlayViewModel?.setSelectedBlocksCount(indexPaths.count)

        let blocksInformation = indexPaths.compactMap {
            modelsHolder.blockViewModel(at: $0.row)?.info
        }
        updateSelectionContent(selectedBlocks: blocksInformation)

        if case .selecting = editingState {
            editingState = .selecting(blocks: blocksInformation.map { $0.id })
        }
    }

    // MARK: - EditorPageMovingManagerProtocol
    func moveItem(at indexPath: IndexPath) {
        movingBlocksIndexPaths = [indexPath]

        startMoving()
    }

    func didSelectMovingIndexPaths(_ indexPaths: [IndexPath]) {
        movingBlocksIndexPaths = indexPaths
    }

    func canPlaceDividerAtIndexPath(_ indexPath: IndexPath) -> Bool {
        guard indexPath.section == 1 else { return false }

        for indexPathRanges in movingBlocksWithChildsIndexPaths {
            var ranges = indexPathRanges.sorted()

            ranges.removeFirst()
            if ranges.contains(indexPath) { return false }
        }

        let notAllowedTypes: [BlockContentType] = [.text(.title), .featuredRelations]

        if let element = modelsHolder.blockViewModel(at: indexPath.row),
           !notAllowedTypes.contains(element.content.type) {
            movingDestination = .position(indexPath)
            return true
        }

        // Divider can be placed at the bottom of last cell.
        if indexPath.row == modelsHolder.items.count {
            movingDestination = .position(indexPath)
            return true
        }

        return false
    }

    func didSelectEditingMode() {
        editingState = .editing
    }

    func canMoveItemsToObject(at indexPath: IndexPath) -> Bool {
        guard !movingBlocksWithChildsIndexPaths.flatMap({ $0 }).contains(indexPath),
              let element = modelsHolder.blockViewModel(at: indexPath.row) else { return false }

        switch element.content.type {
        case .file, .divider, .relation,
                .dataView, .featuredRelations,
                .bookmark, .smartblock, .text(.title):
            return false
        default:
            movingDestination = .object(element.blockId)

            return true
        }
    }

    // MARK: - Private

    private func setupEditingHandlers() {
        $editingState.sink { [unowned self] state in
            switch state {
            case .selecting(let blocks):
                movingBlocksIndexPaths.removeAll()
                movingBlocksWithChildsIndexPaths.removeAll()
                blocksSelectionOverlayViewModel?.setSelectedBlocksCount(blocks.count)
            case .moving:
                blocksSelectionOverlayViewModel?.setNeedsUpdateForMovingState()
            case .editing:
                movingBlocksIndexPaths.removeAll()
            }
        }.store(in: &cancellables)

        blocksSelectionOverlayViewModel?.blocksOptionViewModel?.tapHandler = { [weak self] in
            self?.handleBlocksOptionItemSelection($0)

        }
        blocksSelectionOverlayViewModel?.moveButtonHandler = { [weak self] in
            self?.startMoving()
        }
        blocksSelectionOverlayViewModel?.cancelButtonHandler = { [weak self] in
            self?.editingState = .editing
        }
    }

    private func updateSelectionContent(selectedBlocks: [BlockInformation]) {
        blocksSelectionOverlayViewModel?.blocksOptionViewModel?.options = selectedBlocks.blocksOptionItems
    }

    func startMoving() {
        let position: BlockPosition
        let contextId = document.objectId
        let targetId: BlockId
        let dropTargetId: BlockId
        switch movingDestination {
        case let .object(blockId):
            if let info = document.infoContainer.get(id: blockId),
               case let .link(content) = info.content {
                let document = BaseDocument(objectId: content.targetBlockID)
                let _ = document.open()

                guard let id = document.children.last?.id else { return }

                targetId = document.objectId
                dropTargetId = id
                position = .bottom
            } else {
                targetId = document.objectId
                position = .inner
                dropTargetId = blockId
            }
        case let .position(positionIndexPath):
            if let targetBlock = modelsHolder.blockViewModel(at: positionIndexPath.row) {
                position = .top
                dropTargetId = targetBlock.blockId
            } else if let targetBlock = modelsHolder.blockViewModel(at: positionIndexPath.row - 1) {
                position = .bottom
                dropTargetId = targetBlock.blockId
            } else {
                anytypeAssertionFailure("Unxpected case", domain: .editorPage)
                return
            }
            targetId = document.objectId
        case .none:
            anytypeAssertionFailure("Unxpected case", domain: .editorPage)
            return
        }

        let blockIds = movingBlocksIndexPaths
            .sorted()
            .compactMap { modelsHolder.blockViewModel(at: $0.row)?.blockId }

        blockActionsServiceSingle.move(
            contextId: contextId,
            blockIds: blockIds,
            targetContextID: targetId,
            dropTargetID: dropTargetId,
            position: position
        )

        editingState = .editing
    }

    private func didTapEndSelectionModeButton() {
        editingState = .editing
    }

    private func handleBlocksOptionItemSelection(_ item: BlocksOptionItem) {
        let elements = selectedBlocksIndexPaths.compactMap { modelsHolder.blockViewModel(at: $0.row) }

        switch item {
        case .delete:
            elements.forEach { actionHandler.delete(blockId: $0.blockId) }
        case .addBlockBelow:
            elements.forEach { actionHandler.addBlock(.text(.text), blockId: $0.blockId) }
        case .duplicate:
            elements.forEach { actionHandler.duplicate(blockId: $0.blockId) }
        case .turnInto:
            elements.forEach { actionHandler.turnIntoPage(blockId: $0.blockId) }
        case .moveTo:
            router.showMoveTo { [weak self] pageId in
                elements.forEach {
                    self?.actionHandler.moveToPage(blockId: $0.blockId, pageId: pageId)
                }
                self?.editingState = .editing
            }
            return
        case .move:
            var onlyRootIndexPaths = selectedBlocksIndexPaths
            let allMovingBlocks = selectedBlocksIndexPaths.map { indexPath -> [IndexPath] in
                guard let model = modelsHolder.blockViewModel(at: indexPath.row) else { return [] }

                var childIndexPaths = modelsHolder.allChildIndexes(viewModel: model)
                    .map { IndexPath(row: $0, section: indexPath.section) }

                onlyRootIndexPaths = onlyRootIndexPaths.filter { !childIndexPaths.contains($0) }

                childIndexPaths.append(indexPath)
                return childIndexPaths
            }

            movingBlocksWithChildsIndexPaths = allMovingBlocks
            didSelectMovingIndexPaths(selectedBlocksIndexPaths)
            editingState = .moving(indexPaths: allMovingBlocks.flatMap { $0 })
            movingBlocksIndexPaths = onlyRootIndexPaths
            return
        case .download:
            anytypeAssert(
                elements.count == 1,
                "Number of elements should be 1",
                domain: .editorPage
            )

            if case let .file(blockFile) = elements.first?.content,
               let url = UrlResolver.resolvedUrl(.file(id: blockFile.metadata.hash)) {
                router.saveFile(fileURL: url, type: blockFile.contentType)
            }
        case .style:
            editingState = .editing
            elements.first.map { router.showStyleMenu(information: $0.info) }

            return
        case .paste:
            let blockIds = elements.map(\.blockId)
            let pasteboardHelper = PasteboardHelper()
            if let pasteSlot = pasteboardHelper.obtainSlots() {
                actionHandler.paste(selectedBlockIds: blockIds, pasteSlot: pasteSlot)
            }
        case .copy:
            let blocksIds = elements.map(\.blockId)
            actionHandler.copy(blocksIds: blocksIds, selectedTextRange: NSRange())
        }

        editingState = .editing
    }
}

extension EditorPageBlocksStateManager: BlockSelectionHandler {
    func didSelectEditingState(info: BlockInformation) {
        editingState = .selecting(blocks: [info.id])
        selectedBlocks = [info.id]
        updateSelectionContent(selectedBlocks: [info])
    }
}

extension EditorMainItemModelsHolder {
    func allChildIndexes(viewModel: BlockViewModelProtocol) -> [Int] {
        allIndexes(for: viewModel.info.childrenIds)
    }

    private func allIndexes(for childs: [BlockId]) -> [Int] {
        var indexes = [Int]()

        for child in childs {
            guard let index = items.firstIndex(blockId: child) else {
                continue
            }

            indexes.append(index)

            guard let modelChilds = blockViewModel(at: index)?.info.childrenIds else { continue }
            indexes.append(contentsOf: allIndexes(for: modelChilds))
        }

        return indexes
    }
}
