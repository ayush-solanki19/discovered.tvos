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
    private let logoImageView = UIImageView()
    private let sideMenuStack = UIStackView()

    private let mainContainer = UIView()
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let menuButton = CustomHamburgerButton()
    private let heroHeaderView = HeroHeaderView()
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

        // Initial load par 0th index ka data Hero Card me set karein
        if viewModel.numberOfShows() > 0 {
            let firstShow = viewModel.showItem(at: 0)
            self.heroHeaderView.updateHeroData(title: firstShow.title, imageName: firstShow.imageName)
        }

        // Focus trigger karein
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
    }

    // MARK: - ViewModel Binding
    private func bindViewModel() {
        heroHeaderView.configure(with: viewModel.heroData)

        // Side menu select hone par
        viewModel.onSideMenuSelectionChanged = { [weak self] selectedIndex in
            guard let self = self else { return }
            let selectedCategory = self.viewModel.sideMenuItems[selectedIndex].title
            self.sectionTitleLabel.text = "\(selectedCategory) Videos"
            self.closeSideMenu()
        }

        // API Response aane par Collection View reload
        viewModel.onDataUpdated = { [weak self] in
            guard let self = self else { return }
            self.collectionView.reloadData()
            
            // Pehle item ka banner upar show karein
            if self.viewModel.numberOfShows() > 0 {
                let firstItem = self.viewModel.showItem(at: 0)
                self.heroHeaderView.updateHeroData(title: firstItem.title, imageName: firstItem.imageName)
            }
        }

        viewModel.onError = { errorMessage in
            print("API Error: \(errorMessage)")
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

        // Side Menu setup
        sideMenuView.backgroundColor = UIColor(white: 0.06, alpha: 1.0)
        view.addSubview(sideMenuView)

        logoImageView.image = UIImage(named: "Logo Dark")
        logoImageView.contentMode = .scaleAspectFit
        sideMenuView.addSubview(logoImageView)

        sideMenuStack.axis = .vertical
        sideMenuStack.spacing = 8
        sideMenuStack.alignment = .fill
        sideMenuView.addSubview(sideMenuStack)

        for item in viewModel.sideMenuItems {
            let btn = SideMenuCapsuleButton()
            btn.configure(with: item)
            btn.addTarget(self, action: #selector(sideItemTapped(_:)), for: .primaryActionTriggered)
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.heightAnchor.constraint(equalToConstant: 48).isActive = true
            
            // Login button (id == 5) se theek pehle extra 35pt space
            if item.id == 5 {
                sideMenuStack.setCustomSpacing(35, after: sideMenuStack.arrangedSubviews.last!)
            }
            
            sideMenuStack.addArrangedSubview(btn)
        }
    }

    // MARK: - Constraints
    private func setupConstraints() {
        [mainContainer, scrollView, contentView,
         heroHeaderView, sectionTitleLabel, collectionView,
         menuButton, dimView, sideMenuView, logoImageView, sideMenuStack
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        sideMenuLeadingConstraint = sideMenuView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -sideMenuWidth)
        
        NSLayoutConstraint.activate([
            // Main & Scroll
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

            // Top Menu Button
            menuButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            menuButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            menuButton.widthAnchor.constraint(equalToConstant: 48),
            menuButton.heightAnchor.constraint(equalToConstant: 48),

            // Hero Header
            heroHeaderView.topAnchor.constraint(equalTo: contentView.topAnchor),
            heroHeaderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            heroHeaderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            heroHeaderView.heightAnchor.constraint(equalToConstant: 680),

            // Section Label & Collection View
            sectionTitleLabel.topAnchor.constraint(equalTo: heroHeaderView.bottomAnchor, constant: 28),
            sectionTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),

            collectionView.topAnchor.constraint(equalTo: sectionTitleLabel.bottomAnchor, constant: 14),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: 270),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),

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

            // Logo Constraints (Top safe area se 30pt niche)
            logoImageView.topAnchor.constraint(equalTo: sideMenuView.safeAreaLayoutGuide.topAnchor, constant: 35),
            logoImageView.centerXAnchor.constraint(equalTo: sideMenuView.centerXAnchor), // Centre me lane ke liye
            logoImageView.widthAnchor.constraint(equalToConstant: 200),
            logoImageView.heightAnchor.constraint(equalToConstant: 60),
            
            // Side Menu Stack (Logo ke theek 50pt niche)
            sideMenuStack.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 50),
            sideMenuStack.leadingAnchor.constraint(equalTo: sideMenuView.leadingAnchor, constant: 16),
            sideMenuStack.trailingAnchor.constraint(equalTo: sideMenuView.trailingAnchor, constant: -16)
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

    private func refreshSideMenuAppearance() {
        for case let btn as SideMenuCapsuleButton in sideMenuStack.arrangedSubviews {
            btn.isItemSelected = (btn.tag == viewModel.selectedSideMenuIndex)
        }
    }

    // openSideMenu() me isko call karein:
    private func openSideMenu() {
        viewModel.isSideMenuOpen = true
        sideMenuLeadingConstraint.constant = 0
        refreshSideMenuAppearance()

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

    // MARK: - Preferred Focus
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        if viewModel.isSideMenuOpen {
            // Menu khulte hi jo selected index hai usi button par focus jayega
            if let targetButton = sideMenuStack.arrangedSubviews.first(where: { ($0 as? UIButton)?.tag == viewModel.selectedSideMenuIndex }) {
                return [targetButton]
            }
            return sideMenuStack.arrangedSubviews
        }
        return [collectionView]
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

    // 1. FOCUS CHANGE HONE PAR (Remote navigation par upar card change hoga)
    func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if let nextIndexPath = context.nextFocusedIndexPath {
            let selectedShow = viewModel.showItem(at: nextIndexPath.item)
            // Upar Hero Card ka title aur image change karein
            self.heroHeaderView.updateHeroData(title: selectedShow.title, imageName: selectedShow.imageName)
        }
    }

    // 2. CLICK / SELECT HONE PAR
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedShow = viewModel.showItem(at: indexPath.item)
        
        // Upar card update karein
        self.heroHeaderView.updateHeroData(title: selectedShow.title, imageName: selectedShow.imageName)
        
        // Detail screen par jana ho:
        let detailVC = DetailViewController(show: selectedShow)
        if let nav = navigationController {
            nav.pushViewController(detailVC, animated: true)
        } else {
            detailVC.modalPresentationStyle = .fullScreen
            present(detailVC, animated: true)
        }
    }
}

extension ViewController {
    func indexPathForPreferredFocusedView(in collectionView: UICollectionView) -> IndexPath? {
        // Hamesha pehle item (Index: 0) par focus rakhega
        return IndexPath(item: 0, section: 0)
    }
}
						
