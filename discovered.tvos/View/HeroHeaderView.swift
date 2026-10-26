import UIKit
import AVFoundation

final class HeroHeaderView: UIView {
    private let heroImageView = UIImageView()
    private let gradient = CAGradientLayer()
    private let featuredBadge = UILabel()
    private let titleLabel = UILabel()
    private let metaLabel = UILabel()
    private let descriptionLabel = UILabel()
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var currentVideoUrlString: String?

    override init(frame: CGRect) { super.init(frame: frame); setupLayout() }
    required init?(coder: NSCoder) { super.init(coder: coder); setupLayout() }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
        playerLayer?.frame = bounds
    }

    private func setupLayout() {
        clipsToBounds = true
        layer.cornerRadius = 28
        backgroundColor = UIColor(red: 0.07, green: 0.08, blue: 0.11, alpha: 1)

        heroImageView.contentMode = .scaleAspectFill
        heroImageView.clipsToBounds = true
        heroImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(heroImageView)

        playerLayer = AVPlayerLayer()
        playerLayer?.videoGravity = .resizeAspectFill
        if let playerLayer { layer.insertSublayer(playerLayer, above: heroImageView.layer) }

        gradient.colors = [UIColor.black.withAlphaComponent(0.66).cgColor, UIColor.black.withAlphaComponent(0.20).cgColor, UIColor.black.withAlphaComponent(0.08).cgColor, UIColor.black.withAlphaComponent(0.82).cgColor]
        gradient.locations = [0, 0.38, 0.63, 1]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.55)
        layer.addSublayer(gradient)

        featuredBadge.text = "fgh"
        featuredBadge.textAlignment = .center
        featuredBadge.font = .appFont(ofSize: 12, weight: .bold)
        featuredBadge.textColor = UIColor.white.withAlphaComponent(0.9)
        featuredBadge.backgroundColor = UIColor.white.withAlphaComponent(0.13)
        featuredBadge.layer.cornerRadius = 11
        featuredBadge.clipsToBounds = true
        featuredBadge.translatesAutoresizingMaskIntoConstraints = false
        addSubview(featuredBadge)

        titleLabel.font = .appFont(ofSize: 48, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        metaLabel.font = .appFont(ofSize: 15, weight: .medium)
        metaLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        metaLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(metaLabel)
        descriptionLabel.font = .appFont(ofSize: 17, weight: .regular)
        descriptionLabel.textColor = UIColor.white.withAlphaComponent(0.88)
        descriptionLabel.numberOfLines = 2
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(descriptionLabel)

        NSLayoutConstraint.activate([
            heroImageView.topAnchor.constraint(equalTo: topAnchor), heroImageView.leadingAnchor.constraint(equalTo: leadingAnchor), heroImageView.trailingAnchor.constraint(equalTo: trailingAnchor), heroImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            featuredBadge.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 52), featuredBadge.bottomAnchor.constraint(equalTo: titleLabel.topAnchor, constant: -22), featuredBadge.widthAnchor.constraint(equalToConstant: 92), featuredBadge.heightAnchor.constraint(equalToConstant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 48), titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -48), titleLabel.bottomAnchor.constraint(equalTo: descriptionLabel.topAnchor, constant: -16),
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor), descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -48), descriptionLabel.bottomAnchor.constraint(equalTo: metaLabel.topAnchor, constant: -20),
            // Genre label aligned to bottom
            metaLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor), metaLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -48)
        ])
    }

    func updateHeroData(title: String, imageName: String, videoUrl: String? = nil, genre: String? = nil) {
        updateHeroText(title: title, genre: genre)
        updateHeroMedia(imageName: imageName, videoUrl: videoUrl)
    }

    /// Cheap part — safe to run on every focus change.
    func updateHeroText(title: String, genre: String? = nil) {
        titleLabel.text = title
        metaLabel.text = genre ?? "Drama"
        descriptionLabel.text = "A heartwarming tale of love, dreams and unexpected journeys that change everything."
    }

    /// Expensive part — a full-resolution image download plus a new
    /// `AVPlayerItem`. Callers should debounce this while focus is moving.
    func updateHeroMedia(imageName: String, videoUrl: String?) {
        setImage(imageName)
        playVideo(urlString: videoUrl)
    }

    func configure(with hero: HeroContent) {
        titleLabel.text = hero.title; metaLabel.text = hero.metadata; descriptionLabel.text = hero.description
        featuredBadge.text = hero.badges.first?.text ?? "FEATURED"
        setImage(hero.backgroundImageName); playVideo(urlString: hero.videoUrl)
    }

    private func setImage(_ name: String) {
        if name.hasPrefix("http") { heroImageView.setImage(from: name, isHeroBanner: true) }
        else { heroImageView.image = UIImage(named: name) }
    }

    private func playVideo(urlString: String?) {
        guard let urlString, let url = URL(string: urlString) else {
            currentVideoUrlString = nil
            player?.pause()
            player?.replaceCurrentItem(with: nil)
            return
        }

        // Rebuilding the player item for a video that is already playing
        // is pure main-thread cost for no visible change.
        guard currentVideoUrlString != urlString else { return }
        currentVideoUrlString = urlString

        let item = AVPlayerItem(url: url)
        if player == nil { player = AVPlayer(playerItem: item); playerLayer?.player = player }
        else { player?.replaceCurrentItem(with: item) }
        player?.isMuted = true
        player?.play()
    }
    deinit { player?.pause() }
}
