import SwiftUI
import Services
import Combine

final class EditorBrowserAssembly {
    
    private let coordinatorsDI: CoordinatorsDIProtocol
    private let serviceLocator: ServiceLocator
    
    init(coordinatorsDI: CoordinatorsDIProtocol, serviceLocator: ServiceLocator) {
        self.coordinatorsDI = coordinatorsDI
        self.serviceLocator = serviceLocator
    }
    
    func buildEditorBrowser(
        data: EditorScreenData,
        router: EditorPageOpenRouterProtocol? = nil,
        addRoot: Bool = true
    ) -> EditorBrowserController {
        let browser = EditorBrowserController(dashboardService: serviceLocator.dashboardService())

        if addRoot {
            // Legacy logic. Delete with homeWidgets toggle
            let (page, moduleRouter) = coordinatorsDI.editor()
                .buildEditorModule(browser: browser, data: data, widgetListOutput: nil)
            
            browser.childNavigation = navigationStack(rootPage: page)
            browser.router = router ?? moduleRouter
        } else {
            browser.childNavigation = navigationStack(rootPage: nil)
            browser.router = router
        }
        
        browser.setup()
        
        return browser
    }
    
    private func navigationStack(rootPage: UIViewController?) -> UINavigationController {
        let navigationController = rootPage.map { UINavigationController(rootViewController: $0) } ?? UINavigationController()

        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        navigationController.modifyBarAppearance(navBarAppearance)

        return navigationController
    }
}
