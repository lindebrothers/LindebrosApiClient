import Foundation

public extension Client {
    struct Configuration: Sendable {
        public init(
            baseURL: URL,
            credentialsProvider: CredentialsProvider? = nil,
            urlSession: URLSessionProvider = URLSession.shared,
            keydecodingStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase,
            nonConformingFloatStrategy: JSONEncoder.NonConformingFloatEncodingStrategy = .convertToString(
                positiveInfinity: "+Infinity", negativeInfinity: "-Infinity", nan: "Nan"
            ),
            timeout: TimeInterval? = nil
        ) {
            self.baseURL = baseURL
            self.urlSession = urlSession
            self.credentialsProvider = credentialsProvider
            self.keydecodingStrategy = keydecodingStrategy
            self.nonConformingFloatStrategy = nonConformingFloatStrategy
            self.timeout = timeout
        }

        public let baseURL: URL
        public let credentialsProvider: CredentialsProvider?
        public let urlSession: URLSessionProvider
        public let keydecodingStrategy: JSONDecoder.KeyDecodingStrategy
        public let nonConformingFloatStrategy: JSONEncoder.NonConformingFloatEncodingStrategy
        public let timeout: TimeInterval?
    }
}
