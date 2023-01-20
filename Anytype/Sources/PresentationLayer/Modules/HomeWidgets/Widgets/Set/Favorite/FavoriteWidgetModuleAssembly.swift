import Foundation
import SwiftUI

protocol FavoriteWidgetModuleAssemblyProtocol {
    @MainActor
    func make(widgetBlockId: String, widgetObject: HomeWidgetsObjectProtocol, output: CommonWidgetModuleOutput?) -> AnyView
}

final class FavoriteWidgetModuleAssembly: FavoriteWidgetModuleAssemblyProtocol {
    
    private let serviceLocator: ServiceLocator
    private let uiHelpersDI: UIHelpersDIProtocol
    
    init(serviceLocator: ServiceLocator, uiHelpersDI: UIHelpersDIProtocol) {
        self.serviceLocator = serviceLocator
        self.uiHelpersDI = uiHelpersDI
    }
    
    // MARK: - FavoriteWidgetModuleAssemblyProtocol
    
    @MainActor
    func make(widgetBlockId: String, widgetObject: HomeWidgetsObjectProtocol, output: CommonWidgetModuleOutput?) -> AnyView {
        
        let model = FavoriteWidgetViewModel(
            widgetBlockId: widgetBlockId,
            widgetObject: widgetObject,
            output: output
        )
        return SetWidgetView(model: model).eraseToAnyView()
    }
}