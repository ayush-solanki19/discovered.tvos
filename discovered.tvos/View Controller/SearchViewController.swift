import UIKit

final class SearchViewController: UIViewController {

    // MARK: - UI

    private let searchBar = UISearchBar()
    private let backButton = FocusableBackButton(type: .custom)
    private let keyboardContainer = UIView()
    private let emptyLabel = UILabel()
    private let popularCollectionView: UICollectionView
    private let topFocusGuide = UIFocusGuide()

    private let viewModel = SearchViewModel()

    private var currentSearchText = ""

    private weak var requestedFocusTarget: UIView?
    private weak var firstKeyView: UIView?

    private let keyboardRows: [[String]] = [
        ["a", "b", "c", "d", "e", "f"],
        ["g", "h", "i", "j", "k", "l"],
        ["m", "n", "o", "p", "q", "r"],
        ["s", "t", "u", "v", "w", "x"],
        ["y", "z", "0", "1", "2", "3"],
        ["4", "5", "6", "7", "8", "9"]
    ]

    // MARK: - Init

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {

        let layout = UICollectionViewFlowLayout()

        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 28
        layout.minimumInteritemSpacing = 24
        layout.sectionInset = UIEdgeInsets(
            top: 15,
            left: 0,
            bottom: 50,
            right: 0
        )

        popularCollectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
        )

        super.init(
            nibName: nibNameOrNil,
            bundle: nibBundleOrNil
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        navigationController?.setNavigationBarHidden(true, animated: false)

        setupUI()
        bindViewModel()

        viewModel.search(query: "")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        DispatchQueue.main.async { [weak self] in
            self?.setNeedsFocusUpdate()
            self?.updateFocusIfNeeded()
        }
    }

    override var preferredFocusEnvironments: [UIFocusEnvironment] {

        if let target = requestedFocusTarget,
           target.window != nil {
            return [target]
        }

        if let firstKey = firstKeyView,
           firstKey.window != nil {
            return [firstKey]
        }

        return [backButton]
    }

    // MARK: - Setup UI

    private func setupUI() {

        // MARK: Back Button
        var backConfig = UIButton.Configuration.plain()
        backConfig.image = UIImage(
            systemName: "chevron.left",
            withConfiguration: UIImage.SymbolConfiguration(
                pointSize: 18,
                weight: .semibold
            )
        )
        backConfig.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(
            pointSize: 18,
            weight: .semibold
        )
        backConfig.baseForegroundColor = .white
        backConfig.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)

