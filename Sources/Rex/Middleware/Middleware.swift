import Foundation

/// A protocol that defines the requirements for middleware in the Swift-Rex architecture.
///
/// Middleware provides a way to intercept and process actions before and after they
/// reach the reducer. This enables cross-cutting concerns like logging, analytics,
/// error handling, and debugging.
///
/// ## Overview
///
/// Middleware sits between action dispatch and the reducer, allowing you to:
/// - Log actions and state changes
/// - Track analytics events
/// - Handle errors globally
/// - Implement debugging tools
/// - Add custom processing logic
///
/// ## Key Characteristics
///
/// - **Action Processing**: Middleware can inspect and modify actions
/// - **State Access**: Middleware has access to the current state
/// - **Effect Generation**: Middleware can return effects for side operations
/// - **Async Support**: Middleware can perform async operations
/// - **Composable**: Multiple middleware can be chained together
///
/// ## Example
///
/// ```swift
/// struct LoggingMiddleware: Middleware {
///     func process(state: AppState, action: AppAction, emit: @escaping (AppAction) -> Void) async -> [Effect<AppAction>] {
///         print("[LoggingMiddleware] Action: \(action)")
///         print("[LoggingMiddleware] State: \(state)")
///         return [.none]
///     }
/// }
///
/// struct AnalyticsMiddleware: Middleware {
///     func process(state: AppState, action: AppAction, emit: @escaping (AppAction) -> Void) async -> [Effect<AppAction>] {
///         // Track user actions
///         Analytics.track(action: action, state: state)
///         return [.none]
///     }
/// }
///
/// struct ErrorHandlingMiddleware: Middleware {
///     func process(state: AppState, action: AppAction, emit: @escaping (AppAction) -> Void) async -> [Effect<AppAction>] {
///         // Handle errors globally
///         if let error = state.errorMessage {
///             Crashlytics.recordError(error)
///         }
///         return [.none]
///     }
/// }
/// ```
///
/// ## Best Practices
///
/// - Keep middleware focused on a single concern
/// - Don't modify the state directly in middleware
/// - Use effects for async operations
/// - Handle errors gracefully
/// - Keep middleware lightweight and fast
/// - Consider the order of middleware in the chain
public protocol Middleware {
    /// The type of state this middleware can process.
    associatedtype State: StateType
    
    /// The type of actions this middleware can process.
    associatedtype Action: ActionType
    
    /// Processes an action through this middleware.
    ///
    /// This method is called for each action before it reaches the reducer.
    /// The middleware can inspect the action and state, perform side effects,
    /// and return additional effects that should be executed.
    ///
    /// - Parameters:
    ///   - state: The current state of the application.
    ///   - action: The action being processed.
    ///   - emit: A closure that can dispatch new actions to the store.
    /// - Returns: An array of effects that should be executed. Return `[.none]`
    ///   if no effects are needed.
    func process(
        state: State,
        action: Action,
        emit: @escaping (Action) -> Void
    ) async -> [Effect<Action>]
}
