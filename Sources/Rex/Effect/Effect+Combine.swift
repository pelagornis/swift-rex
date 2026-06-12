#if canImport(Combine)
@preconcurrency import Combine
import Foundation

private final class CancellableBox: @unchecked Sendable {
    var cancellable: AnyCancellable?
}

public extension Effect {
    /// Bridges a Combine publisher into an effect stream.
    ///
    /// Cancellation of the effect cancels the publisher subscription.
    static func publisher<P: Publisher>(
        _ publisher: P,
        map: @escaping @Sendable (P.Output) -> Action?
    ) -> Effect<Action> where P.Failure == Never, P: Sendable {
        Effect {
            AsyncStream { continuation in
                let box = CancellableBox()
                box.cancellable = publisher.sink { output in
                    if let action = map(output) {
                        continuation.yield(action)
                    }
                }
                continuation.onTermination = { _ in
                    box.cancellable?.cancel()
                }
            }
        }
    }
}
#endif
