//
//  RecommendationsGridView.swift
//  discovered.tvos
//
//  Horizontally scrollable recommendations grid
//

import SwiftUI

struct RecommendationsGridView: View {
    let title: String
    let videos: [VideoRecommendation]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(-1)

                Text("Carefully selected for you")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.gray2)
                    .tracking(0.5)
                    .textCase(.uppercase)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    ForEach(videos, id: \.id) { video in
                        RecommendationCardView(video: video)
                    }
                }
                .padding(.horizontal, 48)
            }
        }
        .padding(.vertical, 32)
    }
}

#Preview {
    ZStack {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.06, green: 0.09, blue: 0.16),
                Color(red: 0.04, green: 0.055, blue: 0.16)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 0) {
            RecommendationsGridView(
                title: "More Like This",
                videos: [
                    VideoRecommendation(id: "1", title: "The Witcher", year: "2019", duration: "8 episodes", progress: nil, image: nil, imageURL: nil, videoURL: nil),
                    VideoRecommendation(id: "2", title: "Stranger Things", year: "2016", duration: "42 min", progress: nil, image: nil, imageURL: nil, videoURL: nil),
                    VideoRecommendation(id: "3", title: "Dark", year: "2017", duration: "10 episodes", progress: nil, image: nil, imageURL: nil, videoURL: nil),
                    VideoRecommendation(id: "4", title: "Shadow & Bone", year: "2021", duration: "8 episodes", progress: nil, image: nil, imageURL: nil, videoURL: nil),
                ]
            )

            Spacer()
        }
    }
}
