import Foundation
import SwiftUI
import Combine

@MainActor
protocol HomeWidgetsCoordinatorProtocol {
    func startFlow() -> AnyView
    func flowStarted()
    func createAndShowNewPage()
}

@MainActor
final class HomeWidgetsCoordinator: HomeWidgetsCoordinatorProtocol, HomeWidgetsModuleOutput,
                                    CommonWidgetModuleOutput, HomeBottomPanelModuleOutput {
    
    // MARK: - DI
    
    private let homeWidgetsModuleAssembly: HomeWidgetsModuleAssemblyProtocol
    private let accountManager: AccountManagerProtocol
    private let navigationContext: NavigationContextProtocol
    private let createWidgetCoordinator: CreateWidgetCoordinatorProtocol
    private let editorBrowserCoordinator: EditorBrowserCoordinatorProtocol
    private let searchModuleAssembly: SearchModuleAssemblyProtocol
    private let settingsCoordinator: SettingsCoordinatorProtocol
    private let newSearchModuleAssembly: NewSearchModuleAssemblyProtocol
    private let dashboardService: DashboardServiceProtocol
    private let dashboardAlertsAssembly: DashboardAlertsAssemblyProtocol
    private let quickActionsStorage: QuickActionsStorage
    private let widgetTypeModuleAssembly: WidgetTypeModuleAssemblyProtocol
    
    // MARK: - State
    
    private var subscriptions = [AnyCancellable]()
    
    init(
        homeWidgetsModuleAssembly: HomeWidgetsModuleAssemblyProtocol,
        accountManager: AccountManagerProtocol,
        navigationContext: NavigationContextProtocol,
        createWidgetCoordinator: CreateWidgetCoordinatorProtocol,
        editorBrowserCoordinator: EditorBrowserCoordinatorProtocol,
        searchModuleAssembly: SearchModuleAssemblyProtocol,
        settingsCoordinator: SettingsCoordinatorProtocol,
        newSearchModuleAssembly: NewSearchModuleAssemblyProtocol,
        dashboardService: DashboardServiceProtocol,
        dashboardAlertsAssembly: DashboardAlertsAssemblyProtocol,
        quickActionsStorage: QuickActionsStorage,
        widgetTypeModuleAssembly: WidgetTypeModuleAssemblyProtocol
    ) {
        self.homeWidgetsModuleAssembly = homeWidgetsModuleAssembly
        self.accountManager = accountManager
        self.navigationContext = navigationContext
        self.createWidgetCoordinator = createWidgetCoordinator
        self.editorBrowserCoordinator = editorBrowserCoordinator
        self.searchModuleAssembly = searchModuleAssembly
        self.settingsCoordinator = settingsCoordinator
        self.newSearchModuleAssembly = newSearchModuleAssembly
        self.dashboardService = dashboardService
        self.dashboardAlertsAssembly = dashboardAlertsAssembly
        self.quickActionsStorage = quickActionsStorage
        self.widgetTypeModuleAssembly = widgetTypeModuleAssembly
    }
    
    // MARK: - HomeWidgetsCoordinatorProtocol
    
    func startFlow() -> AnyView {
        return homeWidgetsModuleAssembly.make(
            widgetObjectId: accountManager.account.info.widgetsId,
            output: self,
            widgetOutput: self,
            bottomPanelOutput: self
        )
    }
    
    func flowStarted() {
        
        subscriptions.removeAll()
        quickActionsStorage.$action.sink { [weak self] action in
            switch action {
            case .newNote:
                self?.createAndShowNewPage()
                self?.quickActionsStorage.action = nil
            case .none:
                break
            }
        }
        .store(in: &subscriptions)
        
        if let data = UserDefaultsConfig.lastOpenedPage {
            UserDefaultsConfig.lastOpenedPage = nil
            openObject(screenData: data)
            return
        }
        
        if UserDefaultsConfig.showKeychainAlert {
            UserDefaultsConfig.showKeychainAlert = false
            let module = dashboardAlertsAssembly.makeKeychainRemind(context: .signup)
            navigationContext.present(module)
        }
    }
    
    func createAndShowNewPage() {
        Task { @MainActor in
            guard let details = try? await dashboardService.createNewPage() else { return }
            AnytypeAnalytics.instance().logCreateObject(objectType: details.analyticsType, route: .navigation, view: .home)
            openObject(screenData: details.editorScreenData())
        }
    }
    
    // MARK: - HomeWidgetsModuleOutput
    
    // MARK: - CommonWidgetModuleOutput
        
    func onObjectSelected(screenData: EditorScreenData) {
        openObject(screenData: screenData)
    }
    
    func onChangeSource(widgetId: String, context: AnalyticsWidgetContext) {
        let module = newSearchModuleAssembly.widgetChangeSourceSearchModule(
            widgetObjectId: accountManager.account.info.widgetsId,
            widgetId: widgetId,
            context: context
        ) { [weak self] in
            self?.navigationContext.dismissAllPresented()
        }
        navigationContext.present(module)
    }

    func onChangeWidgetType(widgetId: String, context: AnalyticsWidgetContext) {
        let module = widgetTypeModuleAssembly.makeChangeType(
            widgetObjectId: accountManager.account.info.widgetsId,
            widgetId: widgetId,
            context: context
        ) { [weak self] in
            self?.navigationContext.dismissAllPresented()
        }
        navigationContext.present(module)
    }
    
    func onAddBelowWidget(widgetId: String, context: AnalyticsWidgetContext) {
        createWidgetCoordinator.startFlow(widgetObjectId: accountManager.account.info.widgetsId, position: .below(widgetId: widgetId), context: context)
    }
    
    // MARK: - HomeBottomPanelModuleOutput
    
    func onCreateWidgetSelected(context: AnalyticsWidgetContext) {
        createWidgetCoordinator.startFlow(widgetObjectId: accountManager.account.info.widgetsId, position: .end, context: context)
    }
    
    func onSearchSelected() {
        AnytypeAnalytics.instance().logScreenSearch()
        let module = searchModuleAssembly.makeObjectSearch(title: nil, onSelect: { [weak self] data in
            AnytypeAnalytics.instance().logSearchResult()
            self?.navigationContext.dismissAllPresented()
            self?.openObject(screenData: data.editorScreenData)
        })
        navigationContext.present(module)
    }
    
    func onCreateObjectSelected(screenData: EditorScreenData) {
        openObject(screenData: screenData)
    }
    
    func onSettingsSelected() {
        settingsCoordinator.startFlow()
    }
    
    // MARK: - Private
    
    private func openObject(screenData: EditorScreenData) {
        editorBrowserCoordinator.startFlow(data: screenData)
    }
}
