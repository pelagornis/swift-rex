import Foundation

/// A protocol that defines the base type for all actions in the application.
///
/// Actions represent events that can occur in your application and are used
/// to describe state changes. All actions should conform to this protocol
/// to ensure type safety and consistency.
///
/// ## Example
/// ```swift
/// enum AppAction: Action {
///     case increment
///     case decrement
///     case setCount(Int)
///     case loadUser
///     case userLoaded(User)
/// }
/// ```
public protocol ActionProtocol: Sendable {}
/// Public typealias so app types conform to ``Action`` (e.g. `enum AppAction: Action`).
public typealias Action = ActionProtocol