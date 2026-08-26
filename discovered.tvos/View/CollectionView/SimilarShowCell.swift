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
    private let playButtonOverlay = UIButton()
    private let overlayView = UIView()

    var onPlayButtonTapped: (() -> Void)?

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

        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlayView.alpha = 0
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        posterImageView.addSubview(overlayView)

        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = UIColor.red
        config.baseForegroundColor = .white
        playButtonOverlay.configuration = config
        playButtonOverlay.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButtonOverlay.addTarget(self, action: #selector(playButtonTapped), for: .primaryActionTriggered)
        playButtonOverlay.alpha = 0
        playButtonOverlay.translatesAutoresizingMaskIntoConstraints = false
        posterImageView.addSubview(playButtonOverlay)

        NSLayoutConstraint.activate([
            posterImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            posterImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            posterImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            posterImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            overlayView.topAnchor.constraint(equalTo: posterImageView.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: posterImageView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: posterImageView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: posterImageView.bottomAnchor),

            playButtonOverlay.centerXAnchor.constraint(equalTo: posterImageView.centerXAnchor),
            playButtonOverlay.centerYAnchor.constraint(equalTo: posterImageView.centerYAnchor),
            playButtonOverlay.widthAnchor.constraint(equalToConstant: 60),
            playButtonOverlay.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    func configure(with item: ShowItem) {
        posterImageView.image = UIImage(named: item.imageName) ?? UIImage(named: "")
    }

    func configure(with video: RelatedVideo) {
        posterImageView.setImage(from: video.ThumbImage)
    }

    override var canBecomeFocused: Bool { true }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        coordinator.addCoordinatedAnimations({
            if self.isFocused {
                self.contentView.layer.borderWidth = 3.5
                self.contentView.layer.borderColor = UIColor.white.cgColor
                self.transform = CGAffineTransform(scaleX: 1.06, y: 1.06)
                self.overlayView.alpha = 1
                self.playButtonOverlay.alpha = 1
            } else {
                self.contentView.layer.borderWidth = 0
                self.contentView.layer.borderColor = UIColor.clear.cgColor
                self.transform = .identity
                self.overlayView.alpha = 0
                self.playButtonOverlay.alpha = 0
            }
        }, completion: nil)
    }

    @objc private func playButtonTapped() {
        onPlayButtonTapped?()
    }
}
