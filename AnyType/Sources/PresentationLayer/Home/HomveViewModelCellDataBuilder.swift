import Combine
import BlocksModels

// TODO: Use single subscriptions for all changes instead of per cell approach
extension HomeViewModel {
    
    func onDashboardUpdate(_ updateResult: BaseDocument.UpdateResult) {
        switch updateResult.updates {
        case .general:
            cellData = buldCellData(updateResult)            
        case .update(let payload):
            payload.updatedIds.forEach { updateCellWithTargetId($0) }
        }
    }
    
    private func updateCellWithTargetId(_ blockId: BlockId) {
        guard let newDetails = self.document.getDetails(by: blockId)?.currentDetails else {
            assertionFailure("Could not find object with id: \(blockId)")
            return
        }

        cellData.enumerated()
            .first { $0.element.destinationId == blockId }
            .flatMap { offset, data in
                cellData[offset] = PageCellData(
                    id: data.id,
                    destinationId: data.destinationId,
                    icon: newDetails.documentIcon,
                    title: newDetails.name ?? "",
                    type: data.type,
                    isLoading: false
                )
            }
    }
    
    private func buldCellData(_ updateResult: BaseDocument.UpdateResult) -> [PageCellData] {
        let blockViewModels = blocksConverter.convert(updateResult.models, router: nil)
        let viewModels = blockViewModels.compactMap { $0 as? BlockPageLinkViewModel }
        return viewModels.map { buildPageCellData(pageLinkViewModel: $0) }
    }
    
    private func buildPageCellData(pageLinkViewModel: BlockPageLinkViewModel) -> PageCellData {
        let details = pageLinkViewModel.getDetailsViewModel().currentDetails
        let isLoadings = details.parentId == nil
            
        return PageCellData(
            id: pageLinkViewModel.blockId,
            destinationId: pageLinkViewModel.targetBlockId,
            icon: details.documentIcon,
            title: details.name ?? "",
            type: "Page",
            isLoading: isLoadings
        )
    }
}
