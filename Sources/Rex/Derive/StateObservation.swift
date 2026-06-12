import Foundation

/// A token that cancels a selective state observation when deallocated.
public final class StateObservationToken: Sendable {
    private let onCancel: @Sendable () -> Void

    init(onCancel: @escaping @Sendable () -> Void) {
        self.onCancel = onCancel
    }

    deinit {
        onCancel()
    }
}

/// A minimal readable store interface for selective observation.
public protocol StateReadable: Sendable {
    associatedtype State: Statable
    func subscribeToState(_ handler: @escaping @Sendable (State) -> Void) async
    func currentState() async -> State
}

/// A ``StateReadable`` adapter around ``Store``.
public struct StoreReader<R: Reducer>: StateReadable {
    public typealias State = R.State
    private let store: Store<R>

    public init(_ store: Store<R>) {
        self.store = store
    }

    public func subscribeToState(_ handler: @escaping @Sendable (State) -> Void) async {
        store.subscribe(handler)
    }

    public func currentState() async -> State {
        await store.state
    }
}

private actor StateObserverCore<State: Statable> {
    private var subscribers: [UUID: @Sendable (State) -> Void] = [:]

    func setSubscriber(id: UUID, handler: @escaping @Sendable (State) -> Void) {
        subscribers[id] = handler
    }

    func removeSubscriber(id: UUID) {
        subscribers[id] = nil
    }

    func notify(_ state: State) {
        for subscriber in subscribers.values {
            subscriber(state)
        }
    }
}

/// Selective state observation for UIKit and other non-SwiftUI consumers.
public final class StateObserver<State: Statable>: @unchecked Sendable {
    private let readable: AnyStateReadable<State>
    private let core = StateObserverCore<State>()

    public init<R: Reducer>(_ store: Store<R>) where R.State == State {
        self.readable = AnyStateReadable(StoreReader(store))
        Task {
            await readable.subscribeToState { [core] state in
                Task { await core.notify(state) }
            }
        }
    }

    public init<S: StateReadable>(_ readable: S) where S.State == State {
        self.readable = AnyStateReadable(readable)
        Task {
            await self.readable.subscribeToState { [core] state in
                Task { await core.notify(state) }
            }
        }
    }

    /// Observes a derived slice of state and fires only when the derived value changes.
    @discardableResult
    public func observe<Value: Equatable>(
        _ derive: @escaping @Sendable (State) -> Value,
        onChange: @escaping @Sendable (Value) -> Void
    ) -> StateObservationToken {
        let id = UUID()
        let box = ObservationBox<Value>()

        Task {
            await core.setSubscriber(id: id) { state in
                let value = derive(state)
                guard value != box.value else { return }
                box.value = value
                onChange(value)
            }

            let current = await readable.currentState()
            let value = derive(current)
            box.value = value
            onChange(value)
        }

        return StateObservationToken { [core] in
            Task { await core.removeSubscriber(id: id) }
        }
    }
}

private final class ObservationBox<Value: Equatable>: @unchecked Sendable {
    var value: Value?
}

private struct AnyStateReadable<State: Statable>: StateReadable {
    private let _subscribe: @Sendable (@escaping @Sendable (State) -> Void) async -> Void
    private let _currentState: @Sendable () async -> State

    init<S: StateReadable>(_ base: S) where S.State == State {
        _subscribe = { handler in
            await base.subscribeToState(handler)
        }
        _currentState = {
            await base.currentState()
        }
    }

    func subscribeToState(_ handler: @escaping @Sendable (State) -> Void) async {
        await _subscribe(handler)
    }

    func currentState() async -> State {
        await _currentState()
    }
}

extension Store {
    /// Creates a selective state observer for this store.
    public func observer() -> StateObserver<State> {
        StateObserver(self)
    }
}
