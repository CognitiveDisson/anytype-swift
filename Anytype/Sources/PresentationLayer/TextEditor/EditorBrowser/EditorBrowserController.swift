import UIKit
import BlocksModels
import AnytypeCore

protocol EditorBrowser: AnyObject {
    func pop()
    func goToHome(animated: Bool)
    func showPage(data: EditorScreenData)
}

protocol EditorBrowserViewInputProtocol: AnyObject {
    func setNavigationViewHidden(_ isHidden: Bool, animated: Bool)
}

final class EditorBrowserController: UIViewController, UINavigationControllerDelegate, EditorBrowser, EditorBrowserViewInputProtocol {
        
    var childNavigation: UINavigationController!
    var router: EditorRouterProtocol!

    private lazy var navigationView: EditorBottomNavigationView = createNavigationView()
    private var navigationViewHeighConstaint: NSLayoutConstraint?
    
    private let stateManager = BrowserNavigationManager()

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    func setup() {
        childNavigation.delegate = self
        
        view.addSubview(navigationView) {
            $0.pinToSuperview(excluding: [.top, .bottom])
            $0.bottom.equal(to: view.safeAreaLayoutGuide.bottomAnchor)
            navigationViewHeighConstaint = $0.height.equal(to: 0)
            navigationViewHeighConstaint?.isActive = false
        }

        embedChild(childNavigation, into: view)
        childNavigation.view.layoutUsing.anchors {
            $0.pinToSuperview(excluding: [.bottom])
            $0.bottom.equal(to: navigationView.topAnchor)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navigationController = navigationController as? iOS14SwiftUINavigationController {
            navigationController.anytype_setNavigationBarHidden(true, animated: false)
        } else {
            navigationController?.setNavigationBarHidden(true, animated: false)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let navigationController = navigationController as? iOS14SwiftUINavigationController {
            navigationController.anytype_setNavigationBarHidden(false, animated: false)
        }
    }
    
    // MARK: - Views
    private func createNavigationView() -> EditorBottomNavigationView {
        EditorBottomNavigationView(
            onBackTap: { [weak self] in
                self?.pop()
            },
            onBackPageTap: { [weak self] page in
                guard let self = self else { return }
                guard let controller = page.controller else { return }
                do {
                    try self.stateManager.moveBack(page: page)
                } catch let error {
                    anytypeAssertionFailure(error.localizedDescription, domain: .editorBrowser)
                    self.navigationController?.popViewController(animated: true)
                }

                self.childNavigation.popToViewController(controller, animated: true)
            },
            onForwardTap: { [weak self] in
                guard let self = self else { return }
                guard let page = self.stateManager.closedPages.last else { return }
                guard self.stateManager.moveForwardOnce() else { return }
                
                self.router.showPage(data: page.pageData)
            },
            onForwardPageTap: { [weak self] page in
                guard let self = self else { return }
                do {
                    try self.stateManager.moveForward(page: page)
                } catch let error {
                    anytypeAssertionFailure(error.localizedDescription, domain: .editorBrowser)
                    self.navigationController?.popViewController(animated: true)
                }
                
                self.router.showPage(data: page.pageData)
            },
            onHomeTap: { [weak self] in
                self?.goToHome(animated: true)
            },
            onSearchTap: { [weak self] in
                self?.router.showSearch { data in
                    self?.router.showPage(data: data)
                }
            }
        )
    }
    
    func pop() {        
        if childNavigation.children.count > 1 {
            childNavigation.popViewController(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    func goToHome(animated: Bool) {
        navigationController?.popViewController(animated: animated)
    }
    
    func showPage(data: EditorScreenData) {
        router.showPage(data: data)
    }

    func setNavigationViewHidden(_ isHidden: Bool, animated: Bool) {
        UIView.animate(
            withDuration: animated ? 0.3 : 0,
            delay: 0,
            options: [.curveEaseIn]) { [weak self] in
                self?.navigationViewHeighConstaint?.isActive = isHidden
                self?.view.layoutIfNeeded()
            } completion: { didComplete in

            }
    }
    
    // MARK: - Unavailable
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UINavigationControllerDelegate
        
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        guard let detailsProvider = viewController as? DocumentDetaisProvider else {
            anytypeAssertionFailure("Not supported browser controller: \(viewController)", domain: .editorBrowser)
            return
        }
        
        UserDefaultsConfig.storeOpenedScreenData(detailsProvider.screenData)
        
        let details = detailsProvider.details
        let title = details?.title
        let subtitle = details?.description
        do {
            try stateManager.didShow(
                page: BrowserPage(
                    pageData: detailsProvider.screenData,
                    title: title,
                    subtitle: subtitle,
                    controller: viewController
                ),
                childernCount: childNavigation.children.count
            )
        } catch let error {
            anytypeAssertionFailure(error.localizedDescription, domain: .editorBrowser)
            self.navigationController?.popViewController(animated: true)
        }
        
        navigationView.update(
            openedPages: stateManager.openedPages,
            closedPages: stateManager.closedPages
        )
    }
}
