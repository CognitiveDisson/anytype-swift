//
//  DrawableBlocksViews.swift
//  AnyType
//
//  Created by Dmitry Lobanov on 29.11.2019.
//  Copyright © 2019 AnyType. All rights reserved.
//

import Foundation
enum ImageBlocksViews {
    enum Image {} // -> Image.ContentType.image
    enum PageIcon {} // -> Image.ContentType.pageIcon
}

extension ImageBlocksViews {
    enum Supplement {}
}

extension ImageBlocksViews.Supplement {
    class Matcher: BlocksViews.Supplement.BaseBlocksSeriazlier {
        override func sequenceResolver(block: Block, blocks: [Block]) -> [BlockViewRowBuilderProtocol] {
            switch block.type {
            case let .image(text):
                switch text.contentType {
                case .image: return blocks.map{ImageBlocksViews.Image.BlockViewModel(block: $0)}
                case .pageIcon: return blocks.map{ImageBlocksViews.PageIcon.BlockViewModel(block: $0)}
                }
            default: return []
            }
        }
    }
}
