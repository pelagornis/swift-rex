import Foundation

/// A protocol that defines the base type for all events in the EventBus system.
///
/// Events represent occurrences in your application that can be published and subscribed to
/// through the EventBus. They are used for cross-component communication and handling
/// side effects that are not directly related to state changes.
///
/// ## Example
/// ```swift
/// struct UserLoggedInEvent: EventType {
///     let userId: String
///     let timestamp: Date
/// }
///
/// struct NetworkErrorEvent: EventType {
///     let error: String
///     let code: Int
/// }
/// ```
public protocol EventType: Sendable, Codable {
    // This protocol serves as a marker for event types
    // No additional requirements are needed beyond Sendable and Codable conformance
}
