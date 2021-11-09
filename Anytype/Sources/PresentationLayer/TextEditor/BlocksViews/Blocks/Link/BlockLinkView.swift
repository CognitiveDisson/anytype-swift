import UIKit
import Combine
import BlocksModels
import Kingfisher

final class BlockLinkView: BaseBlockView, UIContentView {
    private var currentConfiguration: BlockLinkContentConfiguration
    var configuration: UIContentConfiguration {
        get { self.currentConfiguration }
        set {
            guard let configuration = newValue as? BlockLinkContentConfiguration else { return }
            guard currentConfiguration != configuration else { return }
            currentConfiguration = configuration
            apply(configuration)
        }
    }
    
    
    init(configuration: BlockLinkContentConfiguration) {
        currentConfiguration = configuration
        super.init(frame: .zero)
        
        setup()
        apply(configuration)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    // MARK: - Internal functions
    func apply(_ configuration: BlockLinkContentConfiguration) {
        iconView.removeAllSubviews()
        iconView.addSubview(configuration.state.makeIconView()) {
            $0.pinToSuperview()
        }
        
        textView.attributedText = configuration.state.attributedTitle
        deletedLabel.isHidden = !configuration.state.archived
        configuration.currentConfigurationState.map(update(with:))
    }
    
    // MARK: - Private functions
    
    private func setup() {
        addSubview(contentView) {
            $0.pinToSuperview(insets: Constants.contentInsets)
        }
        
        contentView.addSubview(iconView) {
            $0.pinToSuperview(excluding: [.right])
        }
        contentView.addSubview(textView) {
            $0.pinToSuperview(excluding: [.left, .right])
            $0.leading.equal(to: iconView.trailingAnchor)
        }
        contentView.addSubview(deletedLabel) {
            $0.pinToSuperview(excluding: [.left, .right])
            $0.trailing.lessThanOrEqual(to: contentView.trailingAnchor)
            $0.leading.equal(to: textView.trailingAnchor)
        }
    }
    
    // MARK: - Views
    private let contentView = UIView()
    private let iconView = UIView()
    
    private let deletedLabel = DeletedLabel()
    
    private let textView: UITextView = {
        let view = UITextView()
        view.isScrollEnabled = false
        view.textContainerInset = Constants.textContainerInset
        view.isUserInteractionEnabled = false
        return view
    }()
}

// MARK: - Constants

private extension BlockLinkView {
    
    enum Constants {
        static let textContainerInset = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 8)
        static let contentInsets = UIEdgeInsets(top: 5, left: 20, bottom: -5, right: -20)
    }
    
}
