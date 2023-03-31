import Foundation

public extension Client {
    enum ContentType: String, Sendable {
        case form = "application/x-www-form-urlencoded; charset=utf-8"
        case json = "application/json; charset=utf-8"
    }
}
