//
//  TVPlayerViewController.swift
//  discovered.tvos
//
//  UIViewController wrapper for the premium SwiftUI player
//

import UIKit
import SwiftUI

class TVPlayerViewController: UIViewController {
    var onDismiss: (() -> Void)?
    var userId: String = "default_user"
    var videoTitle: String = "Video"
    var videoEpisodeInfo: String = ""
    var videoURL: URL?

    private var playerHostingController: UIHostingController<PremiumPlayerView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
    }

    func play(url: URL, title: String = "Video", episodeInfo: String = "") {
        videoURL = url
        videoTitle = title
        videoEpisodeInfo = episodeInfo

        let playerView = PremiumPlayerView(
            title: title,
            episodeInfo: episodeInfo,
            videoURL: url,
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
        hostingController.view.backgroundColor = .black

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        hostingController.didMove(toParent: self)
        self.playerHostingController = hostingController
    }

    private func handlePlayNext(_ nextVideo: VideoRecommendation) {
        if let videoURL = URL(string: nextVideo.videoURL ?? "") {
            play(url: videoURL, title: nextVideo.title, episodeInfo: nextVideo.year)
        }
    }

    private func dismissPlayer() {
        onDismiss?()
        dismiss(animated: true)
    }
}
