//
//  SearchResponseModel.swift
//  discovered.tvos
//
//  Typed models for `appdashboard/get_mysearch_content_new`.
//

import Foundation

struct SearchResponse: Codable {
    let status: Int?
    let type: String?
    let message: String?
    let data: [SearchContentItem]?
    let results: [SearchContentItem]?
    let items: [SearchContentItem]?
    let response: [SearchContentItem]?
    let video: SearchResultGroup?
    let people: SearchResultGroup?

    var contentItems: [SearchContentItem] {
        if let directItems = data ?? results ?? items ?? response {
            return directItems
        }

        return (video?.searchData ?? []) + (people?.searchData ?? [])
    }

    init(items: [SearchContentItem]) {
        status = nil
        type = nil
        message = nil
        data = items
        results = nil
        self.items = nil
        response = nil
        video = nil
        people = nil
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try? container.decodeFlexibleInt(forKey: .status)
        type = try? container.decode(String.self, forKey: .type)
        message = try? container.decode(String.self, forKey: .message)
        data = try? container.decode([SearchContentItem].self, forKey: .data)
        results = try? container.decode([SearchContentItem].self, forKey: .results)
        items = try? container.decode([SearchContentItem].self, forKey: .items)
        response = try? container.decode([SearchContentItem].self, forKey: .response)
        video = try? container.decode(SearchResultGroup.self, forKey: .video)
        people = try? container.decode(SearchResultGroup.self, forKey: .people)
    }
}

struct SearchResultGroup: Codable {
    let searchData: [SearchContentItem]?
    let totalCount: String?

    enum CodingKeys: String, CodingKey {
        case searchData = "search_data"
        case totalCount = "total_count"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        searchData = try? container.decode([SearchContentItem].self, forKey: .searchData)
        totalCount = try? container.decodeFlexibleString(forKey: .totalCount)
    }
}

struct SearchContentItem: Codable {
    let postId: String?
    let userId: String?
    let userPic: String?
    let title: String?
    let name: String?
    let contentTitle: String?
    let videoTitle: String?
    let showTitle: String?
    let titleName: String?
    let image: String?
    let poster: String?
    let thumbnail: String?
    let posterUrl: String?
    let imageUrl: String?
    let thumb: String?
    let banner: String?
    let thumbImage: String?
    let videoFile: String?
    let videoPath: String?
    let previewFile: String?
    let description: String?
    let videoDuration: String?
    let genreName: String?
    let mode: String?
    let userName: String?
    let categoryName: String?

    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case userId = "user_id"
        case userPic = "user_pic"
        case title
        case name
        case contentTitle = "content_title"
        case videoTitle = "video_title"
        case showTitle = "show_title"
        case titleName = "title_name"
        case image
        case poster
        case thumbnail
        case posterUrl = "poster_url"
        case imageUrl = "image_url"
        case thumb
        case banner
        case thumbImage = "ThumbImage"
        case videoFile
        case videoPath = "video_path"
        case previewFile
        case description
        case videoDuration = "video_duration"
        case genreName = "genre_name"
        case mode
        case userName = "user_name"
        case categoryName = "category_name"
    }

    var displayTitle: String {
        firstNonEmpty(title, name, contentTitle, videoTitle, showTitle, titleName, userName) ?? "Unknown"
    }

    var displayImageUrl: String? {
        firstNonEmpty(image, poster, thumbnail, posterUrl, imageUrl, thumb, banner, thumbImage, userPic)
    }

    var showItem: ShowItem {
        ShowItem(
            title: displayTitle,
            imageName: displayImageUrl ?? "",
            videoUrl: firstNonEmpty(videoFile, videoPath, previewFile),
            description: description,
            duration: videoDuration,
            genre: firstNonEmpty(genreName, mode, categoryName),
            userName: userName,
            userId: userId,
            userPic: userPic
        )
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        postId = try? container.decodeFlexibleString(forKey: .postId)
        userId = try? container.decodeFlexibleString(forKey: .userId)
        userPic = try? container.decodeFlexibleString(forKey: .userPic)
        title = try? container.decodeFlexibleString(forKey: .title)
        name = try? container.decodeFlexibleString(forKey: .name)
        contentTitle = try? container.decodeFlexibleString(forKey: .contentTitle)
        videoTitle = try? container.decodeFlexibleString(forKey: .videoTitle)
        showTitle = try? container.decodeFlexibleString(forKey: .showTitle)
        titleName = try? container.decodeFlexibleString(forKey: .titleName)
        image = try? container.decodeFlexibleString(forKey: .image)
        poster = try? container.decodeFlexibleString(forKey: .poster)
        thumbnail = try? container.decodeFlexibleString(forKey: .thumbnail)
        posterUrl = try? container.decodeFlexibleString(forKey: .posterUrl)
        imageUrl = try? container.decodeFlexibleString(forKey: .imageUrl)
        thumb = try? container.decodeFlexibleString(forKey: .thumb)
        banner = try? container.decodeFlexibleString(forKey: .banner)
        thumbImage = try? container.decodeFlexibleString(forKey: .thumbImage)
        videoFile = try? container.decodeFlexibleString(forKey: .videoFile)
        videoPath = try? container.decodeFlexibleString(forKey: .videoPath)
        previewFile = try? container.decodeFlexibleString(forKey: .previewFile)
        description = try? container.decodeFlexibleString(forKey: .description)
        videoDuration = try? container.decodeFlexibleString(forKey: .videoDuration)
        genreName = try? container.decodeFlexibleString(forKey: .genreName)
        mode = try? container.decodeFlexibleString(forKey: .mode)
        userName = try? container.decodeFlexibleString(forKey: .userName)
        categoryName = try? container.decodeFlexibleString(forKey: .categoryName)
    }

    private func firstNonEmpty(_ candidates: String?...) -> String? {
        for value in candidates {
            if let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return value
            }
        }
        return nil
    }
}

private extension KeyedDecodingContainer {
    func decodeFlexibleString(forKey key: Key) throws -> String? {
        if let value = try? decode(String.self, forKey: key) {
            return value
        }
        if let value = try? decode(Int.self, forKey: key) {
            return String(value)
        }
        if let value = try? decode(Double.self, forKey: key) {
            return String(value)
        }
        return nil
    }

    func decodeFlexibleInt(forKey key: Key) throws -> Int? {
        if let value = try? decode(Int.self, forKey: key) {
            return value
        }
        if let value = try? decode(String.self, forKey: key) {
            return Int(value)
        }
        return nil
    }
}
