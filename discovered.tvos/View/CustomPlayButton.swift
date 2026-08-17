//
//  CustomPlayButton.swift
//  discovered.tvos
//
//  Created by mac mini on 17/08/26.
//

import Foundation
import UIKit
// MARK: - Custom Red Play Button
class CustomPlayButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        setTitle(" ▶   Play", for: .normal)
        titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        setTitleColor(.white, for: .normal)
        backgroundColor = UIColor(red: 0.88, green: 0.08, blue: 0.08, alpha: 1.0)
        layer.cornerRadius = 8
        clipsToBounds = true
    }

    override var canBecomeFocused: Bool { true }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)

        coordinator.addCoordinatedAnimations({
            if self.isFocused {
                // Focus hone par Red color maintain rahega + White border + slight scale up
                self.backgroundColor = UIColor(red: 0.95, green: 0.12, blue: 0.12, alpha: 1.0)
                self.layer.borderWidth = 3
                self.layer.borderColor = UIColor.white.cgColor
                self.transform = CGAffineTransform(scaleX: 1.08, y: 1.08)
            } else {
                self.backgroundColor = UIColor(red: 0.88, green: 0.08, blue: 0.08, alpha: 1.0)
                self.layer.borderWidth = 0
                self.layer.borderColor = UIColor.clear.cgColor
                self.transform = .identity
            }
        }, completion: nil)
    }
}
