//
//  PremiumPlayerControlsView.swift
//  discovered.tvos
//

import SwiftUI

struct PremiumPlayerControlsView: View {
    @FocusState private var focusedControl: FocusedControl?
    @State private var isSettingsPanelOpen = false

    var currentTime: String = "0:00"
    var remainingTime: String = "0:00"
    var progress: Double = 0
    @Binding var isPlaying: Bool
    var totalTime: String = "0:00"
    var availableQualities: [String] = []
    @Binding var selectedQuality: String
    var onPlayPause: (() -> Void)?
    var onSeekForward: (() -> Void)?
    var onSeekBackward: (() -> Void)?
    var onQualityMenuStateChanged: ((Bool) -> Void)?

    enum FocusedControl: Hashable {
        case backward, playButton, forward, cc, settings
        case panelBack
        case quality(Int)
    }

    private var sortedQualities: [String] {
        let unique = Array(Set(availableQualities))
        return unique.sorted { a, b in
            if a.lowercased() == "auto" { return true }
            if b.lowercased() == "auto" { return false }
            let numA = Int(a.filter(\.isNumber)) ?? 0
            let numB = Int(b.filter(\.isNumber)) ?? 0
            return numA > numB
        }
    }

    private func isHD(_ quality: String) -> Bool {
        quality.contains("1080")
    }

    var body: some View {
        VStack(spacing: 8) {
            // Progress
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 4)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1, green: 0.42, blue: 0.21),
                                Color(red: 1, green: 0.55, blue: 0.35)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, progress * (UIScreen.main.bounds.width - 80)), height: 4)
            }
            .padding(.horizontal, 40)

            // Time
            HStack {
                Text(currentTime)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
                Text(remainingTime)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 40)

            // Main controls (yeh hamesha focusable rahenge jab panel band ho)  
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    Text(currentTime)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                    Text("/ \(totalTime)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(width: 70, alignment: .leading)
                .padding(.leading, 40)

                Spacer()

                HStack(spacing: 50) {
                    Button(action: onBackward) {
                        Image(systemName: "gobackward.10")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .scaleEffect(focusedControl == .backward ? 1.12 : 1.0)
                    }
                    .focused($focusedControl, equals: .backward)

                    Button(action: { onPlayPause?() }) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                            .scaleEffect(focusedControl == .playButton ? 1.12 : 1.0)
                    }
                    .focused($focusedControl, equals: .playButton)

                    Button(action: onForward) {
                        Image(systemName: "goforward.10")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .scaleEffect(focusedControl == .forward ? 1.12 : 1.0)
                    }
                    .focused($focusedControl, equals: .forward)
                }

                Spacer()

                HStack(spacing: 24) {
                    Button(action: {}) {
                        Image(systemName: "captions.bubble")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .scaleEffect(focusedControl == .cc ? 1.12 : 1.0)
                    }
                    .focused($focusedControl, equals: .cc)

                    Button(action: {
                        isSettingsPanelOpen = true
                        onQualityMenuStateChanged?(true)
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .scaleEffect(focusedControl == .settings ? 1.12 : 1.0)
                    }
                    .focused($focusedControl, equals: .settings)
                }
                .padding(.trailing, 40)
            }
            .padding(.vertical, 12)
            .animation(.easeInOut(duration: 0.15), value: focusedControl)
            // Panel open hone pe yeh controls focus nahi lenge
            .opacity(isSettingsPanelOpen ? 0.4 : 1.0)
            .allowsHitTesting(!isSettingsPanelOpen)
        }
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.8), Color.black.opacity(0.4)],
                startPoint: .bottom,
                endPoint: .top
            )
        )
        .overlay(alignment: .bottomTrailing) {
            if isSettingsPanelOpen {
                settingsPanel
                    .padding(.trailing, 40)
                    .padding(.bottom, 110)
                    .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .bottomTrailing)))
            }
        }
        .onChange(of: isSettingsPanelOpen) { _, open in
            if open {
                let startIndex = sortedQualities.firstIndex(of: selectedQuality) ?? 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    focusedControl = .quality(startIndex)
                }
            } else {
                focusedControl = .settings
            }
        }
    }

    // MARK: - Quality Panel
    private var settingsPanel: some View {
        let qualities = sortedQualities

        return VStack(alignment: .leading, spacing: 0) {
            SettingsPanelRow(isFocused: focusedControl == .panelBack) {
                closeSettingsPanel()
            } content: {
                HStack(spacing: 10) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Quality")
                        .font(.system(size: 17, weight: .semibold))
                    Spacer()
                }
            }
            .focused($focusedControl, equals: .panelBack)

            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 1)

            ForEach(Array(qualities.enumerated()), id: \.offset) { index, quality in
                SettingsPanelRow(isFocused: focusedControl == .quality(index)) {
                    selectedQuality = quality
                    closeSettingsPanel()
                } content: {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .frame(width: 16)
                            .opacity(selectedQuality == quality ? 1 : 0)

                        Text(quality)
                            .font(.system(size: 15, weight: .medium))

                        if isHD(quality) {
                            Text("HD")
                                .font(.system(size: 9, weight: .bold))
                                .baselineOffset(6)
                        }
                        Spacer()
                    }
                }
                .focused($focusedControl, equals: .quality(index))
            }
        }
        .frame(width: 260)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.14).opacity(0.97))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .onMoveCommand(perform: movePanelFocus)
        .onExitCommand(perform: closeSettingsPanel)
        .focusSection()
    }

    private func movePanelFocus(_ direction: MoveCommandDirection) {
        // Rows are stacked vertically in the same focus section, so tvOS's
        // native focus engine already moves up/down between adjacent rows.
        // Only left/right (which has no natural target here) needs handling.
        guard case .quality = focusedControl else { return }

        switch direction {
        case .left, .right:
            focusedControl = .panelBack
        default:
            break
        }
    }

    private func closeSettingsPanel() {
        isSettingsPanelOpen = false
        onQualityMenuStateChanged?(false)
    }

    private func onForward() { onSeekForward?() }
    private func onBackward() { onSeekBackward?() }
}

// MARK: - Row
struct SettingsPanelRow<Content: View>: View {
    let isFocused: Bool
    let action: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .background(isFocused ? Color.white.opacity(0.16) : Color.clear)
            .focusable(true)
            .onTapGesture(perform: action)
    }
}
