public struct AnyMiddleware<State: StateType, Action: ActionType>: Middleware {
    private let _process: @Sendable (State, Action, @escaping (Action) -> Void) async -> [Effect<Action>]

    public init<M: Middleware>(_ middleware: M) where M.State == State, M.Action == Action {
        _process = { state, action, emit in
            await middleware.process(state: state, action: action, emit: emit)
        }
    }

    public func process(state: State, action: Action, emit: @escaping (Action) -> Void) async -> [Effect<Action>] {
        await _process(state, action, emit)
    }
}
