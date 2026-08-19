//
//  RecommendationCardView.swift
//  discovered.tvos
//
//  Premium video recommendation card with focus states
//

import SwiftUI

struct VideoRecommendation {
    let id: String
    let title: String
    let year: String
    let duration: String
    let progress: Double? // 0.0-1.0, nil if not started
    let image: Image?
    let imageURL: String?
    let videoURL: String?

    init(id: String, title: String, year: String, duration: String, progress: Double? = nil, image: Image? = nil, imageURL: String? = nil, videoURL: String? = nil) {
        self.id = id
        self.title = title
        self.year = year
        self.duration = duration
        self.progress = progress
        self.image = image
        self.imageURL = imageURL
        self.videoURL = videoURL
    }
}

struct RecommendationCardView: View {
    @State private var isFocused = false
    @State private var thumbnailImage: UIImage?

    let video: VideoRecommendation

    var body: some View {
        VStack(spacing: 16) {
            // Thumbnail
            ZStack {
                // Background gradient
                RoundedRectangle(cornerRadius: 16)
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

                // Thumbnail image if available
                if let image = thumbnailImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                        .cornerRadius(16)
                }

                // Border
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        Color(red: 1, green: 1, blue: 1, opacity: isFocused ? 0.3 : 0.08),
                        lineWidth: isFocused ? 2 : 1
                    )

                // Play icon
                VStack {
                    HStack {
                        Spacer()
                    }
                    Spacer()
                }
                .overlay(
                    Image(systemName: "play.fill")
                        .font(.system(size: 32))
                        .foregroundColor(Color(red: 1, green: 0.42, blue: 0.21))
                        .frame(width: 64, height: 64)
                        .background(
                            Circle()
                                .fill(Color(red: 1, green: 0.42, blue: 0.21, opacity: isFocused ? 0.4 : 0.2))
                        )
                        .scaleEffect(isFocused ? 1.15 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: isFocused)
                )

                // Progress indicator (if watched)
                if let progress = video.progress {
                    VStack(alignment: .leading) {
                        Spacer()

                        HStack {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color(red: 1, green: 1, blue: 1, opacity: 0.1))

                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(red: 1, green: 0.42, blue: 0.21),
                                                    Color(red: 1, green: 0.55, blue: 0.35)
                                                ]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geo.size.width * progress)
                                }
                            }
                            .frame(height: 4)
                        }
                        .padding(12)
                    }
                }
            }
            .aspectRatio(16 / 9, contentMode: .fit)

            // Info
            VStack(alignment: .leading, spacing: 8) {
                Text(video.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .tracking(-0.3)

                HStack(spacing: 12) {
                    Text(video.year)
                        .font(.system(size: 13))
                        .foregroundColor(.gray2)

                    Text(video.duration)
                        .font(.system(size: 13))
                        .foregroundColor(.gray2)
                }
                .tracking(0.3)
            }
        }
        .frame(width: 260)
        .scaleEffect(isFocused ? 1.1 : 1.0)
        .shadow(
            color: Color(red: 1, green: 0.42, blue: 0.21, opacity: isFocused ? 0.6 : 0),
            radius: isFocused ? 18 : 0,
            x: 0,
            y: isFocused ? 14 : 0
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
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
    ZStack {
        Color(red: 0.04, green: 0.055, blue: 0.16).ignoresSafeArea()

        HStack(spacing: 24) {
            RecommendationCardView(
                video: VideoRecommendation(
                    id: "1",
                    title: "The Witcher",
                    year: "2019",
                    duration: "8 episodes",
                    progress: nil,
                    image: nil,
                    imageURL: nil,
                    videoURL: nil
                )
            )

            RecommendationCardView(
                video: VideoRecommendation(
                    id: "2",
                    title: "Dark",
                    year: "2017",
                    duration: "10 episodes",
                    progress: 0.35,
                    image: nil,
                    imageURL: nil,
                    videoURL: nil
                )
            )
        }
        .padding(48)
    }
}
