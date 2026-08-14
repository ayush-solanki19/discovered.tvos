import UIKit

class ViewController: UIViewController {

    // MARK: - Properties
    private let sideMenuWidth: CGFloat = 240
    private var isSideMenuOpen = false
    private var sideMenuLeadingConstraint: NSLayoutConstraint!
    private var selectedSideIndex = 1   // Music selected by default
    private var shouldFocusMenuButton = true
    // Side Menu
    private let sideMenuView = UIView()
    private let sideMenuStack = UIStackView()
    private let dimView = UIView()

    // Main
    private let mainContainer = UIView()
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // Top
    private let menuButton = UIButton(type: .system)

    // Hero
    private let heroContainer = UIView()
    private let heroImageView = UIImageView()
    private let heroGradient = CAGradientLayer()
    private let titleLabel = UILabel()
    private let metaLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let badgeStack = UIStackView()

    // Section
    private let sectionTitleLabel = UILabel()
    private var collectionView: UICollectionView!

    // Data
    private let shows = [
        ("THE LEADERSHIP FORUM", "poster1"),
        ("THE FUTURE IS NOW", "poster2"),
        ("THE GUEST INNOVATION & LEADERSHIP", "poster3"),
        ("UNLEASHING CREATIVITY", "poster4"),
        ("THE FUTURE OF INNOVATION SHOW", "poster5")
    ]

    private let sideMenuItems: [(icon: String, title: String)] = [
        ("sparkles", "Spotlight"),
        ("music.note", "Music"),
        ("film", "Movies"),
        ("tv", "Television"),
        ("gamecontroller", "Gaming"),
        ("person", "Login"),
        ("questionmark.circle", "Help"),
        ("doc.text", "Policy")
    ]

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        setupUI()
        setupConstraints()

        // Start closed
        sideMenuLeadingConstraint.constant = -sideMenuWidth
        dimView.alpha = 0
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.bringSubviewToFront(menuButton)
        
