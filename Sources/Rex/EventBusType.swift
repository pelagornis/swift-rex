import Foundation

/// A protocol that defines the requirements for events in the EventBus system.
///
/// Events represent occurrences in your application that components can publish
/// and subscribe to. They enable loose coupling between different parts of your
/// application by providing a centralized event system.
///
/// ## Overview
///
/// Events are typically defined as structs that conform to `EventType`. They
/// contain data about what happened and can be used for cross-component communication,
/// analytics, logging, and other cross-cutting concerns.
///
/// ## Key Characteristics
///
/// - **Immutable**: Events should be immutable and contain only the data needed
///   to describe the occurrence
/// - **Serializable**: Events must be `Codable` for debugging and persistence
/// - **Sendable**: Events must be `Sendable` for safe concurrent access
/// - **Equatable**: Events must be `Equatable` for comparison and testing
///
/// ## Example
///
/// ```swift
/// struct UserLoggedInEvent: EventType {
///     let userId: String
///     let timestamp: Date
///     let source: String
/// }
///
/// struct NetworkErrorEvent: EventType {
///     let error: String
///     let code: Int
///     let endpoint: String
/// }
///
/// struct NavigationEvent: EventType {
///     let route: String
///     let parameters: [String: String]
/// }
/// ```
///
/// ## Best Practices
///
/// - Use descriptive names that clearly indicate what happened
/// - Include only necessary data in the event
/// - Make events immutable and value types
/// - Use associated values for events that need additional data
/// - Keep events focused and single-purpose
/// - Consider versioning for events that might change over time
public protocol EventType: Sendable, Codable {}
