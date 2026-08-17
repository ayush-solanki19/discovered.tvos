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
    let badges: [(text: String, colorName: String)]
}
