//
//  ChannelViewController.swift
//  discovered.tvos
//
//  Creator channel screen. Same shape as DetailViewController, but without
//  the Play / Visit Profile buttons, and the rail lists the channel's own
//  videos instead of similar content.
//

import Foundation
import UIKit
import AVFoundation

final class ChannelViewController: UIViewController {

    // MARK: - Properties

    private let viewModel: ChannelViewModel

    /// Attached to the collection view itself — a guide owned by the focused
    /// item's own container is the arrangement the focus engine honours here.
    private let railToBackFocusGuide = UIFocusGuide()

    // Scroll & Containers
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // Header & Banner
    private let backButton = UIButton(type: .system)
    private let bannerImageView = UIImageView()
    private let bannerGradient = CAGradientLayer()

    /// The banner plays whichever video is currently focused in the rail.
    /// `bannerImageView` stays behind it purely as a placeholder for the
    /// moment before the first frame is ready.
    private var bannerPlayer: AVPlayer?
    private var bannerPlayerLayer: AVPlayerLayer?
    private var currentBannerVideoUrl: String?
    private var bannerMediaWorkItem: DispatchWorkItem?

    // Channel header
    private let avatarImageView = UIImageView()
    private let channelNameLabel = UILabel()
    private let metaStackView = UIStackView()
    private let videoCountLabel = UILabel()
    private let tagBadgeContainer = UIView()
    private let tagLabel = UILabel()
    private let descriptionLabel = UILabel()

    // Videos section
    private let videosTitleLabel = UILabel()
    private var videosCollectionView: UICollectionView!

    // Status
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let statusLabel = UILabel()

    private var hasDeliveredInitialFocus = false

    // MARK: - Init

    init(userId: String, userName: String? = nil, userPic: String? = nil) {
        self.viewModel = ChannelViewModel(userId: userId, userName: userName, userPic: userPic)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        setupUI()
        setupConstraints()
        setupFocusGuides()
        bindViewModel()

        applyHeader()
        loadingIndicator.startAnimating()
        viewModel.load()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bannerPlayerLayer?.frame = bannerImageView.bounds
        bannerGradient.frame = bannerImageView.bounds
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.bringSubviewToFront(backButton)
        bannerPlayer?.play()
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        bannerPlayer?.pause()
    }

    // MARK: - Setup UI

