//
//  LoginViewController.swift
//  discovered.tvos
//
//  Created by mac mini on 01/09/26.
//

import Foundation
import UIKit

final class LoginViewController: UIViewController {

    // MARK: - UI Elements
    private let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let dimView = UIView()
    
    private let cardView = UIView()
    private let titleLabel = UILabel()
    
    private let emailContainer = UIView()
    private let emailTextField = UITextField()
    
    private let passwordContainer = UIView()
    private let passwordTextField = UITextField()
    
    private let forgotButton = UIButton(type: .system)
    private let loginButton = UIButton(type: .system)
    private let backButton = UIButton(type: .system)          // ← Back button add kiya
    private let errorLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    var onLoginSuccess: (() -> Void)?

    private let viewModel = LoginViewModel()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupCard()
        setupConstraints()
        bindViewModel()
    }
    
    // MARK: - Background
    private func setupBackground() {
        view.backgroundColor = .clear
        
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        dimView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dimView)
        
        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(blurEffectView, at: 0)
        
        NSLayoutConstraint.activate([
            blurEffectView.topAnchor.constraint(equalTo: view.topAnchor),
            blurEffectView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Card + Fields
    private func setupCard() {
        cardView.backgroundColor = UIColor(white: 0.11, alpha: 0.92)
        cardView.layer.cornerRadius = 24
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        cardView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cardView)
        
        titleLabel.text = "DISCOVERED.TV"
        titleLabel.font = .appFont(ofSize: 34, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)
        
        // ===== Email Field =====
        emailContainer.layer.borderWidth = 2.5
        emailContainer.layer.borderColor = UIColor.orange.cgColor
        emailContainer.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(emailContainer)
        
        emailTextField.placeholder = "Email or Mobile Number"
        emailTextField.font = .appFont(ofSize: 20, weight: .regular)
        emailTextField.textColor = .white
        emailTextField.tintColor = .clear
        emailTextField.backgroundColor = .clear
        emailTextField.borderStyle = .none
        emailTextField.autocapitalizationType = .none
        emailTextField.keyboardType = .emailAddress
        
        emailTextField.layer.cornerRadius = 0
        emailTextField.translatesAutoresizingMaskIntoConstraints = false
        emailContainer.addSubview(emailTextField)
        
        // ===== Password Field =====
        passwordContainer.layer.borderWidth = 0
        passwordContainer.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(passwordContainer)
        
        passwordTextField.placeholder = "Password"
        passwordTextField.font = .appFont(ofSize: 20, weight: .regular)
        passwordTextField.textColor = .white
        passwordTextField.tintColor = .clear
        passwordTextField.isSecureTextEntry = true
        passwordTextField.backgroundColor = .clear
        passwordTextField.borderStyle = .none
        
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        passwordContainer.addSubview(passwordTextField)
        
        // Forgot Password
        forgotButton.setTitle("Forgot Password?", for: .normal)
        forgotButton.setTitleColor(.orange, for: .normal)
        forgotButton.titleLabel?.font = .appFont(ofSize: 17, weight: .medium)
        forgotButton.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(forgotButton)

        // Error Label
        errorLabel.font = .appFont(ofSize: 16, weight: .medium)
        errorLabel.textColor = .systemRed
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 2
        errorLabel.alpha = 0
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(errorLabel)

        // Activity Indicator
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(activityIndicator)
        
        // ===== Back Button =====
        var backConfig = UIButton.Configuration.filled()
        backConfig.title = "Back"
        backConfig.baseBackgroundColor = UIColor(white: 0.25, alpha: 1)
        backConfig.baseForegroundColor = .white
        backConfig.cornerStyle = .capsule
        backConfig.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
        
        backConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .appFont(ofSize: 21, weight: .semibold)
            return outgoing
        }
        
        backButton.configuration = backConfig
        backButton.addTarget(self, action: #selector(backTapped), for: .primaryActionTriggered)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(backButton)
        
        // ===== Login Button =====
        var config = UIButton.Configuration.filled()
        config.title = "Login  →"
        config.baseBackgroundColor = .orange
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
        
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .appFont(ofSize: 21, weight: .semibold)
            return outgoing
        }
        
        loginButton.configuration = config
        loginButton.addTarget(self, action: #selector(loginTapped), for: .primaryActionTriggered)
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(loginButton)
        
        // Focus change pe border update
        emailTextField.addTarget(self, action: #selector(textFieldDidBegin(_:)), for: .editingDidBegin)
        passwordTextField.addTarget(self, action: #selector(textFieldDidBegin(_:)), for: .editingDidBegin)
    }
    
    // MARK: - Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            cardView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            cardView.widthAnchor.constraint(equalToConstant: 520),
            
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 48),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 40),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -40),
            
            emailContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 48),
            emailContainer.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 40),
            emailContainer.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -40),
            emailContainer.heightAnchor.constraint(equalToConstant: 58),
            
            emailTextField.topAnchor.constraint(equalTo: emailContainer.topAnchor),
            emailTextField.bottomAnchor.constraint(equalTo: emailContainer.bottomAnchor),
            emailTextField.leadingAnchor.constraint(equalTo: emailContainer.leadingAnchor, constant: 20),
            emailTextField.trailingAnchor.constraint(equalTo: emailContainer.trailingAnchor, constant: -20),
            
            passwordContainer.topAnchor.constraint(equalTo: emailContainer.bottomAnchor, constant: 18),
            passwordContainer.leadingAnchor.constraint(equalTo: emailContainer.leadingAnchor),
            passwordContainer.trailingAnchor.constraint(equalTo: emailContainer.trailingAnchor),
            passwordContainer.heightAnchor.constraint(equalToConstant: 58),
            
            passwordTextField.topAnchor.constraint(equalTo: passwordContainer.topAnchor),
            passwordTextField.bottomAnchor.constraint(equalTo: passwordContainer.bottomAnchor),
            passwordTextField.leadingAnchor.constraint(equalTo: passwordContainer.leadingAnchor, constant: 20),
            passwordTextField.trailingAnchor.constraint(equalTo: passwordContainer.trailingAnchor, constant: -20),
            
            forgotButton.topAnchor.constraint(equalTo: passwordContainer.bottomAnchor, constant: 16),
            forgotButton.trailingAnchor.constraint(equalTo: passwordContainer.trailingAnchor),

            errorLabel.topAnchor.constraint(equalTo: forgotButton.bottomAnchor, constant: 12),
            errorLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 40),
            errorLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -40),

            activityIndicator.centerYAnchor.constraint(equalTo: loginButton.centerYAnchor),
            activityIndicator.trailingAnchor.constraint(equalTo: loginButton.leadingAnchor, constant: -16),

            // ===== Back + Login Buttons (equal width + 15 spacing) =====
            backButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 30),
            backButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 58),
            backButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -48),
            
            loginButton.topAnchor.constraint(equalTo: backButton.topAnchor),
            loginButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -40),
            loginButton.heightAnchor.constraint(equalTo: backButton.heightAnchor),
            loginButton.bottomAnchor.constraint(equalTo: backButton.bottomAnchor),
            
            // Equal width + 15 spacing
            backButton.trailingAnchor.constraint(equalTo: loginButton.leadingAnchor, constant: -15),
            backButton.widthAnchor.constraint(equalTo: loginButton.widthAnchor)
        ])
    }
    
    // MARK: - Focus Border
    @objc private func textFieldDidBegin(_ textField: UITextField) {
        if textField == emailTextField {
            emailContainer.layer.borderWidth = 2.5
            emailContainer.layer.borderColor = UIColor.clear.cgColor
            passwordContainer.layer.borderWidth = 0
        } else {
            passwordContainer.layer.borderWidth = 2.5
            passwordContainer.layer.borderColor = UIColor.clear.cgColor
            emailContainer.layer.borderWidth = 0
        }
    }
    
    // MARK: - ViewModel Binding
    private func bindViewModel() {
        viewModel.onLoginStarted = { [weak self] in
            guard let self else { return }
            self.errorLabel.alpha = 0
            self.loginButton.isEnabled = false
            self.activityIndicator.startAnimating()
        }

        viewModel.onLoginFailure = { [weak self] message in
            guard let self else { return }
            self.activityIndicator.stopAnimating()
            self.loginButton.isEnabled = true
            self.errorLabel.text = message
            UIView.animate(withDuration: 0.2) {
                self.errorLabel.alpha = 1
            }
        }

        viewModel.onLoginSuccess = { [weak self] in
            guard let self else { return }
            self.activityIndicator.stopAnimating()
            self.loginButton.isEnabled = true
            self.dismiss(animated: true) {
                self.onLoginSuccess?()
            }
        }
    }

    // MARK: - Actions
    @objc private func backTapped() {
        dismiss(animated: true)
    }

    @objc private func loginTapped() {
        let email = emailTextField.text ?? ""
        let password = passwordTextField.text ?? ""
        viewModel.login(email: email, password: password)
    }
    
    // Menu button se dismiss
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            if press.type == .menu {
                dismiss(animated: true)
                return
            }
        }
        super.pressesBegan(presses, with: event)
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        
        if context.nextFocusedView == emailTextField {
            emailContainer.layer.borderWidth = 0
            emailContainer.layer.borderColor = UIColor.clear.cgColor
            passwordContainer.layer.borderWidth = 0
        } else if context.nextFocusedView == passwordTextField {
            passwordContainer.layer.borderWidth = 0
            passwordContainer.layer.borderColor = UIColor.clear.cgColor
            emailContainer.layer.borderWidth = 0
        }
    }
}
