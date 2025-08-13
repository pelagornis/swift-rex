#if canImport(SwiftUI)
import SwiftUI
import Combine

@MainActor
public final class ObservableStore<R: Reducer>: ObservableObject where R.State: StateType {
    @Published public private(set) var state: R.State
    private let store: Store<R>

    public init(store: Store<R>) {
        self.store = store
        self.state = store.state

        store.subscribe { [weak self] newState in
            Task { @MainActor in
                self?.state = newState
            }
        }
    }

    public func send(_ action: R.Action) {
        store.dispatch(action)
    }
}
#endif
