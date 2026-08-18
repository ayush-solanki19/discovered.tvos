//
//  TVPlayerState.swift
//  discovered.tvos
//
//  Created by Claude Code
//

import Foundation

enum TVPlayerState: Equatable {
    case idle
    case loading
    case ready
    case playing
    case paused
    case buffering
    case ended
    case failed(error: TVPlayerError)
}

enum TVPlayerError: Error, Equatable {
    case invalidURL
    case playerSetupFailed
    case playbackFailed(String)
    case unknown
}
