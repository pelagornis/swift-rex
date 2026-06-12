import Foundation

/// A thread-safe store that manages application state using the Redux pattern.
///
/// Actions flow through an ``ActionPipeline`` with hooks, then the reducer, then reactive effects.
public final class Store<R: Reducer>: Sendable {
    /// State type from the reducer.
    public typealias State = R.State
    /// Action type from the reducer.
    public typealias Action = R.Action

    private let dispatchActor: DispatchActor<R.State, R.Action, R>
    private let stateActor: StateActor<R.State>
    private let subscribersActor: SubscribersActor<R.State>
    private let effectRunner: EffectRunner<R.Action>
    private let timeTravelHook: TimeTravelPipelineHook<R.State, R.Action>?
    private let eventBus: EventBus
    private let initialState: R.State

    /// Creates a new Store instance.
    ///
    /// - Parameters:
    ///   - initialState: The initial state of the application.
    ///   - reducer: The reducer that processes actions and updates state.
    ///   - middlewares: Legacy middleware adapters (run at `willReceive`). Prefer ``pipelineHooks``.
    ///   - pipelineHooks: Pipeline 2.0 hooks for logging, analytics, and time travel.
    ///   - timeTravel: When set, automatically appended to pipeline hooks and exposed via ``undoTimeTravel()`` / ``redoTimeTravel()``.
    ///   - eventBus: An optional EventBus for cross-component communication.
    public init(
        initialState: R.State,
        reducer: R,
        middlewares: @escaping () -> [AnyMiddleware<R.State, R.Action>] = { [] },
        pipelineHooks: @escaping () -> [AnyPipelineHook<R.State, R.Action>] = { [] },
        timeTravel: TimeTravelPipelineHook<R.State, R.Action>? = nil,
        eventBus: EventBus = EventBus()
    ) {
        self.stateActor = StateActor(initialState)
        self.subscribersActor = SubscribersActor()
        self.effectRunner = EffectRunner()
        self.timeTravelHook = timeTravel
        self.eventBus = eventBus
        self.initialState = initialState

        var hooks = pipelineHooks()
        hooks.append(contentsOf: middlewares().map { AnyPipelineHook(MiddlewarePipelineHook($0)) })
        if let timeTravel {
            hooks.append(AnyPipelineHook(timeTravel))
        }

        self.dispatchActor = DispatchActor(
            stateActor: stateActor,
            subscribersActor: subscribersActor,
            reducer: reducer,
            hooks: hooks,
            effectRunner: effectRunner
        )
    }

    /// The current state of the store.
    public var state: R.State {
        get async {
            await stateActor.state
        }
    }

    /// Returns the initial state that was used when creating the store.
    public func getInitialState() -> R.State {
        initialState
    }

    /// Dispatches an action through the pipeline.
    public func dispatch(_ action: R.Action) {
        Task {
            await dispatchActor.dispatch(action) { [weak self] action in
                self?.dispatch(action)
            }
        }
    }

    /// Subscribes to state changes.
    public func subscribe(_ subscriber: @escaping @Sendable (R.State) -> Void) {
        Task {
            await subscribersActor.addSubscriber(subscriber)
            let currentState = await stateActor.state
            subscriber(currentState)
        }
    }

    /// Cancels a running effect by id.
    public func cancelEffect(id: EffectID) {
        Task {
            await effectRunner.cancel(id: id)
        }
    }

    /// Cancels all tracked long-lived effects.
    public func cancelAllEffects() {
        Task {
            await effectRunner.cancelAll()
        }
    }

    /// Steps backward in time-travel history and applies the state when available.
    @discardableResult
    public func undoTimeTravel() async -> R.State? {
        guard let timeTravelHook else { return nil }
        guard let restored = await timeTravelHook.undo() else { return nil }
        await stateActor.setState(restored)
        await subscribersActor.notifySubscribers(restored)
        return restored
    }

    /// Steps forward in time-travel history and applies the state when available.
    @discardableResult
    public func redoTimeTravel() async -> R.State? {
        guard let timeTravelHook else { return nil }
        guard let restored = await timeTravelHook.redo() else { return nil }
        await stateActor.setState(restored)
        await subscribersActor.notifySubscribers(restored)
        return restored
    }

    /// Returns the EventBus associated with this store.
    @MainActor
    public func getEventBus() -> EventBus {
        eventBus
    }

    func bindGraphLifecycle(_ hook: GraphLifecyclePipelineHook<R.State, R.Action>) where R.State: GraphStateContainer {
        hook.bind(effectRunner: effectRunner)
    }
}

private actor DispatchActor<State, Action, R: Reducer> where R.State == State, R.Action == Action {
    private let stateActor: StateActor<State>
    private let subscribersActor: SubscribersActor<State>
    private let pipeline: ActionPipeline<State, Action, R>
    private let effectRunner: EffectRunner<Action>
    private var queuedActions: [Action] = []
    private var isDrainingQueue = false

    init(
        stateActor: StateActor<State>,
        subscribersActor: SubscribersActor<State>,
        reducer: R,
        hooks: [AnyPipelineHook<State, Action>],
        effectRunner: EffectRunner<Action>
    ) {
        self.stateActor = stateActor
        self.subscribersActor = subscribersActor
        self.effectRunner = effectRunner
        self.pipeline = ActionPipeline(hooks: hooks, reducer: reducer)
    }

    func dispatch(
        _ action: Action,
        dispatchCallback: @escaping @Sendable (Action) -> Void
    ) async {
        queuedActions.append(action)
        guard !isDrainingQueue else { return }

        isDrainingQueue = true
        while !queuedActions.isEmpty {
            let next = queuedActions.removeFirst()
            await process(next, dispatchCallback: dispatchCallback)
        }
        isDrainingQueue = false
    }

    private func process(
        _ action: Action,
        dispatchCallback: @escaping @Sendable (Action) -> Void
    ) async {
        let stateBefore = await stateActor.state

        guard let result = await pipeline.process(
            action,
            stateBefore: stateBefore,
            dispatchCallback: dispatchCallback
        ) else {
            return
        }

        if !result.preReducerEffects.isEmpty {
            await effectRunner.run(result.preReducerEffects, dispatch: dispatchCallback)
        }

        await stateActor.setState(result.stateAfter)
        await subscribersActor.notifySubscribers(result.stateAfter)

        if !result.postReducerEffects.isEmpty {
            await effectRunner.run(result.postReducerEffects, dispatch: dispatchCallback)
        }
    }
}
