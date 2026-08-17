//
//  SideMenuCapsuleButton.swift
//  discovered.tvos
//
//  Created by mac mini on 17/08/26.
//

import Foundation

import UIKit

class SideMenuCapsuleButton: UIButton {
    private let iconImageView = UIImageView()
    private let nameLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
    }

    private func setupLayout() {
        layer.cornerRadius = 24
        clipsToBounds = true

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconImageView)

        nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nameLabel)

        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 22),
            iconImageView.heightAnchor.constraint(equalToConstant: 22),

            nameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 14),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            nameLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        updateAppearance()
    }

    func configure(with item: SideMenuItem) {
        self.tag = item.id
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        iconImageView.image = UIImage(systemName: item.iconName, withConfiguration: config)?.withRenderingMode(.alwaysTemplate)
        nameLabel.text = item.title
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
            backgroundColor = UIColor(white: 0.94, alpha: 1.0)
            iconImageView.tintColor = UIColor(white: 0.10, alpha: 1.0)
            nameLabel.textColor = UIColor(white: 0.10, alpha: 1.0)
            transform = CGAffineTransform(scaleX: 1.02, y: 1.02)
        } else {
            backgroundColor = UIColor(white: 0.18, alpha: 1.0)
            iconImageView.tintColor = UIColor(white: 0.75, alpha: 1.0)
            nameLabel.textColor = UIColor(white: 0.75, alpha: 1.0)
            transform = .identity
        }
    }
}
