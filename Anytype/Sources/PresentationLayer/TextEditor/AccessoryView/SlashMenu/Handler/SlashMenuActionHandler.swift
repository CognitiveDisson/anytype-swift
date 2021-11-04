import Foundation
import BlocksModels


final class SlashMenuActionHandler {
    private let actionHandler: EditorActionHandlerProtocol
    private let router: EditorRouterProtocol
    
    init(
        actionHandler: EditorActionHandlerProtocol,
        router: EditorRouterProtocol
    ) {
        self.actionHandler = actionHandler
        self.router = router
    }
    
    func handle(_ action: SlashAction, blockId: BlockId) {
        switch action {
        case let .actions(action):
            handleActions(action, blockId: blockId)
        case let .alignment(alignmnet):
            handleAlignment(alignmnet, blockId: blockId)
        case let .style(style):
            handleStyle(style, blockId: blockId)
        case let .media(media):
            actionHandler.handleAction(.addBlock(media.blockViewsType), blockId: blockId)
        case .objects(let action):
            switch action {
            case .linkTo:
                router.showLinkTo { [weak self] targetDetailsId in
                    self?.actionHandler.handleAction(.addLink(targetDetailsId), blockId: blockId)
                }
            case .objectType(let object):
                actionHandler.createPage(targetId: blockId, type: .dynamic(object.id))
                    .flatMap { actionHandler.showPage(blockId: $0) }
            }
        case .relations:
            break
        case let .other(other):
            actionHandler.handleAction(.addBlock(other.blockViewsType), blockId: blockId)
        case let .color(color):
            actionHandler.handleAction(.setTextColor(color), blockId: blockId)
        case let .background(color):
            actionHandler.handleAction(.setBackgroundColor(color), blockId: blockId)
        }
    }
    
    func changeText(_ text: NSAttributedString, info: BlockInformation) {
        actionHandler.changeText(text, info: info)
    }
    
    private func handleAlignment(_ alignment: SlashActionAlignment, blockId: BlockId) {
        switch alignment {
        case .left :
            actionHandler.handleAction(.setAlignment(.left), blockId: blockId)
        case .right:
            actionHandler.handleAction(.setAlignment(.right), blockId: blockId)
        case .center:
            actionHandler.handleAction(.setAlignment(.center), blockId: blockId)
        }
    }
    
    private func handleStyle(_ style: SlashActionStyle, blockId: BlockId) {
        switch style {
        case .text:
            actionHandler.handleAction(.turnIntoBlock(.text(.text)), blockId: blockId)
        case .title:
            actionHandler.handleAction(.turnIntoBlock(.text(.header)), blockId: blockId)
        case .heading:
            actionHandler.handleAction(.turnIntoBlock(.text(.header2)), blockId: blockId)
        case .subheading:
            actionHandler.handleAction(.turnIntoBlock(.text(.header3)), blockId: blockId)
        case .highlighted:
            actionHandler.handleAction(.turnIntoBlock(.text(.quote)), blockId: blockId)
        case .checkbox:
            actionHandler.handleAction(.turnIntoBlock(.text(.checkbox)), blockId: blockId)
        case .bulleted:
            actionHandler.handleAction(.turnIntoBlock(.text(.bulleted)), blockId: blockId)
        case .numberedList:
            actionHandler.handleAction(.turnIntoBlock(.text(.numbered)), blockId: blockId)
        case .toggle:
            actionHandler.handleAction(.turnIntoBlock(.text(.toggle)), blockId: blockId)
        case .bold:
            actionHandler.handleAction(.toggleWholeBlockMarkup(.bold), blockId: blockId)
        case .italic:
            actionHandler.handleAction(.toggleWholeBlockMarkup(.italic), blockId: blockId)
        case .strikethrough:
            actionHandler.handleAction(.toggleWholeBlockMarkup(.strikethrough), blockId: blockId)
        case .code:
            actionHandler.handleAction(.toggleWholeBlockMarkup(.keyboard), blockId: blockId)
        case .link:
            break
        }
    }
    
    private func handleActions(_ action: BlockAction, blockId: BlockId) {
        switch action {
        case .delete:
            actionHandler.handleAction(.delete, blockId: blockId)
        case .duplicate:
            actionHandler.handleAction(.duplicate, blockId: blockId)
        case .moveTo:
            router.showMoveTo { [weak self] targetId in
                self?.actionHandler.handleAction(
                    .moveTo(targetId: targetId), blockId: blockId
                )
            }
        }
    }
}
