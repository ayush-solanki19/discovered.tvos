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

    private let controlsOverlay = UIView()
    private let scrubberContainer = UIView()
    private let scrubberTrack = UIView()
    private let scrubberFill = UIView()
    private let scrubberThumb = UIView()
    private var scrubberWidthConstraint: NSLayoutConstraint?

    private let timeLabel = UILabel()
    private let durationLabel = UILabel()

    private let playButton = UIButton()
    private let backwardButton = UIButton()
    private let forwardButton = UIButton()
    private let volumeButton = UIButton()
    private let captionsButton = UIButton()
    private let settingsButton = UIButton()
    private let fullscreenButton = UIButton()

    private let titleLabel = UILabel()

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
        playButton.isSelected = true
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

        // Modern Controls Overlay at bottom
        controlsOverlay.backgroundColor = UIColor(white: 0, alpha: 0.6)
        controlsOverlay.alpha = 1
        view.addSubview(controlsOverlay)

        // Scrubber/Timeline bar (top of controls)
        scrubberContainer.backgroundColor = .clear
        controlsOverlay.addSubview(scrubberContainer)

        scrubberTrack.backgroundColor = UIColor(white: 1, alpha: 0.25)
        scrubberTrack.layer.cornerRadius = 1.5
        scrubberTrack.clipsToBounds = true
        scrubberContainer.addSubview(scrubberTrack)

        scrubberFill.backgroundColor = UIColor(red: 1, green: 0.2, blue: 0.2, alpha: 1)
        scrubberFill.layer.cornerRadius = 1.5
        scrubberTrack.addSubview(scrubberFill)

        scrubberThumb.backgroundColor = .white
        scrubberThumb.layer.cornerRadius = 5
        scrubberThumb.clipsToBounds = true
        scrubberContainer.addSubview(scrubberThumb)

        // Time labels
        timeLabel.text = "0:00"
        timeLabel.textColor = UIColor(white: 1, alpha: 0.9)
        timeLabel.font = .systemFont(ofSize: 11, weight: .medium)
        scrubberContainer.addSubview(timeLabel)

        durationLabel.text = "0:00"
        durationLabel.textColor = UIColor(white: 1, alpha: 0.9)
        durationLabel.font = .systemFont(ofSize: 11, weight: .medium)
        durationLabel.textAlignment = .right
        scrubberContainer.addSubview(durationLabel)

        // Title label (top of overlay for context)
        titleLabel.text = "Video"
        titleLabel.textColor = UIColor(white: 1, alpha: 0.95)
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.numberOfLines = 1
        controlsOverlay.addSubview(titleLabel)

        // Button configuration - Clean, minimal style
        var buttonConfig = UIButton.Configuration.plain()
        buttonConfig.baseForegroundColor = UIColor(white: 1, alpha: 0.9)
        buttonConfig.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)

        // Backward button (skip back)
        backwardButton.configuration = buttonConfig
        backwardButton.setImage(UIImage(systemName: "gobackward.10"), for: .normal)
        backwardButton.addTarget(self, action: #selector(rewindDidTap), for: .primaryActionTriggered)
        controlsOverlay.addSubview(backwardButton)

        // Play/Pause button (centered, largest)
        playButton.configuration = buttonConfig
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.setImage(UIImage(systemName: "pause.fill"), for: .selected)
        playButton.addTarget(self, action: #selector(playPauseDidTap), for: .primaryActionTriggered)
        controlsOverlay.addSubview(playButton)

        // Forward button (skip forward)
        forwardButton.configuration = buttonConfig
        forwardButton.setImage(UIImage(systemName: "goforward.10"), for: .normal)
        forwardButton.addTarget(self, action: #selector(fastForwardDidTap), for: .primaryActionTriggered)
        controlsOverlay.addSubview(forwardButton)

        // Right side controls
        volumeButton.configuration = buttonConfig
        volumeButton.setImage(UIImage(systemName: "speaker.wave.2"), for: .normal)
        controlsOverlay.addSubview(volumeButton)

        captionsButton.configuration = buttonConfig
        captionsButton.setImage(UIImage(systemName: "captions.bubble"), for: .normal)
        controlsOverlay.addSubview(captionsButton)

        settingsButton.configuration = buttonConfig
        settingsButton.setImage(UIImage(systemName: "gearshape"), for: .normal)
        controlsOverlay.addSubview(settingsButton)

        fullscreenButton.configuration = buttonConfig
        fullscreenButton.setImage(UIImage(systemName: "arrowshape.expand"), for: .normal)
        controlsOverlay.addSubview(fullscreenButton)

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
        [playerView, controlsOverlay, scrubberContainer, scrubberTrack, scrubberFill, scrubberThumb,
         timeLabel, durationLabel, titleLabel, playButton, backwardButton, forwardButton,
         volumeButton, captionsButton, settingsButton, fullscreenButton,
         loadingIndicator, errorContainerView, errorLabel, errorRetryButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            // Player view
            playerView.topAnchor.constraint(equalTo: view.topAnchor),
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            // Modern controls overlay at bottom
            controlsOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controlsOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controlsOverlay.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            controlsOverlay.heightAnchor.constraint(equalToConstant: 100),

            // Title (top of overlay)
            titleLabel.leadingAnchor.constraint(equalTo: controlsOverlay.leadingAnchor, constant: 20),
            titleLabel.topAnchor.constraint(equalTo: controlsOverlay.topAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: controlsOverlay.trailingAnchor, constant: -20),

            // Scrubber container
            scrubberContainer.leadingAnchor.constraint(equalTo: controlsOverlay.leadingAnchor, constant: 20),
            scrubberContainer.trailingAnchor.constraint(equalTo: controlsOverlay.trailingAnchor, constant: -20),
            scrubberContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            scrubberContainer.heightAnchor.constraint(equalToConstant: 20),

            // Scrubber track
            scrubberTrack.leadingAnchor.constraint(equalTo: scrubberContainer.leadingAnchor, constant: 30),
            scrubberTrack.trailingAnchor.constraint(equalTo: scrubberContainer.trailingAnchor, constant: -30),
            scrubberTrack.centerYAnchor.constraint(equalTo: scrubberContainer.centerYAnchor, constant: -2),
            scrubberTrack.heightAnchor.constraint(equalToConstant: 3),

            // Scrubber fill
            scrubberFill.leadingAnchor.constraint(equalTo: scrubberTrack.leadingAnchor),
            scrubberFill.topAnchor.constraint(equalTo: scrubberTrack.topAnchor),
            scrubberFill.bottomAnchor.constraint(equalTo: scrubberTrack.bottomAnchor),

            // Scrubber thumb
            scrubberThumb.widthAnchor.constraint(equalToConstant: 10),
            scrubberThumb.heightAnchor.constraint(equalToConstant: 10),
            scrubberThumb.centerYAnchor.constraint(equalTo: scrubberTrack.centerYAnchor),

            // Time labels
            timeLabel.leadingAnchor.constraint(equalTo: scrubberContainer.leadingAnchor),
            timeLabel.centerYAnchor.constraint(equalTo: scrubberTrack.centerYAnchor),
            timeLabel.widthAnchor.constraint(equalToConstant: 28),

            durationLabel.trailingAnchor.constraint(equalTo: scrubberContainer.trailingAnchor),
            durationLabel.centerYAnchor.constraint(equalTo: scrubberTrack.centerYAnchor),
            durationLabel.widthAnchor.constraint(equalToConstant: 28),

            // Playback buttons (centered)
            backwardButton.centerXAnchor.constraint(equalTo: controlsOverlay.centerXAnchor, constant: -60),
            backwardButton.topAnchor.constraint(equalTo: scrubberContainer.bottomAnchor, constant: 12),
            backwardButton.widthAnchor.constraint(equalToConstant: 40),
            backwardButton.heightAnchor.constraint(equalToConstant: 40),

            playButton.centerXAnchor.constraint(equalTo: controlsOverlay.centerXAnchor),
            playButton.topAnchor.constraint(equalTo: scrubberContainer.bottomAnchor, constant: 8),
            playButton.widthAnchor.constraint(equalToConstant: 48),
            playButton.heightAnchor.constraint(equalToConstant: 48),

            forwardButton.centerXAnchor.constraint(equalTo: controlsOverlay.centerXAnchor, constant: 60),
            forwardButton.topAnchor.constraint(equalTo: scrubberContainer.bottomAnchor, constant: 12),
            forwardButton.widthAnchor.constraint(equalToConstant: 40),
            forwardButton.heightAnchor.constraint(equalToConstant: 40),

            // Right side controls
            volumeButton.trailingAnchor.constraint(equalTo: controlsOverlay.trailingAnchor, constant: -16),
            volumeButton.centerYAnchor.constraint(equalTo: playButton.centerYAnchor),
            volumeButton.widthAnchor.constraint(equalToConstant: 36),
            volumeButton.heightAnchor.constraint(equalToConstant: 36),

            captionsButton.trailingAnchor.constraint(equalTo: volumeButton.leadingAnchor, constant: -8),
            captionsButton.centerYAnchor.constraint(equalTo: playButton.centerYAnchor),
            captionsButton.widthAnchor.constraint(equalToConstant: 36),
            captionsButton.heightAnchor.constraint(equalToConstant: 36),

            settingsButton.trailingAnchor.constraint(equalTo: captionsButton.leadingAnchor, constant: -8),
            settingsButton.centerYAnchor.constraint(equalTo: playButton.centerYAnchor),
            settingsButton.widthAnchor.constraint(equalToConstant: 36),
            settingsButton.heightAnchor.constraint(equalToConstant: 36),

            fullscreenButton.trailingAnchor.constraint(equalTo: settingsButton.leadingAnchor, constant: -8),
            fullscreenButton.centerYAnchor.constraint(equalTo: playButton.centerYAnchor),
            fullscreenButton.widthAnchor.constraint(equalToConstant: 36),
            fullscreenButton.heightAnchor.constraint(equalToConstant: 36),

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

        scrubberWidthConstraint = scrubberFill.widthAnchor.constraint(equalToConstant: 0)
        scrubberWidthConstraint?.isActive = true
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
            self.controlsOverlay.alpha = self.controlsVisible ? 1 : 0
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
                self?.controlsOverlay.alpha = 0
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
        controlsVisible ? [playButton] : [playerView]
    }
}

// MARK: - TVPlayerEngineDelegate
extension TVPlayerViewController: TVPlayerEngineDelegate {
    func playerEngine(_ engine: TVPlayerEngine, stateDidChange newState: TVPlayerState) {
        DispatchQueue.main.async {
            switch newState {
            case .idle:
                self.loadingIndicator.stopAnimating()
                self.controlsOverlay.isHidden = true

            case .loading:
                self.loadingIndicator.startAnimating()
                self.errorContainerView.isHidden = true

            case .ready:
                self.loadingIndicator.stopAnimating()
                self.controlsOverlay.isHidden = false
                self.controlsOverlay.alpha = 1
                self.controlsVisible = true

            case .playing:
                self.playButton.isSelected = true
                self.resetControlsHideTimer()

            case .paused:
                self.playButton.isSelected = false
                self.controlsHideTimer?.invalidate()

            case .buffering:
                self.loadingIndicator.startAnimating()

            case .ended:
                self.playButton.isSelected = false

            case .failed(let error):
                self.loadingIndicator.stopAnimating()
                self.controlsOverlay.isHidden = true
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
            self.timeLabel.text = self.formatTime(time)
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
        let progressWidth = progress * scrubberTrack.bounds.width

        UIView.animate(withDuration: 0.05) {
            self.scrubberWidthConstraint?.constant = progressWidth
            self.scrubberThumb.centerXAnchor.constraint(equalTo: self.scrubberTrack.leadingAnchor, constant: progressWidth).isActive = true
            self.view.layoutIfNeeded()
        }
    }
}