        // Initial focus
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        heroGradient.frame = heroImageView.bounds
        view.bringSubviewToFront(menuButton)
    }

    // MARK: - Setup
    private func setupUI() {
        // Dim
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        dimView.alpha = 0
        let tap = UITapGestureRecognizer(target: self, action: #selector(closeSideMenu))
        dimView.addGestureRecognizer(tap)
        view.addSubview(dimView)

        // Side Menu
        sideMenuView.backgroundColor = UIColor(white: 0.09, alpha: 1)
        view.addSubview(sideMenuView)

        sideMenuStack.axis = .vertical
        sideMenuStack.spacing = 10
        sideMenuStack.alignment = .fill
        sideMenuView.addSubview(sideMenuStack)

        for (index, item) in sideMenuItems.enumerated() {
            let btn = createSideButton(icon: item.icon, title: item.title, tag: index)
            sideMenuStack.addArrangedSubview(btn)
        }

        // Main
        mainContainer.backgroundColor = .black
        view.addSubview(mainContainer)

        scrollView.showsVerticalScrollIndicator = false
        mainContainer.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // ====== MENU BUTTON (Hamburger) ======
        menuButton.setImage(UIImage(systemName: "line.horizontal.3", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)), for: .normal)
        menuButton.tintColor = .white
        menuButton.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        menuButton.layer.cornerRadius = 10
        menuButton.addTarget(self, action: #selector(toggleSideMenu), for: .primaryActionTriggered)
        view.addSubview(menuButton)

        // Hero
        heroContainer.clipsToBounds = true
        contentView.addSubview(heroContainer)

        heroImageView.contentMode = .scaleToFill
        heroImageView.clipsToBounds = true
        heroImageView.image = UIImage(named: "hero_back")
        heroContainer.addSubview(heroImageView)

        heroGradient.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.3).cgColor,
            UIColor.black.withAlphaComponent(0.8).cgColor,
            UIColor.black.cgColor
        ]
        heroGradient.locations = [0.0, 0.4, 0.7, 1.0]
        heroImageView.layer.addSublayer(heroGradient)

        titleLabel.text = "The Hunting\nWives"
        titleLabel.numberOfLines = 2
        titleLabel.font = UIFont(name: "Georgia-Italic", size: 42) ?? .italicSystemFont(ofSize: 42)
        titleLabel.textColor = .white
        heroContainer.addSubview(titleLabel)

        metaLabel.text = "Drama  •  2025  •  8 Episodes  •  TV-MA"
        metaLabel.font = .systemFont(ofSize: 13, weight: .medium)
        metaLabel.textColor = UIColor.white.withAlphaComponent(0.85)
        heroContainer.addSubview(metaLabel)

        descriptionLabel.text = "Sophie trades New England for East Texas and falls into a wealthy socialite's magnetic orbit — where a clique of housewives hide deadly secrets."
        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = .systemFont(ofSize: 14)
        descriptionLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        heroContainer.addSubview(descriptionLabel)

        badgeStack.axis = .horizontal
        badgeStack.spacing = 8
        heroContainer.addSubview(badgeStack)

        badgeStack.addArrangedSubview(makeBadge("RECENTLY ADDED", .darkGray))
        badgeStack.addArrangedSubview(makeBadge("TOP 10", .red))
        badgeStack.addArrangedSubview(makeBadge("#3 In TV Shows", .darkGray))

        // Section
        sectionTitleLabel.text = "Critically Acclaimed TV Shows"
        sectionTitleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        sectionTitleLabel.textColor = .white
        contentView.addSubview(sectionTitleLabel)

        // Collection
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 170, height: 240)
        layout.minimumLineSpacing = 14
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ShowCell.self, forCellWithReuseIdentifier: "ShowCell")
        contentView.addSubview(collectionView)
    }

    private func createSideButton(icon: String, title: String, tag: Int) -> UIButton {
        let btn = UIButton(type: .system)

        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        btn.setImage(UIImage(systemName: icon, withConfiguration: config), for: .normal)
        btn.setTitle("  \(title)", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        btn.contentHorizontalAlignment = .left
        btn.contentEdgeInsets = UIEdgeInsets(top: 14, left: 18, bottom: 14, right: 18)
        btn.layer.cornerRadius = 12
        btn.tag = tag
        btn.tintColor = .white
        btn.setTitleColor(.white, for: .normal)
        btn.addTarget(self, action: #selector(sideItemTapped(_:)), for: .primaryActionTriggered)

        // Default style
        btn.backgroundColor = .clear
        btn.layer.borderWidth = 0

        // Selected style
        if tag == selectedSideIndex {
            btn.backgroundColor = UIColor.white.withAlphaComponent(0.18)
            btn.layer.borderWidth = 1.5
            btn.layer.borderColor = UIColor.white.withAlphaComponent(0.6).cgColor
        }

        return btn
    }

    private func makeBadge(_ text: String, _ color: UIColor) -> UIView {
        let v = UIView()
        v.backgroundColor = color.withAlphaComponent(0.85)
        v.layer.cornerRadius = 4

        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 11, weight: .bold)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(l)

        NSLayoutConstraint.activate([
            l.topAnchor.constraint(equalTo: v.topAnchor, constant: 4),
            l.bottomAnchor.constraint(equalTo: v.bottomAnchor, constant: -4),
            l.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 8),
            l.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -8)
        ])
        return v
    }

    // MARK: - Constraints
    private func setupConstraints() {
        [dimView, sideMenuView, sideMenuStack, mainContainer, scrollView, contentView,
         menuButton, heroContainer, heroImageView, titleLabel, metaLabel,
         descriptionLabel, badgeStack, sectionTitleLabel, collectionView
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        sideMenuLeadingConstraint = sideMenuView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -sideMenuWidth)

        NSLayoutConstraint.activate([
            // Dim
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Side Menu
            sideMenuLeadingConstraint,
            sideMenuView.topAnchor.constraint(equalTo: view.topAnchor),
            sideMenuView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sideMenuView.widthAnchor.constraint(equalToConstant: sideMenuWidth),

            sideMenuStack.topAnchor.constraint(equalTo: sideMenuView.safeAreaLayoutGuide.topAnchor, constant: 80),
            sideMenuStack.leadingAnchor.constraint(equalTo: sideMenuView.leadingAnchor, constant: 14),
            sideMenuStack.trailingAnchor.constraint(equalTo: sideMenuView.trailingAnchor, constant: -14),

            // Main
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

            // ===== MENU BUTTON (FORCE VISIBLE) =====
            menuButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            menuButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            menuButton.widthAnchor.constraint(equalToConstant: 44),
            menuButton.heightAnchor.constraint(equalToConstant: 44),

            // Hero
            heroContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            heroContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            heroContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            heroContainer.heightAnchor.constraint(equalToConstant: 540),

            heroImageView.topAnchor.constraint(equalTo: heroContainer.topAnchor),
            heroImageView.leadingAnchor.constraint(equalTo: heroContainer.leadingAnchor),
            heroImageView.trailingAnchor.constraint(equalTo: heroContainer.trailingAnchor),
            heroImageView.bottomAnchor.constraint(equalTo: heroContainer.bottomAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: heroContainer.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: heroContainer.trailingAnchor, constant: -24),
            titleLabel.bottomAnchor.constraint(equalTo: metaLabel.topAnchor, constant: -10),

            metaLabel.leadingAnchor.constraint(equalTo: heroContainer.leadingAnchor, constant: 24),
            metaLabel.bottomAnchor.constraint(equalTo: descriptionLabel.topAnchor, constant: -10),

            descriptionLabel.leadingAnchor.constraint(equalTo: heroContainer.leadingAnchor, constant: 24),
            descriptionLabel.trailingAnchor.constraint(equalTo: heroContainer.trailingAnchor, constant: -24),
            descriptionLabel.bottomAnchor.constraint(equalTo: badgeStack.topAnchor, constant: -14),

            badgeStack.leadingAnchor.constraint(equalTo: heroContainer.leadingAnchor, constant: 24),
            badgeStack.bottomAnchor.constraint(equalTo: heroContainer.bottomAnchor, constant: -30),

            // Section
            sectionTitleLabel.topAnchor.constraint(equalTo: heroContainer.bottomAnchor, constant: 28),
            sectionTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),

            collectionView.topAnchor.constraint(equalTo: sectionTitleLabel.bottomAnchor, constant: 14),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: 260),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }

    // MARK: - Actions
    @objc private func toggleSideMenu() {
        isSideMenuOpen ? closeSideMenu() : openSideMenu()
    }

    private func openSideMenu() {
        isSideMenuOpen = true
        sideMenuLeadingConstraint.constant = 0
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.dimView.alpha = 1
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.setNeedsFocusUpdate()
            self.updateFocusIfNeeded()
        }
        
        view.bringSubviewToFront(sideMenuView)
        view.bringSubviewToFront(menuButton)
    }
    
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        if isSideMenuOpen {
            // Side menu open hone pe pehle side menu ke buttons pe focus do
            return sideMenuStack.arrangedSubviews
        } else if shouldFocusMenuButton {
            return [menuButton]
        } else {
            // Normal case → collection view pe focus
            return [collectionView]
        }
    }

    @objc private func closeSideMenu() {
        isSideMenuOpen = false
        sideMenuLeadingConstraint.constant = -sideMenuWidth
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            self.dimView.alpha = 0
            self.view.layoutIfNeeded()
        }) { _ in
            // Focus wapas menu button pe laao
            self.setNeedsFocusUpdate()
            self.updateFocusIfNeeded()
        }
    }

    @objc private func sideItemTapped(_ sender: UIButton) {
        // Remove previous selection
        for case let btn as UIButton in sideMenuStack.arrangedSubviews {
            btn.backgroundColor = .clear
            btn.layer.borderWidth = 0
        }

        // Apply selection
        sender.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        sender.layer.borderWidth = 1.5
        sender.layer.borderColor = UIColor.white.withAlphaComponent(0.7).cgColor

        selectedSideIndex = sender.tag

        // Dismiss + Focus restore
        closeSideMenu()
    }
}

// MARK: - CollectionView
extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        shows.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ShowCell", for: indexPath) as! ShowCell
        cell.configure(title: shows[indexPath.item].0, imageName: shows[indexPath.item].1)
        return cell
    }
}

// MARK: - Cell
class ShowCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 10
        contentView.clipsToBounds = true
        contentView.backgroundColor = UIColor(white: 0.12, alpha: 1)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)

        titleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.78),

            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, imageName: String) {
        titleLabel.text = title
        imageView.image = UIImage(named: imageName) ?? UIImage(named: "hero_back")
    }
}


// MARK: - Focus Handling for CollectionView
extension ViewController {
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        
        // Agar focus collection view pe chala gaya to flag update karo
        if let next = context.nextFocusedView, next.isDescendant(of: collectionView) {
            shouldFocusMenuButton = false
        }
        
        // Agar focus menu button pe aa gaya
        if context.nextFocusedView == menuButton {
            shouldFocusMenuButton = true
        }
    }
}
