import Foundation

public protocol ClientLoggerProvider {
    func publish(message: String, obj: [Any], level: Client.ClientLogger.LogLevel)
}

public extension Client {
    struct ClientLoggerMock: ClientLoggerProvider {
        public init() {}
        public func publish(message: String, obj: [Any], level: Client.ClientLogger.LogLevel) {}
    }

    struct ClientLogger: ClientLoggerProvider {
        public var logLevel: ClientLogger.LogLevel {
#if DEBUG
            return .debug
#else
            return .none
#endif
        }

        static let shared = ClientLogger()

        public init() {}

        public static func getFileName(_ path: String?) -> String {
            guard let path = path else { return "" }
            return (path as NSString).lastPathComponent.components(separatedBy: ".")[0]
        }

        public static func getFunctionName(_ name: String?) -> String {
            guard let name = name else { return "" }
            return name.components(separatedBy: "(")[0]
        }

        public func debug(_ obj: Any..., functionName: String? = #function, line: Int? = #line, path: String? = #file) {
            let lineStr = line != nil ? "[\(line ?? 0)]" : ""
            publish(
                message: "\(ClientLogger.getFileName(path)).\(ClientLogger.getFunctionName(functionName))\(lineStr):",

                obj: obj,
                level: .debug
            )
        }

        public func info(_ obj: Any..., functionName: String? = #function, line: Int? = #line, path: String? = #file) {
            let lineStr = line != nil ? "[\(line ?? 0)]" : ""
            publish(
                message: "\(ClientLogger.getFileName(path)).\(ClientLogger.getFunctionName(functionName))\(lineStr):",
                obj: obj,
                level: .info
            )
        }

        public func warning(_ obj: Any..., functionName: String? = #function, line: Int? = #line, path: String? = #file) {
            let lineStr = line != nil ? "[\(line ?? 0)]" : ""
            publish(
                message: "\(ClientLogger.getFileName(path)).\(ClientLogger.getFunctionName(functionName))\(lineStr):",
                obj: obj,
                level: .warning
            )
        }

        public func error(_ obj: Any..., functionName: String? = #function, line: Int? = #line, path: String? = #file) {
            let lineStr = line != nil ? "[\(line ?? 0)]" : ""
            publish(
                message: "\(ClientLogger.getFileName(path)).\(ClientLogger.getFunctionName(functionName))\(lineStr):",
                obj: obj,
                level: .error
            )
        }

        public func publish(message: String, obj: [Any], level: LogLevel) {
            guard level.rawValue >= logLevel.rawValue else {
                return
            }
            print("Client: \(level.getEmoj()) ", terminator: "")
            for item in obj {
                print(item, terminator: "")
            }
            print("")
        }
    }
}

public extension Client.ClientLogger {
    enum LogLevel: Int {
        case none, debug, info, warning, error

        func getEmoj() -> String {
            switch self {
            case .debug:
                return "🏷"
            case .info:
                return "💬"
            case .warning:
                return "⚠️"
            case .error:
                return "❌"
            default:
                return ""
            }
        }
    }
}
