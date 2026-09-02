import UIKit

final class ViewController: UIViewController {

    // MARK: - Properties
    private let viewModel = HomeViewModel()
    
    private let navigationContainer = UIView()
    private let dashboardCard = UIView()
    private let header = UIView()
    private let heroHeaderView = HeroHeaderView()

    private let brandMark = UIImageView()
    private let brandLabel = UILabel()
    private let navigationStack = UIStackView()

    private let playButton = UIButton(type: .system)
    private let moreInfoButton = UIButton(type: .system)

    private let scrollView = UIScrollView()
    private let sliderContainerView = UIStackView()
    private var collectionViews: [UICollectionView] = []

    private var featuredIndex = 0
    private var selectedShow: ShowItem?

    private var heroHeightConstraint: NSLayoutConstraint!
    private var isHeroCollapsed = false

    private var requestedFocusTarget: UIFocusEnvironment?
    private weak var lastTopMenuButton: UIButton?
    private var activeSliderIndex: Int?
    private var isRailFocusTransitionInProgress = false

    private let menuToPlayFocusGuide = UIFocusGuide()
    private let playToRailFocusGuide = UIFocusGuide()
    private let railToPlayFocusGuide = UIFocusGuide()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        bindViewModel()
    }

    // MARK: - Setup UI
    private func setupUI() {

        // Dashboard
        dashboardCard.backgroundColor = UIColor(red: 0.045, green: 0.055, blue: 0.075, alpha: 1)
        dashboardCard.layer.cornerRadius = 8
        dashboardCard.layer.borderWidth = 3
        dashboardCard.layer.borderColor = UIColor.white.withAlphaComponent(0.78).cgColor
        dashboardCard.clipsToBounds = true
        dashboardCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dashboardCard)

        // Header
        header.translatesAutoresizingMaskIntoConstraints = false
        dashboardCard.addSubview(header)

        // Brand Icon
        brandMark.image = UIImage(named: "logo_dark")
        brandMark.tintColor = .white
        brandMark.contentMode = .scaleAspectFit
        brandMark.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(brandMark)

        // Brand Label
        brandLabel.text = "DiscoveredTV"
        brandLabel.font = .systemFont(ofSize: 24, weight: .bold)
        brandLabel.textColor = UIColor(white: 0.91, alpha: 1)
        brandLabel.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(brandLabel)

        // Navigation Container (Netflix style)
        navigationContainer.backgroundColor = UIColor(white: 0.18, alpha: 0.95)
        navigationContainer.layer.cornerRadius = 28
        navigationContainer.clipsToBounds = true
        navigationContainer.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(navigationContainer)

        // Navigation Stack
        navigationStack.axis = .horizontal
        navigationStack.spacing = 0
        navigationStack.alignment = .center
        navigationStack.distribution = .fillEqually
        navigationStack.translatesAutoresizingMaskIntoConstraints = false
        navigationContainer.addSubview(navigationStack)

        // Top Navigation Buttons
        let titles = ["SPOTLIGHT", "MUSIC", "MOVIES", "TELEVISION"]
        
        for (index, title) in titles.enumerated() {
            let button = UIButton(type: .system)
            
            var config = UIButton.Configuration.plain()
            config.title = title
            config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 28, bottom: 16, trailing: 28)
            
            var attributes = AttributeContainer()
            attributes.font = .systemFont(ofSize: 16, weight: .semibold)
            config.attributedTitle = AttributedString(title, attributes: attributes)
            
            config.baseForegroundColor = UIColor(white: 0.75, alpha: 1)
            config.baseBackgroundColor = .clear
            
            button.configuration = config
            button.tag = index
            button.layer.cornerRadius = 22
            button.clipsToBounds = true
            
            if index == 0 {
                applySelectedStyle(to: button)
            }
            
            button.addTarget(self, action: #selector(navigationItemSelected(_:)), for: .primaryActionTriggered)
            navigationStack.addArrangedSubview(button)
        }

        // Search & Profile
        let searchButton = makeHeaderButton(title: "SEARCH", image: "magnifyingglass")
        let profileButton = makeHeaderButton(title: nil, image: "person.crop.circle")
        profileButton.addTarget(self, action: #selector(profileTapped), for: .primaryActionTriggered)
        header.addSubview(searchButton)
        header.addSubview(profileButton)

        // Hero
        heroHeaderView.translatesAutoresizingMaskIntoConstraints = false
        heroHeaderView.layer.borderWidth = 4
        heroHeaderView.layer.borderColor = UIColor.white.cgColor
        dashboardCard.addSubview(heroHeaderView)

        // Scroll View
        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        dashboardCard.addSubview(scrollView)

        // Slider Container
        sliderContainerView.axis = .vertical
        sliderContainerView.spacing = 24
        sliderContainerView.distribution = .fill
        sliderContainerView.alignment = .fill
        sliderContainerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(sliderContainerView)

        // Hero Height Constraint
        heroHeightConstraint = heroHeaderView.heightAnchor.constraint(equalToConstant: 832)

        // MARK: - Constraints
        NSLayoutConstraint.activate([
            // Dashboard
            dashboardCard.topAnchor.constraint(equalTo: view.topAnchor, constant: 2),
            dashboardCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 2),
            dashboardCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -2),
            dashboardCard.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -2),

            // Header
            header.topAnchor.constraint(equalTo: dashboardCard.topAnchor, constant: 18),
            header.leadingAnchor.constraint(equalTo: dashboardCard.leadingAnchor, constant: 20),
            header.trailingAnchor.constraint(equalTo: dashboardCard.trailingAnchor, constant: -64),
            header.heightAnchor.constraint(equalToConstant: 56),

            // Brand
            brandMark.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            brandMark.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            brandMark.widthAnchor.constraint(equalToConstant: 32),
            brandMark.heightAnchor.constraint(equalToConstant: 32),

            brandLabel.leadingAnchor.constraint(equalTo: brandMark.trailingAnchor, constant: 8),
            brandLabel.centerYAnchor.constraint(equalTo: header.centerYAnchor),

            // Search
            searchButton.leadingAnchor.constraint(equalTo: brandLabel.trailingAnchor, constant: 36),
            searchButton.centerYAnchor.constraint(equalTo: header.centerYAnchor),

            // Navigation Container
            navigationContainer.centerXAnchor.constraint(equalTo: header.centerXAnchor),
            navigationContainer.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            navigationContainer.heightAnchor.constraint(equalToConstant: 56),

            // Navigation Stack
            navigationStack.topAnchor.constraint(equalTo: navigationContainer.topAnchor, constant: 4),
            navigationStack.bottomAnchor.constraint(equalTo: navigationContainer.bottomAnchor, constant: -4),
            navigationStack.leadingAnchor.constraint(equalTo: navigationContainer.leadingAnchor, constant: 4),
            navigationStack.trailingAnchor.constraint(equalTo: navigationContainer.trailingAnchor, constant: -4),

            // Profile
            profileButton.trailingAnchor.constraint(equalTo: header.trailingAnchor),
            profileButton.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            profileButton.widthAnchor.constraint(equalToConstant: 34),

            // Hero
            heroHeaderView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 20),
            heroHeaderView.leadingAnchor.constraint(equalTo: dashboardCard.leadingAnchor, constant: 64),
            heroHeaderView.trailingAnchor.constraint(equalTo: dashboardCard.trailingAnchor, constant: -64),
            heroHeightConstraint,

            // Scroll View
            scrollView.topAnchor.constraint(equalTo: heroHeaderView.bottomAnchor, constant: 24),
            scrollView.leadingAnchor.constraint(equalTo: dashboardCard.leadingAnchor, constant: 64),
            scrollView.trailingAnchor.constraint(equalTo: dashboardCard.trailingAnchor, constant: -64),
            scrollView.bottomAnchor.constraint(equalTo: dashboardCard.bottomAnchor, constant: -8),

            // Slider Container
            sliderContainerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            sliderContainerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            sliderContainerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            sliderContainerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            sliderContainerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        // Focus Guides
        dashboardCard.addLayoutGuide(menuToPlayFocusGuide)
        dashboardCard.addLayoutGuide(playToRailFocusGuide)
        dashboardCard.addLayoutGuide(railToPlayFocusGuide)

        NSLayoutConstraint.activate([
            menuToPlayFocusGuide.topAnchor.constraint(equalTo: header.bottomAnchor),
            menuToPlayFocusGuide.bottomAnchor.constraint(equalTo: heroHeaderView.topAnchor),
            menuToPlayFocusGuide.leadingAnchor.constraint(equalTo: heroHeaderView.leadingAnchor),
            menuToPlayFocusGuide.widthAnchor.constraint(equalTo: heroHeaderView.widthAnchor),

            playToRailFocusGuide.topAnchor.constraint(equalTo: heroHeaderView.bottomAnchor),
            playToRailFocusGuide.bottomAnchor.constraint(equalTo: scrollView.topAnchor),
            playToRailFocusGuide.leadingAnchor.constraint(equalTo: heroHeaderView.leadingAnchor),
            playToRailFocusGuide.trailingAnchor.constraint(equalTo: heroHeaderView.trailingAnchor),

            railToPlayFocusGuide.topAnchor.constraint(equalTo: scrollView.topAnchor),
            railToPlayFocusGuide.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            railToPlayFocusGuide.leadingAnchor.constraint(equalTo: heroHeaderView.leadingAnchor),
            railToPlayFocusGuide.trailingAnchor.constraint(equalTo: heroHeaderView.trailingAnchor)
        ])

        menuToPlayFocusGuide.preferredFocusEnvironments = []
        playToRailFocusGuide.preferredFocusEnvironments = []
        playToRailFocusGuide.isEnabled = false
        railToPlayFocusGuide.preferredFocusEnvironments = [navigationStack.arrangedSubviews.first ?? header]
    }

    // MARK: - Style Helpers
    private func applySelectedStyle(to button: UIButton) {
        guard var config = button.configuration else { return }
        config.baseBackgroundColor = .white
        config.baseForegroundColor = .black
        button.configuration = config
    }

    private func applyUnselectedStyle(to button: UIButton) {
        guard var config = button.configuration else { return }
        config.baseBackgroundColor = .clear
        config.baseForegroundColor = UIColor(white: 0.75, alpha: 1)
        button.configuration = config
    }

    // MARK: - Header Button Factory
    private func makeHeaderButton(title: String?, image: String) -> UIButton {
        let button = UIButton(type: .system)
        
        var config = UIButton.Configuration.plain()
        config.title = title
        config.image = UIImage(systemName: image)
        
        let iconSize: CGFloat = title == nil ? 24 : 16
        
        // ← Yahan se icon aur text ke beech space control hoti hai
        config.imagePadding = title == nil ? 0 : 10   // pehle 6 tha, ab 10
        
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(
            pointSize: iconSize,
            weight: .semibold
        )
        
        if title != nil {
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = .systemFont(ofSize: 18, weight: .bold)
                return outgoing
            }
        }
        
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8)
        
        button.configuration = config
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    // MARK: - ViewModel Binding
    private func bindViewModel() {
        viewModel.onDataUpdated = { [weak self] in
            guard let self else { return }
            self.setupSliders()
            
            if self.viewModel.numberOfShows() > 0 {
                let show = self.viewModel.showItem(at: 0)
                self.selectedShow = show
                self.heroHeaderView.updateHeroData(
                    title: show.title,
                    imageName: show.imageName,
                    videoUrl: show.videoUrl,
                    genre: show.genre
                )
            }
        }
    }

    // MARK: - Sliders
    // MARK: - Sliders
    private func setupSliders() {
        sliderContainerView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        collectionViews.removeAll()
        activeSliderIndex = nil

        for sliderIndex in 0..<viewModel.numberOfSliders() {
            guard let slider = viewModel.slider(at: sliderIndex) else { continue }

            let sliderStack = UIStackView()
            sliderStack.axis = .vertical
            sliderStack.spacing = 12
            sliderStack.translatesAutoresizingMaskIntoConstraints = false

            let titleLabel = UILabel()
            titleLabel.text = slider.type ?? "Videos"
            titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
            titleLabel.textColor = UIColor(white: 0.9, alpha: 1)
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            sliderStack.addArrangedSubview(titleLabel)

            let collectionView = createCollectionView(tag: sliderIndex)
            sliderStack.addArrangedSubview(collectionView)

            // ↑ increased height so focused cell has space to scale
            collectionView.heightAnchor.constraint(equalToConstant: 280).isActive = true

            sliderContainerView.addArrangedSubview(sliderStack)
            collectionViews.append(collectionView)
        }
    }

    private func createCollectionView(tag: Int) -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 140, height: 230)          // slightly larger cells
        layout.minimumLineSpacing = 22
        layout.sectionInset = UIEdgeInsets(top: 20, left: 8, bottom: 20, right: 64)  // ← important for focus scale

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionView.clipsToBounds = false          // ← MOST IMPORTANT – allows focus scale to go outside
        collectionView.tag = tag
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ShowCell.self, forCellWithReuseIdentifier: ShowCell.reuseIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }

    // MARK: - Navigation Action
    @objc private func navigationItemSelected(_ sender: UIButton) {
        for case let button as UIButton in navigationStack.arrangedSubviews {
            applyUnselectedStyle(to: button)
        }
        applySelectedStyle(to: sender)
        viewModel.selectSideMenu(at: sender.tag)
    }

    // MARK: - Video Player
    private func presentVideoPlayer() {
        guard let show = selectedShow,
              let videoUrlString = show.videoUrl,
              let videoUrl = URL(string: videoUrlString) else { return }

        let player = TVPlayerViewController()
        player.play(url: videoUrl, title: show.title, episodeInfo: show.year ?? "")
        present(player, animated: true)
    }

    // MARK: - Focus Management
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        if let requestedFocusTarget {
            return [requestedFocusTarget]
        }
        return [navigationStack.arrangedSubviews.first ?? header]
    }

    override func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool {
        guard !isRailFocusTransitionInProgress,
              let currentFocus = context.previouslyFocusedView,
              let sourceCollectionView = collectionViews.first(where: { currentFocus.isDescendant(of: $0) }) else {
            return super.shouldUpdateFocus(in: context)
        }

        switch context.focusHeading {
        case .down where sourceCollectionView.tag < collectionViews.count - 1:
            let destination = collectionViews[sourceCollectionView.tag + 1]
            DispatchQueue.main.async { [weak self] in
                self?.moveFocus(from: sourceCollectionView, to: destination)
            }
            return false

        case .up where sourceCollectionView.tag > 0:
            let destination = collectionViews[sourceCollectionView.tag - 1]
            DispatchQueue.main.async { [weak self] in
                self?.moveFocus(from: sourceCollectionView, to: destination)
            }
            return false

        case .up:
            activeSliderIndex = nil
            setHeroCollapsed(false)
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.requestFocus(self.lastTopMenuButton ?? self.navigationStack.arrangedSubviews.first ?? self.header)
            }
            return false

        default:
            return super.shouldUpdateFocus(in: context)
        }
    }
    
    @objc private func profileTapped() {
        if AuthManager.shared.isLoggedIn {
            let settingsVC = AccountSettingsViewController()
            settingsVC.modalPresentationStyle = .overFullScreen
            present(settingsVC, animated: true)
        } else {
            let loginVC = LoginViewController()
            loginVC.modalPresentationStyle = .overFullScreen   // Important for blur
            loginVC.onLoginSuccess = { [weak self] in
                let settingsVC = AccountSettingsViewController()
                settingsVC.modalPresentationStyle = .overFullScreen
                self?.present(settingsVC, animated: true)
            }
            present(loginVC, animated: true)
        }
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        let isDown = presses.contains { $0.type == .downArrow }
        let isTopMenuFocused = navigationStack.arrangedSubviews.contains { $0.isFocused }

        if isDown && isTopMenuFocused {
            lastTopMenuButton = navigationStack.arrangedSubviews.first(where: { $0.isFocused }) as? UIButton
            setHeroCollapsed(true)
            if let first = collectionViews.first {
                activeSliderIndex = 0
                focusOnCell(at: IndexPath(item: 0, section: 0), in: first)
            }
            return
        }
        super.pressesBegan(presses, with: event)
    }

    private func moveFocus(from source: UICollectionView, to destination: UICollectionView) {
        guard !isRailFocusTransitionInProgress else { return }
        isRailFocusTransitionInProgress = true
        activeSliderIndex = destination.tag

        let focusedCell = source.visibleCells.first(where: { $0.isFocused })
        let sourceIndex = focusedCell.flatMap { source.indexPath(for: $0) }?.item ?? 0
        let maxItem = max(0, destination.numberOfItems(inSection: 0) - 1)
        let targetIndex = min(sourceIndex, maxItem)

        scrollToCollectionView(destination, animated: true)
        focusOnCell(at: IndexPath(item: targetIndex, section: 0), in: destination)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.isRailFocusTransitionInProgress = false
        }
    }

    private func focusOnCell(at indexPath: IndexPath, in collectionView: UICollectionView) {
        collectionView.layoutIfNeeded()
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
        collectionView.layoutIfNeeded()

        guard let cell = collectionView.cellForItem(at: indexPath) else {
            isRailFocusTransitionInProgress = false
            return
        }
        requestFocus(cell)
    }

    private func scrollToCollectionView(_ collectionView: UICollectionView, animated: Bool) {
        guard let parentStack = collectionView.superview as? UIStackView,
              let containerStack = parentStack.superview as? UIStackView else { return }

        containerStack.layoutIfNeeded()

        let frameInScroll = collectionView.convert(collectionView.bounds, to: scrollView)
        let targetY = frameInScroll.origin.y - 16
        let maxY = max(0, scrollView.contentSize.height - scrollView.bounds.height)

        if targetY < scrollView.contentOffset.y {
            scrollView.setContentOffset(CGPoint(x: 0, y: min(maxY, max(0, targetY))), animated: animated)
        } else if targetY + frameInScroll.height > scrollView.contentOffset.y + scrollView.bounds.height {
            let newY = targetY + frameInScroll.height + 32 - scrollView.bounds.height
            scrollView.setContentOffset(CGPoint(x: 0, y: min(maxY, max(0, newY))), animated: animated)
        }
    }

    private func requestFocus(_ target: UIFocusEnvironment) {
        requestedFocusTarget = target
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
        DispatchQueue.main.async {
            self.requestedFocusTarget = nil
        }
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        guard let next = context.nextFocusedView else { return }
        let isInSlider = collectionViews.contains { next.isDescendant(of: $0) }
        setHeroCollapsed(isInSlider)
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

// MARK: - UICollectionView
extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let slider = viewModel.slider(at: collectionView.tag) else { return 0 }
        return slider.videos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ShowCell.reuseIdentifier, for: indexPath) as! ShowCell
        
        guard let slider = viewModel.slider(at: collectionView.tag) else { return cell }
        
        let show = slider.videos[indexPath.item]
        cell.configure(with: show)
        
        cell.onPlayButtonTapped = { [weak self] in
            self?.selectedShow = show
            self?.presentVideoPlayer()
        }
        
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let slider = viewModel.slider(at: collectionView.tag) else { return }
        let item = slider.videos[indexPath.item]
        
        let detail = DetailViewController(show: item, allShows: viewModel.shows)
        
        if let nav = navigationController {
            nav.pushViewController(detail, animated: true)
        } else {
            present(detail, animated: true)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        guard let indexPath = context.nextFocusedIndexPath,
              let slider = viewModel.slider(at: collectionView.tag) else { return }
        
        activeSliderIndex = collectionView.tag
        featuredIndex = indexPath.item
        let item = slider.videos[indexPath.item]
        selectedShow = item
        
        heroHeaderView.updateHeroData(
            title: item.title,
            imageName: item.imageName,
            videoUrl: item.videoUrl,
            genre: item.genre
        )
    }
}
