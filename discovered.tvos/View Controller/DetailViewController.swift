import Foundation
import UIKit
import AVFoundation

class DetailViewController: UIViewController {

    // MARK: - Properties
    private let viewModel: DetailViewModel
    private let homeViewModel = HomeViewModel.shared

    private let sideMenuWidth: CGFloat = 350
    private var sideMenuLeadingConstraint: NSLayoutConstraint!

    // Focus Guides
    private let actionToSimilarFocusGuide = UIFocusGuide()
    private let backToActionFocusGuide = UIFocusGuide()

    // Side Drawer Views
    private let dimView = UIView()
    private let sideMenuView = UIView()
    private let logoImageView = UIImageView()
    private let sideMenuStack = UIStackView()

    // Scroll & Containers
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // Header & Banner
    private let menuButton = CustomHamburgerButton()
    private let bannerImageView = UIImageView()
    private let bannerGradient = CAGradientLayer()

    // Content Labels
    private let titleLabel = UILabel()
    private let metaStackView = UIStackView()
    private let starsLabel = UILabel()
    private let ratingLabel = UILabel()
    private let yearLabel = UILabel()
    private let durationLabel = UILabel()
    private let genreBadgeContainer = UIView()
    private let genreLabel = UILabel()

    private let descriptionLabel = UILabel()
    private let starringLabel = UILabel()

    // Action Buttons
    private let actionButtonStack = UIStackView()
    private let playButton = CustomPlayButton()
    private let visitProfileButton = CustomProfileButton()

    // Similar Content Section
    private let similarTitleLabel = UILabel()
    private var similarCollectionView: UICollectionView!

    // Related Videos Section
    private let relatedTitleLabel = UILabel()
    private var relatedVideosCollectionView: UICollectionView!

    // MARK: - Init
    init(show: ShowItem, allShows: [ShowItem] = []) {
        self.viewModel = DetailViewModel(selectedVideo: show, allVideos: allShows)
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
        populateData()
        bindSideMenu()
        bindViewModel()

        sideMenuLeadingConstraint.constant = -sideMenuWidth
        dimView.alpha = 0
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.bringSubviewToFront(dimView)
        view.bringSubviewToFront(sideMenuView)
        view.bringSubviewToFront(menuButton)

        setNeedsFocusUpdate()
        updateFocusIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bannerGradient.frame = bannerImageView.bounds
    }

    // MARK: - Side Menu Binding
    private func bindSideMenu() {
        homeViewModel.onSideMenuSelectionChanged = { [weak self] _ in
            self?.closeSideMenu()
        }
    }

    private func bindViewModel() {
        // Similar videos are loaded directly from videoDetail.similarVideos
    }

