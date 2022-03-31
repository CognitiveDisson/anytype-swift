import BlocksModels
import SwiftUI

extension Relation {
    
    struct Object: RelationProtocol, Hashable, Identifiable {
        let id: String
        let name: String
        let isFeatured: Bool
        let isEditable: Bool
        let isBundled: Bool
        
        let selectedObjects: [Option]
        let limitObjectTypes: [String]
    }
    
}

extension Relation.Object {

    struct Option: Hashable, Identifiable {
        let id: String
        
        let icon: ObjectIconImage
        let title: String
        let type: String
    }
    
}
