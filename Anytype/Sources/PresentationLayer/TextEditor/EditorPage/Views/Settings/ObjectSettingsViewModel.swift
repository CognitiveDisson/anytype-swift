import Foundation
import Combine
import BlocksModels
import UIKit
import FloatingPanel
import SwiftUI

final class ObjectSettingsViewModel: ObservableObject, Dismissible {
    var onDismiss: () -> Void = {} {
        didSet {
            objectActionsViewModel.dismissSheet = onDismiss
        }
    }
    
    var settings: [ObjectSetting] {
        settingsBuilder.build(details: details, restrictions: objectActionsViewModel.objectRestrictions)
    }
    
    @Published private(set) var details: ObjectDetails = ObjectDetails(id: "", values: [:])
    
    let objectActionsViewModel: ObjectActionsViewModel

    let iconPickerViewModel: ObjectIconPickerViewModel
    let coverPickerViewModel: ObjectCoverPickerViewModel
    let layoutPickerViewModel: ObjectLayoutPickerViewModel
    let relationsViewModel: RelationsListViewModel
    
    private(set) var popupLayout: AnytypePopupLayoutType = .constantHeight(height: 0, floatingPanelStyle: true)
    
    private weak var popup: AnytypePopupProxy?
    private let objectId: String
    private let objectDetailsService: DetailsService
    private let settingsBuilder = ObjectSettingBuilder()
    
    private let onLayoutSettingsTap: (ObjectLayoutPickerViewModel) -> ()
    
    init(
        objectId: String,
        objectDetailsService: DetailsService,
        router: EditorRouterProtocol
    ) {
        self.objectId = objectId
        self.objectDetailsService = objectDetailsService
        
        self.onLayoutSettingsTap = { [weak router] model in
            router?.showLayoutPicker(viewModel: model)
        }
        
        self.iconPickerViewModel = ObjectIconPickerViewModel(
            objectId: objectId,
            fileService: BlockActionsServiceFile(),
            detailsService: objectDetailsService
        )
        self.coverPickerViewModel = ObjectCoverPickerViewModel(
            objectId: objectId,
            fileService: BlockActionsServiceFile(),
            detailsService: objectDetailsService
        )
        
        self.layoutPickerViewModel = ObjectLayoutPickerViewModel(
            detailsService: objectDetailsService
        )
        
        self.relationsViewModel = RelationsListViewModel(
            relationsService: RelationsService(objectId: objectId),
            onValueEditingTap: { [weak router] in
                router?.showRelationValueEditingView(key: $0, source: .object)
            }
        )

        self.objectActionsViewModel = ObjectActionsViewModel(
            objectId: objectId,
            popScreenAction: { [weak router] in
                router?.goBack()
            }
        )
    }
    
    func update(objectRestrictions: ObjectRestrictions, parsedRelations: ParsedRelations) {
        if let details = ObjectDetailsStorage.shared.get(id: objectId) {
            objectActionsViewModel.details = details
            self.details = details
            iconPickerViewModel.details = details
            layoutPickerViewModel.details = details

            relationsViewModel.update(with: parsedRelations)
        }
        objectActionsViewModel.objectRestrictions = objectRestrictions
    }
    
    func showLayoutSettings() {
        onLayoutSettingsTap(layoutPickerViewModel)
    }
    
    func viewDidUpdateHeight(_ height: CGFloat) {
        popupLayout = .constantHeight(height: height, floatingPanelStyle: true)
        popup?.updateLayout(false)
    }
    
}

extension ObjectSettingsViewModel: AnytypePopupViewModelProtocol {
    
    func onPopupInstall(_ popup: AnytypePopupProxy) {
        self.popup = popup
    }
    
    func makeContentView() -> UIViewController {
        UIHostingController(rootView: ObjectSettingsView(viewModel: self))
    }
    
}
