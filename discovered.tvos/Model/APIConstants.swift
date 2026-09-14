//
//  APIConstants.swift
//  discovered.tvos
//
//  Created by mac mini on 18/08/26.
//

import Foundation
struct APIConstants {
    
    // MARK: - Base URL
    static let baseURL = "https://discovered.tv/api/v3/"
    
    // MARK: - Endpoints
    struct Endpoints {
        static let homeVideoSpotlight = "appdashboard/homeVideoSpotlight"
        static let allowLoginAccess = "authentication/allow_login_access"
        static let getUserProfile = "appdashboard/profile"
        static let myChannel = "appdashboard/my_channel"
        static let searchContent = "appdashboard/get_mysearch_content_new"
    }
    
    // MARK: - Full URL Generator
    static func getFullURL(for endpoint: String) -> String {
        return baseURL + endpoint
    }
}
