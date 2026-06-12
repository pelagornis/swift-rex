import Rex

@MainActor
public final class AppEnvironment {
    public let graphStore: GraphStore<AppReducer>
    public let store: Store<AppReducer>

    public init() {
        let graphStore = GraphStore(
            initialState: AppState(),
            reducer: AppReducer(),
            embedGraphAction: { .graph($0) },
            pipelineHooks: {
                [AnyPipelineHook(LoggingPipelineHook(label: "GameApp"))]
            }
        )
        self.graphStore = graphStore
        self.store = graphStore.store
    }
}
