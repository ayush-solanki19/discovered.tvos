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
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    private let profileCard = UIView()
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let premiumBadge = UILabel()
    private let memberSinceLabel = UILabel()
    private let watchTimeLabel = UILabel()
    
    private let optionsStack = UIStackView()
    private let logoutButton = UIButton(type: .system)
    
    var onLogout: (() -> Void)?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        setupConstraints()
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Scroll
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Title
        titleLabel.text = "Account Settings"
        titleLabel.font = .systemFont(ofSize: 42, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        subtitleLabel.text = "Manage your Cinematic profile and preferences."
        subtitleLabel.font = .systemFont(ofSize: 20, weight: .regular)
        subtitleLabel.textColor = UIColor(white: 0.65, alpha: 1)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(subtitleLabel)
        
        // Profile Card
        profileCard.backgroundColor = UIColor(white: 0.12, alpha: 1)
        profileCard.layer.cornerRadius = 20
        profileCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(profileCard)
        
        avatarImageView.image = UIImage(named: "alex_avatar") // Add avatar image
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 70
        avatarImageView.layer.borderWidth = 3
        avatarImageView.layer.borderColor = UIColor.orange.cgColor
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        profileCard.addSubview(avatarImageView)
        
        nameLabel.text = AuthManager.shared.userName
        nameLabel.font = .systemFont(ofSize: 28, weight: .bold)
        nameLabel.textColor = .white
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        profileCard.addSubview(nameLabel)
        
        premiumBadge.text = "★  PREMIUM MEMBER"
        premiumBadge.font = .systemFont(ofSize: 14, weight: .semibold)
        premiumBadge.textColor = .white
        premiumBadge.backgroundColor = .orange
        premiumBadge.textAlignment = .center
        premiumBadge.layer.cornerRadius = 12
        premiumBadge.clipsToBounds = true
        premiumBadge.translatesAutoresizingMaskIntoConstraints = false
        profileCard.addSubview(premiumBadge)
        
        memberSinceLabel.text = "Member Since          Oct 2021"
        memberSinceLabel.font = .systemFont(ofSize: 18, weight: .regular)
        memberSinceLabel.textColor = UIColor(white: 0.7, alpha: 1)
        memberSinceLabel.translatesAutoresizingMaskIntoConstraints = false
        profileCard.addSubview(memberSinceLabel)
        
        watchTimeLabel.text = "Total Watch Time    1,402 hrs"
        watchTimeLabel.font = .systemFont(ofSize: 18, weight: .regular)
        watchTimeLabel.textColor = UIColor(white: 0.7, alpha: 1)
        watchTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        profileCard.addSubview(watchTimeLabel)
        
        // Options
        optionsStack.axis = .vertical
        optionsStack.spacing = 16
        optionsStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(optionsStack)
        
        let options: [(String, String, Bool)] = [
            ("person.crop.circle", "Account Details\nUpdate email, password, and personal info", false),
            ("play.rectangle", "Subscription Plan\nManage billing and plan options", true),
            ("gearshape", "Playback Settings\nAdjust video quality, subtitles, and audio", false),
            ("headphones", "Help & Support\nFAQs, troubleshooting, and contact us", false)
        ]
        
        for (icon, title, isActive) in options {
            let option = createOptionButton(icon: icon, title: title, isActive: isActive)
            optionsStack.addArrangedSubview(option)
        }
        
        // Logout Button
        var logoutConfig = UIButton.Configuration.plain()
        logoutConfig.title = "LOGOUT"
        logoutConfig.image = UIImage(systemName: "arrow.right.square")
        logoutConfig.imagePlacement = .leading
        logoutConfig.imagePadding = 12
        logoutConfig.baseForegroundColor = UIColor(white: 0.7, alpha: 1)
        logoutConfig.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 30, bottom: 20, trailing: 30)
        logoutButton.configuration = logoutConfig
        logoutButton.backgroundColor = UIColor(white: 0.15, alpha: 1)
        logoutButton.layer.cornerRadius = 14
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .primaryActionTriggered)
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(logoutButton)
    }
    
    private func createOptionButton(icon: String, title: String, isActive: Bool) -> UIButton {
        let button = UIButton(type: .system)
        
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: icon)
        config.imagePlacement = .leading
        config.imagePadding = 20
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 22, leading: 24, bottom: 22, trailing: 24)
        
        var attributed = NSMutableAttributedString(string: title)
        if let range = title.range(of: "\n") {
            let firstLine = String(title[..<range.lowerBound])
            let secondLine = String(title[range.upperBound...])
            
            attributed = NSMutableAttributedString(string: firstLine + "\n", attributes: [
                .font: UIFont.systemFont(ofSize: 22, weight: .semibold),
                .foregroundColor: UIColor.white
            ])
            attributed.append(NSAttributedString(string: secondLine, attributes: [
                .font: UIFont.systemFont(ofSize: 16, weight: .regular),
                .foregroundColor: UIColor(white: 0.6, alpha: 1)
            ]))
        }
        
        config.attributedTitle = AttributedString(attributed)
        
        button.configuration = config
        button.backgroundColor = UIColor(white: 0.12, alpha: 1)
        button.layer.cornerRadius = 16
        button.contentHorizontalAlignment = .left
        
        if isActive {
            let badge = UILabel()
            badge.text = " ACTIVE "
            badge.font = .systemFont(ofSize: 12, weight: .bold)
            badge.textColor = .white
            badge.backgroundColor = .orange
            badge.layer.cornerRadius = 6
            badge.clipsToBounds = true
            badge.translatesAutoresizingMaskIntoConstraints = false
            button.addSubview(badge)
            
            NSLayoutConstraint.activate([
                badge.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -24),
                badge.centerYAnchor.constraint(equalTo: button.centerYAnchor, constant: -10)
            ])
        }
        
        // Chevron
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = UIColor(white: 0.5, alpha: 1)
        chevron.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(chevron)
        
        NSLayoutConstraint.activate([
            chevron.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -24),
            chevron.centerYAnchor.constraint(equalTo: button.centerYAnchor)
        ])
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 90).isActive = true
        
        return button
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 80),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            
            profileCard.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 50),
            profileCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 80),
            profileCard.widthAnchor.constraint(equalToConstant: 320),
            profileCard.heightAnchor.constraint(equalToConstant: 420),
            
            avatarImageView.topAnchor.constraint(equalTo: profileCard.topAnchor, constant: 40),
            avatarImageView.centerXAnchor.constraint(equalTo: profileCard.centerXAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 140),
            avatarImageView.heightAnchor.constraint(equalToConstant: 140),
            
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 24),
            nameLabel.centerXAnchor.constraint(equalTo: profileCard.centerXAnchor),
            
            premiumBadge.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 12),
            premiumBadge.centerXAnchor.constraint(equalTo: profileCard.centerXAnchor),
            premiumBadge.heightAnchor.constraint(equalToConstant: 28),
            premiumBadge.widthAnchor.constraint(equalToConstant: 180),
            
            memberSinceLabel.topAnchor.constraint(equalTo: premiumBadge.bottomAnchor, constant: 40),
            memberSinceLabel.leadingAnchor.constraint(equalTo: profileCard.leadingAnchor, constant: 30),
            
            watchTimeLabel.topAnchor.constraint(equalTo: memberSinceLabel.bottomAnchor, constant: 12),
            watchTimeLabel.leadingAnchor.constraint(equalTo: memberSinceLabel.leadingAnchor),
            
            optionsStack.topAnchor.constraint(equalTo: profileCard.topAnchor),
            optionsStack.leadingAnchor.constraint(equalTo: profileCard.trailingAnchor, constant: 40),
            optionsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -80),
            
            logoutButton.topAnchor.constraint(equalTo: optionsStack.bottomAnchor, constant: 50),
            logoutButton.leadingAnchor.constraint(equalTo: optionsStack.leadingAnchor),
            logoutButton.trailingAnchor.constraint(equalTo: optionsStack.trailingAnchor),
            logoutButton.heightAnchor.constraint(equalToConstant: 70),
            logoutButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -60)
        ])
    }
    
    // MARK: - Actions
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
}
