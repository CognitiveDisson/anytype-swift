import UIKit
import BlocksModels
import Combine

protocol AccessoryViewSwitcherProtocol {
    func updateData(data: TextBlockDelegateData)
    
    func restoreDefaultState()
    
    func showURLInput(url: URL?)
    func showDefaultView()
    func showSlashMenuView()
    func showMentionsView()
}

final class AccessoryViewSwitcher: AccessoryViewSwitcherProtocol {
    private(set) var activeView = AccessoryViewType.none
    private(set) var data: TextBlockDelegateData?
    
    private let cursorModeAccessoryView: CursorModeAccessoryView
    private let mentionsView: MentionView
    private let slashMenuView: SlashMenuView
    private let changeTypeView: ChangeTypeAccessoryView
    private let markupAccessoryView: MarkupAccessoryView
    private let urlInputView: URLInputAccessoryView
    
    private let document: BaseDocumentProtocol

    init(
        mentionsView: MentionView,
        slashMenuView: SlashMenuView,
        cursorModeAccessoryView: CursorModeAccessoryView,
        markupAccessoryView: MarkupAccessoryView,
        changeTypeView: ChangeTypeAccessoryView,
        urlInputView: URLInputAccessoryView,
        document: BaseDocumentProtocol
    ) {
        self.slashMenuView = slashMenuView
        self.cursorModeAccessoryView = cursorModeAccessoryView
        self.markupAccessoryView = markupAccessoryView
        self.changeTypeView = changeTypeView
        self.mentionsView = mentionsView
        self.urlInputView = urlInputView
        self.document = document
        
        setupDismissHandlers()
    }

    // MARK: - Public methods
    
    func updateData(data: TextBlockDelegateData) {
        self.data = data
        
        cursorModeAccessoryView.update(info: data.block.information, textView: data.textView)
        markupAccessoryView.update(block: data.block, textView: data.textView)
        slashMenuView.update(info: data.info, relations: document.parsedRelations.all)

        if data.textView.selectedRange.length != .zero {
            showMarkupView(range: data.textView.selectedRange)
        } else {
            showDefaultView()
        }
    }
    
    func showMentionsView() {
        showAccessoryView(.mention(mentionsView))
    }
    
    func showSlashMenuView() {
        showAccessoryView(.slashMenu(slashMenuView))
    }

    func showMarkupView(range: NSRange) {
        markupAccessoryView.selectionChanged(range: range)
        showAccessoryView(.markup(markupAccessoryView))
    }

    func updateSelection(range: NSRange) {
        markupAccessoryView.selectionChanged(range: range)
    }

    func showDefaultView() {
        markupAccessoryView.selectionChanged(range: .zero)

        let accessoryView: AccessoryViewType =
            document.isDocumentEmpty && !document.objectRestrictions.objectRestriction.contains(.typechange)
                ? .changeType(changeTypeView)
                : .default(cursorModeAccessoryView)

        showAccessoryView(accessoryView, animation: activeView.animation)
    }
    
    func showURLInput(url: URL?) {
        guard let data = data else { return }
        
        urlInputView.updateUrlData(.init(data: data, url: url))
        showAccessoryView(.urlInput(urlInputView))
        _ = urlInputView.becomeFirstResponder()
    }
    
    func restoreDefaultState() {
        slashMenuView.restoreDefaultState()
        showDefaultView()
    }
    
    // MARK: - Private methods
    private func showAccessoryView(_ view: AccessoryViewType, animation: Bool = false) {
        guard let textView = data?.textView else { return }
        
        activeView = view
        
        changeAccessoryView(view.view, animation: animation)
        
        if let view = view.view as? DismissableInputAccessoryView {
            view.didShow(from: textView)
        }
    }
    
    private func changeAccessoryView(_ accessoryView: UIView?, animation: Bool = false) {
        guard let accessoryView = accessoryView,
              let textView = data?.textView,
              textView.inputAccessoryView != accessoryView else {
            return
        }
        
        textView.inputAccessoryView = accessoryView

        let reloadInputViews = {
            accessoryView.transform = .identity
            textView.reloadInputViews()
            textView.window?.layoutIfNeeded()
        }
        accessoryView.transform = CGAffineTransform(translationX: 0, y: accessoryView.bounds.size.height)

        if animation {
            UIView.animate(withDuration: CATransaction.animationDuration()) {
                reloadInputViews()
            }
        } else {
            reloadInputViews()
        }
    }
    
    private func setupDismissHandlers() {
        let dismiss = { [weak self] in
            guard let self = self else { return }
            self.restoreDefaultState()
        }

        mentionsView.dismissHandler = dismiss
        slashMenuView.dismissHandler = dismiss
        urlInputView.dismissHandler = dismiss
    }
}
