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

    // MARK: - Get User Profile
    func getUserProfile(
        userId: String = "215",
        timeZoneOffset: String = "-530",
        completion: @escaping (Result<UserProfileResponse, Error>) -> Void
    ) {
        guard let token = AuthManager.shared.authToken else {
            completion(.failure(NetworkError.server(message: "No auth token available")))
            return
        }

        let baseURLString = APIConstants.getFullURL(for: APIConstants.Endpoints.getUserProfile)
        let principal = "83d63cf713964c3eccf7e87480ee5b7d0fd02a23a46f16a0f619d280c0492563"
        let urlString = "\(baseURLString)?principal=\(principal)"

        guard let url = URL(string: urlString) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }

        // Create form-data body
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()

        // Add user_id parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"user_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(userId)\r\n".data(using: .utf8)!)

        // Add TimeZoneOffset parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"TimeZoneOffset\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(timeZoneOffset)\r\n".data(using: .utf8)!)

        // End boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "Authorization")
        request.setValue("ANDROID", forHTTPHeaderField: "device")
        request.httpBody = body

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
                let decodedResponse = try JSONDecoder().decode(UserProfileResponse.self, from: data)
                completion(.success(decodedResponse))
            } catch {
                print("Get Profile Decoding Error: \(error)")
                print("Response: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
                completion(.failure(NetworkError.decodingFailed))
            }
        }.resume()
    }

    // MARK: - My Channel

    /// Loads a creator's channel (profile + their videos).
    ///
    /// The endpoint accepts requests without an Authorization header, so this
    /// also works while logged out; the token is sent when one is available.
    func fetchMyChannel(
        userId: String,
        completion: @escaping (Result<ChannelResponse, Error>) -> Void
    ) {
        let baseURLString = APIConstants.getFullURL(for: APIConstants.Endpoints.myChannel)
        let principal = "83d63cf713964c3eccf7e87480ee5b7d0fd02a23a46f16a0f619d280c0492563"
        let urlString = "\(baseURLString)?principal=\(principal)"

        guard let url = URL(string: urlString) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"user_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(userId)\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("ANDROID", forHTTPHeaderField: "device")
        if let token = AuthManager.shared.authToken {
            request.setValue(token, forHTTPHeaderField: "Authorization")
        }
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(ChannelResponse.self, from: data)

                guard decoded.status == 1 else {
                    completion(.failure(NetworkError.server(
                        message: decoded.message ?? "Unable to load this channel."
                    )))
                    return
                }

                completion(.success(decoded))
            } catch {
                print("My Channel Decoding Error: \(error)")
                completion(.failure(NetworkError.decodingFailed))
            }
        }.resume()
    }

    // MARK: - Search Content

    @discardableResult
    func searchContent(
        query: String,
        start: Int = 0,
        limit: Int = 20,
        completion: @escaping (Result<SearchResponse, Error>) -> Void
    ) -> URLSessionDataTask? {
        let urlString = APIConstants.getFullURL(for: APIConstants.Endpoints.searchContent)

        guard let url = URL(string: urlString) else {
            completion(.failure(NetworkError.invalidURL))
            return nil
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        let formFields: [(String, String)] = [
            ("search_query", query),
            ("start", String(start)),
            ("limit", String(limit))
        ]

        for (name, value) in formFields {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        var request = URLRequest(url: url, timeoutInterval: 60)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("TIZEN", forHTTPHeaderField: "device")

        if let token = AuthManager.shared.authToken {
            request.setValue(token, forHTTPHeaderField: "Authorization")
        }

        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error as NSError?, error.code != NSURLErrorCancelled {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                if error == nil {
                    completion(.failure(NetworkError.noData))
                }
                return
            }

            do {
                if let arrayResponse = try? JSONDecoder().decode([SearchContentItem].self, from: data) {
                    completion(.success(SearchResponse(items: arrayResponse)))
                    return
                }

                let decoded = try JSONDecoder().decode(SearchResponse.self, from: data)
                completion(.success(decoded))
            } catch {
                print("Search Decoding Error: \(error)")
                print("Response: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
                completion(.failure(NetworkError.decodingFailed))
            }
        }
        task.resume()
        return task
    }
}
