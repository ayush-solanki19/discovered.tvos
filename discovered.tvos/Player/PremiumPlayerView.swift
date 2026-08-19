//
//  PremiumPlayerView.swift
//  discovered.tvos
//
//  Complete premium Apple TV video player with SwiftUI
//

import SwiftUI
import AVKit
import AVFoundation

struct PremiumPlayerView: View {
    @State private var showControls = true
    @State private var showSidebar = false
    @State private var controlsHideTimer: Timer?
    @State private var currentTime: String = "0:00"
    @State private var totalTime: String = "0:00"
    @State private var remainingTime: String = "0:00"
    @State private var progress: Double = 0
    @State private var showEndOfVideo = false
    @State private var endOfVideoCountdown: Int = 12
    @State private var playerEngine = TVPlayerEngine()
    @State private var playerState: TVPlayerState = .idle
    @State private var suggestions: [VideoRecommendation] = []
    @State private var isLoadingSuggestions = false
    @State private var isPlaying = false
    @State private var nextVideoInQueue: VideoRecommendation?
    @FocusState private var focusedElement: FocusedElement?

    enum FocusedElement: Hashable {
        case backButton
        case moreButton
        case videoArea
        case controls
    }

    let title: String
    let episodeInfo: String
    let videoURL: URL?
    let userId: String

    var onBackTapped: (() -> Void)?
    var onPlayNext: ((VideoRecommendation) -> Void)?
    var onVideoEnded: (() -> Void)?

