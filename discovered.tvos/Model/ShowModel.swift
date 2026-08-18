//
//  ShowModel.swift
//  discovered.tvos
//
//  Created by mac mini on 17/08/26.
//

import Foundation

// MARK: - Show Model
struct ShowItem {
    let id = UUID()
    let title: String
    let imageName: String
    let videoUrl: String?
    let description: String?
    let duration: String?
    let genre: String?
    let userName: String?
    let rating: String?
    let year: String?

    init(
        title: String,
        imageName: String,
        videoUrl: String? = nil,
        description: String? = nil,
        duration: String? = nil,
        genre: String? = nil,
        userName: String? = nil,
        rating: String? = "4.5/5",
        year: String? = "2026"
    ) {
        self.title = title
        self.imageName = imageName
        self.videoUrl = videoUrl
        self.description = description
        self.duration = duration
        self.genre = genre
        self.userName = userName
        self.rating = rating
        self.year = year
    }
}

// MARK: - Side Menu Model
struct SideMenuItem {
    let id: Int
    let iconName: String
    let title: String
}

// MARK: - Hero Content Model
struct HeroContent {
    let title: String
    let metadata: String
    let description: String
    let backgroundImageName: String
    let videoUrl: String?
    let badges: [(text: String, colorName: String)]

    init(
        title: String,
        metadata: String,
        description: String,
        backgroundImageName: String,
        videoUrl: String? = nil,
        badges: [(text: String, colorName: String)]
    ) {
        self.title = title
        self.metadata = metadata
        self.description = description
        self.backgroundImageName = backgroundImageName
        self.videoUrl = videoUrl
        self.badges = badges
    }
}
