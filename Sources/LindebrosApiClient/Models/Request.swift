import Foundation

/**
 The Request model that describes a request to the API.
 */
public struct Request<Model: Decodable, ErrorModel, RequestBodyModel: Encodable> {
    /// Describes the type of content of the body in the request

    /// The endpoint to invoke
    var endpoint: String

    /// The HTTP method to use
    var method: HttpMethod

    /// The content type of the data. See ContentType object
    var contentType: ContentType

    /// The data to send in the request
    var body: Data?

    /// Should the API combine baseUrl with the endpoint?
    var isRelativeUrl: Bool

    /// if true, the client will print the entire response to the log.
    var debugData: Bool

    /// Provides custom headers to the client. Overwrites defaults if duplications occurs
    var customHeaders: [CustomHeader]?
    /**
     The Request model that describes a request to the API.

     - parameter endpoint: The endpoint to invoke
     - parameter method: The HTTP method to use
     - parameter data: The data to send in the request
     - parameter contentType: the content type of the data. json or form
     - parameter isRelativeUrl: Should the API combine baseUrl with the endpoint?
     - parameter debugData: if true, the client will print the entire response to the log.
     */
    public init(endpoint: String, method: HttpMethod, data: RequestBodyModel? = nil, contentType: ContentType = .json, isRelativeUrl: Bool = true, debugData: Bool = false, customHeaders: [CustomHeader]? = nil) {
        self.endpoint = endpoint
        self.method = method
        self.isRelativeUrl = isRelativeUrl
        self.contentType = contentType
        self.debugData = debugData
        self.customHeaders = customHeaders

        if self.method == .post || self.method == .put, let data = data {
            switch self.contentType {
            case .json, .raw:
                do {
                    let encoder = JSONEncoder()
                    encoder.keyEncodingStrategy = .convertToSnakeCase
                    body = try encoder.encode(data)
                } catch {}
            case .form:
                body = data.asQueryString.data(using: .utf8)
            }
        }

        if self.method == .get, let data = data {
            switch self.contentType {
            case .raw:
                self.endpoint = "\(self.endpoint)?\(data.asRawQueryString)"
            default:
                self.endpoint = "\(self.endpoint)?\(data.asQueryString)"
            }
        }
    }
}

public struct Empty: Codable {}

public struct CustomHeader {
    var key: String
    var value: String
}

public enum ContentType {
    /// data will be encoded as application/x-www-form-urlencoded; charset=utf-8
    case form

    /// data will be encoded as application/json; charset=utf-8
    case json

    case raw

    /// String version of the content type to be used in the `Content-Type` header
    var header: String {
        switch self {
        case .form:
            return "application/x-www-form-urlencoded; charset=utf-8"
        case .json, .raw:
            return "application/json; charset=utf-8"
        }
    }
}
