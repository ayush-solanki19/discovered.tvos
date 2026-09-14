//
//  PremiumPlayerControlsView.swift
//  discovered.tvos
//

import SwiftUI

struct PremiumPlayerControlsView: View {
    @FocusState private var focusedControl: FocusedControl?
    @State private var isSettingsPanelOpen = false
    // 0 = back/header row, 1...sortedQualities.count = quality rows (index - 1 into sortedQualities)
    @State private var panelSelection: Int = 0

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
        case panel
    }

    private var sortedQualities: [String] {
        let unique = Array(Set(availableQualities))
        return unique.sorted { a, b in
            if a.lowercased() == "auto" { return true }
            if b.lowercased() == "auto" { return false }
            return heightValue(from: a) > heightValue(from: b)
        }
    }

    private func heightValue(from quality: String) -> Int {
        guard let pIndex = quality.firstIndex(where: { $0 == "p" || $0 == "P" }) else { return 0 }
        return Int(quality[..<pIndex]) ?? 0
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
            .disabled(isSettingsPanelOpen)
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
                panelSelection = (sortedQualities.firstIndex(of: selectedQuality) ?? 0) + 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    focusedControl = .panel
                }
            } else {
                focusedControl = .settings
            }
        }
    }

    // MARK: - Quality Panel
    // Panel ko ek hi focusable node banaya gaya hai (Button) — isse tvOS ka
    // native spatial focus engine har row ko alag se focus target nahi
    // maanta, aur up/down navigation poori tarah humare onMoveCommand se
    // deterministic rehta hai (kisi geometry-based guess pe depend nahi karta).
    private var settingsPanel: some View {
        let qualities = sortedQualities
        let itemCount = qualities.count + 1

        return Button(action: { handlePanelSelect(qualities: qualities) }) {
            VStack(alignment: .leading, spacing: 0) {
                SettingsPanelRow(isFocused: panelSelection == 0) {
                    HStack(spacing: 10) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Quality")
                            .font(.system(size: 17, weight: .semibold))
                        Spacer()
                    }
                }

                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(height: 1)

                ForEach(Array(qualities.enumerated()), id: \.offset) { index, quality in
                    SettingsPanelRow(isFocused: panelSelection == index + 1) {
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
        }
        .buttonStyle(ClearFocusButtonStyle())
        .focusEffectDisabled()
        .focused($focusedControl, equals: .panel)
        .accessibilityLabel(panelAccessibilityLabel(qualities: qualities))
        .onMoveCommand { direction in
            guard itemCount > 0 else { return }
            switch direction {
            case .up:
                panelSelection = (panelSelection - 1 + itemCount) % itemCount
            case .down:
                panelSelection = (panelSelection + 1) % itemCount
            default:
                break
            }
        }
        .onExitCommand(perform: closeSettingsPanel)
        .focusSection()
    }

    private func handlePanelSelect(qualities: [String]) {
        if panelSelection == 0 {
            closeSettingsPanel()
        } else if qualities.indices.contains(panelSelection - 1) {
            selectedQuality = qualities[panelSelection - 1]
            closeSettingsPanel()
        }
    }

    private func panelAccessibilityLabel(qualities: [String]) -> String {
        if panelSelection == 0 {
            return "Back"
        } else if qualities.indices.contains(panelSelection - 1) {
            return "Quality, \(qualities[panelSelection - 1])"
        }
        return "Quality"
    }

    private func closeSettingsPanel() {
        isSettingsPanelOpen = false
        onQualityMenuStateChanged?(false)
    }

    private func onForward() { onSeekForward?() }
    private func onBackward() { onSeekBackward?() }
}

// MARK: - Button Style
// Default tvOS button styles draw a system focus "platter" (white card) behind
// the label. This style renders nothing extra so only our own dark background
// shows, while keeping Button's native select-press handling.
struct ClearFocusButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

// MARK: - Row
// Purely presentational — the panel's single Button owns focus and selection,
// this just renders the highlight for whichever index is currently selected.
struct SettingsPanelRow<Content: View>: View {
    let isFocused: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isFocused ? Color.white.opacity(0.16) : Color.clear)
    }
}
