import Foundation

/// A thread-safe event bus for publishing and subscribing to events across the application.
///
/// The EventBus provides a decoupled communication mechanism where components can publish
/// events without knowing who will receive them, and subscribe to events without knowing
/// who published them. Events are processed sequentially to ensure order and prevent loss.
///
/// ## Example
/// ```swift
/// let eventBus = EventBus()
///
/// // Subscribe to all events
/// eventBus.subscribe { event in
///     print("Received event: \(event)")
/// }
///
/// // Subscribe to specific event type
/// eventBus.subscribe(to: UserLoggedInEvent.self) { event in
///     print("User logged in: \(event.userId)")
/// }
///
/// // Publish an event
/// eventBus.publish(UserLoggedInEvent(userId: "123"))
/// ```
public final class EventBus: Sendable {
    private let publishActor: EventPublishActor
    private let subscribersActor: EventSubscribersActor

    /// Creates a new EventBus instance.
    public init() {
        self.subscribersActor = EventSubscribersActor()
        self.publishActor = EventPublishActor(subscribersActor: subscribersActor)
    }

    /// Publishes an event to all subscribers.
    ///
    /// Events are queued and processed sequentially to ensure order and prevent loss.
    /// This method returns immediately without waiting for the event to be processed.
    ///
    /// - Parameter event: The event to publish.
    public func publish(_ event: EventType) {
        Task {
            await publishActor.enqueue(event)
        }
    }

    /// Subscribes to all events.
    ///
    /// The handler will be called for every event published to the bus.
    ///
    /// - Parameter handler: A closure that receives published events.
    public func subscribe(handler: @escaping @Sendable (EventType) -> Void) {
        Task {
            await subscribersActor.addSubscriber(handler)
        }
    }

    /// Subscribes to events of a specific type.
    ///
    /// The handler will only be called for events that match the specified type.
    ///
    /// - Parameters:
    ///   - eventType: The type of events to subscribe to.
    ///   - handler: A closure that receives events of the specified type.
    public func subscribe<T: EventType>(
        to eventType: T.Type,
        handler: @escaping @Sendable (T) -> Void
    ) {
        subscribe { event in
            if let typedEvent = event as? T {
                handler(typedEvent)
            }
        }
    }

    /// Subscribes to events of a specific type that match a filter condition.
    ///
    /// The handler will only be called for events that match both the type and the filter condition.
    ///
    /// - Parameters:
    ///   - eventType: The type of events to subscribe to.
    ///   - filter: A closure that determines if an event should be handled.
    ///   - handler: A closure that receives events matching the type and filter.
    public func subscribe<T: EventType>(
        to eventType: T.Type,
        where filter: @escaping @Sendable (T) -> Bool,
        handler: @escaping @Sendable (T) -> Void
    ) {
        subscribe { event in
            if let typedEvent = event as? T, filter(typedEvent) {
                handler(typedEvent)
            }
        }
    }
}

/// An actor that manages the event publishing queue and ensures sequential processing.
///
/// This actor maintains a queue of events and processes them one at a time
/// to guarantee order and prevent event loss.
private actor EventPublishActor {
    private let subscribersActor: EventSubscribersActor
    private var eventQueue: [EventType] = []
    private var processingTask: Task<Void, Never>?
    
    init(subscribersActor: EventSubscribersActor) {
        self.subscribersActor = subscribersActor
    }
    
    /// Adds an event to the queue and starts processing if needed.
    ///
    /// - Parameter event: The event to enqueue.
    func enqueue(_ event: EventType) {
        eventQueue.append(event)
        startProcessingIfNeeded()
    }
    
    /// Starts the processing task if one is not already running.
    ///
    /// If a processing task is already active, this method does nothing.
    /// Otherwise, it creates a new task to process events from the queue.
    private func startProcessingIfNeeded() {
        // If already processing, just add to queue and return
        guard processingTask == nil else { return }
        
        // Start processing task - ensures actor isolation by calling actor methods from within Task
        let subscribersActor = self.subscribersActor
        processingTask = Task {
            await Self.processQueueContinuously(
                actor: self,
                subscribersActor: subscribersActor
            )
        }
    }
    
    /// Continuously processes events from the queue until it's empty.
    ///
    /// This method runs in a loop, dequeuing events one at a time and publishing them
    /// to subscribers. It stops when the queue is empty and clears the processing task.
    ///
    /// - Parameters:
    ///   - actor: The EventPublishActor instance to interact with.
    ///   - subscribersActor: The actor managing subscribers.
    private static func processQueueContinuously(
        actor: EventPublishActor,
        subscribersActor: EventSubscribersActor
    ) async {
        while true {
            // Dequeue next event from the queue
            let event: EventType? = await actor.dequeueNextEvent()
            
            guard let event = event else {
                // If queue is empty, stop processing
                let shouldStop = await actor.checkAndClearIfEmpty()
                if shouldStop {
                    break
                }
                // Wait briefly for events to be added to the queue
                await Task.yield()
                continue
            }
            
            // Publish the event to all subscribers
            await subscribersActor.publish(event)
        }
    }
    
    /// Removes and returns the next event from the queue.
    ///
    /// - Returns: The next event in the queue, or `nil` if the queue is empty.
    private func dequeueNextEvent() -> EventType? {
        guard !eventQueue.isEmpty else { return nil }
        return eventQueue.removeFirst()
    }
    
    /// Checks if the queue is empty and clears the processing task if so.
    ///
    /// - Returns: `true` if the queue is empty and the task was cleared, `false` otherwise.
    private func checkAndClearIfEmpty() -> Bool {
        if eventQueue.isEmpty {
            processingTask = nil
            return true
        }
        return false
    }
}

/// An actor that manages event subscribers and publishes events to them.
///
/// This actor maintains a list of subscriber handlers and ensures thread-safe
/// access when adding subscribers or publishing events.
private actor EventSubscribersActor {
    private var subscribers: [@Sendable (EventType) -> Void] = []

    /// Adds a new subscriber to the list.
    ///
    /// - Parameter handler: The closure that will be called when events are published.
    func addSubscriber(_ handler: @escaping @Sendable (EventType) -> Void) {
        subscribers.append(handler)
    }

    /// Publishes an event to all registered subscribers.
    ///
    /// - Parameter event: The event to publish to all subscribers.
    func publish(_ event: EventType) {
        for subscriber in subscribers {
            subscriber(event)
        }
    }
}