    // MARK: - Setup UI
    private func setupUI() {
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // Banner Image
        bannerImageView.contentMode = .scaleAspectFill
        bannerImageView.clipsToBounds = true
        contentView.addSubview(bannerImageView)

        bannerGradient.colors = [
            UIColor.black.withAlphaComponent(0.2).cgColor,
            UIColor.black.withAlphaComponent(0.6).cgColor,
            UIColor.black.cgColor
        ]
        bannerGradient.locations = [0.0, 0.55, 1.0]
        bannerImageView.layer.addSublayer(bannerGradient)

        // Title
        titleLabel.numberOfLines = 2
        titleLabel.font = UIFont(name: "TimesNewRomanPS-BoldMT", size: 46) ?? .systemFont(ofSize: 46, weight: .bold)
        titleLabel.textColor = .white
        contentView.addSubview(titleLabel)

        // Metadata Stack (Stars, Rating, Year, Duration, Genre)
        metaStackView.axis = .horizontal
        metaStackView.spacing = 14
        metaStackView.alignment = .center
        contentView.addSubview(metaStackView)

        starsLabel.text = "★★★★★"
        starsLabel.textColor = UIColor(red: 0.95, green: 0.15, blue: 0.15, alpha: 1.0)
        starsLabel.font = .systemFont(ofSize: 14, weight: .bold)
        metaStackView.addArrangedSubview(starsLabel)

        ratingLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        ratingLabel.textColor = .white
        metaStackView.addArrangedSubview(ratingLabel)

        metaStackView.addArrangedSubview(makeSeparator())

        yearLabel.font = .systemFont(ofSize: 13, weight: .medium)
        yearLabel.textColor = UIColor(white: 0.8, alpha: 1.0)
        metaStackView.addArrangedSubview(yearLabel)

        metaStackView.addArrangedSubview(makeSeparator())

        durationLabel.font = .systemFont(ofSize: 13, weight: .medium)
        durationLabel.textColor = UIColor(white: 0.8, alpha: 1.0)
        metaStackView.addArrangedSubview(durationLabel)

        metaStackView.addArrangedSubview(makeSeparator())

        genreBadgeContainer.layer.borderWidth = 1
        genreBadgeContainer.layer.borderColor = UIColor(white: 0.45, alpha: 1.0).cgColor
        genreBadgeContainer.layer.cornerRadius = 3

        genreLabel.font = .systemFont(ofSize: 11, weight: .bold)
        genreLabel.textColor = UIColor(white: 0.85, alpha: 1.0)
        genreLabel.translatesAutoresizingMaskIntoConstraints = false
        genreBadgeContainer.addSubview(genreLabel)

        NSLayoutConstraint.activate([
            genreLabel.topAnchor.constraint(equalTo: genreBadgeContainer.topAnchor, constant: 2),
            genreLabel.bottomAnchor.constraint(equalTo: genreBadgeContainer.bottomAnchor, constant: -2),
            genreLabel.leadingAnchor.constraint(equalTo: genreBadgeContainer.leadingAnchor, constant: 6),
            genreLabel.trailingAnchor.constraint(equalTo: genreBadgeContainer.trailingAnchor, constant: -6)
        ])
        metaStackView.addArrangedSubview(genreBadgeContainer)

        // Description
        descriptionLabel.numberOfLines = 4
        descriptionLabel.font = .systemFont(ofSize: 14, weight: .regular)
        descriptionLabel.textColor = UIColor(white: 0.85, alpha: 1.0)
        contentView.addSubview(descriptionLabel)

        // Starring / Creator
        starringLabel.numberOfLines = 2
        contentView.addSubview(starringLabel)

        // Action Buttons (Play & Visit Profile)
        actionButtonStack.axis = .horizontal
        actionButtonStack.spacing = 16
        actionButtonStack.alignment = .fill
        actionButtonStack.distribution = .fill
        contentView.addSubview(actionButtonStack)

        playButton.addTarget(self, action: #selector(didTapPlay), for: .primaryActionTriggered)
        actionButtonStack.addArrangedSubview(playButton)

        visitProfileButton.addTarget(self, action: #selector(didTapVisitProfile), for: .primaryActionTriggered)
        actionButtonStack.addArrangedSubview(visitProfileButton)

        // Similar Content
        similarTitleLabel.text = "Similar Content"
        similarTitleLabel.font = UIFont(name: "TimesNewRomanPS-BoldMT", size: 22) ?? .systemFont(ofSize: 22, weight: .bold)
        similarTitleLabel.textColor = .white
        contentView.addSubview(similarTitleLabel)

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 350, height: 260)
        layout.minimumLineSpacing = 30
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)

        similarCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        similarCollectionView.backgroundColor = .clear
        similarCollectionView.showsHorizontalScrollIndicator = false
        similarCollectionView.dataSource = self
        similarCollectionView.delegate = self
        similarCollectionView.clipsToBounds = false
        similarCollectionView.register(SimilarShowCell.self, forCellWithReuseIdentifier: SimilarShowCell.reuseIdentifier)
        contentView.addSubview(similarCollectionView)

        // Related Videos Section
        relatedTitleLabel.text = "More From This Creator"
        relatedTitleLabel.font = UIFont(name: "TimesNewRomanPS-BoldMT", size: 22) ?? .systemFont(ofSize: 22, weight: .bold)
        relatedTitleLabel.textColor = .white
        contentView.addSubview(relatedTitleLabel)

        let relatedLayout = UICollectionViewFlowLayout()
        relatedLayout.scrollDirection = .horizontal
        relatedLayout.itemSize = CGSize(width: 190, height: 340)
        relatedLayout.minimumLineSpacing = 30
        relatedLayout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)

