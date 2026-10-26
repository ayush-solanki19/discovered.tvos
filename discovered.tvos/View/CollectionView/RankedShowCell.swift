//
//  RankedShowCell.swift
//  discovered.tvos
//

import UIKit

/// "Top 10" card: a big outlined rank number with the poster
/// overlapping its right edge (Netflix style).
class RankedShowCell: UICollectionViewCell {
    static let reuseIdentifier = "RankedShowCell"

    /// Width of the poster inside the cell. The rest of the cell
    /// (on the left) is room for the rank number.
    static let posterWidth: CGFloat = 150

    private let rankLabel = UILabel()
    private let posterView = UIView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let overlayView = UIView()
    private let playButtonOverlay = UIButton()

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
        contentView.clipsToBounds = false

        // Rank number sits BEHIND the poster.
        rankLabel.textAlignment = .left
        rankLabel.adjustsFontSizeToFitWidth = true
        rankLabel.minimumScaleFactor = 0.5
        rankLabel.baselineAdjustment = .alignCenters
        rankLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(rankLabel)

        posterView.layer.cornerRadius = 6
        posterView.clipsToBounds = true
        posterView.backgroundColor = UIColor(white: 0.14, alpha: 1)
        posterView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(posterView)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        posterView.addSubview(imageView)

        titleLabel.font = .appFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.backgroundColor = UIColor.black.withAlphaComponent(0.46)
        posterView.addSubview(titleLabel)

        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlayView.alpha = 0
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        posterView.addSubview(overlayView)

        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = UIColor.red
        config.baseForegroundColor = .white
        playButtonOverlay.configuration = config
        playButtonOverlay.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButtonOverlay.addTarget(self, action: #selector(playButtonTapped), for: .primaryActionTriggered)
        playButtonOverlay.alpha = 0
        playButtonOverlay.translatesAutoresizingMaskIntoConstraints = false
        posterView.addSubview(playButtonOverlay)

        NSLayoutConstraint.activate([
            posterView.topAnchor.constraint(equalTo: contentView.topAnchor),
            posterView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            posterView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            posterView.widthAnchor.constraint(equalToConstant: Self.posterWidth),

            // Number starts at the left edge and runs ~40pt under the poster.
            rankLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            rankLabel.trailingAnchor.constraint(equalTo: posterView.leadingAnchor, constant: 40),
            rankLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            rankLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            imageView.topAnchor.constraint(equalTo: posterView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: posterView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: posterView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: posterView.bottomAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: posterView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: posterView.trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: posterView.bottomAnchor),
            titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 28),

            overlayView.topAnchor.constraint(equalTo: posterView.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: posterView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: posterView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: posterView.bottomAnchor),

            playButtonOverlay.centerXAnchor.constraint(equalTo: posterView.centerXAnchor),
            playButtonOverlay.centerYAnchor.constraint(equalTo: posterView.centerYAnchor),
            playButtonOverlay.widthAnchor.constraint(equalToConstant: 56),
            playButtonOverlay.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    func configure(with item: ShowItem, rank: Int) {
        titleLabel.text = item.title

        // Outline-only digits (positive stroke width = no fill).
        rankLabel.attributedText = NSAttributedString(
            string: "\(rank)",
            attributes: [
                .font: UIFont.appFont(ofSize: 210, weight: .heavy),
                .strokeColor: UIColor(white: 0.42, alpha: 1),
                .strokeWidth: 3,
                .kern: -12
            ]
        )

        if item.imageName.hasPrefix("http") {
            imageView.setImage(from: item.imageName)
        } else {
            imageView.image = UIImage(named: item.imageName)
        }
    }

    override var canBecomeFocused: Bool { true }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)

        coordinator.addCoordinatedAnimations({
            if self.isFocused {
                self.posterView.layer.borderWidth = 3
                self.posterView.layer.borderColor = UIColor.white.cgColor
                self.transform = CGAffineTransform(scaleX: 1.04, y: 1.04)
                self.overlayView.alpha = 1
                self.playButtonOverlay.alpha = 1
            } else {
                self.posterView.layer.borderWidth = 0
                self.posterView.layer.borderColor = UIColor.clear.cgColor
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
