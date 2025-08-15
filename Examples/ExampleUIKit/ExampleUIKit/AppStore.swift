import SwiftUI
import Rex

@MainActor
public class AppStore: ObservableObject {
    @Published var state: AppState
    private let store: Store<AppReducer>

    init(store: Store<AppReducer>) {
        self.store = store
        self.state = store.getInitialState()

        store.subscribe { [weak self] newState in
            Task { @MainActor in
                self?.state = newState
            }
        }
    }

    public func send(_ action: AppAction) {
        store.dispatch(action)
    }
}
