import UIKit
import AVFoundation

class HeroHeaderView: UIView {
    private let heroImageView = UIImageView()
    private let heroGradient = CAGradientLayer()
    private let titleLabel = UILabel()
    private let metaLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let badgeStack = UIStackView()

    // MARK: - Video Layer Properties
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
        heroGradient.frame = bounds
    }

    private func setupLayout() {
        clipsToBounds = true
        backgroundColor = .black

        // 1. Poster Thumbnail Image
        heroImageView.contentMode = .scaleAspectFill
        heroImageView.clipsToBounds = true
        heroImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(heroImageView)

        // 2. Video Player Layer
        playerLayer = AVPlayerLayer()
        playerLayer?.videoGravity = .resizeAspectFill
        if let pLayer = playerLayer {
            layer.addSublayer(pLayer)
        }

        // 3. Gradient Overlay
        heroGradient.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.3).cgColor,
            UIColor.black.withAlphaComponent(0.8).cgColor,
            UIColor.black.cgColor
        ]
        heroGradient.locations = [0.0, 0.4, 0.7, 1.0]
        layer.addSublayer(heroGradient)

        // 4. Content Labels
        titleLabel.numberOfLines = 2
        titleLabel.font = UIFont(name: "Georgia-Italic", size: 42) ?? .italicSystemFont(ofSize: 42)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        metaLabel.font = .systemFont(ofSize: 13, weight: .medium)
        metaLabel.textColor = UIColor.white.withAlphaComponent(0.85)
        metaLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(metaLabel)

        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = .systemFont(ofSize: 14)
        descriptionLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(descriptionLabel)

        badgeStack.axis = .horizontal
        badgeStack.spacing = 8
        badgeStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(badgeStack)

        NSLayoutConstraint.activate([
            heroImageView.topAnchor.constraint(equalTo: topAnchor),
            heroImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            heroImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            heroImageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            titleLabel.bottomAnchor.constraint(equalTo: metaLabel.topAnchor, constant: -10),

            metaLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            metaLabel.bottomAnchor.constraint(equalTo: descriptionLabel.topAnchor, constant: -10),

            descriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            descriptionLabel.bottomAnchor.constraint(equalTo: badgeStack.topAnchor, constant: -14),

            badgeStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            badgeStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -30)
        ])
    }

    // MARK: - Video Playback
    func playVideo(urlString: String?) {
        guard let urlString = urlString, let url = URL(string: urlString) else {
            stopVideo()
            return
        }

        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)

        let playerItem = AVPlayerItem(url: url)
        
        if player == nil {
            player = AVPlayer(playerItem: playerItem)
            playerLayer?.player = player
        } else {
            player?.replaceCurrentItem(with: playerItem)
        }

        // Video ko Mute karein
        player?.isMuted = true
        player?.volume = 0.0
        
        player?.play()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidReachEnd(notification:)),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
    }

    @objc private func playerItemDidReachEnd(notification: Notification) {
        player?.seek(to: .zero)
        player?.play()
    }

    func stopVideo() {
        player?.pause()
    }

    // MARK: - Update Hero Data
    func updateHeroData(title: String, imageName: String, videoUrl: String? = nil) {
        UIView.transition(with: self.titleLabel, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.titleLabel.text = title
        }, completion: nil)

        if imageName.hasPrefix("http") {
            self.heroImageView.setImage(from: imageName, isHeroBanner: true)
        } else {
            self.heroImageView.image = UIImage(named: imageName) ?? UIImage(named: "")
        }

        playVideo(urlString: videoUrl)
    }

    func configure(with hero: HeroContent) {
        titleLabel.text = hero.title
        metaLabel.text = hero.metadata
        descriptionLabel.text = hero.description

        badgeStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for badge in hero.badges {
            let color: UIColor = badge.colorName == "red" ? .red : .darkGray
            badgeStack.addArrangedSubview(makeBadge(badge.text, color))
        }

        if hero.backgroundImageName.hasPrefix("http") {
            heroImageView.setImage(from: hero.backgroundImageName, isHeroBanner: true)
        } else {
            heroImageView.image = UIImage(named: hero.backgroundImageName) ?? UIImage(named: "")
        }

        playVideo(urlString: hero.videoUrl)
    }

    private func makeBadge(_ text: String, _ color: UIColor) -> UIView {
        let container = UIView()
        container.backgroundColor = color.withAlphaComponent(0.85)
        container.layer.cornerRadius = 4

        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 11, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8)
        ])
        return container
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        player?.pause()
        player = nil
    }
}
