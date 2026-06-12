import Foundation

/// A reactive side effect modeled as an ``AsyncStream`` of actions.
///
/// Effects can be one-shot (legacy closure style) or long-lived streams (WebSocket, timers, Combine).
/// Assign an ``EffectID`` with `cancelInFlight` to automatically cancel prior runs of the same effect.
public struct Effect<Action: Actionable>: Sendable {
    private let streamFactory: @Sendable () -> AsyncStream<Action>

    /// Optional identifier for cancellation and deduplication in the store.
    public let id: EffectID?

    /// When `true` and `id` is set, starting this effect cancels any in-flight effect with the same id.
    public let cancelInFlight: Bool

    /// Creates an effect from an async stream factory.
    public init(
        id: EffectID? = nil,
        cancelInFlight: Bool = false,
        stream: @escaping @Sendable () -> AsyncStream<Action>
    ) {
        self.id = id
        self.cancelInFlight = cancelInFlight
        self.streamFactory = stream
    }

    /// Creates a one-shot or long-lived effect using an emitter (backward compatible).
    public init(_ operation: @escaping @Sendable (EffectEmitter<Action>) async -> Void) {
        self.init(id: nil, cancelInFlight: false, stream: {
            Self.closureStream(operation)
        })
    }

    /// Creates a cancellable effect with an optional in-flight cancellation policy.
    public init(
        id: EffectID,
        cancelInFlight: Bool = true,
        _ operation: @escaping @Sendable (EffectEmitter<Action>) async -> Void
    ) {
        self.init(id: id, cancelInFlight: cancelInFlight, stream: {
            Self.closureStream(operation)
        })
    }

    /// Materializes the effect as an ``AsyncStream`` of actions.
    public func makeStream() -> AsyncStream<Action> {
        streamFactory()
    }

    /// Consumes the stream and dispatches each action (blocks until the stream finishes).
    public func run(dispatch: @escaping @Sendable (Action) -> Void) async {
        for await action in makeStream() {
            if Task.isCancelled { break }
            dispatch(action)
        }
    }

