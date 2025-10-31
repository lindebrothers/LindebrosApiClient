import Foundation

public protocol ClientProvider: Sendable {
    func get(_ endpoint: String, with state: QuerystringState?, decodingOptions: [Client.DecodingConfigType]?, loggingStrategy: LoggingStrategy?) async -> Client.Request

    func post<PostModel: Encodable>(_ model: PostModel, to endpoint: String, encodingConfig: [Client.EncodingConfigType]?, decodingOptions: [Client.DecodingConfigType]?, loggingStrategy: LoggingStrategy?) async -> Client.Request

    func put<PutModel: Encodable>(_ model: PutModel, to endpoint: String, encodingConfig: [Client.EncodingConfigType]?, decodingOptions: [Client.DecodingConfigType]?, loggingStrategy: LoggingStrategy?) async -> Client.Request

    func patch<PutModel: Encodable>(_ model: PutModel, to endpoint: String, encodingConfig: [Client.EncodingConfigType]?, decodingOptions: [Client.DecodingConfigType]?, loggingStrategy: LoggingStrategy?) async -> Client.Request

    func delete(_ endpoint: String, with state: QuerystringState?, decodingOptions: [Client.DecodingConfigType]?, loggingStrategy: LoggingStrategy?) async -> Client.Request

    func endpoint(_ endpoint: String, decodingOptions: [Client.DecodingConfigType]?, loggingStrategy: LoggingStrategy?) -> Client.Request
}

public extension ClientProvider {
    func get(_ endpoint: String, with state: QuerystringState? = nil, decodingOptions: [Client.DecodingConfigType]? = nil, loggingStrategy: LoggingStrategy? = nil) async -> Client.Request {
        await get(endpoint, with: state, decodingOptions: decodingOptions, loggingStrategy: loggingStrategy)
    }

    func post<PostModel: Encodable>(_ model: PostModel, to endpoint: String, encodingConfig: [Client.EncodingConfigType]? = nil, decodingOptions: [Client.DecodingConfigType]? = nil, loggingStrategy: LoggingStrategy? = nil) async -> Client.Request {
        await post(model, to: endpoint, encodingConfig: encodingConfig, decodingOptions: decodingOptions, loggingStrategy: loggingStrategy)
    }

    func put<PutModel: Encodable>(_ model: PutModel, to endpoint: String, encodingConfig: [Client.EncodingConfigType]? = nil, decodingOptions: [Client.DecodingConfigType]? = nil, loggingStrategy: LoggingStrategy? = nil) async -> Client.Request {
        await put(model, to: endpoint, encodingConfig: encodingConfig, decodingOptions: decodingOptions, loggingStrategy: loggingStrategy)
    }

    func patch<PutModel: Encodable>(_ model: PutModel, to endpoint: String, encodingConfig: [Client.EncodingConfigType]? = nil, decodingOptions: [Client.DecodingConfigType]? = nil, loggingStrategy: LoggingStrategy? = nil) async -> Client.Request {
        await patch(model, to: endpoint, encodingConfig: encodingConfig, decodingOptions: decodingOptions, loggingStrategy: loggingStrategy)
    }

    func delete(_ endpoint: String, with state: QuerystringState? = nil, decodingOptions: [Client.DecodingConfigType]? = nil, loggingStrategy: LoggingStrategy? = nil) async -> Client.Request {
        await delete(endpoint, with: state, decodingOptions: decodingOptions, loggingStrategy: loggingStrategy)
    }

    func endpoint(_ endpointStr: String, decodingOptions: [Client.DecodingConfigType]? = nil, loggingStrategy: LoggingStrategy? = nil) -> Client.Request {
        endpoint(endpointStr, decodingOptions: decodingOptions, loggingStrategy: loggingStrategy)
    }
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
    public func get(_ endpoint: String, with state: QuerystringState?, decodingOptions: [Client.DecodingConfigType]?, loggingStrategy: LoggingStrategy?) async -> Request {
        Request(url: URL(string: endpoint, relativeTo: configuration.baseURL), decodingOptions: decodingOptions, loggingStrategy: loggingStrategy)
            .authenticate(by: await configuration.credentialsProvider?.provideCredentials())
            .setQueryIfNeeded(with: state)
            .setMethod(.get)
            .setAcceptJSON()
            .setConfig(configuration)
    }