        relatedVideosCollectionView = UICollectionView(frame: .zero, collectionViewLayout: relatedLayout)
        relatedVideosCollectionView.backgroundColor = .clear
        relatedVideosCollectionView.showsHorizontalScrollIndicator = false
        relatedVideosCollectionView.dataSource = self
        relatedVideosCollectionView.delegate = self
        relatedVideosCollectionView.clipsToBounds = false
        relatedVideosCollectionView.register(RelatedVideoCell.self, forCellWithReuseIdentifier: RelatedVideoCell.reuseIdentifier)
        contentView.addSubview(relatedVideosCollectionView)

        // Hamburger Menu Button
        menuButton.addTarget(self, action: #selector(toggleSideMenu), for: .primaryActionTriggered)
        view.addSubview(menuButton)

        // Dim Overlay
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.65)
        dimView.alpha = 0
        let tap = UITapGestureRecognizer(target: self, action: #selector(closeSideMenu))
        dimView.addGestureRecognizer(tap)
        view.addSubview(dimView)

        // Side Drawer
        sideMenuView.backgroundColor = UIColor(white: 0.06, alpha: 1.0)
        view.addSubview(sideMenuView)

        logoImageView.image = UIImage(named: "Logo Dark")
        logoImageView.contentMode = .scaleAspectFit
        sideMenuView.addSubview(logoImageView)

        sideMenuStack.axis = .vertical
        sideMenuStack.spacing = 10
        sideMenuStack.alignment = .fill
        sideMenuView.addSubview(sideMenuStack)

        for item in homeViewModel.sideMenuItems {
            let btn = SideMenuCapsuleButton()
            btn.configure(with: item)
            btn.addTarget(self, action: #selector(sideItemTapped(_:)), for: .primaryActionTriggered)
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.heightAnchor.constraint(equalToConstant: 48).isActive = true

            if item.id == 5, let prev = sideMenuStack.arrangedSubviews.last {
                sideMenuStack.setCustomSpacing(35, after: prev)
            }
            sideMenuStack.addArrangedSubview(btn)
        }
    }

    private func makeSeparator() -> UILabel {
        let label = UILabel()
        label.text = "|"
        label.textColor = UIColor(white: 0.4, alpha: 1.0)
        label.font = .systemFont(ofSize: 12)
        return label
    }

    // MARK: - Populate Data
    private func populateData() {
        let movie = viewModel.videoDetail
        titleLabel.text = movie.title
        ratingLabel.text = movie.rating
        yearLabel.text = movie.year
        durationLabel.text = movie.duration
        genreLabel.text = movie.genre
        descriptionLabel.text = movie.description

        if movie.bannerImageUrl.hasPrefix("http") {
            bannerImageView.setImage(from: movie.bannerImageUrl, placeholder: "hero_back", isHeroBanner: true)
        } else {
            bannerImageView.image = UIImage(named: movie.bannerImageUrl) ?? UIImage(named: "hero_back")
        }

        let starringAttributedString = NSMutableAttributedString(
            string: "Creator: ",
            attributes: [.font: UIFont.systemFont(ofSize: 14, weight: .bold), .foregroundColor: UIColor.white]
        )
        starringAttributedString.append(NSAttributedString(
            string: movie.starring,
            attributes: [.font: UIFont.systemFont(ofSize: 14, weight: .regular), .foregroundColor: UIColor(white: 0.8, alpha: 1.0)]
        ))
        starringLabel.attributedText = starringAttributedString

        similarCollectionView.reloadData()
    }

    // MARK: - Constraints
    private func setupConstraints() {
        [scrollView, contentView, bannerImageView, menuButton,
         titleLabel, metaStackView, descriptionLabel, starringLabel,
         actionButtonStack, playButton, visitProfileButton,
         similarTitleLabel, similarCollectionView,
         relatedTitleLabel, relatedVideosCollectionView,
         dimView, sideMenuView, logoImageView, sideMenuStack
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        sideMenuLeadingConstraint = sideMenuView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -sideMenuWidth)

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

            menuButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            menuButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            menuButton.widthAnchor.constraint(equalToConstant: 48),
            menuButton.heightAnchor.constraint(equalToConstant: 48),

            bannerImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            bannerImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bannerImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bannerImageView.heightAnchor.constraint(equalToConstant: 680),

            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 220),

            metaStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 14),
            metaStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),

            descriptionLabel.topAnchor.constraint(equalTo: metaStackView.bottomAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            descriptionLabel.widthAnchor.constraint(equalToConstant: 580),

            starringLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 18),
            starringLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            starringLabel.trailingAnchor.constraint(equalTo: descriptionLabel.trailingAnchor),

            actionButtonStack.topAnchor.constraint(equalTo: starringLabel.bottomAnchor, constant: 22),
            actionButtonStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            actionButtonStack.heightAnchor.constraint(equalToConstant: 46),

            playButton.widthAnchor.constraint(equalToConstant: 130),
            visitProfileButton.widthAnchor.constraint(equalToConstant: 160),

            similarTitleLabel.topAnchor.constraint(equalTo: bannerImageView.bottomAnchor, constant: 20),
            similarTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),

            similarCollectionView.topAnchor.constraint(equalTo: similarTitleLabel.bottomAnchor, constant: 14),
            similarCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            similarCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            similarCollectionView.heightAnchor.constraint(equalToConstant: 280),

            // Related Videos
            relatedTitleLabel.topAnchor.constraint(equalTo: similarCollectionView.bottomAnchor, constant: 40),
            relatedTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),

            relatedVideosCollectionView.topAnchor.constraint(equalTo: relatedTitleLabel.bottomAnchor, constant: 14),
            relatedVideosCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            relatedVideosCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            relatedVideosCollectionView.heightAnchor.constraint(equalToConstant: 360),
            relatedVideosCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),

            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            sideMenuLeadingConstraint,
            sideMenuView.topAnchor.constraint(equalTo: view.topAnchor),
            sideMenuView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sideMenuView.widthAnchor.constraint(equalToConstant: sideMenuWidth),

            logoImageView.topAnchor.constraint(equalTo: sideMenuView.safeAreaLayoutGuide.topAnchor, constant: 35),
            logoImageView.centerXAnchor.constraint(equalTo: sideMenuView.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 220),
            logoImageView.heightAnchor.constraint(equalToConstant: 70),

            sideMenuStack.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 50),
            sideMenuStack.leadingAnchor.constraint(equalTo: sideMenuView.leadingAnchor, constant: 16),
            sideMenuStack.trailingAnchor.constraint(equalTo: sideMenuView.trailingAnchor, constant: -16)
        ])
    }

    // MARK: - Focus Guides
    private func setupFocusGuides() {
        view.addLayoutGuide(actionToSimilarFocusGuide)
        view.addLayoutGuide(backToActionFocusGuide)

        NSLayoutConstraint.activate([
            actionToSimilarFocusGuide.topAnchor.constraint(equalTo: actionButtonStack.bottomAnchor),
            actionToSimilarFocusGuide.bottomAnchor.constraint(equalTo: similarCollectionView.topAnchor),
            actionToSimilarFocusGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            actionToSimilarFocusGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            backToActionFocusGuide.topAnchor.constraint(equalTo: menuButton.bottomAnchor),
            backToActionFocusGuide.bottomAnchor.constraint(equalTo: actionButtonStack.topAnchor),
            backToActionFocusGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backToActionFocusGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        actionToSimilarFocusGuide.preferredFocusEnvironments = [similarCollectionView]
        backToActionFocusGuide.preferredFocusEnvironments = [playButton]
    }

    // MARK: - Actions
    @objc private func toggleSideMenu() {
        homeViewModel.isSideMenuOpen ? closeSideMenu() : openSideMenu()
    }

    private func openSideMenu() {
        homeViewModel.isSideMenuOpen = true
        sideMenuLeadingConstraint.constant = 0

        view.bringSubviewToFront(dimView)
        view.bringSubviewToFront(sideMenuView)

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.dimView.alpha = 1
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.setNeedsFocusUpdate()
            self.updateFocusIfNeeded()
        }
    }

    @objc private func closeSideMenu() {
        homeViewModel.isSideMenuOpen = false
        sideMenuLeadingConstraint.constant = -sideMenuWidth

        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn) {
            self.dimView.alpha = 0
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.setNeedsFocusUpdate()
            self.updateFocusIfNeeded()
        }
    }

    @objc private func sideItemTapped(_ sender: UIButton) {
        let selectedIndex = sender.tag
        HomeViewModel.shared.selectSideMenu(at: selectedIndex)
        closeSideMenu()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self = self else { return }
            if let nav = self.navigationController {
                nav.popToRootViewController(animated: true)
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }

    @objc private func didTapPlay() {
        presentVideoPlayer()
    }

    private func presentVideoPlayer() {
        let playerVC = TVPlayerViewController()

        playerVC.onDismiss = { [weak self] in
            print("Player dismissed")
        }

        let hlsURL = URL(string: "https://serverguys-s3-trans-cdn.discovered.tv/aud_270/videos/6a34e55d55beb/6a34e55d55beb.m3u8")!
        playerVC.play(url: hlsURL)

        self.present(playerVC, animated: true)
    }

    @objc private func didTapVisitProfile() {
        if let nav = navigationController {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        if homeViewModel.isSideMenuOpen {
            if let selectedBtn = sideMenuStack.arrangedSubviews.first(where: { ($0 as? UIButton)?.tag == homeViewModel.selectedSideMenuIndex }) {
                return [selectedBtn]
            }
            return sideMenuStack.arrangedSubviews
        }
        return [playButton]
    }
}

// MARK: - CollectionView Delegate & DataSource
extension DetailViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == similarCollectionView {
            return viewModel.numberOfSimilarVideos()
        } else if collectionView == relatedVideosCollectionView {
            return viewModel.numberOfSimilarVideos()
        }
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == similarCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SimilarShowCell.reuseIdentifier, for: indexPath) as! SimilarShowCell
            let item = viewModel.similarVideo(at: indexPath.item)
            cell.configure(with: item)
            cell.onPlayButtonTapped = { [weak self] in
                self?.presentVideoPlayer()
            }
            return cell
        } else if collectionView == relatedVideosCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RelatedVideoCell.reuseIdentifier, for: indexPath) as! RelatedVideoCell
            let video = viewModel.similarVideo(at: indexPath.item)
            cell.configure(with: video)
            cell.onPlayButtonTapped = { [weak self] in
                self?.presentVideoPlayer()
            }
            return cell
        }
        return UICollectionViewCell()
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedItem = viewModel.similarVideo(at: indexPath.item)
        let nextDetailVC = DetailViewController(show: selectedItem, allShows: viewModel.videoDetail.similarVideos)
        navigationController?.pushViewController(nextDetailVC, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
        return true
    }
}
