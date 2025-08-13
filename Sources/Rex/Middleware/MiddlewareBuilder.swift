import Foundation

@resultBuilder
public struct MiddlewareBuilder<State: StateType, Action: ActionType> {
    public static func buildBlock<M: Middleware>(_ components: M...) -> [AnyMiddleware<State, Action>] where M.State == State, M.Action == Action {
        components.map { AnyMiddleware($0) }
    }

    public static func buildBlock() -> [AnyMiddleware<State, Action>] {
        [AnyMiddleware(EmptyMiddleware<State, Action>())]
    }
}
