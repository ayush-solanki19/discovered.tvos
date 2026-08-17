import Foundation

class HomeViewModel {
    
    // Shared Instance (Taaki DetailViewController aur ViewController same data share karein)
    static let shared = HomeViewModel()

    var onSideMenuSelectionChanged: ((Int) -> Void)?
    var onDataLoaded: (() -> Void)?

    private(set) var heroData: HeroContent!
    private(set) var sideMenuItems: [SideMenuItem] = []
    private(set) var shows: [ShowItem] = []
    
    var selectedSideMenuIndex: Int = 0 {
        didSet {
            onSideMenuSelectionChanged?(selectedSideMenuIndex)
        }
    }
    
    var isSideMenuOpen: Bool = false

    init() {
        loadMockData()
    }

    private func loadMockData() {
        heroData = HeroContent(
            title: "The Hunting\nWives",
            metadata: "Drama  •  2025  •  8 Episodes  •  TV-MA",
            description: "Sophie trades New England for East Texas and falls into a wealthy socialite's magnetic orbit — where a clique of housewives hide deadly secrets.",
            backgroundImageName: "hero_back",
            badges: [
                ("RECENTLY ADDED", "darkGray"),
                ("TOP 10", "red"),
                ("#3 In TV Shows", "darkGray")
            ]
        )

        sideMenuItems = [
            SideMenuItem(id: 0, iconName: "sparkles", title: "Spotlight"),
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
            ShowItem(title: "THE GUEST INNOVATION & LEADERSHIP", imageName: "poster3"),
            ShowItem(title: "UNLEASHING CREATIVITY", imageName: "poster4"),
            ShowItem(title: "THE FUTURE OF INNOVATION SHOW", imageName: "poster5")
        ]
    }

    func numberOfShows() -> Int { shows.count }
    func showItem(at index: Int) -> ShowItem { shows[index] }
    func selectSideMenu(at index: Int) {
        selectedSideMenuIndex = index
    }
}
