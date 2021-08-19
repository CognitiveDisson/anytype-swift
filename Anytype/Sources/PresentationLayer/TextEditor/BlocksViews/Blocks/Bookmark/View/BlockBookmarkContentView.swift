import Combine
import UIKit
import BlocksModels
    
final class BlockBookmarkContentView: UIView & UIContentView {
    private var currentConfiguration: BlockBookmarkConfiguration
    var configuration: UIContentConfiguration {
        get { currentConfiguration }
        set {
            guard let configuration = newValue as? BlockBookmarkConfiguration,
                  configuration != currentConfiguration else { return }
            
            currentConfiguration = configuration
            apply(state: currentConfiguration.state)
        }
    }
    
    lazy var bookmarkHeight = bookmarkView.heightAnchor.constraint(equalToConstant: Layout.emptyViewHeight)
    
    init(configuration: BlockBookmarkConfiguration) {
        self.currentConfiguration = configuration
        super.init(frame: .zero)
        
        setup()
        apply(state: currentConfiguration.state)
    }
    
    @available(*, unavailable)
    override init(frame: CGRect) {
        fatalError("Not implemented")
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        addSubview(bookmarkView) {
            $0.pinToSuperview(insets: Layout.bookmarkViewInsets)
        }
        bookmarkHeight.isActive = true
    }
    
    private func apply(state: BlockBookmarkState) {
        switch state {
        case .onlyURL:
            bookmarkHeight.constant = Layout.emptyViewHeight
        case .fetched:
            bookmarkHeight.constant = Layout.bookmarkViewHeight
        }
        
        bookmarkView.handle(state: state)
    }

    private let bookmarkView: BlockBookmarkView = {
        let view = BlockBookmarkView()
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.grayscale30.cgColor
        view.layer.cornerRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        return view
    }()
}

private extension BlockBookmarkContentView {
    enum Layout {
        static let emptyViewHeight: CGFloat = 48
        static let bookmarkViewHeight: CGFloat = 108
        static let bookmarkViewInsets = UIEdgeInsets(top: 10, left: 20, bottom: -10, right: -20)
    }
}
