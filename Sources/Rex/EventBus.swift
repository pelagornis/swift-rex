import Foundation

public final class EventBus: Sendable {
    private let subscribersActor: EventSubscribersActor
    private let lock = NSLock()

    public init() {
        self.subscribersActor = EventSubscribersActor()
    }

    @MainActor
    public func publish(_ event: EventType) {
        Task {
            await subscribersActor.publish(event)
        }
    }

    @MainActor
    public func subscribe(handler: @escaping @Sendable (EventType) -> Void) {
        Task {
            await subscribersActor.addSubscriber(handler)
        }
    }

    @MainActor
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

    @MainActor
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

private actor EventSubscribersActor {
    private var subscribers: [@Sendable (EventType) -> Void] = []

    func addSubscriber(_ handler: @escaping @Sendable (EventType) -> Void) {
        subscribers.append(handler)
    }

    func publish(_ event: EventType) {
        for subscriber in subscribers {
            subscriber(event)
        }
    }
}
