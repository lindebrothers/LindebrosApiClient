import Combine
import Foundation
import SwiftUI

extension Client.Request {
    private func logResponse(of url: URL?, with status: Client.HttpStatusCode) {
        let path = url != nil ? "\(url?.path ?? "") " : ""
        Client.ClientLogger.shared.info("✅ [\(status.rawValue)] \(path)")
    }

    @MainActor public func dispatch<Model: Decodable>() async throws -> Model? {
        Client.ClientLogger.shared.info(self)

        // Make the request
        do {
            guard let config = config else {
                throw Client.ErrorResponse(message: "Configuration is not provided", status: .unknown)
            }

            let response: Client.Response<Model> = try await asyncRequest(urlSession: config.urlSession)

            logResponse(of: urlRequest?.url, with: response.status)
            return response.model

        } catch let e {
            // If client credentials token has expired, fetch a new token and make the request again.
            if

                let errorResponse = e as? Client.ErrorResponse,
                errorResponse.status == .unauthorized || errorResponse.status == .forbidden,
                let config = config,
                let credentialsProvider = config.credentialsProvider,
                let newCredentials = await credentialsProvider.fetchNewCredentials() {
                Client.ClientLogger.shared.info("🔑 Received new token")
                config.credentialsProvider?.setCredentials(to: newCredentials)

                // Make the requeat again
                let response: Client.Response<Model> = try await authenticate(by: config.credentialsProvider?.provideCredentials()).asyncRequest(urlSession: config.urlSession)
                logResponse(of: urlRequest?.url, with: response.status)
                return response.model
            }

            // Throw it again if error is not handled
            throw e
        }
    }
}

public extension Client.Request {
    func asyncRequest<Model: Decodable>() async throws -> Client.Response<Model> {
        guard let config = self.config else {
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
        jsonDecoder.keyDecodingStrategy = config?.keydecodingStrategy ?? .convertFromSnakeCase
        if httpStatus.isOk() {
            if data.count > 0 {
                return Client.Response(
                    model: try jsonDecoder.decode(Model.self, from: data),
                    status: httpStatus
                )
            }
            return Client.Response(model: nil, status: httpStatus)
        }

        throw Client.ErrorResponse(message: "Service responded with error", status: httpStatus, data: data)
    }

    func setQueryIfNeeded(with state: QuerystringState? = nil) -> Self {
        guard
            var urlRequest = self.urlRequest,
            let state = state,
            let newURL = updateURL(with: state)
        else {
            return self
        }

        urlRequest.url = newURL

        return clone(with: urlRequest, andConfig: config)
    }
}

extension Client.Request {
    var contentType: Client.ContentType? {
        guard let urlRequest = self.urlRequest else { return nil }
        guard let contentType = urlRequest.allHTTPHeaderFields?.filter({ $0.key == "Content-Type" }).map({ $0.value }).first else { return nil }
        return Client.ContentType(rawValue: contentType)
    }

    func clone(with urlRequest: URLRequest, andConfig config: Client.Configuration?) -> Self {
        Client.Request(urlRequest: urlRequest, config: config)
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

        components.queryItems = state.asURLQueryItems

        return components.url
    }

    private func port(of reguest: URLRequest) -> String {
        if let port = reguest.url?.port {
            return "\(port)"
        }
        return ""
    }
}
