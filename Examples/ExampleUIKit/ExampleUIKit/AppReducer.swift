import Foundation
import Combine
import Rex

struct AppReducer: Reducer {
    func reduce(state: inout AppState, action: AppAction) -> [Effect<AppAction>] {
        switch action {
        case .increment:
            state.count += 1
            return [.none]
        case .decrement:
            state.count -= 1
            return [.none]
        case .reset:
            state.count = 0
            return [.none]
        case .loadFromServer:
            state.isLoading = true
            return [
                Effect { emitter in
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    await emitter.withValue { emitter in
                        await emitter.send(.loadedFromServer(500))
                    }
                }
            ]
        case .loadedFromServer(let value):
            state.count = value
            state.isLoading = false
            return [.none]
        }
    }
}
