import Foundation

/// Represents a side effect or asynchronous operation in the Swift-Rex architecture.
///
/// Effects are used to handle operations that cannot be performed synchronously
/// in the reducer, such as network requests, file I/O, timers, or other async tasks.
/// They are returned by reducers and executed by the store.
///
/// ## Overview
///
/// Effects encapsulate side effects and provide a way to dispatch new actions
/// when they complete. This keeps the reducer pure while allowing the application
/// to perform necessary async operations.
///
/// ## Key Characteristics
///
/// - **Async Operations**: Effects can perform any async operation
/// - **Action Dispatching**: Effects can dispatch new actions when they complete
/// - **Cancellable**: Effects can be cancelled if needed
/// - **Composable**: Effects can be combined and chained together
///
/// ## Example
///
/// ```swift
/// // Network request effect
/// Effect { emitter in
///     let data = try await URLSession.shared.data(from: url)
///     let response = try JSONDecoder().decode(User.self, from: data.0)
///     await emitter.send(.userLoaded(response))
/// }
///
/// // Timer effect
/// Effect { emitter in
///     for await _ in Timer.publish(every: 1, on: .main, in: .common).autoconnect() {
///         await emitter.send(.timerTick)
///     }
/// }
///
/// // Multiple actions effect
/// Effect { emitter in
///     await emitter.withValue { emitter in
///         await emitter.send(.showLoading)
///         await emitter.send(.startOperation)
///     }
/// }
/// ```
///
/// ## Best Practices
///
/// - Keep effects focused on a single operation
/// - Always dispatch actions when effects complete (success or failure)
/// - Handle errors appropriately and dispatch error actions
/// - Use `emitter.withValue` when you need to send multiple actions
/// - Consider cancellation for long-running effects
public struct Effect<Action> {
    /// The underlying async operation that this effect performs.
    private let operation: (EffectEmitter<Action>) async -> Void
    
    /// Creates a new effect with the specified async operation.
    ///
    /// - Parameter operation: A closure that performs the async operation and
    ///   can dispatch actions through the provided emitter.
    public init(_ operation: @escaping (EffectEmitter<Action>) async -> Void) {
        self.operation = operation
    }
    
    /// Executes the effect with the provided action dispatcher.
    ///
    /// This method is called by the store to execute the effect. The effect
    /// can dispatch actions through the provided closure when it completes.
    ///
    /// - Parameter dispatch: A closure that can dispatch actions to the store.
    public func run(dispatch: @escaping (Action) -> Void) async {
        let emitter = EffectEmitter(dispatch: dispatch)
        await operation(emitter)
    }
}

/// A special effect that represents no side effects.
///
/// Use this when your reducer doesn't need to perform any async operations
/// or side effects. This is the most common return value for simple state updates.
public extension Effect {
    /// An effect that performs no operations.
    static var none: Effect<Action> {
        Effect { _ in }
    }
}

/// An emitter that allows effects to dispatch actions.
///
/// The `EffectEmitter` provides a safe way for effects to dispatch actions
/// back to the store. It encapsulates the dispatch function and provides
/// additional utilities for common patterns.
///
/// ## Overview
///
/// Effects receive an `EffectEmitter` instance that they can use to dispatch
/// actions. The emitter provides both simple dispatch methods and more advanced
/// utilities for complex scenarios.
///
/// ## Example
///
/// ```swift
/// Effect { emitter in
///     // Simple dispatch
///     await emitter.send(.showLoading)
///     
///     // Multiple actions
///     await emitter.withValue { emitter in
///         await emitter.send(.action1)
///         await emitter.send(.action2)
///     }
///     
///     // Conditional dispatch
///     if shouldDispatch {
///         await emitter.send(.conditionalAction)
///     }
/// }
/// ```
public struct EffectEmitter<Action> {
    /// The function used to dispatch actions to the store.
    private let dispatch: (Action) -> Void
    
    /// Creates a new emitter with the specified dispatch function.
    ///
    /// - Parameter dispatch: A closure that dispatches actions to the store.
    init(dispatch: @escaping (Action) -> Void) {
        self.dispatch = dispatch
    }
    
    /// Dispatches a single action to the store.
    ///
    /// This is the simplest way to dispatch an action from an effect.
    /// The action is dispatched immediately when this method is called.
    ///
    /// - Parameter action: The action to dispatch.
    public func send(_ action: Action) async {
        dispatch(action)
    }
    
    /// Provides a context for dispatching multiple actions.
    ///
    /// This method is useful when you need to dispatch multiple actions
    /// in sequence or when you need to perform some logic between dispatches.
    ///
    /// - Parameter operation: A closure that can dispatch multiple actions.
    public func withValue(_ operation: (EffectEmitter<Action>) async -> Void) async {
        await operation(self)
    }
}
