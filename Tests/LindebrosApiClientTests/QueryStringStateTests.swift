@testable import LindebrosApiClient
import SwiftUI
import XCTest

class QueryStringStateTests: XCTestCase {
    func testAsURLQueryItems() throws {
        let state = QuerystringState(queryString: "a=b&a=c&d=e")

        XCTAssertEqual(state.asQueryString, "a=b&a=c&d=e")

        XCTAssertEqual(state.asURLQueryItems.count, 3)
        XCTAssertEqual(try XCTUnwrap(state.asURLQueryItems.first).name, "a")
        XCTAssertEqual(try XCTUnwrap(state.asURLQueryItems.first).value, "b")
        XCTAssertEqual(try XCTUnwrap(state.asURLQueryItems.filter { $0.name == "a" }.last).value, "c")
        XCTAssertEqual(try XCTUnwrap(state.asURLQueryItems.last).name, "d")
        XCTAssertEqual(try XCTUnwrap(state.asURLQueryItems.last).value, "e")
    }
}
