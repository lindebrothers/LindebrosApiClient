import Foundation

public extension Client {
    struct Configuration: Sendable {
        public init(
            baseURL: URL,
            credentialsProvider: CredentialsProvider? = nil,
            urlSession: URLSessionProvider = URLSession.shared,
            keydecodingStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase,
            dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601,
            nonConformingFloatStrategy: JSONEncoder.NonConformingFloatEncodingStrategy = .convertToString(
                positiveInfinity: "+Infinity", negativeInfinity: "-Infinity", nan: "Nan"
            ),
            timeout: TimeInterval? = nil
        ) {
            self.baseURL = baseURL
            self.urlSession = urlSession
            self.credentialsProvider = credentialsProvider
            self.keydecodingStrategy = keydecodingStrategy
            self.dateDecodingStrategy = dateDecodingStrategy
            self.nonConformingFloatStrategy = nonConformingFloatStrategy
            self.timeout = timeout
        }

        public let baseURL: URL
        public let credentialsProvider: CredentialsProvider?
        public let urlSession: URLSessionProvider
        public let keydecodingStrategy: JSONDecoder.KeyDecodingStrategy
        public let dateDecodingStrategy: JSONDecoder.DateDecodingStrategy
        public let nonConformingFloatStrategy: JSONEncoder.NonConformingFloatEncodingStrategy
        public let timeout: TimeInterval?
    }
}
