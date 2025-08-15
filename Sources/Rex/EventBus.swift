import Foundation
import Combine

/// A global event system for cross-component communication in Swift-Rex.
///
/// The `EventBus` provides a centralized way for different parts of your application
/// to communicate without direct coupling. It allows components to publish events
/// and subscribe to events they're interested in.
///
/// ## Overview
///
/// Each `Store` instance has its own `EventBus`, providing isolated event handling
/// for different parts of your application. The EventBus supports:
///
/// - **Event Publishing**: Components can publish events to notify others
/// - **Event Subscription**: Components can subscribe to specific event types
/// - **Filtered Subscriptions**: Subscribe to events with custom filters
/// - **All Events Subscription**: Subscribe to all events for debugging or logging
///
/// ## Key Features
///
/// - **Type-Safe**: Events are strongly typed and checked at compile time
/// - **Thread-Safe**: All operations are safe for concurrent access
/// - **Main Actor**: All operations are performed on the main actor for UI safety
/// - **Cancellable**: Subscriptions can be cancelled to prevent memory leaks
/// - **Composable**: Multiple subscriptions can be combined and managed together
///
/// ## Example
///
/// ```swift
/// // Define custom events
/// struct UserLoggedInEvent: EventType {
///     let userId: String
///     let timestamp: Date
/// }
///
/// struct NetworkErrorEvent: EventType {
///     let error: String
///     let code: Int
/// }
///
/// // Publish events
/// store.getEventBus().publish(UserLoggedInEvent(userId: "123", timestamp: Date()))
/// store.getEventBus().publish(NetworkErrorEvent(error: "Connection failed", code: 500))
///
/// // Subscribe to specific events
/// let cancellable = store.getEventBus().subscribe(to: UserLoggedInEvent.self) { event in
///     print("User logged in: \(event.userId)")
/// }
///
/// // Subscribe with filter
/// let errorCancellable = store.getEventBus().subscribe(
///     to: NetworkErrorEvent.self,
///     where: { $0.code >= 500 },
///     handler: { event in
///         print("Critical error: \(event.error)")
///     }
/// )
///
/// // Subscribe to all events
/// let allEventsCancellable = store.getEventBus().subscribe { event in
///     print("Event: \(event)")
/// }
/// ```
///
/// ## Use Cases
///
/// - **User Authentication**: Handle login/logout events across the app
/// - **Navigation**: Manage navigation state and deep linking
/// - **Error Handling**: Global error management and user notifications
/// - **Analytics**: Track user actions and app usage
/// - **Cross-Component Communication**: Communicate between unrelated components
/// - **Background Tasks**: Handle app lifecycle and background processing
public final class EventBus {
    /// The subject that manages all event publishers.
    private let subject = PassthroughSubject<EventType, Never>()
    
    /// Creates a new EventBus instance.
    public init() {}
    
    /// Publishes an event to all subscribers.
    ///
    /// This method publishes the event to all subscribers who are listening
    /// for events of this type or all events. The event is published immediately
    /// and synchronously.
    ///
    /// - Parameter event: The event to publish.
    @MainActor
    public func publish(_ event: EventType) {
        subject.send(event)
    }
    
    /// Subscribes to all events.
    ///
    /// This subscription will receive all events published to this EventBus.
    /// Use this for debugging, logging, or when you need to monitor all events.
    ///
    /// - Parameter handler: A closure that will be called with each event.
    /// - Returns: A cancellable that can be used to cancel the subscription.
    @MainActor
    public func subscribe(handler: @escaping (EventType) -> Void) -> AnyCancellable {
        return subject.sink { event in
            handler(event)
        }
    }
    
    /// Subscribes to events of a specific type.
    ///
    /// This subscription will only receive events of the specified type.
    /// This is the most common type of subscription and provides type safety.
    ///
    /// - Parameters:
    ///   - eventType: The type of events to subscribe to.
    ///   - handler: A closure that will be called with each event of the specified type.
    /// - Returns: A cancellable that can be used to cancel the subscription.
    @MainActor
    public func subscribe<T: EventType>(
        to eventType: T.Type,
        handler: @escaping (T) -> Void
    ) -> AnyCancellable {
        return subject
            .compactMap { $0 as? T }
            .sink { event in
                handler(event)
            }
    }
    
    /// Subscribes to events of a specific type with a filter.
    ///
    /// This subscription will only receive events of the specified type that
    /// pass the provided filter. This is useful for conditional event handling.
    ///
    /// - Parameters:
    ///   - eventType: The type of events to subscribe to.
    ///   - where: A closure that filters events. Return `true` to receive the event.
    ///   - handler: A closure that will be called with each filtered event.
    /// - Returns: A cancellable that can be used to cancel the subscription.
    @MainActor
    public func subscribe<T: EventType>(
        to eventType: T.Type,
        where filter: @escaping (T) -> Bool,
        handler: @escaping (T) -> Void
    ) -> AnyCancellable {
        return subject
            .compactMap { $0 as? T }
            .filter(filter)
            .sink { event in
                handler(event)
            }
    }
}