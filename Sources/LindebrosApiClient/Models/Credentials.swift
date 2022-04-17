import Foundation

public extension Client {
    struct Credentials: Codable {
        public init(
            accessToken: String,
            tokenType: String = "",
            expiresIn: TimeInterval = 0,
            refreshToken: String? = nil,
            userId: String? = nil
        ) {
            self.accessToken = accessToken
            self.userId = userId
            // Client is not really interested in these values except for providing them to the credentials provider when fetching a new token.
            self.tokenType = tokenType
            self.expiresIn = expiresIn
            self.refreshToken = refreshToken
        }

        public let accessToken: String
        public let tokenType: String
        public let expiresIn: TimeInterval
        public let refreshToken: String?
        public let userId: String?

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case tokenType = "token_type"
            case expiresIn = "expires_in"
            case refreshToken = "refresh_token"
            case userId = "user_id"
        }

        /// True if this is a user backed credential (signed in)
        public var isUserCredential: Bool {
            return userId != nil
        }
    }
}

// MARK: - CustomStringConvertible

extension Client.Credentials: CustomStringConvertible {
    public var description: String {
        return accessToken
    }
}

// MARK: - Keychain

public protocol CredentialsProvider {
    func provideCredentials() -> Client.Credentials?
    func setCredentials(to: Client.Credentials) -> Void
}

public extension Client {
    struct ClientCredentials: Codable {
        public init(
            clientSecret: String,
            clientId: String
        ) {
            self.clientSecret = clientSecret
            self.clientId = clientId
        }

        public var clientSecret, clientId: String
        public var grantType = "client_credentials"
    }
}
