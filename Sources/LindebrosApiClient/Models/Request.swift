import Foundation
import os

public extension Client {
    struct Request: Sendable, CustomStringConvertible {
        public var urlRequest: URLRequest?
        let decodingOptions: [Client.DecodingConfigType]?
        var config: Configuration?
        var loggingStrategy: LoggingStrategy?
        public init(
            url: URL?,
            decodingOptions: [Client.DecodingConfigType]?,
            loggingStrategy: LoggingStrategy?
        ) {
            self.decodingOptions = decodingOptions
            self.loggingStrategy = loggingStrategy
            guard let url = url else { return }
            urlRequest = URLRequest(url: url)
            config = nil
        }

        public init(
            urlRequest: URLRequest,
            config: Configuration?,
            decodingOptions: [Client.DecodingConfigType]?,
            loggingStrategy: LoggingStrategy?
        ) {
            self.urlRequest = urlRequest
            self.config = config
            self.loggingStrategy = loggingStrategy

            let combinedDecodingOptions = (decodingOptions ?? []) + (config?.decodingConfig ?? [])
            var seenKeys = Set<String>()
            self.decodingOptions = combinedDecodingOptions.filter { option in
                let key = String(describing: option)
                if seenKeys.contains(key) { return false }
                seenKeys.insert(key)
                return true
            }

            if let timeout = config?.timeout {
                self.urlRequest?.timeoutInterval = timeout
            }
        }

        public func setHeader(key: String, value: String) -> Self {
            guard var urlRequest = urlRequest else { return self }
            urlRequest.setValue(value, forHTTPHeaderField: key)
            return clone(with: urlRequest)
        }

        public func setMethod(_ method: HttpMethod) -> Self {
            guard var urlRequest = urlRequest else { return self }
            urlRequest.httpMethod = method.rawValue
            return clone(with: urlRequest)
        }

        public func setBody<Model: Encodable>(model: Model, encodingConfig: [Client.EncodingConfigType]?) -> Self {
            guard var urlRequest = urlRequest else { return self }

            var seenKeys = Set<String>()
            let encodingConfig = (encodingConfig ?? []) + (config?.encodingConfig ?? []).filter { option in
                if option.isContentType {
                    return false
                }
                let key = String(describing: option)
                if seenKeys.contains(key) { return false }
                seenKeys.insert(key)
                return true
            }

            switch HttpMethod(rawValue: urlRequest.httpMethod ?? "unknown") {
            case .post, .put, .patch:
                switch contentType {
                case .json:
                    do {
                        let encoder = JSONEncoder()

                        encodingConfig.forEach { config in
                            config.populateValues(to: encoder)
                        }
                        urlRequest.httpBody = try encoder.encode(model)
                    } catch {}
                case .form:
                    urlRequest.httpBody = model.asQueryString.data(using: .utf8)
                case .none:
                    break
                }

            case .get, .delete:
                if let newURL = updateURL(with: QuerystringState(queryString: model.asRawQueryString)) {
                    urlRequest.url = newURL
                }
            case .none:
                break
            }

            return clone(with: urlRequest)
        }

        public func setContentType(_ type: ContentType) -> Self {
            setHeader(key: "Content-Type", value: type.rawValue)
        }

        public func setAcceptJSON() -> Self {
            setHeader(key: "Accept", value: "application/json")
        }

        public func authenticate(by credentials: Credentials?) -> Self {
            guard
                let credential = credentials
            else { return self }
            return setHeader(key: "Authorization", value: "Bearer \(credential.accessToken)")
        }

        public func authenticate(by token: String) -> Self {
            return setHeader(key: "Authorization", value: "Bearer \(token)")
        }

        public func setConfig(_ config: Configuration) -> Self {
            guard let urlRequest = urlRequest else { return self }
            return clone(with: urlRequest, andConfig: config)
        }

        public var description: String {
            guard
                let urlRequest = urlRequest,
                let url = urlRequest.url,
                let method = HttpMethod(rawValue: urlRequest.httpMethod ?? "unknown")
            else { return "invalid" }

            let token = urlRequest.value(forHTTPHeaderField: "Authorization")

            return "[\(method.rawValue)] \(url.path) \(url.query ?? "") \(token ?? "")"
        }

        public func modifyURLRequest(_ closure: (URLRequest) -> URLRequest) -> Self {
            guard let urlRequest = urlRequest else { return self }
            return clone(with: closure(urlRequest))
        }
    }
}
