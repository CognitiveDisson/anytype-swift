import UIKit

class EditorCollectionView: UICollectionView {
    private(set) var indexPathsForMovingItems = Set<IndexPath>()

    func deselectAllMovingItems() {
        indexPathsForMovingItems.forEach { indexPath in
            setItemIsMoving(false, at: indexPath)
        }

        indexPathsForMovingItems.removeAll()
    }

    func setItemIsMoving(_ isMoving: Bool, at indexPath: IndexPath) {
        if isMoving && !indexPathsForMovingItems.contains(indexPath) {
            indexPathsForMovingItems.insert(indexPath)
        } else if !isMoving && indexPathsForMovingItems.contains(indexPath) {
            indexPathsForMovingItems.remove(indexPath)
        }

        if indexPathsForMovingItems.contains(indexPath) {
            indexPathsForMovingItems.insert(indexPath)
        }

        setCelIsMoving(isMoving: isMoving, at: indexPath)
    }

    private func setCelIsMoving(isMoving: Bool, at indexPath: IndexPath) {
        let cell = cellForItem(at: indexPath) as? CustomTypesAccessable

        cell?.isMoving = isMoving
    }
}
