//
//  EditorNavigationBarTitleView.swift
//  EditorNavigationBarTitleView
//
//  Created by Konstantin Mordan on 18.08.2021.
//  Copyright © 2021 Anytype. All rights reserved.
//

import Foundation
import UIKit

final class EditorNavigationBarTitleView: UIView {
    
    private let stackView = UIStackView()
    
    private let iconImageView = ObjectIconImageView()
    private let titleLabel = UILabel()
    
    init() {
        super.init(frame: .zero)
        setupView()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension EditorNavigationBarTitleView: ConfigurableView {
    
    struct Model {
        let icon: ObjectIconImage?
        let title: String
    }
    
    func configure(model: Model) {
        titleLabel.text = model.title
        
        switch model.icon {
        case .some(let objectIconImage):
            iconImageView.isHidden = false
            iconImageView.configure(
                model: ObjectIconImageView.Model(
                    iconImage: objectIconImage,
                    usecase: .openedObjectNavigationBar
                )
            )
        case .none:
            iconImageView.isHidden = true
        }
    }
    
    /// Parents alpha sets automatically by system when it attaches to NavigationBar. 
    func setAlphaForSubviews(_ alpha: CGFloat) {
        titleLabel.alpha = alpha
        iconImageView.alpha = alpha
    }
    
}

private extension EditorNavigationBarTitleView {
    
    func setupView() {
        titleLabel.font = .uxCalloutRegular
        titleLabel.textColor = .textPrimary
        titleLabel.numberOfLines = 1
        
        iconImageView.contentMode = .scaleAspectFit
        
        stackView.axis = .horizontal
        stackView.spacing = 8
        
        setupLayout()        
    }
    
    func setupLayout() {
        addSubview(stackView) {
            $0.pinToSuperview()
        }
        
        stackView.addArrangedSubview(iconImageView)
        stackView.addArrangedSubview(titleLabel)
        
        iconImageView.layoutUsing.anchors {
            $0.size(CGSize(width: 18, height: 18))
        }
    }
    
}
