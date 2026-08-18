import UIKit

class RelatedVideoGridCell: UICollectionViewCell {
    static let reuseIdentifier = "RelatedVideoGridCell"

    private let posterImageView = UIImageView()
    private let overlayView = UIView()
    private let playButtonOverlay = UIButton()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
    }

    private func setupLayout() {
        contentView.layer.cornerRadius = 6
        contentView.clipsToBounds = true
        contentView.backgroundColor = UIColor(white: 0.15, alpha: 1.0)

        posterImageView.contentMode = .scaleAspectFill
        posterImageView.clipsToBounds = true
        posterImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(posterImageView)

        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        overlayView.alpha = 0
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        posterImageView.addSubview(overlayView)

        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = UIColor.red
        config.baseForegroundColor = .white
        playButtonOverlay.configuration = config
        playButtonOverlay.setImage(UIImage(systemName: "play.fill"), for: .normal)
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
            playButtonOverlay.widthAnchor.constraint(equalToConstant: 50),
            playButtonOverlay.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    func configure(with video: RelatedVideo) {
        posterImageView.setImage(from: video.ThumbImage)
    }

    override var canBecomeFocused: Bool { true }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        coordinator.addCoordinatedAnimations({
            if self.isFocused {
                self.contentView.layer.borderWidth = 2.5
                self.contentView.layer.borderColor = UIColor.white.cgColor
                self.transform = CGAffineTransform(scaleX: 1.08, y: 1.08)
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
}
