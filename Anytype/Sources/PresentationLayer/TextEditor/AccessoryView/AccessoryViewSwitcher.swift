import UIKit
import BlocksModels
import Combine

protocol AccessoryViewSwitcherProtocol: EditorAccessoryViewDelegate {
    func showURLInput(url: URL?)
    
    func didBeginEditing(data: AccessoryViewSwitcherData)
        
    func textDidChange()
    func textWillChange(replacementText: String, range: NSRange)
}

final class AccessoryViewSwitcher: AccessoryViewSwitcherProtocol {
    private(set) var triggerSymbolPosition: UITextPosition?
    
    private var activeView = AccessoryViewType.none
    
    private var latestTextViewTextChange: TextViewTextChangeType?
    
    private let accessoryView: EditorAccessoryView
    private let mentionsView: MentionView
    private let slashMenuView: SlashMenuView
    private let changeTypeView: ChangeTypeAccessoryView

    private let document: BaseDocumentProtocol

    private lazy var urlInputView = buildURLInputView()
    
    let handler: EditorActionHandlerProtocol
    var data: AccessoryViewSwitcherData?
    private var cancellables = [AnyCancellable]()

    private var editorAccessoryView: AccessoryViewType {
        document.isDocumentEmpty ? .changeType(changeTypeView) : .default(accessoryView)
    }

    init(
        mentionsView: MentionView,
        slashMenuView: SlashMenuView,
        accessoryView: EditorAccessoryView,
        changeTypeView: ChangeTypeAccessoryView,
        handler: EditorActionHandlerProtocol,
        document: BaseDocumentProtocol
    ) {
        self.slashMenuView = slashMenuView
        self.accessoryView = accessoryView
        self.changeTypeView = changeTypeView
        self.mentionsView = mentionsView
        self.handler = handler
        self.document = document
        
        setupDismissHandlers()
    }

    // MARK: - Public methods
    func showMentionsView() {
        showAccessoryView(.mention(mentionsView))
    }
    
    func showSlashMenuView() {
        showAccessoryView(.slashMenu(slashMenuView))
    }
    
    func didBeginEditing(data: AccessoryViewSwitcherData) {
        self.data = data
        
        accessoryView.update(block: data.block, textView: data.textView)
        showAccessoryView(editorAccessoryView)
        
        slashMenuView.update(block: data.block)
    }

    func textWillChange(replacementText: String, range: NSRange) {
        guard let data = data else { return }
        
        latestTextViewTextChange = data.textView.textView.textChangeType(
            changeTextRange: range,
            replacementText: replacementText
        )
    }

    func textDidChange() {
        switch activeView {
        case .`default`, .changeType:
            let editorAccessoryView = editorAccessoryView

            if activeView != editorAccessoryView {
                showAccessoryView(editorAccessoryView)
            }
        default:
            break
        }

        if isSlashOrMentionCurrentlyVisible() {
            setTextToSlashOrMention()
            return
        }
        
        switch latestTextViewTextChange {
        case .typingSymbols:
            displaySlashOrMentionIfNeeded()
        case .none, .deletingSymbols:
            return
        }
    }
    
    func showURLInput(url: URL?) {
        urlInputView.updateUrl(url)
        showAccessoryView(.urlInput(urlInputView))
        urlInputView.urlInputView.textField.becomeFirstResponder()
        cleanupDisplayedView()
    }
    
    // MARK: - Private methods
    private func cleanupDisplayedView() {
        slashMenuView.restoreDefaultState()
        
        activeView = .none
        triggerSymbolPosition = nil
    }
    
    private func showAccessoryView(_ view: AccessoryViewType) {
        guard let textView = data?.textView.textView else { return }
        
        activeView = view
        triggerSymbolPosition = textView.caretPosition
        
        changeAccessoryView(view.view)
        
        if let view = view.view as? DismissableInputAccessoryView {
            view.didShow(from: textView)
        }
    }
    
