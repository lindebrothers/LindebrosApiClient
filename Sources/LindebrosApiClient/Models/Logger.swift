import Foundation

public protocol ApiLogger: Sendable {
    func debug(_ values: Any?..., file: StaticString, line: UInt)
    func info(_ values: Any?..., file: StaticString, line: UInt)
    func warning(_ values: Any?..., file: StaticString, line: UInt)
    func error(_ values: Any?..., file: StaticString, line: UInt)
}

extension ApiLogger {
    func debug(_ values: Any?..., file: StaticString = #file, line: UInt = #line) {
        debug(values, file: file, line: line)
    }
    func info(_ values: Any?..., file: StaticString = #file, line: UInt = #line) {
        info(values, file: file, line: line)
    }
    func warning(_ values: Any?..., file: StaticString = #file, line: UInt = #line) {
        warning(values, file: file, line: line)
    }
    func error(_ values: Any?..., file: StaticString = #file, line: UInt = #line) {
        error(values, file: file, line: line)
    }
}

public enum LoggingStrategy: Sendable {
    case normal
    case raw
    case none
}
