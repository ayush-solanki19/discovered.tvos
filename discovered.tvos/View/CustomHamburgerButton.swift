//
//  CustomHamburgerButton.swift
//  discovered.tvos
//
//  Created by mac mini on 17/08/26.
//

import Foundation

import UIKit

class CustomHamburgerButton: UIButton {
    private let iconImageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
    }

    private func setupLayout() {
        layer.cornerRadius = 10
        clipsToBounds = true

        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        iconImageView.image = UIImage(systemName: "line.horizontal.3", withConfiguration: config)?.withRenderingMode(.alwaysTemplate)
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconImageView)

        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24)
        ])

        updateAppearance()
    }

    override var canBecomeFocused: Bool { true }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        coordinator.addCoordinatedAnimations({
            self.updateAppearance()
        }, completion: nil)
    }

    private func updateAppearance() {
        if isFocused {
            layer.borderWidth = 2.5
            layer.borderColor = UIColor.white.cgColor
            backgroundColor = UIColor(white: 0.94, alpha: 1.0)
            iconImageView.tintColor = UIColor(white: 0.10, alpha: 1.0)
            transform = CGAffineTransform(scaleX: 1.08, y: 1.08)
        } else {
            layer.borderWidth = 0
            layer.borderColor = UIColor.clear.cgColor
            backgroundColor = UIColor(white: 0.18, alpha: 0.9)
            iconImageView.tintColor = .white
            transform = .identity
            }
    }
}
