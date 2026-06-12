import SwiftUI
import Combine
import Rex

@MainActor
final class AppEnvironment: ObservableObject {
    let graphStore: GraphStore<AppReducer>
    let observableStore: ObservableStore<AppReducer>
    private var storeChangeSubscription: AnyCancellable?

    init() {
        let graphStore = GraphStore(
            initialState: AppState(),
            reducer: AppReducer(),
            embedGraphAction: { .graph($0) },
            pipelineHooks: {
                [AnyPipelineHook(LoggingPipelineHook(label: "ChatApp"))]
            }
        )
        self.graphStore = graphStore
        self.observableStore = ObservableStore(store: graphStore.store)

        // Forward ObservableStore updates so views observing AppEnvironment re-render.
        storeChangeSubscription = observableStore.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
    }
}
