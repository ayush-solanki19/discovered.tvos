//
//  TVPlayerEngine.swift
//  discovered.tvos
//
//  Created by Claude Code
//

import AVFoundation

protocol TVPlayerEngineDelegate: AnyObject {
    func playerEngine(_ engine: TVPlayerEngine, stateDidChange newState: TVPlayerState)
    func playerEngine(_ engine: TVPlayerEngine, currentTimeDidChange time: TimeInterval)
    func playerEngine(_ engine: TVPlayerEngine, durationDidChange duration: TimeInterval)
    func playerEngine(_ engine: TVPlayerEngine, bufferingRangeDidChange range: CMTimeRange)
}

class TVPlayerEngine: NSObject {

    // MARK: - Properties
    weak var delegate: TVPlayerEngineDelegate?

    private(set) var player: AVPlayer
    private(set) var state: TVPlayerState = .idle {
        didSet {
            guard state as? AnyHashable != oldValue as? AnyHashable else { return }
            delegate?.playerEngine(self, stateDidChange: state)
        }
    }

    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0

    private var timeObserver: Any?
    private var statusObservation: NSKeyValueObservation?
    private var durationObservation: NSKeyValueObservation?
    private var bufferingObservation: NSKeyValueObservation?
    private var rateObservation: NSKeyValueObservation?

    private let seekInterval: TimeInterval = 10.0

    // MARK: - Init
    override init() {
        self.player = AVPlayer()
        super.init()
        setupPlayerObservers()
    }

    // MARK: - Setup
    private func setupPlayerObservers() {
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.1, preferredTimescale: 1000),
            queue: .main
        ) { [weak self] time in
            self?.currentTime = time.seconds
            self?.delegate?.playerEngine(self!, currentTimeDidChange: time.seconds)
        }

        rateObservation = player.observe(\.rate, options: [.new, .old]) { [weak self] player, change in
            guard let self = self else { return }

            let rate = player.rate
            if rate == 0 && self.state == .playing {
                if player.currentItem?.status == .readyToPlay {
                    self.state = .paused
                }
            } else if rate > 0 {
                self.state = .playing
            }
        }
    }

    // MARK: - Public Methods
    func load(url: URL) {
        state = .loading

        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)

        observePlayerItem(playerItem)
        player.replaceCurrentItem(with: playerItem)
    }

    func play() {
        player.play()
    }

    func pause() {
        player.pause()
    }

    func togglePlayPause() {
        if player.rate > 0 {
            pause()
        } else {
            play()
        }
    }

    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 1000)
        player.seek(to: cmTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
    }

    func seekForward(seconds: TimeInterval? = nil) {
        let interval = seconds ?? seekInterval
        let newTime = currentTime + interval
        let maxTime = min(newTime, duration)
        seek(to: maxTime)
    }

    func seekBackward(seconds: TimeInterval? = nil) {
        let interval = seconds ?? seekInterval
        let newTime = max(currentTime - interval, 0)
        seek(to: newTime)
    }

    func stop() {
        player.pause()
        seek(to: 0)
        state = .idle
    }

    func release() {
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
        }

        statusObservation?.invalidate()
        durationObservation?.invalidate()
        bufferingObservation?.invalidate()
        rateObservation?.invalidate()
    }

    // MARK: - Private Methods
    private func observePlayerItem(_ item: AVPlayerItem) {
        statusObservation?.invalidate()
        bufferingObservation?.invalidate()

        statusObservation = item.observe(\.status, options: [.new, .old]) { [weak self] playerItem, change in
            guard let self = self else { return }

            switch playerItem.status {
            case .readyToPlay:
                self.updateDuration(from: playerItem)
                self.state = .ready

            case .failed:
                let error = playerItem.error ?? TVPlayerError.playbackFailed("Unknown error")
                self.state = .failed(error: error as? TVPlayerError ?? TVPlayerError.playbackFailed(playerItem.error?.localizedDescription ?? "Unknown"))

            case .unknown:
                break
            @unknown default:
                break
            }
        }

        durationObservation = item.observe(\.duration, options: [.initial, .new]) { [weak self] playerItem, _ in
            self?.updateDuration(from: playerItem)
        }

        bufferingObservation = item.observe(\.loadedTimeRanges, options: [.new]) { [weak self] playerItem, change in
            guard let self = self else { return }

            if let timeRange = playerItem.loadedTimeRanges.first?.timeRangeValue {
                self.delegate?.playerEngine(self, bufferingRangeDidChange: timeRange)
            }
        }
    }

    private func updateDuration(from item: AVPlayerItem) {
        let value = item.duration.seconds
        guard value.isFinite, value >= 0, value != duration else { return }

        duration = value
        delegate?.playerEngine(self, durationDidChange: value)
    }

    deinit {
        release()
    }
}
