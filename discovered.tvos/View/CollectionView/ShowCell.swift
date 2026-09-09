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

// MARK: - Image Loading

/// Shared, cached image loader.
///
/// Every remote image used to be downloaded again on each cell reuse and
/// then decoded on the main thread (assigning a freshly created `UIImage`
/// defers decoding to the next render pass). On tvOS that showed up as a
/// long hitch whenever a batch of new cells appeared at once — e.g. when
/// the hero collapses and the rail area suddenly grows.
final class ImageLoader {

    static let shared = ImageLoader()

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 240
    }

    func cachedImage(for key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    @discardableResult
    func load(
        _ urlString: String,
        completion: @escaping (UIImage?) -> Void
    ) -> URLSessionDataTask? {

        if let cached = cachedImage(for: urlString) {
            completion(cached)
            return nil
        }

        guard let url = URL(string: urlString) else {
            completion(nil)
            return nil
        }

        let task = URLSession.shared.dataTask(
            with: url
        ) { [weak self] data, _, _ in

            guard
                let data,
                let raw = UIImage(data: data)
            else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            // Force the (expensive) decode here, off the main thread.
            let ready = raw.preparingForDisplay() ?? raw

            self?.cache.setObject(
                ready,
                forKey: urlString as NSString
            )

            DispatchQueue.main.async { completion(ready) }
        }

        task.resume()

        return task
    }
}

private enum ImageViewAssociatedKeys {
    nonisolated(unsafe) static var task: UInt8 = 0
    nonisolated(unsafe) static var urlString: UInt8 = 0
}

extension UIImageView {

    private var inFlightImageTask: URLSessionDataTask? {

        get {
            objc_getAssociatedObject(
                self,
                &ImageViewAssociatedKeys.task
            ) as? URLSessionDataTask
        }

        set {
            objc_setAssociatedObject(
                self,
                &ImageViewAssociatedKeys.task,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    private var currentImageURLString: String? {

        get {
            objc_getAssociatedObject(
                self,
                &ImageViewAssociatedKeys.urlString
            ) as? String
        }

        set {
            objc_setAssociatedObject(
                self,
                &ImageViewAssociatedKeys.urlString,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    func setImage(
        from urlString: String?,
        placeholder: String = "",
        isHeroBanner: Bool = false
    ) {

        // A reused cell must not be filled in by its previous request.
        inFlightImageTask?.cancel()
        inFlightImageTask = nil

        guard
            let urlString,
            !urlString.isEmpty
        else {
            currentImageURLString = nil
            image = placeholder.isEmpty
                ? nil
                : UIImage(named: placeholder)
            return
        }

        var finalUrlString = urlString

        if isHeroBanner {
            finalUrlString = urlString
                .replacingOccurrences(
                    of: "_thumbnail_thumb",
                    with: "_original_thumbnail"
                )
                .replacingOccurrences(
                    of: "_thumb",
                    with: ""
                )
        }

        // Already showing exactly this image — nothing to do.
        if currentImageURLString == finalUrlString,
           image != nil {
            return
        }

        currentImageURLString = finalUrlString

        if let cached =
            ImageLoader.shared.cachedImage(for: finalUrlString) {

            image = cached
            return
        }

        image = placeholder.isEmpty
            ? nil
            : UIImage(named: placeholder)

        inFlightImageTask = ImageLoader.shared.load(
            finalUrlString
        ) { [weak self] loaded in

            guard
                let self,
                self.currentImageURLString == finalUrlString
            else {
                return
            }

            if let loaded {
                self.image = loaded
                return
            }

            // Hero banners fall back to the unmodified URL.
            guard
                isHeroBanner,
                finalUrlString != urlString
            else {
                return
            }

            self.inFlightImageTask = ImageLoader.shared.load(
                urlString
            ) { [weak self] fallback in

                guard
                    let self,
                    self.currentImageURLString == finalUrlString,
                    let fallback
                else {
                    return
                }

                self.image = fallback
            }
        }
    }
}
