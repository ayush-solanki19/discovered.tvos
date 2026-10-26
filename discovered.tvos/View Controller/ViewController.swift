import UIKit

final class ViewController: UIViewController {

    // MARK: - Layout Metrics

    private enum Metrics {

        /// Top inset of the whole rail stack inside the scroll view.
        static let railTopInset: CGFloat = 16

        /// Fixed height of every rail title ("Top Videos Of The Month" …).
        static let railTitleHeight: CGFloat = 34

        /// Space between the rail title and its collection view.
        static let railSpacing: CGFloat = 10

        /// Vertical section inset inside a rail. Gives the focused
        /// cell (scaled 1.04) room to grow without being clipped.
        static let sectionVerticalInset: CGFloat = 18

        /// Vertical space between two rails.
        static let interRailSpacing: CGFloat = 24

        /// Height required to show one complete rail (title + cards).
        /// Uses the tallest rail style so the hero math is always safe.
        static var fullRailHeight: CGFloat {
            railTopInset
            + railTitleHeight
            + railSpacing
            + RailStyle.poster.collectionHeight
        }

        /// Everything above the scroll view except the hero itself:
        /// card top (2) + header top (18) + header (56)
        /// + header→hero gap (20) + hero→scroll gap (24)
        /// + card bottom (2) + scroll bottom (8)
        static let verticalChrome: CGFloat = 130
    }

    // MARK: - Rail Style

    /// Look of a home rail (see the Netflix-style reference):
    /// - landscape: wide 16:9 thumbnails ("Continue Watching")
    /// - poster:    tall 2:3 posters ("Trending Now")
    /// - ranked:    big outlined numbers + poster ("Top 10")
    private enum RailStyle {

        case landscape
        case poster
        case ranked

        /// Top 10 rails only ever show ten cards.
        static let maxRankedItems = 10

        static func style(
            for slider: VideoSlider,
            at index: Int
        ) -> RailStyle {

            let name = (slider.type ?? "").lowercased()

            if name.contains("top") {
                return .ranked
            }

            if index == 0 {
                return .landscape
            }

            return .poster
        }

        var itemSize: CGSize {
            switch self {
            case .landscape:
                return CGSize(width: 304, height: 171)
            case .poster:
                return CGSize(width: 160, height: 240)
            case .ranked:
                return CGSize(
                    width: RankedShowCell.posterWidth + 96,
                    height: 225
                )
            }
        }

        var itemSpacing: CGFloat {
            switch self {
            case .landscape: return 22
            case .poster: return 18
            case .ranked: return 8
            }
        }

        /// Height of the rail's collection view.
        ///
        /// Must fit the focus-scaled card (height * 1.04) plus both
        /// section insets, otherwise the focused cell pokes out of the
        /// rail and UIKit scrolls the outer scroll view to reveal it —
        /// which looked like the page jumping up and back on every
        /// left/right step.
        var collectionHeight: CGFloat {
            (itemSize.height * 1.04).rounded(.up)
            + Metrics.sectionVerticalInset * 2
            + 10
        }
    }

    // MARK: - Properties

    private let viewModel = HomeViewModel()

    private let navigationContainer = UIView()
    private let dashboardCard = UIView()
    private let header = UIView()
    private let heroHeaderView = HeroHeaderView()

    private let brandMark = UIImageView()
    private let brandLabel = UILabel()

    private let navigationStack = UIStackView()

    private var searchButton = UIButton(type: .system)
    private var profileButton = UIButton(type: .system)

    private let scrollView = UIScrollView()
    private let sliderContainerView = UIStackView()

    private var collectionViews: [UICollectionView] = []
    private var railStacks: [UIStackView] = []
    private var railStyles: [RailStyle] = []

    private var featuredIndex = 0
    private var selectedShow: ShowItem?

    private var heroHeightConstraint: NSLayoutConstraint!

    private var isHeroCollapsed = false

    private var expandedHeroHeight: CGFloat = 720
    private var collapsedHeroHeight: CGFloat = 580

    // MARK: - Focus State

    /// The bridge between the header and the first rail.
    /// Its destination is flipped depending on where focus currently is,
    /// so it works for BOTH directions (down into the rails,
    /// up back into the header).
    private let heroFocusGuide = UIFocusGuide()

    /// Last focused view inside the header
    /// (a menu button, SEARCH or the profile button).
    private weak var lastFocusedHeaderView: UIView?

    /// Currently applied tab (index of the nav button).
    private var selectedTabIndex: Int = 0

    /// Temporary focus target used by `preferredFocusEnvironments`.
    private weak var requestedFocusTarget: UIView?

    /// Remembered cell per rail. Cleared whenever the header is focused,
    /// so entering the rails from the top always lands on the FIRST cell.
    private var lastFocusedIndexPaths: [Int: IndexPath] = [:]

