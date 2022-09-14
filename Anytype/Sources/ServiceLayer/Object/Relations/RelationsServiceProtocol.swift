import Foundation
import BlocksModels
import SwiftProtobuf

enum RelationSource {
    case object
    case dataview(contextId: BlockId)
}

protocol RelationsServiceProtocol: AnyObject {
    func addFeaturedRelation(relationKey: String)
    func removeFeaturedRelation(relationKey: String)
    
    func updateRelation(relationKey: String, value: Google_Protobuf_Value)

    func createRelation(relationDetails: RelationDetails) -> Bool
    func addRelation(relationDetails: RelationDetails) -> Bool

    func removeRelation(relationId: String)
    func addRelationOption(source: RelationSource, relationKey: String, optionText: String) -> String?
    func availableRelations() -> [RelationDetails]
}
