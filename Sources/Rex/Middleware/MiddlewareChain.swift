import Foundation

public final class MiddlewareChain<S: State, A: Action> {
    private var middlewares: [AnyMiddleware<S, A>] = []

    public init(_ middlewares: [AnyMiddleware<S, A>] = []) {
        self.middlewares = middlewares
    }

    public func append(_ middleware: AnyMiddleware<S, A>) {
        middlewares.append(middleware)
    }

    public func process(state: S, action: A, emit: @escaping (A) -> Void) async -> [Effect<A>] {
        var effects: [Effect<A>] = []
        for middleware in middlewares {
            let newEffects = await middleware.process(state: state, action: action, emit: emit)
            effects.append(contentsOf: newEffects)
        }
        return effects
    }
}
