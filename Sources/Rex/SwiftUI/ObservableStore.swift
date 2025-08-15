#if canImport(SwiftUI)
import SwiftUI
import Combine

@MainActor
public final class ObservableStore<R: Reducer>: ObservableObject, Sendable {
    private let store: Store<R>
    @Published public private(set) var state: R.State
    private let cancellablesActor: CancellablesActor

    public init(store: Store<R>) {
        self.store = store
        self.state = R.State() // 임시 초기값
        self.cancellablesActor = CancellablesActor()

        Task {
            self.state = await store.state
            
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

private actor CancellablesActor {
    var cancellables: Set<AnyCancellable> = []

    func add(_ cancellable: AnyCancellable) {
        cancellables.insert(cancellable)
    }

    func removeAll() {
        cancellables.removeAll()
    }
}
#endif