        backButton.configuration = backConfig
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        backButton.layer.cornerRadius = 20
        backButton.layer.borderWidth = 1
        backButton.layer.borderColor = UIColor(white: 1.0, alpha: 0.12).cgColor
        backButton.contentHorizontalAlignment = .center
        backButton.contentVerticalAlignment = .center
        backButton.adjustsImageWhenHighlighted = false
        backButton.addTarget(self, action: #selector(didTapBack), for: .primaryActionTriggered)

        backButton.onFocusChanged = { [weak self] focused in
            guard let self = self else { return }
            UIView.animate(withDuration: 0.12) {
                self.backButton.transform = focused ? CGAffineTransform(scaleX: 1.08, y: 1.08) : .identity
                self.backButton.backgroundColor = focused ? UIColor(white: 0.9, alpha: 1.0) : UIColor(white: 0.15, alpha: 1.0)
                self.backButton.configuration?.baseForegroundColor = focused ? .black : .white
            }

            // When the back button is focused, the gap guide should hand
            // "down" presses into the keyboard. Otherwise it should hand
            // "up" presses back to the back button. Toggling this on every
            // focus change avoids the guide bouncing focus back on itself.
            if focused {
                self.topFocusGuide.preferredFocusEnvironments = [self.firstKeyView ?? self.keyboardContainer]
            } else {
                self.topFocusGuide.preferredFocusEnvironments = [self.backButton]
            }
        }

        view.addSubview(backButton)

        // MARK: Search Bar

        searchBar.placeholder = "Search for TV shows, movies, actor"
        searchBar.searchBarStyle = .minimal
        searchBar.barTintColor = .clear
        searchBar.backgroundImage = UIImage()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.isUserInteractionEnabled = false
        searchBar.layer.cornerRadius = 18
        searchBar.layer.masksToBounds = true
        searchBar.backgroundColor = UIColor(white: 0.14, alpha: 1.0)

        if let textField = searchBar.value(
            forKey: "searchField"
        ) as? UITextField {

            textField.backgroundColor = UIColor(white: 0.14, alpha: 1.0)
            textField.layer.cornerRadius = 18
            textField.layer.masksToBounds = true
            textField.textColor = .white
            textField.font = .systemFont(ofSize: 26)

            textField.attributedPlaceholder = NSAttributedString(
                string: "Search for TV shows, movies, actor",
                attributes: [
                    .foregroundColor: UIColor.lightGray,
                    .font: UIFont.systemFont(ofSize: 24)
                ]
            )

            textField.leftView = nil
            textField.leftViewMode = .never
            textField.setNeedsLayout()
        }

        view.addSubview(searchBar)

        // MARK: Keyboard Container

        keyboardContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(keyboardContainer)

        // MARK: Top Focus Guide
        // Fills the empty gap between the search bar and the keyboard so
        // focus can jump between the back button and the keyboard's top
        // row. It never overlaps an actual key, so it can't hijack presses
        // meant for real keyboard buttons.

        view.addLayoutGuide(topFocusGuide)
        topFocusGuide.preferredFocusEnvironments = [backButton]

        NSLayoutConstraint.activate([
            topFocusGuide.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            topFocusGuide.bottomAnchor.constraint(equalTo: keyboardContainer.topAnchor),
            topFocusGuide.leadingAnchor.constraint(equalTo: keyboardContainer.leadingAnchor),
            topFocusGuide.trailingAnchor.constraint(equalTo: keyboardContainer.trailingAnchor)
        ])

        buildKeyboard()

        // MARK: Empty Label

        emptyLabel.text = "No Results Found"
        emptyLabel.textColor = .lightGray
        emptyLabel.font = .systemFont(
            ofSize: 24,
            weight: .medium
        )
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(emptyLabel)

        // MARK: Collection View

        popularCollectionView.backgroundColor = .clear
        popularCollectionView.dataSource = self
        popularCollectionView.delegate = self

        popularCollectionView.register(
            PopularCell.self,
            forCellWithReuseIdentifier: "PopularCell"
        )

        popularCollectionView.translatesAutoresizingMaskIntoConstraints = false

        popularCollectionView.remembersLastFocusedIndexPath = true
        popularCollectionView.showsVerticalScrollIndicator = false

        view.addSubview(popularCollectionView)

        // MARK: Constraints

        NSLayoutConstraint.activate([

            backButton.topAnchor.constraint(
                equalTo: view.topAnchor,
                constant: 50
            ),

            backButton.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 60
            ),

            backButton.widthAnchor.constraint(
                equalToConstant: 40
            ),

            backButton.heightAnchor.constraint(
                equalToConstant: 40
            ),

            // Search Bar
            searchBar.topAnchor.constraint(
                equalTo: backButton.bottomAnchor,
                constant: 12
            ),

            searchBar.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 60
            ),

            searchBar.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -60
            ),

            searchBar.heightAnchor.constraint(
                equalToConstant: 50
            ),

            // Keyboard
            keyboardContainer.topAnchor.constraint(
                equalTo: searchBar.bottomAnchor,
                constant: 50
            ),

