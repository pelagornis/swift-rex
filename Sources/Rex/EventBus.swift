import Foundation
@preconcurrency import Combine

public final class EventBus: Sendable {
    private let subject = PassthroughSubject<EventType, Never>()

    public init() {}

    @MainActor
    public func publish(_ event: EventType) {
        subject.send(event)
    }

    @MainActor
    public func subscribe(handler: @escaping @Sendable (EventType) -> Void) -> AnyCancellable {
        return subject.sink { event in
            handler(event)
        }
    }

    @MainActor
    public func subscribe<T: EventType>(
        to eventType: T.Type,
        handler: @escaping @Sendable (T) -> Void
    ) -> AnyCancellable {
        return subject
            .compactMap { $0 as? T }
            .sink { event in
                handler(event)
            }
    }

    @MainActor
    public func subscribe<T: EventType>(
        to eventType: T.Type,
        where filter: @escaping @Sendable (T) -> Bool,
        handler: @escaping @Sendable (T) -> Void
    ) -> AnyCancellable {
        return subject
            .compactMap { $0 as? T }
            .filter(filter)
            .sink { event in
                handler(event)
            }
    }
}
