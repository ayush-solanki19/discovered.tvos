import Foundation

struct VideoSlider {
    let type: String?
    let videos: [ShowItem]
}

class HomeViewModel {
    static let shared = HomeViewModel()

    var onSideMenuSelectionChanged: ((Int) -> Void)?
    var onDataUpdated: (() -> Void)?
    var onError: ((String) -> Void)?

    private(set) var heroData: HeroContent!
    private(set) var sideMenuItems: [SideMenuItem] = []
    private(set) var videoSliders: [VideoSlider] = []
    private(set) var shows: [ShowItem] = []

    var isSideMenuOpen: Bool = false
    var selectedSideMenuIndex: Int = 0 {
        didSet {
            onSideMenuSelectionChanged?(selectedSideMenuIndex)
            handleCategorySelection(index: selectedSideMenuIndex)
        }
    }

    init() {
        setupSideMenu()
        fetchVideos(forMode: 8)
    }

    private func setupSideMenu() {
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
    }

    private func handleCategorySelection(index: Int) {
        switch index {
        case 0:
            fetchVideos(forMode: 8)
        case 1:
            fetchVideos(forMode: 1)
        case 2:
            fetchVideos(forMode: 2)
        case 3:
            fetchVideos(forMode: 3)
        case 4:
            fetchVideos(forMode: 7)
        default:
            break
        }
    }

    // MARK: - Dynamic API Call
    func fetchVideos(forMode mode: Int) {
        NetworkManager.shared.fetchHomeVideoSpotlight(mode: mode, limit: 10, start: 0, timeZoneOffset: "+250") { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    // 1. Cover Video (Hero Banner)
                    if let cover = response.coverVideo?.first {
                        self?.heroData = HeroContent(
                            title: cover.title ?? "Featured Video",
                            metadata: "\(cover.genreName ?? "")  •  \(cover.userName ?? "")",
                            description: cover.description ?? "",
                            backgroundImageName: cover.preview ?? cover.url ?? "",
                            videoUrl: cover.url ?? cover.preview,
                            badges: [("FEATURED", "red")]
                        )
                    }

                    // 2. All Sliders with Type as Heading
                    var sliders: [VideoSlider] = []
                    var allVideos: [ShowItem] = []

                    if let homeSections = response.homeVideos {
                        for section in homeSections {
                            if let slider = section.slider {
                                var videos: [ShowItem] = []
                                for video in slider {
                                    let item = ShowItem(
                                        title: video.title ?? "Untitled",
                                        imageName: video.thumbImage ?? "",
                                        videoUrl: video.videoFile ?? video.previewFile,
                                        description: video.description,
                                        duration: video.videoDuration,
                                        genre: video.genreName,
                                        userName: video.userName
                                    )
                                    videos.append(item)
                                    allVideos.append(item)
                                }

                                let videoSlider = VideoSlider(
                                    type: section.type ?? section.sliderType,
                                    videos: videos
                                )
                                sliders.append(videoSlider)
                            }
                        }
                    }

                    self?.videoSliders = sliders
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
    func numberOfSliders() -> Int { videoSliders.count }
    func slider(at index: Int) -> VideoSlider? { index < videoSliders.count ? videoSliders[index] : nil }
    func selectSideMenu(at index: Int) { selectedSideMenuIndex = index }
}
