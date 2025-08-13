import Foundation

public struct LoggingMiddleware<S: State, A: Action>: Middleware {
    
    public init() {}

    public func process(state: S, action: A, emit: @escaping (A) -> Void) async -> [Effect<A>] {
        print("[LOG] action: \(action)")
        return []
    }
}
 
