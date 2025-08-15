import Foundation

public struct LoggingMiddleware<State: StateType, Action: ActionType>: Middleware {
    public init() {}

    public func process(
        state: State,
        action: Action,
        emit: @escaping @Sendable (Action) -> Void
    ) async -> [Effect<Action>] {
        print("[LoggingMiddleware] Action: \(action)")
        print("[LoggingMiddleware] State: \(state)")
        return [.none]
    }
}
