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
                        try continuation.resume(returning: (encoder.encode(credentials), urlResponse))
                    case "/awesome":
                        guard
                            let auth = request.allHTTPHeaderFields?.first(where: { $0.key == "Authorization" })?.value,
                            auth.contains("Bearer")
                        else {
                            return continuation.resume(returning: (Data(), HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!))
                        }

                        let model = Model(label: "Awesome", secondLabel: "Very Awesome")
                        try continuation.resume(returning: (encoder.encode(model), urlResponse))

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
