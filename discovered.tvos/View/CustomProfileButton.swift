//
//  CustomProfileButton.swift
//  discovered.tvos
//
//  Created by mac mini on 17/08/26.
//

import Foundation
import UIKit

class CustomProfileButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        setTitle("Visit Profile", for: .normal)
        titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        setTitleColor(.white, for: .normal)
        backgroundColor = UIColor(white: 0.16, alpha: 0.95)
        layer.cornerRadius = 8
        layer.borderWidth = 1.2
        layer.borderColor = UIColor(white: 0.38, alpha: 1.0).cgColor
        clipsToBounds = true
    }   

    override var canBecomeFocused: Bool { true }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)

        coordinator.addCoordinatedAnimations({
            if self.isFocused {
                self.backgroundColor = UIColor(white: 0.94, alpha: 1.0)
                self.setTitleColor(UIColor(white: 0.10, alpha: 1.0), for: .normal)
                self.layer.borderColor = UIColor.white.cgColor
                self.layer.borderWidth = 3
                self.transform = CGAffineTransform(scaleX: 1.06, y: 1.06)
            } else {
                self.backgroundColor = UIColor(white: 0.16, alpha: 0.95)
                self.setTitleColor(.white, for: .normal)
                self.layer.borderColor = UIColor(white: 0.38, alpha: 1.0).cgColor
                self.layer.borderWidth = 1.2
                self.transform = .identity
            }
        }, completion: nil)
    }
}
