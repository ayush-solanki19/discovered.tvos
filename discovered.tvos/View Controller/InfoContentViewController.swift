//
//  InfoContentViewController.swift
//  discovered.tvos
//
//  Created by mac mini on 07/09/26.
//

import Foundation
import UIKit

final class InfoContentViewController: UIViewController {

    private let backButton = FocusableBackButton(type: .custom)
    private let titleLabel = UILabel()
    private let scrollView = UIScrollView()
    private let contentLabel = UILabel()

    private let pageTitle: String
    private let bodyText: String

    private let focusedColor = UIColor(red: 0.92, green: 0.92, blue: 0.92, alpha: 1)

    init(title: String, body: String) {
        self.pageTitle = title
        self.bodyText = body
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
    }

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return [backButton]
    }

    private func setupUI() {
        // Back Button
        var backConfig = UIButton.Configuration.plain()
        backConfig.image = UIImage(systemName: "chevron.left")
        backConfig.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        backConfig.baseForegroundColor = .white

        backButton.configuration = backConfig
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backTapped), for: .primaryActionTriggered)

        backButton.onFocusChanged = { [weak self] focused in
            guard let self = self else { return }
            UIView.animate(withDuration: 0.18) {
                if focused {
                    self.backButton.transform = CGAffineTransform(scaleX: 1.18, y: 1.18)
                    self.backButton.backgroundColor = self.focusedColor
                    self.backButton.layer.cornerRadius = 22
                    self.backButton.configuration?.baseForegroundColor = .black
                } else {
                    self.backButton.transform = .identity
                    self.backButton.backgroundColor = .clear
                    self.backButton.configuration?.baseForegroundColor = .white
                }
            }
        }
        view.addSubview(backButton)

        // Title
        titleLabel.text = pageTitle
        titleLabel.font = .systemFont(ofSize: 36, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        // ScrollView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        view.addSubview(scrollView)

        // Content Label
        contentLabel.text = bodyText
        contentLabel.font = .systemFont(ofSize: 22, weight: .regular)
        contentLabel.textColor = UIColor(white: 0.85, alpha: 1)
        contentLabel.numberOfLines = 0
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentLabel)

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -50),

            scrollView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 40),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 80),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -80),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40),

            contentLabel.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentLabel.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentLabel.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentLabel.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentLabel.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }

    @objc private func backTapped() {
        dismiss(animated: true)
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            if press.type == .menu {
                dismiss(animated: true)
                return
            }
        }
        super.pressesBegan(presses, with: event)
    }
}
