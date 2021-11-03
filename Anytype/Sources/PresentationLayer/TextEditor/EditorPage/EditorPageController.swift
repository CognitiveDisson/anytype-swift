import BlocksModels
import UIKit
import Combine
import AnytypeCore

import SwiftUI
import Amplitude

final class EditorPageController: UIViewController {
    
    private(set) lazy var dataSource = makeCollectionViewDataSource()
    
    private lazy var deletedScreen = EditorPageDeletedScreen(
        onBackTap: viewModel.router.goBack
    )
    
    let collectionView: UICollectionView = {
        var listConfiguration = UICollectionLayoutListConfiguration(appearance: .plain)
        listConfiguration.backgroundColor = .clear
        listConfiguration.showsSeparators = false
        let layout = UICollectionViewCompositionalLayout.list(using: listConfiguration)
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
        )
        collectionView.allowsMultipleSelection = true
        collectionView.backgroundColor = .clear
        collectionView.contentInsetAdjustmentBehavior = .never
        
        return collectionView
    }()
    
    private var insetsHelper: ScrollViewContentInsetsHelper?
    private var firstResponderHelper: FirstResponderHelper?
    private var contentOffset: CGPoint = .zero
    
    // Gesture recognizer to handle taps in empty document
    private let listViewTapGestureRecognizer: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer()
        recognizer.cancelsTouchesInView = false
        return recognizer
    }()
    
    private lazy var navigationBarHelper = EditorNavigationBarHelper(
        onSettingsBarButtonItemTap: { [weak self] in
            UISelectionFeedbackGenerator().selectionChanged()
            self?.viewModel.showSettings()
        }
    )
    
    var viewModel: EditorPageViewModelProtocol!
    
    // MARK: - Initializers
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Overrided functions
    
    override func loadView() {
        super.loadView()
        
        setupView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.viewLoaded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationBarHelper.handleViewWillAppear(controllerForNavigationItems, collectionView)
        
        firstResponderHelper = FirstResponderHelper(scrollView: collectionView)
        insetsHelper = ScrollViewContentInsetsHelper(
            scrollView: collectionView
        )
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.viewAppeared()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationBarHelper.handleViewWillDisappear()
        insetsHelper = nil
        firstResponderHelper = nil
    }
    
    private var controllerForNavigationItems: UIViewController? {
        guard parent is UINavigationController else {
            return parent
        }
        
        return self
    }
    
}

// MARK: - EditorPageViewInput

extension EditorPageController: EditorPageViewInput {
    
    func update(header: ObjectHeader, details: ObjectDetails?) {
        var headerSnapshot = NSDiffableDataSourceSectionSnapshot<EditorItem>()
        headerSnapshot.append([.header(header)])
        dataSource.apply(headerSnapshot, to: .header, animatingDifferences: false)
        
        navigationBarHelper.configureNavigationBar(
            using: header,
            details: details
        )
    }
    
    func update(syncStatus: SyncStatus) {
        navigationBarHelper.updateSyncStatus(syncStatus)
    }
    
    func update(blocks: [BlockViewModelProtocol]) {
        var blocksSnapshot = NSDiffableDataSourceSectionSnapshot<EditorItem>()
        blocksSnapshot.append(blocks.map { EditorItem.block($0) })
        
        let sectionSnapshot = self.dataSource.snapshot(for: .main)

        sectionSnapshot.visibleItems.forEach { item in
            switch item {
            case let .block(block):
                let blockForUpdate = blocks.first { $0.blockId == block.blockId }

                guard let blockForUpdate = blockForUpdate else { return }
                guard let indexPath = self.dataSource.indexPath(for: item) else { return }
                guard let cell = self.collectionView.cellForItem(at: indexPath) as? UICollectionViewListCell else { return }

                cell.contentConfiguration = blockForUpdate.makeContentConfiguration(maxWidth: cell.bounds.width)
                cell.indentationLevel = blockForUpdate.indentationLevel
            case .header:
                return
            }
        }
        
        applyBlocksSectionSnapshot(blocksSnapshot)
    }
    
    func selectBlock(blockId: BlockId) {
        let item = dataSource.snapshot().itemIdentifiers.first {
            switch $0 {
            case let .block(block):
                return block.information.id == blockId
            case .header:
                return false
            }
        }
        
        if let item = item {
            let indexPath = dataSource.indexPath(for: item)
            collectionView.selectItem(at: indexPath, animated: true, scrollPosition: [])
        }
        updateView()
    }

    func needsUpdateLayout() {
        updateView()
    }
    
    func textBlockWillBeginEditing() {
        contentOffset = collectionView.contentOffset
    }
    
    func textBlockDidBeginEditing() {
        collectionView.setContentOffset(contentOffset, animated: false)
    }
    
    func showDeletedScreen(_ show: Bool) {
        navigationBarHelper.setNavigationBarHidden(show)
        deletedScreen.isHidden = !show
        if show { UIApplication.shared.hideKeyboard() }
    }
    
    private func updateView() {
        UIView.performWithoutAnimation {
            dataSource.refresh(animatingDifferences: true)
        }
    }
    
}

// MARK: - Private extension

private extension EditorPageController {
    
