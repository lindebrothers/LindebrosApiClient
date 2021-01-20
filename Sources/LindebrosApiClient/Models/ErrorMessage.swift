import Foundation

/// Common Error Protocol
public protocol ErrorResponse {
    var message: String? { get set }
}

/// Common Error Message
public struct ErrorMessage: Codable, ErrorResponse {
    public var message: String?
}

public struct FileNotFound: Error {}
