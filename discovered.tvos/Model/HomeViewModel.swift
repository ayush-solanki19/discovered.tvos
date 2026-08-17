import Foundation

class HomeViewModel {
    static let shared = HomeViewModel()

    var onSideMenuSelectionChanged: ((Int) -> Void)?
    var onDataUpdated: (() -> Void)?
    var onError: ((String) -> Void)?

    private(set) var heroData: HeroContent!
    private(set) var sideMenuItems: [SideMenuItem] = []
    private(set) var shows: [ShowItem] = []

    var isSideMenuOpen: Bool = false
    var selectedSideMenuIndex: Int = 0 {
        didSet {
            onSideMenuSelectionChanged?(selectedSideMenuIndex)
            handleCategorySelection(index: selectedSideMenuIndex)
        }
    }

    init() {
        setupDefaultData()
    }

    private func setupDefaultData() {
        heroData = HeroContent(
            title: "The Hunting\nWives",
            metadata: "Drama  •  2025  •  8 Episodes  •  TV-MA",
            description: "Sophie trades New England for East Texas and falls into a wealthy socialite's magnetic orbit.",
            backgroundImageName: "hero_back",
            badges: [("RECENTLY ADDED", "darkGray"), ("TOP 10", "red")]
        )

        sideMenuItems = [
            SideMenuItem(id: 0, iconName: "sun.min", title: "Spotlight"),
            SideMenuItem(id: 1, iconName: "headphones", title: "Music"),
            SideMenuItem(id: 2, iconName: "film", title: "Movies"),
            SideMenuItem(id: 3, iconName: "tv", title: "Television"),
            SideMenuItem(id: 4, iconName: "gamecontroller", title: "Gaming"),
            SideMenuItem(id: 5, iconName: "person.crop.circle", title: "Login"),
            SideMenuItem(id: 6, iconName: "questionmark.circle", title: "Help"),
            SideMenuItem(id: 7, iconName: "shield", title: "Policy")
        ]

        shows = [
            ShowItem(title: "THE LEADERSHIP FORUM", imageName: "poster1"),
            ShowItem(title: "THE FUTURE IS NOW", imageName: "poster2"),
            ShowItem(title: "THE GUEST INNOVATION", imageName: "poster3"),
            ShowItem(title: "UNLEASHING CREATIVITY", imageName: "poster4")
        ]
    }

    private func handleCategorySelection(index: Int) {
        if index == 1 { // 1 = Music
            fetchMusicVideos()
        }
    }

    // MARK: - Fetch API Data
    func fetchMusicVideos() {
        NetworkManager.shared.fetchHomeVideoSpotlight(mode: 8, limit: 2, start: 0, timeZoneOffset: "+250") { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    // 1. Cover Video se Hero Card setup
                    if let cover = response.coverVideo?.first {
                        self?.heroData = HeroContent(
                            title: cover.title ?? "Featured Video",
                            metadata: "\(cover.genreName ?? "Music")  •  \(cover.userName ?? "")",
                            description: cover.description ?? "",
                            backgroundImageName: cover.preview ?? cover.url ?? "",
                            badges: [("FEATURED", "red")]
                        )
                    }

                    // 2. homeVideos list se videos nikaal kar shows array me map karna
                    var allVideos: [ShowItem] = []
                    if let homeSections = response.homeVideos {
                        for section in homeSections {
                            if let slider = section.slider {
                                for video in slider {
                                    let item = ShowItem(
                                        title: video.title ?? "Untitled",
                                        imageName: video.thumbImage ?? ""
                                    )
                                    allVideos.append(item)
                                }
                            }
                        }
                    }

                    self?.shows = allVideos
                    self?.onDataUpdated?()

                case .failure(let error):
                    self?.onError?(error.localizedDescription)
                }
            }
        }
    }

    func numberOfShows() -> Int { shows.count }
    func showItem(at index: Int) -> ShowItem { shows[index] }
    func selectSideMenu(at index: Int) { selectedSideMenuIndex = index }
}
