//
//  TVPlayerViewController.swift
//  discovered.tvos
//
//  Created by Claude Code
//

import UIKit
import AVFoundation

class TVPlayerViewController: UIViewController {

    // MARK: - Public Properties
    var onDismiss: (() -> Void)?

    // MARK: - Private Properties
    private let engine = TVPlayerEngine()

    private let playerView = UIView()
    private let playerLayer = AVPlayerLayer()

    private let controlsBar = UIView()
    private let timelineContainer = UIView()
    private let timelineBackground = UIView()
    private let progressBar = UIView()
    private var progressWidthConstraint: NSLayoutConstraint?

    private let backButton = UIButton()
    private let currentTimeLabel = UILabel()
    private let rewindButton = UIButton()
    private let playPauseButton = UIButton()
    private let fastForwardButton = UIButton()
    private let volumeButton = UIButton()
    private let titleLabel = UILabel()
    private let infoButton = UIButton()
    private let settingsButton = UIButton()
    private let pipButton = UIButton()
    private let fullscreenButton = UIButton()

    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let errorContainerView = UIView()
    private let errorLabel = UILabel()
    private let errorRetryButton = UIButton()

    private var currentHLSURL: URL?
    private var controlsHideTimer: Timer?
    private var controlsVisible = true

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        engine.delegate = self

