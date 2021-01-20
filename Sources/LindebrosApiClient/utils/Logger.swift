import Foundation

public enum LogLevel: Int {
    case none, debug, info, warning, error

    func getEmoj() -> String {
        switch self {
        case .debug:
            return "🛠"
        case .info:
            return "💬"
        case .warning:
            return "⚠️"
        case .error:
            return "❌"
        case .none:
            return ""
        }
    }
}

public struct Logger {
    var logLevel: LogLevel

    func getFileName(_ path: String) -> String {
        return (path as NSString).lastPathComponent.components(separatedBy: ".")[0]
    }

    func getFunctionName(_ name: String) -> String {
        return name.components(separatedBy: "(")[0]
    }

    func debug(_ message: String, functionName: String = #function, line: Int = #line, path: String = #file) {
        DispatchQueue.global(qos: .background).async {
            self.publish(message: "\(self.getFileName(path)).\(self.getFunctionName(functionName))[\(line)]: \(message)", level: .debug)
        }
    }

    func info(_ message: String, functionName: String = #function, line: Int = #line, path: String = #file) {
        DispatchQueue.global(qos: .background).async {
            self.publish(message: "\(self.getFileName(path)).\(self.getFunctionName(functionName))[\(line)]: \(message)", level: .info)
        }
    }

    func warning(_ message: String, functionName: String = #function, line: Int = #line, path: String = #file) {
        DispatchQueue.global(qos: .background).async {
            self.publish(message: "\(self.getFileName(path)).\(self.getFunctionName(functionName))[\(line)]: \(message)", level: .warning)
        }
    }

    func error(_ message: String, functionName: String = #function, line: Int = #line, path: String = #file) {
        DispatchQueue.global(qos: .background).async {
            self.publish(message: "\(self.getFileName(path)).\(self.getFunctionName(functionName))[\(line)]: \(message)", level: .error)
        }
    }

    private func publish(message: String, level: LogLevel) {
        guard level.rawValue >= logLevel.rawValue else {
            return
        }
        print("🏷 \(level.getEmoj()) \(message)")
    }
}
