import Foundation

public protocol ClientProvider {
    func get<Model: Decodable>(_ endpoint: String, with state: QuerystringState?) async throws -> Model?

    func post<PostModel: Encodable, Model: Decodable>(_ model: PostModel, to endpoint: String, contentType: Client.ContentType) async throws -> Model?

    func put<PutModel: Encodable, Model: Decodable>(_ model: PutModel, to endpoint: String, contentType: Client.ContentType) async throws -> Model?

    func delete<Model: Decodable>(_ endpoint: String, with state: QuerystringState?) async throws -> Model?
}

public struct Client: ClientProvider {
    /**
     Init Client
     - parameter configuration: Configuration of the Client
     */
    public init(
        configuration: Client.Configuration
    ) {
        self.configuration = configuration
    }

    public init(
        _ configuration: Client.Configuration
    ) {
        self.configuration = configuration
    }

    public let configuration: Client.Configuration

    /**
     makes a GET request
     - parameter endpoint: Path to endpoint
     - parameter with state: Querystring parameter representation
     - returns Model with populated data
     */
    @MainActor public func get<Model: Decodable>(_ endpoint: String, with state: QuerystringState? = nil) async throws -> Model? {
        try await Request(url: URL(string: endpoint, relativeTo: configuration.baseURL))
            .setQueryIfNeeded(with: state)
            .setMethod(.get)
            .setAcceptJSON()
            .authenticate(by: configuration.credentialsProvider?.provideCredentials())
            .dispatch(with: configuration)
    }

    /**
     makes a POST request
     - parameter model: The data to send
     - parameter to endpoint: Path to endpoint
     - parameter contentType: The type of data, json or form.
     - returns Model with populated data
     */
    @MainActor public func post<PostModel: Encodable, Model: Decodable>(_ model: PostModel, to endpoint: String, contentType: ContentType = .json) async throws -> Model? {
        try await Request(url: URL(string: endpoint, relativeTo: configuration.baseURL))
            .setMethod(.post)
            .setContentType(contentType)
            .setBody(model: model)
            .setAcceptJSON()
            .authenticate(by: configuration.credentialsProvider?.provideCredentials())
            .dispatch(with: configuration)
    }

    /**
     makes a PUT request
     - parameter model: The data to send
     - parameter to endpoint: Path to endpoint
     - parameter contentType: The type of data, json or form.
     - returns Model with populated data
     */
    @MainActor public func put<PutModel: Encodable, Model: Decodable>(_ model: PutModel, to endpoint: String, contentType: ContentType = .json) async throws -> Model? {
        try await Request(url: URL(string: endpoint, relativeTo: configuration.baseURL))
            .setMethod(.put)
            .setContentType(contentType)
            .setBody(model: model)
            .setAcceptJSON()
            .authenticate(by: configuration.credentialsProvider?.provideCredentials())
            .dispatch(with: configuration)
    }

    /**
     makes a DELETE request
     - parameter endpoint: Path to endpoint
     - parameter with state: Querystring parameter representation
     - returns Model with populated data
     */
    @MainActor public func delete<Model: Decodable>(_ endpoint: String, with state: QuerystringState? = nil) async throws -> Model? {
        try await Request(url: URL(string: endpoint, relativeTo: configuration.baseURL))
            .setQueryIfNeeded(with: state)
            .setMethod(.delete)
            .setAcceptJSON()
            .authenticate(by: configuration.credentialsProvider?.provideCredentials())
            .dispatch(with: configuration)
    }

    /**
     returns a request object without making a request
     - parameter endpoint: Path to endpoint
     - returns a Request
     */
    public func endpoint(_ endpoint: String) -> Request {
        Request(url: URL(string: endpoint, relativeTo: configuration.baseURL))
    }
}
