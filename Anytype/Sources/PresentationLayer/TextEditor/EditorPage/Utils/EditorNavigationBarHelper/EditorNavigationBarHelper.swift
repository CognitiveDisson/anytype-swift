import Foundation
import UIKit
import BlocksModels

final class EditorNavigationBarHelper {
    
    private let fakeNavigationBarBackgroundView = UIView()
    private let navigationBarTitleView = EditorNavigationBarTitleView()
    
    private let settingsItem: EditorBarButtonItemView
    private let syncStatusItem: EditorBarButtonItemView
    
    private var contentOffsetObservation: NSKeyValueObservation?
    
    private var isObjectHeaderWithCover = false
    private var objectHeaderHeight: CGFloat = 0.0
        
    init(onSettingsBarButtonItemTap: @escaping () -> Void) {
        self.settingsItem = EditorBarButtonItemView(
            style: .settings(image: .editorNavigation.more, action: onSettingsBarButtonItemTap)
        )
        
        let greenCircle = ImageBuilder(
            .init(
                size: CGSize(width: 10, height: 10),
                cornersGuideline: .init(radius: 5, borderColor: nil)
            )
        )
            .setImageColor(.pureGreen).build()
        self.syncStatusItem = EditorBarButtonItemView(
            style: .syncStatus(image: greenCircle, title: "Synced", description: "Backed up on one node at least")
        )
        
        self.fakeNavigationBarBackgroundView.backgroundColor = .backgroundPrimary
        self.fakeNavigationBarBackgroundView.alpha = 0.0
        
        self.navigationBarTitleView.setAlphaForSubviews(0.0)
    }
    
}

// MARK: - EditorNavigationBarHelperProtocol

extension EditorNavigationBarHelper: EditorNavigationBarHelperProtocol {
    
    func addFakeNavigationBarBackgroundView(to view: UIView) {
        view.addSubview(fakeNavigationBarBackgroundView) {
            $0.top.equal(to: view.topAnchor)
            $0.leading.equal(to: view.leadingAnchor)
            $0.trailing.equal(to: view.trailingAnchor)
            $0.bottom.equal(to: view.layoutMarginsGuide.topAnchor)
        }
    }
    
    func handleViewWillAppear(_ vc: UIViewController?, _ scrollView: UIScrollView) {
        guard let vc = vc else { return }
        
        configureNavigationItem(in: vc)
        
        contentOffsetObservation = scrollView.observe(
            \.contentOffset,
            options: .new
        ) { [weak self] scrollView, _ in
            self?.updateNavigationBarAppearanceBasedOnContentOffset(scrollView.contentOffset.y + scrollView.contentInset.top)
        }
    }
    
    func handleViewWillDisappear() {
        contentOffsetObservation?.invalidate()
        contentOffsetObservation = nil
    }
    
    func configureNavigationBar(using header: ObjectHeader, details: DetailsDataProtocol?) {
        isObjectHeaderWithCover = header.isWithCover
        objectHeaderHeight = header.height
        
        updateBarButtonItemsBackground(alpha: isObjectHeaderWithCover ? 1.0 : 0.0)
        
        let title: String = {
            guard
                let string = details?.name, !string.isEmpty
            else {
                return "Untitled".localized
            }
            
            return string
        }()
        
        navigationBarTitleView.configure(
            model: EditorNavigationBarTitleView.Model(
                icon: details?.objectIconImage,
                title: title
            )
        )
    }
    
}

// MARK: - Private extension

private extension EditorNavigationBarHelper {
    
    func configureNavigationItem(in vc: UIViewController) {
        vc.navigationItem.titleView = navigationBarTitleView
        vc.navigationItem.backBarButtonItem = nil
        vc.navigationItem.hidesBackButton = true
        
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(
            customView: settingsItem
        )
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(
            customView: syncStatusItem
        )
    }
    
    func updateBarButtonItemsBackground(alpha: CGFloat) {
        [settingsItem, syncStatusItem].forEach {
            guard !$0.backgroundAlpha.isEqual(to: alpha) else { return }
            
            $0.backgroundAlpha = alpha
        }
    }
    
    func updateNavigationBarAppearanceBasedOnContentOffset(_ newOffset: CGFloat) {
        let startAppearingOffset = objectHeaderHeight - 50
        let endAppearingOffset = objectHeaderHeight

        let navigationBarHeight = fakeNavigationBarBackgroundView.bounds.height
        
        let yFullOffset = newOffset + navigationBarHeight

        let alpha: CGFloat? = {
            if yFullOffset < startAppearingOffset {
                return 0
            } else if yFullOffset > endAppearingOffset {
                return 1
            } else if yFullOffset > startAppearingOffset, yFullOffset < endAppearingOffset {
                let currentDiff = yFullOffset - startAppearingOffset
                let max = endAppearingOffset - startAppearingOffset
                return currentDiff / max
            }
            
            return nil
        }()
        
        guard let alpha = alpha else {
            return
        }
        
        let barButtonItemsBackgroundAlpha: CGFloat = {
            guard isObjectHeaderWithCover else { return 0.0 }
            
            switch alpha {
            case 0.0:
                return isObjectHeaderWithCover ? 1.0 : 0.0
            default:
                return 1.0 - alpha
            }
        }()

        navigationBarTitleView.setAlphaForSubviews(alpha)
        updateBarButtonItemsBackground(alpha: barButtonItemsBackgroundAlpha)
        fakeNavigationBarBackgroundView.alpha = alpha
    }
    
}

// MARK: - ObjectHeader

private extension ObjectHeader {
    
    var isWithCover: Bool {
        switch self {
        case .filled(let filledState):
            return filledState.isWithCover
        case .empty:
            return false
        }
    }
    
    var height: CGFloat {
        switch self {
        case .filled:
            return ObjectHeaderView.Constants.height
            
        case .empty:
            return ObjectHeaderEmptyContentView.Constants.height
        }
    }
    
}
