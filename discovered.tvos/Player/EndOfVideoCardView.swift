//
//  EndOfVideoCardView.swift
//  discovered.tvos
//
//  Next episode auto-play card shown at end of video
//

import SwiftUI

struct EndOfVideoCardView: View {
    @State private var playNextFocused = false
    @State private var dismissFocused = false
    @FocusState private var focusedButton: FocusedButton?

    enum FocusedButton: Hashable {
        case playNext
        case dismiss
    }

    let nextEpisodeTitle: String
    let episodeInfo: String
    let countdown: Int

    var onPlayNext: (() -> Void)?
    var onDismiss: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 12)
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

                Image(systemName: "play.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color(red: 1, green: 0.42, blue: 0.21))
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(Color(red: 1, green: 0.42, blue: 0.21, opacity: 0.25))
                    )
            }
            .aspectRatio(16 / 9, contentMode: .fit)

            // Info
            VStack(alignment: .leading, spacing: 12) {
                Text("Next Episode")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray2)
                    .tracking(0.5)
                    .textCase(.uppercase)

                Text(nextEpisodeTitle)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .tracking(-0.3)

                Text(episodeInfo)
                    .font(.system(size: 13))
                    .foregroundColor(Color(red: 0.69, green: 0.69, blue: 0.69))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Countdown
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .trim(from: 0, to: CGFloat(countdown) / 30.0)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 1, green: 0.42, blue: 0.21),
                                    Color(red: 1, green: 0.55, blue: 0.35)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    Circle()
                        .stroke(Color(red: 1, green: 0.42, blue: 0.21, opacity: 0.2), lineWidth: 1)

                    Text("\(countdown)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 1, green: 0.42, blue: 0.21))
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Plays in")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray2)
                        .tracking(0.3)
                        .textCase(.uppercase)

                    Text("\(countdown)s")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 1, green: 0.42, blue: 0.21))
                }
            }
            .padding(12)
            .background(Color(red: 1, green: 0.42, blue: 0.21, opacity: 0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(red: 1, green: 0.42, blue: 0.21, opacity: 0.2), lineWidth: 1)
            )
            .cornerRadius(12)

            // Actions
            HStack(spacing: 12) {
                Button(action: {
                    onPlayNext?()
                }) {
                    Text("Play Next")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 1, green: 0.42, blue: 0.21),
                                    Color(red: 1, green: 0.55, blue: 0.35)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(10)
                        .shadow(
                            color: Color(red: 1, green: 0.42, blue: 0.21, opacity: focusedButton == .playNext ? 0.4 : 0.2),
                            radius: focusedButton == .playNext ? 12 : 6
                        )
                }
                .focused($focusedButton, equals: .playNext)
                .scaleEffect(focusedButton == .playNext ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: focusedButton == .playNext)

                Button(action: {
                    onDismiss?()
                }) {
                    Text("Cancel")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(red: 1, green: 1, blue: 1, opacity: 0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    Color(red: 1, green: 1, blue: 1, opacity: focusedButton == .dismiss ? 0.3 : 0.12),
                                    lineWidth: 1
                                )
                        )
                        .cornerRadius(10)
                }
                .focused($focusedButton, equals: .dismiss)
                .scaleEffect(focusedButton == .dismiss ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: focusedButton == .dismiss)
            }
            .onAppear {
                focusedButton = .playNext
            }
        }
        .frame(width: 400)
        .padding(24)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.06, green: 0.117, blue: 0.18, opacity: 0.95),
                    Color(red: 0.04, green: 0.055, blue: 0.16, opacity: 0.98)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(red: 1, green: 0.42, blue: 0.21, opacity: 0.2), lineWidth: 1)
        )
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.6), radius: 24)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            Spacer()

            HStack {
                Spacer()

                EndOfVideoCardView(
                    nextEpisodeTitle: "The Last Kingdom",
                    episodeInfo: "Season 5 • Episode 9 • 58 min",
                    countdown: 12
                )

                Spacer()
            }

            Spacer()
        }
    }
}
