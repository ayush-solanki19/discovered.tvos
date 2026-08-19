//
//  SuggestionAPIService.swift
//  discovered.tvos
//
//  Fetches video suggestions and recommendations based on current video using get_related_video API
//

import Foundation

class SuggestionAPIService {
    static let shared = SuggestionAPIService()

    private let session = URLSession.shared
    private let getRelatedVideoURL = "https://discovered.tv/api/v3/appdashboard/get_related_video"

    func fetchRelatedVideos(userId: String, start: Int = 0, limit: Int = 20, completion: @escaping ([RelatedVideo]?) -> Void) {
        let boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW"
        var body = ""
        body += "--\(boundary)\r\n"
        body += "Content-Disposition: form-data; name=\"uid\"\r\n\r\n"
        body += userId + "\r\n"
        body += "--\(boundary)\r\n"
        body += "Content-Disposition: form-data; name=\"start\"\r\n\r\n"
        body += "\(start)\r\n"
        body += "--\(boundary)\r\n"
        body += "Content-Disposition: form-data; name=\"limit\"\r\n\r\n"
        body += "\(limit)\r\n"
        body += "--\(boundary)--\r\n"

        guard let url = URL(string: getRelatedVideoURL) else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("TIZEN", forHTTPHeaderField: "device")
        request.httpBody = body.data(using: .utf8)

        session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Get Related Video API Error: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let data = data else {
                print("No data received")
                completion(nil)
                return
            }

            do {
                let decoder = JSONDecoder()
                let apiResponse = try decoder.decode(RelatedVideoResponse.self, from: data)
                print("Fetched \(apiResponse.related_video.slider.count) related videos")
                completion(apiResponse.related_video.slider)
            } catch {
                print("Decode Error: \(error.localizedDescription)")
                completion(nil)
            }
        }.resume()
    }

    func fetchSuggestions(userId: String, completion: @escaping ([RelatedVideo]?) -> Void) {
        fetchRelatedVideos(userId: userId, start: 0, limit: 20, completion: completion)
    }
}
