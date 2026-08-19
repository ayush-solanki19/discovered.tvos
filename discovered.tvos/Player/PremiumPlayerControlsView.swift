//
//  PremiumPlayerControlsView.swift
//  discovered.tvos
//
//  Premium Apple TV video player controls with reference design
//

import SwiftUI

struct PremiumPlayerControlsView: View {
    @FocusState private var focusedControl: FocusedControl?

    var currentTime: String = "0:00"
    var remainingTime: String = "0:00"
    var progress: Double = 0
    @Binding var isPlaying: Bool
    var totalTime: String = "0:00"
    var onPlayPause: (() -> Void)?
    var onSeekForward: (() -> Void)?
    var onSeekBackward: (() -> Void)?

    enum FocusedControl: Hashable {
        case backward
        case playButton
        case forward
        case progressBar
        case cc
        case audio
        case settings
    }

    var body: some View {
        VStack(spacing: 8) {
            // Progress bar at top - full width
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(red: 1, green: 1, blue: 1, opacity: 0.1))
                    .frame(height: 4)

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
                    .frame(width: max(0, progress * (UIScreen.main.bounds.width - 80)), height: 4)
            }
            .padding(.horizontal, 40)
            .focused($focusedControl, equals: .progressBar)

            // Time display bar
            HStack {
                Text(currentTime)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)

                Spacer()

                Text(remainingTime)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(red: 1, green: 1, blue: 1, opacity: 0.6))
            }
            .padding(.horizontal, 40)

            // Main controls bar
            HStack(spacing: 0) {
                // Left: Time info
                VStack(spacing: 0) {
                    Text(currentTime)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                    Text("/ \(totalTime)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(red: 1, green: 1, blue: 1, opacity: 0.6))
                }
                .frame(width: 70, alignment: .leading)
                .padding(.leading, 40)

                Spacer()

                // Center: Playback controls - perfectly centered
                HStack(spacing: 50) {
                    // Rewind button
                    Button(action: onBackward) {
                        Image(systemName: "gobackward.10")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .scaleEffect(focusedControl == .backward ? 1.12 : 1.0)
                            .animation(.easeInOut(duration: 0.15), value: focusedControl == .backward)
                    }
                    .focused($focusedControl, equals: .backward)

                    // Play/Pause button (centered, prominent)
                    Button(action: {
                        onPlayPause?()
                    }) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                            .scaleEffect(focusedControl == .playButton ? 1.12 : 1.0)
                            .animation(.easeInOut(duration: 0.15), value: focusedControl == .playButton)
                    }
                    .focused($focusedControl, equals: .playButton)

                    // Forward button
                    Button(action: onForward) {
                        Image(systemName: "goforward.10")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .scaleEffect(focusedControl == .forward ? 1.12 : 1.0)
                            .animation(.easeInOut(duration: 0.15), value: focusedControl == .forward)
                    }
                    .focused($focusedControl, equals: .forward)
                }

                Spacer()

                // Right side: Quality and settings
                HStack(spacing: 24) {
                    QualityBadge(quality: "4K", audio: "5.1")

                    Button(action: {}) {
                        Image(systemName: "captions.bubble")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .scaleEffect(focusedControl == .cc ? 1.12 : 1.0)
                            .animation(.easeInOut(duration: 0.15), value: focusedControl == .cc)
                    }
                    .focused($focusedControl, equals: .cc)

                    Button(action: {}) {
                        Image(systemName: "speaker.wave.2")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .scaleEffect(focusedControl == .audio ? 1.12 : 1.0)
                            .animation(.easeInOut(duration: 0.15), value: focusedControl == .audio)
                    }
                    .focused($focusedControl, equals: .audio)

                    Button(action: {}) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .scaleEffect(focusedControl == .settings ? 1.12 : 1.0)
                            .animation(.easeInOut(duration: 0.15), value: focusedControl == .settings)
                    }
                    .focused($focusedControl, equals: .settings)
                }
                .padding(.trailing, 40)
            }
            .padding(.vertical, 12)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.8),
                    Color.black.opacity(0.4)
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
        )
        .padding(.horizontal, -40)
        .padding(.vertical, -12)
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
                .scaleEffect(isFocused ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: isFocused)

            if isFocused {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
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
                .scaleEffect(isFocused ? 1.15 : 1.0)
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
