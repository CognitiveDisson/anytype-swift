import UIKit
import SwiftUI
import AnytypeCore


struct EditingTemplateView: View, KeyboardReadable {
    var editorView: AnyView
    
    var body: some View {
        VStack {
            ZStack(alignment: .center) {
                AnytypeText(Loc.TemplateEditing.title, style: .uxTitle2Medium, color: .Text.primary)
                HStack(alignment: .center) {
                    Spacer()
                    Button {
                        
                    } label: {
                        Image(asset: .X24.more)
                    }
                    
                }
                .padding(12)
            }
            .frame(height: 48)
            editorView
        }
        .overlay(alignment: .bottom) {
            StandardButton(model: .)
        }
    }
}


//final class EditingTemplateViewController: UIViewController {
//    private let editorViewController: UIViewController
//    private lazy var settingsNavigationButton = UIBarButtonItem(
//        image: .init(asset: .X24.more),
//        style: .plain,
//        target: self,
//        action: #selector(didTapSettingButton)
//    )
//
//    init(editorViewController: UIViewController) {
//        self.editorViewController = editorViewController
//
//        super.init(nibName: nil, bundle: nil)
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        navigationItem.title = Loc.TemplateEditing.title
//        navigationItem.rightBarButtonItem = settingsNavigationButton
//
//        view.backgroundColor = .Background.primary
//
//        embedChild(editorViewController, into: view)
//        editorViewController.view.layoutUsing.anchors {
//            $0.pinToSuperviewPreservingReadability(excluding: [.bottom])
//            $0.bottom.equal(to: view.bottomAnchor)
//        }
//    }
//
//    @objc
//    private func didTapSettingButton() {
//
//    }
//}
