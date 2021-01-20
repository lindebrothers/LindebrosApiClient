import Foundation

/// The API response object. This is a wrapper that stores info about the API Response
public struct ApiResponse<Model: Codable, ErrorModel: Codable> {
    /// Was the Request successful?
    var isOk: Bool

    /// HTTP Status of the response
    var status: HTTPStatusCode

    /// The model that was populated with data, if successful
    var data: Model?

    /// The error model when API responded with errors
    var errorModel: ErrorModel?

    /// Error
    var error: [Error]?
}

