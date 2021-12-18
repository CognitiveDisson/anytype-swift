import ProtobufMessages
import SwiftProtobuf
import BlocksModels

final class PageService {
    func createPage(name: String) -> BlockId? {
        let details = Google_Protobuf_Struct(
            fields: [
                BundledRelationKey.name.rawValue: name.protobufValue,
                BundledRelationKey.type.rawValue: ObjectTypeProvider.defaultObjectType.url.protobufValue
            ]
        )
        
        guard let response = Anytype_Rpc.Page.Create.Service.invoke(details: details).getValue(domain: .pageService) else {
            return nil
        }
        
        EventsBunch(event: response.event).send()
        return response.pageID
    }
}
