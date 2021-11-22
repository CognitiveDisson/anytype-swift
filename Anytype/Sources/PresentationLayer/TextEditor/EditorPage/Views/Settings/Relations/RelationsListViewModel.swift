import Foundation
import BlocksModels
import SwiftProtobuf
import UIKit

final class RelationsListViewModel: ObservableObject {
    
    // MARK: - Private variables
    
    @Published private(set) var sections: [RelationsSection]
    private let sectionsBuilder = RelationsSectionBuilder()
    private let relationsService: RelationsServiceProtocol = RelationsService()
    
    private let objectId: String
    
    // MARK: - Initializers
    
    init(objectId: String, sections: [RelationsSection] = []) {
        self.objectId = objectId
        self.sections = sections
    }
    
    // MARK: - Internal functions
    
    func update(
        with objectRelationsStorage: ParsedRelations,
        detailsStorage: ObjectDetailsStorageProtocol
    ) {
        self.sections = sectionsBuilder.buildViewModels(featuredRelations: objectRelationsStorage.featuredRelations,
                                                        otherRelations: objectRelationsStorage.otherRelations)
    }
    
    func changeRelationFeaturedState(relationId: String) {
        let relationsRowData: [Relation] = sections.flatMap { $0.relations }
        let relationRowData = relationsRowData.first { $0.id == relationId }
        
        guard let relationRowData = relationRowData else { return }
        
        if relationRowData.isFeatured {
            relationsService.removeFeaturedRelations(objectId: objectId, relationIds: [relationRowData.id])
        } else {
            relationsService.addFeaturedRelations(objectId: objectId, relationIds: [relationRowData.id])
        }
    }
    
    func removeRelation(id: String) {
        relationsService.removeRelation(objectId: objectId, relationId: id)
    }
    
    
}
