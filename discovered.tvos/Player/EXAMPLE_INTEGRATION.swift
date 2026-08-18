//
//  EXAMPLE_INTEGRATION.swift
//  discovered.tvos
//
//  This file shows how to integrate the TVPlayer into your existing ViewController.
//  You can use this as a reference when you're ready to add playback to your app.
//

import UIKit

// MARK: - Example: Add this to your ViewController
/*

// In your existing ViewController where you handle show selection:

override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    collectionView.cellForItem(at: indexPath)?.setNeedsFocusUpdate()

    // Launch the player with a sample HLS URL
    presentVideoPlayer(with: indexPath.item)
}

private func presentVideoPlayer(with showIndex: Int) {
    let playerVC = TVPlayerViewController()

    // Handle player dismissal - you can use this to track watched content
    playerVC.onDismiss = { [weak self] in
        print("Show \(showIndex) player dismissed")
        // TODO: Save watched position, update continue watching, etc.
    }

    // Use a sample HLS URL - replace with your actual video URL from your backend
    let sampleHLSURL = URL(string: "https://test-streams.mux.dev/x36xhzz/x3ysqsyx/media.m3u8")!

    playerVC.play(url: sampleHLSURL)

    // Present modally (fullscreen)
    self.present(playerVC, animated: true)
}

 */

// MARK: - Example: Using with your ShowItem model
/*

// You could extend ShowItem to include a video URL:

struct ShowItem {
    let id = UUID()
    let title: String
    let imageName: String
    let videoURL: URL?  // Add this when you have video content
}

// Then in your ViewController:

private func presentVideoPlayer(for show: ShowItem) {
    guard let videoURL = show.videoURL else {
        print("No video URL available for this show")
        return
    }

    let playerVC = TVPlayerViewController()

    playerVC.onDismiss = { [weak self] in
        // Track that user watched/played this show
        print("Finished watching: \(show.title)")
    }

    playerVC.play(url: videoURL)
    self.present(playerVC, animated: true)
}

 */

// MARK: - Example: Adding video URLs to your mock data
/*

// In HomeViewModel.loadMockData():

shows = [
    ShowItem(
        title: "THE LEADERSHIP FORUM",
        imageName: "poster1",
        videoURL: URL(string: "https://test-streams.mux.dev/x36xhzz/x3ysqsyx/media.m3u8")
    ),
    // ... add more shows with their HLS URLs
]

 */
