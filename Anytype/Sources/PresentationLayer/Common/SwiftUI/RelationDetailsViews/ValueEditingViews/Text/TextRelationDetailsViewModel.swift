import Foundation
import BlocksModels
import SwiftUI
import Combine
import FloatingPanel

final class TextRelationDetailsViewModel: ObservableObject {
          
    weak var viewController: TextRelationDetailsViewController?
    
    weak var delegate: RelationDetailsViewModelDelegate?
    
    private(set) var floatingPanelLayout: FloatingPanelLayout = IntrinsicTextRelationDetailsPopupLayout() {
        didSet {
            delegate?.didAskInvalidateLayout(false)
        }
    }
    
    @Published var value: String = "" {
        didSet {
            actionButtonViewModel?.text = value
        }
    }
    
    let type: TextRelationDetailsViewType
    
    let actionButtonViewModel: TextRelationActionButtonViewModel?
    
    private let relation: Relation
    private let service: TextRelationDetailsServiceProtocol
        
    private var cancellable: AnyCancellable?
    
    private var keyboardListener: KeyboardEventsListnerHelper?

    // MARK: - Initializers
    
    init(
        value: String,
        type: TextRelationDetailsViewType,
        relation: Relation,
        service: TextRelationDetailsServiceProtocol,
        actionButtonViewModel: TextRelationActionButtonViewModel?
    ) {
        self.value = value
        self.type = type
        self.actionButtonViewModel = actionButtonViewModel
        self.relation = relation
        self.service = service
        
        cancellable = self.$value
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveValue()
            }
        
        setupKeyboardListener()
    }
    
    var title: String {
        relation.name
    }
    
}

extension TextRelationDetailsViewModel {
    
    func updatePopupLayout(_ layoutGuide: UILayoutGuide) {
        self.floatingPanelLayout = AdaptiveTextRelationDetailsPopupLayout(layout: layoutGuide)
    }
    
}

extension TextRelationDetailsViewModel: RelationDetailsViewModelProtocol {
    
    func makeViewController() -> UIViewController {
        let vc = TextRelationDetailsViewController(viewModel: self)
        self.viewController = vc
        return vc
    }
}

private extension TextRelationDetailsViewModel {
    
    func saveValue() {
        service.saveRelation(value: value, key: relation.id, textType: type)
    }
    
    func setupKeyboardListener() {
        let showAction: KeyboardEventsListnerHelper.Action = { [weak self] notification in
            guard
                let keyboardRect = notification.localKeyboardRect(for: UIResponder.keyboardFrameEndUserInfoKey)
            else { return }
            
            self?.adjustViewHeightBy(keyboardHeight: keyboardRect.height)
        }

        let willHideAction: KeyboardEventsListnerHelper.Action = { [weak self] _ in
            self?.adjustViewHeightBy(keyboardHeight: 0)
        }

        self.keyboardListener = KeyboardEventsListnerHelper(
            willShowAction: showAction,
            willChangeFrame: showAction,
            willHideAction: willHideAction
        )
    }
    
    func adjustViewHeightBy(keyboardHeight: CGFloat) {
        viewController?.keyboardDidUpdateHeight(keyboardHeight)
        delegate?.didAskInvalidateLayout(true)
    }
    
}
