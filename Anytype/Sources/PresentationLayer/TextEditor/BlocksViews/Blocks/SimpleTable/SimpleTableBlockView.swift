import UIKit
import BlocksModels
import Combine

final class SimpleTableBlockView: UIView, BlockContentView {
    private lazy var dynamicLayoutView = DynamicCollectionLayoutView(frame: .zero)
    private lazy var spreadsheetLayout = SpreadsheetLayout()
    private var heightDidChangedSubscriptions = [AnyCancellable]()
    private weak var blockDelegate: BlockDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupSubview()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)

        setupSubview()
    }

    func update(with configuration: SimpleTableBlockContentConfiguration) {
        self.blockDelegate = configuration.blockDelegate

        spreadsheetLayout.reset()
        spreadsheetLayout.itemWidths = configuration.widths
        spreadsheetLayout.items = configuration.items
        spreadsheetLayout.relativePositionProvider = configuration.relativePositionProvider

        dynamicLayoutView.update(
            with: .init(
                hashable: AnyHashable(configuration),
                views: configuration.items,
                layout: spreadsheetLayout,
                heightDidChanged: { [weak self] in self?.blockDelegate?.textBlockSetNeedsLayout() }
            )
        )

        setupHeightChangeHandlers(configuration: configuration)
    }

    private func setupHeightChangeHandlers(configuration: SimpleTableBlockContentConfiguration) {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            for (sectionIndex, section) in configuration.items.enumerated() {
                for (rowIndex, element) in section.enumerated() {
                    element.heightDidChangedSubject.sink { [weak self] in
                        let indexPath = IndexPath(row: rowIndex, section: sectionIndex)

                        self?.spreadsheetLayout.setNeedsLayout(indexPath: indexPath)

                        self?.spreadsheetLayout.invalidateLayout()
                        self?.dynamicLayoutView.layoutIfNeeded()

                    }.store(in: &self.heightDidChangedSubscriptions)
                }
            }
        }
    }

    private func setupSubview() {
        addSubview(dynamicLayoutView) {
            $0.pinToSuperview()
        }

        dynamicLayoutView.collectionView.contentInset = .init(
            top: 0,
            left: 20,
            bottom: 0,
            right: 20
        )

        dynamicLayoutView.collectionView.register(
            SimpleTableCollectionViewCell<TextBlockContentView>.self,
            forCellWithReuseIdentifier: SimpleTableCellConfiguration<TextBlockContentConfiguration>.reusableIdentifier
        )
    }
}
