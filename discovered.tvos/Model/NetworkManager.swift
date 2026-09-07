//
//  NetworkManager.swift
//  discovered.tvos
//
//  Created by mac mini on 17/08/26.
//

import Foundation
import UIKit

enum NetworkError: LocalizedError {
    case invalidURL
    case noData
    case decodingFailed
    case server(message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL."
        case .noData:
            return "No data received from server."
        case .decodingFailed:
            return "Unable to read server response."
        case .server(let message):
            return message
        }
    }
}

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

    // MARK: - Login
    func login(
        email: String,
        password: String,
        firebaseToken: String = "",
        loginFrom: String = "IOS",
        completion: @escaping (Result<LoginResponse, Error>) -> Void
    ) {
        let urlString = APIConstants.getFullURL(for: APIConstants.Endpoints.allowLoginAccess)

        guard let url = URL(string: urlString) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }

        let boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW"

        let formFields: [(String, String)] = [
            ("u_em", email),
            ("u_pwd", password),
            ("firebase_token", firebaseToken),
            ("login_from", loginFrom)
        ]

        var body = ""
        for (name, value) in formFields {
            body += "--\(boundary)\r\n"
            body += "Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n"
            body += "\(value)\r\n"
        }
        body += "--\(boundary)--\r\n"

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("IOS", forHTTPHeaderField: "device")
        request.httpBody = body.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode(LoginResponse.self, from: data)

                if decodedResponse.status == 1 {
                    completion(.success(decodedResponse))
                } else {
                    completion(.failure(NetworkError.server(message: decodedResponse.message ?? "Login failed.")))
                }
            } catch {
                print("Login Decoding Error: \(error)")
                completion(.failure(NetworkError.decodingFailed))
            }
        }.resume()
    }
}
