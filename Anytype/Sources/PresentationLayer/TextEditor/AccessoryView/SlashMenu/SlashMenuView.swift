import UIKit
import Amplitude
import BlocksModels

final class SlashMenuView: DismissableInputAccessoryView {
    
    private var menuItems = [SlashMenuItem]()
    private var filterStringMismatchLength = 0
    private var cachedFilterText = ""
    
    private let viewModel: SlashMenuViewModel
    private let cellDataBuilder = SlashMenuCellDataBuilder()
    
    init(frame: CGRect, viewModel: SlashMenuViewModel) {
        self.viewModel = viewModel
        super.init(frame: frame)
        
        setup()
    }
    
    private func setup() {
        addSubview(navigationController.view) {
            $0.pinToSuperview(excluding: [.top])
            $0.top.equal(to: topSeparator?.bottomAnchor ?? topAnchor)
        }
    }
    
    func update(info: BlockInformation, relations: [Relation]) {
        viewModel.info = info
        menuItems = SlashMenuItemsBuilder(blockType: info.content.type, relations: relations).slashMenuItems
        
        restoreDefaultState()
    }
    
    func restoreDefaultState() {
        filterStringMismatchLength = 0
        cachedFilterText = ""
        popTooRoot()
        
        controller.cellData = cellDataBuilder.build(menuItems: menuItems)
    }
    
    override func didShow(from textView: UITextView) {
        Amplitude.instance().logEvent(AmplitudeEventsName.popupSlashMenu)
        
        viewModel.didShowMenuView(from: textView)
    }
    
    private func popTooRoot() {
        if controller.navigationController?.topViewController != controller {
            controller.navigationController?.popToRootViewController(animated: false)
        }
    }
    
    // MARK: - Controllers
    private lazy var navigationController: UINavigationController = {
        let navigationController = UINavigationController(rootViewController: controller)
        
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        navBarAppearance.shadowColor = .backgroundPrimary
        navBarAppearance.backgroundColor = .backgroundPrimary
        navBarAppearance.setBackIndicatorImage(UIImage.backArrow, transitionMaskImage: UIImage.backArrow)
        navigationController.modifyBarAppearance(navBarAppearance)
        navigationController.navigationBar.tintColor = .textSecondary
        
        return navigationController
    }()
    
    private lazy var controller = SlashMenuAssembly
        .menuController(viewModel: viewModel, dismissHandler: dismissHandler)
}

extension SlashMenuView: FilterableItemsView {
    
    func setFilterText(filterText: String) {
        guard cachedFilterText != filterText else { return }
        
        popTooRoot()
        
        controller.cellData = cellDataBuilder.build(filter: filterText, menuItems: menuItems)
        
        if !controller.cellData.isEmpty {
            filterStringMismatchLength = 0
        } else {
            filterStringMismatchLength += filterText.count - cachedFilterText.count
        }
        
        cachedFilterText = filterText
    }
}

extension SlashMenuView: DismissStatusProvider {
    var shouldDismiss: Bool {
        filterStringMismatchLength > 3
    }
}
