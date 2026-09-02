//
//  AuthManager.swift
//  discovered.tvos
//
//  Created by mac mini on 01/09/26.
//

import Foundation

final class AuthManager {
    static let shared = AuthManager()
    
    private let isLoggedInKey = "isLoggedIn"
    private let userNameKey = "userName"
    
    var isLoggedIn: Bool {
        get { UserDefaults.standard.bool(forKey: isLoggedInKey) }
        set { UserDefaults.standard.set(newValue, forKey: isLoggedInKey) }
    }
    
    var userName: String {
        get { UserDefaults.standard.string(forKey: userNameKey) ?? "Alex" }
        set { UserDefaults.standard.set(newValue, forKey: userNameKey) }
    }
    
    func login(emailOrMobile: String, password: String) -> Bool {
        // Demo login – replace with real API later
        guard !emailOrMobile.isEmpty, !password.isEmpty else { return false }
        isLoggedIn = true
        userName = "Alex"
        return true
    }
    
    func logout() {
        isLoggedIn = false
    }
}
