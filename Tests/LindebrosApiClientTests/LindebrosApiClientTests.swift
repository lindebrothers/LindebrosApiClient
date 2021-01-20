@testable import LindebrosApiClient
import XCTest

final class LindebrosApiClientTests: XCTestCase {
    struct MyResponse: Decodable {
        var name: String
    }

    func testAsyncClient() {
        let expect = expectation(description: "get location list")
        let client = LindebrosApiClient(baseURL: "http://localhost:8080", logLevel: .debug)

        let r = Request<MyResponse, ErrorMessage, Empty>(endpoint: "/test")

        client.call(r, bearerToken: "") { response in
            XCTAssertTrue(response.isOk)
            expect.fulfill()
        }
        waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testSyncClient() {
        let client = LindebrosApiClient(baseURL: "http://localhost:8080", logLevel: .debug)

        let r = Request<MyResponse, ErrorMessage, Empty>(endpoint: "/test")

        let response = client.syncCall(r, bearerToken: "")
        XCTAssertTrue(response.isOk)
    }
}
