//
//  BlockModel+NewModels.swift
//  AnyType
//
//  Created by Dmitry Lobanov on 24.02.2020.
//  Copyright © 2020 AnyType. All rights reserved.
//

import Foundation
import os

// MARK: Block
extension BlockModels {
    class Block {
        var node: Node
        var information: Information
        init() {
            self.node = .init(indexPath: .init(), blocks: [])
            self.information = .default
        }
    }
}

// MARK: Information
extension BlockModels.Block {
    struct Information: MiddlewareBlockInformationModel {
        static func defaultValue() -> BlockModels.Block.Information { .default }
        
        var id: String
        var content: BlockType
        var childrenIds: [String] = []
        var fields: [String: Any] = .init()
        var restrictions: [String] = []
        
        init(id: String, content: BlockType) {
            self.id = id
            self.content = content
        }
        
        init(information: MiddlewareBlockInformationModel) {
            self.id = information.id
            self.content = information.content
            self.childrenIds = information.childrenIds
            self.fields = information.fields
            self.restrictions = information.restrictions
        }
        
        static let `defaultId`: String = "DefaultIdentifier"
        static let `defaultBlockType`: BlockType = .text(.init(text: "DefaultText", contentType: .text))
        static let `default`: Information = .init(id: Self.defaultId, content: Self.defaultBlockType)
    }
}

// MARK: Node
extension BlockModels.Block {
    class Node: ObservableObject {
        typealias Index = IndexPath
        var kind: BlockModels.Utilities.Inspector.BlockKind = .block
        var indexPath: Index
        weak var parent: Node?
        @Published var blocks: [Node] = [] {
            didSet {
                self.objectWillChange.send()
                // TODO: Maybe we require to call self.parent manually.
                self.parent?.objectWillChange.send()
            }
        }
                
        // MARK: Initialization
        init(indexPath: IndexPath, blocks: [Node]) {
            self.indexPath = indexPath
            self.blocks = self.update(blocks: blocks)
        }
    }
}

// MARK: Indices
extension BlockModels.Block.Node {
    @inline(__always) func childIndex() -> Index.Index {
        return self.indexPath.index(after: self.indexPath.section)
//        switch kind {
//        case .block: return self.indexPath.index(after: self.indexPath.section)
//        case .meta: return self.indexPath.section
//        }
    }
    @inline(__always) func createIndex(for blockAt: Index.Element) -> Index {
        return .init(item: blockAt, section: self.childIndex())
//        switch kind {
//        case .block: return .init(item: blockAt, section: self.childIndex())
//        case .meta: return .init(item: self.indexPath.item + blockAt + 1, section: self.childIndex())
//        }
    }
    @inline(__always) func getInternalIndex(for indexPath: IndexPath) -> Int? {
        return indexPath.item
//        switch kind {
//        case .block: return indexPath.item
//        case .meta:
//            let result = indexPath.item - self.indexPath.item - 1
//            return result > 0 ? result : nil
//        }
    }
}

// MARK: Checks
extension BlockModels.Block.Node {
    var isRoot: Bool { self.parent == nil }
}

// MARK: Indicies builders
extension BlockModels.Block.Node {
    static func newIndex(level: Index.Index, position: Index.Element) -> Index {
        .init(item: position, section: level)
    }
}

// MARK: Child blocks updates.
extension BlockModels.Block.Node {
    typealias Node = BlockModels.Block.Node
    func update(blocks: [Node]) -> [Node] {
        blocks.enumerated().map{ (index, block) in
            let block = block
            block.indexPath = self.createIndex(for: index)
            block.parent = self
            return block
        }
    }
    func update(_ blocks: [Node]) {
        self.blocks = self.update(blocks: blocks)
    }
    func buildIndexPaths() {
        self.blocks = self.update(blocks: blocks)
    }
}

