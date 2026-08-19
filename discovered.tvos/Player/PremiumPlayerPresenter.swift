//
//  PremiumPlayerPresenter.swift
//  discovered.tvos
//
//  Presents the SwiftUI PremiumPlayerView from UIKit when a video is selected
//

import UIKit
import SwiftUI

class PremiumPlayerPresenter {
    weak var viewController: UIViewController?
    var userId: String = "default_user"

    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    func presentPlayer(for video: RelatedVideo) {
        let videoURL = URL(string: video.videoFile)

        let playerView = PremiumPlayerView(
            title: video.title,
            episodeInfo: video.description,
            videoURL: videoURL,
            userId: userId,
            onBackTapped: {
                self.dismissPlayer()
            },
            onPlayNext: { nextVideo in
                self.handlePlayNext(nextVideo)
            },
            onVideoEnded: {
                // Optional: handle video ended
            }
        )

        let hostingController = UIHostingController(rootView: playerView)
        hostingController.modalPresentationStyle = .fullScreen

        viewController?.present(hostingController, animated: true)
    }

    private func handlePlayNext(_ nextVideo: VideoRecommendation) {
        if let videoURL = URL(string: nextVideo.videoURL ?? "") {
            presentPlayer(title: nextVideo.title, episodeInfo: nextVideo.year, videoURL: videoURL)
        }
    }

    private func presentPlayer(title: String, episodeInfo: String, videoURL: URL?) {
        let playerView = PremiumPlayerView(
            title: title,
            episodeInfo: episodeInfo,
            videoURL: videoURL,
            userId: userId,
            onBackTapped: {
                self.dismissPlayer()
            },
            onPlayNext: { nextVideo in
                self.handlePlayNext(nextVideo)
            },
            onVideoEnded: {
                // Optional: handle video ended
            }
        )

        let hostingController = UIHostingController(rootView: playerView)
        hostingController.modalPresentationStyle = .fullScreen

        viewController?.present(hostingController, animated: true)
    }

    private func dismissPlayer() {
        viewController?.dismiss(animated: true)
    }
}
