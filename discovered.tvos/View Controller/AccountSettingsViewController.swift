//
//  AccountSettingsViewController.swift
//  discovered.tvos
//
//  Created by mac mini on 01/09/26.
//

import Foundation
import UIKit


final class AccountSettingsViewController: UIViewController {

    // MARK: - UI

    private let backButton = FocusableBackButton(type: .custom)
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    private let profileCard = UIView()
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let categoryLabel = UILabel()
    private let locationLabel = UILabel()

    private let optionsStack = UIStackView()
    private let logoutButton = FocusableLogoutButton(type: .custom)

    // Focus bridge
    private let focusGuide = UIFocusGuide()

    var onLogout: (() -> Void)?

    // MARK: - Properties

    private var userProfile: UserProfile?
    private var isLoading = false
    private var isFirstAppear = true

    // MARK: - Colors

    private let cardColor = UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1)
    private let focusedColor = UIColor(red: 0.92, green: 0.92, blue: 0.92, alpha: 1)
    private let secondaryTextColor = UIColor(white: 0.62, alpha: 1)
    private let orangeColor = UIColor(red: 1.0, green: 0.52, blue: 0.0, alpha: 1)

    
    // MARK: - Static Content

    private let POLICY_TEXT = """
    Privacy Policy

    Effective Date: September 1, 2026

    Discovered TV is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your information when you use our application.

    1. Information We Collect
    We may collect device information, usage data, and viewing preferences to improve your experience.

    2. How We Use Your Information
    Your information is used to personalize content recommendations, improve our services, and ensure secure access to the platform.

    3. Data Security
    We implement industry-standard security measures to protect your personal information from unauthorized access or disclosure.

    4. Third-Party Services
    We may use third-party services for analytics and advertising. These services have their own privacy policies.

    5. Changes to This Policy
    We reserve the right to update this Privacy Policy at any time. Continued use of the app constitutes acceptance of any changes.

    Contact us at support@discoveredtv.com for any privacy-related concerns.
    """

    private let TERMS_TEXT = """
    Terms of Service

    Last Updated: September 1, 2026

    Welcome to Discovered TV. By using this application, you agree to the following Terms of Service.

    1. Acceptance of Terms
    By accessing or using Discovered TV, you agree to be bound by these terms. If you do not agree, please discontinue use of the application.

    2. Use of the Service
    Discovered TV is intended for personal, non-commercial use only. You may not reproduce, distribute, or commercially exploit any content without written consent.

    3. Content
    All content available on Discovered TV is the property of their respective owners and is protected by copyright law.

    4. User Accounts
    You are responsible for maintaining the confidentiality of your account credentials. Discovered TV is not liable for any unauthorized account access.

    5. Termination
    We reserve the right to suspend or terminate your access to the service at any time for violations of these terms.

    For questions, contact us at legal@discoveredtv.com.
    """

    private let HELP_TEXT = """
    Help & Support

    Welcome to the Discovered TV Help Center.

    Getting Started
    Discovered TV brings you a curated selection of music, movies, television, gaming, and spotlight content — all in one place.

    Navigation
    Use the remote to navigate through content. Press the Menu button to open the side menu. Press Select/OK to play content.

    Playback Controls
    During video playback, press any key to reveal the player controls.

    Video Quality
    Adjust playback quality using the Settings option inside the player.

    Search
    Use the Search option in the side menu to find specific content by title or category.

    Account
    Login from the side menu to access personalized features and recommendations.

    Frequently Asked Questions
    • Why is the video buffering? — Check your internet connection speed.
    • How do I exit the app? — Navigate to Exit in the side menu.
    • Can I watch offline? — Offline viewing is not supported at this time.

    For further assistance, contact us at help@discoveredtv.com.
    """
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        setupConstraints()
        setupFocusGuide()
        fetchUserProfile()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if isFirstAppear {
            isFirstAppear = false
            DispatchQueue.main.async { [weak self] in
                self?.setNeedsFocusUpdate()
                self?.updateFocusIfNeeded()
            }
        }
    }

    // MARK: - Preferred Focus

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        if isFirstAppear, let first = optionsStack.arrangedSubviews.first {
            return [first]
        }
        return super.preferredFocusEnvironments
    }

    // MARK: - Focus Update

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)

        if let next = context.nextFocusedView {
            if next === backButton {
                if let first = optionsStack.arrangedSubviews.first {
                    focusGuide.preferredFocusEnvironments = [first]
                }
            } else if optionsStack.arrangedSubviews.contains(next) || next === logoutButton {
                focusGuide.preferredFocusEnvironments = [backButton]
            }
        }
    }

    // MARK: - Menu button support

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            if press.type == .menu {
                navigationController?.popViewController(animated: true)
                return
            }
        }
        super.pressesBegan(presses, with: event)
    }

    // MARK: - Fetch User Profile

    private func fetchUserProfile() {
        isLoading = true
        profileCard.showLoadingIndicator()

        NetworkManager.shared.getUserProfile { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.profileCard.hideLoadingIndicator()
                switch result {
                case .success(let response):
                    self?.userProfile = UserProfile(from: response)
                    self?.updateProfileUI()
                case .failure(let error):
                    print("Error fetching profile: \(error.localizedDescription)")
                    self?.showErrorAlert(message: error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Update Profile UI

    private func updateProfileUI() {
        guard let profile = userProfile else { return }
        nameLabel.text = profile.userFullName
        categoryLabel.text = "\(profile.category) (\(profile.subCategory ?? profile.category))"
        locationLabel.text = "\(profile.location ?? ""), \(profile.name ?? ""), \(profile.country_name ?? "")"

        if let profilePicURL = profile.profilePicture, let url = URL(string: profilePicURL) {
            loadImage(from: url, into: avatarImageView)
        }
    }

    // MARK: - Load Image

    private func loadImage(from url: URL, into imageView: UIImageView) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    imageView.image = image
                    imageView.contentMode = .scaleAspectFill
                }
            }
        }.resume()
    }

    // MARK: - Setup UI

    private func setupUI() {

        // Back Button
        var backConfig = UIButton.Configuration.plain()
        backConfig.image = UIImage(systemName: "chevron.left")
        backConfig.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        backConfig.baseForegroundColor = .white

        backButton.configuration = backConfig
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .primaryActionTriggered)

        backButton.onFocusChanged = { [weak self] focused in
            guard let self = self else { return }
            UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseOut, .beginFromCurrentState]) {
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

        // Scroll View
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(scrollView)

        // Content View
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .clear
        scrollView.addSubview(contentView)

        // Title
        titleLabel.text = "Account Settings"
        titleLabel.font = .systemFont(ofSize: 42, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        // Subtitle
        subtitleLabel.text = "Manage your Cinematic profile and preferences."
        subtitleLabel.font = .systemFont(ofSize: 20, weight: .regular)
        subtitleLabel.textColor = UIColor(white: 0.65, alpha: 1)
        subtitleLabel.numberOfLines = 1
        subtitleLabel.adjustsFontSizeToFitWidth = true
        subtitleLabel.minimumScaleFactor = 0.8
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(subtitleLabel)

        // Profile Card
        setupProfileCard()

        // Options
        optionsStack.axis = .vertical
        optionsStack.spacing = 16
        optionsStack.alignment = .fill
        optionsStack.distribution = .fill
        optionsStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(optionsStack)

        let options: [(icon: String, title: String, subtitle: String, active: Bool, tag: Int)] = [
            ("person.crop.circle", "Account Details", "Update email, password, and personal info", false, 0),
            ("gearshape", "Playback Settings", "Adjust video quality, subtitles, and audio", false, 1),
            ("headphones", "Help & Support", "FAQs, troubleshooting, and contact us", false, 2),
            ("lock.shield", "Privacy Policy", "Read how we handle your data", false, 3),
            ("doc.text", "Terms & Conditions", "Rules and guidelines of the service", false, 4)
        ]

        for option in options {
            let button = createOptionButton(
                icon: option.icon,
                title: option.title,
                subtitle: option.subtitle,
                isActive: option.active
            )
            button.tag = option.tag
            button.addTarget(self, action: #selector(optionButtonTapped(_:)), for: .primaryActionTriggered)
            optionsStack.addArrangedSubview(button)
        }

        // Logout
        setupLogoutButton()
    }

    // MARK: - Focus Guide

    private func setupFocusGuide() {
        view.addLayoutGuide(focusGuide)

        NSLayoutConstraint.activate([
            focusGuide.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 8),
            focusGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            focusGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            focusGuide.heightAnchor.constraint(equalToConstant: 40)
        ])

        if let first = optionsStack.arrangedSubviews.first {
            focusGuide.preferredFocusEnvironments = [first]
        }
    }

    // MARK: - Profile Card

    private func setupProfileCard() {
        profileCard.backgroundColor = cardColor
        profileCard.layer.cornerRadius = 20
        profileCard.clipsToBounds = true
        profileCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(profileCard)

        avatarImageView.backgroundColor = .clear
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 60
        avatarImageView.layer.borderWidth = 3
        avatarImageView.layer.borderColor = orangeColor.cgColor
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        profileCard.addSubview(avatarImageView)

        nameLabel.text = "Loading..."
        nameLabel.font = .systemFont(ofSize: 28, weight: .bold)
        nameLabel.textColor = .white
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 1
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.7
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        profileCard.addSubview(nameLabel)

        categoryLabel.text = "—"
        categoryLabel.font = .systemFont(ofSize: 17, weight: .regular)
        categoryLabel.textColor = UIColor(white: 0.7, alpha: 1)
        categoryLabel.textAlignment = .center
        categoryLabel.numberOfLines = 1
        categoryLabel.adjustsFontSizeToFitWidth = true
        categoryLabel.minimumScaleFactor = 0.65
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        profileCard.addSubview(categoryLabel)

        locationLabel.text = "—"
        locationLabel.font = .systemFont(ofSize: 17, weight: .regular)
        locationLabel.textColor = UIColor(white: 0.7, alpha: 1)
        locationLabel.textAlignment = .center
        locationLabel.numberOfLines = 1
        locationLabel.adjustsFontSizeToFitWidth = true
        locationLabel.minimumScaleFactor = 0.65
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        profileCard.addSubview(locationLabel)
    }

    // MARK: - Option Button

    private func createOptionButton(icon: String, title: String, subtitle: String, isActive: Bool) -> UIButton {
        let button = FocusableOptionButton(type: .custom)
        button.backgroundColor = cardColor
        button.layer.cornerRadius = 18
        button.clipsToBounds = false
        button.translatesAutoresizingMaskIntoConstraints = false

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(iconView)

        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.alignment = .fill
        textStack.distribution = .fill
        textStack.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(textStack)

        let optionTitleLabel = UILabel()
        optionTitleLabel.text = title
        optionTitleLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        optionTitleLabel.textColor = .white
        optionTitleLabel.numberOfLines = 1
        optionTitleLabel.lineBreakMode = .byTruncatingTail
        optionTitleLabel.adjustsFontSizeToFitWidth = true
        optionTitleLabel.minimumScaleFactor = 0.7
        textStack.addArrangedSubview(optionTitleLabel)

        let optionSubtitleLabel = UILabel()
        optionSubtitleLabel.text = subtitle
        optionSubtitleLabel.font = .systemFont(ofSize: 16, weight: .regular)
        optionSubtitleLabel.textColor = secondaryTextColor
        optionSubtitleLabel.numberOfLines = 1
        optionSubtitleLabel.lineBreakMode = .byTruncatingTail
        optionSubtitleLabel.adjustsFontSizeToFitWidth = true
        optionSubtitleLabel.minimumScaleFactor = 0.65
        textStack.addArrangedSubview(optionSubtitleLabel)

        if isActive {
            let badge = UILabel()
            badge.text = "ACTIVE"
            badge.font = .systemFont(ofSize: 11, weight: .bold)
            badge.textColor = .white
            badge.backgroundColor = orangeColor
            badge.textAlignment = .center
            badge.layer.cornerRadius = 7
            badge.clipsToBounds = true
            badge.translatesAutoresizingMaskIntoConstraints = false
            button.addSubview(badge)

            NSLayoutConstraint.activate([
                badge.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -48),
                badge.centerYAnchor.constraint(equalTo: button.centerYAnchor),
                badge.widthAnchor.constraint(greaterThanOrEqualToConstant: 52),
                badge.heightAnchor.constraint(equalToConstant: 24)
            ])
        }

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = UIColor(white: 0.5, alpha: 1)
        chevron.contentMode = .scaleAspectFit
        chevron.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(chevron)

        let textTrailing: CGFloat = isActive ? -150 : -85

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 26),
            iconView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 38),
            iconView.heightAnchor.constraint(equalToConstant: 38),

            textStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 22),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: button.trailingAnchor, constant: textTrailing),
            textStack.centerYAnchor.constraint(equalTo: button.centerYAnchor),

            chevron.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -26),
            chevron.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 18),
            chevron.heightAnchor.constraint(equalToConstant: 24),

            button.heightAnchor.constraint(equalToConstant: 82)
        ])

        button.onFocusChanged = { [weak button, weak iconView, weak chevron, weak optionTitleLabel, weak optionSubtitleLabel] focused in
            guard let button = button,
                  let iconView = iconView,
                  let chevron = chevron,
                  let optionTitleLabel = optionTitleLabel,
                  let optionSubtitleLabel = optionSubtitleLabel else { return }

            UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseOut, .beginFromCurrentState]) {
                if focused {
                    button.backgroundColor = self.focusedColor
                    button.transform = CGAffineTransform(scaleX: 1.025, y: 1.025)
                    iconView.tintColor = .black
                    chevron.tintColor = UIColor(white: 0.25, alpha: 1)
                    optionTitleLabel.textColor = .black
                    optionSubtitleLabel.textColor = UIColor(white: 0.35, alpha: 1)
                } else {
                    button.backgroundColor = self.cardColor
                    button.transform = .identity
                    iconView.tintColor = .white
                    chevron.tintColor = UIColor(white: 0.5, alpha: 1)
                    optionTitleLabel.textColor = .white
                    optionSubtitleLabel.textColor = self.secondaryTextColor
                }
            }
        }

        return button
    }

    // MARK: - Logout Button

    private func setupLogoutButton() {
        var configuration = UIButton.Configuration.plain()
        configuration.attributedTitle = AttributedString(
            NSAttributedString(
                string: "LOGOUT",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 18, weight: .medium),
                    .foregroundColor: UIColor(white: 0.7, alpha: 1)
                ]
            )
        )
        configuration.image = UIImage(systemName: "arrow.right.square")
        configuration.imagePlacement = .leading
        configuration.imagePadding = 10
        configuration.baseForegroundColor = UIColor(white: 0.7, alpha: 1)
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 18, leading: 30, bottom: 18, trailing: 30)

        logoutButton.configuration = configuration
        logoutButton.backgroundColor = UIColor(white: 0.15, alpha: 1)
        logoutButton.layer.cornerRadius = 16
        logoutButton.clipsToBounds = false
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .primaryActionTriggered)
        contentView.addSubview(logoutButton)

        logoutButton.onFocusChanged = { [weak self] focused in
            guard let self = self else { return }
            UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseOut, .beginFromCurrentState]) {
                if focused {
                    self.logoutButton.backgroundColor = self.focusedColor
                    self.logoutButton.transform = CGAffineTransform(scaleX: 1.025, y: 1.025)
                    self.updateLogoutAppearance(focused: true)
                } else {
                    self.logoutButton.backgroundColor = UIColor(white: 0.15, alpha: 1)
                    self.logoutButton.transform = .identity
                    self.updateLogoutAppearance(focused: false)
                }
            }
        }
    }

    private func updateLogoutAppearance(focused: Bool) {
        var configuration = logoutButton.configuration
        let textColor: UIColor = focused ? .black : UIColor(white: 0.7, alpha: 1)
        let fontWeight: UIFont.Weight = focused ? .semibold : .medium

        configuration?.attributedTitle = AttributedString(
            NSAttributedString(
                string: "LOGOUT",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 18, weight: fontWeight),
                    .foregroundColor: textColor
                ]
            )
        )
        configuration?.baseForegroundColor = textColor
        logoutButton.configuration = configuration
    }

    // MARK: - Constraints

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Back Button
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            // Scroll View
            scrollView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Content View
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            // Title
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 80),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -80),

            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            // Profile Card
            profileCard.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 42),
            profileCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 80),
            profileCard.widthAnchor.constraint(equalToConstant: 320),
            profileCard.heightAnchor.constraint(equalToConstant: 320),

            // Avatar
            avatarImageView.topAnchor.constraint(equalTo: profileCard.topAnchor, constant: 34),
            avatarImageView.centerXAnchor.constraint(equalTo: profileCard.centerXAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 120),
            avatarImageView.heightAnchor.constraint(equalToConstant: 120),

            // Name
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 18),
            nameLabel.leadingAnchor.constraint(equalTo: profileCard.leadingAnchor, constant: 25),
            nameLabel.trailingAnchor.constraint(equalTo: profileCard.trailingAnchor, constant: -25),

            // Category
            categoryLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            categoryLabel.leadingAnchor.constraint(equalTo: profileCard.leadingAnchor, constant: 25),
            categoryLabel.trailingAnchor.constraint(equalTo: profileCard.trailingAnchor, constant: -25),

            // Location
            locationLabel.topAnchor.constraint(equalTo: categoryLabel.bottomAnchor, constant: 8),
            locationLabel.leadingAnchor.constraint(equalTo: profileCard.leadingAnchor, constant: 25),
            locationLabel.trailingAnchor.constraint(equalTo: profileCard.trailingAnchor, constant: -25),
            locationLabel.bottomAnchor.constraint(lessThanOrEqualTo: profileCard.bottomAnchor, constant: -25),

            // Options
            optionsStack.topAnchor.constraint(equalTo: profileCard.topAnchor),
            optionsStack.leadingAnchor.constraint(equalTo: profileCard.trailingAnchor, constant: 34),
            optionsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -80),

            // Logout
            logoutButton.topAnchor.constraint(equalTo: optionsStack.bottomAnchor, constant: 40),
            logoutButton.leadingAnchor.constraint(equalTo: optionsStack.leadingAnchor),
            logoutButton.trailingAnchor.constraint(equalTo: optionsStack.trailingAnchor),
            logoutButton.heightAnchor.constraint(equalToConstant: 64),
            logoutButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -50)
        ])
    }

    // MARK: - Actions

    @objc private func backButtonTapped() {
        self.dismiss(animated: true)
    }

    @objc private func optionButtonTapped(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            print("Account Details tapped")
            
        case 1:
            print("Playback Settings tapped")
            
        case 2:
            // Help & Support
            openInfoPage(title: "Help & Support", body: HELP_TEXT)
            
        case 3:
            // Privacy Policy
            openInfoPage(title: "Privacy Policy", body: POLICY_TEXT)
            
        case 4:
            // Terms & Conditions
            openInfoPage(title: "Terms & Conditions", body: TERMS_TEXT)
            
        default:
            break
        }
    }

    private func openInfoPage(title: String, body: String) {
        let vc = InfoContentViewController(title: title, body: body)
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }



    @objc private func logoutTapped() {
        let signOutVC = SignOutViewController()
        signOutVC.modalPresentationStyle = .overFullScreen
        signOutVC.onConfirmLogout = { [weak self] in
            AuthManager.shared.logout()
            self?.dismiss(animated: true) {
                self?.onLogout?()
            }
        }
        present(signOutVC, animated: true)
    }

    // MARK: - Error Handling

    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Focusable Back Button

final class FocusableBackButton: UIButton {
    var onFocusChanged: ((Bool) -> Void)?

    override var canBecomeFocused: Bool { true }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        let isFocused = context.nextFocusedView === self
        coordinator.addCoordinatedAnimations {
            self.onFocusChanged?(isFocused)
        }
    }
}

// MARK: - Focusable Option Button

final class FocusableOptionButton: UIButton {
    var onFocusChanged: ((Bool) -> Void)?

    override var canBecomeFocused: Bool { true }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        let isFocused = context.nextFocusedView === self
        coordinator.addCoordinatedAnimations {
            self.onFocusChanged?(isFocused)
        }
    }
}

// MARK: - Focusable Logout Button

final class FocusableLogoutButton: UIButton {
    var onFocusChanged: ((Bool) -> Void)?

    override var canBecomeFocused: Bool { true }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        let isFocused = context.nextFocusedView === self
        coordinator.addCoordinatedAnimations {
            self.onFocusChanged?(isFocused)
        }
    }
}
