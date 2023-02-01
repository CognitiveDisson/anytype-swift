import Foundation

extension HomeViewModel {
    static func makeForPreview() -> HomeViewModel {
        return HomeViewModel(
            homeBlockId: UUID().uuidString,
            editorBrowserAssembly: DI.preview.coordinatorsDI.browser(),
            tabsSubsciptionDataBuilder: TabsSubscriptionDataBuilder(accountManager: DI.preview.serviceLocator.accountManager()),
            profileSubsciptionDataBuilder: ProfileSubscriptionDataBuilder(),
            newSearchModuleAssembly: DI.preview.modulesDI.newSearch(),
            windowManager: DI.preview.coordinatorsDI.windowManager(),
            accountManager: DI.preview.serviceLocator.accountManager(),
            middlewareConfigurationProvider: DI.preview.serviceLocator.middlewareConfigurationProvider()
        )
    }
}
