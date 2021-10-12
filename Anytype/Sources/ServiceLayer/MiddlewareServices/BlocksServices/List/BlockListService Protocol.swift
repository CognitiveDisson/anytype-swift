import Foundation
import Combine
import BlocksModels
import UIKit

protocol BlockListServiceProtocol {
    func delete(blockIds: [String]) -> ResponseEvent?
    func setDivStyle(contextId: BlockId, blockIds: [BlockId], style: BlockDivider.Style) -> ResponseEvent?
    func setAlign(contextId: BlockId, blockIds: [BlockId], alignment: LayoutAlignment) -> ResponseEvent?
    func setBackgroundColor(contextId: BlockId, blockIds: [BlockId], color: MiddlewareColor) -> ResponseEvent?
    func setTextStyle(contextId: BlockId, blockIds: [BlockId], style: BlockText.Style) -> AnyPublisher<ResponseEvent, Error>
    func setFields(contextId: BlockId, fields: [BlockFields]) -> ResponseEvent?
    func setBlockColor(contextId: BlockId, blockIds: [BlockId], color: MiddlewareColor) -> ResponseEvent?
    func moveTo(contextId: BlockId, blockId: BlockId, targetId: BlockId) -> ResponseEvent?
}