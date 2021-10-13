import Foundation
import Combine
import AnytypeCore

final class BlockContainer: BlockContainerModelProtocol {
    var rootId: BlockId?
    private var models = [BlockId: BlockModelProtocol]()
    
    func children(of id: BlockId) -> [BlockId] {
        guard let value = models[id] else {
            return []
        }
        
        return value.information.childrenIds
    }

    func model(id: BlockId) -> BlockModelProtocol? {
        models[id]
    }

    func remove(_ id: BlockId) {
        // go to parent and remove this block from a parent.
        if let parentId = model(id: id)?.parent,
           var parent = models[parentId.information.id] {
            var information = parent.information
            information.childrenIds = information.childrenIds.filter {$0 != id}
            parent.information = information
        }
        
        if let block = self.model(id: id) {
            models.removeValue(forKey: id)
            block.information.childrenIds.forEach(self.remove(_:))
        }
    }

    func add(_ block: BlockModelProtocol) {
        var block = block
        block.container = self
        
        if models[block.information.id] != nil {
            anytypeAssertionFailure("We shouldn't replace block by add operation. Skipping...")
            return
        }
        models[block.information.id] = block
    }

    private func insert(childId: BlockId, parentId: BlockId, at index: Int) {
        guard var parentModel = model(id: parentId) else {
            anytypeAssertionFailure("I can't find parent with id: \(parentId)")
            return
        }
        
        guard var childModel = self.model(id: childId) else {
            anytypeAssertionFailure("I can't find child with id: \(childId)")
            return
        }
        
        var childrenIds = parentModel.information.childrenIds
        childrenIds.insert(childId, at: index)
        parentModel.information.childrenIds = childrenIds
        
        /// And now set parent
        childModel.parent = parentModel
    }

    func add(child: BlockId, beforeChild: BlockId) {
        /// First, we must find parent of beforeChild
        guard let parent = model(id: beforeChild)?.parent, let index = parent.information.childrenIds.firstIndex(of: beforeChild) else {
            anytypeAssertionFailure("I can't find either parent or block itself with id: \(beforeChild)")
            return
        }

        let parentId = parent.information.id
        self.insert(childId: child, parentId: parentId, at: index)
    }

    func add(child: BlockId, afterChild: BlockId) {
        /// First, we must find parent of afterChild
        guard let parent = model(id: afterChild)?.parent, let index = parent.information.childrenIds.firstIndex(of: afterChild) else {
            anytypeAssertionFailure("I can't find either parent or block itself with id: \(afterChild)")
            return
        }

        let parentId = parent.information.id
        let newIndex = index.advanced(by: 1)
        self.insert(childId: child, parentId: parentId, at: newIndex)
    }
    
    // MARK: - Children / Replace
    /// If you would like to change children in parent, you should call this method.
    ///
    /// WARNING:
    /// This method doesn't change parent of previous model.
    /// You should add this functionality later.
    ///
    /// NOTES:
    /// This method also could change only children ids WITHOUT additional condition if block exists or not.
    /// For that, set parameter `shouldSkipGuardAgainstMissingIds` to `true`.
    ///
    /// - Parameters:
    ///   - childrenIds: Associated keys to children entries which parent we would like to change.
    ///   - parentId: An associated key to a parent entry in which we would like to change children.
    ///   - shouldSkipGuardAgainstMissingIds: A flag that notes if we should skip condition about existing entries.
    func replace(
        childrenIds: [BlockId],
        parentId: BlockId,
        shouldSkipGuardAgainstMissingIds: Bool = false
    ) {
        
        guard var parent = model(id: parentId) else {
            anytypeAssertionFailure("I can't find entry with id: \(parentId)")
            return
        }
                
        let existedIds = !shouldSkipGuardAgainstMissingIds ? childrenIds.filter { (childId) in
            if model(id: childId) != nil {
                return true
            }
            else {
                anytypeAssertionFailure("I can't find entry with id: \(parentId)")
                return false
            }
        } : childrenIds

        parent.information.childrenIds = existedIds
        /// TODO: Set children their new parentId if needed?
        /// Actually, yes, but not now.
        /// Do it later.
    }    
}
