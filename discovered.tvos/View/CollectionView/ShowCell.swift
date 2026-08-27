//
//  ShowCell.swift
//  discovered.tvos
//
//  Created by mac mini on 17/08/26.
//

import UIKit

class ShowCell: UICollectionViewCell {
    static let reuseIdentifier = "ShowCell"

    private let imageView = UIImageView()
    private let titleLabel = UILabel()
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
        contentView.layer.cornerRadius = 10
        contentView.clipsToBounds = true
        contentView.backgroundColor = UIColor(white: 0.14, alpha: 1)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)

        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.backgroundColor = UIColor.black.withAlphaComponent(0.46)
        contentView.addSubview(titleLabel)

        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlayView.alpha = 0
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        imageView.addSubview(overlayView)

        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = UIColor.red
        config.baseForegroundColor = .white
        playButtonOverlay.configuration = config
        playButtonOverlay.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButtonOverlay.addTarget(self, action: #selector(playButtonTapped), for: .primaryActionTriggered)
        playButtonOverlay.alpha = 0
        playButtonOverlay.translatesAutoresizingMaskIntoConstraints = false
        imageView.addSubview(playButtonOverlay)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            titleLabel.heightAnchor.constraint(equalToConstant: 22),

            overlayView.topAnchor.constraint(equalTo: imageView.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),

            playButtonOverlay.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            playButtonOverlay.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            playButtonOverlay.widthAnchor.constraint(equalToConstant: 56),
            playButtonOverlay.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    func configure(with item: ShowItem) {
        titleLabel.text = item.title
        if item.imageName.hasPrefix("http") {
            imageView.setImage(from: item.imageName)
        } else {
            imageView.image = UIImage(named: item.imageName) ?? UIImage(named: "")
        }
    }

    override var canBecomeFocused: Bool { true }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)

        coordinator.addCoordinatedAnimations({
            if self.isFocused {
                self.contentView.layer.borderWidth = 3
                self.contentView.layer.borderColor = UIColor.white.cgColor
                self.transform = CGAffineTransform(scaleX: 1.04, y: 1.04)
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

extension UIImageView {
    func setImage(from urlString: String?, placeholder: String = "", isHeroBanner: Bool = false) {
        self.image = UIImage(named: placeholder)
        
        guard let urlString = urlString, !urlString.isEmpty else { return }
        
        var finalUrlString = urlString
        if isHeroBanner {
            finalUrlString = urlString
                .replacingOccurrences(of: "_thumbnail_thumb", with: "_original_thumbnail")
                .replacingOccurrences(of: "_thumb", with: "")
        }
        
        guard let url = URL(string: finalUrlString) else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil, let image = UIImage(data: data) else {
                // Agar original image fail ho toh fallback to original url
                if isHeroBanner, let fallbackUrl = URL(string: urlString) {
                    URLSession.shared.dataTask(with: fallbackUrl) { fallbackData, _, _ in
                        if let fData = fallbackData, let fbImg = UIImage(data: fData) {
                            DispatchQueue.main.async { self?.image = fbImg }
                        }
                    }.resume()
                }
                return
            }
            
            DispatchQueue.main.async {
                self?.image = image
            }
        }.resume()
    }
}
