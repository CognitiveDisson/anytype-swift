import SwiftUI
import Services
import AnytypeCore

final class EditorSetHostingController: UIHostingController<EditorSetView> {
    
    let objectId: BlockId
    let model: EditorSetViewModel
    
    init(objectId: BlockId, model: EditorSetViewModel) {
        self.objectId = objectId
        self.model = model
        
        super.init(rootView: EditorSetView(model: model))
        navigationItem.hidesBackButton = true
    }
    
    @MainActor @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        model.onWillDisappear()
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
}