    /**
     makes a POST request
     - parameter model: The data to send
     - parameter to endpoint: Path to endpoint
     - parameter encodingConfig: Encoding options
     - returns Model with populated data
     */
    public func post<PostModel: Encodable>(_ model: PostModel, to endpoint: String, encodingConfig: [Client.EncodingConfigType]?, decodingOptions: [Client.DecodingConfigType]?, loggingStrategy: LoggingStrategy?) async -> Request {
        Request(url: URL(string: endpoint, relativeTo: configuration.baseURL), decodingOptions: decodingOptions, loggingStrategy: loggingStrategy)
            .authenticate(by: await configuration.credentialsProvider?.provideCredentials())
            .setMethod(.post)
            .setContentType(encodingConfig?.first(where: { $0.isContentType })?.contentType ?? .json)
            .setBody(model: model, encodingConfig: encodingConfig)
            .setAcceptJSON()
            .setConfig(configuration)
    }

    /**
     makes a PUT request
     - parameter model: The data to send
     - parameter to endpoint: Path to endpoint
     - parameter encodingConfig: Encoding options
     - returns Model with populated data
     */
    public func put<PutModel: Encodable>(_ model: PutModel, to endpoint: String, encodingConfig: [Client.EncodingConfigType]?, decodingOptions: [Client.DecodingConfigType]?, loggingStrategy: LoggingStrategy?) async -> Request {
        Request(url: URL(string: endpoint, relativeTo: configuration.baseURL), decodingOptions: decodingOptions, loggingStrategy: loggingStrategy)
            .authenticate(by: await configuration.credentialsProvider?.provideCredentials())
            .setMethod(.put)
            .setContentType(encodingConfig?.first(where: { $0.isContentType })?.contentType ?? .json)
            .setBody(model: model, encodingConfig: encodingConfig)
            .setAcceptJSON()
            .setConfig(configuration)
    }

    /**
     makes a PATCH request
     - parameter model: The data to send
     - parameter to endpoint: Path to endpoint
     - parameter encodingConfig: Encoding options
     - returns Model with populated data
     */
    public func patch<PutModel: Encodable>(_ model: PutModel, to endpoint: String, encodingConfig: [Client.EncodingConfigType]?, decodingOptions: [Client.DecodingConfigType]?, loggingStrategy: LoggingStrategy?) async -> Request {
        Request(url: URL(string: endpoint, relativeTo: configuration.baseURL), decodingOptions: decodingOptions, loggingStrategy: loggingStrategy)
            .authenticate(by: await configuration.credentialsProvider?.provideCredentials())
            .setMethod(.patch)
            .setContentType(encodingConfig?.first(where: { $0.isContentType })?.contentType ?? .json)
            .setBody(model: model, encodingConfig: encodingConfig)
            .setAcceptJSON()
            .setConfig(configuration)
    }

    /**
     makes a DELETE request
     - parameter endpoint: Path to endpoint
     - parameter with state: Querystring parameter representation
     - returns Model with populated data
     */
    public func delete(_ endpoint: String, with state: QuerystringState? = nil, decodingOptions: [Client.DecodingConfigType]?, loggingStrategy: LoggingStrategy?) async -> Request {
        Request(
            url: URL(string: endpoint, relativeTo: configuration.baseURL),
            decodingOptions: decodingOptions,
            loggingStrategy: loggingStrategy
        )
        .authenticate(by: await configuration.credentialsProvider?.provideCredentials())
        .setQueryIfNeeded(with: state)
        .setMethod(.delete)
        .setAcceptJSON()
        .setConfig(configuration)
    }

    /**
     returns a request object without making a request
     - parameter endpoint: Path to endpoint
     - returns a Request
     */
    public func endpoint(_ endpoint: String, decodingOptions: [Client.DecodingConfigType]? = nil, loggingStrategy: LoggingStrategy?) -> Request {
        Request(url: URL(string: endpoint, relativeTo: configuration.baseURL), decodingOptions: decodingOptions, loggingStrategy: loggingStrategy)
    }
}
