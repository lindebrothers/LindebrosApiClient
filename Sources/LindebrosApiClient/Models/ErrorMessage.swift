import Foundation

/// Common Error Protocol
protocol ErrorResponse {
    var message: String? { get set }
}

/// Common Error Message
struct ErrorMessage: Codable, ErrorResponse {
    var message: String?
}

struct FileNotFound: Error {}
