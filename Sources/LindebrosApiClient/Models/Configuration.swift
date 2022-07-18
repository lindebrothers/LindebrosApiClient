import Foundation

public extension Client {
    struct Configuration {
        public init(
            baseURL: URL,
            credentialsProvider: CredentialsProvider? = nil,
            authenticator: AuthenticatorProvider? = nil,
            urlSession: URLSessionProvider = URLSession.shared,
            keydecodingStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase,
            timeout: TimeInterval? = nil
        ) {
            self.baseURL = baseURL
            self.authenticator = authenticator
            self.urlSession = urlSession
            self.credentialsProvider = credentialsProvider
            self.keydecodingStrategy = keydecodingStrategy
            self.timeout = timeout
        }

        public let baseURL: URL
        public let credentialsProvider: CredentialsProvider?
        public let authenticator: AuthenticatorProvider?
        public let urlSession: URLSessionProvider
        public let keydecodingStrategy: JSONDecoder.KeyDecodingStrategy
        public let timeout: TimeInterval?
    }
}

public protocol AuthenticatorProvider {
    func fetchNewCredentials() async -> Client.Credentials?
}
