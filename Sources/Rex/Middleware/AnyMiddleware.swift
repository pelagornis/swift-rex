public struct AnyMiddleware<S: State, A: Action>: Middleware {
    private let _process: @Sendable (S, A, @escaping (A) -> Void) async -> [Effect<A>]

    public init<M: Middleware>(_ middleware: M) where M.S == S, M.A == A {
        _process = { state, action, emit in
            await middleware.process(state: state, action: action, emit: emit)
        }
    }

    public func process(state: S, action: A, emit: @escaping (A) -> Void) async -> [Effect<A>] {
        await _process(state, action, emit)
    }
}
