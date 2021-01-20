import Foundation

/// The API response object. This is a wrapper that stores info about the API Response
public struct ApiResponse<Model: Decodable, ErrorModel: Decodable> {
    /// Was the Request successful?
    public var isOk: Bool

    /// HTTP Status of the response
    public var status: HTTPStatusCode

    /// The model that was populated with data, if successful
    public var data: Model?

    /// The error model when API responded with errors
    public var errorModel: ErrorModel?

    /// Error
    public var error: [Error]?
}

