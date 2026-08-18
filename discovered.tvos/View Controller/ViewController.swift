import UIKit

class ViewController: UIViewController {

    // MARK: - ViewModel
    private let viewModel = HomeViewModel()

    // MARK: - Properties
    private let sideMenuWidth: CGFloat = 350
    private var sideMenuLeadingConstraint: NSLayoutConstraint!

    // Focus Guide
    private let upToMenuFocusGuide = UIFocusGuide()

    // Views
    private let dimView = UIView()
    private let sideMenuView = UIView()
    private let sideMenuStack = UIStackView()

    private let mainContainer = UIView()
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let menuButton = CustomHamburgerButton()
    private let heroHeaderView = HeroHeaderView()
    private let playButton = UIButton()
    private let sectionTitleLabel = UILabel()
    private var collectionView: UICollectionView!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        setupUI()
        setupConstraints()
        setupFocusGuides()
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

    // MARK: - ViewModel Binding
    private func bindViewModel() {
        heroHeaderView.configure(with: viewModel.heroData)

        viewModel.onSideMenuSelectionChanged = { [weak self] selectedIndex in
            print("Selected Tab Index: \(selectedIndex)")
            self?.closeSideMenu()
        }
    }

    // MARK: - Setup UI
    private func setupUI() {
        mainContainer.backgroundColor = .black
        view.addSubview(mainContainer)

        scrollView.showsVerticalScrollIndicator = false
        mainContainer.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(heroHeaderView)

        var playConfig = UIButton.Configuration.filled()
        playConfig.baseBackgroundColor = .red
        playConfig.baseForegroundColor = .white
        playButton.configuration = playConfig
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.addTarget(self, action: #selector(playButtonDidTap), for: .primaryActionTriggered)
        contentView.addSubview(playButton)

        sectionTitleLabel.text = "Critically Acclaimed TV Shows"
        sectionTitleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        sectionTitleLabel.textColor = .white
        contentView.addSubview(sectionTitleLabel)

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 350, height: 250)
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.clipsToBounds = false
        collectionView.register(ShowCell.self, forCellWithReuseIdentifier: ShowCell.reuseIdentifier)
        contentView.addSubview(collectionView)

        menuButton.addTarget(self, action: #selector(toggleSideMenu), for: .primaryActionTriggered)
        view.addSubview(menuButton)

        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.65)
        dimView.alpha = 0
        let tap = UITapGestureRecognizer(target: self, action: #selector(closeSideMenu))
        dimView.addGestureRecognizer(tap)
        view.addSubview(dimView)

        sideMenuView.backgroundColor = UIColor(white: 0.06, alpha: 1.0)
        view.addSubview(sideMenuView)

        sideMenuStack.axis = .vertical
        sideMenuStack.spacing = 10
        sideMenuStack.alignment = .fill
        sideMenuView.addSubview(sideMenuStack)

        for item in viewModel.sideMenuItems {
            let btn = SideMenuCapsuleButton()
            btn.configure(with: item)
            btn.addTarget(self, action: #selector(sideItemTapped(_:)), for: .primaryActionTriggered)
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.heightAnchor.constraint(equalToConstant: 48).isActive = true
            sideMenuStack.addArrangedSubview(btn)
        }
    }

    // MARK: - Constraints
    private func setupConstraints() {
        [mainContainer, scrollView, contentView,
         heroHeaderView, playButton, sectionTitleLabel, collectionView,
         menuButton, dimView, sideMenuView, sideMenuStack
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        sideMenuLeadingConstraint = sideMenuView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -sideMenuWidth)

        NSLayoutConstraint.activate([
            mainContainer.topAnchor.constraint(equalTo: view.topAnchor),
            mainContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: mainContainer.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: mainContainer.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: mainContainer.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: mainContainer.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            menuButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            menuButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            menuButton.widthAnchor.constraint(equalToConstant: 48),
            menuButton.heightAnchor.constraint(equalToConstant: 48),

            heroHeaderView.topAnchor.constraint(equalTo: contentView.topAnchor),
            heroHeaderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            heroHeaderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            heroHeaderView.heightAnchor.constraint(equalToConstant: 540),

            playButton.centerXAnchor.constraint(equalTo: heroHeaderView.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: heroHeaderView.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 80),
            playButton.heightAnchor.constraint(equalToConstant: 80),

            sectionTitleLabel.topAnchor.constraint(equalTo: heroHeaderView.bottomAnchor, constant: 28),
            sectionTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),

            collectionView.topAnchor.constraint(equalTo: sectionTitleLabel.bottomAnchor, constant: 14),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: 270),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),

            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            sideMenuLeadingConstraint,
            sideMenuView.topAnchor.constraint(equalTo: view.topAnchor),
            sideMenuView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sideMenuView.widthAnchor.constraint(equalToConstant: sideMenuWidth),

            sideMenuStack.topAnchor.constraint(equalTo: sideMenuView.safeAreaLayoutGuide.topAnchor, constant: 40),
            sideMenuStack.leadingAnchor.constraint(equalTo: sideMenuView.leadingAnchor, constant: 12),
            sideMenuStack.trailingAnchor.constraint(equalTo: sideMenuView.trailingAnchor, constant: -12)
        ])
    }

    // MARK: - Focus Guides
    private func setupFocusGuides() {
        view.addLayoutGuide(upToMenuFocusGuide)

        NSLayoutConstraint.activate([
            upToMenuFocusGuide.topAnchor.constraint(equalTo: menuButton.topAnchor),
            upToMenuFocusGuide.bottomAnchor.constraint(equalTo: sectionTitleLabel.topAnchor),
            upToMenuFocusGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            upToMenuFocusGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        upToMenuFocusGuide.preferredFocusEnvironments = [menuButton]
    }

    // MARK: - Actions
    @objc private func toggleSideMenu() {
        viewModel.isSideMenuOpen ? closeSideMenu() : openSideMenu()
    }

    private func openSideMenu() {
        viewModel.isSideMenuOpen = true
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
        viewModel.isSideMenuOpen = false
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
        viewModel.selectSideMenu(at: sender.tag)
    }

    @objc private func playButtonDidTap() {
        presentVideoPlayer()
    }

    private func presentVideoPlayer() {
        let playerVC = TVPlayerViewController()

        playerVC.onDismiss = { [weak self] in
            print("Player dismissed")
        }

        let testHLSURL = URL(string: "https://test-streams.mux.dev/x36xhzz/x3ysqsyx/media.m3u8")!
        playerVC.play(url: testHLSURL)

        self.present(playerVC, animated: true)
    }

    // MARK: - Preferred Focus
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        if viewModel.isSideMenuOpen {
            if let selectedBtn = sideMenuStack.arrangedSubviews.first(where: { ($0 as? UIButton)?.tag == viewModel.selectedSideMenuIndex }) {
                return [selectedBtn]
            }
            return sideMenuStack.arrangedSubviews
        }
        // Focus on play button for easy testing
        return [playButton]
    }
}

// MARK: - CollectionView DataSource & Delegate
extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfShows()
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ShowCell.reuseIdentifier, for: indexPath) as! ShowCell
        let show = viewModel.showItem(at: indexPath.item)
        cell.configure(with: show)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.cellForItem(at: indexPath)?.setNeedsFocusUpdate()
    }
}
