import SwiftUI
import Rex

@MainActor
class AppStore: ObservableObject {
    @Published var state: AppState
    let store: Store<AppReducer>

    init(store: Store<AppReducer>) {
        self.store = store
        self.state = store.state

        store.subscribe { [weak self] newState in
            Task { @MainActor in
                self?.state = newState
            }
        }
    }

    func send(_ action: AppAction) {
        store.dispatch(action)
    }
    
    func getEventBus() -> EventBus {
        return store.getEventBus()
    }
}
