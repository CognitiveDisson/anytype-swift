import Foundation
import BlocksModels
import Combine

@MainActor
final class FavoriteWidgetViewModel: ListWidgetViewModelProtocol, ObservableObject {
    
    private enum Constants {
        static let maxItems = 3
    }
    
    // MARK: - DI
    private let widgetBlockId: BlockId
    private let widgetObject: HomeWidgetsObjectProtocol
    private let accountManager: AccountManager
    private let favoriteSubscriptionService: FavoriteSubscriptionServiceProtocol
    private weak var output: CommonWidgetModuleOutput?
    
    // MARK: - State
    private var document: BaseDocumentProtocol
    private var rowDetails: [ObjectDetails] = []
    
    @Published private(set) var name: String = Loc.favorites
    @Published var isExpanded: Bool = true
    @Published private(set) var headerItems: [ListWidgetHeaderItem.Model] = []
    @Published private(set) var rows: [ListWidgetRow.Model] = []
    var minimimRowsCount: Int { Constants.maxItems }
    @Published var count: String? = nil
    
    init(
        widgetBlockId: BlockId,
        widgetObject: HomeWidgetsObjectProtocol,
        accountManager: AccountManager,
        favoriteSubscriptionService: FavoriteSubscriptionServiceProtocol,
        output: CommonWidgetModuleOutput?
    ) {
        self.widgetBlockId = widgetBlockId
        self.widgetObject = widgetObject
        self.accountManager = accountManager
        self.favoriteSubscriptionService = favoriteSubscriptionService
        self.output = output
        self.document = BaseDocument(objectId: accountManager.account.info.homeObjectID)
    }
    
    // MARK: - ListWidgetViewModelProtocol
    
    func onAppear() {
        setupAllSubscriptions()
    }

    func onDisappear() {
        Task { @MainActor [weak self] in
            try? await self?.document.close()
            self?.favoriteSubscriptionService.stopSubscription()
        }
    }
    
    func onDeleteWidgetTap() {
       // TODO: Add configuration for context menu
    }
    
    // MARK: - Private
    
    private func setupAllSubscriptions() {
        Task { @MainActor [weak self, document] in
            try? await document.open()
            self?.favoriteSubscriptionService.startSubscription(
                homeDocument: document,
                objectLimit: Constants.maxItems,
                update: { details, count in
                    self?.rowDetails = details
                    self?.count = "\(count)"
                    self?.updateViewState()
                }
            )
        }
    }
    
    private func updateViewState() {
        rows = rowDetails.map { details in
            ListWidgetRow.Model(
                details: details,
                onTap: { [weak self] in
                    self?.output?.onObjectSelected(screenData: $0)
                }
            )
        }
    }
}