            keyboardContainer.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 50
            ),

            keyboardContainer.widthAnchor.constraint(
                equalToConstant: 420
            ),

            keyboardContainer.bottomAnchor.constraint(
                equalTo: view.bottomAnchor,
                constant: -40
            ),

            // Collection
            popularCollectionView.topAnchor.constraint(
                equalTo: searchBar.bottomAnchor,
                constant: 24
            ),

            popularCollectionView.leadingAnchor.constraint(
                equalTo: keyboardContainer.trailingAnchor,
                constant: 40
            ),

            popularCollectionView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -50
            ),

            popularCollectionView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor,
                constant: -30
            ),

            // Empty State
            emptyLabel.centerXAnchor.constraint(
                equalTo: popularCollectionView.centerXAnchor
            ),

            emptyLabel.centerYAnchor.constraint(
                equalTo: popularCollectionView.centerYAnchor
            )
        ])
    }

    @objc private func didTapBack() {
        dismiss(animated: true)
    }

    // MARK: - Keyboard

    private func buildKeyboard() {

        keyboardContainer.subviews.forEach {
            $0.removeFromSuperview()
        }

        let mainStack = UIStackView()

        mainStack.axis = .vertical
        mainStack.spacing = 12
        mainStack.alignment = .leading
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        keyboardContainer.addSubview(mainStack)

        NSLayoutConstraint.activate([

            mainStack.topAnchor.constraint(
                equalTo: keyboardContainer.topAnchor
            ),

            mainStack.leadingAnchor.constraint(
                equalTo: keyboardContainer.leadingAnchor
            )
        ])

        // MARK: Top Row - Space + Backspace

        let topRow = UIStackView()

        topRow.axis = .horizontal
        topRow.spacing = 12

        let spaceKey = makeKeyView(
            title: "␣",
            value: " "
        )

        let backspaceKey = makeKeyView(
            title: "⌫",
            value: "backspace"
        )

        topRow.addArrangedSubview(spaceKey)
        topRow.addArrangedSubview(backspaceKey)

        mainStack.addArrangedSubview(topRow)

        if firstKeyView == nil {
            firstKeyView = spaceKey
        }

        // MARK: Letter / Number Rows

        for row in keyboardRows {

            let rowStack = UIStackView()

            rowStack.axis = .horizontal
            rowStack.spacing = 10

            for key in row {

                let keyView = makeKeyView(
                    title: key,
                    value: key
                )

                rowStack.addArrangedSubview(keyView)
            }

            mainStack.addArrangedSubview(rowStack)
        }
    }

    private func makeKeyView(
        title: String,
        value: String
    ) -> UIView {

        let container = FocusableKeyView()

        container.translatesAutoresizingMaskIntoConstraints = false

        container.backgroundColor = UIColor(
            white: 0.18,
            alpha: 1
        )

        container.layer.cornerRadius = 10
        container.clipsToBounds = true

        // MARK: Label

        let label = UILabel()

        label.text = title
        label.textColor = .white

        label.font = .systemFont(
            ofSize: 26,
            weight: .medium
        )

        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(label)

        NSLayoutConstraint.activate([

            container.widthAnchor.constraint(
                equalToConstant: 56
            ),

            container.heightAnchor.constraint(
                equalToConstant: 56
            ),

            label.centerXAnchor.constraint(
                equalTo: container.centerXAnchor
            ),

            label.centerYAnchor.constraint(
                equalTo: container.centerYAnchor
            )
        ])

        // MARK: Store Value

        container.keyValue = value

        container.onSelect = { [weak self] val in
            self?.handleKey(val)
        }

        return container
    }

    // MARK: - Handle Keyboard

    private func handleKey(_ value: String) {

        if value == "backspace" {

            if !currentSearchText.isEmpty {
                currentSearchText.removeLast()
            }

        } else {

            currentSearchText += value
        }

        updateSearchField()

        viewModel.search(
            query: currentSearchText
        )
    }

    private func updateSearchField() {
        searchBar.text = currentSearchText
    }

    // MARK: - Binding

    private func bindViewModel() {

        viewModel.onUpdate = { [weak self] in

            self?.popularCollectionView.reloadData()
            self?.updateEmptyState()
        }

        viewModel.onError = { message in

            print("Search Error: \(message)")
        }

        viewModel.onLoadingChanged = { [weak self] isLoading in

            guard let self = self else { return }

            if isLoading {
                self.popularCollectionView.showLoadingIndicator()
            } else {
                self.popularCollectionView.hideLoadingIndicator()
            }
        }
    }

    private func updateEmptyState() {

        let isEmpty = viewModel.items.isEmpty

        emptyLabel.isHidden = !isEmpty
        popularCollectionView.isHidden = isEmpty
    }
}

// MARK: - Focusable Key View

final class FocusableKeyView: UIView {

    var keyValue: String = ""

    var onSelect: ((String) -> Void)?

    override var canBecomeFocused: Bool {
        true
    }

    override func didUpdateFocus(
        in context: UIFocusUpdateContext,
        with coordinator: UIFocusAnimationCoordinator
    ) {

        coordinator.addCoordinatedAnimations({

            if self.isFocused {

                self.backgroundColor = .white

                self.subviews
                    .compactMap { $0 as? UILabel }
                    .forEach {
                        $0.textColor = .black
                    }

                self.transform = CGAffineTransform(
                    scaleX: 1.12,
                    y: 1.12
                )

            } else {

                self.backgroundColor = UIColor(
                    white: 0.18,
                    alpha: 1
                )

                self.subviews
                    .compactMap { $0 as? UILabel }
                    .forEach {
                        $0.textColor = .white
                    }

                self.transform = .identity
            }

        }, completion: nil)
    }

