//
//  SignOutViewController.swift
//  discovered.tvos
//
//  Created by mac mini on 01/09/26.
//

import Foundation
import UIKit

final class SignOutViewController: UIViewController {
    
    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let logoutButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    
    var onConfirmLogout: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        
        cardView.backgroundColor = UIColor(white: 0.12, alpha: 0.98)
        cardView.layer.cornerRadius = 24
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        cardView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cardView)
        
        let brandLabel = UILabel()
        brandLabel.text = "DISCOVERED.TV"
        brandLabel.font = .systemFont(ofSize: 22, weight: .bold)
        brandLabel.textColor = .white
        brandLabel.textAlignment = .center
        brandLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(brandLabel)
        
        let icon = UIImageView(image: UIImage(systemName: "arrow.right.square"))
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(icon)
        
        titleLabel.text = "Sign Out"
        titleLabel.font = .systemFont(ofSize: 36, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)
        
        messageLabel.text = "Are you sure you want to sign out of your\naccount on this device?"
        messageLabel.font = .systemFont(ofSize: 20, weight: .regular)
        messageLabel.textColor = UIColor(white: 0.65, alpha: 1)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(messageLabel)
        
        // Logout Button
        var logoutConfig = UIButton.Configuration.filled()
        logoutConfig.title = "Logout"
        logoutConfig.baseBackgroundColor = .orange
        logoutConfig.baseForegroundColor = .white
        logoutConfig.cornerStyle = .medium
        logoutConfig.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 40, bottom: 16, trailing: 40)
        logoutButton.configuration = logoutConfig
        logoutButton.addTarget(self, action: #selector(confirmLogout), for: .primaryActionTriggered)
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(logoutButton)
        
        // Cancel Button
        var cancelConfig = UIButton.Configuration.gray()
        cancelConfig.title = "Cancel"
        cancelConfig.baseForegroundColor = .white
        cancelConfig.cornerStyle = .medium
        cancelConfig.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 40, bottom: 16, trailing: 40)
        cancelButton.configuration = cancelConfig
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .primaryActionTriggered)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            brandLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 40),
            brandLabel.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            
            icon.topAnchor.constraint(equalTo: brandLabel.bottomAnchor, constant: 30),
            icon.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            icon.widthAnchor.constraint(equalToConstant: 40),
            icon.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            messageLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 40),
            messageLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -40),
            
            logoutButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 50),
            logoutButton.trailingAnchor.constraint(equalTo: cardView.centerXAnchor, constant: -12),
            
            cancelButton.topAnchor.constraint(equalTo: logoutButton.topAnchor),
            cancelButton.leadingAnchor.constraint(equalTo: cardView.centerXAnchor, constant: 12),
            
            logoutButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -50)
        ])
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            cardView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            cardView.widthAnchor.constraint(equalToConstant: 520)
        ])
    }
    
    @objc private func confirmLogout() {
        dismiss(animated: true) {
            self.onConfirmLogout?()
        }
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
}
