import UIKit
import BlocksModels

enum EditorAccessoryViewAction {
    /// Slash button pressed
    case slashMenu
    /// Done button pressed
    case keyboardDismiss
    /// Show bottom sheet style menu
    case showStyleMenu
    /// Show mention menu
    case mention
    /// Enter editing mode
    case editingMode
}


final class EditorAccessoryViewModel {
    var block: BlockModelProtocol!
    
    weak var customTextView: CustomTextView?
    weak var delegate: EditorAccessoryViewDelegate?
    
    private let handler: EditorActionHandlerProtocol
    private let router: EditorRouter
    
    init(router: EditorRouter, handler: EditorActionHandlerProtocol) {
        self.router = router
        self.handler = handler
    }
    
    func handle(_ action: EditorAccessoryViewAction) {
        guard let textView = customTextView?.textView, let delegate = delegate else {
            return
        }

        switch action {
        case .showStyleMenu:
            router.showStyleMenu(information: block.information)
        case .keyboardDismiss:
            UIApplication.shared.hideKeyboard()
        case .mention:
            textView.insertStringAfterCaret(
                TextTriggerSymbols.mention(prependSpace: shouldPrependSpace(textView: textView))
            )
            
            handler.handleActionForFirstResponder(
                .textView(
                    action: .changeText(textView.attributedText),
                    block: block
                )
            )
            
            delegate.showMentionsView()
        case .slashMenu:
            textView.insertStringAfterCaret(TextTriggerSymbols.slashMenu)
            
            handler.handleActionForFirstResponder(
                .textView(
                    action: .changeText(textView.attributedText),
                    block: block
                )
            )
            
            delegate.showSlashMenuView()
        case .editingMode:
            // Not implemented
            break
        }
    }
    
    private func shouldPrependSpace(textView: UITextView) -> Bool {
        let carretInTheBeginingOfDocument = textView.isCarretInTheBeginingOfDocument
        let haveSpaceBeforeCarret = textView.textBeforeCaret?.last == " "
        
        return !(carretInTheBeginingOfDocument || haveSpaceBeforeCarret)
    }
}