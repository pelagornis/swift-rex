#if canImport(SwiftUI)
import SwiftUI
import Combine

@MainActor
public class ObservableStore<R: Reducer>: ObservableObject where R.S: State & Codable {
    @Published public private(set) var state: R.S
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

    public func send(_ action: R.A) {
        store.dispatch(action)
    }
}

#endif
