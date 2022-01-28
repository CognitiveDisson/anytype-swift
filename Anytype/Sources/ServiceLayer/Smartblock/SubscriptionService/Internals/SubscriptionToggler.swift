import ProtobufMessages
import BlocksModels
import AnytypeCore

typealias SubscriptionTogglerResult = (details: [ObjectDetails], pageCount: Int64)

protocol SubscriptionTogglerProtocol {
    func startSubscription(data: SubscriptionData) -> SubscriptionTogglerResult?
    func stopSubscription(id: SubscriptionId)
}

final class SubscriptionToggler: SubscriptionTogglerProtocol {
    func startSubscription(data: SubscriptionData) -> SubscriptionTogglerResult? {
        switch data {
        case .historyTab:
            return startHistoryTabSubscription()
        case .archiveTab:
            return startArchiveTabSubscription()
        case .sharedTab:
            return startSharedTabSubscription()
        case .setsTab:
            return startSetsTabSubscription()
        case .profile(id: let profileId):
            return startProfileSubscription(blockId: profileId)
        case let .set(data):
            return startSetSubscription(data: data)
        }
    }
    
    func stopSubscription(id: SubscriptionId) {
        _ = Anytype_Rpc.Object.SearchUnsubscribe.Service.invoke(subIds: [id.rawValue])
    }
    
    // MARK: - Private
    private func startProfileSubscription(blockId: BlockId) -> SubscriptionTogglerResult? {
        let response = Anytype_Rpc.Object.IdsSubscribe.Service.invoke(
            subID: SubscriptionId.profile.rawValue,
            ids: [blockId],
            keys: [BundledRelationKey.id.rawValue, BundledRelationKey.name.rawValue, BundledRelationKey.iconImage.rawValue],
            ignoreWorkspace: ""
        )
        
        guard let result = response.getValue(domain: .subscriptionService) else {
            return nil
        }
        
        return (details: result.records.asDetais, pageCount: 1)
    }
    
    private func startSetSubscription(data: SetSubsriptionData) -> SubscriptionTogglerResult? {
        var keys = data.relations.map { $0.key }
        keys.append(contentsOf: homeDetailsKeys.map { $0.rawValue} )
        
        return makeRequest(subId: .set, filters: data.filters, sorts: data.sorts, source: data.source, keys: keys, pageNumber: data.currentPage)
    }
    
    private func startHistoryTabSubscription() -> SubscriptionTogglerResult? {
        let sort = SearchHelper.sort(
            relation: BundledRelationKey.lastModifiedDate,
            type: .desc
        )
        var filters = buildFilters(
            isArchived: false,
            typeUrls: ObjectTypeProvider.supportedTypeUrls
        )
        filters.append(SearchHelper.lastOpenedDateNotNilFilter())
        
        return makeRequest(subId: .historyTab, filters: filters, sorts: [sort])
    }
    
    private func startArchiveTabSubscription() -> SubscriptionTogglerResult? {
        let sort = SearchHelper.sort(
            relation: BundledRelationKey.lastModifiedDate,
            type: .desc
        )
        
        let filters = buildFilters(
            isArchived: true,
            typeUrls: ObjectTypeProvider.supportedTypeUrls
        )
        
        return makeRequest(subId: .archiveTab, filters: filters, sorts: [sort])
    }
    
    private func startSharedTabSubscription() -> SubscriptionTogglerResult? {
        let sort = SearchHelper.sort(
            relation: BundledRelationKey.lastModifiedDate,
            type: .desc
        )
        var filters = buildFilters(isArchived: false, typeUrls: ObjectTypeProvider.supportedTypeUrls)
        filters.append(contentsOf: SearchHelper.sharedObjectsFilters())
        
        return makeRequest(subId: .sharedTab, filters: filters, sorts: [sort])
    }
    
    private func startSetsTabSubscription() -> SubscriptionTogglerResult? {
        let sort = SearchHelper.sort(
            relation: BundledRelationKey.lastModifiedDate,
            type: .desc
        )
        let filters = buildFilters(
            isArchived: false,
            typeUrls: ObjectTypeProvider.objectTypes(smartblockTypes: [.set]).map { $0.url }
        )
        
        return makeRequest(subId: .setsTab, filters: filters, sorts: [sort])
    }

    private let homeDetailsKeys: [BundledRelationKey] = [
        .id, .iconEmoji, .iconImage, .name, .snippet, .description, .type, .layout, .isArchived, .isDeleted, .done
    ]
    private func makeRequest(
        subId: SubscriptionId,
        filters: [DataviewFilter],
        sorts: [DataviewSort],
        source: [String] = [],
        keys: [String]? = nil,
        pageNumber: Int64 = 1
    ) -> SubscriptionTogglerResult? {
        let offset = Int64(pageNumber - 1) * Constants.numberOfRowsPerPageInSubscriptions
        let response = Anytype_Rpc.Object.SearchSubscribe.Service.invoke(
            subID: subId.rawValue,
            filters: filters,
            sorts: sorts,
            fullText: "",
            limit: Int32(Constants.numberOfRowsPerPageInSubscriptions),
            offset: Int32(offset),
            keys: keys ?? homeDetailsKeys.map { $0.rawValue },
            afterID: "",
            beforeID: "",
            source: source,
            ignoreWorkspace: ""
        )
        
        guard let result = response.getValue(domain: .subscriptionService) else {
            return nil
        }
        
        // Returns 1 if count < numberOfRowsPerPageInSubscriptions
        // And returns 1 if count = numberOfRowsPerPageInSubscriptions
        let closestNumberToRowsPerPage = Int64(Constants.numberOfRowsPerPageInSubscriptions) - 1
        let pageCount = (result.counters.total + closestNumberToRowsPerPage) / Int64(Constants.numberOfRowsPerPageInSubscriptions)
        
        return (details: result.records.asDetais, pageCount: pageCount)
    }
    
    private func buildFilters(isArchived: Bool, typeUrls: [String]) -> [DataviewFilter] {
        [
            SearchHelper.notHiddenFilter(),
            
            SearchHelper.isArchivedFilter(isArchived: isArchived),
            
            SearchHelper.typeFilter(typeUrls: typeUrls)
        ]
    }
}