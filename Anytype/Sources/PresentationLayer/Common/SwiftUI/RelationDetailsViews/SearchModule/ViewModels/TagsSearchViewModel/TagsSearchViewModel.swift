import Foundation
import Combine
import SwiftUI

final class TagsSearchViewModel {
    
    @Published private var sections: [NewSearchSectionConfiguration] = []
    
    private var tags: [Relation.Tag.Option] = [] {
        didSet {
            sections = makeSections(tags: tags, selectedTagIds: selectedTagIds)
        }
    }
    
    private var selectedTagIds: [String] = [] {
        didSet {
            sections = makeSections(tags: tags, selectedTagIds: selectedTagIds)
        }
    }
    
    private let interactor: TagsSearchInteractor
    
    init(interactor: TagsSearchInteractor) {
        self.interactor = interactor
    }
    
}

extension TagsSearchViewModel: NewInternalSearchViewModelProtocol {
    
    var listModelPublisher: AnyPublisher<NewSearchView.ListModel, Never> {
        $sections.map { sections -> NewSearchView.ListModel in
            NewSearchView.ListModel.sectioned(sectinos: sections)
        }.eraseToAnyPublisher()
    }
    
    func search(text: String) {
        interactor.search(text: text) { [weak self] tags in
            self?.tags = tags
        }
    }
    
    func handleRowsSelection(ids: [String]) {
        selectedTagIds = ids
    }
    
}

private extension TagsSearchViewModel {
    
    func makeSections(tags: [Relation.Tag.Option], selectedTagIds: [String]) -> [NewSearchSectionConfiguration] {
        NewSearchSectionsBuilder.makeSections(tags) {
            $0.asRowConfigurations(with: selectedTagIds)
        }
    }
    
}

private extension Array where Element == Relation.Tag.Option {
    
    func asRowConfigurations(with selectedTagIds: [String]) -> [NewSearchRowConfiguration] {
        map { tag in
            NewSearchRowConfiguration(
                id: tag.id,
                rowContentHash: tag.hashValue
            ) {
                TagSearchRowView(
                    viewModel: tag.asTagViewModel,
                    guidlines: RelationStyle.regular(allowMultiLine: false).tagViewGuidlines,
                    selectionIndicatorViewModel: SelectionIndicatorViewModelBuilder.buildModel(id: tag.id, selectedIds: selectedTagIds)
                ).eraseToAnyView()
            }
        }
    }
    
}

private extension Relation.Tag.Option {
    
    var asTagViewModel: TagView.Model {
        TagView.Model(text: text, textColor: textColor, backgroundColor: backgroundColor)
    }
    
}