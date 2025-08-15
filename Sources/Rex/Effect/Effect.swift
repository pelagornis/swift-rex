import Foundation

/// A struct that represents a side effect that can be executed by the store.
///
/// Effects are used to handle asynchronous operations, side effects, and other
/// operations that are not pure state transformations. They can dispatch new
/// actions back to the store using the provided emitter.
///
/// ## Example
/// ```swift
/// // Network request effect
/// Effect { emitter in
///     let data = try await URLSession.shared.data(from: url)
///     let response = try JSONDecoder().decode(Response.self, from: data.0)
///     await emitter.withValue { emitter in
///         emitter.send(.dataLoaded(response))
///     }
/// }
///
/// // Timer effect
/// Effect { emitter in
///     for await _ in Timer.publish(every: 1, on: .main, in: .common).autoconnect() {
///         await emitter.withValue { emitter in
///             emitter.send(.timerTick)
///         }
///     }
/// }
/// ```
public struct Effect<Action: ActionType>: Sendable {
    private let operation: @Sendable (EffectEmitter<Action>) async -> Void

    /// Creates a new effect with the specified operation.
    ///
    /// - Parameter operation: An async closure that performs the side effect.
    ///   The closure receives an `EffectEmitter` that can be used to dispatch actions.
    public init(_ operation: @escaping @Sendable (EffectEmitter<Action>) async -> Void) {
        self.operation = operation
    }

    /// Executes the effect with the provided dispatch function.
    ///
    /// - Parameter dispatch: A closure that can be used to dispatch actions back to the store.
    public func run(dispatch: @escaping @Sendable (Action) -> Void) async {
        let emitter = EffectEmitter(dispatch: dispatch)
        await operation(emitter)
    }
}

public extension Effect {
    /// An effect that does nothing.
    ///
    /// Use this when an action doesn't need to perform any side effects.
    static var none: Effect<Action> {
        Effect { _ in }
    }
    
    /// Creates an effect that immediately dispatches a single action.
    ///
    /// - Parameter action: The action to dispatch.
    /// - Returns: An effect that immediately dispatches the specified action.
    static func just(_ action: Action) -> Effect<Action> {
        Effect { emitter in
            emitter.send(action)
        }
    }
    
    /// Creates an effect that immediately dispatches multiple actions.
    ///
    /// - Parameter actions: The actions to dispatch.
    /// - Returns: An effect that immediately dispatches all specified actions.
    static func many(_ actions: Action...) -> Effect<Action> {
        Effect { emitter in
            for action in actions {
                emitter.send(action)
            }
        }
    }
    
    /// Creates an effect that dispatches a single action after a delay.
    ///
    /// - Parameters:
    ///   - action: The action to dispatch.
    ///   - delay: The delay in seconds before dispatching the action.
    /// - Returns: An effect that dispatches the action after the specified delay.
    static func delayed(_ action: Action, delay: TimeInterval) -> Effect<Action> {
        Effect { emitter in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            emitter.send(action)
        }
    }
    
    /// Creates an effect that dispatches multiple actions in sequence.
    ///
    /// - Parameter actions: The actions to dispatch in sequence.
    /// - Returns: An effect that dispatches all actions one after another.
    static func sequence(_ actions: Action...) -> Effect<Action> {
        Effect { emitter in
            for action in actions {
                emitter.send(action)
            }
        }
    }
    
    /// Creates an effect that dispatches multiple actions concurrently.
    ///
    /// - Parameter actions: The actions to dispatch concurrently.
    /// - Returns: An effect that dispatches all actions at the same time.
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
    ///
    /// - Parameters:
    ///   - effect: The effect to repeat.
    ///   - interval: The interval between repetitions in seconds.
    ///   - count: The number of times to repeat the effect. If nil, repeats indefinitely.
    /// - Returns: An effect that repeats the specified effect.
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
    ///
    /// - Parameters:
    ///   - condition: A closure that returns true if the action should be dispatched.
    ///   - action: The action to dispatch if the condition is true.
    /// - Returns: An effect that conditionally dispatches the action.
    static func conditional(_ condition: @escaping @Sendable () -> Bool, action: Action) -> Effect<Action> {
        Effect { emitter in
            if condition() {
                emitter.send(action)
            }
        }
    }
    
    /// Creates an effect that maps one action to another.
    ///
    /// - Parameters:
    ///   - action: The original action.
    ///   - transform: A closure that transforms the original action.
    /// - Returns: An effect that dispatches the transformed action.
    static func map(_ action: Action, transform: @escaping @Sendable (Action) -> Action) -> Effect<Action> {
        Effect { emitter in
            emitter.send(transform(action))
        }
    }
    
    /// Creates an effect that combines multiple effects into one.
    ///
    /// - Parameter effects: The effects to combine.
    /// - Returns: An effect that executes all the provided effects.
    static func combine(_ effects: Effect<Action>...) -> Effect<Action> {
        Effect { emitter in
            await withTaskGroup(of: Void.self) { group in
                for effect in effects {
                    group.addTask {
                        await effect.run(dispatch: { action in
                            emitter.send(action)
                        })
                    }
                }
            }
        }
    }
    
    /// Creates an effect that retries another effect on failure.
    ///
    /// - Parameters:
    ///   - effect: The effect to retry.
    ///   - maxAttempts: The maximum number of retry attempts.
    ///   - delay: The delay between retry attempts in seconds.
    ///   - shouldRetry: A closure that determines if the effect should be retried.
    /// - Returns: An effect that retries the specified effect on failure.
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
                    return // Success, exit the retry loop
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
            
            // If we get here, all retries failed
            if let error = lastError {
                onError(error)
            }
        }
    }
    
    /// Creates an effect that retries another effect on failure and dispatches an error action.
    ///
    /// - Parameters:
    ///   - effect: The effect to retry.
    ///   - maxAttempts: The maximum number of retry attempts.
    ///   - delay: The delay between retry attempts in seconds.
    ///   - shouldRetry: A closure that determines if the effect should be retried.
    ///   - errorAction: The action to dispatch when all retries fail.
    /// - Returns: An effect that retries the specified effect on failure.
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
                    return // Success, exit the retry loop
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
            
            // If we get here, all retries failed
            if let error = lastError {
                emitter.send(errorAction(error))
            }
        }
    }
}
