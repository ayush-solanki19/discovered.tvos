//
//  SpotlightResponseModel.swift
//  discovered.tvos
//
//  Created by mac mini on 17/08/26.
//

import Foundation

struct SpotlightMainResponse: Codable {
    let status: Int?
    let type: String?
    let message: String?
    let totalSliderCount: String?
    let homeVideos: [HomeVideoSection]?
    let coverVideo: [CoverVideoItem]?
    let relatedVideo: [RelatedVideoSection]?

    enum CodingKeys: String, CodingKey {
        case status, type, message
        case totalSliderCount = "total_slider_count"
        case homeVideos = "homeVideos"
        case coverVideo = "cover_video"
        case relatedVideo = "related_video"
    }
}

// Section Model
struct HomeVideoSection: Codable {
    let sliderType: String?
    let type: String?
    let slider: [VideoItem]?

    enum CodingKeys: String, CodingKey {
        case sliderType = "slider_type"
        case type
        case slider
    }
}

// Individual Video Item Model
struct VideoItem: Codable {
    let postId: String?
    let title: String?
    let thumbImage: String?
    let videoFile: String?
    let previewFile: String?
    let userName: String?
    let genreName: String?
    let description: String?
    let videoDuration: String?
    let mode: String?

    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case title
        case thumbImage = "ThumbImage"
        case videoFile
        case previewFile
        case userName = "user_name"
        case genreName = "genre_name"
        case description
        case videoDuration = "video_duration"
        case mode
    }

    // JSON me duration string ya int dono handle karne ke liye
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        postId = try? container.decode(String.self, forKey: .postId)
        title = try? container.decode(String.self, forKey: .title)
        thumbImage = try? container.decode(String.self, forKey: .thumbImage)
        videoFile = try? container.decode(String.self, forKey: .videoFile)
        previewFile = try? container.decode(String.self, forKey: .previewFile)
        userName = try? container.decode(String.self, forKey: .userName)
        genreName = try? container.decode(String.self, forKey: .genreName)
        description = try? container.decode(String.self, forKey: .description)
        mode = try? container.decode(String.self, forKey: .mode)

        if let durationStr = try? container.decode(String.self, forKey: .videoDuration) {
            videoDuration = durationStr
        } else if let durationInt = try? container.decode(Int.self, forKey: .videoDuration) {
            videoDuration = String(durationInt)
        } else {
            videoDuration = nil
        }
    }
}

// Cover Video Model (Hero Banner)
struct CoverVideoItem: Codable {
    let postId: String?
    let title: String?
    let url: String?
    let preview: String?
    let description: String?
    let genreName: String?
    let userName: String?

    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case title, url, preview, description
        case genreName = "genre_name"
        case userName = "user_name"
    }
}

// Related Video Section Model
struct RelatedVideoSection: Codable {
    let sliderType: String?
    let type: String?
    let slider: [VideoItem]?

    enum CodingKeys: String, CodingKey {
        case sliderType = "slider_type"
        case type
        case slider
    }
}
