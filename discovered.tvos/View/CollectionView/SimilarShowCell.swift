//
//  SimilarShowCell.swift
//  discovered.tvos
//
//  Created by mac mini on 17/08/26.
//

import Foundation
import UIKit

class SimilarShowCell: UICollectionViewCell {
    static let reuseIdentifier = "SimilarShowCell"

    private let posterImageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
    }

    private func setupLayout() {
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true
        contentView.backgroundColor = UIColor(white: 0.12, alpha: 1.0)

        posterImageView.contentMode = .scaleAspectFill
        posterImageView.clipsToBounds = true
        posterImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(posterImageView)

        NSLayoutConstraint.activate([
            posterImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            posterImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            posterImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            posterImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    func configure(with item: ShowItem) {
        posterImageView.image = UIImage(named: item.imageName) ?? UIImage(named: "")
    }

    override var canBecomeFocused: Bool { true }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        coordinator.addCoordinatedAnimations({
            if self.isFocused {
                self.contentView.layer.borderWidth = 3.5
                self.contentView.layer.borderColor = UIColor.white.cgColor
                self.transform = CGAffineTransform(scaleX: 1.06, y: 1.06)
            } else {
                self.contentView.layer.borderWidth = 0
                self.contentView.layer.borderColor = UIColor.clear.cgColor
                self.transform = .identity
            }
        }, completion: nil)
    }
}