    var body: some View {
        ZStack {
            Color.darkBg.ignoresSafeArea()

            HStack(spacing: 0) {
                // Main content (left side)
                VStack(spacing: 0) {
                    // Top bar
                    if showControls {
                        HStack {
                            Button(action: { onBackTapped?() }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Back")
                                        .font(.system(size: 16, weight: .medium))
                                }
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .focused($focusedElement, equals: .backButton)
                            .onPlayPauseCommand {
                                onBackTapped?()
                            }

                            Spacer()

                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showSidebar.toggle()
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Text(showSidebar ? "Hide" : "More")
                                        .font(.system(size: 16, weight: .medium))
                                    Image(systemName: showSidebar ? "xmark" : "list.bullet")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .focused($focusedElement, equals: .moreButton)
                            .onPlayPauseCommand {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showSidebar.toggle()
                                }
                            }
                        }
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.6),
                                    Color.black.opacity(0)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Video area
                    ZStack {
                        VideoPlayerArea(playerEngine: playerEngine)
                            .layoutPriority(1)

                        if playerState == .loading {
                            VStack {
                                ProgressView()
                                    .tint(.premiumOrange)
                            }
                        }
                    }
                    .focused($focusedElement, equals: .videoArea)
                    .onPlayPauseCommand {
                        togglePlayPause()
                    }

                    Spacer()

                    // Bottom controls
                    if showControls {
                        PremiumPlayerControlsView(
                            currentTime: currentTime,
                            remainingTime: remainingTime,
                            progress: progress,
                            isPlaying: $isPlaying,
                            totalTime: totalTime,
                            onPlayPause: togglePlayPause,
                            onSeekForward: seekForward,
                            onSeekBackward: seekBackward
                        )
                        .focused($focusedElement, equals: .controls)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }

                // Right sidebar - Recommendations (Vertical scroll)
                if showSidebar && !suggestions.isEmpty && !isLoadingSuggestions {
                    RecommendationsSidebar(suggestions: suggestions)
                        .frame(width: 320)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }

            // End of video overlay
            if showEndOfVideo && nextVideoInQueue != nil {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showEndOfVideo = false
                        }

                    VStack {
                        Spacer()

                        HStack {
                            Spacer()

                            if let nextVideo = nextVideoInQueue {
                                EndOfVideoCardView(
                                    nextEpisodeTitle: nextVideo.title,
                                    episodeInfo: nextVideo.year,
                                    countdown: endOfVideoCountdown,
                                    onPlayNext: {
                                        playNextVideo(nextVideo)
                                        showEndOfVideo = false
                                    },
                                    onDismiss: {
                                        showEndOfVideo = false
                                    }
                                )
                            }

                            Spacer()
                        }

                        Spacer()
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                        removal: .opacity
                    ))
                }
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                showControls.toggle()
                resetControlsHideTimer()
            }
        }
        .onPlayPauseCommand {
            if !isPlaying && playerState == .ready {
                togglePlayPause()
            }
        }
        .onAppear {
            setupPlayer()
            loadSuggestions()
            resetControlsHideTimer()
        }
        .onDisappear {
            controlsHideTimer?.invalidate()
            playerEngine.release()
        }
    }

    private func togglePlayPause() {
        isPlaying.toggle()
        playerEngine.togglePlayPause()
        resetControlsHideTimer()
    }

    private func seekForward() {
        playerEngine.seekForward()
        resetControlsHideTimer()
    }

    private func seekBackward() {
        playerEngine.seekBackward()
        resetControlsHideTimer()
    }

    private func resetControlsHideTimer() {
        controlsHideTimer?.invalidate()
        showControls = true

        controlsHideTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                showControls = false
            }
        }
    }

    private func setupPlayer() {
        playerEngine.delegate = PlayerEngineDelegate(onStateChange: { state in
            playerState = state

            // Handle video end
            if case .failed(_) = state {
                handleVideoEnded()
            }
        }, onTimeChange: { time in
            currentTime = formatTime(time)
            let duration = playerEngine.duration
            totalTime = formatTime(duration)
            let remaining = duration - time
            remainingTime = "-\(formatTime(remaining))"
            progress = duration > 0 ? time / duration : 0

            // Check if video is almost ended (within 3 seconds)
            if duration > 0 && (duration - time) < 3 && (duration - time) > 0 && isPlaying {
                if !showEndOfVideo && nextVideoInQueue == nil {
                    setNextVideoInQueue()
                }
                if nextVideoInQueue != nil && !showEndOfVideo {
                    showEndOfVideo = true
                }
            }
        })

        if let url = videoURL {
            playerEngine.load(url: url)
            playerEngine.play()
            isPlaying = true
        }
    }

    private func loadSuggestions() {
        isLoadingSuggestions = true

        SuggestionAPIService.shared.fetchSuggestions(userId: userId) { videos in
            DispatchQueue.main.async {
                isLoadingSuggestions = false
                if let videos = videos {
                    self.suggestions = videos.map { video in
                        VideoRecommendation(
                            id: video.post_id,
                            title: video.title,
                            year: video.genre_name,
                            duration: formatDuration(video.video_duration),
                            progress: nil,
                            image: nil,
                            imageURL: video.ThumbImage,
                            videoURL: video.videoFile
                        )
                    }
                    print("Loaded \(self.suggestions.count) suggestions")
                }
            }
        }
    }

    private func setNextVideoInQueue() {
        if let firstSuggestion = suggestions.first {
            nextVideoInQueue = firstSuggestion
        }
    }

    private func playNextVideo(_ video: VideoRecommendation) {
        onPlayNext?(video)
    }

    private func handleVideoEnded() {
        onVideoEnded?()
        setNextVideoInQueue()
        if let nextVideo = nextVideoInQueue {
            showEndOfVideo = true
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}

// MARK: - Helper Functions
private func formatDuration(_ duration: AnyCodable) -> String {
    switch duration {
    case .int(let value):
        return "\(value) min"
    case .string(let value):
        return value
    case .double(let value):
        return "\(Int(value)) min"
    }
}

// MARK: - Player Engine Delegate
class PlayerEngineDelegate: TVPlayerEngineDelegate {
    let onStateChange: (TVPlayerState) -> Void
    let onTimeChange: (TimeInterval) -> Void

    init(onStateChange: @escaping (TVPlayerState) -> Void, onTimeChange: @escaping (TimeInterval) -> Void) {
        self.onStateChange = onStateChange
        self.onTimeChange = onTimeChange
    }

    func playerEngine(_ engine: TVPlayerEngine, stateDidChange newState: TVPlayerState) {
        onStateChange(newState)
    }

    func playerEngine(_ engine: TVPlayerEngine, currentTimeDidChange time: TimeInterval) {
        onTimeChange(time)
    }

    func playerEngine(_ engine: TVPlayerEngine, durationDidChange duration: TimeInterval) {}

    func playerEngine(_ engine: TVPlayerEngine, bufferingRangeDidChange range: CMTimeRange) {}
}

struct VideoPlayerArea: View {
    let playerEngine: TVPlayerEngine

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VideoPlayerRepresentable(player: playerEngine.player)
                .ignoresSafeArea()
        }
    }
}

