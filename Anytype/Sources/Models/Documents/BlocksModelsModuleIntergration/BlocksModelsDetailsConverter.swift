import Foundation
import SwiftProtobuf
import ProtobufMessages
import Combine
import os
import BlocksModels
import AnytypeCore

private extension LoggerCategory {
    static let blocksModelsParser: Self = "BlocksModelsParser"
}

/// Top converter which convert all details to and from protobuf.
enum BlocksModelsDetailsConverter {
    static func asMiddleware(models: [DetailsKind: DetailsEntry<AnyHashable>]) -> [Anytype_Rpc.Block.Set.Details.Detail] {
        models.compactMap { row in
            Anytype_Rpc.Block.Set.Details.Detail.converted(
                kind: row.key,
                entry: row.value
            )
        }
    }
    
    static func asModel(details: [Anytype_Rpc.Block.Set.Details.Detail]) -> [DetailsKind:  DetailsEntry<AnyHashable>] {
        details.asModel()
    }
    
    static func asModel(details: [Anytype_Event.Object.Details.Amend.KeyValue]) -> [DetailsKind: DetailsEntry<AnyHashable>] {
        details.asModel()
    }
}

private extension Anytype_Rpc.Block.Set.Details.Detail {

    static func converted(kind: DetailsKind, entry: DetailsEntry<AnyHashable>) -> Self? {
        let protobufValue: Google_Protobuf_Value? = {
            if let string = entry.value as? String {
                return Google_Protobuf_Value(stringValue: string)
            }
            
            if let coverType = entry.value as? CoverType {
                return Google_Protobuf_Value(
                    numberValue: Double(coverType.rawValue)
                )
            }
            
            if let layout = entry.value as? DetailsLayout {
                return Google_Protobuf_Value(
                    numberValue: Double(layout.rawValue)
                )
            }
            
            anytypeAssertionFailure("Implement converter from \(entry.value) to `Google_Protobuf_Value`")
            return nil
        }()
        
        guard let value = protobufValue else { return nil }
        
        return Anytype_Rpc.Block.Set.Details.Detail(
            key: kind.rawValue,
            value: value
        )
    }
    
}

private extension Array where Element == Anytype_Rpc.Block.Set.Details.Detail {
    
    func asModel() -> [DetailsKind: DetailsEntry<AnyHashable>] {
        let details = self.reduce([String: Google_Protobuf_Value]()) { (dict, detail) -> [String: Google_Protobuf_Value] in
            var dict = dict
            dict[detail.key] = detail.value
            return dict
        }
        
        return DetailsEntryConverter.convert(details: details)
    }
    
}

private extension Array where Element == Anytype_Event.Object.Details.Amend.KeyValue {
    
    func asModel() -> [DetailsKind: DetailsEntry<AnyHashable>] {
        let details = self.reduce([String: Google_Protobuf_Value]()) { (dict, detail) -> [String: Google_Protobuf_Value] in
            var dict = dict
            dict[detail.key] = detail.value
            return dict
        }
        
        return DetailsEntryConverter.convert(details: details)
    }
}
