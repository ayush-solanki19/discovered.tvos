import UIKit

// MARK: - Shared Loading Indicator
// Reusable "show a spinner while an API call is in flight" helper so every
// screen that fetches data can display a consistent loader without
// duplicating UIActivityIndicatorView setup.

extension UIView {

    private static var loadingIndicatorKey: UInt8 = 0

    private var loadingIndicator: UIActivityIndicatorView? {
        get {
            objc_getAssociatedObject(self, &UIView.loadingIndicatorKey) as? UIActivityIndicatorView
        }
        set {
            objc_setAssociatedObject(self, &UIView.loadingIndicatorKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// Centers a large white spinner over this view (on top of any existing content) and starts animating it.
    func showLoadingIndicator() {

        if let existing = loadingIndicator {
            existing.startAnimating()
            return
        }

        let indicator = UIActivityIndicatorView(style: .large)

        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false

        addSubview(indicator)

        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        indicator.startAnimating()

        loadingIndicator = indicator
    }

    /// Stops and removes the spinner added by `showLoadingIndicator()`, if any.
    func hideLoadingIndicator() {
        loadingIndicator?.stopAnimating()
        loadingIndicator?.removeFromSuperview()
        loadingIndicator = nil
    }
}
