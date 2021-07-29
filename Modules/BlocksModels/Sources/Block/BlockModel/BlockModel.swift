import Foundation
import Combine
import os
import SwiftProtobuf

public final class BlockModel: ObservableObject, BlockModelProtocol {
    public var container: BlockContainerModelProtocol?

    @Published public var information: BlockInformation
    public var parent: BlockModelProtocol?
    public var indentationLevel: Int = 0

    public var isRoot: Bool {
        parent == nil
    }

    public var isFirstResponder: Bool {
        get {
            container?.userSession.firstResponder?.information.id == information.id
        }
        set {
            self.container?.userSession.firstResponder = self
        }
    }

    public func unsetFirstResponder() {
        if self.isFirstResponder {
            self.container?.userSession.firstResponder = nil
        }
    }

    public var isToggled: Bool {
        get {
            container?.userSession.toggles[information.id] ?? false
        }
    }

    public func toggle() {
        let newValue = !isToggled
        container?.userSession.toggles[information.id] = newValue
    }

    public var focusAt: BlockFocusPosition? {
        get {
            guard container?.userSession.firstResponder?.information.id == information.id else { return nil }
            return container?.userSession.focus
        }
        set {
            guard container?.userSession.firstResponder?.information.id == information.id else { return }
            if let value = newValue {
                container?.userSession.focus = value
            }
            else {
                container?.userSession.focus = nil
            }
        }
    }

    public var kind: BlockKind {
        switch self.information.content {
        case .smartblock, .divider: return .meta
        case let .layout(layout) where layout.style == .div: return .meta
        case let .layout(layout) where layout.style == .header: return .meta
        default: return .block
        }
    }

    public required init(information: BlockInformation) {
        self.information = information
    }
    
    public func update(fields: Dictionary<String, Google_Protobuf_Value>) {
        // TODO
    }
}
