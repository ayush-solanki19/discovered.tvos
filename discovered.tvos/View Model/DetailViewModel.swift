//
//  DetailViewModel.swift
//  discovered.tvos
//
//  Created by mac mini on 17/08/26.
//

import Foundation

struct MovieDetailModel {
    let title: String
    let rating: String
    let year: String
    let duration: String
    let genre: String
    let description: String
    let starring: String
    let bannerImageName: String
    let similarShows: [ShowItem]
}

class DetailViewModel {
    let movieDetail: MovieDetailModel
    private(set) var relatedVideos: [RelatedVideo] = []

    var onRelatedVideosUpdated: (() -> Void)?

    init(show: ShowItem) {
        // Mocking detailed data based on clicked item
        self.movieDetail = MovieDetailModel(
            title: "NEBULA\nASCENDANT",
            rating: "4.5/5",
            year: "2024",
            duration: "2h 45m",
            genre: "Sci-Fi",
            description: "When an anomaly tears through the outer rim colonies, a disgraced pilot must assemble a fractured crew to navigate the cosmic void. What they discover in the deep silence is not just a threat to humanity, but the unraveling of time itself.",
            starring: "Elena Rostova, Kaelen Vance, Dr. Aris Thorne",
            bannerImageName: show.imageName,
            similarShows: [
                ShowItem(title: "NEON VEIL", imageName: "poster1"),
                ShowItem(title: "THE VOID BEYOND", imageName: "poster2"),
                ShowItem(title: "ECHOES OF THE DRIFT", imageName: "poster3"),
                ShowItem(title: "CRYSTAL ABYSS", imageName: "poster4"),
                ShowItem(title: "THE AWAKENING", imageName: "poster5"),
                ShowItem(title: "SOLARIS 2.0", imageName: "poster1")
            ]
        )
    }

    func numberOfSimilarShows() -> Int {
        return movieDetail.similarShows.count
    }

    func similarShow(at index: Int) -> ShowItem {
        return movieDetail.similarShows[index]
    }

    func fetchRelatedVideos(userId: String) {
        let boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW"
        var body = ""
        body += "--\(boundary)\r\n"
        body += "Content-Disposition: form-data; name=\"uid\"\r\n\r\n"
        body += userId + "\r\n"
        body += "--\(boundary)\r\n"
        body += "Content-Disposition: form-data; name=\"start\"\r\n\r\n"
        body += "0\r\n"
        body += "--\(boundary)\r\n"
        body += "Content-Disposition: form-data; name=\"limit\"\r\n\r\n"
        body += "20\r\n"
        body += "--\(boundary)--\r\n"

        var request = URLRequest(url: URL(string: "https://discovered.tv/api/v3/appdashboard/get_related_video")!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("TIZEN", forHTTPHeaderField: "device")
        request.httpBody = body.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data, error == nil else { return }

            do {
                let response = try JSONDecoder().decode(RelatedVideoResponse.self, from: data)
                self?.relatedVideos = response.related_video.slider
                DispatchQueue.main.async {
                    self?.onRelatedVideosUpdated?()
                }
            } catch {
                print("Error decoding related videos: \(error)")
            }
        }.resume()
    }

    func numberOfRelatedVideos() -> Int {
        return relatedVideos.count
    }

    func relatedVideo(at index: Int) -> RelatedVideo? {
        guard index >= 0 && index < relatedVideos.count else { return nil }
        return relatedVideos[index]
    }
}
