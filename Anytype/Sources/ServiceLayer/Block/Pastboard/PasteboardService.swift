import BlocksModels

final class PasteboardService: PasteboardServiceProtocol {
    private let document: BaseDocumentProtocol
    private let pasteboardHelper: PasteboardHelper
    private let pasteboardMiddlewareService: PasteboardMiddlewareServiceProtocol
    private let pasteboardOperations: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .utility
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    init(document: BaseDocumentProtocol,
         pasteboardHelper: PasteboardHelper,
         pasteboardMiddlewareService: PasteboardMiddlewareServiceProtocol) {
        self.document = document
        self.pasteboardMiddlewareService = pasteboardMiddlewareService
        self.pasteboardHelper = pasteboardHelper
    }
    
    var hasValidURL: Bool {
        pasteboardHelper.hasValidURL
    }
    
    func pasteInsideBlock(focusedBlockId: BlockId, range: NSRange) {
        let context = PasteboardActionContext.focused(focusedBlockId, range)
        paste(context: context)
    }
    
    func pasteInSelectedBlocks(selectedBlockIds: [BlockId]) {
        let context = PasteboardActionContext.selected(selectedBlockIds)
        paste(context: context)
    }
    
    private func paste(context: PasteboardActionContext) {
        let operation = PasteboardOperation (
            pasteboardHelper: pasteboardHelper,
            pasteboardMiddlewareService: pasteboardMiddlewareService,
            context: context
        ) { _ in
            #warning("add completion")
        }
        pasteboardOperations.addOperation(operation)
    }
    
    func copy(blocksIds: [BlockId], selectedTextRange: NSRange) {
        if let result = pasteboardMiddlewareService.copy(blocksIds: blocksIds, selectedTextRange: selectedTextRange) {
            pasteboardHelper.setItems(textSlot: result.textSlot, htmlSlot: result.htmlSlot, blocksSlots: result.blockSlot)
        }
    }
}