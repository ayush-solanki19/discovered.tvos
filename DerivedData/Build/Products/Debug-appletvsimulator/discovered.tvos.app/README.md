# TVPlayer - Minimal Future-Ready Video Player for tvOS

A lightweight, native Swift/UIKit video player for tvOS that plays HLS streams with a clean, minimal UI. Designed to be extended with features later without architectural changes.

## What's Included

### Core Player Components

**1. TVPlayerEngine** (`TVPlayerEngine.swift`)
- Manages all AVPlayer logic
- Independent of UI
- Handles playback states, seeking, timing, and error detection
- Notifies delegate of state changes via callbacks
- Automatically cleans up observers and resources

**2. TVPlayerViewController** (`TVPlayerViewController.swift`)
- Minimal playback UI with basic controls
- Play/Pause, Seek Forward/Backward (10 seconds)
- Visual timeline with progress indicator
- Loading indicator for buffering
- Error state with retry option
- Native tvOS Siri Remote support
- Auto-hiding controls (5 seconds after playback starts)

**3. TVPlayerState** (`TVPlayerState.swift`)
- State machine enum
- Supports current and future states without refactoring
- Includes error handling

## Quick Start

### 1. Present the Player

```swift
import UIKit

class YourViewController: UIViewController {
    
    @objc private func playShow() {
        let playerVC = TVPlayerViewController()
        
        playerVC.onDismiss = { [weak self] in
            // Handle any cleanup or tracking after player closes
        }
        
        let hlsURL = URL(string: "https://example.com/video/master.m3u8")!
        playerVC.play(url: hlsURL)
        
        self.present(playerVC, animated: true)
    }
}
```

### 2. Test with Sample HLS

For testing, use this public test stream:
```swift
let testURL = URL(string: "https://test-streams.mux.dev/x36xhzz/x3ysqsyx/media.m3u8")!
```

## Features

### Current MVP (Implemented ✓)

- ✓ HLS `.m3u8` playback
- ✓ Play/Pause
- ✓ Seek forward/backward (10 seconds)
- ✓ Visual timeline with current position
- ✓ Duration display
- ✓ Buffering indicator
- ✓ Playback error handling
- ✓ Full-screen video display
- ✓ Siri Remote controls
- ✓ Clean dismissal

### Not Implemented (Available for Future)

- Quality selector (bitrate/resolution)
- Audio track selection
- Subtitle/closed caption selection
- DVR / time shifting
- Live streaming (go live button, behind live edge)
- Next video / autoplay
- Playback speed
- DRM / FairPlay
- Ads
- Analytics / QoE reporting
- Skip intro / skip recap
- Chapters

## Architecture

```
Your App (ViewController)
    ↓ creates & presents
TVPlayerViewController
    ↓ owns & delegates to
TVPlayerEngine
    ↓ manages
AVPlayer
    ↓ plays
HLS Stream (.m3u8)
```

### Design Principles

- **Separation of Concerns**: UI knows nothing about AVPlayer or KVO
- **Delegate Pattern**: Engine notifies UI of state changes
- **Resource Cleanup**: Observers and timers properly released
- **Future-Ready**: State machine and delegate methods support new features
- **No Over-Engineering**: Only implements MVP, no empty managers

## Extending the Player

### Add a New Feature

1. Identify if you need new state → add to `TVPlayerState`
2. Add method to `TVPlayerEngine`
3. Add delegate callback if UI needs to react
4. Update UI in `TVPlayerViewController`

### Example: Add Playback Speed

```swift
// In TVPlayerEngine
func setPlaybackSpeed(_ rate: Float) {
    player.rate = rate
}

// In TVPlayerViewController
@objc private func speedButtonTapped() {
    engine.setPlaybackSpeed(1.5)
}
```

### Example: Add Audio Track Selection

```swift
// In TVPlayerEngine
func getAvailableAudioTracks() -> [AVMediaSelectionOption] {
    guard let asset = player.currentItem?.asset else { return [] }
    guard let group = asset.mediaSelectionGroup(forMediaCharacteristic: .audible) else { return [] }
    return group.options
}

func selectAudioTrack(_ option: AVMediaSelectionOption) {
    player.currentItem?.select(option, in: group)
}
```

## Lifecycle

### Player Initialization
```swift
let playerVC = TVPlayerViewController()
// Engine created automatically
// Observers set up
// UI configured
```

### Loading Content
```swift
playerVC.play(url: hlsURL)
// Engine.load() called
// Asset created, playerItem created
// playerItem observers set up
// Player item replaces current item
// Playback readiness observed
```

### Playback States
- `idle` → `loading` → `ready` → `playing`
- During playback: `paused`, `buffering`, `ended`
- Error state: `failed(error: TVPlayerError)`

### Cleanup
- Automatic when ViewController disappears
- All KVO observers removed
- Time observer removed
- Timers invalidated
- Player stopped

## tvOS Considerations

### Siri Remote Support
- Play/Pause: Press touch pad center or Menu
- Seek: Use left/right on touch pad
- Menu: Exits player

### Focus Management
- Play button receives initial focus
- All buttons focusable for tvOS
- Navigation via Siri Remote directional pad

### Full-Screen Playback
- Player fills entire screen
- Controls overlay at bottom with fade out
- Auto-hide controls after 5 seconds during playback

## Testing

### Local Test Stream
```swift
let url = URL(string: "https://test-streams.mux.dev/x36xhzz/x3ysqsyx/media.m3u8")!
playerVC.play(url: url)
```

### Test Scenarios
1. Play and pause multiple times
2. Seek forward/backward
3. Check timeline updates smoothly
4. Dismiss and reopen
5. Test error handling with invalid URL

## Future Enhancement Ideas

When you're ready to extend:

- **Quality Selection**: Query `AVPlayerItem` for variant streams
- **Captions**: Use `AVMediaSelectionGroup` with `.legible` characteristic
- **Live Streams**: Detect duration = infinity, add live indicator
- **DRM**: Implement `AVAssetResourceLoaderDelegate`
- **Analytics**: Add events in delegate methods
- **Recommendations**: Add "Next" UI in dismissal callback
- **Continue Watching**: Track and pass last playback position

## Notes

- No SwiftUI (uses UIKit as requested)
- No external dependencies
- Follows your app's MVVM + UIKit conventions
- Dark theme only (matches your app)
- tvOS 16+ compatible

## Project Structure

```
Player/
├── TVPlayerState.swift         # State machine + errors
├── TVPlayerEngine.swift        # Playback engine
├── TVPlayerViewController.swift # UI & controls
├── INTEGRATION.md              # Integration guide
├── EXAMPLE_INTEGRATION.swift   # Usage examples
└── README.md                   # This file
```

## Next Steps

1. Ensure the 4 Swift files are in your Xcode project
2. Update your existing ViewController to call `presentVideoPlayer()`
3. Pass HLS URLs to the player
4. Test playback with Siri Remote
5. When ready, extend with new features
