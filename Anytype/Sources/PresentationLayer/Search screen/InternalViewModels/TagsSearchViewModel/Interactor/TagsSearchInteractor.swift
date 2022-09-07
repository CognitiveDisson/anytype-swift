import Foundation
import BlocksModels

final class TagsSearchInteractor {
    
    private let allTags: [Relation.Tag.Option] = []
    private let relationKey: String
    private let selectedTagIds: [String]
    private let isPreselectModeAvailable: Bool
    private let searchService = ServiceLocator.shared.searchService()
    
    init(
        relationKey: String,
        selectedTagIds: [String],
        isPreselectModeAvailable: Bool = false
    ) {
        self.relationKey = relationKey
        self.selectedTagIds = selectedTagIds
        self.isPreselectModeAvailable = isPreselectModeAvailable
    }
    
}

extension TagsSearchInteractor {
    
    func search(text: String) -> Result<[Relation.Tag.Option], NewSearchError> {
        #warning("Check me")
        let filteredTags = searchService.searchRelationOptions(
            text: text,
            relationKey: relationKey,
            excludedObjectIds: selectedTagIds)?
            .map { RelationMetadata.Option(details: $0) }
            .map { Relation.Tag.Option(option: $0) } ?? []
        
//        guard text.isNotEmpty else {
//            return .success(availableTags)
//        }
//
//        let filteredTags: [Relation.Tag.Option] = availableTags.filter {
//            guard $0.text.isNotEmpty else { return false }
//
//            return $0.text.lowercased().contains(text.lowercased())
//        }
//
//        if filteredTags.isEmpty {
//            let isSearchedTagSelected = allTags.filter { tag in
//                selectedTagIds.contains { $0 == tag.id }
//            }
//                .contains { $0.text.lowercased() == text.lowercased() }
//
//            return isSearchedTagSelected ?
//                .failure(.alreadySelected(searchText: text)) :
//                .success(filteredTags)
//        }
        
        return .success(filteredTags)
    }
    
    func isCreateButtonAvailable(searchText: String, tags: [Relation.Tag.Option]) -> Bool {
        searchText.isNotEmpty && tags.isEmpty
    }
}
