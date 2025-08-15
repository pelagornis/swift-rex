import Foundation

public final class MiddlewareChain<State: StateType, Action: ActionType> {
    private var middlewares: [AnyMiddleware<State, Action>] = []

    public init(_ middlewares: [AnyMiddleware<State, Action>] = []) {
        self.middlewares = middlewares
    }

    public func append(_ middleware: AnyMiddleware<State, Action>) {
        middlewares.append(middleware)
    }

    public func process(state: State, action: Action, emit: @Sendable @escaping (Action) -> Void) async -> [Effect<Action>] {
        var effects: [Effect<Action>] = []
        for middleware in middlewares {
            let newEffects = await middleware.process(state: state, action: action, emit: emit)
            effects.append(contentsOf: newEffects)
        }
        return effects
    }
}
