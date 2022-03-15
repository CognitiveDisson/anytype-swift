import SwiftUI
import BlocksModels

final class ObjectSettingAssembly {
    func settingsPopup(document: BaseDocumentProtocol, router: EditorRouterProtocol) -> UIViewController {
        let viewModel = ObjectSettingsViewModel(
            document: document,
            objectDetailsService: ServiceLocator.shared.detailsService(objectId: document.objectId),
            router: router
        )
        return AnytypePopup(viewModel: viewModel, insetted: true)
    }
    
    func coverPicker(document: BaseDocumentProtocol) -> UIViewController {
        let viewModel = ObjectCoverPickerViewModel(
            objectId: document.objectId,
            fileService: ServiceLocator.shared.fileService(),
            detailsService: ServiceLocator.shared.detailsService(objectId: document.objectId)
        )
        
        let controller = UIHostingController(
            rootView: ObjectCoverPicker(viewModel: viewModel)
        )
        
        controller.rootView.onDismiss = { [weak controller] in
            controller?.dismiss(animated: true)
        }
        
        return controller
    }
    
    func iconPicker(document: BaseDocumentProtocol) -> UIViewController {
        let viewModel = ObjectIconPickerViewModel(
            document: document,
            fileService: ServiceLocator.shared.fileService(),
            detailsService: ServiceLocator.shared.detailsService(objectId: document.objectId)
        )
        
        let controller = UIHostingController(
            rootView: ObjectIconPicker(viewModel: viewModel)
        )
        
        controller.rootView.dismissHandler = DismissHandler(
            onDismiss:  { [weak controller] in
                controller?.dismiss(animated: true)
            }
        )
        
        return controller
    }
    
    func layoutPicker(document: BaseDocumentProtocol) -> UIViewController {
        let viewModel = ObjectLayoutPickerViewModel(
            document: document,
            detailsService: ServiceLocator.shared.detailsService(objectId: document.objectId)
        )
        return AnytypePopup(viewModel: viewModel)
    }
}
