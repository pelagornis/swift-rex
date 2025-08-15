import Foundation

public struct EmptyMiddleware<State: StateType, Action: ActionType>: Middleware {
    public init() {}
    public func process(state: State, action: Action, emit: @escaping @Sendable (Action) -> Void) async -> [Effect<Action>] {
        []
    }
}
