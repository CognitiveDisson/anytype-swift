import Foundation
import SwiftUI

final class HomeBottomPanelProvider: HomeSubmoduleProviderProtocol {
    
    private let bottomPanelModuleAssembly: HomeBottomPanelModuleAssemblyProtocol
    private let stateManager: HomeWidgetsStateManagerProtocol
    private weak var output: HomeBottomPanelModuleOutput?
    
    init(
        bottomPanelModuleAssembly: HomeBottomPanelModuleAssemblyProtocol,
        stateManager: HomeWidgetsStateManagerProtocol,
        output: HomeBottomPanelModuleOutput?
    ) {
        self.bottomPanelModuleAssembly = bottomPanelModuleAssembly
        self.stateManager = stateManager
        self.output = output
    }
    
    // MARK: - HomeSubmoduleProviderProtocol
    
    @MainActor
    lazy var view: AnyView = {
        return bottomPanelModuleAssembly.make(stateManager: stateManager, output: output)
    }()
    
    lazy var componentId: String = {
        return UUID().uuidString
    }()
}
