import Foundation

struct RelatedVideoResponse: Codable {
    let related_video: RelatedVideoContainer
    let status: Int
    let type: String
    let message: String

    enum CodingKeys: String, CodingKey {
        case related_video
        case status, type, message
    }
}

struct RelatedVideoContainer: Codable {
    let slider_type: String
    let type: String
    let slider: [RelatedVideo]
}

struct RelatedVideo: Codable {
    let user_id: String
    let user_name: String
    let post_id: String
    let title: String
    let ThumbImage: String
    let videoFile: String
    let video_duration: AnyCodable
    let genre_name: String
    let description: String
    let user_cate: String
}

enum AnyCodable: Codable {
    case int(Int)
    case string(String)
    case double(Double)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) {
            self = .int(intVal)
        } else if let stringVal = try? container.decode(String.self) {
            self = .string(stringVal)
        } else if let doubleVal = try? container.decode(Double.self) {
            self = .double(doubleVal)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode AnyCodable")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .int(let value): try container.encode(value)
        case .string(let value): try container.encode(value)
        case .double(let value): try container.encode(value)
        }
    }
}
