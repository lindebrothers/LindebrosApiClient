@testable import LindebrosApiClient
import SwiftUI
import XCTest

class ClientRequestTests: XCTestCase {
    func testURLManagement() throws {
        let request = Client.Request(url: URL(string: "https://www.lindebros.com:43/awesome?a=b"))
            .updateURL(with: QuerystringState(queryString: "c=d&e=f"))

        XCTAssertEqual(try XCTUnwrap(request?.absoluteString), "https://www.lindebros.com:43/awesome?a=b&c=d&e=f")
    }
}

struct Model: Codable {
    var label: String
    var secondLabel: String
}

class URLSessionSpy: URLSessionProvider {
    var requests: [URLRequest] = []

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .background).async { [weak self] in
                do {
                    self?.requests.append(request)

                    let encoder = JSONEncoder()

                    let urlResponse = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!

                    switch request.url?.path {
                    case "/auth/v1/oauth/tokens":
                        let credentials = Client.Credentials(accessToken: "123", tokenType: "client", expiresIn: 1000)
                        continuation.resume(returning: (try encoder.encode(credentials), urlResponse))
                    case "/awesome":
                        guard
                            let auth = request.allHTTPHeaderFields?.first(where: { $0.key == "Authorization" })?.value,
                            auth.contains("Bearer")
                        else {
                            return continuation.resume(returning: (Data(), HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!))
                        }

                        let model = Model(label: "Awesome", secondLabel: "Very Awesome")
                        continuation.resume(returning: (try encoder.encode(model), urlResponse))

                    default:
                        continuation.resume(returning: ("not found".data(using: .utf8)!, HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!))
                    }
                } catch let e {
                    continuation.resume(throwing: e)
                }
            }
        }
    }
}

class ApiClientTests: XCTestCase {
    func testFetchClientCredentials() async {
        let clientCredentials = Client.ClientCredentials(clientSecret: "123", clientId: "abc")
        let urlSession = URLSessionSpy()
        let client = Client(configuration: Client.Configuration(
            baseURL: URL(string: "https://someapi.io")!,
            credentialsProvider: CredentialsProviderSpy(),
            clientCredentials: clientCredentials,
            urlSession: urlSession
        ))

        do {
            let model: Model? = try await client.get("/awesome").dispatch()
            XCTAssertTrue(Thread.current.isMainThread)

            XCTAssertEqual(model?.label ?? "not known", "Awesome")

        } catch let e {
            XCTFail("Could not make request with error \(e.localizedDescription)")
        }

        // Client should have made three requests, first attempt, login request and second attempt
        XCTAssertEqual(urlSession.requests.count, 3)
        XCTAssertEqual(urlSession.requests.first?.url?.path, "/awesome")
        XCTAssertEqual(urlSession.requests[1].url?.path, "/auth/v1/oauth/tokens")
        XCTAssertEqual(urlSession.requests.last?.url?.path, "/awesome")

        guard
            let authRequest = urlSession.requests.first(where: { $0.url?.path == "/auth/v1/oauth/tokens" }),
            let data = authRequest.httpBody,
            let formData = String(data: data, encoding: .utf8)
        else {
            return XCTFail("Auth request was not found")
        }

        let querystring = QuerystringState(queryString: formData)

        XCTAssertEqual(querystring.get("client_secret")?.first ?? "not known", "123")
        XCTAssertEqual(querystring.get("client_id")?.first ?? "not known", "abc")
    }
}

