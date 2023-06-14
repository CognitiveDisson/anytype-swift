import Foundation
import ProtobufMessages
import Services
import SwiftProtobuf

final class RelationsService: RelationsServiceProtocol {
    
    private let relationDetailsStorage = ServiceLocator.shared.relationDetailsStorage()
    private let objectId: String
        
    init(objectId: String) {
        self.objectId = objectId
    }
    
    // MARK: - RelationsServiceProtocol
    
    func addFeaturedRelation(relationKey: String) async throws {
        AnytypeAnalytics.instance().logEvent(AnalyticsEventsName.addFeatureRelation)
        _ = try? await ClientCommands.objectRelationAddFeatured(.with {
            $0.contextID = objectId
            $0.relations = [relationKey]
        }).invoke()
    }
    
    func removeFeaturedRelation(relationKey: String) async throws {
        AnytypeAnalytics.instance().logEvent(AnalyticsEventsName.removeFeatureRelation)
        _ = try? await ClientCommands.objectRelationRemoveFeatured(.with {
            $0.contextID = objectId
            $0.relations = [relationKey]
        }).invoke()
    }
    
    func updateRelation(relationKey: String, value: Google_Protobuf_Value) {
        _ = try? ClientCommands.objectSetDetails(.with {
            $0.contextID = objectId
            $0.details = [
                Anytype_Rpc.Object.SetDetails.Detail.with {
                    $0.key = relationKey
                    $0.value = value
                }
            ]
        }).invoke()
    }

    func createRelation(relationDetails: RelationDetails) -> RelationDetails? {
        let result = try? ClientCommands.objectCreateRelation(.with {
            $0.details = relationDetails.asCreateMiddleware
        }).invoke()
        
        guard let result = result,
              addRelations(relationKeys: [result.key]),
              let objectDetails = ObjectDetails(protobufStruct: result.details)
            else { return nil }
        
        return RelationDetails(objectDetails: objectDetails)
    }

    func addRelations(relationsDetails: [RelationDetails]) -> Bool {
        return addRelations(relationKeys: relationsDetails.map(\.key))
    }

    func addRelations(relationKeys: [String]) -> Bool {
        let result = try? ClientCommands.objectRelationAdd(.with {
            $0.contextID = objectId
            $0.relationKeys = relationKeys
        }).invoke()
        
        return result.isNotNil
    }
    
    func removeRelation(relationKey: String) {
        _ = try? ClientCommands.objectRelationDelete(.with {
            $0.contextID = objectId
            $0.relationKeys = [relationKey]
        }).invoke()
        
        AnytypeAnalytics.instance().logEvent(AnalyticsEventsName.deleteRelation)
    }
    
    func addRelationOption(relationKey: String, optionText: String) async throws -> String? {
        let color = MiddlewareColor.allCases.randomElement()?.rawValue ?? MiddlewareColor.default.rawValue
        
        let details = Google_Protobuf_Struct(
            fields: [
                BundledRelationKey.name.rawValue: optionText.protobufValue,
                BundledRelationKey.relationKey.rawValue: relationKey.protobufValue,
                BundledRelationKey.relationOptionColor.rawValue: color.protobufValue
            ]
        )
        
        let optionResult = try? await ClientCommands.objectCreateRelationOption(.with {
            $0.details = details
        }).invoke()
        
        return optionResult?.objectID
    }

    func availableRelations() -> [RelationDetails] {
        relationDetailsStorage.relationsDetails()
    }
}
