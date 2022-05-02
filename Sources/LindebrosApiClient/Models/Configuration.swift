import Foundation

public extension Client {
    struct Configuration {
        public init(
            baseURL: URL,
            credentialsProvider: CredentialsProvider? = nil,
            clientCredentials: Client.ClientCredentials? = nil,
            urlSession: URLSessionProvider = URLSession.shared,
            keydecodingStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase
        ) {
            self.baseURL = baseURL
            self.clientCredentials = clientCredentials
            self.urlSession = urlSession
            self.credentialsProvider = credentialsProvider
            self.keydecodingStrategy = keydecodingStrategy
        }

        public let baseURL: URL
        public let clientCredentials: ClientCredentials?
        public let urlSession: URLSessionProvider
        public let credentialsProvider: CredentialsProvider?
        public let keydecodingStrategy: JSONDecoder.KeyDecodingStrategy
    }
}
