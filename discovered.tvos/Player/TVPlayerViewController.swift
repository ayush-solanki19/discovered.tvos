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
    private let topControlsView = UIView()
    private let controlsButtonsView = UIView()
    private let timelineView = UIView()
    private let suggestionsView = UIView()

    private let backButton = UIButton()
    private let playPauseButton = UIButton()
    private let rewindButton = UIButton()
    private let fastForwardButton = UIButton()

    private let progressBar = UIView()
    private let currentTimeLabel = UILabel()
    private let durationLabel = UILabel()
    private let timelineBackground = UIView()
    private var progressWidthConstraint: NSLayoutConstraint?

    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let errorContainerView = UIView()
    private let errorLabel = UILabel()
    private let errorRetryButton = UIButton()

    private var relatedVideosCollectionView: UICollectionView!
    private var relatedVideos: [RelatedVideo] = []

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
        fetchRelatedVideos()
    }

    private func fetchRelatedVideos() {
        let boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW"
        var body = ""
        body += "--\(boundary)\r\n"
        body += "Content-Disposition: form-data; name=\"uid\"\r\n\r\n"
        body += "215\r\n"
        body += "--\(boundary)\r\n"
        body += "Content-Disposition: form-data; name=\"start\"\r\n\r\n"
        body += "0\r\n"
        body += "--\(boundary)\r\n"
        body += "Content-Disposition: form-data; name=\"limit\"\r\n\r\n"
        body += "20\r\n"
        body += "--\(boundary)--\r\n"

        var request = URLRequest(url: URL(string: "https://discovered.tv/api/v3/appdashboard/get_related_video")!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("TIZEN", forHTTPHeaderField: "device")
        request.httpBody = body.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data, error == nil else { return }

            do {
                let response = try JSONDecoder().decode(RelatedVideoResponse.self, from: data)
                self?.relatedVideos = response.related_video.slider
                DispatchQueue.main.async {
                    self?.relatedVideosCollectionView.reloadData()
                }
            } catch {
                print("Error decoding related videos: \(error)")
            }
        }.resume()
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
        // Main Controls Container
        controlsContainer.backgroundColor = .clear
        controlsContainer.alpha = 1
        view.addSubview(controlsContainer)

        // Loading indicator
        loadingIndicator.color = .white
        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)

        // Top Controls View (Back Button)
        topControlsView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        controlsContainer.addSubview(topControlsView)

        var topConfig = UIButton.Configuration.filled()
        topConfig.baseBackgroundColor = UIColor.white.withAlphaComponent(0.3)
        topConfig.baseForegroundColor = .white
        backButton.configuration = topConfig
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.addTarget(self, action: #selector(dismissDidTap), for: .primaryActionTriggered)
        topControlsView.addSubview(backButton)

        // Control Buttons View
        controlsButtonsView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        controlsContainer.addSubview(controlsButtonsView)

        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = UIColor.white.withAlphaComponent(0.3)
        config.baseForegroundColor = .white

        playPauseButton.configuration = config
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .selected)
        playPauseButton.addTarget(self, action: #selector(playPauseDidTap), for: .primaryActionTriggered)
        controlsButtonsView.addSubview(playPauseButton)

        rewindButton.configuration = config
        rewindButton.setImage(UIImage(systemName: "gobackward.10"), for: .normal)
        rewindButton.addTarget(self, action: #selector(rewindDidTap), for: .primaryActionTriggered)
        controlsButtonsView.addSubview(rewindButton)

        fastForwardButton.configuration = config
        fastForwardButton.setImage(UIImage(systemName: "goforward.10"), for: .normal)
        fastForwardButton.addTarget(self, action: #selector(fastForwardDidTap), for: .primaryActionTriggered)
        controlsButtonsView.addSubview(fastForwardButton)

        // Timeline View
        timelineView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        controlsContainer.addSubview(timelineView)

        timelineBackground.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        timelineBackground.layer.cornerRadius = 2
        timelineBackground.clipsToBounds = true
        timelineView.addSubview(timelineBackground)

        progressBar.backgroundColor = UIColor.red.withAlphaComponent(0.8)
        progressBar.layer.cornerRadius = 2
        timelineBackground.addSubview(progressBar)

        currentTimeLabel.text = "00:00"
        currentTimeLabel.textColor = .white
        currentTimeLabel.font = .systemFont(ofSize: 12, weight: .regular)
        timelineView.addSubview(currentTimeLabel)

        durationLabel.text = "00:00"
        durationLabel.textColor = .white
        durationLabel.font = .systemFont(ofSize: 12, weight: .regular)
        durationLabel.textAlignment = .right
        timelineView.addSubview(durationLabel)

        // Suggestions View with Grid
        suggestionsView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        controlsContainer.addSubview(suggestionsView)

        let gridLayout = UICollectionViewFlowLayout()
        gridLayout.scrollDirection = .vertical
        gridLayout.itemSize = CGSize(width: 140, height: 250)
        gridLayout.minimumLineSpacing = 12
        gridLayout.minimumInteritemSpacing = 16
        gridLayout.sectionInset = UIEdgeInsets(top: 16, left: 24, bottom: 16, right: 24)

        relatedVideosCollectionView = UICollectionView(frame: .zero, collectionViewLayout: gridLayout)
        relatedVideosCollectionView.backgroundColor = .clear
        relatedVideosCollectionView.showsVerticalScrollIndicator = false
        relatedVideosCollectionView.showsHorizontalScrollIndicator = false
        relatedVideosCollectionView.dataSource = self
        relatedVideosCollectionView.delegate = self
        relatedVideosCollectionView.clipsToBounds = true
        relatedVideosCollectionView.register(RelatedVideoGridCell.self, forCellWithReuseIdentifier: RelatedVideoGridCell.reuseIdentifier)
        suggestionsView.addSubview(relatedVideosCollectionView)

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
        [playerView, controlsContainer, topControlsView, controlsButtonsView, timelineView, suggestionsView,
         loadingIndicator, errorContainerView,
         backButton, playPauseButton, rewindButton, fastForwardButton, timelineBackground,
         progressBar, currentTimeLabel, durationLabel, relatedVideosCollectionView,
         errorLabel, errorRetryButton].forEach {
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
            controlsContainer.heightAnchor.constraint(equalToConstant: 600),

            // Top Controls View
            topControlsView.topAnchor.constraint(equalTo: controlsContainer.topAnchor),
            topControlsView.leadingAnchor.constraint(equalTo: controlsContainer.leadingAnchor),
            topControlsView.trailingAnchor.constraint(equalTo: controlsContainer.trailingAnchor),
            topControlsView.heightAnchor.constraint(equalToConstant: 80),

            backButton.leadingAnchor.constraint(equalTo: topControlsView.leadingAnchor, constant: 24),
            backButton.centerYAnchor.constraint(equalTo: topControlsView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 50),
            backButton.heightAnchor.constraint(equalToConstant: 50),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            // Control Buttons View
            controlsButtonsView.topAnchor.constraint(equalTo: topControlsView.bottomAnchor),
            controlsButtonsView.leadingAnchor.constraint(equalTo: controlsContainer.leadingAnchor),
            controlsButtonsView.trailingAnchor.constraint(equalTo: controlsContainer.trailingAnchor),
            controlsButtonsView.heightAnchor.constraint(equalToConstant: 140),

            rewindButton.leadingAnchor.constraint(equalTo: controlsButtonsView.leadingAnchor, constant: 48),
            rewindButton.centerYAnchor.constraint(equalTo: controlsButtonsView.centerYAnchor),
            rewindButton.widthAnchor.constraint(equalToConstant: 60),
            rewindButton.heightAnchor.constraint(equalToConstant: 60),

            playPauseButton.centerXAnchor.constraint(equalTo: controlsButtonsView.centerXAnchor),
            playPauseButton.centerYAnchor.constraint(equalTo: controlsButtonsView.centerYAnchor),
            playPauseButton.widthAnchor.constraint(equalToConstant: 80),
            playPauseButton.heightAnchor.constraint(equalToConstant: 80),

            fastForwardButton.trailingAnchor.constraint(equalTo: controlsButtonsView.trailingAnchor, constant: -48),
            fastForwardButton.centerYAnchor.constraint(equalTo: controlsButtonsView.centerYAnchor),
            fastForwardButton.widthAnchor.constraint(equalToConstant: 60),
            fastForwardButton.heightAnchor.constraint(equalToConstant: 60),

            // Timeline View
            timelineView.topAnchor.constraint(equalTo: controlsButtonsView.bottomAnchor),
            timelineView.leadingAnchor.constraint(equalTo: controlsContainer.leadingAnchor),
            timelineView.trailingAnchor.constraint(equalTo: controlsContainer.trailingAnchor),
            timelineView.heightAnchor.constraint(equalToConstant: 60),

            timelineBackground.leadingAnchor.constraint(equalTo: timelineView.leadingAnchor, constant: 48),
            timelineBackground.trailingAnchor.constraint(equalTo: timelineView.trailingAnchor, constant: -48),
            timelineBackground.centerYAnchor.constraint(equalTo: timelineView.centerYAnchor, constant: -8),
            timelineBackground.heightAnchor.constraint(equalToConstant: 4),

            progressBar.leadingAnchor.constraint(equalTo: timelineBackground.leadingAnchor),
            progressBar.topAnchor.constraint(equalTo: timelineBackground.topAnchor),
            progressBar.bottomAnchor.constraint(equalTo: timelineBackground.bottomAnchor),

            currentTimeLabel.leadingAnchor.constraint(equalTo: timelineView.leadingAnchor, constant: 48),
            currentTimeLabel.topAnchor.constraint(equalTo: timelineBackground.bottomAnchor, constant: 8),

            durationLabel.trailingAnchor.constraint(equalTo: timelineView.trailingAnchor, constant: -48),
            durationLabel.topAnchor.constraint(equalTo: timelineBackground.bottomAnchor, constant: 8),

            // Suggestions View
            suggestionsView.topAnchor.constraint(equalTo: timelineView.bottomAnchor),
            suggestionsView.leadingAnchor.constraint(equalTo: controlsContainer.leadingAnchor),
            suggestionsView.trailingAnchor.constraint(equalTo: controlsContainer.trailingAnchor),
            suggestionsView.bottomAnchor.constraint(equalTo: controlsContainer.bottomAnchor),

            relatedVideosCollectionView.topAnchor.constraint(equalTo: suggestionsView.topAnchor),
            relatedVideosCollectionView.leadingAnchor.constraint(equalTo: suggestionsView.leadingAnchor),
            relatedVideosCollectionView.trailingAnchor.constraint(equalTo: suggestionsView.trailingAnchor),
            relatedVideosCollectionView.bottomAnchor.constraint(equalTo: suggestionsView.bottomAnchor),

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

// MARK: - CollectionView DataSource & Delegate
extension TVPlayerViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return relatedVideos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RelatedVideoGridCell.reuseIdentifier, for: indexPath) as! RelatedVideoGridCell
        let video = relatedVideos[indexPath.item]
        cell.configure(with: video)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let video = relatedVideos[indexPath.item]
        if let url = URL(string: video.videoFile) {
            play(url: url)
        }
    }
}