extension BlockModels.Block {
    // DISCUSS: Maybe we would like to add Container.Node<Wrapped> with parameter.
    // TODO: Remove when ready.
    // We should collapse all classes, that are not needed.
    // This class is only required for prototyping and later could be replaced by BlockModels.Block
    final class RealBlock: Node {
        var information: Information = .defaultValue()
        var debugInformation: Information? {
            information.id == Information.defaultId ? nil : information
        }
        // Here Node is Self, so, just treat them as Self.
        override init(indexPath: IndexPath, blocks: [Node]) {
            super.init(indexPath: indexPath, blocks: blocks)
        }
        required init(information: Information, _ makeUniqueIndexPaths: Bool = true) {
            self.information = information
            super.init(indexPath: makeUniqueIndexPaths ? BlockModels.Utilities.IndexGenerator.generateID() : .init(), blocks: [])
        }
    }
}

// MARK: FullIdentifier
extension BlockModels.Block.Node {
    typealias FullIndex = [IndexPath]
    func depthLimit() -> Int { 10 }
    func getMaxDepth() -> Int {
        let value = depthLimit()
        let logger = Logging.createLogger(category: .todo(.improve("")))
        os_log(.debug, log: logger, "self.getMaxDepth() has limit: >%d< defined in self.depthLimit()", depthLimit())
        return value
    }
    func getFullIndex() -> FullIndex {
        sequence(first: self, next: { $0.parent }).prefix(getMaxDepth()).compactMap({$0}).map({$0.indexPath}).reversed()
    }
}

// MARK: Find
extension BlockModels.Block.RealBlock {
    func find(_ indexPath: IndexPath) -> BlockModels.Block.RealBlock? {
        // here we have index path.
        guard self.childIndex() == indexPath.section else {
            os_log(.error, "Strange situation. We are passing indexPath to a block, that doesn't contain child at this indexPath. IndexPath: >%s<. Our IndexPath: >%s<", indexPath.description, self.indexPath.description)
            return nil
        }
        return self.getInternalIndex(for: indexPath).flatMap{self.blocks[$0] as? BlockModels.Block.RealBlock}
    }
}

// MARK: Configuration
extension BlockModels.Block.Node {
    func with(kind: BlockModels.Utilities.Inspector.BlockKind) -> Self {
        self.kind = kind
        return self
    }
}

// MARK: Mocking
extension BlockModels.Block.RealBlock {
    static func mock(_ contentType: BlockType) -> Self {
        .init(information: .init(id: UUID().uuidString, content: contentType))
    }
    static func mockText(_ type: BlockType.Text.ContentType) -> Self {
        .mock(.text(.init(text: "", contentType: type)))
    }
    static func mockImage(_ type: BlockType.Image.ContentType) -> Self {
        .mock(.image(.init(contentType: type)))
    }
    static func mockVideo(_ type: BlockType.Video.ContentType) -> Self {
        .mock(.video(.init(contentType: type)))
    }
}

// MARK: Metablock Indices ( Insert indices )
// MARK: Not used, actually.
private extension BlockModels.Block.Node {
    @inline(__always) func beforeIndex() -> Index.Index {
        switch kind {
        case .block: return self.indexPath.item
        case .meta: return self.indexPath.item
        }
    }
    @inline(__always) func afterIndex() -> Index.Index {
        switch kind {
        case .block: return self.indexPath.item + 1
        case .meta: return self.indexPath.item + self.blocks.reduce(0, {$0 + $1.afterIndex() - $1.beforeIndex()}) + 1
        }
    }
}

// MARK: Indentation Level
extension BlockModels.Block.Node {
    static let defaultIndentationLevel: UInt = 0
    @inline(__always) func indentationLevel() -> UInt {
        if self.isRoot {
            return BlockModels.Block.Node.defaultIndentationLevel
        }
        guard let parent = self.parent else { return 0 }
        
        switch self.kind {
        case .meta: return parent.indentationLevel()
        case .block: return parent.indentationLevel() + 1
        }
    }
}

// MARK: CustomDebugStringConvertible
extension BlockModels.Block.RealBlock: CustomDebugStringConvertible {
    var debugDescription: String {
        BlockModels.Utilities.Debug.output(self).joined(separator: "\n")
    }
}
