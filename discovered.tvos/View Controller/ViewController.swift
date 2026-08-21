import UIKit

final class ViewController: UIViewController {
    private let viewModel = HomeViewModel()
    private let dashboardCard = UIView()
    private let header = UIView()
    private let heroHeaderView = HeroHeaderView()
    private let brandMark = UIImageView()
    private let brandLabel = UILabel()
    private let navigationStack = UIStackView()
    private let playButton = UIButton(type: .system)
    private let moreInfoButton = UIButton(type: .system)
    private let sectionTitleLabel = UILabel()
    private let viewAllButton = UIButton(type: .system)
    private var collectionView: UICollectionView!
    private var featuredIndex = 0
    private var heroHeightConstraint: NSLayoutConstraint!
    private var isHeroCollapsed = false
    private var requestedFocusTarget: UIFocusEnvironment?
    private weak var lastTopMenuButton: UIButton?
    private let menuToPlayFocusGuide = UIFocusGuide()
    private let playToRailFocusGuide = UIFocusGuide()
    private let railToPlayFocusGuide = UIFocusGuide()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        bindViewModel()
    }

    private func setupUI() {
        dashboardCard.backgroundColor = UIColor(red: 0.045, green: 0.055, blue: 0.075, alpha: 1)
        dashboardCard.layer.cornerRadius = 34
        dashboardCard.layer.borderWidth = 3
        dashboardCard.layer.borderColor = UIColor.white.withAlphaComponent(0.78).cgColor
        dashboardCard.clipsToBounds = true
        dashboardCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dashboardCard)

        header.translatesAutoresizingMaskIntoConstraints = false
        dashboardCard.addSubview(header)
        brandMark.image = UIImage(systemName: "play.fill")
        brandMark.tintColor = .white
        brandMark.backgroundColor = UIColor(red: 0.36, green: 0.34, blue: 0.96, alpha: 1)
        brandMark.contentMode = .center
        brandMark.layer.cornerRadius = 12
        brandMark.clipsToBounds = true
        brandMark.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(brandMark)
        brandLabel.text = "DiscoveredTV"
        brandLabel.font = .systemFont(ofSize: 28, weight: .bold)
        brandLabel.textColor = UIColor(white: 0.91, alpha: 1)
        brandLabel.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(brandLabel)

        navigationStack.axis = .horizontal
        navigationStack.spacing = 2
        navigationStack.alignment = .center
        navigationStack.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(navigationStack)
        ["SPOTLIGHT", "MUSIC", "MOVIES", "TELEVISION"].enumerated().forEach { index, title in
            let button = UIButton(type: .system)
            var config = UIButton.Configuration.plain()
            config.title = title
            config.image = index == 0 ? UIImage(systemName: "house.fill") : nil
            config.imagePadding = 70
            config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: index == 0 ? 18 : 7, bottom: 8, trailing: index == 0 ? 18 : 7)
            button.configuration = config
            button.titleLabel?.font = .systemFont(ofSize: 10, weight: .medium)
             
            button.tintColor = UIColor(white: 0.8, alpha: 1)
            button.tag = index
            button.addTarget(self, action: #selector(navigationItemSelected(_:)), for: .primaryActionTriggered)
            if index == 0 { button.configuration?.baseBackgroundColor = UIColor(red: 0.36, green: 0.34, blue: 0.96, alpha: 1); button.configuration?.baseForegroundColor = .white; button.layer.cornerRadius = 18 }
            navigationStack.addArrangedSubview(button)
        }

        let searchButton = makeHeaderButton(title: "SEARCH", image: "magnifyingglass")
        let profileButton = makeHeaderButton(title: nil, image: "person.crop.circle")
        header.addSubview(searchButton); header.addSubview(profileButton)

        heroHeaderView.translatesAutoresizingMaskIntoConstraints = false
        heroHeaderView.layer.borderWidth = 2
        heroHeaderView.layer.borderColor = UIColor.white.cgColor
        dashboardCard.addSubview(heroHeaderView)
        configureActionButton(playButton, title: "Play", image: "play.fill", background: UIColor(red: 0.74, green: 0.73, blue: 1, alpha: 1), foreground: UIColor(red: 0.05, green: 0.05, blue: 0.24, alpha: 1))
        playButton.addTarget(self, action: #selector(playButtonDidTap), for: .primaryActionTriggered)
        dashboardCard.addSubview(playButton)
        configureActionButton(moreInfoButton, title: "Details", image: "info.circle.fill", background: UIColor(red: 0.20, green: 0.21, blue: 0.25, alpha: 1), foreground: .white)
        moreInfoButton.addTarget(self, action: #selector(detailsButtonDidTap), for: .primaryActionTriggered)
        dashboardCard.addSubview(moreInfoButton)

        sectionTitleLabel.text = "Continue Watching"
        sectionTitleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        sectionTitleLabel.textColor = UIColor(white: 0.9, alpha: 1)
        sectionTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        dashboardCard.addSubview(sectionTitleLabel)
        viewAllButton.setTitle("View All  ›", for: .normal)
        viewAllButton.setTitleColor(UIColor(white: 0.82, alpha: 1), for: .normal)
        viewAllButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        viewAllButton.translatesAutoresizingMaskIntoConstraints = false
        dashboardCard.addSubview(viewAllButton)

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        // Portrait artwork is easier to scan on television and keeps the
        // content rail at the standard 9:16 streaming-poster ratio.
        layout.itemSize = CGSize(width: 180, height: 249)
        layout.minimumLineSpacing = 18
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 64)
        collectionView.dataSource = self; collectionView.delegate = self
        collectionView.register(ShowCell.self, forCellWithReuseIdentifier: ShowCell.reuseIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        dashboardCard.addSubview(collectionView)

        heroHeightConstraint = heroHeaderView.heightAnchor.constraint(equalToConstant: 832)
        NSLayoutConstraint.activate([
            dashboardCard.topAnchor.constraint(equalTo: view.topAnchor, constant: 2), dashboardCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 2), dashboardCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -2), dashboardCard.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -2),
            header.topAnchor.constraint(equalTo: dashboardCard.topAnchor, constant: 18), header.leadingAnchor.constraint(equalTo: dashboardCard.leadingAnchor, constant: 64), header.trailingAnchor.constraint(equalTo: dashboardCard.trailingAnchor, constant: -64), header.heightAnchor.constraint(equalToConstant: 48),
            brandMark.leadingAnchor.constraint(equalTo: header.leadingAnchor), brandMark.centerYAnchor.constraint(equalTo: header.centerYAnchor), brandMark.widthAnchor.constraint(equalToConstant: 36), brandMark.heightAnchor.constraint(equalToConstant: 36),
            brandLabel.leadingAnchor.constraint(equalTo: brandMark.trailingAnchor, constant: 10), brandLabel.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            navigationStack.centerXAnchor.constraint(equalTo: header.centerXAnchor, constant: 45), navigationStack.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            profileButton.trailingAnchor.constraint(equalTo: header.trailingAnchor), profileButton.centerYAnchor.constraint(equalTo: header.centerYAnchor), profileButton.widthAnchor.constraint(equalToConstant: 38),
            searchButton.trailingAnchor.constraint(equalTo: profileButton.leadingAnchor, constant: -30), searchButton.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            // One shared page grid keeps every dashboard element aligned.
            heroHeaderView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 20), heroHeaderView.leadingAnchor.constraint(equalTo: dashboardCard.leadingAnchor, constant: 64), heroHeaderView.trailingAnchor.constraint(equalTo: dashboardCard.trailingAnchor, constant: -64), heroHeightConstraint,
            playButton.leadingAnchor.constraint(equalTo: heroHeaderView.leadingAnchor, constant: 48), playButton.bottomAnchor.constraint(equalTo: heroHeaderView.bottomAnchor, constant: -36), playButton.heightAnchor.constraint(equalToConstant: 48),
            moreInfoButton.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 12), moreInfoButton.centerYAnchor.constraint(equalTo: playButton.centerYAnchor), moreInfoButton.heightAnchor.constraint(equalToConstant: 48),
            sectionTitleLabel.topAnchor.constraint(equalTo: heroHeaderView.bottomAnchor, constant: 16), sectionTitleLabel.leadingAnchor.constraint(equalTo: heroHeaderView.leadingAnchor),
            viewAllButton.trailingAnchor.constraint(equalTo: heroHeaderView.trailingAnchor, constant: -4), viewAllButton.centerYAnchor.constraint(equalTo: sectionTitleLabel.centerYAnchor),
            collectionView.topAnchor.constraint(equalTo: sectionTitleLabel.bottomAnchor, constant: 8), collectionView.leadingAnchor.constraint(equalTo: heroHeaderView.leadingAnchor), collectionView.trailingAnchor.constraint(equalTo: heroHeaderView.trailingAnchor), collectionView.bottomAnchor.constraint(equalTo: dashboardCard.bottomAnchor, constant: -8)
        ])

        // Explicit vertical focus routing for the Siri Remote.
        dashboardCard.addLayoutGuide(menuToPlayFocusGuide)
        dashboardCard.addLayoutGuide(playToRailFocusGuide)
        dashboardCard.addLayoutGuide(railToPlayFocusGuide)
        NSLayoutConstraint.activate([
            menuToPlayFocusGuide.topAnchor.constraint(equalTo: header.bottomAnchor), menuToPlayFocusGuide.bottomAnchor.constraint(equalTo: playButton.topAnchor), menuToPlayFocusGuide.centerXAnchor.constraint(equalTo: playButton.centerXAnchor), menuToPlayFocusGuide.widthAnchor.constraint(equalTo: heroHeaderView.widthAnchor),
            playToRailFocusGuide.topAnchor.constraint(equalTo: playButton.bottomAnchor), playToRailFocusGuide.bottomAnchor.constraint(equalTo: sectionTitleLabel.topAnchor), playToRailFocusGuide.leadingAnchor.constraint(equalTo: heroHeaderView.leadingAnchor), playToRailFocusGuide.trailingAnchor.constraint(equalTo: heroHeaderView.trailingAnchor),
            railToPlayFocusGuide.topAnchor.constraint(equalTo: sectionTitleLabel.bottomAnchor), railToPlayFocusGuide.bottomAnchor.constraint(equalTo: collectionView.topAnchor), railToPlayFocusGuide.leadingAnchor.constraint(equalTo: heroHeaderView.leadingAnchor), railToPlayFocusGuide.trailingAnchor.constraint(equalTo: heroHeaderView.trailingAnchor)
        ])
        menuToPlayFocusGuide.preferredFocusEnvironments = [playButton]
        playToRailFocusGuide.preferredFocusEnvironments = [collectionView]
        railToPlayFocusGuide.preferredFocusEnvironments = [playButton]
    }

    private func makeHeaderButton(title: String?, image: String) -> UIButton {
        let button = UIButton(type: .system); var config = UIButton.Configuration.plain(); config.title = title; config.image = UIImage(systemName: image); config.imagePadding = 8; button.configuration = config; button.tintColor = UIColor(white: 0.77, alpha: 1); button.translatesAutoresizingMaskIntoConstraints = false; return button
    }
    private func configureActionButton(_ button: UIButton, title: String, image: String, background: UIColor, foreground: UIColor) {
        var config = UIButton.Configuration.filled(); config.title = title; config.image = UIImage(systemName: image); config.imagePadding = 8; config.baseBackgroundColor = background; config.baseForegroundColor = foreground; config.cornerStyle = .fixed; config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16); button.configuration = config; button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold); button.layer.cornerRadius = 8; button.clipsToBounds = true; button.layer.borderWidth = 1; button.layer.borderColor = UIColor.white.withAlphaComponent(0.34).cgColor; button.translatesAutoresizingMaskIntoConstraints = false
    }
    private func bindViewModel() {
        viewModel.onDataUpdated = { [weak self] in guard let self else { return }; self.collectionView.reloadData(); if self.viewModel.numberOfShows() > 0 { let show = self.viewModel.showItem(at: 0); self.heroHeaderView.updateHeroData(title: show.title, imageName: show.imageName, videoUrl: show.videoUrl) } }
    }
    @objc private func navigationItemSelected(_ sender: UIButton) {
        // Keeps the top navigation directly actionable with the Siri Remote.
        viewModel.selectSideMenu(at: sender.tag)
        sectionTitleLabel.text = ["Continue Watching", "Music", "Movies", "Television"][sender.tag]
    }
    @objc private func playButtonDidTap() { presentVideoPlayer() }
    @objc private func detailsButtonDidTap() {
        guard viewModel.numberOfShows() > featuredIndex else { return }
        let item = viewModel.showItem(at: featuredIndex)
        let detail = DetailViewController(show: item, allShows: viewModel.shows)
        if let nav = navigationController { nav.pushViewController(detail, animated: true) }
        else { present(detail, animated: true) }
    }
    private func presentVideoPlayer() { let player = TVPlayerViewController(); player.play(url: URL(string: "https://serverguys-s3-trans-cdn.discovered.tv/aud_270/videos/6a34e55d55beb/6a34e55d55beb.m3u8")!); present(player, animated: true) }
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        if let requestedFocusTarget { return [requestedFocusTarget] }
        if isHeroCollapsed { return [collectionView] }
        return [playButton]
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        let isDown = presses.contains { $0.type == .downArrow }
        let isUp = presses.contains { $0.type == .upArrow }
        let isTopMenuFocused = navigationStack.arrangedSubviews.contains { $0.isFocused }

        if isDown && isTopMenuFocused {
            lastTopMenuButton = navigationStack.arrangedSubviews.first(where: { $0.isFocused }) as? UIButton
            requestFocus(playButton)
            return
        }
        if !isHeroCollapsed,
           (playButton.isFocused || moreInfoButton.isFocused),
           isDown {
            setHeroCollapsed(true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
                self.requestFocus(self.collectionView)
            }
            return
        }
        if isUp && (playButton.isFocused || moreInfoButton.isFocused) {
            requestFocus(lastTopMenuButton ?? navigationStack.arrangedSubviews.first!)
            return
        }
        if isUp && collectionView.visibleCells.contains(where: { $0.isFocused }) {
            setHeroCollapsed(false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
                self.requestFocus(self.playButton)
            }
            return
        }
        super.pressesBegan(presses, with: event)
    }

    private func requestFocus(_ target: UIFocusEnvironment) {
        requestedFocusTarget = target
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
        DispatchQueue.main.async { self.requestedFocusTarget = nil }
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        guard let next = context.nextFocusedView else { return }
        if next.isDescendant(of: collectionView) {
            setHeroCollapsed(true)
        } else {
            setHeroCollapsed(false)
        }
    }

    private func setHeroCollapsed(_ collapsed: Bool) {
        guard collapsed != isHeroCollapsed else { return }
        isHeroCollapsed = collapsed
        heroHeightConstraint.constant = collapsed ? 666 : 832
        UIView.animate(withDuration: 0.32, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState]) {
            self.view.layoutIfNeeded()
        }
    }
}

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { viewModel.numberOfShows() }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell { let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ShowCell.reuseIdentifier, for: indexPath) as! ShowCell; cell.configure(with: viewModel.showItem(at: indexPath.item)); cell.onPlayButtonTapped = { [weak self] in self?.presentVideoPlayer() }; return cell }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) { let item = viewModel.showItem(at: indexPath.item); let detail = DetailViewController(show: item, allShows: viewModel.shows); if let nav = navigationController { nav.pushViewController(detail, animated: true) } else { present(detail, animated: true) } }
    func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) { if let indexPath = context.nextFocusedIndexPath { featuredIndex = indexPath.item; let item = viewModel.showItem(at: indexPath.item); heroHeaderView.updateHeroData(title: item.title, imageName: item.imageName, videoUrl: item.videoUrl) } }
}
