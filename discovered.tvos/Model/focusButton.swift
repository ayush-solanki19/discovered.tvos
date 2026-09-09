//
//  focusButton.swift
//  discovered.tvos
//
//  Created by mac mini on 07/09/26.
//

import Foundation
import UIKit

final class FocusButton: UIButton {

    var onFocusChanged: ((Bool) -> Void)?

    override func didUpdateFocus(
        in context: UIFocusUpdateContext,
        with coordinator: UIFocusAnimationCoordinator
    ) {
        super.didUpdateFocus(
            in: context,
            with: coordinator
        )

        let isFocused = (context.nextFocusedView === self)

        coordinator.addCoordinatedAnimations {

            self.onFocusChanged?(isFocused)

        }
    }
}
