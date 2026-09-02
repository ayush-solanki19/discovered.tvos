//
//  PremiumPlayerColors.swift
//  discovered.tvos
//
//  Premium color scheme for the Apple TV player
//

import SwiftUI

extension Color {
    // Brand colors
    static let premiumOrange = Color(red: 1, green: 0.42, blue: 0.21) // #ff6b35
    static let premiumOrangeDark = Color(red: 1, green: 0.55, blue: 0.35) // #ff8c5a

    // Backgrounds
    static let darkBg = Color(red: 0.04, green: 0.055, blue: 0.16) // #0a0e27
    static let darkBgGradient = Color(red: 0.06, green: 0.09, blue: 0.16) // #0f1626

    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.88, green: 0.88, blue: 0.88) // #e0e0e0
    static let gray2 = Color(red: 0.53, green: 0.53, blue: 0.53) // #888888

    // Overlay
    static let overlayLight = Color(red: 1, green: 1, blue: 1, opacity: 0.08)
    static let overlayMedium = Color(red: 1, green: 1, blue: 1, opacity: 0.12)
    static let overlayDark = Color.black.opacity(0.6)
}
