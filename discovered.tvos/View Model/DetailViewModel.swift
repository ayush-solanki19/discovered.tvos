//
//  DetailViewModel.swift
//  discovered.tvos
//
//  Created by mac mini on 17/08/26.
//

import Foundation

struct VideoDetailDisplayModel {
    let title: String
    let rating: String
    let year: String
    let duration: String
    let genre: String
    let description: String
    let starring: String
    let bannerImageUrl: String
    let videoUrl: String?
    let userCategory: String
    let similarVideos: [ShowItem]
}

class DetailViewModel {
    let videoDetail: VideoDetailDisplayModel

    init(selectedVideo: ShowItem, allVideos: [ShowItem] = []) {
        // Duration ko seconds se Minutes format me convert karna (e.g. 195s -> 3m)
        var formattedDuration = "HD Video"
        if let durSec = Int(selectedVideo.duration ?? "0"), durSec > 0 {
            let minutes = durSec / 60
            let seconds = durSec % 60
            formattedDuration = minutes > 0 ? "\(minutes)m \(seconds)s" : "\(seconds)s"
        }

        // Description fallback agar API se "NA" ya blank aaye
        let rawDesc = selectedVideo.description ?? ""
        let finalDescription = (rawDesc == "NA" || rawDesc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            ? "Watch full episode and exclusive streaming available on Discovered TV."
            : rawDesc

        // Similar Videos: Selected video ko chhodkar baaki videos
        let related = allVideos.filter { $0.title != selectedVideo.title }

        self.videoDetail = VideoDetailDisplayModel(
            title: selectedVideo.title,
            rating: selectedVideo.rating ?? "4.5/5",
            year: selectedVideo.year ?? "2026",
            duration: formattedDuration,
            genre: selectedVideo.genre ?? "General",
            description: finalDescription,
            starring: selectedVideo.userName ?? "Creator",
            bannerImageUrl: selectedVideo.imageName,
            videoUrl: selectedVideo.videoUrl,
            userCategory: "Brand",
            similarVideos: related.isEmpty ? HomeViewModel.shared.shows : related
        )
    }

    func numberOfSimilarVideos() -> Int {
        return videoDetail.similarVideos.count
    }

    func similarVideo(at index: Int) -> ShowItem {
        return videoDetail.similarVideos[index]
    }
}
