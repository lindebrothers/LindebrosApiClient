import Foundation

public extension Client {
    struct Response<Model: Sendable>: Sendable {
        public let model: Model?
        public let status: HttpStatusCode
    }

    struct ErrorResponse: Error, Sendable, Codable {
        public init(message: String? = nil, status: HttpStatusCode, data: Data? = nil) {
            self.message = message
            self.status = status
            self.data = data
        }

        public var message: String?
        public var status: HttpStatusCode
        public var data: Data?
    }

    struct EmptyResponse: Sendable, Codable {}
}
