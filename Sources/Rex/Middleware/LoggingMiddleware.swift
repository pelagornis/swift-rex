import Foundation

public struct LoggingMiddleware<State: StateType, Action: ActionType>: Middleware {
    
    public init() {}

    public func process(state: State, action: Action, emit: @escaping (Action) -> Void) async -> [Effect<Action>] {
        print("[LOG] action: \(action)")
        return []
    }
}
 