    func setupView() {
        view.backgroundColor = .backgroundPrimary
        
        setupCollectionView()
        
        setupInteractions()
        
        setupLayout()
        navigationBarHelper.addFakeNavigationBarBackgroundView(to: view)
    }
    
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.addGestureRecognizer(self.listViewTapGestureRecognizer)
    }
    
    func setupInteractions() {
        listViewTapGestureRecognizer.addTarget(
            self,
            action: #selector(tapOnListViewGestureRecognizerHandler)
        )
        view.addGestureRecognizer(self.listViewTapGestureRecognizer)
    }
    
    func setupLayout() {
        view.addSubview(collectionView) {
            $0.pinToSuperview()
        }
        view.addSubview(deletedScreen) {
            $0.pinToSuperview()
        }
        deletedScreen.isHidden = true
    }
    
    @objc
    func tapOnListViewGestureRecognizerHandler() {
        let location = self.listViewTapGestureRecognizer.location(in: collectionView)
        let cellIndexPath = collectionView.indexPathForItem(at: location)
        guard cellIndexPath == nil else { return }
        
        viewModel.blockActionHandler.onEmptySpotTap()
    }
    
    func makeCollectionViewDataSource() -> UICollectionViewDiffableDataSource<EditorSection, EditorItem> {
        let headerCellRegistration = createHeaderCellRegistration()
        let cellRegistration = createCellRegistration()
        let codeCellRegistration = createCodeCellRegistration()
        
        let dataSource = UICollectionViewDiffableDataSource<EditorSection, EditorItem>(
            collectionView: collectionView
        ) { (collectionView, indexPath, dataSourceItem) -> UICollectionViewCell? in
            switch dataSourceItem {
            case let .block(block):
                guard case .text(.code) = block.content.type else {
                    return collectionView.dequeueConfiguredReusableCell(
                        using: cellRegistration,
                        for: indexPath,
                        item: block
                    )
                }
                
                return collectionView.dequeueConfiguredReusableCell(
                    using: codeCellRegistration,
                    for: indexPath,
                    item: block
                )
            case let .header(header):
                return collectionView.dequeueConfiguredReusableCell(
                    using: headerCellRegistration,
                    for: indexPath,
                    item: header
                )
            }
        }
        
        
        var initialSnapshot = NSDiffableDataSourceSnapshot<EditorSection, EditorItem>()
        initialSnapshot.appendSections(EditorSection.allCases)
        
        dataSource.apply(initialSnapshot, animatingDifferences: false)
        
        return dataSource
    }
    
    func createHeaderCellRegistration()-> UICollectionView.CellRegistration<UICollectionViewListCell, ObjectHeader> {
        .init { cell, _, item in
            cell.contentConfiguration = item.makeContentConfiguration(maxWidth: cell.bounds.width)
        }
    }
    
    func createCellRegistration() -> UICollectionView.CellRegistration<UICollectionViewListCell, BlockViewModelProtocol> {
        .init { [weak self] cell, indexPath, item in
            self?.setupCell(cell: cell, indexPath: indexPath, item: item)
        }
    }
    
    func createCodeCellRegistration() -> UICollectionView.CellRegistration<CodeBlockCellView, BlockViewModelProtocol> {
        .init { [weak self] (cell, indexPath, item) in
            self?.setupCell(cell: cell, indexPath: indexPath, item: item)
        }
    }
    
    func setupCell(cell: UICollectionViewListCell, indexPath: IndexPath, item: BlockViewModelProtocol) {
        cell.contentConfiguration = item.makeContentConfiguration(maxWidth: cell.bounds.width)
        cell.indentationWidth = Constants.cellIndentationWidth
        cell.indentationLevel = item.indentationLevel
        cell.contentView.isUserInteractionEnabled = true
        
        cell.backgroundConfiguration = UIBackgroundConfiguration.clear()
        if FeatureFlags.rainbowCells {
            cell.fillSubviewsWithRandomColors(recursively: false)
        }
    }
    
}

// MARK: - Initial Update data

private extension EditorPageController {
    
    func applyBlocksSectionSnapshot(_ snapshot: NSDiffableDataSourceSectionSnapshot<EditorItem>) {
        let selectedCells = collectionView.indexPathsForSelectedItems
        
        UIView.performWithoutAnimation { [weak self] in
            guard let self = self else { return }
            
            self.dataSource.apply(snapshot, to: .main, animatingDifferences: true)
            self.focusOnFocusedBlock()
            selectedCells?.forEach {
                self.collectionView.selectItem(at: $0, animated: false, scrollPosition: [])
            }
        }
    }
    
    private func focusOnFocusedBlock() {
        let userSession = UserSession.shared
        // TODO: we should move this logic to TextBlockViewModel
        if let id = userSession.firstResponderId.value, let focusedAt = userSession.focus.value,
           let blockViewModel = viewModel.modelsHolder.models.first(where: { $0.blockId == id }) as? TextBlockViewModel {
            blockViewModel.set(focus: focusedAt)
        }
    }
}


// MARK: - Constants

private extension EditorPageController {
    
    enum Constants {
        static let cellIndentationWidth: CGFloat = 24
    }
    
}
