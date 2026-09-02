//
//  SideMenuItem.swift
//  discovered.tvos
//
//  Created by mac mini on 18/08/26.
//

import Foundation

enum CategoryMode: Int {
    case music = 1
    case movies = 2
    case television = 3
    case gaming = 7
    case spotlight = 8
}

struct SideMenuItemss {
    let id: Int
    let iconName: String
    let title: String
    let mode: CategoryMode?
}
