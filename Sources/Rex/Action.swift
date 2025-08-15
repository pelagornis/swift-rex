import Foundation

/// A protocol that defines the requirements for actions in the Swift-Rex architecture.
///
/// Actions represent events that can occur in your application and describe
/// what should happen to the state. They are the primary way to communicate
/// intent from the UI or other parts of your app to the state management system.
///
/// ## Overview
///
/// Actions are typically defined as enums that conform to `ActionType`. Each case
/// represents a different event or user action that can occur in your application.
/// Actions are dispatched to the store, which then processes them through the reducer.
///
/// ## Key Characteristics
///
/// - **Immutable**: Actions should be immutable and contain only the data needed
///   to describe the event
/// - **Serializable**: Actions must be `Codable` for debugging and time travel features
/// - **Sendable**: Actions must be `Sendable` for safe concurrent access
/// - **Equatable**: Actions must be `Equatable` for comparison and testing
///
/// ## Example
///
/// ```swift
/// enum AppAction: ActionType {
///     // User interactions
///     case increment
///     case decrement
///     case setCount(Int)
///     
///     // Async operations
///     case loadUser
///     case userLoaded(User)
///     case loadFailed(String)
///     
///     // UI state
///     case showLoading
///     case hideLoading
///     case setError(String?)
/// }
/// ```
///
/// ## Best Practices
///
/// - Use descriptive names that clearly indicate the intent
/// - Group related actions together
/// - Include only necessary data in action cases
/// - Use associated values for actions that need additional data
/// - Keep actions focused and single-purpose
public protocol ActionType: Sendable, Equatable, Codable {}
