import SwiftUI
import BlocksModels
import Combine

final class EditorAssembly {
    
    func documentView(blockId: BlockId) -> some View {
        EditorViewRepresentable(documentId: blockId).eraseToAnyView()
    }
    
    static func build(blockId: BlockId) -> DocumentEditorViewController {
        let controller = DocumentEditorViewController()
        let document = BaseDocument()
        let router = EditorRouter(viewController: controller, document: document)
        
        let viewModel = buildViewModel(
            blockId: blockId,
            viewInput: controller,
            document: document,
            router: router)
        
        controller.viewModel = viewModel
        
        return controller
    }
    
    private static func buildViewModel(
        blockId: BlockId,
        viewInput: EditorModuleDocumentViewInput,
        document: BaseDocumentProtocol,
        router: EditorRouter
    ) -> DocumentEditorViewModel {
        
        let objectSettinsViewModel = ObjectSettingsViewModel(
            objectDetailsService: ObjectDetailsService(
                eventHandler: document.eventHandler,
                objectId: blockId
            )
        )
        
        let detailsViewModel = DocumentDetailsViewModel { }
        
        let selectionHandler = EditorSelectionHandler()
        let modelsHolder = SharedBlockViewModelsHolder(objectId: blockId)
        
        let blockActionHandler = BlockActionHandler(
            documentId: blockId,
            modelsHolder: modelsHolder,
            selectionHandler: selectionHandler,
            document: document,
            router: router
        )
        
        let eventProcessor = EventProcessor(document: document, modelsHolder: modelsHolder)
        let editorBlockActionHandler = EditorActionHandler(
            document: document,
            blockActionHandler: blockActionHandler,
            eventProcessor: eventProcessor
        )
        
        let blockDelegate = BlockDelegateImpl(
            viewInput: viewInput,
            document: document
        )
        
        let blocksConverter = BlockViewModelBuilder(
            document: document,
            blockActionHandler: editorBlockActionHandler,
            router: router,
            delegate: blockDelegate,
            mentionsConfigurator: MentionsConfigurator(
                didSelectMention: { pageId in
                    router.showPage(with: pageId)
                }
            ),
            detailsLoader: DetailsLoader(
                document: document,
                eventProcessor: eventProcessor
            )
        )
        
        let wholeBlockMarkupViewModel = MarkupViewModel(actionHandler: editorBlockActionHandler)
        
        return DocumentEditorViewModel(
            documentId: blockId,
            document: document,
            viewInput: viewInput,
            blockDelegate: blockDelegate,
            objectSettinsViewModel: objectSettinsViewModel,
            detailsViewModel: detailsViewModel,
            selectionHandler: selectionHandler,
            router: router,
            modelsHolder: modelsHolder,
            blockBuilder: blocksConverter,
            blockActionHandler: editorBlockActionHandler,
            wholeBlockMarkupViewModel: wholeBlockMarkupViewModel
        )
    }
}
