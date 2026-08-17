import UIKit

class DetailViewController: UIViewController {

    // MARK: - Properties
    private let viewModel: DetailViewModel
    private let homeViewModel = HomeViewModel()

    private let sideMenuWidth: CGFloat = 350
    private var sideMenuLeadingConstraint: NSLayoutConstraint!

    // Focus Guides
    private let playToSimilarFocusGuide = UIFocusGuide()
    private let backToPlayFocusGuide = UIFocusGuide()

    // Side Drawer Views
    private let dimView = UIView()
    private let sideMenuView = UIView()
    private let logoImageView = UIImageView()
    private let sideMenuStack = UIStackView()

    // Scroll & Containers
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // Header Components
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

    // Action Button
    private let playButton = CustomPlayButton()

    // Similar Content Section
    private let similarTitleLabel = UILabel()
    private var similarCollectionView: UICollectionView!

    // MARK: - Init
    init(show: ShowItem) {
        self.viewModel = DetailViewModel(show: show)
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

    // MARK: - Setup UI
    private func setupUI() {
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // Banner Image & Gradient
        bannerImageView.contentMode = .scaleAspectFill
        bannerImageView.clipsToBounds = true
        contentView.addSubview(bannerImageView)

        bannerGradient.colors = [
            UIColor.black.withAlphaComponent(0.2).cgColor,
            UIColor.black.withAlphaComponent(0.6).cgColor,
            UIColor.black.cgColor
        ]
        bannerGradient.locations = [0.0, 0.6, 1.0]
        bannerImageView.layer.addSublayer(bannerGradient)

        // Title
        titleLabel.numberOfLines = 2
        titleLabel.font = UIFont(name: "TimesNewRomanPS-BoldMT", size: 48) ?? .systemFont(ofSize: 48, weight: .bold)
        titleLabel.textColor = .white
        contentView.addSubview(titleLabel)

        // Metadata Stack
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

        // Sci-Fi Genre Box
        genreBadgeContainer.layer.borderWidth = 1
        genreBadgeContainer.layer.borderColor = UIColor(white: 0.4, alpha: 1.0).cgColor
        genreBadgeContainer.layer.cornerRadius = 3

        genreLabel.font = .systemFont(ofSize: 11, weight: .bold)
        genreLabel.textColor = UIColor(white: 0.8, alpha: 1.0)
        genreLabel.translatesAutoresizingMaskIntoConstraints = false
        genreBadgeContainer.addSubview(genreLabel)

        NSLayoutConstraint.activate([
            genreLabel.topAnchor.constraint(equalTo: genreBadgeContainer.topAnchor, constant: 2),
            genreLabel.bottomAnchor.constraint(equalTo: genreBadgeContainer.bottomAnchor, constant: -2),
            genreLabel.leadingAnchor.constraint(equalTo: genreBadgeContainer.leadingAnchor, constant: 6),
            genreLabel.trailingAnchor.constraint(equalTo: genreBadgeContainer.trailingAnchor, constant: -6)
        ])
        metaStackView.addArrangedSubview(genreBadgeContainer)

        // Description & Starring
        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = .systemFont(ofSize: 14, weight: .regular)
        descriptionLabel.textColor = UIColor(white: 0.85, alpha: 1.0)
        contentView.addSubview(descriptionLabel)

        starringLabel.numberOfLines = 2
        contentView.addSubview(starringLabel)

        // Play Button
        playButton.setTitle(" ▶   Play", for: .normal)
        playButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        playButton.setTitleColor(.white, for: .normal)
        playButton.backgroundColor = UIColor(red: 0.88, green: 0.08, blue: 0.08, alpha: 1.0)
        playButton.layer.cornerRadius = 6
        playButton.addTarget(self, action: #selector(didTapPlay), for: .primaryActionTriggered)
        contentView.addSubview(playButton)

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
        let movie = viewModel.movieDetail
        titleLabel.text = movie.title
        ratingLabel.text = movie.rating
        yearLabel.text = movie.year
        durationLabel.text = movie.duration
        genreLabel.text = movie.genre
        descriptionLabel.text = movie.description
        bannerImageView.image = UIImage(named: movie.bannerImageName) ?? UIImage(named: "hero_back")

        let starringAttributedString = NSMutableAttributedString(
            string: "Starring: ",
            attributes: [.font: UIFont.systemFont(ofSize: 13, weight: .bold), .foregroundColor: UIColor.white]
        )
        starringAttributedString.append(NSAttributedString(
            string: movie.starring,
            attributes: [.font: UIFont.systemFont(ofSize: 13, weight: .regular), .foregroundColor: UIColor(white: 0.8, alpha: 1.0)]
        ))
        starringLabel.attributedText = starringAttributedString
    }

    // MARK: - Constraints
    private func setupConstraints() {
        [scrollView, contentView, bannerImageView, menuButton,
         titleLabel, metaStackView, descriptionLabel, starringLabel,
         playButton, similarTitleLabel, similarCollectionView,
         dimView, sideMenuView, logoImageView, sideMenuStack
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        sideMenuLeadingConstraint = sideMenuView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -sideMenuWidth)

        NSLayoutConstraint.activate([
            // Scroll & Content
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Top Menu Button
            menuButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            menuButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            menuButton.widthAnchor.constraint(equalToConstant: 48),
            menuButton.heightAnchor.constraint(equalToConstant: 48),

            // Hero Banner
            bannerImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            bannerImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bannerImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bannerImageView.heightAnchor.constraint(equalToConstant: 680),

            // Labels
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 220),

            metaStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 14),
            metaStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),

            descriptionLabel.topAnchor.constraint(equalTo: metaStackView.bottomAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            descriptionLabel.widthAnchor.constraint(equalToConstant: 520),

            starringLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 18),
            starringLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            starringLabel.trailingAnchor.constraint(equalTo: descriptionLabel.trailingAnchor),

            // Play Button
            playButton.topAnchor.constraint(equalTo: starringLabel.bottomAnchor, constant: 22),
            playButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            playButton.widthAnchor.constraint(equalToConstant: 130),
            playButton.heightAnchor.constraint(equalToConstant: 44),

            // Similar Content
            similarTitleLabel.topAnchor.constraint(equalTo: bannerImageView.bottomAnchor, constant: 20),
            similarTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),

            similarCollectionView.topAnchor.constraint(equalTo: similarTitleLabel.bottomAnchor, constant: 14),
            similarCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            similarCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            similarCollectionView.heightAnchor.constraint(equalToConstant: 280),
            similarCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),

