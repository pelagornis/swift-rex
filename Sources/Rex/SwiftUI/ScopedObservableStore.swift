#if canImport(SwiftUI)
import SwiftUI

/// A scoped view into a parent store, observing only a derived slice of state.
@MainActor
public final class ScopedObservableStore<LocalState: Equatable & Sendable, LocalAction>: ObservableObject {
    @Published public private(set) var state: LocalState
    private let sendAction: (LocalAction) -> Void
    private var token: StateObservationToken?

    public init<R: Reducer>(
        parent: Store<R>,
        derive: @escaping @Sendable (R.State) -> LocalState,
        send: @escaping @Sendable (LocalAction) -> R.Action
    ) where R.State: Statable, R.Action: Actionable {
        self.state = derive(parent.getInitialState())
        self.sendAction = { local in
            parent.dispatch(send(local))
        }

        let observer = StateObserver(parent)
        self.token = observer.observe(derive) { [weak self] value in
            Task { @MainActor in
                self?.state = value
            }
        }
    }

    public init<R: Reducer>(
        observableParent: ObservableStore<R>,
        derive: @escaping @Sendable (R.State) -> LocalState,
        send: @escaping @Sendable (LocalAction) -> R.Action
    ) {
        self.state = derive(observableParent.state)
        self.sendAction = { observableParent.send(send($0)) }

        let observer = StateObserver(observableParent.store)
        self.token = observer.observe(derive) { [weak self] value in
            Task { @MainActor in
                self?.state = value
            }
        }
    }

    public func send(_ action: LocalAction) {
        sendAction(action)
    }
}

extension ObservableStore {
    /// Scopes this store to a child state domain with selective observation.
    public func scope<LocalState: Equatable & Sendable, LocalAction>(
        derive: @escaping @Sendable (State) -> LocalState,
        send: @escaping @Sendable (LocalAction) -> Action
    ) -> ScopedObservableStore<LocalState, LocalAction> {
        ScopedObservableStore(observableParent: self, derive: derive, send: send)
    }

    /// Observes a derived value and refreshes only when it changes.
    @discardableResult
    public func observeDerived<Value: Equatable & Sendable>(
        _ derive: @escaping @Sendable (State) -> Value,
        onChange: @escaping @MainActor (Value) -> Void
    ) -> StateObservationToken {
        StateObserver(store).observe(derive) { value in
            Task { @MainActor in onChange(value) }
        }
    }
}
#endif
