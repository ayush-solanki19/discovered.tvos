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

    private let sliderContainerView = UIStackView()
    private var collectionViews: [UICollectionView] = []

    private var featuredIndex = 0
    private var selectedShow: ShowItem?

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

        // MARK: - Dashboard

        dashboardCard.backgroundColor = UIColor(
            red: 0.045,
            green: 0.055,
            blue: 0.075,
            alpha: 1
        )

        dashboardCard.layer.cornerRadius = 8
        dashboardCard.layer.borderWidth = 3
        dashboardCard.layer.borderColor = UIColor.white
            .withAlphaComponent(0.78)
            .cgColor

        dashboardCard.clipsToBounds = true
        dashboardCard.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(dashboardCard)


        // MARK: - Header

        header.translatesAutoresizingMaskIntoConstraints = false

        dashboardCard.addSubview(header)


        // MARK: - Brand Icon

        brandMark.image = UIImage(named: "logo_dark")
        brandMark.tintColor = .white

        brandMark.backgroundColor = .clear

        brandMark.contentMode = .scaleAspectFit

        brandMark.layer.cornerRadius = 0
        brandMark.clipsToBounds = true

        brandMark.translatesAutoresizingMaskIntoConstraints = false

        header.addSubview(brandMark)


        // MARK: - Brand Label

        brandLabel.text = "DiscoveredTV"

        brandLabel.font = .systemFont(
            ofSize: 24,
            weight: .bold
        )

        brandLabel.textColor = UIColor(
            white: 0.91,
            alpha: 1
        )

        brandLabel.translatesAutoresizingMaskIntoConstraints = false

        header.addSubview(brandLabel)


        // MARK: - Navigation Stack

        navigationStack.axis = .horizontal

        // Reduced spacing between top menu items
        navigationStack.spacing = 14

        navigationStack.alignment = .center
        navigationStack.translatesAutoresizingMaskIntoConstraints = false

        header.addSubview(navigationStack)


        // MARK: - Top Navigation

        [
            "SPOTLIGHT",
            "MUSIC",
            "MOVIES",
            "TELEVISION"
        ]
        .enumerated()
        .forEach { index, title in

            let button = UIButton(type: .system)

            var config = UIButton.Configuration.plain()

            config.title = title

            config.image = nil

            // Smaller gap between icon and title
            config.imagePadding = 5

            // Compact menu padding
            config.contentInsets = NSDirectionalEdgeInsets(
                top: 5,
                leading: 5,
                bottom: 5,
                trailing: 5
            )

            // Proper font configuration for UIButton.Configuration
            var titleAttributes = AttributeContainer()

            titleAttributes.font = .systemFont(
                ofSize: 15,
                weight: .semibold
            )

            config.attributedTitle = AttributedString(
                title,
                attributes: titleAttributes
            )

            button.configuration = config

            button.tintColor = UIColor(
                white: 0.8,
                alpha: 1
            )

            button.tag = index

            button.addTarget(
                self,
                action: #selector(navigationItemSelected(_:)),
                for: .primaryActionTriggered
            )

            // Selected menu item
            if index == 0 {

                button.configuration?.baseBackgroundColor = UIColor(
                    red: 0.36,
                    green: 0.34,
                    blue: 0.96,
                    alpha: 1
                )

                button.configuration?.baseForegroundColor = .white

                button.layer.cornerRadius = 14
                button.clipsToBounds = true
            }

            navigationStack.addArrangedSubview(button)
        }


        // MARK: - Search & Profile

        let searchButton = makeHeaderButton(
            title: "SEARCH",
            image: "magnifyingglass"
        )

        let profileButton = makeHeaderButton(
            title: nil,
            image: "person.crop.circle"
        )

        header.addSubview(searchButton)
        header.addSubview(profileButton)
        header.bringSubviewToFront(searchButton)


        // MARK: - Hero

        heroHeaderView.translatesAutoresizingMaskIntoConstraints = false

        heroHeaderView.layer.borderWidth = 4

        heroHeaderView.layer.borderColor = UIColor.white.cgColor

        dashboardCard.addSubview(heroHeaderView)


        // MARK: - Play Button

        // configureActionButton(
        //     playButton,
        //     title: "Play",
        //     image: "play.fill",
        //     background: UIColor(
        //         red: 0.74,
        //         green: 0.73,
        //         blue: 1,
        //         alpha: 1
        //     ),
        //     foreground: UIColor(
        //         red: 0.05,
        //         green: 0.05,
        //         blue: 0.24,
        //         alpha: 1
        //     )
        // )

        // playButton.addTarget(
        //     self,
        //     action: #selector(playButtonDidTap),
        //     for: .primaryActionTriggered
        // )

        // dashboardCard.addSubview(playButton)


        // MARK: - Details Button

        // configureActionButton(
        //     moreInfoButton,
        //     title: "Details",
        //     image: "info.circle.fill",
        //     background: UIColor(
        //         red: 0.20,
        //         green: 0.21,
        //         blue: 0.25,
        //         alpha: 1
        //     ),
        //     foreground: .white
        // )

        // moreInfoButton.addTarget(
        //     self,
        //     action: #selector(detailsButtonDidTap),
        //     for: .primaryActionTriggered
        // )

        // dashboardCard.addSubview(moreInfoButton)


        // MARK: - Slider Container

        sliderContainerView.axis = .vertical
        sliderContainerView.spacing = 24
        sliderContainerView.distribution = .fill
        sliderContainerView.alignment = .fill
        sliderContainerView.translatesAutoresizingMaskIntoConstraints = false

        dashboardCard.addSubview(sliderContainerView)


        // MARK: - Hero Height

        heroHeightConstraint = heroHeaderView.heightAnchor.constraint(
            equalToConstant: 832
        )


        // MARK: - Layout

        NSLayoutConstraint.activate([

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


            // MARK: Header

            header.topAnchor.constraint(
                equalTo: dashboardCard.topAnchor,
                constant: 18
            ),

            header.leadingAnchor.constraint(
                equalTo: dashboardCard.leadingAnchor,
                constant: 64
            ),

            header.trailingAnchor.constraint(
                equalTo: dashboardCard.trailingAnchor,
                constant: -64
            ),

            // Reduced header height
            header.heightAnchor.constraint(
                equalToConstant: 44
            ),


            // MARK: Brand

            brandMark.leadingAnchor.constraint(
                equalTo: header.leadingAnchor
            ),

            brandMark.centerYAnchor.constraint(
                equalTo: header.centerYAnchor
            ),

            // Smaller brand icon
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


            // MARK: Search

            searchButton.leadingAnchor.constraint(
                equalTo: brandLabel.trailingAnchor,
                constant: 24
            ),

            searchButton.centerYAnchor.constraint(
                equalTo: header.centerYAnchor
            ),


            // MARK: Navigation

            navigationStack.centerXAnchor.constraint(
                equalTo: header.centerXAnchor
            ),

            navigationStack.centerYAnchor.constraint(
                equalTo: header.centerYAnchor
            ),


            // MARK: Profile

            profileButton.trailingAnchor.constraint(
                equalTo: header.trailingAnchor
            ),

            profileButton.centerYAnchor.constraint(
                equalTo: header.centerYAnchor
            ),

            profileButton.widthAnchor.constraint(
                equalToConstant: 34
            ),


            // MARK: Hero

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


            // MARK: Hero Actions

            // playButton.leadingAnchor.constraint(
            //     equalTo: heroHeaderView.leadingAnchor,
            //     constant: 48
            // ),

            // playButton.bottomAnchor.constraint(
            //     equalTo: heroHeaderView.bottomAnchor,
            //     constant: -36
            // ),

            // playButton.heightAnchor.constraint(
            //     equalToConstant: 48
            // ),


            // moreInfoButton.leadingAnchor.constraint(
            //     equalTo: playButton.trailingAnchor,
            //     constant: 12
            // ),

            // moreInfoButton.centerYAnchor.constraint(
            //     equalTo: playButton.centerYAnchor
            // ),

            // moreInfoButton.heightAnchor.constraint(
            //     equalToConstant: 48
            // ),


            // MARK: Slider Container

            sliderContainerView.topAnchor.constraint(
                equalTo: heroHeaderView.bottomAnchor,
                constant: 24
            ),

            sliderContainerView.leadingAnchor.constraint(
                equalTo: heroHeaderView.leadingAnchor
            ),

            sliderContainerView.trailingAnchor.constraint(
                equalTo: heroHeaderView.trailingAnchor
            ),

            sliderContainerView.bottomAnchor.constraint(
                equalTo: dashboardCard.bottomAnchor,
                constant: -8
            )
        ])


        // MARK: - Focus Guides

        dashboardCard.addLayoutGuide(menuToPlayFocusGuide)
        dashboardCard.addLayoutGuide(playToRailFocusGuide)
        dashboardCard.addLayoutGuide(railToPlayFocusGuide)

        NSLayoutConstraint.activate([
            menuToPlayFocusGuide.topAnchor.constraint(
                equalTo: header.bottomAnchor
            ),
            menuToPlayFocusGuide.bottomAnchor.constraint(
                equalTo: heroHeaderView.topAnchor
            ),
            menuToPlayFocusGuide.leadingAnchor.constraint(
                equalTo: heroHeaderView.leadingAnchor
            ),
            menuToPlayFocusGuide.widthAnchor.constraint(
                equalTo: heroHeaderView.widthAnchor
            ),

            playToRailFocusGuide.topAnchor.constraint(
                equalTo: heroHeaderView.bottomAnchor
            ),
            playToRailFocusGuide.bottomAnchor.constraint(
                equalTo: sliderContainerView.topAnchor
            ),
            playToRailFocusGuide.leadingAnchor.constraint(
                equalTo: heroHeaderView.leadingAnchor
            ),
            playToRailFocusGuide.trailingAnchor.constraint(
                equalTo: heroHeaderView.trailingAnchor
            ),

            railToPlayFocusGuide.topAnchor.constraint(
                equalTo: sliderContainerView.topAnchor
            ),
            railToPlayFocusGuide.bottomAnchor.constraint(
                equalTo: sliderContainerView.bottomAnchor
            ),
            railToPlayFocusGuide.leadingAnchor.constraint(
                equalTo: heroHeaderView.leadingAnchor
            ),
            railToPlayFocusGuide.trailingAnchor.constraint(
                equalTo: heroHeaderView.trailingAnchor
            )
        ])

        menuToPlayFocusGuide.preferredFocusEnvironments = []
        playToRailFocusGuide.preferredFocusEnvironments = []
        playToRailFocusGuide.isEnabled = false
        railToPlayFocusGuide.preferredFocusEnvironments = [
            navigationStack.arrangedSubviews.first ?? header
        ]
    }


    // MARK: - Header Button

    private func makeHeaderButton(
        title: String?,
        image: String
    ) -> UIButton {

        let button = UIButton(type: .system)

        var config = UIButton.Configuration.plain()

        config.title = title
        config.image = UIImage(systemName: image)

        config.imagePadding = title == nil ? 0 : 4

        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(
            pointSize: title == nil ? 16 : 10,
            weight: .semibold
        )

        if title != nil {
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
                var updatedAttributes = attributes
                updatedAttributes.font = .systemFont(ofSize: 18, weight: .bold)
                return updatedAttributes
            }
        }

        config.contentInsets = NSDirectionalEdgeInsets(
            top: 4,
            leading: 4,
            bottom: 4,
            trailing: 4
        )

        button.configuration = config

        button.tintColor = UIColor(
            white: 1,
            alpha: 1
        )

        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }


    // MARK: - Action Button

    private func configureActionButton(
        _ button: UIButton,
        title: String,
        image: String,
        background: UIColor,
        foreground: UIColor
    ) {

        var config = UIButton.Configuration.filled()

        config.title = title

        // config.image = UIImage(
        //     systemName: image
        // )

        config.imagePadding = 12

        config.baseBackgroundColor = background
        config.baseForegroundColor = foreground

        config.cornerStyle = .fixed

        config.contentInsets = NSDirectionalEdgeInsets(
            top: 36,
            leading: 48,
            bottom: 36,
            trailing: 48
        )

        button.configuration = config

        button.titleLabel?.font = .systemFont(
            ofSize: 12,
            weight: .bold
        )

        button.layer.cornerRadius = 8

        button.clipsToBounds = true

        button.layer.borderWidth = 1

        button.layer.borderColor = UIColor.white
            .withAlphaComponent(0.34)
            .cgColor

        button.translatesAutoresizingMaskIntoConstraints = false
    }


    // MARK: - Bind ViewModel

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

    private func setupSliders() {
        sliderContainerView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        collectionViews.removeAll()

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

            let collectionView = createCollectionView(
                tag: sliderIndex,
                itemCount: slider.videos.count
            )

            sliderStack.addArrangedSubview(collectionView)

            NSLayoutConstraint.activate([
                collectionView.heightAnchor.constraint(equalToConstant: 230)
            ])

            sliderContainerView.addArrangedSubview(sliderStack)
            collectionViews.append(collectionView)
        }
    }

    private func createCollectionView(tag: Int, itemCount: Int) -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 120, height: 213)
        layout.minimumLineSpacing = 18

        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
        )

        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 64)
        collectionView.tag = tag
        collectionView.dataSource = self
        collectionView.delegate = self

        collectionView.register(
            ShowCell.self,
            forCellWithReuseIdentifier: ShowCell.reuseIdentifier
        )

        collectionView.translatesAutoresizingMaskIntoConstraints = false

        return collectionView
    }


    // MARK: - Navigation

    @objc
    private func navigationItemSelected(
        _ sender: UIButton
    ) {
        viewModel.selectSideMenu(at: sender.tag)
    }


    // MARK: - Actions

    @objc
    private func playButtonDidTap() {
        presentVideoPlayer()
    }


    @objc
    private func detailsButtonDidTap() {

        guard viewModel.numberOfShows() > featuredIndex else {
            return
        }

        let item = viewModel.showItem(
            at: featuredIndex
        )

        let detail = DetailViewController(
            show: item,
            allShows: viewModel.shows
        )

        if let nav = navigationController {

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


    // MARK: - Video Player

    private func presentVideoPlayer() {

        guard let show = selectedShow,
              let videoUrlString = show.videoUrl,
              let videoUrl = URL(string: videoUrlString) else {
            return
        }

        let player = TVPlayerViewController()

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


    // MARK: - Focus

    override var preferredFocusEnvironments: [UIFocusEnvironment] {

        if let requestedFocusTarget {
            return [requestedFocusTarget]
        }

        return [navigationStack.arrangedSubviews.first ?? header]
    }


    override func pressesBegan(
        _ presses: Set<UIPress>,
        with event: UIPressesEvent?
    ) {
        let isDown = presses.contains { $0.type == .downArrow }
        let isUp = presses.contains { $0.type == .upArrow }

        let isTopMenuFocused = navigationStack.arrangedSubviews.contains { $0.isFocused }

        if isDown && isTopMenuFocused {
            lastTopMenuButton = navigationStack.arrangedSubviews.first(where: { $0.isFocused }) as? UIButton
            setHeroCollapsed(true)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
                if let firstCollectionView = self.collectionViews.first {
                    self.requestFocus(firstCollectionView)
                }
            }
            return
        }

        let isAnyCollectionViewFocused = collectionViews.contains {
            $0.visibleCells.contains { $0.isFocused }
        }

        if isUp && isAnyCollectionViewFocused {
            setHeroCollapsed(false)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
                self.requestFocus(
                    self.lastTopMenuButton ?? self.navigationStack.arrangedSubviews.first!
                )
            }
            return
        }

        super.pressesBegan(presses, with: event)
    }


    private func requestFocus(
        _ target: UIFocusEnvironment
    ) {

        requestedFocusTarget = target

        setNeedsFocusUpdate()

        updateFocusIfNeeded()

        DispatchQueue.main.async {
            self.requestedFocusTarget = nil
        }
    }


    override func didUpdateFocus(
        in context: UIFocusUpdateContext,
        with coordinator: UIFocusAnimationCoordinator
    ) {
        super.didUpdateFocus(in: context, with: coordinator)

        guard let next = context.nextFocusedView else { return }

        let isFocusedInSlider = collectionViews.contains { next.isDescendant(of: $0) }

        if isFocusedInSlider {
            setHeroCollapsed(true)
        } else {
            setHeroCollapsed(false)
        }
    }


    // MARK: - Hero Collapse

    private func setHeroCollapsed(
        _ collapsed: Bool
    ) {

        guard collapsed != isHeroCollapsed else {
            return
        }

        isHeroCollapsed = collapsed

        heroHeightConstraint.constant =
            collapsed ? 666 : 832

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


// MARK: - CollectionView

extension ViewController:
    UICollectionViewDataSource,
    UICollectionViewDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        guard let slider = viewModel.slider(at: collectionView.tag) else { return 0 }
        return slider.videos.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ShowCell.reuseIdentifier,
            for: indexPath
        ) as! ShowCell

        guard let slider = viewModel.slider(at: collectionView.tag) else {
            return cell
        }

        let show = slider.videos[indexPath.item]
        cell.configure(with: show)

        cell.onPlayButtonTapped = { [weak self] in
            self?.selectedShow = show
            self?.presentVideoPlayer()
        }

        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard let slider = viewModel.slider(at: collectionView.tag) else { return }

        let item = slider.videos[indexPath.item]

        let detail = DetailViewController(
            show: item,
            allShows: viewModel.shows
        )

        if let nav = navigationController {
            nav.pushViewController(detail, animated: true)
        } else {
            present(detail, animated: true)
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didUpdateFocusIn context: UICollectionViewFocusUpdateContext,
        with coordinator: UIFocusAnimationCoordinator
    ) {
        if let indexPath = context.nextFocusedIndexPath {
            guard let slider = viewModel.slider(at: collectionView.tag) else { return }

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
}
