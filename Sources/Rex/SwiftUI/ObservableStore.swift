#if canImport(SwiftUI)
import SwiftUI

@MainActor
public final class ObservableStore<R: Reducer>: ObservableObject, Sendable {
    private let store: Store<R>
    @Published public private(set) var state: R.State

    public init(store: Store<R>) {
        self.store = store
        self.state = store.getInitialState()

        Task {
            store.subscribe { [weak self] newState in
                Task { @MainActor in
                    self?.state = newState
                }
            }
        }
    }

    public func send(_ action: R.Action) {
        store.dispatch(action)
    }

    public func getEventBus() -> EventBus {
        return store.getEventBus()
    }
}
#endif
