import Combine
import Foundation
import SwiftUI

extension Client.Request {
    private func logResponse(url: URL?, httpStatus: Client.HttpStatusCode, resp: HTTPURLResponse?, data: Data?) {
        switch loggingStrategy ?? config?.loggingStrategy ?? .none {
        case .normal:
            config?.logger?.info("\(httpStatus.logIcon) [\(httpStatus.rawValue)] \(url?.path ?? "")", file: "LindebrosApiClient", line: 0)
        case .raw:
            let method = Client.HttpMethod(rawValue: urlRequest?.httpMethod ?? "unknown")
            config?.logger?.info("""

            Response:
            \(httpStatus.logIcon) \(httpStatus.rawValue) [\(method?.rawValue ?? "unknown")] \(url?.path ?? "")
            \(resp?.getHeaders().joined(separator: "\n") ?? "")

            \(resp?.getJSONBody(with: data) ?? "")
            """, file: "LindebrosApiClient", line: 0)
        default:
            break
        }
    }

    private func logRequest() {
        guard
            let urlRequest = urlRequest,
            let url = urlRequest.url,
            let method = Client.HttpMethod(rawValue: urlRequest.httpMethod ?? "unknown")
        else { return}

        let token = urlRequest.value(forHTTPHeaderField: "Authorization")

        switch loggingStrategy ?? config?.loggingStrategy ?? .none {
        case .raw:
            config?.logger?.info("""

            Request:

            \(method.rawValue) \(url)
            \(getHeaders().joined(separator: "\n"))

            \(getJSONBody() ?? "")
            """, file: "LindebrosApiClient", line: 0)

        case .normal:
            config?.logger?.info("📤 [\(method.rawValue)] \(url.path) \(url.query ?? "") \(token ?? "")", file: "LindebrosApiClient", line: 0)
        default:
            break
        }
    }

    public func dispatch() async throws {
        let _ : Client.EmptyResponse = try await dispatch()
    }

    public func dispatch<Model: Decodable>() async throws -> Model {
        logRequest()
        // Make the request
        do {
            guard let config = config else {
                throw Client.ErrorResponse(message: "Configuration is not provided", status: .unknown)
            }

            let response: Client.Response<Model> = try await asyncRequest(urlSession: config.urlSession)

            return response.model

        } catch let e {
            // If client credentials token has expired, fetch a new token and make the request again.
            if

                let errorResponse = e as? Client.ErrorResponse,
                errorResponse.status == .unauthorized || errorResponse.status == .forbidden,
                let config = config,
                let credentialsProvider = config.credentialsProvider,
                let newCredentials = await credentialsProvider.fetchNewCredentials()
            {
                config.logger?.info("🔑 Received new token")

                await config.credentialsProvider?.setCredentials(to: newCredentials)

                // Make the requeat again
                let response: Client.Response<Model> = try await authenticate(by: config.credentialsProvider?.provideCredentials()).asyncRequest(urlSession: config.urlSession)
                return response.model
            }

            // Throw it again if error is not handled
            throw e
        }
    }
}

public extension Client.Request {
    func asyncRequest<Model: Decodable>() async throws -> Client.Response<Model> {
        guard let config = config else {
            throw Client.ErrorResponse(message: "Configuration is not provided", status: .unknown)
        }
        return try await asyncRequest(urlSession: config.urlSession)
    }

    func asyncRequest<Model: Decodable>(urlSession: URLSessionProvider) async throws -> Client.Response<Model> {
        guard let urlRequest = urlRequest else {
            throw Client.ErrorResponse(message: "Invalid URL", status: .badRequest)
        }

        let (data, resp) = try await urlSession.data(for: urlRequest)

        let response = resp as? HTTPURLResponse

        let httpStatus = Client.HttpStatusCode(rawValue: response?.statusCode ?? 0) ?? .unknown

        let jsonDecoder = JSONDecoder()
        (decodingOptions ?? []).forEach { option in
            option.populateValues(to: jsonDecoder)
        }

        logResponse(url: urlRequest.url, httpStatus: httpStatus, resp: response, data: data)

        if httpStatus.isOk() {
            if data.isEmpty {
                return try Client.Response(model: JSONDecoder().decodeIfEmpty(Model.self), status: httpStatus)
            } else {
                return try Client.Response(model: jsonDecoder.decode(Model.self, from: data), status: httpStatus)
            }
        }

        throw Client.ErrorResponse(message: "Service responded with error", status: httpStatus, data: data)
    }

    func setQueryIfNeeded(with state: QuerystringState? = nil) -> Self {
        guard
            var urlRequest = urlRequest,
            let state = state,
            let newURL = updateURL(with: state)
        else {
            return self
        }

        urlRequest.url = newURL

        return clone(with: urlRequest)
    }
}

extension Client.Request {
    var contentType: Client.ContentType? {
        guard let urlRequest = urlRequest else { return nil }
        guard let contentType = urlRequest.allHTTPHeaderFields?.filter({ $0.key == "Content-Type" }).map({ $0.value }).first else { return nil }
        return Client.ContentType(rawValue: contentType)
    }

    func clone(with urlRequest: URLRequest, andConfig config: Client.Configuration? = nil, decodingOptions: [Client.DecodingConfigType]? = nil, loggingStrategy: LoggingStrategy? = nil) -> Self {
        Client.Request(urlRequest: urlRequest, config: config ?? self.config, decodingOptions: decodingOptions ?? self.decodingOptions, loggingStrategy: loggingStrategy ?? self.loggingStrategy)
    }

    func updateURL(with newQuery: QuerystringState) -> URL? {
        guard
            let urlString = urlRequest?.url?.absoluteString,
            var components = URLComponents(string: urlString)
        else {
            return nil
        }
        let state = QuerystringState(queryString: components.query ?? "")
            .clone(overwriteWith: newQuery.keyValues)

        components.percentEncodedQueryItems = state.asURLQueryItemsPercentageEncoded

        return components.url
    }

    private func port(of reguest: URLRequest) -> String {
        if let port = reguest.url?.port {
            return "\(port)"
        }
        return ""
    }

    private func getJSONBody() -> String? {
        guard let data = urlRequest?.httpBody else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func getHeaders() -> [String] {
        if let headers = urlRequest?.allHTTPHeaderFields {
            return headers.map { key, value in
                "\(key): \(value)"
            }
        }
        return []
    }
}
