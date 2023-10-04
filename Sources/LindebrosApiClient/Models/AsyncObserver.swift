import Combine
import Foundation

public class AsyncObserver {
    public init() {}

    private var subscriber: Cancellable?
    private var resumed: Bool = false
    private var timer: Timer?

    @MainActor public func wait<Value>(
        for model: Published<Value>.Publisher,
        toBeTrue condition: @escaping (Value) -> Bool
    ) async throws {
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self = self else {
                return continuation.resume(throwing: WaitError.timeout)
            }
            self.timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [weak self] _ in
                guard let self = self, self.resumed == false else {
                    return continuation.resume(throwing: WaitError.timeout)
                }
                self.resumed = true

                continuation.resume(throwing: WaitError.timeout)
                self.subscriber?.cancel()
            }

            self.subscriber = model.sink { [weak self] value in
                guard
                    let self = self,
                    self.resumed == false,
                    condition(value)
                else { return }
                self.resumed = true
                self.timer?.invalidate()
                self.timer = nil
                self.subscriber?.cancel()
                continuation.resume()
            }
        }
    }

    public enum WaitError: Error {
        case timeout
    }
}

public class AsyncSubscriber<T> {
    @Published public private(set) var events = [T]()
    private var subscriber: Cancellable?
    public init(publisher: PassthroughSubject<T, Never>) {
        subscriber = publisher.sink { [weak self] newEvent in
            self?.events.append(newEvent)
        }
    }

    public func reset() {
        events = []
    }
}