    private func changeAccessoryView(_ accessoryView: UIView?) {
        guard let accessoryView = accessoryView,
              let textView = data?.textView.textView,
              textView.inputAccessoryView != accessoryView else {
            return
        }
        
        textView.inputAccessoryView = accessoryView
        
        accessoryView.transform = CGAffineTransform(translationX: 0, y: accessoryView.bounds.size.height)
        UIView.animate(withDuration: CATransaction.animationDuration()) {
            accessoryView.transform = .identity
            textView.reloadInputViews()
            textView.window?.layoutIfNeeded()
        }
    }
    
    private func isSlashOrMentionCurrentlyVisible() -> Bool {
        switch activeView {
        case .mention, .slashMenu:
            return true
        default:
            return false
        }
    }
    
    private func setTextToSlashOrMention() {
        guard let filterText = searchText() else { return }
        
        switch activeView {
        case .mention(let view):
            view.setFilterText(filterText: filterText)
            dismissViewIfNeeded()
        case .slashMenu(let view):
            view.setFilterText(filterText: filterText)
            dismissViewIfNeeded(forceDismiss: view.shouldDismiss)
        default:
            break
        }
    }
    
    private func dismissViewIfNeeded(forceDismiss: Bool = false) {
        if forceDismiss || isTriggerSymbolDeleted {
            cleanupDisplayedView()
            showAccessoryView(editorAccessoryView)
        }
    }
    
    private var isTriggerSymbolDeleted: Bool {
        guard let triggerSymbolPosition = triggerSymbolPosition,
              let textView = data?.textView.textView,
              let caretPosition = textView.caretPosition else {
            return false
        }
        
        return textView.compare(triggerSymbolPosition, to: caretPosition) == .orderedDescending
    }
    
    private func searchText() -> String? {
        guard let textView = data?.textView.textView else { return nil }
        
        guard let caretPosition = textView.caretPosition,
              let triggerSymbolPosition = triggerSymbolPosition,
              let range = textView.textRange(from: triggerSymbolPosition, to: caretPosition) else {
            return nil
        }
        return textView.text(in: range)
    }
    
    private func displaySlashOrMentionIfNeeded() {
        guard let textView = data?.textView.textView else { return }
        guard let data = data, data.information.content.type != .text(.title) else { return }
        guard let textBeforeCaret = textView.textBeforeCaret else { return }
        guard let caretPosition = textView.caretPosition else { return }
        
        let carretOffset = textView.offsetFromBegining(caretPosition)
        let prependSpace = carretOffset > 1 // We need whitespace before / or @ if it is not 1st symbol
        
        if textBeforeCaret.hasSuffix(TextTriggerSymbols.slashMenu) {
            showAccessoryView(.slashMenu(slashMenuView))
        } else if textBeforeCaret.hasSuffix(
            TextTriggerSymbols.mention(prependSpace: prependSpace)
        ) {
            showAccessoryView(.mention(mentionsView))
        }
    }
    
    private func setupDismissHandlers() {
        let dismissActionsMenu = { [weak self] in
            guard let self = self else { return }
            self.cleanupDisplayedView()
            self.showAccessoryView(.default(self.accessoryView))
        }

        mentionsView.dismissHandler = dismissActionsMenu
        slashMenuView.dismissHandler = dismissActionsMenu
    }
    
    // MARK: - Views
    func buildURLInputView() -> URLInputAccessoryView {
        let dismissHandler = { [weak self] in
            guard let self = self, let textView = self.data?.textView.textView else { return }
            _ = textView.becomeFirstResponder()
            self.showAccessoryView(.default(self.accessoryView))
        }
        let urlInputView = URLInputAccessoryView() { [weak self] url in
            guard let self = self, let data = self.data else { return }
            
            let range = data.textView.textView.selectedRange
            self.handler.handleAction(
                .setLink(data.text.attrString, url, range),
                blockId: data.information.id
            )
            dismissHandler()
        }
        urlInputView.dismissHandler = dismissHandler
        return urlInputView
    }
}