            // Dim Overlay
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Side Drawer
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
        view.addLayoutGuide(playToSimilarFocusGuide)
        view.addLayoutGuide(backToPlayFocusGuide)

        NSLayoutConstraint.activate([
            playToSimilarFocusGuide.topAnchor.constraint(equalTo: playButton.bottomAnchor),
            playToSimilarFocusGuide.bottomAnchor.constraint(equalTo: similarCollectionView.topAnchor),
            playToSimilarFocusGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playToSimilarFocusGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            backToPlayFocusGuide.topAnchor.constraint(equalTo: menuButton.bottomAnchor),
            backToPlayFocusGuide.bottomAnchor.constraint(equalTo: playButton.topAnchor),
            backToPlayFocusGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backToPlayFocusGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        playToSimilarFocusGuide.preferredFocusEnvironments = [similarCollectionView]
        backToPlayFocusGuide.preferredFocusEnvironments = [menuButton]
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
        
        // Side drawer close karein aur root ViewController par wapas chale jayein
        closeSideMenu()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self = self else { return }
            
            if let nav = self.navigationController {
                // Agar Navigation Controller me push kiya tha to root ViewController par wapas jayein
                nav.popToRootViewController(animated: true)
            } else {
                // Agar modal present kiya tha to dismiss karke wapas jayein
                self.dismiss(animated: true, completion: nil)
            }
        }
    }

    @objc private func didTapPlay() {
        print("Play Movie Triggered")
    }

    // MARK: - Preferred Focus
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

// MARK: - CollectionView DataSource & Delegate
extension DetailViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfSimilarShows()
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SimilarShowCell.reuseIdentifier, for: indexPath) as! SimilarShowCell
        let item = viewModel.similarShow(at: indexPath.item)
        cell.configure(with: item)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
        return true
    }
}
