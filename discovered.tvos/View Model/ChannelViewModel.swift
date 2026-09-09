//
//  ChannelViewModel.swift
//  discovered.tvos
//
//  Drives ChannelViewController from `appdashboard/my_channel`.
//

import Foundation

/// Everything the channel screen needs to draw its header.
struct ChannelDisplayModel {
    let userName: String
    let avatarUrl: String?
    let bannerUrl: String?
    /// Video played behind the channel header.
    let bannerVideoUrl: String?
    let featuredTitle: String?
    let description: String
    let tags: [String]
    let videoCount: Int
}

final class ChannelViewModel {

    // MARK: - Inputs

    private let userId: String

    /// Shown immediately so the screen is never empty while loading.
    private let fallbackUserName: String?
    private let fallbackAvatarUrl: String?

    // MARK: - Outputs

    private(set) var display: ChannelDisplayModel
    private(set) var videos: [ShowItem] = []
    private(set) var isLoading = false

    var onUpdate: (() -> Void)?
    var onError: ((String) -> Void)?

    // MARK: - Init

    init(userId: String, userName: String? = nil, userPic: String? = nil) {
        self.userId = userId
        self.fallbackUserName = userName
        self.fallbackAvatarUrl = userPic

        self.display = ChannelDisplayModel(
            userName: userName ?? "Channel",
            avatarUrl: userPic,
            bannerUrl: nil,
            bannerVideoUrl: nil,
            featuredTitle: nil,
            description: "",
            tags: [],
            videoCount: 0
        )
    }

    // MARK: - Loading

    func load() {
        guard !isLoading else { return }
        isLoading = true

        NetworkManager.shared.fetchMyChannel(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false

                switch result {
                case .success(let response):
                    self.apply(response)
                    self.onUpdate?()

                case .failure(let error):
                    self.onError?(error.localizedDescription)
                }
            }
        }
    }

    private func apply(_ response: ChannelResponse) {

        let channelVideos = response.channel ?? []

        videos = channelVideos.map { video in
            ShowItem(
                title: video.title ?? "Untitled",
                imageName: video.thumbImage ?? "",
                videoUrl: video.videoFile ?? video.previewFile,
                description: video.description,
                duration: video.videoDuration,
                genre: (video.genreName?.isEmpty == false) ? video.genreName : video.mode,
                userName: video.userName,
                userId: video.userId,
                userPic: video.userPic
            )
        }

        // The feature_* fields describe the channel owner; fall back to the
        // first video when the channel has no featured entry.
        let firstVideo = channelVideos.first

        let name = firstNonEmpty(
            response.featureUsername,
            firstVideo?.userName,
            fallbackUserName
        ) ?? "Channel"

        let avatar = firstNonEmpty(
            response.featureUserPic,
            firstVideo?.userPic,
            fallbackAvatarUrl
        )

        let banner = firstNonEmpty(
            response.featureThumb,
            response.coverVideo?.preview,
            firstVideo?.thumbImage
        )

        let bannerVideo = firstNonEmpty(
            response.featureVideo,
            response.coverVideo?.preview,
            firstVideo?.videoFile,
            firstVideo?.previewFile
        )

        let rawDescription = firstNonEmpty(
            response.featureDesc,
            firstVideo?.description
        ) ?? ""

        let description = rawDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Watch every video from this creator on Discovered TV."
            : rawDescription

        let tags = (response.featureTag ?? "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        display = ChannelDisplayModel(
            userName: name,
            avatarUrl: avatar,
            bannerUrl: banner,
            bannerVideoUrl: bannerVideo,
            featuredTitle: firstNonEmpty(response.featureTitle),
            description: description,
            tags: Array(tags.prefix(6)),
            videoCount: videos.count
        )
    }

    private func firstNonEmpty(_ candidates: String?...) -> String? {
        for value in candidates {
            if let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return value
            }
        }
        return nil
    }

    // MARK: - Collection Helpers

    func numberOfVideos() -> Int { videos.count }

    func video(at index: Int) -> ShowItem? {
        guard index >= 0, index < videos.count else { return nil }
        return videos[index]
    }
}
