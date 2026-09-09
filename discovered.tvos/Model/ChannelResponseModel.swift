//
//  ChannelResponseModel.swift
//  discovered.tvos
//
//  Response models for `appdashboard/my_channel`.
//

import Foundation

// MARK: - Response

struct ChannelResponse: Codable {

    let channel: [ChannelVideo]?
    let coverVideo: ChannelCoverVideo?

    let featureVideo: String?
    let featureThumb: String?
    let featureUid: String?
    let featurePid: String?
    let featureUsername: String?
    let featureTitle: String?
    let featureDesc: String?
    let featureTag: String?
    let featureUserPic: String?
    let featureCreatedAt: String?

    let status: Int?
    let type: String?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case channel
        case coverVideo = "cover_video"
        case featureVideo = "feature_video"
        case featureThumb = "feature_thumb"
        case featureUid = "feature_uid"
        case featurePid = "feature_pid"
        case featureUsername = "feature_username"
        case featureTitle = "feature_title"
        case featureDesc = "feature_desc"
        case featureTag = "feature_tag"
        case featureUserPic = "feature_uc_pic"
        case featureCreatedAt = "feature_created_at"
        case status, type, message
    }

    /// Every field is optional in practice, so decode defensively rather than
    /// letting one unexpected value fail the whole response.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        channel = try? c.decode([ChannelVideo].self, forKey: .channel)
        coverVideo = try? c.decode(ChannelCoverVideo.self, forKey: .coverVideo)

        featureVideo = try? c.decode(String.self, forKey: .featureVideo)
        featureThumb = try? c.decode(String.self, forKey: .featureThumb)
        featureUid = try? c.decode(String.self, forKey: .featureUid)
        featurePid = try? c.decode(String.self, forKey: .featurePid)
        featureUsername = try? c.decode(String.self, forKey: .featureUsername)
        featureTitle = try? c.decode(String.self, forKey: .featureTitle)
        featureDesc = try? c.decode(String.self, forKey: .featureDesc)
        featureTag = try? c.decode(String.self, forKey: .featureTag)
        featureUserPic = try? c.decode(String.self, forKey: .featureUserPic)
        featureCreatedAt = try? c.decode(String.self, forKey: .featureCreatedAt)

        status = try? c.decode(Int.self, forKey: .status)
        type = try? c.decode(String.self, forKey: .type)
        message = try? c.decode(String.self, forKey: .message)
    }
}

// MARK: - Cover Video

struct ChannelCoverVideo: Codable {
    let url: String?
    let preview: String?
}

// MARK: - Channel Video

struct ChannelVideo: Codable {

    let userId: String?
    let userName: String?
    let userPic: String?
    let postId: String?
    let title: String?
    let thumbImage: String?
    let videoFile: String?
    let previewFile: String?
    let description: String?
    let genreName: String?
    let tag: String?
    let mode: String?
    let createdAt: String?

    /// The API sends this as a number, not a string.
    let videoDuration: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case userName = "user_name"
        case userPic = "user_pic"
        case postId = "post_id"
        case title
        case thumbImage = "ThumbImage"
        case videoFile
        case previewFile
        case description
        case genreName = "genre_name"
        case tag
        case mode
        case createdAt = "created_at"
        case videoDuration = "video_duration"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        userId = try? c.decode(String.self, forKey: .userId)
        userName = try? c.decode(String.self, forKey: .userName)
        userPic = try? c.decode(String.self, forKey: .userPic)
        postId = try? c.decode(String.self, forKey: .postId)
        title = try? c.decode(String.self, forKey: .title)
        thumbImage = try? c.decode(String.self, forKey: .thumbImage)
        videoFile = try? c.decode(String.self, forKey: .videoFile)
        previewFile = try? c.decode(String.self, forKey: .previewFile)
        description = try? c.decode(String.self, forKey: .description)
        genreName = try? c.decode(String.self, forKey: .genreName)
        tag = try? c.decode(String.self, forKey: .tag)
        mode = try? c.decode(String.self, forKey: .mode)
        createdAt = try? c.decode(String.self, forKey: .createdAt)

        // Duration arrives as a number here and as a string elsewhere.
        if let asString = try? c.decode(String.self, forKey: .videoDuration) {
            videoDuration = asString
        } else if let asInt = try? c.decode(Int.self, forKey: .videoDuration) {
            videoDuration = String(asInt)
        } else {
            videoDuration = nil
        }
    }
}
