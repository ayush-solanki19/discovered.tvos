//
//  AppFont.swift
//  discovered.tvos
//

import SwiftUI
import UIKit

/// Single place that decides the app-wide typeface.
///
/// The font files live in `Font/` and are registered through
/// `UIAppFonts` in Info.plist.
enum AppFont {

    /// PostScript name of `Font/micross.ttf`.
    static let regularName = "MicrosoftSansSerif"

    /// PostScript name of `Font/micross-Bold.ttf`, used for
    /// semibold and heavier. `micross.ttf` only ships a Regular face,
    /// so this one is a synthetic bold generated from it.
    static let boldName: String? = "MicrosoftSansSerif-Bold"

    static func name(for weight: UIFont.Weight) -> String {
        if weight.rawValue >= UIFont.Weight.semibold.rawValue,
           let boldName {
            return boldName
        }
        return regularName
    }
}

extension UIFont {

    /// Drop-in replacement for `UIFont.systemFont(ofSize:weight:)`.
    static func appFont(
        ofSize size: CGFloat,
        weight: UIFont.Weight = .regular
    ) -> UIFont {
        UIFont(name: AppFont.name(for: weight), size: size)
            ?? .systemFont(ofSize: size, weight: weight)
    }
}

extension Font {

    /// Drop-in replacement for SwiftUI's `.system(size:weight:)`.
    static func app(
        size: CGFloat,
        weight: UIFont.Weight = .regular
    ) -> Font {
        .custom(AppFont.name(for: weight), fixedSize: size)
    }
}
