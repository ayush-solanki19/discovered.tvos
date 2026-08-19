//
//  PremiumPlayerControlsView.swift
//  discovered.tvos
//
//  Premium Apple TV video player controls with focus-based remote navigation
//

import SwiftUI

struct PremiumPlayerControlsView: View {
    @State private var focusedControl: FocusedControl = .playButton

    var currentTime: String = "0:00"
    var remainingTime: String = "0:00"
    var progress: Double = 0
    @Binding var isPlaying: Bool
    var totalTime: String = "0:00"
    var onPlayPause: (() -> Void)?
    var onSeekForward: (() -> Void)?
    var onSeekBackward: (() -> Void)?

    enum FocusedControl {
        case backward
        case playButton
        case forward
        case progressBar
        case cc
        case audio
        case settings
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress Bar Section - Larger area for better interaction
            VStack(spacing: 12) {
                // Progress bar itself
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(Color(red: 1, green: 1, blue: 1, opacity: 0.1))
                        .frame(height: focusedControl == .progressBar ? 8 : 5)

                    // Played progress - animated
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
                        .frame(width: max(0, progress * 280), height: focusedControl == .progressBar ? 8 : 5)

                    // Playhead indicator - only show when focused
                    if focusedControl == .progressBar {
                        Circle()
                            .fill(Color(red: 1, green: 0.42, blue: 0.21))
                            .frame(width: 14, height: 14)
                            .shadow(color: Color(red: 1, green: 0.42, blue: 0.21, opacity: 0.6), radius: 8)
                            .offset(x: max(0, progress * 280) - 7)
                    }
                }
                .frame(maxWidth: 280)
                .frame(height: focusedControl == .progressBar ? 8 : 5)
                .focusable(true) { focused in
                    if focused {
                        focusedControl = .progressBar
                    }
                }

                // Time display - Below progress bar for clarity
                HStack(spacing: 16) {
                    Text(currentTime)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.gray2)
                        .frame(minWidth: 50, alignment: .leading)

                    Spacer()

                    Text(remainingTime)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.gray2)
                        .frame(minWidth: 50, alignment: .trailing)
                }
            }
            .padding(.horizontal, 48)
            .padding(.top, 24)
            .padding(.bottom, 28)

            Divider()
                .frame(height: 0.5)
                .background(Color(red: 1, green: 1, blue: 1, opacity: 0.08))

            // Control buttons - Separate section with good spacing
            VStack(spacing: 20) {
                // Playback controls
                HStack(spacing: 20) {
                    // Left side: Playback controls
                    HStack(spacing: 16) {
                        Button(action: onBackward) {
                            ControlButton(
                                icon: "gobackward.10",
                                label: "Rewind 10s",
                                isFocused: focusedControl == .backward,
                                isLarge: false
                            )
                        }
                        .focusable(true) { focused in
                            if focused { focusedControl = .backward }
                        }

                        Button(action: {
                            onPlayPause?()
                        }) {
                            PrimaryPlayButton(
                                isPlaying: isPlaying,
                                isFocused: focusedControl == .playButton
                            )
                        }
                        .focusable(true) { focused in
                            if focused { focusedControl = .playButton }
                        }

                        Button(action: onForward) {
                            ControlButton(
                                icon: "goforward.10",
                                label: "Forward 10s",
                                isFocused: focusedControl == .forward,
                                isLarge: false
                            )
                        }
                        .focusable(true) { focused in
                            if focused { focusedControl = .forward }
                        }
                    }

                    Spacer()

                    // Right side: Additional controls
                    HStack(spacing: 12) {
                        QualityBadge(quality: "4K", audio: "5.1")

                        ControlButton(
                            icon: "captions.bubble",
                            label: "Subtitles",
                            isFocused: focusedControl == .cc,
                            isLarge: false
                        )
                        .focusable(true) { focused in
                            if focused { focusedControl = .cc }
                        }

                        ControlButton(
                            icon: "speaker.wave.2",
                            label: "Audio",
                            isFocused: focusedControl == .audio,
                            isLarge: false
                        )
                        .focusable(true) { focused in
                            if focused { focusedControl = .audio }
                        }

                        ControlButton(
                            icon: "gearshape",
                            label: "Settings",
                            isFocused: focusedControl == .settings,
                            isLarge: false
                        )
                        .focusable(true) { focused in
                            if focused { focusedControl = .settings }
                        }
                    }
                }
            }
            .padding(.horizontal, 48)
            .padding(.vertical, 20)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.85),
                    Color.black.opacity(0.5),
                    Color.black.opacity(0)
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
        )
    }

    private func onForward() {
        onSeekForward?()
    }

    private func onBackward() {
        onSeekBackward?()
    }
}

struct ControlButton: View {
    let icon: String
    let label: String
    let isFocused: Bool
    let isLarge: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: isLarge ? 26 : 22, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: isLarge ? 64 : 56, height: isLarge ? 64 : 56)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            isFocused ?
                            Color(red: 1, green: 0.42, blue: 0.21, opacity: 0.2) :
                            Color(red: 1, green: 1, blue: 1, opacity: 0.06)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    Color(red: 1, green: 0.42, blue: 0.21, opacity: isFocused ? 0.8 : 0.1),
                                    lineWidth: isFocused ? 1.5 : 0.8
                                )
                        )
                )
                .scaleEffect(isFocused ? 1.12 : 1.0)
                .shadow(color: Color(red: 1, green: 0.42, blue: 0.21, opacity: isFocused ? 0.5 : 0), radius: isFocused ? 10 : 0)
                .animation(.easeInOut(duration: 0.15), value: isFocused)

            if isFocused {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray2)
                    .lineLimit(1)
                    .transition(.opacity)
            }
        }
    }
}

struct PrimaryPlayButton: View {
    let isPlaying: Bool
    let isFocused: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 68, height: 68)
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
                .cornerRadius(12)
                .shadow(color: Color(red: 1, green: 0.42, blue: 0.21, opacity: 0.4), radius: 10)
                .scaleEffect(isFocused ? 1.18 : 1.0)
                .shadow(color: Color(red: 1, green: 0.42, blue: 0.21, opacity: isFocused ? 0.7 : 0), radius: isFocused ? 20 : 0)
                .animation(.easeInOut(duration: 0.15), value: isFocused)

            if isFocused {
                Text(isPlaying ? "Pause" : "Play")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
                    .transition(.opacity)
            }
        }
    }
}

struct QualityBadge: View {
    let quality: String
    let audio: String

    var body: some View {
        Text("\(quality) • \(audio)")
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(red: 1, green: 1, blue: 1, opacity: 0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(red: 1, green: 1, blue: 1, opacity: 0.15), lineWidth: 0.8)
            )
            .cornerRadius(6)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            Spacer()
            PremiumPlayerControlsView(
                progress: 0.45,
                isPlaying: .constant(true),
                onPlayPause: {}
            )
        }
    }
}
