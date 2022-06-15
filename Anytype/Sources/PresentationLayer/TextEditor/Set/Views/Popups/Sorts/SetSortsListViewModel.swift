import Foundation
import SwiftUI
import BlocksModels
import FloatingPanel

final class SetSortsListViewModel: ObservableObject {
    
    private let setModel: EditorSetViewModel
    private let service: DataviewServiceProtocol
    private let router: EditorRouterProtocol
    
    private(set) var popupLayout = AnytypePopupLayoutType.fullScreen
    private weak var popup: AnytypePopupProxy?

    
    init(
        setModel: EditorSetViewModel,
        service: DataviewServiceProtocol,
        router: EditorRouterProtocol)
    {
        self.setModel = setModel
        self.service = service
        self.router = router
    }
    
}

extension SetSortsListViewModel {
    
    // MARK: - Routing
    
    func addButtonTapped() {
        router.presentSheet(
            AnytypePopup(
                viewModel: SetSortsSearchViewPopupModel(
                    setModel: setModel,
                    onSelect: { [weak self] key in
                        self?.addNewSort(with: key)
                    }
                ),
                configuration: .init(isGrabberVisible: false, dismissOnBackdropView: true)
            )
        )
    }
    
    func sortRowTapped(_ setSort: SetSort) {
        let view = CheckPopupView(viewModel: SetSortTypesListViewModel(
            sort: setSort,
            onSelect: { [weak self] sort in
                let newSetSort = SetSort(
                    metadata: setSort.metadata,
                    sort: sort
                )
                self?.updateSorts(with: newSetSort)
            })
        )
        router.presentSheet(
            AnytypePopup(
                contentView: view
            )
        )
    }
    
    // MARK: - Actions
    
    func delete(_ indexSet: IndexSet) {
        var sorts = setModel.sorts
        sorts.remove(atOffsets: indexSet)
        updateView(with: sorts)
    }
    
    func move(from: IndexSet, to: Int) {
        var sorts = setModel.sorts
        sorts.move(fromOffsets: from, toOffset: to)
        updateView(with: sorts)
    }
    
    func addNewSort(with key: String) {
        var dataviewSorts = setModel.sorts.map { $0.sort }
        dataviewSorts.append(
            DataviewSort(
                relationKey: key,
                type: .asc
            )
        )
        updateView(with: dataviewSorts)
    }
    
    private func updateSorts(with setSort: SetSort) {
        let sorts: [SetSort] = setModel.sorts.map { sort in
            if sort.metadata.key == setSort.metadata.key {
                return setSort
            } else {
                return sort
            }
        }
        updateView(with: sorts)
    }
    
    private func updateView(with sorts: [SetSort]) {
        let dataviewSorts = sorts.map { $0.sort }
        updateView(with: dataviewSorts)
    }
    
    private func updateView(with dataviewSorts: [DataviewSort]) {
        let newView = setModel.activeView.updated(sorts: dataviewSorts)
        service.updateView(newView)
    }
}

extension SetSortsListViewModel: AnytypePopupViewModelProtocol {
    
    func makeContentView() -> UIViewController {
        UIHostingController(
            rootView:
                SetSortsListView()
                .environmentObject(self)
                .environmentObject(setModel)
        )
    }
    
    func onPopupInstall(_ popup: AnytypePopupProxy) {
        self.popup = popup
    }
    
}