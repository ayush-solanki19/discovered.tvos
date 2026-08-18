//
//  APIConfig.swift
//  discovered.tvos
//
//  Created by mac mini on 18/08/26.
//

import Foundation

enum APIConfig {
    static let baseURL = "https://discovered.tv/api/v3"
    
    enum Endpoint {
        case homeVideoSpotlight
        
        var path: String {
            switch self {
            case .homeVideoSpotlight:
                return "/appdashboard/homeVideoSpotlight"
            }
        }
        
        var url: URL? {
            return URL(string: APIConfig.baseURL + path)
        }
    }
}
