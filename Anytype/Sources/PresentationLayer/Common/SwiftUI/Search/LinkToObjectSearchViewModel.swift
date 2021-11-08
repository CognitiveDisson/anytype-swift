//
//  LinkToObjectSearchViewModel.swift
//  Anytype
//
//  Created by Denis Batvinkin on 29.10.2021.
//  Copyright © 2021 Anytype. All rights reserved.
//

import SwiftUI
import BlocksModels


final class LinkToObjectSearchViewModel: SearchViewModelProtocol {
    enum SearchKind {
        case web(String)
        case createObject(String)
        case object(BlockId)
    }

    typealias SearchDataType = LinkToObjectSearchData

    private let service = SearchService()

    let descriptionTextColor: Color = .textPrimary
    let shouldShowCallout: Bool = true

    @Published var searchData: [SearchDataSection<SearchDataType>] = []
    var onSelect: (SearchDataType.SearchResult) -> ()

    func search(text: String) {
        searchData.removeAll()

        let result = service.search(text: text)

        var objectData = result?.compactMap { searchData in
            LinkToObjectSearchData(searchData: searchData)
        }

        if text.isNotEmpty {
            let icon = UIImage.createImage(ImageName.slashMenu.style.link)
            let webSearchData = LinkToObjectSearchData(
                searchKind: .web(text),
                searchTitle: text,
                iconImage: .image(icon))

            let webSection = SearchDataSection(searchData: [webSearchData], sectionName: "Web pages".localized)
            searchData.append(webSection)

            let createObjectIcon = UIImage.createImage("createNewObject")
            let title = "Create object".localized + "  " + "\"" + text + "\""
            let createObjectData = LinkToObjectSearchData(searchKind: .createObject(text),
                                                          searchTitle: title,
                                                          iconImage: .image(createObjectIcon))
            objectData?.insert(createObjectData, at: 0)
        }

        searchData.append(SearchDataSection(searchData: objectData ?? [], sectionName: text.isNotEmpty ? "Objects".localized : ""))
    }

    init(onSelect: @escaping (SearchDataType.SearchResult) -> ()) {
        self.onSelect = onSelect
    }
}


struct LinkToObjectSearchData: SearchDataProtocol {
    let id = UUID()

    let searchResult: LinkToObjectSearchViewModel.SearchKind
    let searchTitle: String
    let description: String
    let iconImage: ObjectIconImage
    let callout: String

    var shouldShowDescription: Bool {
        switch searchResult {
        case .object: return true
        case .web, .createObject: return false
        }
    }

    var shouldShowCallout: Bool {
        switch searchResult {
        case .object: return true
        case .web, .createObject: return false
        }
    }

    var descriptionTextColor: Color {
        return .textPrimary
    }

    var usecase: ObjectIconImageUsecase {
        switch searchResult {
        case .object: return .dashboardSearch
        case .web, .createObject: return .mention(.heading)
        }
    }

    init(searchData: SearchData) {
        self.searchResult = .object(searchData.id)
        self.searchTitle = searchData.title
        self.description = searchData.description

        let layout = searchData.layout
        if layout == .todo {
            self.iconImage =  .todo(searchData.isDone)
        } else {
            self.iconImage = searchData.icon.flatMap { .icon($0) } ?? .placeholder(searchTitle.first)
        }

        callout = searchData.objectType.name
    }

    init(searchKind: LinkToObjectSearchViewModel.SearchKind, searchTitle: String, iconImage: ObjectIconImage) {
        self.searchResult = searchKind
        self.searchTitle = searchTitle
        self.iconImage = iconImage
        self.description = ""
        self.callout = ""
    }
}
