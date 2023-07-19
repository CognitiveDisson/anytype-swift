import UIKit
import Services
import SwiftUI

protocol TemplateSelectionCoordinatorProtocol: AnyObject {
    @MainActor
    func showTemplatesSelection(
        setDocument: SetDocumentProtocol,
        dataview: DataviewView,
        onTemplateSelection: @escaping (BlockId) -> ()
    )
}

final class TemplateSelectionCoordinator: TemplateSelectionCoordinatorProtocol {
    private let navigationContext: NavigationContextProtocol
    private let templatesModuleAssembly: TemplateModulesAssembly
    private let editorAssembly: EditorAssembly
    
    init(
        navigationContext: NavigationContextProtocol,
        templatesModulesAssembly: TemplateModulesAssembly,
        editorAssembly: EditorAssembly
    ) {
        self.navigationContext = navigationContext
        self.templatesModuleAssembly = templatesModulesAssembly
        self.editorAssembly = editorAssembly
    }
    
    @MainActor
    func showTemplatesSelection(
        setDocument: SetDocumentProtocol,
        dataview: DataviewView,
        onTemplateSelection: @escaping (BlockId) -> ()
    ) {
        let view = templatesModuleAssembly.buildTemplateSelection(
            setDocument: setDocument,
            dataView: dataview,
            onTemplateSelection: { [weak navigationContext] templateId in
                navigationContext?.dismissTopPresented(animated: true) {
                    onTemplateSelection(templateId)
                }
            }
        )
        
        view.model.templateOptionsHandler = { [weak self] closure in
            self?.showTemplateOptions(handler: closure)
        }
        
        view.model.templateEditingHandler = { [weak self] blockId in
            self?.showTemplateEditing(blockId: blockId)
        }
        
        let viewModel = AnytypePopupViewModel(contentView: view, popupLayout: .intrinsic)
        let popup = AnytypePopup(
            viewModel: viewModel,
            floatingPanelStyle: true,
            configuration: .init(isGrabberVisible: false, dismissOnBackdropView: true, skipThroughGestures: false),
            onDismiss: { }
        )
        navigationContext.present(popup)
    }
    
    private func showTemplateOptions(handler: @escaping (TemplateOptionAction) -> Void) {
        let templateActions = TemplateOptionAction.allCases.map { option in
            UIAlertAction(
                title: option.title,
                style: option.style
            ) { _ in
                handler(option)
            }
        }
        let cancelAction = UIAlertAction(title: Loc.cancel, style: .cancel)
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        templateActions.forEach(alertController.addAction(_:))
        alertController.addAction(cancelAction)
        
        navigationContext.present(alertController)
    }
    
    private func showTemplateEditing(blockId: BlockId) {
        let editorPage = editorAssembly.buildEditorModule(
            browser: nil,
            data: .page(.init(objectId: blockId, isSupportedForEdit: true, isOpenedForPreview: false))
        )
        
        
        let editorView = EditorView(viewController: editorPage.vc)
        let editingTemplateView = EditingTemplateView(editorView: editorView.eraseToAnyView())
        
        
        navigationContext.present(editingTemplateView)
//        navigationContext.dismissAllPresented(animated: true) { [weak navigationContext] in
//            
//        }
    }
}

struct EditorView: UIViewControllerRepresentable {
    let viewController: UIViewController
    
    init(viewController: UIViewController) {
        self.viewController = viewController
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
}
