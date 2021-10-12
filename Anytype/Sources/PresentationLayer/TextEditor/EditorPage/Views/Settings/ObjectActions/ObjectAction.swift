//
//  ObjectAction.swift
//  Anytype
//
//  Created by Denis Batvinkin on 24.09.2021.
//  Copyright © 2021 Anytype. All rights reserved.
//

import BlocksModels


enum ObjectAction: Hashable {

    // NOTE: When adding new case here, it case MUST be added in allCasesWith method
    case archive(isArchived: Bool)
    case favorite(isFavorite: Bool)
//    case moveTo
//    case template
//    case search

    // When adding to case
    static func allCasesWith(details: DetailsDataProtocol) -> [Self] {
        var allCases: [ObjectAction] = []

        allCases.append(.archive(isArchived: details.isArchived ?? false))
        allCases.append(.favorite(isFavorite: details.isFavorite ?? false))
//        allCases.append(.moveTo)
//        allCases.append(.template)
//        allCases.append(.search)

        return allCases
    }
}