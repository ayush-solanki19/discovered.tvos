# TVPlayer Integration Guide

## Quick Start

The player is designed to be integrated into your existing app with minimal changes.

### Basic Usage

```swift
import UIKit

// In your ViewController where you want to launch the player:

@objc private func playShowDidTap() {
    // Create the player
    let playerVC = TVPlayerViewController()
    
    // Handle dismissal
    playerVC.onDismiss = { [weak self] in
        print("Player dismissed")
    }
    
    // Pass your HLS URL and present
    let hlsURL = URL(string: "https://example.com/video/master.m3u8")!
    playerVC.play(url: hlsURL)
    
    // Present modally or use your preferred navigation
    self.present(playerVC, animated: true)
}
```

## Architecture

The player consists of three main components:

### 1. TVPlayerEngine
- Handles all AVPlayer logic
- Manages playback state, seeking, timing
- No UI knowledge
- Reusable across different UI implementations

**Public Methods:**
- `load(url:)` - Load HLS URL
- `play()` - Start playback
- `pause()` - Pause playback
- `togglePlayPause()` - Toggle between play/pause
- `seek(to:)` - Seek to specific time
- `seekForward()` - Seek forward 10 seconds
- `seekBackward()` - Seek backward 10 seconds
- `stop()` - Stop playback and release resources
- `release()` - Clean up observers (called automatically)

**Delegate Methods:**
- `playerEngine(_:stateDidChange:)` - State changes
- `playerEngine(_:currentTimeDidChange:)` - Time updates
- `playerEngine(_:durationDidChange:)` - Duration updates
- `playerEngine(_:bufferingRangeDidChange:)` - Buffering progress

### 2. TVPlayerState
State machine with support for current and future states:

**Current States:**
- `idle` - No playback
- `loading` - Preparing to play
- `ready` - Ready to play
- `playing` - Actively playing
- `paused` - Paused
- `buffering` - Buffering content
- `ended` - Playback ended
- `failed(error:)` - Playback failed

**Future States (extend easily):**
- `seeking` - Seeking in progress
- `reconnecting` - Reconnecting (for live)
- `live` - Live playback
- `behindLiveEdge` - Catching up to live

### 3. TVPlayerViewController
- Minimal UI controller
- Handles playback controls (play/pause, seek, timeline)
- Shows loading/error states
- Siri Remote compatible focus management

## Extending the Player

### Adding a new playback feature (e.g., quality selector)

1. Add state to `TVPlayerEngine` if needed
2. Add a method to control the feature
3. Add delegate callbacks if needed
4. Update UI in `TVPlayerViewController`

Example - adding playback speed:

```swift
// In TVPlayerEngine
func setPlaybackSpeed(_ rate: Float) {
    player.rate = rate
}

// In TVPlayerViewController
@objc private func speedDidChange() {
    engine.setPlaybackSpeed(1.5)
}
```

### Adding audio/subtitle tracks

1. Observe `AVPlayerItem.selectableMediaOptions`
2. Filter by `.legible` (subtitles) or `.audible` (audio)
3. Call `select()` on `AVMediaSelectionGroup`

### Adding DRM (FairPlay)

1. Set up certificate/license URLs
2. Implement `AVAssetResourceLoaderDelegate`
3. Handle DRM licensing before playing

### Adding live streaming

1. Extend `TVPlayerState` with `.live`, `.behindLiveEdge`
2. Handle duration = CMSTIME_POSITIVEINFINITY in engine
3. Add "Go Live" button to UI
4. Disable seekbar for active live content

## Future-Ready Design

The player is structured so that:

- **Playback logic stays in TVPlayerEngine** (never in the UI)
- **UI updates via delegate callbacks** (not by inspecting engine state)
- **New features don't require rewriting the core** (just extend and add)
- **State machine supports future states** (just add to enum)

This means features like quality selector, audio tracks, subtitles, DRM, analytics, etc., can be added incrementally without touching the core player.
