//
//  NetworkManager.swift
//  discovered.tvos
//
//  Created by mac mini on 17/08/26.
//

import Foundation
import UIKit

class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    func fetchHomeVideoSpotlight(
        mode: Int = 8,
        limit: Int = 2,
        start: Int = 0,
        timeZoneOffset: String = "+250",
        completion: @escaping (Result<SpotlightMainResponse, Error>) -> Void
    ) {
        // Base URL + Endpoint dynamically banaya gaya hai
        let urlString = APIConstants.getFullURL(for: APIConstants.Endpoints.homeVideoSpotlight)
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let parameters: [String: Any] = [
            "mode": mode,
            "limit": limit,
            "start": start,
            "TimeZoneOffset": timeZoneOffset
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: -1)))
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode(SpotlightMainResponse.self, from: data)
                completion(.success(decodedResponse))
            } catch {
                print("Decoding Error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
}
