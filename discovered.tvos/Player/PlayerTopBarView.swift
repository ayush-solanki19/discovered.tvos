//
//  PlayerTopBarView.swift
//  discovered.tvos
//
//  Top information bar for the premium player
//

import SwiftUI

struct PlayerTopBarView: View {
    @State private var isBackFocused = false

    let title: String
    let episodeInfo: String
    var onBackTapped: (() -> Void)?

    var body: some View {
        HStack(spacing: 24) {
            BackButton(isFocused: isBackFocused)
                .focusable(true) { focused in
                    isBackFocused = focused
                }
                .onTapGesture {
                    onBackTapped?()
                }

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .tracking(-0.5)

                Text(episodeInfo)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.gray2)
                    .lineLimit(1)
                    .tracking(0.5)
                    .textCase(.uppercase)
            }

            Spacer()
        }
        .padding(.horizontal, 48)
        .padding(.vertical, 32)
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
    }
}

struct BackButton: View {
    let isFocused: Bool

    var body: some View {
        Image(systemName: "chevron.left")
            .font(.system(size: 24, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 56, height: 56)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        Color(red: 1, green: 1, blue: 1, opacity: isFocused ? 0.2 : 0.1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                Color(red: 1, green: 0.42, blue: 0.21, opacity: isFocused ? 1 : 0.2),
                                lineWidth: isFocused ? 2 : 2
                            )
                    )
            )
            .scaleEffect(isFocused ? 1.08 : 1.0)
            .shadow(color: Color(red: 1, green: 0.42, blue: 0.21, opacity: isFocused ? 0.4 : 0), radius: isFocused ? 12 : 0)
            .animation(.easeInOut(duration: 0.3), value: isFocused)
    }
}

#Preview {
    ZStack {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.17, green: 0.25, blue: 0.41),
                Color(red: 0.1, green: 0.14, blue: 0.27)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack {
            PlayerTopBarView(
                title: "The Last Kingdom",
                episodeInfo: "Season 5 • Episode 8 • 58 min"
            )
            Spacer()
        }
    }
}