    /// Currently active rail.
    private var activeSliderIndex: Int?

    /// Last view the focus engine handed focus to inside this controller.
    private weak var focusedView: UIView?

    /// Debounce for the expensive part of the hero update.
    private var heroMediaWorkItem: DispatchWorkItem?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        setupUI()
        bindViewModel()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        recalculateHeroHeights()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // First launch / returning from another controller.
        restoreHeaderFocusIfNeeded()
    }

    // MARK: - Hero Sizing

    /// Hero height is derived from the real screen height so that the
    /// first rail (title + cards) is ALWAYS fully visible once the hero
    /// collapses — this is what used to be cut off at the top.
    private func recalculateHeroHeights() {

        let containerHeight = view.bounds.height

        guard containerHeight > 200 else {
            return
        }

        let available =
            containerHeight - Metrics.verticalChrome

        // Collapsed: full first rail + a peek of the next one.
        let collapsed =
            max(
                320,
                available - (Metrics.fullRailHeight + 30)
            )

        // Expanded: title + roughly half of the first row of cards.
        let expanded =
            max(
                collapsed + 80,
                available - 215
            )

        collapsedHeroHeight = collapsed
        expandedHeroHeight = expanded

        let target =
            isHeroCollapsed
            ? collapsedHeroHeight
            : expandedHeroHeight

        if abs(heroHeightConstraint.constant - target) > 0.5 {

            heroHeightConstraint.constant = target
            view.layoutIfNeeded()
        }
    }

    // MARK: - Setup UI

    private func setupUI() {

        // --------------------------------------------------
        // Dashboard
        // --------------------------------------------------

        dashboardCard.backgroundColor = UIColor(
            red: 0.045,
            green: 0.055,
            blue: 0.075,
            alpha: 1
        )

        dashboardCard.layer.cornerRadius = 8
        dashboardCard.layer.borderWidth = 3
        dashboardCard.layer.borderColor =
            UIColor.white.withAlphaComponent(0.78).cgColor

        dashboardCard.clipsToBounds = true
        dashboardCard.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(dashboardCard)

        // --------------------------------------------------
        // Header
        // --------------------------------------------------

        header.translatesAutoresizingMaskIntoConstraints = false
        dashboardCard.addSubview(header)

        // --------------------------------------------------
        // Brand Icon
        // --------------------------------------------------

        brandMark.image = UIImage(named: "logo_dark")
        brandMark.tintColor = .white
        brandMark.contentMode = .scaleAspectFit
        brandMark.translatesAutoresizingMaskIntoConstraints = false

        header.addSubview(brandMark)

        // --------------------------------------------------
        // Brand Label
        // --------------------------------------------------

        brandLabel.text = "DiscoveredTV"
        brandLabel.font = .appFont(ofSize: 24, weight: .bold)
        brandLabel.textColor = UIColor(white: 0.91, alpha: 1)
        brandLabel.translatesAutoresizingMaskIntoConstraints = false

        header.addSubview(brandLabel)

        // --------------------------------------------------
        // Navigation Container
        // --------------------------------------------------

        navigationContainer.backgroundColor =
            UIColor(white: 0.18, alpha: 0.95)

        navigationContainer.layer.cornerRadius = 28
        navigationContainer.clipsToBounds = true
        navigationContainer.translatesAutoresizingMaskIntoConstraints = false

        header.addSubview(navigationContainer)

        // --------------------------------------------------
        // Navigation Stack
        // --------------------------------------------------

        navigationStack.axis = .horizontal
        navigationStack.spacing = 0
        navigationStack.alignment = .center
        navigationStack.distribution = .fillEqually
        navigationStack.translatesAutoresizingMaskIntoConstraints = false

        navigationContainer.addSubview(navigationStack)

        // --------------------------------------------------
        // Top Navigation Buttons
        // --------------------------------------------------

        let titles = [
            "SPOTLIGHT",
            "MUSIC",
            "MOVIES",
            "TELEVISION"
        ]

        for (index, title) in titles.enumerated() {

            let button = UIButton(type: .system)

            var config = UIButton.Configuration.plain()

            config.contentInsets = NSDirectionalEdgeInsets(
                top: 16,
                leading: 28,
                bottom: 16,
                trailing: 28
            )

            var attributes = AttributeContainer()

            attributes.font = .appFont(
                ofSize: 16,
                weight: .semibold
            )

            config.attributedTitle = AttributedString(
                title,
                attributes: attributes
            )

            config.baseForegroundColor =
                UIColor(white: 0.75, alpha: 1)

            config.background.backgroundColor = .clear

            button.configuration = config

            button.tag = index
            button.layer.cornerRadius = 22
            button.clipsToBounds = true
            button.backgroundColor = .clear

            button.addTarget(
                self,
                action: #selector(navigationItemSelected(_:)),
                for: .primaryActionTriggered
            )

            navigationStack.addArrangedSubview(button)
        }

        // Spotlight selected initially.
        selectedTabIndex = 0
        lastFocusedHeaderView = topMenuButton(at: 0)
        refreshTopMenuStyles(focused: nil)

        // --------------------------------------------------
        // Search & Profile
        // --------------------------------------------------

        searchButton = makeHeaderButton(
            title: "SEARCH",
            image: "magnifyingglass"
        )

        profileButton = makeHeaderButton(
            title: nil,
            image: "person.crop.circle"
        )

        profileButton.addTarget(
            self,
            action: #selector(profileTapped),
            for: .primaryActionTriggered
        )

        searchButton.addTarget(
            self,
            action: #selector(searchTapped),
            for: .primaryActionTriggered
        )

        header.addSubview(searchButton)
        header.addSubview(profileButton)

        // --------------------------------------------------
        // Hero
        // --------------------------------------------------

        heroHeaderView.translatesAutoresizingMaskIntoConstraints = false

        heroHeaderView.layer.borderWidth = 4
        heroHeaderView.layer.borderColor =
            UIColor.white.cgColor

        dashboardCard.addSubview(heroHeaderView)

        // --------------------------------------------------
        // Scroll View
        // --------------------------------------------------

        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.clipsToBounds = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        dashboardCard.addSubview(scrollView)

        // --------------------------------------------------
        // Slider Container
        // --------------------------------------------------

        sliderContainerView.axis = .vertical
        sliderContainerView.spacing = Metrics.interRailSpacing
        sliderContainerView.distribution = .fill
        sliderContainerView.alignment = .fill

        sliderContainerView.layoutMargins = UIEdgeInsets(
            top: Metrics.railTopInset,
            left: 0,
            bottom: 24,
            right: 0
        )

        sliderContainerView.isLayoutMarginsRelativeArrangement = true
        sliderContainerView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(sliderContainerView)

        // --------------------------------------------------
        // Hero Height
        // --------------------------------------------------

        heroHeightConstraint =
            heroHeaderView.heightAnchor.constraint(
                equalToConstant: expandedHeroHeight
            )

        // --------------------------------------------------
        // Focus Guide (header <-> rails bridge)
        // --------------------------------------------------

        dashboardCard.addLayoutGuide(heroFocusGuide)

        // --------------------------------------------------
        // Constraints
        // --------------------------------------------------

        NSLayoutConstraint.activate([

            // Dashboard
            dashboardCard.topAnchor.constraint(
                equalTo: view.topAnchor,
                constant: 2
            ),

            dashboardCard.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 2
            ),

            dashboardCard.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -2
            ),

            dashboardCard.bottomAnchor.constraint(
                equalTo: view.bottomAnchor,
                constant: -2
            ),

            // Header
            header.topAnchor.constraint(
                equalTo: dashboardCard.topAnchor,
                constant: 18
            ),

            header.leadingAnchor.constraint(
                equalTo: dashboardCard.leadingAnchor,
                constant: 20
            ),

            header.trailingAnchor.constraint(
                equalTo: dashboardCard.trailingAnchor,
                constant: -64
            ),

            header.heightAnchor.constraint(
                equalToConstant: 56
            ),

            // Brand
            brandMark.leadingAnchor.constraint(
                equalTo: header.leadingAnchor
            ),

            brandMark.centerYAnchor.constraint(
                equalTo: header.centerYAnchor
            ),

            brandMark.widthAnchor.constraint(
                equalToConstant: 32
            ),

            brandMark.heightAnchor.constraint(
                equalToConstant: 32
            ),

            brandLabel.leadingAnchor.constraint(
                equalTo: brandMark.trailingAnchor,
                constant: 8
            ),

            brandLabel.centerYAnchor.constraint(
                equalTo: header.centerYAnchor
            ),

            // Search
            searchButton.leadingAnchor.constraint(
                equalTo: brandLabel.trailingAnchor,
                constant: 36
            ),

            searchButton.centerYAnchor.constraint(
                equalTo: header.centerYAnchor
            ),

            // Navigation Container
            navigationContainer.centerXAnchor.constraint(
                equalTo: header.centerXAnchor
            ),

            navigationContainer.centerYAnchor.constraint(
                equalTo: header.centerYAnchor
            ),

            navigationContainer.heightAnchor.constraint(
                equalToConstant: 56
            ),

            // Navigation Stack
            navigationStack.topAnchor.constraint(
                equalTo: navigationContainer.topAnchor,
                constant: 4
            ),

            navigationStack.bottomAnchor.constraint(
                equalTo: navigationContainer.bottomAnchor,
                constant: -4
            ),

            navigationStack.leadingAnchor.constraint(
                equalTo: navigationContainer.leadingAnchor,
                constant: 4
            ),

            navigationStack.trailingAnchor.constraint(
                equalTo: navigationContainer.trailingAnchor,
                constant: -4
            ),

            // Profile
            profileButton.trailingAnchor.constraint(
                equalTo: header.trailingAnchor
            ),

            profileButton.centerYAnchor.constraint(
                equalTo: header.centerYAnchor
            ),

            profileButton.widthAnchor.constraint(
                equalToConstant: 34
            ),

            // Hero
            heroHeaderView.topAnchor.constraint(
                equalTo: header.bottomAnchor,
                constant: 20
            ),

            heroHeaderView.leadingAnchor.constraint(
                equalTo: dashboardCard.leadingAnchor,
                constant: 64
            ),

            heroHeaderView.trailingAnchor.constraint(
                equalTo: dashboardCard.trailingAnchor,
                constant: -64
            ),

            heroHeightConstraint,

            // Scroll View
            scrollView.topAnchor.constraint(
                equalTo: heroHeaderView.bottomAnchor,
                constant: 24
            ),

            scrollView.leadingAnchor.constraint(
                equalTo: dashboardCard.leadingAnchor,
                constant: 64
            ),

            scrollView.trailingAnchor.constraint(
                equalTo: dashboardCard.trailingAnchor,
                constant: -64
            ),

            scrollView.bottomAnchor.constraint(
                equalTo: dashboardCard.bottomAnchor,
                constant: -8
            ),

            // Slider Container
            sliderContainerView.topAnchor.constraint(
                equalTo: scrollView.topAnchor
            ),

            sliderContainerView.leadingAnchor.constraint(
                equalTo: scrollView.leadingAnchor
            ),

            sliderContainerView.trailingAnchor.constraint(
                equalTo: scrollView.trailingAnchor
            ),

            sliderContainerView.bottomAnchor.constraint(
                equalTo: scrollView.bottomAnchor
            ),

            sliderContainerView.widthAnchor.constraint(
                equalTo: scrollView.widthAnchor
            ),

            // Focus Guide — fills the whole hero area so it is always
            // the first candidate when moving down from the header
            // and the first candidate when moving up from rail 0.
            heroFocusGuide.topAnchor.constraint(
                equalTo: header.bottomAnchor
            ),

            heroFocusGuide.bottomAnchor.constraint(
                equalTo: scrollView.topAnchor
            ),

            heroFocusGuide.leadingAnchor.constraint(
                equalTo: dashboardCard.leadingAnchor
            ),

            heroFocusGuide.trailingAnchor.constraint(
                equalTo: dashboardCard.trailingAnchor
            )
        ])

        // Start pointing downwards (header is focused first).
        updateFocusGuideDestination(for: lastFocusedHeaderView)
    }

    // MARK: - Style Helpers

    /// White pill — currently focused menu item.
    private func applyFocusedStyle(to button: UIButton) {

        button.backgroundColor = .white

        guard var config = button.configuration else {
            return
        }

        config.baseForegroundColor = .black
        button.configuration = config
    }

    /// Subtle pill — active tab while focus is elsewhere.
    private func applySelectedStyle(to button: UIButton) {

        button.backgroundColor =
            UIColor.white.withAlphaComponent(0.22)

        guard var config = button.configuration else {
            return
        }

        config.baseForegroundColor = .white
        button.configuration = config
    }

    private func applyUnselectedStyle(to button: UIButton) {

        button.backgroundColor = .clear

        guard var config = button.configuration else {
            return
        }

        config.baseForegroundColor =
            UIColor(white: 0.75, alpha: 1)

        button.configuration = config
    }

    /// Single place that decides how every top menu button looks.
    private func refreshTopMenuStyles(focused: UIButton?) {

        for case let button as UIButton
        in navigationStack.arrangedSubviews {

            if let focused, button === focused {
                applyFocusedStyle(to: button)
            } else if button.tag == selectedTabIndex {
                applySelectedStyle(to: button)
            } else {
                applyUnselectedStyle(to: button)
            }
        }
    }

    // MARK: - Header Button Factory

    private func makeHeaderButton(
        title: String?,
        image: String
    ) -> UIButton {

        let button = UIButton(type: .system)

        var config = UIButton.Configuration.plain()

        config.title = title
        config.image = UIImage(systemName: image)

        let iconSize: CGFloat =
            title == nil ? 24 : 16

        config.imagePadding =
            title == nil ? 0 : 10

        config.preferredSymbolConfigurationForImage =
            UIImage.SymbolConfiguration(
                pointSize: iconSize,
                weight: .semibold
            )

        if title != nil {

            config.titleTextAttributesTransformer =
                UIConfigurationTextAttributesTransformer {
                    incoming in

                    var outgoing = incoming

                    outgoing.font =
                        .appFont(
                            ofSize: 18,
                            weight: .bold
                        )

                    return outgoing
                }
        }

        config.contentInsets = NSDirectionalEdgeInsets(
            top: 6,
            leading: 8,
            bottom: 6,
            trailing: 8
        )

        button.configuration = config
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }

    // MARK: - ViewModel Binding

    private func bindViewModel() {

        viewModel.onDataUpdated = { [weak self] in

            guard let self else {
                return
            }

            self.setupSliders()

            if self.viewModel.numberOfShows() > 0 {

                let show =
                    self.viewModel.showItem(at: 0)

                self.selectedShow = show

                self.heroHeaderView.updateHeroData(
                    title: show.title,
                    imageName: show.imageName,
                    videoUrl: show.videoUrl,
                    genre: show.genre
                )
            }

            // Fresh data => next entry into the rails starts at cell 0.
            self.lastFocusedIndexPaths.removeAll()

            self.updateFocusGuideDestination(
                for: self.currentlyFocusedView()
            )

            self.restoreHeaderFocusIfNeeded()
        }

        viewModel.onError = { [weak self] message in
            print("Home Error: \(message)")
            self?.dashboardCard.hideLoadingIndicator()
        }

        viewModel.onLoadingChanged = { [weak self] isLoading in
            guard let self = self else { return }

            if isLoading {
                self.dashboardCard.showLoadingIndicator()
            } else {
                self.dashboardCard.hideLoadingIndicator()
            }
        }
    }

    // MARK: - Sliders

    private func setupSliders() {

        sliderContainerView.arrangedSubviews.forEach {
            sliderContainerView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        collectionViews.removeAll()
        railStacks.removeAll()
        railStyles.removeAll()

        activeSliderIndex = nil

        for sliderIndex in 0..<viewModel.numberOfSliders() {

            guard let slider =
                    viewModel.slider(at: sliderIndex)
            else {
                continue
            }

            let style = RailStyle.style(
                for: slider,
                at: sliderIndex
            )

            let sliderStack = UIStackView()

            sliderStack.axis = .vertical
            sliderStack.spacing = Metrics.railSpacing
            sliderStack.alignment = .fill
            sliderStack.translatesAutoresizingMaskIntoConstraints = false

            let titleLabel = UILabel()

            titleLabel.text =
                slider.type ?? "Videos"

            titleLabel.font =
                .appFont(
                    ofSize: 26,
                    weight: .bold
                )

            titleLabel.textColor = .white

            titleLabel.translatesAutoresizingMaskIntoConstraints = false

            sliderStack.addArrangedSubview(titleLabel)

            titleLabel.heightAnchor.constraint(
                equalToConstant: Metrics.railTitleHeight
            ).isActive = true

            let collectionView =
                createCollectionView(
                    tag: sliderIndex,
                    style: style
                )

            sliderStack.addArrangedSubview(collectionView)

            collectionView.heightAnchor.constraint(
                equalToConstant: style.collectionHeight
            ).isActive = true

            sliderContainerView.addArrangedSubview(
                sliderStack
            )

            railStacks.append(sliderStack)
            collectionViews.append(collectionView)
            railStyles.append(style)
        }

        view.layoutIfNeeded()
    }

    private func createCollectionView(
        tag: Int,
        style: RailStyle
    ) -> UICollectionView {

        let layout =
            UICollectionViewFlowLayout()

        layout.scrollDirection = .horizontal

        layout.itemSize = style.itemSize

        layout.minimumLineSpacing = style.itemSpacing

        layout.sectionInset = UIEdgeInsets(
            top: Metrics.sectionVerticalInset,
            left: 8,
            bottom: Metrics.sectionVerticalInset,
            right: 64
        )

        let collectionView =
            UICollectionView(
                frame: .zero,
                collectionViewLayout: layout
            )

        collectionView.backgroundColor = .clear

        collectionView.showsHorizontalScrollIndicator = false

        collectionView.contentInset = .zero

        collectionView.contentInsetAdjustmentBehavior = .never

        collectionView.clipsToBounds = false

        // We decide the landing cell ourselves.
        collectionView.remembersLastFocusedIndexPath = false

        collectionView.tag = tag

        collectionView.dataSource = self
        collectionView.delegate = self

        collectionView.register(
            ShowCell.self,
            forCellWithReuseIdentifier:
                ShowCell.reuseIdentifier
        )

        collectionView.register(
            RankedShowCell.self,
            forCellWithReuseIdentifier:
                RankedShowCell.reuseIdentifier
        )

        collectionView.translatesAutoresizingMaskIntoConstraints =
            false

        return collectionView
    }

    // MARK: - Navigation Action

    @objc
    private func navigationItemSelected(
        _ sender: UIButton
    ) {

        selectedTabIndex = sender.tag
        lastFocusedHeaderView = sender

        refreshTopMenuStyles(focused: sender)

        activeSliderIndex = nil
        lastFocusedIndexPaths.removeAll()

        setHeroCollapsed(false)

        scrollView.setContentOffset(
            .zero,
            animated: true
        )

        viewModel.selectSideMenu(
            at: sender.tag
        )
    }

    // MARK: - Video Player

    private func presentVideoPlayer() {

        guard
            let show = selectedShow,
            let videoUrlString = show.videoUrl,
            let videoUrl = URL(
                string: videoUrlString
            )
        else {
            return
        }

        let player =
            TVPlayerViewController()

        player.play(
            url: videoUrl,
            title: show.title,
            episodeInfo: show.year ?? ""
        )

        present(
            player,
            animated: true
        )
    }

    // MARK: - Focus Management

    override var preferredFocusEnvironments:
        [UIFocusEnvironment] {

        if let target = requestedFocusTarget,
           target.window != nil {

            return [target]
        }

        if let headerView = lastFocusedHeaderView,
           headerView.window != nil {

            return [headerView]
        }

        if let first =
            navigationStack.arrangedSubviews.first {

            return [first]
        }

        return [header]
    }

    /// Flips the hero focus guide so it always points *away* from
    /// where focus currently is.
    ///
    /// - focus in header  -> guide leads DOWN into rail 0
    /// - focus in a rail  -> guide leads UP into the header
    private func updateFocusGuideDestination(
        for focusedView: UIView?
    ) {

        guard let focusedView else {

            heroFocusGuide.preferredFocusEnvironments = []
            return
        }

        if isHeaderView(focusedView) {

            if let firstRail = collectionViews.first,
               firstRail.numberOfItems(inSection: 0) > 0 {

                heroFocusGuide.preferredFocusEnvironments =
                    [firstRail]

            } else {

                heroFocusGuide.preferredFocusEnvironments = []
            }

            return
        }

        if collectionViews.contains(
            where: { focusedView.isDescendant(of: $0) }
        ) {

            let target =
                lastFocusedHeaderView
                ?? topMenuButton(at: selectedTabIndex)
                ?? topMenuButton(at: 0)

            heroFocusGuide.preferredFocusEnvironments =
                target.map { [$0] } ?? []
        }
    }

    private func isHeaderView(_ view: UIView) -> Bool {

        view.isDescendant(of: header)
    }

    /// Runs BEFORE the focus engine commits the change and, crucially,
    /// before UIKit scrolls the scroll view to reveal the new item.
    ///
    /// Resizing the hero here means the scroll view already reports its
    /// final (taller) height when UIKit decides how far to scroll — so
    /// the first rail no longer gets pushed under its own title, and the
    /// scroll offset stays 0 (which is also what lets an UP press leave
    /// the rail instead of being swallowed as a scroll).
    override func shouldUpdateFocus(
        in context: UIFocusUpdateContext
    ) -> Bool {

        guard let next = context.nextFocusedView else {

            return super.shouldUpdateFocus(in: context)
        }

        if collectionViews.contains(
            where: { next.isDescendant(of: $0) }
        ) {

            setHeroCollapsed(true)

        } else if isHeaderView(next) {

            setHeroCollapsed(false)
        }

        return super.shouldUpdateFocus(in: context)
    }

    private func currentlyFocusedView() -> UIView? {

        focusedView ?? lastFocusedHeaderView
    }

    // MARK: - Header Return

    private func restoreHeaderFocusIfNeeded() {

        guard !isHeroCollapsed else {
            return
        }

        let target =
            lastFocusedHeaderView
            ?? topMenuButton(at: selectedTabIndex)
            ?? topMenuButton(at: 0)

        guard let target else {
            return
        }

        DispatchQueue.main.async { [weak self, weak target] in

            guard
                let self,
                let target,
                self.view.window != nil,
                !target.isFocused
            else {
                return
            }

            self.requestFocus(on: target)
        }
    }

    private func topMenuButton(
        at index: Int
    ) -> UIButton? {

        guard
            index >= 0,
            index < navigationStack.arrangedSubviews.count
        else {
            return nil
        }

        return navigationStack.arrangedSubviews[index]
            as? UIButton
    }

    // MARK: - Reliable Focus Request

    private func requestFocus(on target: UIView) {

        requestedFocusTarget = target

        setNeedsFocusUpdate()
        updateFocusIfNeeded()

        // Retry once after the current focus transaction, then
        // ALWAYS clear the target so it can never hijack a later
        // focus update.
        DispatchQueue.main.async { [weak self, weak target] in

            guard let self else {
                return
            }

            if let target,
               !target.isFocused,
               target.window != nil {

                self.requestedFocusTarget = target

                self.setNeedsFocusUpdate()
                self.updateFocusIfNeeded()
            }

            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.30
            ) { [weak self] in

                self?.requestedFocusTarget = nil
            }
        }
    }

    // MARK: - Profile

    @objc
    private func searchTapped() {

        let searchVC = SearchViewController()
        let nav = UINavigationController(rootViewController: searchVC)
        nav.modalPresentationStyle = .overFullScreen
        present(nav, animated: true)
    }

    @objc
    private func profileTapped() {

        if AuthManager.shared.isLoggedIn {

            let settingsVC =
                AccountSettingsViewController()

            settingsVC.modalPresentationStyle =
                .overFullScreen

            present(
                settingsVC,
                animated: true
            )

        } else {

            let loginVC =
                LoginViewController()

            loginVC.modalPresentationStyle =
                .overFullScreen

            loginVC.onLoginSuccess =
                { [weak self] in

                    let settingsVC =
                        AccountSettingsViewController()

                    settingsVC.modalPresentationStyle =
                        .overFullScreen

                    self?.present(
                        settingsVC,
                        animated: true
                    )
                }

            present(
                loginVC,
                animated: true
            )
        }
    }

    // MARK: - Rail Scrolling

    /// Scrolls the vertical scroll view so that the WHOLE rail
    /// (its title + its cards) is visible — the title used to be
    /// clipped away by UIKit's minimal focus scrolling.
    private func revealRail(
        at index: Int,
        animated: Bool
    ) {

        guard
            index >= 0,
            index < railStacks.count
        else {
            return
        }

        let rail = railStacks[index]

        scrollView.layoutIfNeeded()

        let railFrame =
            rail.convert(rail.bounds, to: scrollView)

        // Kept generous so a rail is never flush with the visible edge:
        // a rail resting exactly on the boundary makes UIKit nudge the
        // scroll view on the next focus change.
        let padding: CGFloat = 24

        let maxOffset =
            max(
                0,
                scrollView.contentSize.height
                - scrollView.bounds.height
            )

        var offset = scrollView.contentOffset.y

        if railFrame.minY - padding < offset {

            offset = railFrame.minY - padding

        } else if railFrame.maxY + padding
                    > offset + scrollView.bounds.height {

            offset =
                railFrame.maxY
                + padding
                - scrollView.bounds.height
        }

        offset = min(maxOffset, max(0, offset))

        guard
            abs(offset - scrollView.contentOffset.y) > 0.5
        else {
            return
        }

        scrollView.setContentOffset(
            CGPoint(x: 0, y: offset),
            animated: animated
        )
    }

    private func resetRailScrollPositions() {

        scrollView.setContentOffset(
            .zero,
            animated: true
        )

        for collectionView in collectionViews {

            if collectionView.contentOffset.x != 0 {

                collectionView.setContentOffset(
                    .zero,
                    animated: false
                )
            }
        }
    }

    // MARK: - Focus Update

    override func didUpdateFocus(
        in context: UIFocusUpdateContext,
        with coordinator: UIFocusAnimationCoordinator
    ) {

        super.didUpdateFocus(
            in: context,
            with: coordinator
        )

        guard let next =
                context.nextFocusedView
        else {
            return
        }

        focusedView = next

        // --------------------------------------------------
        // Header Focus
        // --------------------------------------------------

        if isHeaderView(next) {

            lastFocusedHeaderView = next

            if let button = next as? UIButton,
               navigationStack.arrangedSubviews.contains(
                    where: { $0 === button }
               ) {

                refreshTopMenuStyles(focused: button)

            } else {

                refreshTopMenuStyles(focused: nil)
            }

            activeSliderIndex = nil

            // Entering the rails again must always start at cell 0.
            lastFocusedIndexPaths.removeAll()

            setHeroCollapsed(false)
            resetRailScrollPositions()

            updateFocusGuideDestination(for: next)

            return
        }

        // --------------------------------------------------
        // Rail Focus
        // --------------------------------------------------

        guard let railIndex =
                collectionViews.firstIndex(
                    where: { next.isDescendant(of: $0) }
                )
        else {
            return
        }

        let previousRailIndex = activeSliderIndex

        activeSliderIndex = railIndex

        setHeroCollapsed(true)

        updateFocusGuideDestination(for: next)

        // Coming from the header: drop the menu highlight once.
        if previousRailIndex == nil {
            refreshTopMenuStyles(focused: nil)
        }

        // Moving left/right inside the SAME row must never move the page
        // vertically. Re-running the reveal on every horizontal step is
        // what made the top rows jump up and settle back.
        guard previousRailIndex != railIndex else {
            return
        }

        // Run after UIKit's own focus scrolling so ours always wins,
        // and once more after the hero resize animation settles.
        DispatchQueue.main.async { [weak self] in

            self?.revealRail(
                at: railIndex,
                animated: true
            )
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.35
        ) { [weak self] in

            guard
                let self,
                self.activeSliderIndex == railIndex
            else {
                return
            }

            self.revealRail(
                at: railIndex,
                animated: false
            )
        }
    }

    // MARK: - Hero

    /// Titles update instantly so the UI stays responsive, while the
    /// image download / player item swap waits until focus has settled.
    /// Without this, holding a direction on the remote queued one
    /// full-resolution download and one `AVPlayerItem` per step.
    private func updateHero(with item: ShowItem) {

        heroHeaderView.updateHeroText(
            title: item.title,
            genre: item.genre
        )

        heroMediaWorkItem?.cancel()

        let work = DispatchWorkItem { [weak self] in

            guard
                let self,
                let current = self.selectedShow
            else {
                return
            }

            self.heroHeaderView.updateHeroMedia(
                imageName: current.imageName,
                videoUrl: current.videoUrl
            )
        }

        heroMediaWorkItem = work

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.30,
            execute: work
        )
    }

    private func setHeroCollapsed(
        _ collapsed: Bool
    ) {

        guard
            collapsed != isHeroCollapsed
        else {
            return
        }

        isHeroCollapsed = collapsed

        heroHeightConstraint.constant =
            collapsed
            ? collapsedHeroHeight
            : expandedHeroHeight

        UIView.animate(
            withDuration: 0.32,
            delay: 0,
            options: [
                .curveEaseInOut,
                .beginFromCurrentState
            ]
        ) {

            self.view.layoutIfNeeded()
        }
    }
}

