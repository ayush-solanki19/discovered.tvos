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

    private let controlsContainer = UIView()
    private let progressContainer = UIView()
    private let progressTrack = UIView()
    private let progressBar = UIView()
    private let progressThumb = UIView()
    private var progressWidthConstraint: NSLayoutConstraint?

    private let currentTimeLabel = UILabel()
    private let durationLabel = UILabel()

    private let playPauseButton = UIButton()
    private let volumeButton = UIButton()
    private let ccButton = UIButton()
    private let likeButton = UIButton()
    private let dislikeButton = UIButton()
    private let addButton = UIButton()
    private let settingsButton = UIButton()
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

        // Controls Container - YouTube style
        controlsContainer.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        controlsContainer.alpha = 1
        view.addSubview(controlsContainer)

        // Progress bar area
        progressContainer.backgroundColor = .clear
        controlsContainer.addSubview(progressContainer)

        progressTrack.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        progressTrack.layer.cornerRadius = 2
        progressTrack.clipsToBounds = true
        progressContainer.addSubview(progressTrack)

        progressBar.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
        progressBar.layer.cornerRadius = 2
        progressTrack.addSubview(progressBar)

        progressThumb.backgroundColor = .white
        progressThumb.layer.cornerRadius = 6
        progressThumb.clipsToBounds = true
        progressTrack.addSubview(progressThumb)

        currentTimeLabel.text = "0:00"
        currentTimeLabel.textColor = .white
        currentTimeLabel.font = .systemFont(ofSize: 12, weight: .medium)
        progressContainer.addSubview(currentTimeLabel)

        durationLabel.text = "0:00"
        durationLabel.textColor = .white
        durationLabel.font = .systemFont(ofSize: 12, weight: .medium)
        durationLabel.textAlignment = .right
        progressContainer.addSubview(durationLabel)

        // Button config
        var buttonConfig = UIButton.Configuration.plain()
        buttonConfig.baseForegroundColor = .white
        buttonConfig.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)

        // Play/Pause button
        playPauseButton.configuration = buttonConfig
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .selected)
        playPauseButton.addTarget(self, action: #selector(playPauseDidTap), for: .primaryActionTriggered)
        controlsContainer.addSubview(playPauseButton)

        // Volume button
        volumeButton.configuration = buttonConfig
        volumeButton.setImage(UIImage(systemName: "speaker.wave.2.fill"), for: .normal)
        controlsContainer.addSubview(volumeButton)

        // CC (Captions) button
        ccButton.configuration = buttonConfig
        ccButton.setImage(UIImage(systemName: "captions.bubble.fill"), for: .normal)
        controlsContainer.addSubview(ccButton)

        // Like button
        likeButton.configuration = buttonConfig
        likeButton.setImage(UIImage(systemName: "hand.thumbsup"), for: .normal)
        controlsContainer.addSubview(likeButton)

        // Dislike button
        dislikeButton.configuration = buttonConfig
        dislikeButton.setImage(UIImage(systemName: "hand.thumbsdown"), for: .normal)
        controlsContainer.addSubview(dislikeButton)

        // Add to playlist button
        addButton.configuration = buttonConfig
        addButton.setImage(UIImage(systemName: "plus.square"), for: .normal)
        controlsContainer.addSubview(addButton)

        // Settings button
        settingsButton.configuration = buttonConfig
        settingsButton.setImage(UIImage(systemName: "gear"), for: .normal)
        controlsContainer.addSubview(settingsButton)

        // Fullscreen button
        fullscreenButton.configuration = buttonConfig
        fullscreenButton.setImage(UIImage(systemName: "arrowshape.expand.fill"), for: .normal)
        controlsContainer.addSubview(fullscreenButton)

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
        [playerView, controlsContainer, progressContainer, progressTrack, progressBar, progressThumb,
         currentTimeLabel, durationLabel, playPauseButton, volumeButton, ccButton, likeButton,
         dislikeButton, addButton, settingsButton, fullscreenButton,
         loadingIndicator, errorContainerView, errorLabel, errorRetryButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: view.topAnchor),
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            // YouTube-style controls at bottom
            controlsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controlsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controlsContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            controlsContainer.heightAnchor.constraint(equalToConstant: 80),

            // Progress bar area (top of controls)
            progressContainer.leadingAnchor.constraint(equalTo: controlsContainer.leadingAnchor, constant: 16),
            progressContainer.trailingAnchor.constraint(equalTo: controlsContainer.trailingAnchor, constant: -16),
            progressContainer.topAnchor.constraint(equalTo: controlsContainer.topAnchor, constant: 8),
            progressContainer.heightAnchor.constraint(equalToConstant: 28),

            // Progress track
            progressTrack.leadingAnchor.constraint(equalTo: progressContainer.leadingAnchor, constant: 40),
            progressTrack.trailingAnchor.constraint(equalTo: progressContainer.trailingAnchor, constant: -40),
            progressTrack.centerYAnchor.constraint(equalTo: progressContainer.centerYAnchor),
            progressTrack.heightAnchor.constraint(equalToConstant: 4),

            // Progress bar fill
            progressBar.leadingAnchor.constraint(equalTo: progressTrack.leadingAnchor),
            progressBar.topAnchor.constraint(equalTo: progressTrack.topAnchor),
            progressBar.bottomAnchor.constraint(equalTo: progressTrack.bottomAnchor),

            // Progress thumb
            progressThumb.widthAnchor.constraint(equalToConstant: 12),
            progressThumb.heightAnchor.constraint(equalToConstant: 12),
            progressThumb.centerYAnchor.constraint(equalTo: progressTrack.centerYAnchor),

            // Time labels
            currentTimeLabel.leadingAnchor.constraint(equalTo: progressContainer.leadingAnchor),
            currentTimeLabel.centerYAnchor.constraint(equalTo: progressTrack.centerYAnchor),
            currentTimeLabel.widthAnchor.constraint(equalToConstant: 36),

            durationLabel.trailingAnchor.constraint(equalTo: progressContainer.trailingAnchor),
            durationLabel.centerYAnchor.constraint(equalTo: progressTrack.centerYAnchor),
            durationLabel.widthAnchor.constraint(equalToConstant: 36),

            // Buttons (bottom row)
            playPauseButton.leadingAnchor.constraint(equalTo: controlsContainer.leadingAnchor, constant: 16),
            playPauseButton.topAnchor.constraint(equalTo: progressContainer.bottomAnchor, constant: 8),
            playPauseButton.widthAnchor.constraint(equalToConstant: 32),
            playPauseButton.heightAnchor.constraint(equalToConstant: 32),

            volumeButton.leadingAnchor.constraint(equalTo: playPauseButton.trailingAnchor, constant: 8),
            volumeButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            volumeButton.widthAnchor.constraint(equalToConstant: 28),
            volumeButton.heightAnchor.constraint(equalToConstant: 28),

            ccButton.leadingAnchor.constraint(equalTo: volumeButton.trailingAnchor, constant: 8),
            ccButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            ccButton.widthAnchor.constraint(equalToConstant: 28),
            ccButton.heightAnchor.constraint(equalToConstant: 28),

            // Right side buttons
            fullscreenButton.trailingAnchor.constraint(equalTo: controlsContainer.trailingAnchor, constant: -16),
            fullscreenButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            fullscreenButton.widthAnchor.constraint(equalToConstant: 28),
            fullscreenButton.heightAnchor.constraint(equalToConstant: 28),

            settingsButton.trailingAnchor.constraint(equalTo: fullscreenButton.leadingAnchor, constant: -8),
            settingsButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            settingsButton.widthAnchor.constraint(equalToConstant: 28),
            settingsButton.heightAnchor.constraint(equalToConstant: 28),

            addButton.trailingAnchor.constraint(equalTo: settingsButton.leadingAnchor, constant: -8),
            addButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 28),
            addButton.heightAnchor.constraint(equalToConstant: 28),

            dislikeButton.trailingAnchor.constraint(equalTo: addButton.leadingAnchor, constant: -8),
            dislikeButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            dislikeButton.widthAnchor.constraint(equalToConstant: 28),
            dislikeButton.heightAnchor.constraint(equalToConstant: 28),

            likeButton.trailingAnchor.constraint(equalTo: dislikeButton.leadingAnchor, constant: -8),
            likeButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            likeButton.widthAnchor.constraint(equalToConstant: 28),
            likeButton.heightAnchor.constraint(equalToConstant: 28),

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
            self.controlsContainer.alpha = self.controlsVisible ? 1 : 0
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
                self?.controlsContainer.alpha = 0
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
                self.controlsContainer.isHidden = true

            case .loading:
                self.loadingIndicator.startAnimating()
                self.errorContainerView.isHidden = true

            case .ready:
                self.loadingIndicator.stopAnimating()
                self.controlsContainer.isHidden = false
                self.controlsContainer.alpha = 1
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
                self.controlsContainer.isHidden = true
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
        DispatchQueue.main.async {
            self.durationLabel.text = self.formatTime(duration)
        }
    }

    func playerEngine(_ engine: TVPlayerEngine, bufferingRangeDidChange range: CMTimeRange) {
        // Future: Use this for buffering UI if needed
    }

    private func updateProgressBar() {
        guard engine.duration > 0 else { return }
        let progress = engine.currentTime / engine.duration
        let progressWidth = progress * progressTrack.bounds.width

        UIView.animate(withDuration: 0.05) {
            self.progressWidthConstraint?.constant = progressWidth
            self.progressThumb.centerXAnchor.constraint(equalTo: self.progressTrack.leadingAnchor, constant: progressWidth).isActive = true
            self.view.layoutIfNeeded()
        }
    }
}

