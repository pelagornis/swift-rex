import Foundation

/// A store wrapper for apps using ``GraphStateContainer`` with automatic graph lifecycle management.
///
/// Navigation is modeled as graph movement; popping a node unmounts it and cancels its scoped effects.
public final class GraphStore<R: Reducer>: Sendable where R.State: GraphStateContainer {
    public let store: Store<R>
    public let lifecycleHook: GraphLifecyclePipelineHook<R.State, R.Action>
    private let embedGraphAction: @Sendable (GraphAction) -> R.Action

    public init(
        initialState: R.State,
        reducer: R,
        embedGraphAction: @escaping @Sendable (GraphAction) -> R.Action,
        middlewares: @escaping () -> [AnyMiddleware<R.State, R.Action>] = { [] },
        pipelineHooks: @escaping () -> [AnyPipelineHook<R.State, R.Action>] = { [] },
        timeTravel: TimeTravelPipelineHook<R.State, R.Action>? = nil,
        eventBus: EventBus = EventBus()
    ) {
        let lifecycleHook = GraphLifecyclePipelineHook<R.State, R.Action>()
        self.lifecycleHook = lifecycleHook
        self.embedGraphAction = embedGraphAction
        self.store = Store(
            initialState: initialState,
            reducer: reducer,
            middlewares: middlewares,
            pipelineHooks: {
                var hooks = pipelineHooks()
                hooks.append(AnyPipelineHook(lifecycleHook))
                return hooks
            },
            timeTravel: timeTravel,
            eventBus: eventBus
        )
        store.bindGraphLifecycle(lifecycleHook)
    }

    public func dispatch(_ action: R.Action) {
        store.dispatch(action)
    }

    public func push(_ id: GraphNodeID, parent: GraphNodeID? = nil, dependency: String? = nil) {
        dispatch(embedGraphAction(.push(id, parent: parent, dependency: dependency)))
    }

    public func pop() {
        dispatch(embedGraphAction(.pop))
    }

    public func popTo(_ id: GraphNodeID) {
        dispatch(embedGraphAction(.popTo(id)))
    }

    public func popToRoot() {
        dispatch(embedGraphAction(.popToRoot))
    }

    public func cancelEffect(id: EffectID) {
        store.cancelEffect(id: id)
    }

    public func subscribe(_ subscriber: @escaping @Sendable (R.State) -> Void) {
        store.subscribe(subscriber)
    }
}