        setupPlayerView()
        setupControls()
        setupError()
        setupConstraints()
        setupGestureRecognizers()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer.frame = playerView.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        engine.release()
    }

    // MARK: - Public Methods
    func play(url: URL) {
        currentHLSURL = url
        engine.load(url: url)
        playPauseButton.isSelected = true
    }

    // MARK: - Setup UI
    private func setupPlayerView() {
        playerView.backgroundColor = .black
        playerView.layer.addSublayer(playerLayer)
        playerLayer.player = engine.player
        playerLayer.videoGravity = .resizeAspect
        view.addSubview(playerView)
    }

    private func setupControls() {
        // Loading indicator
        loadingIndicator.color = .white
        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)

        // Controls Bar - Horizontal compact bar at bottom
        controlsBar.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        controlsBar.alpha = 1
        view.addSubview(controlsBar)

        var buttonConfig = UIButton.Configuration.filled()
        buttonConfig.baseBackgroundColor = .clear
        buttonConfig.baseForegroundColor = .white
        buttonConfig.cornerStyle = .capsule

        // Back button
        backButton.configuration = buttonConfig
        backButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        backButton.addTarget(self, action: #selector(dismissDidTap), for: .primaryActionTriggered)
        controlsBar.addSubview(backButton)

        // Timeline
        timelineContainer.backgroundColor = .clear
        controlsBar.addSubview(timelineContainer)

        timelineBackground.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        timelineBackground.layer.cornerRadius = 1.5
        timelineBackground.clipsToBounds = true
        timelineContainer.addSubview(timelineBackground)

        progressBar.backgroundColor = UIColor.red
        progressBar.layer.cornerRadius = 1.5
        timelineBackground.addSubview(progressBar)

        currentTimeLabel.text = "00:00"
        currentTimeLabel.textColor = .white
        currentTimeLabel.font = .systemFont(ofSize: 10, weight: .regular)
        timelineContainer.addSubview(currentTimeLabel)

        // Rewind button
        rewindButton.configuration = buttonConfig
        rewindButton.setImage(UIImage(systemName: "gobackward.15"), for: .normal)
        rewindButton.addTarget(self, action: #selector(rewindDidTap), for: .primaryActionTriggered)
        controlsBar.addSubview(rewindButton)

        // Play/Pause button
        playPauseButton.configuration = buttonConfig
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .selected)
        playPauseButton.addTarget(self, action: #selector(playPauseDidTap), for: .primaryActionTriggered)
        controlsBar.addSubview(playPauseButton)

        // Forward button
        fastForwardButton.configuration = buttonConfig
        fastForwardButton.setImage(UIImage(systemName: "goforward.15"), for: .normal)
        fastForwardButton.addTarget(self, action: #selector(fastForwardDidTap), for: .primaryActionTriggered)
        controlsBar.addSubview(fastForwardButton)

        // Volume button
        volumeButton.configuration = buttonConfig
        volumeButton.setImage(UIImage(systemName: "speaker.wave.2.fill"), for: .normal)
        controlsBar.addSubview(volumeButton)

        // Title label
        titleLabel.text = "Video Title"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 11, weight: .regular)
        titleLabel.numberOfLines = 1
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        controlsBar.addSubview(titleLabel)

        // Info button
        infoButton.configuration = buttonConfig
        infoButton.setImage(UIImage(systemName: "info.circle"), for: .normal)
        controlsBar.addSubview(infoButton)

        // Settings button
        settingsButton.configuration = buttonConfig
        settingsButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        controlsBar.addSubview(settingsButton)

        // PiP button
        pipButton.configuration = buttonConfig
        pipButton.setImage(UIImage(systemName: "pip"), for: .normal)
        controlsBar.addSubview(pipButton)

        // Fullscreen button
        fullscreenButton.configuration = buttonConfig
        fullscreenButton.setImage(UIImage(systemName: "arrowshape.expand.fill"), for: .normal)
        controlsBar.addSubview(fullscreenButton)

        // Setup preferred focus
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
    }

    private func setupError() {
        errorContainerView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        errorContainerView.isHidden = true
        view.addSubview(errorContainerView)

        errorLabel.text = "Unable to play this video."
        errorLabel.textColor = .white
        errorLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorContainerView.addSubview(errorLabel)

        var retryConfig = UIButton.Configuration.filled()
        retryConfig.baseBackgroundColor = .white
        retryConfig.baseForegroundColor = .black

        errorRetryButton.configuration = retryConfig
        errorRetryButton.setTitle("Retry", for: .normal)
        errorRetryButton.addTarget(self, action: #selector(retryDidTap), for: .primaryActionTriggered)
        errorContainerView.addSubview(errorRetryButton)

        let backButton = UIButton(configuration: retryConfig)
        backButton.setTitle("Back", for: .normal)
        backButton.addTarget(self, action: #selector(dismissDidTap), for: .primaryActionTriggered)
        errorContainerView.addSubview(backButton)
    }

    private func setupConstraints() {
        [playerView, controlsBar, timelineContainer, timelineBackground, progressBar,
         backButton, rewindButton, playPauseButton, fastForwardButton, volumeButton,
         titleLabel, infoButton, settingsButton, pipButton, fullscreenButton,
         currentTimeLabel, loadingIndicator, errorContainerView, errorLabel, errorRetryButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: view.topAnchor),
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            // Controls Bar - Horizontal at bottom
            controlsBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controlsBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controlsBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            controlsBar.heightAnchor.constraint(equalToConstant: 50),

            // Back button
            backButton.leadingAnchor.constraint(equalTo: controlsBar.leadingAnchor, constant: 12),
            backButton.centerYAnchor.constraint(equalTo: controlsBar.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 32),
            backButton.heightAnchor.constraint(equalToConstant: 32),

            // Timeline
            timelineContainer.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 8),
            timelineContainer.centerYAnchor.constraint(equalTo: controlsBar.centerYAnchor),
            timelineContainer.heightAnchor.constraint(equalToConstant: 16),

            timelineBackground.leadingAnchor.constraint(equalTo: timelineContainer.leadingAnchor),
            timelineBackground.trailingAnchor.constraint(equalTo: timelineContainer.trailingAnchor),
            timelineBackground.centerYAnchor.constraint(equalTo: timelineContainer.centerYAnchor),
            timelineBackground.heightAnchor.constraint(equalToConstant: 3),

            progressBar.leadingAnchor.constraint(equalTo: timelineBackground.leadingAnchor),
            progressBar.topAnchor.constraint(equalTo: timelineBackground.topAnchor),
            progressBar.bottomAnchor.constraint(equalTo: timelineBackground.bottomAnchor),

            currentTimeLabel.leadingAnchor.constraint(equalTo: timelineContainer.leadingAnchor),
            currentTimeLabel.bottomAnchor.constraint(equalTo: timelineBackground.topAnchor, constant: -2),
            currentTimeLabel.widthAnchor.constraint(equalToConstant: 32),

            // Rewind button
            rewindButton.leadingAnchor.constraint(equalTo: timelineContainer.trailingAnchor, constant: 8),
            rewindButton.centerYAnchor.constraint(equalTo: controlsBar.centerYAnchor),
            rewindButton.widthAnchor.constraint(equalToConstant: 28),
            rewindButton.heightAnchor.constraint(equalToConstant: 28),

            // Play button
            playPauseButton.leadingAnchor.constraint(equalTo: rewindButton.trailingAnchor, constant: 6),
            playPauseButton.centerYAnchor.constraint(equalTo: controlsBar.centerYAnchor),
            playPauseButton.widthAnchor.constraint(equalToConstant: 28),
            playPauseButton.heightAnchor.constraint(equalToConstant: 28),

            // Forward button
            fastForwardButton.leadingAnchor.constraint(equalTo: playPauseButton.trailingAnchor, constant: 6),
            fastForwardButton.centerYAnchor.constraint(equalTo: controlsBar.centerYAnchor),
            fastForwardButton.widthAnchor.constraint(equalToConstant: 28),
            fastForwardButton.heightAnchor.constraint(equalToConstant: 28),

            // Volume button
            volumeButton.leadingAnchor.constraint(equalTo: fastForwardButton.trailingAnchor, constant: 6),
            volumeButton.centerYAnchor.constraint(equalTo: controlsBar.centerYAnchor),
            volumeButton.widthAnchor.constraint(equalToConstant: 24),
            volumeButton.heightAnchor.constraint(equalToConstant: 24),

            // Title label
            titleLabel.leadingAnchor.constraint(equalTo: volumeButton.trailingAnchor, constant: 8),
            titleLabel.centerYAnchor.constraint(equalTo: controlsBar.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: infoButton.leadingAnchor, constant: -8),

            // Info button
            infoButton.trailingAnchor.constraint(equalTo: settingsButton.leadingAnchor, constant: -6),
            infoButton.centerYAnchor.constraint(equalTo: controlsBar.centerYAnchor),
            infoButton.widthAnchor.constraint(equalToConstant: 24),
            infoButton.heightAnchor.constraint(equalToConstant: 24),

            // Settings button
            settingsButton.trailingAnchor.constraint(equalTo: pipButton.leadingAnchor, constant: -6),
            settingsButton.centerYAnchor.constraint(equalTo: controlsBar.centerYAnchor),
            settingsButton.widthAnchor.constraint(equalToConstant: 24),
            settingsButton.heightAnchor.constraint(equalToConstant: 24),

            // PiP button
            pipButton.trailingAnchor.constraint(equalTo: fullscreenButton.leadingAnchor, constant: -6),
            pipButton.centerYAnchor.constraint(equalTo: controlsBar.centerYAnchor),
            pipButton.widthAnchor.constraint(equalToConstant: 24),
            pipButton.heightAnchor.constraint(equalToConstant: 24),

            // Fullscreen button
            fullscreenButton.trailingAnchor.constraint(equalTo: controlsBar.trailingAnchor, constant: -12),
            fullscreenButton.centerYAnchor.constraint(equalTo: controlsBar.centerYAnchor),
            fullscreenButton.widthAnchor.constraint(equalToConstant: 24),
            fullscreenButton.heightAnchor.constraint(equalToConstant: 24),

            // Error container
            errorContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            errorContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            errorContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            errorContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            errorLabel.centerXAnchor.constraint(equalTo: errorContainerView.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: errorContainerView.centerYAnchor, constant: -40),
            errorLabel.leadingAnchor.constraint(equalTo: errorContainerView.leadingAnchor, constant: 100),
            errorLabel.trailingAnchor.constraint(equalTo: errorContainerView.trailingAnchor, constant: -100),

            errorRetryButton.centerXAnchor.constraint(equalTo: errorContainerView.centerXAnchor, constant: -80),
            errorRetryButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 48),
            errorRetryButton.widthAnchor.constraint(equalToConstant: 140),
            errorRetryButton.heightAnchor.constraint(equalToConstant: 52)
        ])

        let errorBackButton = errorContainerView.subviews.last as? UIButton
        NSLayoutConstraint.activate([
            errorBackButton!.centerXAnchor.constraint(equalTo: errorContainerView.centerXAnchor, constant: 80),
            errorBackButton!.centerYAnchor.constraint(equalTo: errorRetryButton.centerYAnchor),
            errorBackButton!.widthAnchor.constraint(equalToConstant: 140),
            errorBackButton!.heightAnchor.constraint(equalToConstant: 52)
        ])

        progressWidthConstraint = progressBar.widthAnchor.constraint(equalToConstant: 0)
        progressWidthConstraint?.isActive = true
    }

    private func setupGestureRecognizers() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        playerView.addGestureRecognizer(tapGesture)
    }

    // MARK: - Actions
    @objc private func playPauseDidTap() {
        engine.togglePlayPause()
    }

    @objc private func rewindDidTap() {
        engine.seekBackward()
    }

    @objc private func fastForwardDidTap() {
        engine.seekForward()
    }

    @objc private func handleTap() {
        toggleControlsVisibility()
    }

    @objc private func retryDidTap() {
        errorContainerView.isHidden = true
        if let url = currentHLSURL {
            play(url: url)
        }
    }

    @objc private func dismissDidTap() {
        engine.stop()
        dismiss(animated: true) { [weak self] in
            self?.onDismiss?()
        }
    }

    // MARK: - Controls Management
    private func toggleControlsVisibility() {
        controlsVisible.toggle()
        updateControlsVisibility()
    }

    private func updateControlsVisibility() {
        UIView.animate(withDuration: 0.3) {
            self.controlsBar.alpha = self.controlsVisible ? 1 : 0
        }
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
        resetControlsHideTimer()
    }

    private func resetControlsHideTimer() {
        controlsHideTimer?.invalidate()

        guard controlsVisible else { return }

        controlsHideTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            guard case .playing = self?.engine.state else {
                return
            }
            UIView.animate(withDuration: 0.3) {
                self?.controlsBar.alpha = 0
            }
            self?.controlsVisible = false
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        guard !seconds.isNaN && !seconds.isInfinite else { return "00:00" }
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        controlsVisible ? [playPauseButton] : [playerView]
    }
}

