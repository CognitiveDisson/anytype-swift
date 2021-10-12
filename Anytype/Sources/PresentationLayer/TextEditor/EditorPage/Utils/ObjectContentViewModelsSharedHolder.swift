import BlocksModels

// We need to share models between several mutating services
// Using reference semantics of ObjectContentViewModelsSharedHolder to share pointer
// To the same models everywhere
final class ObjectContentViewModelsSharedHolder {
    
    let objectId: String
    
    var details: DetailsDataProtocol? = nil
    var models: [BlockViewModelProtocol] = []

    init(objectId: String) {
        self.objectId = objectId
    }
    
    func findModel(beforeBlockId blockId: BlockId) -> BlockDataProvider? {
        guard let modelIndex = models.firstIndex(where: { $0.blockId == blockId }) else {
            return nil
            
        }

        let index = models.index(before: modelIndex)
        guard index >= models.startIndex else {
            return nil
        }
        
        return models[index]
    }
}

extension ObjectContentViewModelsSharedHolder {
    
    func apply(newDetails: DetailsDataProtocol?) {
        guard let newDetails = newDetails else {
            details = nil
            return
        }
        
        guard newDetails.blockId == objectId else { return }
        
        details = newDetails
    }
    
    func apply(newModels: [BlockViewModelProtocol]) {
        let difference = newModels.difference(
            from: models
        ) { $0.hashable == $1.hashable }
        
        
        if !difference.isEmpty, let result = models.applying(difference) {
            models = result
        }
    }
    
}