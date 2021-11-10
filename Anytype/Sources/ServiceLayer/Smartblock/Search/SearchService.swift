import ProtobufMessages
import Combine
import BlocksModels

protocol SearchServiceProtocol {
    func search(text: String) -> [SearchData]?
    func searchArchivedPages() -> [SearchData]?
    func searchHistoryPages() -> [SearchData]?
    func searchSharedPages() -> [SearchData]?
    func searchSets() -> [SearchData]?
    func searchObjectTypes(text: String, filteringTypeUrl: String?) -> [SearchData]?
}

final class SearchService: ObservableObject, SearchServiceProtocol {
    
    // MARK: - Private variables
    
    private var subscriptions = [AnyCancellable]()
    
    // MARK: - SearchServiceProtocol
    
    func search(text: String) -> [SearchData]? {
        let sort = SearchHelper.sort(
            relation: RelationKey.lastOpenedDate,
            type: .desc
        )
        
        let filters = buildFilters(
            isArchived: false,
            typeUrls: ObjectTypeProvider.supportedTypeUrls
        )
        
        return makeRequest(
            filters: filters, sorts: [sort], fullText: text,
            offset: 0, limit: 100, objectTypeFilter: [], keys: []
        )
    }
    
    func searchArchivedPages() -> [SearchData]? {
        let sort = SearchHelper.sort(
            relation: RelationKey.lastModifiedDate,
            type: .desc
        )
        
        let filters = buildFilters(
            isArchived: true,
            typeUrls: ObjectTypeProvider.supportedTypeUrls
        )
        
        return makeRequest(
            filters: filters,
            sorts: [sort],
            fullText: "",
            offset: 0,
            limit: 100,
            objectTypeFilter: [],
            keys: []
        )
    }
    
    func searchHistoryPages() -> [SearchData]? {
        let sort = SearchHelper.sort(
            relation: RelationKey.lastModifiedDate,
            type: .desc
        )
        let filters = buildFilters(
            isArchived: false,
            typeUrls: ObjectTypeProvider.supportedTypeUrls
        )
        
        return makeRequest(
            filters: filters,
            sorts: [sort],
            fullText: "",
            offset: 0,
            limit: 100,
            objectTypeFilter: [],
            keys: []
        )
    }
    
    func searchSharedPages() -> [SearchData]? {
        let sort = SearchHelper.sort(
            relation: RelationKey.lastModifiedDate,
            type: .desc
        )
        var filters = buildFilters(isArchived: false, typeUrls: ObjectTypeProvider.supportedTypeUrls)
        filters.append(contentsOf: [SearchHelper.sharedObjectsFilter()])
        
        return makeRequest(
            filters: filters,
            sorts: [sort],
            fullText: "",
            offset: 0,
            limit: 100,
            objectTypeFilter: [],
            keys: []
        )
    }
    
    func searchSets() -> [SearchData]? {
        let sort = SearchHelper.sort(
            relation: RelationKey.lastOpenedDate,
            type: .desc
        )
        let filters = buildFilters(
            isArchived: false,
            typeUrls: ObjectTypeProvider.supportedTypeUrls
        )
        
        return makeRequest(
            filters: filters,
            sorts: [sort],
            fullText: "",
            offset: 0,
            limit: 100,
            objectTypeFilter: [],
            keys: []
        )
    }
    
    func searchObjectTypes(text: String, filteringTypeUrl: String? = nil) -> [SearchData]? {
        let sort = SearchHelper.sort(
            relation: RelationKey.name,
            type: .asc
        )
        var filters = [
            SearchHelper.isArchivedFilter(isArchived: false),
            SearchHelper.supportedObjectTypeUrlsFilter(
                ObjectTypeProvider.supportedTypeUrls
            ),
            SearchHelper.excludedObjectTypeUrlFilter(ObjectTemplateType.BundledType.set.rawValue)
        ]
        filteringTypeUrl.map { filters.append(SearchHelper.excludedObjectTypeUrlFilter($0)) }


        let result = makeRequest(
            filters: filters, sorts: [sort], fullText: text,
            offset: 0, limit: 100, objectTypeFilter: [], keys: []
        )
        
        return result?.reordered(
            by: [
                ObjectTemplateType.BundledType.note.rawValue,
                ObjectTemplateType.BundledType.page.rawValue
            ]
        ) { $0.id }
    }
    
    private func makeRequest(
        filters: [Anytype_Model_Block.Content.Dataview.Filter],
        sorts: [Anytype_Model_Block.Content.Dataview.Sort],
        fullText: String,
        offset: Int32,
        limit: Int32,
        objectTypeFilter: [String],
        keys: [String]
    ) -> [SearchData]? {
        guard let response = Anytype_Rpc.Object.Search.Service.invoke(
            filters: filters,
            sorts: sorts,
            fullText: fullText,
            offset: offset,
            limit: limit,
            objectTypeFilter: objectTypeFilter,
            keys: keys,
            ignoreWorkspace: false
        ).getValue() else { return nil }
            
        let details: [SearchData] = response.records.compactMap { search in
            let idValue = search.fields["id"]
            let idString = idValue?.unwrapedListValue.stringValue
            
            guard let id = idString, id.isNotEmpty else { return nil }
            
            return SearchData(id: id, values: search.fields)
        }
            
        return details
    }
    
    private func buildFilters(isArchived: Bool, typeUrls: [String]) -> [Anytype_Model_Block.Content.Dataview.Filter] {
        [
            SearchHelper.notHiddenFilter(),
            
            SearchHelper.isArchivedFilter(isArchived: isArchived),
            
            SearchHelper.typeFilter(typeUrls: typeUrls)
        ]
    }
    
}