// MARK: - TVPlayerEngineDelegate
extension TVPlayerViewController: TVPlayerEngineDelegate {
    func playerEngine(_ engine: TVPlayerEngine, stateDidChange newState: TVPlayerState) {
        DispatchQueue.main.async {
            switch newState {
            case .idle:
                self.loadingIndicator.stopAnimating()
                self.controlsBar.isHidden = true

            case .loading:
                self.loadingIndicator.startAnimating()
                self.errorContainerView.isHidden = true

            case .ready:
                self.loadingIndicator.stopAnimating()
                self.controlsBar.isHidden = false
                self.controlsBar.alpha = 1
                self.controlsVisible = true

            case .playing:
                self.playPauseButton.isSelected = true
                self.resetControlsHideTimer()

            case .paused:
                self.playPauseButton.isSelected = false
                self.controlsHideTimer?.invalidate()

            case .buffering:
                self.loadingIndicator.startAnimating()

            case .ended:
                self.playPauseButton.isSelected = false

            case .failed(let error):
                self.loadingIndicator.stopAnimating()
                self.controlsBar.isHidden = true
                self.errorContainerView.isHidden = false

                if let tvError = error as? TVPlayerError {
                    switch tvError {
                    case .invalidURL:
                        self.errorLabel.text = "Invalid video URL."
                    case .playbackFailed(let msg):
                        self.errorLabel.text = "Unable to play this video.\n\(msg)"
                    default:
                        self.errorLabel.text = "Unable to play this video."
                    }
                }
            }
        }
    }

    func playerEngine(_ engine: TVPlayerEngine, currentTimeDidChange time: TimeInterval) {
        DispatchQueue.main.async {
            self.currentTimeLabel.text = self.formatTime(time)
            self.updateProgressBar()
        }
    }

    func playerEngine(_ engine: TVPlayerEngine, durationDidChange duration: TimeInterval) {
        // Duration tracking for progress bar calculations
    }

    func playerEngine(_ engine: TVPlayerEngine, bufferingRangeDidChange range: CMTimeRange) {
        // Future: Use this for buffering UI if needed
    }

    private func updateProgressBar() {
        guard engine.duration > 0 else { return }
        let progress = engine.currentTime / engine.duration
        let progressWidth = progress * (timelineBackground.bounds.width)

        UIView.animate(withDuration: 0.1) {
            self.progressWidthConstraint?.constant = progressWidth
            self.view.layoutIfNeeded()
        }
    }
}

