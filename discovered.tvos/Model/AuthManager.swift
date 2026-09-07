//
//  AuthManager.swift
//  discovered.tvos
//
//  Created by mac mini on 01/09/26.
//

import Foundation

/// Persists the logged-in user's session (auth token + profile) and exposes
/// login/logout state to the rest of the app. Backed by UserDefaults.
final class AuthManager {
    static let shared = AuthManager()
    private init() {}

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let isLoggedIn = "auth.isLoggedIn"
        static let token = "auth.token"
        static let userLoginId = "auth.userLoginId"
        static let userName = "auth.userName"
        static let userEmail = "auth.userEmail"
        static let userPic = "auth.userPic"
    }

    // MARK: - Session State

    private(set) var isLoggedIn: Bool {
        get { defaults.bool(forKey: Keys.isLoggedIn) }
        set { defaults.set(newValue, forKey: Keys.isLoggedIn) }
    }

    private(set) var authToken: String? {
        get { defaults.string(forKey: Keys.token) }
        set { defaults.set(newValue, forKey: Keys.token) }
    }

    private(set) var userLoginId: String? {
        get { defaults.string(forKey: Keys.userLoginId) }
        set { defaults.set(newValue, forKey: Keys.userLoginId) }
    }

    var userName: String {
        get { defaults.string(forKey: Keys.userName) ?? "Guest" }
        set { defaults.set(newValue, forKey: Keys.userName) }
    }

    private(set) var userEmail: String? {
        get { defaults.string(forKey: Keys.userEmail) }
        set { defaults.set(newValue, forKey: Keys.userEmail) }
    }

    private(set) var userPic: String? {
        get { defaults.string(forKey: Keys.userPic) }
        set { defaults.set(newValue, forKey: Keys.userPic) }
    }

    // MARK: - Session Management

    /// Persists a successful login response as the active session.
    func startSession(with userData: UserData) {
        authToken = userData.token
        userLoginId = userData.userLoginId
        userName = userData.userName ?? "Guest"
        userEmail = userData.userEmail
        userPic = userData.userPic
        isLoggedIn = true
    }

    /// Clears the active session, logging the user out.
    func logout() {
        authToken = nil
        userLoginId = nil
        userEmail = nil
        userPic = nil
        userName = "Guest"
        isLoggedIn = false
    }
}