    private func setupUI() {

        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // Banner
        bannerImageView.contentMode = .scaleAspectFill
        bannerImageView.clipsToBounds = true
        contentView.addSubview(bannerImageView)

        let playerLayer = AVPlayerLayer()
        playerLayer.videoGravity = .resizeAspectFill
        bannerImageView.layer.addSublayer(playerLayer)
        bannerPlayerLayer = playerLayer

        bannerGradient.colors = [
            UIColor.black.withAlphaComponent(0.15).cgColor,
            UIColor.black.withAlphaComponent(0.75).cgColor,
            UIColor.black.cgColor
        ]
        bannerGradient.locations = [0, 0.55, 1]
        bannerImageView.layer.addSublayer(bannerGradient)

        // Back button — same treatment as the detail screen.
        var backConfig = UIButton.Configuration.plain()
        backConfig.image = UIImage(systemName: "chevron.left")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 28, weight: .semibold))
        backConfig.baseForegroundColor = .white
        backConfig.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        backButton.configuration = backConfig
        backButton.contentHorizontalAlignment = .center
        backButton.addTarget(self, action: #selector(didTapBack), for: .primaryActionTriggered)
        view.addSubview(backButton)

        // Avatar
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 60
        avatarImageView.layer.borderWidth = 3
        avatarImageView.layer.borderColor = UIColor.white.withAlphaComponent(0.85).cgColor
        avatarImageView.backgroundColor = UIColor(white: 0.14, alpha: 1.0)
        contentView.addSubview(avatarImageView)

        // Channel name
        channelNameLabel.font = UIFont(name: "TimesNewRomanPS-BoldMT", size: 46) ?? .systemFont(ofSize: 46, weight: .bold)
        channelNameLabel.textColor = .white
        channelNameLabel.numberOfLines = 2
        contentView.addSubview(channelNameLabel)

        // Meta row
        metaStackView.axis = .horizontal
        metaStackView.spacing = 14
        metaStackView.alignment = .center
        contentView.addSubview(metaStackView)

        videoCountLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        videoCountLabel.textColor = UIColor(white: 0.8, alpha: 1.0)
        metaStackView.addArrangedSubview(videoCountLabel)

        tagBadgeContainer.layer.borderWidth = 1
        tagBadgeContainer.layer.borderColor = UIColor(white: 0.45, alpha: 1.0).cgColor
        tagBadgeContainer.layer.cornerRadius = 3
        tagLabel.font = .systemFont(ofSize: 11, weight: .bold)
        tagLabel.textColor = UIColor(white: 0.85, alpha: 1.0)
        tagLabel.translatesAutoresizingMaskIntoConstraints = false
        tagBadgeContainer.addSubview(tagLabel)
        NSLayoutConstraint.activate([
            tagLabel.topAnchor.constraint(equalTo: tagBadgeContainer.topAnchor, constant: 2),
            tagLabel.bottomAnchor.constraint(equalTo: tagBadgeContainer.bottomAnchor, constant: -2),
            tagLabel.leadingAnchor.constraint(equalTo: tagBadgeContainer.leadingAnchor, constant: 6),
            tagLabel.trailingAnchor.constraint(equalTo: tagBadgeContainer.trailingAnchor, constant: -6)
        ])
        metaStackView.addArrangedSubview(tagBadgeContainer)

        // Description
        descriptionLabel.numberOfLines = 4
        descriptionLabel.font = .systemFont(ofSize: 14, weight: .regular)
        descriptionLabel.textColor = UIColor(white: 0.85, alpha: 1.0)
        contentView.addSubview(descriptionLabel)

        // Videos section
        videosTitleLabel.text = "Channel Videos"
        videosTitleLabel.font = UIFont(name: "TimesNewRomanPS-BoldMT", size: 22) ?? .systemFont(ofSize: 22, weight: .bold)
        videosTitleLabel.textColor = .white
        contentView.addSubview(videosTitleLabel)

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 280, height: 290)
        layout.minimumLineSpacing = 20
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)

        videosCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        videosCollectionView.backgroundColor = .clear
        videosCollectionView.showsHorizontalScrollIndicator = false
        videosCollectionView.dataSource = self
        videosCollectionView.delegate = self
        videosCollectionView.clipsToBounds = false
        videosCollectionView.remembersLastFocusedIndexPath = false
        videosCollectionView.register(SimilarShowCell.self, forCellWithReuseIdentifier: SimilarShowCell.reuseIdentifier)
        contentView.addSubview(videosCollectionView)

        // Status
        loadingIndicator.color = .white
        loadingIndicator.hidesWhenStopped = true
        contentView.addSubview(loadingIndicator)

        statusLabel.font = .systemFont(ofSize: 16, weight: .medium)
        statusLabel.textColor = UIColor(white: 0.7, alpha: 1.0)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 2
        statusLabel.isHidden = true
        contentView.addSubview(statusLabel)
    }

    // MARK: - Constraints

    private func setupConstraints() {
        [scrollView, contentView, bannerImageView, backButton,
         avatarImageView, channelNameLabel, metaStackView, descriptionLabel,
         videosTitleLabel, videosCollectionView, loadingIndicator, statusLabel
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            backButton.widthAnchor.constraint(equalToConstant: 80),
            backButton.heightAnchor.constraint(equalToConstant: 64),

            bannerImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            bannerImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bannerImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bannerImageView.heightAnchor.constraint(equalToConstant: 680),

            avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 200),
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            avatarImageView.widthAnchor.constraint(equalToConstant: 120),
            avatarImageView.heightAnchor.constraint(equalToConstant: 120),

            channelNameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 24),
            channelNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            channelNameLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor, constant: 8),

            metaStackView.topAnchor.constraint(equalTo: channelNameLabel.bottomAnchor, constant: 12),
            metaStackView.leadingAnchor.constraint(equalTo: channelNameLabel.leadingAnchor),

            descriptionLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 24),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            descriptionLabel.widthAnchor.constraint(equalToConstant: 700),

            videosTitleLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 34),
            videosTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),

            videosCollectionView.topAnchor.constraint(equalTo: videosTitleLabel.bottomAnchor, constant: 14),
            videosCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            videosCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            videosCollectionView.heightAnchor.constraint(equalToConstant: 310),
            videosCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),

            loadingIndicator.centerXAnchor.constraint(equalTo: videosCollectionView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: videosCollectionView.centerYAnchor),

            statusLabel.centerXAnchor.constraint(equalTo: videosCollectionView.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: videosCollectionView.centerYAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40)
        ])
    }

    // MARK: - Focus

    private func setupFocusGuides() {
        // Owned by the rail, mirroring how the detail screen reaches its back
        // button from the action row.
        videosCollectionView.addLayoutGuide(railToBackFocusGuide)

        NSLayoutConstraint.activate([
            railToBackFocusGuide.topAnchor.constraint(equalTo: videosCollectionView.topAnchor, constant: -500),
            railToBackFocusGuide.bottomAnchor.constraint(equalTo: videosCollectionView.topAnchor),
            railToBackFocusGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            railToBackFocusGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        railToBackFocusGuide.preferredFocusEnvironments = [backButton]
    }

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        if viewModel.numberOfVideos() > 0 {
            return [videosCollectionView]
        }
        return [backButton]
    }

    // MARK: - Binding

    private func bindViewModel() {
        viewModel.onUpdate = { [weak self] in
            guard let self else { return }

            self.loadingIndicator.stopAnimating()
            self.applyHeader()
            self.videosCollectionView.reloadData()

            if self.viewModel.numberOfVideos() == 0 {
                self.statusLabel.isHidden = false
                self.statusLabel.text = "This channel has no videos yet."
            } else {
                self.statusLabel.isHidden = true
            }

            // Hand focus to the first video once the rail actually has cells.
            if !self.hasDeliveredInitialFocus, self.viewModel.numberOfVideos() > 0 {
                self.hasDeliveredInitialFocus = true
                self.view.layoutIfNeeded()
                self.setNeedsFocusUpdate()
                self.updateFocusIfNeeded()
            }
        }

        viewModel.onError = { [weak self] message in
            guard let self else { return }
            self.loadingIndicator.stopAnimating()
            self.statusLabel.isHidden = false
            self.statusLabel.text = message
            self.setNeedsFocusUpdate()
            self.updateFocusIfNeeded()
        }
    }

    private func applyHeader() {
        let model = viewModel.display

        channelNameLabel.text = model.userName

        let count = model.videoCount
        videoCountLabel.text = count == 1 ? "1 Video" : "\(count) Videos"

        if let firstTag = model.tags.first {
            tagLabel.text = firstTag.uppercased()
            tagBadgeContainer.isHidden = false
        } else {
            tagBadgeContainer.isHidden = true
        }

        descriptionLabel.text = model.description

        if let avatar = model.avatarUrl, avatar.hasPrefix("http") {
            avatarImageView.setImage(from: avatar)
        }

        setBannerMedia(imageUrl: model.bannerUrl, videoUrl: model.bannerVideoUrl)
    }

    // MARK: - Banner Media

    /// Debounced so holding a direction on the remote does not build one
    /// `AVPlayerItem` per step.
    private func scheduleBannerUpdate(for item: ShowItem) {
        bannerMediaWorkItem?.cancel()

        let work = DispatchWorkItem { [weak self] in
            self?.setBannerMedia(imageUrl: item.imageName, videoUrl: item.videoUrl)
        }

        bannerMediaWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30, execute: work)
    }

    private func setBannerMedia(imageUrl: String?, videoUrl: String?) {
        if let imageUrl, imageUrl.hasPrefix("http") {
            bannerImageView.setImage(from: imageUrl, placeholder: "hero_back", isHeroBanner: true)
        } else if bannerImageView.image == nil {
            bannerImageView.image = UIImage(named: "hero_back")
        }

        playBanner(urlString: videoUrl)
    }

    private func playBanner(urlString: String?) {
        guard
            let urlString,
            !urlString.isEmpty,
            let url = URL(string: urlString)
        else {
            currentBannerVideoUrl = nil
            bannerPlayer?.pause()
            bannerPlayer?.replaceCurrentItem(with: nil)
            return
        }

        // Rebuilding the item for a video that is already playing is pure
        // main-thread cost for no visible change.
        guard currentBannerVideoUrl != urlString else { return }
        currentBannerVideoUrl = urlString

        let item = AVPlayerItem(url: url)

        if bannerPlayer == nil {
            bannerPlayer = AVPlayer(playerItem: item)
            bannerPlayerLayer?.player = bannerPlayer
        } else {
            bannerPlayer?.replaceCurrentItem(with: item)
        }

        bannerPlayer?.isMuted = true
        bannerPlayer?.actionAtItemEnd = .none
        bannerPlayer?.play()

        NotificationCenter.default.removeObserver(
            self,
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(bannerReachedEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: item
        )
    }

    /// Keeps the background looping instead of freezing on the last frame.
    @objc private func bannerReachedEnd() {
        bannerPlayer?.seek(to: .zero)
        bannerPlayer?.play()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        bannerPlayer?.pause()
    }

    // MARK: - Actions

    @objc private func didTapBack() {
        if let nav = navigationController {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses where press.type == .menu {
            didTapBack()
            return
        }
        super.pressesBegan(presses, with: event)
    }

    private func play(_ item: ShowItem) {
        guard
            let urlString = item.videoUrl,
            let url = URL(string: urlString)
        else { return }

        let playerVC = TVPlayerViewController()
        playerVC.play(
            url: url,
            title: item.title,
            episodeInfo: item.userName ?? viewModel.display.userName
        )
        present(playerVC, animated: true)
    }
}

// MARK: - CollectionView Delegate & DataSource

extension ChannelViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfVideos()
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: SimilarShowCell.reuseIdentifier,
            for: indexPath
        ) as! SimilarShowCell

        guard let item = viewModel.video(at: indexPath.item) else { return cell }

        cell.configure(with: item)
        cell.onPlayButtonTapped = { [weak self] in
            self?.play(item)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = viewModel.video(at: indexPath.item) else { return }
        play(item)
    }

    func indexPathForPreferredFocusedView(in collectionView: UICollectionView) -> IndexPath? {
        guard collectionView.numberOfItems(inSection: 0) > 0 else { return nil }
        return IndexPath(item: 0, section: 0)
    }

    func collectionView(_ collectionView: UICollectionView,
                        didUpdateFocusIn context: UICollectionViewFocusUpdateContext,
                        with coordinator: UIFocusAnimationCoordinator) {
        guard let indexPath = context.nextFocusedIndexPath else { return }

        if let item = viewModel.video(at: indexPath.item) {
            scheduleBannerUpdate(for: item)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
}
