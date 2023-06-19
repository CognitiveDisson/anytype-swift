import Foundation
import Services
import SwiftProtobuf
import UIKit
import AnytypeCore
import Combine

final class RelationsListViewModel: ObservableObject {
        
    @Published private(set) var navigationBarButtonsDisabled: Bool = false
    @Published var sections = [RelationsSection]()
    
    // MARK: - Private variables
    
    private let sectionsBuilder = RelationsSectionBuilder()
    private let relationsService: RelationsServiceProtocol
    
    private weak var output: RelationsListModuleOutput?
    
    // MARK: - Initializers
    
    init(
        document: BaseDocumentProtocol,
        relationsService: RelationsServiceProtocol,
        output: RelationsListModuleOutput
    ) {
        self.relationsService = relationsService
        self.output = output
        
        document.parsedRelationsPublisher
            .map { [sectionsBuilder] relations in
                sectionsBuilder.buildSections(
                    from: relations,
                    objectTypeName: document.details?.objectType.name ?? ""
                )
            }
            .assign(to: &$sections)
        
        document.isLockedPublisher.assign(to: &$navigationBarButtonsDisabled)
    }
    
}

// MARK: - Internal functions

extension RelationsListViewModel {
    
    func changeRelationFeaturedState(relation: Relation, addedToObject: Bool) {
        if !addedToObject {
            if relationsService.addRelations(relationKeys: [relation.key]) {
                changeRelationFeaturedState(relation: relation)
            }
        } else {
            changeRelationFeaturedState(relation: relation)
        }
    }
    
    private func changeRelationFeaturedState(relation: Relation) {
        if relation.isFeatured {
            relationsService.removeFeaturedRelation(relationKey: relation.key)
        } else {
            relationsService.addFeaturedRelation(relationKey: relation.key)
        }
        UISelectionFeedbackGenerator().selectionChanged()
    }
    
    func handleTapOnRelation(relation: Relation) {
        output?.editRelationValueAction(relationKey: relation.key)
    }
    
    func removeRelation(relation: Relation) {
        relationsService.removeRelation(relationKey: relation.key)
    }
    
    func showAddNewRelationView() {
        output?.addNewRelationAction()
    }
    
}