    override func pressesEnded(
        _ presses: Set<UIPress>,
        with event: UIPressesEvent?
    ) {

        super.pressesEnded(
            presses,
            with: event
        )

        for press in presses {

            if press.type == .select {
                onSelect?(keyValue)
            }
        }
    }
}

// MARK: - CollectionView

extension SearchViewController:
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {

        return viewModel.numberOfItems()
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "PopularCell",
            for: indexPath
        ) as! PopularCell

        if let item = viewModel.item(
            at: indexPath.item
        ) {

            cell.configure(with: item)
        }

        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {

        let availableWidth = collectionView.bounds.width

        let spacing: CGFloat = 24
        let columns: CGFloat = 3

        let width = (
            availableWidth -
            (spacing * (columns - 1))
        ) / columns

        return CGSize(
            width: floor(width),
            height: floor(width * 1.35)
        )
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {

        guard let item = viewModel.item(
            at: indexPath.item
        ) else {
            return
        }

        playVideo(for: item)
    }
}

// MARK: - Video Playback

extension SearchViewController {

    private func playVideo(for item: ShowItem) {

        guard let videoUrlString = item.videoUrl,
              let videoUrl = URL(string: videoUrlString) else {
            return
        }

        let playerVC = TVPlayerViewController()
        playerVC.modalPresentationStyle = .fullScreen

        playerVC.play(
            url: videoUrl,
            title: item.title,
            episodeInfo: item.year ?? ""
        )

        present(playerVC, animated: true)
    }
}

// MARK: - Popular Cell

final class PopularCell: UICollectionViewCell {

    private let imageView = UIImageView()

    private let gradientLayer = CAGradientLayer()

    private let titleLabel = UILabel()

    private var imageTask: URLSessionDataTask?

    override init(frame: CGRect) {

        super.init(frame: frame)

        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true

        contentView.backgroundColor = UIColor(
            white: 0.12,
            alpha: 1
        )

        contentView.layer.borderWidth = 0

        // MARK: Image

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        imageView.backgroundColor = UIColor(
            white: 0.15,
            alpha: 1
        )

        imageView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(imageView)

        // MARK: Gradient

        gradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.75).cgColor
        ]

        gradientLayer.locations = [0.0, 1.0]

        contentView.layer.addSublayer(
            gradientLayer
        )

        // MARK: Title

        titleLabel.textColor = .white

        titleLabel.font = .systemFont(
            ofSize: 18,
            weight: .semibold
        )

        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byTruncatingTail

        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([

            imageView.topAnchor.constraint(
                equalTo: contentView.topAnchor
            ),

            imageView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor
            ),

            imageView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor
            ),

            imageView.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor
            ),

            titleLabel.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: 12
            ),

            titleLabel.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -12
            ),

            titleLabel.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor,
                constant: -14
            )
        ])
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func layoutSubviews() {

        super.layoutSubviews()

        let gradientHeight = bounds.height * 0.42

        gradientLayer.frame = CGRect(
            x: 0,
            y: bounds.height - gradientHeight,
            width: bounds.width,
            height: gradientHeight
        )
    }

    func configure(with item: ShowItem) {

        titleLabel.text = item.title

        imageView.image = nil

        imageTask?.cancel()

        guard let url = URL(
            string: item.imageName
        ),
        !item.imageName.isEmpty else {

            imageView.backgroundColor = UIColor(
                white: 0.18,
                alpha: 1
            )

            return
        }

        imageTask = URLSession.shared.dataTask(
            with: url
        ) { [weak self] data, _, _ in

            guard let data = data,
                  let image = UIImage(data: data) else {
                return
            }

            DispatchQueue.main.async {
                self?.imageView.image = image
            }
        }

        imageTask?.resume()
    }

    override func prepareForReuse() {

        super.prepareForReuse()

        imageTask?.cancel()

        imageView.image = nil
        titleLabel.text = nil

        contentView.layer.borderWidth = 0
    }

    // MARK: - Focus

    override func didUpdateFocus(
        in context: UIFocusUpdateContext,
        with coordinator: UIFocusAnimationCoordinator
    ) {

        coordinator.addCoordinatedAnimations({

            if self.isFocused {

                self.contentView.layer.borderWidth = 4

                self.contentView.layer.borderColor =
                    UIColor.white.cgColor

            } else {

                self.contentView.layer.borderWidth = 0

                self.contentView.layer.borderColor =
                    UIColor.clear.cgColor
            }

        }, completion: nil)
    }
}