// MARK: - AVPlayer Representable
struct VideoPlayerRepresentable: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspect
        controller.view.backgroundColor = .black
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
    }
}

// MARK: - Recommendations Sidebar
struct RecommendationsSidebar: View {
    let suggestions: [VideoRecommendation]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text("More Like This")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(-0.6)

                Text("Recommended for you")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gray2)
                    .tracking(0.3)
                    .textCase(.uppercase)
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider()
                .frame(height: 0.5)
                .background(Color(red: 1, green: 1, blue: 1, opacity: 0.1))

            // Vertical scrollable list
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, video in
                        RecommendationSidebarCard(
                            video: video,
                            isFirstCard: index == 0
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.6),
                    Color.black.opacity(0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color(red: 1, green: 1, blue: 1, opacity: 0.08), lineWidth: 1)
        )
    }
}

// MARK: - Sidebar Card Component
struct RecommendationSidebarCard: View {
    @State private var isFocused = false
    @State private var thumbnailImage: UIImage?

    let video: VideoRecommendation
    let isFirstCard: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.18, green: 0.35, blue: 0.55),
                                Color(red: 0.1, green: 0.24, blue: 0.36)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                if let image = thumbnailImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                        .cornerRadius(8)
                }

                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        Color(red: 1, green: 1, blue: 1, opacity: isFocused ? 0.3 : 0.08),
                        lineWidth: isFocused ? 1.5 : 0.8
                    )

                VStack {
                    HStack {
                        Spacer()
                    }
                    Spacer()
                }
                .overlay(
                    Image(systemName: "play.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(red: 1, green: 0.42, blue: 0.21))
                        .frame(width: 48, height: 48)
                        .background(
                            Circle()
                                .fill(Color(red: 1, green: 0.42, blue: 0.21, opacity: isFocused ? 0.4 : 0.2))
                        )
                        .scaleEffect(isFocused ? 1.12 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isFocused)
                )
            }
            .aspectRatio(16 / 9, contentMode: .fit)

            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(video.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .tracking(-0.2)

                HStack(spacing: 8) {
                    Text(video.year)
                        .font(.system(size: 11))
                        .foregroundColor(.gray2)

                    Text("•")
                        .foregroundColor(.gray2)

                    Text(video.duration)
                        .font(.system(size: 11))
                        .foregroundColor(.gray2)
                }
                .tracking(0.2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .shadow(
            color: Color(red: 1, green: 0.42, blue: 0.21, opacity: isFocused ? 0.4 : 0),
            radius: isFocused ? 12 : 0,
            x: 0,
            y: isFocused ? 8 : 0
        )
        .animation(.easeInOut(duration: 0.15), value: isFocused)
        .focusable(true) { focused in
            isFocused = focused
        }
        .onAppear {
            loadThumbnail()
        }
    }

    private func loadThumbnail() {
        guard let imageURLString = video.imageURL, let url = URL(string: imageURLString) else {
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil, let image = UIImage(data: data) else {
                return
            }
            DispatchQueue.main.async {
                self.thumbnailImage = image
            }
        }.resume()
    }
}

#Preview {
    PremiumPlayerView(
        title: "The Last Kingdom",
        episodeInfo: "Season 5 • Episode 8 • 58 min",
        videoURL: nil,
        userId: "user123"
    )
}
