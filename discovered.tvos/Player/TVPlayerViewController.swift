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
    private let controlsFadeView = UIView()

    private let playPauseButton = UIButton()
    private let rewindButton = UIButton()
    private let fastForwardButton = UIButton()

    private let timelineContainer = UIView()
    private let progressBar = UIView()
    private let currentTimeLabel = UILabel()
    private let durationLabel = UILabel()
    private let timelineBackground = UIView()
    private var progressWidthConstraint: NSLayoutConstraint?

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
        // Background for controls
        controlsContainer.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        controlsContainer.alpha = 1
        view.addSubview(controlsContainer)

        // Loading indicator
        loadingIndicator.color = .white
        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)

        // Play/Pause Button
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = UIColor.white.withAlphaComponent(0.3)
        config.baseForegroundColor = .white

        playPauseButton.configuration = config
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .selected)
        playPauseButton.addTarget(self, action: #selector(playPauseDidTap), for: .primaryActionTriggered)
        controlsContainer.addSubview(playPauseButton)

        // Rewind Button
        rewindButton.configuration = config
        rewindButton.setImage(UIImage(systemName: "gobackward.10"), for: .normal)
        rewindButton.addTarget(self, action: #selector(rewindDidTap), for: .primaryActionTriggered)
        controlsContainer.addSubview(rewindButton)

        // Fast Forward Button
        fastForwardButton.configuration = config
        fastForwardButton.setImage(UIImage(systemName: "goforward.10"), for: .normal)
        fastForwardButton.addTarget(self, action: #selector(fastForwardDidTap), for: .primaryActionTriggered)
        controlsContainer.addSubview(fastForwardButton)

        // Timeline Container
        timelineBackground.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        timelineBackground.layer.cornerRadius = 2
        timelineBackground.clipsToBounds = true
        controlsContainer.addSubview(timelineBackground)

        // Progress Bar
        progressBar.backgroundColor = UIColor.red.withAlphaComponent(0.8)
        progressBar.layer.cornerRadius = 2
        timelineBackground.addSubview(progressBar)

        // Time Labels
        currentTimeLabel.text = "00:00"
        currentTimeLabel.textColor = .white
        currentTimeLabel.font = .systemFont(ofSize: 12, weight: .regular)
        controlsContainer.addSubview(currentTimeLabel)

        durationLabel.text = "00:00"
        durationLabel.textColor = .white
        durationLabel.font = .systemFont(ofSize: 12, weight: .regular)
        durationLabel.textAlignment = .right
        controlsContainer.addSubview(durationLabel)

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
        [playerView, controlsContainer, loadingIndicator, errorContainerView,
         playPauseButton, rewindButton, fastForwardButton, timelineBackground,
         progressBar, currentTimeLabel, durationLabel, errorLabel, errorRetryButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: view.topAnchor),
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            controlsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controlsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controlsContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            controlsContainer.heightAnchor.constraint(equalToConstant: 180),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            rewindButton.leadingAnchor.constraint(equalTo: controlsContainer.leadingAnchor, constant: 48),
            rewindButton.centerYAnchor.constraint(equalTo: controlsContainer.centerYAnchor, constant: -20),
            rewindButton.widthAnchor.constraint(equalToConstant: 60),
            rewindButton.heightAnchor.constraint(equalToConstant: 60),

            playPauseButton.centerXAnchor.constraint(equalTo: controlsContainer.centerXAnchor),
            playPauseButton.centerYAnchor.constraint(equalTo: controlsContainer.centerYAnchor, constant: -20),
            playPauseButton.widthAnchor.constraint(equalToConstant: 80),
            playPauseButton.heightAnchor.constraint(equalToConstant: 80),

            fastForwardButton.trailingAnchor.constraint(equalTo: controlsContainer.trailingAnchor, constant: -48),
            fastForwardButton.centerYAnchor.constraint(equalTo: controlsContainer.centerYAnchor, constant: -20),
            fastForwardButton.widthAnchor.constraint(equalToConstant: 60),
            fastForwardButton.heightAnchor.constraint(equalToConstant: 60),

            timelineBackground.leadingAnchor.constraint(equalTo: controlsContainer.leadingAnchor, constant: 48),
            timelineBackground.trailingAnchor.constraint(equalTo: controlsContainer.trailingAnchor, constant: -48),
            timelineBackground.bottomAnchor.constraint(equalTo: controlsContainer.bottomAnchor, constant: -24),
            timelineBackground.heightAnchor.constraint(equalToConstant: 4),

            progressBar.leadingAnchor.constraint(equalTo: timelineBackground.leadingAnchor),
            progressBar.topAnchor.constraint(equalTo: timelineBackground.topAnchor),
            progressBar.bottomAnchor.constraint(equalTo: timelineBackground.bottomAnchor),

            currentTimeLabel.leadingAnchor.constraint(equalTo: controlsContainer.leadingAnchor, constant: 48),
            currentTimeLabel.topAnchor.constraint(equalTo: timelineBackground.bottomAnchor, constant: 8),

            durationLabel.trailingAnchor.constraint(equalTo: controlsContainer.trailingAnchor, constant: -48),
            durationLabel.topAnchor.constraint(equalTo: timelineBackground.bottomAnchor, constant: 8),

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

        let backButton = errorContainerView.subviews.last as? UIButton
        NSLayoutConstraint.activate([
            backButton!.centerXAnchor.constraint(equalTo: errorContainerView.centerXAnchor, constant: 80),
            backButton!.centerYAnchor.constraint(equalTo: errorRetryButton.centerYAnchor),
            backButton!.widthAnchor.constraint(equalToConstant: 140),
            backButton!.heightAnchor.constraint(equalToConstant: 52)
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
        [playPauseButton]
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
        let progressWidth = progress * (timelineBackground.bounds.width)

        UIView.animate(withDuration: 0.1) {
            self.progressWidthConstraint?.constant = progressWidth
            self.view.layoutIfNeeded()
        }
    }
}