// MARK: - UICollectionView

extension ViewController:
    UICollectionViewDataSource,
    UICollectionViewDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {

        guard let slider =
                viewModel.slider(
                    at: collectionView.tag
                )
        else {
            return 0
        }

        if railStyle(for: collectionView) == .ranked {
            return min(
                slider.videos.count,
                RailStyle.maxRankedItems
            )
        }

        return slider.videos.count
    }

    private func railStyle(
        for collectionView: UICollectionView
    ) -> RailStyle {

        let index = collectionView.tag

        guard index < railStyles.count else {
            return .poster
        }

        return railStyles[index]
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {

        let show =
            viewModel.slider(at: collectionView.tag)
                .flatMap {
                    indexPath.item < $0.videos.count
                        ? $0.videos[indexPath.item]
                        : nil
                }

        let playAction: () -> Void = { [weak self] in

            guard let show else {
                return
            }

            self?.selectedShow = show

            self?.presentVideoPlayer()
        }

        if railStyle(for: collectionView) == .ranked {

            let cell =
                collectionView.dequeueReusableCell(
                    withReuseIdentifier:
                        RankedShowCell.reuseIdentifier,
                    for: indexPath
                ) as! RankedShowCell

            if let show {
                cell.configure(
                    with: show,
                    rank: indexPath.item + 1
                )
            }

            cell.onPlayButtonTapped = playAction

            return cell
        }

        let cell =
            collectionView.dequeueReusableCell(
                withReuseIdentifier:
                    ShowCell.reuseIdentifier,
                for: indexPath
            ) as! ShowCell

        if let show {
            cell.configure(
                with: show
            )
        }

        cell.onPlayButtonTapped = playAction

        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {

        guard let slider =
                viewModel.slider(
                    at: collectionView.tag
                ),
              indexPath.item < slider.videos.count
        else {
            return
        }

        let item =
            slider.videos[indexPath.item]

        let detail =
            DetailViewController(
                show: item,
                allShows: viewModel.shows
            )

        if let nav =
            navigationController {

            nav.pushViewController(
                detail,
                animated: true
            )

        } else {

            present(
                detail,
                animated: true
            )
        }
    }

    /// THE fix for "second cell is selected".
    ///
    /// When the focus engine is redirected into a collection view
    /// (by the hero focus guide) it asks the delegate which item it
    /// should land on. Without this it uses geometry — and the
    /// SPOTLIGHT button sits in the middle of the screen, so the
    /// engine picked whichever card happened to be below it.
    func indexPathForPreferredFocusedView(
        in collectionView: UICollectionView
    ) -> IndexPath? {

        guard
            collectionView.numberOfItems(inSection: 0) > 0
        else {
            return nil
        }

        if let remembered =
            lastFocusedIndexPaths[collectionView.tag],
           remembered.item <
            collectionView.numberOfItems(inSection: 0) {

            return remembered
        }

        return IndexPath(item: 0, section: 0)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didUpdateFocusIn context:
            UICollectionViewFocusUpdateContext,
        with coordinator:
            UIFocusAnimationCoordinator
    ) {

        guard
            let indexPath =
                context.nextFocusedIndexPath,
            let slider =
                viewModel.slider(
                    at: collectionView.tag
                ),
            indexPath.item < slider.videos.count
        else {
            return
        }

        activeSliderIndex =
            collectionView.tag

        lastFocusedIndexPaths[collectionView.tag] =
            indexPath

        featuredIndex =
            indexPath.item

        let item =
            slider.videos[indexPath.item]

        selectedShow = item

        updateHero(with: item)
    }
}
