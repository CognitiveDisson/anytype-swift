final class IndentationStyleRecursiveData {
    var lastChildCalloutBlocks = [BlockId: MiddlewareColor?]()
    var hightlightedChildBlockIdToClosingIndexes = [BlockId: [Int]]() // [6:  [0]]

    func addClosing(for blockId: BlockId, at index: Int) {
        if var existingIndexes = hightlightedChildBlockIdToClosingIndexes[blockId] {

            existingIndexes.append(index)
            hightlightedChildBlockIdToClosingIndexes[blockId] = existingIndexes
        } else {
            hightlightedChildBlockIdToClosingIndexes[blockId] = [index]
        }
    }
}
