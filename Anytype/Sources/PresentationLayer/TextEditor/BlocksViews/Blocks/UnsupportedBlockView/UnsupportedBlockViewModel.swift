import BlocksModels
import UIKit
import AnytypeCore

struct UnsupportedBlockViewModel: BlockViewModelProtocol {
    let indentationLevel = 0
    let info: BlockInformation

    var hashable: AnyHashable {
        [
            indentationLevel,
            info
        ] as [AnyHashable]
    }

    init(info: BlockInformation) {
        self.info = info
    }

    func makeContentConfiguration(maxWidth _ : CGFloat) -> UIContentConfiguration {
        UnsupportedBlockContentConfiguration(text: "Unsupported block".localized).asCellBlockConfiguration
    }

    func didSelectRowInTableView() { }
}
