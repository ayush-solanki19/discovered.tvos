//
//  LoginViewModel.swift
//  discovered.tvos
//
//  Created by mac mini on 04/09/26.
//

import Foundation

final class LoginViewModel {

    // MARK: - Output (bind these from the view controller)
    var onLoginStarted: (() -> Void)?
    var onLoginSuccess: (() -> Void)?
    var onLoginFailure: ((String) -> Void)?

    private(set) var isLoading = false

    // MARK: - Input
    func login(email: String, password: String) {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            onLoginFailure?("Please enter both email/mobile number and password.")
            return
        }

        guard !isLoading else { return }
        isLoading = true
        onLoginStarted?()

        NetworkManager.shared.login(email: trimmedEmail, password: password) { [weak self] result in
            guard let self else { return }

            DispatchQueue.main.async {
                self.isLoading = false

                switch result {
                case .success(let response):
                    guard let userData = response.userData else {
                        self.onLoginFailure?("Login failed. Please try again.")
                        return
                    }
                    AuthManager.shared.startSession(with: userData)
                    self.onLoginSuccess?()

                case .failure(let error):
                    self.onLoginFailure?(error.localizedDescription)
                }
            }
        }
    }
}