    private static func closureStream(
        _ operation: @escaping @Sendable (EffectEmitter<Action>) async -> Void
    ) -> AsyncStream<Action> {
        AsyncStream { continuation in
            let task = Task {
                let emitter = EffectEmitter { action in
                    continuation.yield(action)
                }
                await operation(emitter)
                continuation.finish()
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}

public extension Effect {
    /// An effect that does nothing.
    static var none: Effect<Action> {
        Effect { _ in }
    }

    /// Creates an effect backed by an existing ``AsyncStream``.
    static func stream(_ stream: @escaping @Sendable () -> AsyncStream<Action>) -> Effect<Action> {
        Effect(stream: stream)
    }

    /// Maps elements from any async sequence into actions.
    static func fromSequence<S: AsyncSequence>(
        _ sequence: S,
        map: @escaping @Sendable (S.Element) -> Action?
    ) -> Effect<Action> where S: Sendable {
        Effect {
            AsyncStream { continuation in
                let task = Task {
                    do {
                        for try await element in sequence {
                            if Task.isCancelled { break }
                            if let action = map(element) {
                                continuation.yield(action)
                            }
                        }
                    } catch {
                        continuation.finish()
                        return
                    }
                    continuation.finish()
                }
                continuation.onTermination = { _ in task.cancel() }
            }
        }
    }

    /// Creates an effect that immediately dispatches a single action.
    static func just(_ action: Action) -> Effect<Action> {
        Effect { emitter in
            emitter.send(action)
        }
    }

    /// Creates an effect that immediately dispatches multiple actions.
    static func many(_ actions: Action...) -> Effect<Action> {
        Effect { emitter in
            for action in actions {
                emitter.send(action)
            }
        }
    }

    /// Creates an effect that dispatches a single action after a delay.
    static func delayed(_ action: Action, delay: TimeInterval) -> Effect<Action> {
        Effect { emitter in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            emitter.send(action)
        }
    }

    /// Creates an effect that dispatches multiple actions in sequence.
    static func sequence(_ actions: Action...) -> Effect<Action> {
        Effect { emitter in
            for action in actions {
                emitter.send(action)
            }
        }
    }

    /// Creates an effect that dispatches multiple actions concurrently.
    static func concurrent(_ actions: Action...) -> Effect<Action> {
        Effect { emitter in
            await withTaskGroup(of: Void.self) { group in
                for action in actions {
                    group.addTask {
                        emitter.send(action)
                    }
                }
            }
        }
    }

    /// Creates an effect that repeats another effect at regular intervals.
    static func repeating(_ effect: Effect<Action>, interval: TimeInterval, count: Int? = nil) -> Effect<Action> {
        Effect { emitter in
            var repetitions = 0
            while count == nil || repetitions < count! {
                await effect.run(dispatch: { action in
                    emitter.send(action)
                })

                repetitions += 1
                if count == nil || repetitions < count! {
                    try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                }
            }
        }
    }

    /// Creates an effect that dispatches an action based on a condition.
    static func conditional(_ condition: @escaping @Sendable () -> Bool, action: Action) -> Effect<Action> {
        Effect { emitter in
            if condition() {
                emitter.send(action)
            }
        }
    }

    /// Creates an effect that maps one action to another.
    static func map(_ action: Action, transform: @escaping @Sendable (Action) -> Action) -> Effect<Action> {
        Effect { emitter in
            emitter.send(transform(action))
        }
    }

    /// Creates an effect that combines multiple effects into one stream.
    static func combine(_ effects: Effect<Action>...) -> Effect<Action> {
        Effect {
            AsyncStream { continuation in
                let task = Task {
                    await withTaskGroup(of: Void.self) { group in
                        for effect in effects {
                            group.addTask {
                                for await action in effect.makeStream() {
                                    if Task.isCancelled { return }
                                    continuation.yield(action)
                                }
                            }
                        }
                    }
                    continuation.finish()
                }
                continuation.onTermination = { _ in task.cancel() }
            }
        }
    }

    /// Assigns an id and cancellation policy to an existing effect.
    func cancellable(id: EffectID, cancelInFlight: Bool = true) -> Effect<Action> {
        Effect(id: id, cancelInFlight: cancelInFlight, stream: streamFactory)
    }

    /// Creates an effect that retries another effect on failure.
    static func retry(
        _ effect: Effect<Action>,
        maxAttempts: Int = 3,
        delay: TimeInterval = 1.0,
        shouldRetry: @escaping @Sendable (Error?) -> Bool = { _ in true },
        onError: @escaping @Sendable (Error) -> Void = { _ in }
    ) -> Effect<Action> {
        Effect { emitter in
            var attempts = 0
            var lastError: Error?

            while attempts < maxAttempts {
                do {
                    await effect.run(dispatch: { action in
                        emitter.send(action)
                    })
                    return
                } catch {
                    lastError = error
                    attempts += 1

                    if attempts < maxAttempts && shouldRetry(error) {
                        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    } else {
                        break
                    }
                }
            }

            if let error = lastError {
                onError(error)
            }
        }
    }

    /// Creates an effect that retries on failure and dispatches an error action.
    static func retryWithErrorAction(
        _ effect: Effect<Action>,
        maxAttempts: Int = 3,
        delay: TimeInterval = 1.0,
        shouldRetry: @escaping @Sendable (Error?) -> Bool = { _ in true },
        errorAction: @escaping @Sendable (Error) -> Action
    ) -> Effect<Action> {
        Effect { emitter in
            var attempts = 0
            var lastError: Error?

            while attempts < maxAttempts {
                do {
                    await effect.run(dispatch: { action in
                        emitter.send(action)
                    })
                    return
                } catch {
                    lastError = error
                    attempts += 1

                    if attempts < maxAttempts && shouldRetry(error) {
                        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    } else {
                        break
                    }
                }
            }

            if let error = lastError {
                emitter.send(errorAction(error))
            }
        }
    }
}
