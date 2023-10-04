import Combine
import Foundation

public protocol WebSocketClientProvider {
    @MainActor @discardableResult func connect(to: Client.Request) -> WebSocketClientProvider
    @MainActor @discardableResult func reconnect() async throws -> WebSocketClientProvider
    @MainActor @discardableResult func disconnect() -> WebSocketClientProvider
    func send(message: Encodable) async throws
    var state: WebSocketClient.State { get }
    var events: PassthroughSubject<WebSocketClient.Event, Never> { get }
}

public final class WebSocketClient: NSObject, WebSocketClientProvider {
    public init(config: WebSocketClient.Configuration) {
        self.config = config
        super.init()
    }

    deinit {
        websocketTask?.cancel()
        websocketTask = nil
    }

    private let config: WebSocketClient.Configuration
    private var urlSession: URLSession?
    private var websocketTask: URLSessionWebSocketTask?
    private var request: Client.Request?
    private var pingPongTimer: Timer?

    public private(set) var state: State = .disconnected {
        didSet {
            if config.verbose {
                print("⚡️ \(state) \(request?.urlRequest?.url?.absoluteString ?? "unknown")")
            }
            events.send(.stateChanged(to: state))
        }
    }

    public let events = PassthroughSubject<WebSocketClient.Event, Never>()

    @MainActor public func reconnect() async throws -> WebSocketClientProvider {
        guard state == .disconnected else {
            return self
        }
        guard let request = request else {
            throw NSError(domain: "⚡️ ❌ Request is undefined", code: 500)
        }
        let subscriber = AsyncSubscriber(publisher: events)
        connect(to: request)
        try await AsyncObserver().wait(for: subscriber.$events, toBeTrue: { $0.first(where: { $0.stateChanged(to: .connected) }) != nil })

        guard state == .connected else {
            throw NSError(domain: "⚡️ ❌ Failed to reconnect", code: 500)
        }
        return self
    }

    @MainActor @discardableResult public func connect(to request: Client.Request) -> WebSocketClientProvider {
        guard
            state != .connected,
            let urlRequest = request.urlRequest
        else {
            return self
        }
        self.request = request
        state = .connecting

        urlSession = URLSession(configuration: config.urlSessionConfig, delegate: self, delegateQueue: nil)
        websocketTask = urlSession?.webSocketTask(with: urlRequest)
        setupListener()
        websocketTask?.resume()
        return self
    }

    @MainActor @discardableResult public func disconnect() -> WebSocketClientProvider {
        guard state != .disconnected else { return self }
        state = .disconnecting
        pingPongTimer?.invalidate()
        websocketTask?.cancel(with: .goingAway, reason: "⚡️ 👋 closing connection".data(using: .utf8))
        return self
    }

    public func send(message: Encodable) async throws {
        let message = try encode(message: message)
        if config.verbose {
            print("⚡️ ✉️ Sending message", message)
        }
        guard let websocketTask = websocketTask, state == .connected else {
            throw NSError(domain: "⚡️ ❌ Cannot send message because websocket is not alive", code: 400)
        }

        do {
            try await websocketTask.send(message)
        } catch {
            throw NSError(domain: "⚡️ ❌ Failed to send message with error \(error)", code: 500)
        }
    }
}

extension WebSocketClient: URLSessionWebSocketDelegate {
    public func urlSession(_: URLSession, webSocketTask _: URLSessionWebSocketTask, didOpenWithProtocol _: String?) {
        state = .connected

        switch config.pingPongType {
        case let .timeInterval(timeInterval):
            applyPingPong(with: timeInterval)
        case .none:
            break
        }
    }

    public func urlSession(_: URLSession, webSocketTask _: URLSessionWebSocketTask, didCloseWith _: URLSessionWebSocketTask.CloseCode, reason _: Data?) {
        state = .disconnected
        pingPongTimer?.invalidate()
    }
}

private extension WebSocketClient {
    func applyPingPong(with timeInterval: TimeInterval) {
        pingPongTimer?.invalidate()
        DispatchQueue.main.async { [weak self] in
            self?.pingPongTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { _ in
                if self?.config.verbose == true {
                    print("⚡️ ⏲️ Ping")
                }
                self?.websocketTask?.sendPing(pongReceiveHandler: { error in
                    if let error = error {
                        print("⚡️ ❌ Failed to recive pong with error", error)
                        return
                    }
                    if self?.config.verbose == true {
                        print("⚡️ 🟢 Pong")
                    }
                })
            }
        }
    }

    func setupListener() {
        let workItem = DispatchWorkItem { [weak self] in
            self?.websocketTask?.receive { [weak self] result in
                switch result {
                case let .success(message):
                    if self?.config.verbose == true {
                        print("⚡️ 📬 Received message")
                    }
                    self?.events.send(.received(message: message))
                    // Create new listener according to documentation
                    self?.setupListener()
                case let .failure(error):
                    print("⚡️ ❌ Failed to receive message with error", error)
                }
            }
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 1, execute: workItem)
    }

    private func encode(message: Encodable) throws -> URLSessionWebSocketTask.Message {
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(message)
            guard
                let value = String(data: jsonData, encoding: .utf8)
            else {
                throw NSError(domain: "Could not convert data to string", code: 500)
            }
            return URLSessionWebSocketTask.Message.string(value)
        } catch {
            throw NSError(domain: "⚡️ ❌ Failed to encode the message with error \(error)", code: 500)
        }
    }
}

public extension WebSocketClient {
    enum Event {
        case stateChanged(to: State)
        case received(message: URLSessionWebSocketTask.Message)

        func stateChanged(to compareState: State) -> Bool {
            if case let .stateChanged(to: state) = self, state == compareState {
                return true
            }
            return false
        }
    }

    enum State: Equatable, CustomStringConvertible {
        case connected
        case connecting
        case disconnected
        case disconnecting

        public var description: String {
            switch self {
            case .connected:
                return "🟢 Connected"
            case .connecting:
                return "🟠 Connecting"
            case .disconnected:
                return "🔴 Disconnected"
            case .disconnecting:
                return "🟠 Disconnecting"
            }
        }
    }
}
