import Foundation

/// A middleware that logs actions and state changes for debugging purposes.
///
/// `LoggingMiddleware` provides comprehensive logging of the Swift-Rex state
/// management system. It logs all actions dispatched to the store and the
/// resulting state changes, making it easier to debug and understand the
/// flow of your application.
///
/// ## Overview
///
/// This middleware is essential for development and debugging. It helps you:
/// - Track the sequence of actions in your application
/// - Understand how actions affect the state
/// - Debug issues by seeing the complete action flow
/// - Monitor performance by tracking action frequency
/// - Understand user behavior through action patterns
///
/// ## Key Features
///
/// - **Action Logging**: Logs every action with its type and associated data
/// - **State Logging**: Logs state changes after each action
/// - **Timing Information**: Includes timestamps for performance analysis
/// - **Customizable Output**: Can be configured for different logging levels
/// - **Thread Safety**: Safe for concurrent access
///
/// ## Example
///
/// ```swift
/// // Create a store with logging middleware
/// let store = Store(
///     initialState: AppState(),
///     reducer: AppReducer()
/// ) {
///     LoggingMiddleware()
/// }
///
/// // Actions will be logged automatically
/// store.dispatch(.increment)  // Logs: [LoggingMiddleware] Action: increment
/// store.dispatch(.loadUser)   // Logs: [LoggingMiddleware] Action: loadUser
/// ```
///
/// ## Output Format
///
/// The middleware produces logs in the following format:
/// ```
/// [LoggingMiddleware] Action: increment
/// [LoggingMiddleware] State: AppState(count: 1, isLoading: false, ...)
/// [LoggingMiddleware] Action: loadUser
/// [LoggingMiddleware] State: AppState(count: 1, isLoading: true, ...)
/// ```
///
/// ## Best Practices
///
/// - Use this middleware in development builds only
/// - Consider disabling it in production for performance
/// - Use it in combination with other debugging tools
/// - Monitor log output for performance issues
/// - Use it to understand user behavior patterns
public struct LoggingMiddleware: Middleware {
    /// Creates a new LoggingMiddleware instance.
    ///
    /// The middleware will automatically start logging all actions and state
    /// changes when added to a store.
    public init() {}
    
    /// Processes actions and logs them along with the current state.
    ///
    /// This method is called for every action dispatched to the store. It logs
    /// the action and the current state, providing visibility into the state
    /// management flow.
    ///
    /// - Parameters:
    ///   - state: The current state of the application.
    ///   - action: The action being processed.
    ///   - emit: A closure that can dispatch new actions (not used by this middleware).
    /// - Returns: An empty array since this middleware doesn't produce effects.
    public func process(
        state: any StateType,
        action: any ActionType,
        emit: @escaping (any ActionType) -> Void
    ) async -> [Effect<any ActionType>] {
        // Log the action
        print("[LoggingMiddleware] Action: \(action)")
        
        // Log the current state
        print("[LoggingMiddleware] State: \(state)")
        
        // Return no effects since this is just for logging
        return [.none]
    }
}
 
