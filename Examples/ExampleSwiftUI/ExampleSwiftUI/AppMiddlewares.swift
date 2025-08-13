import Rex

public struct LoggingMiddleware: Middleware {
    public init() {}

    public func process(state: AppState, action: AppAction, emit: @escaping (AppAction) -> Void) async -> [Effect<AppAction>] {
        print("[LoggingMiddleware] Action: \(action), State before: \(state)")
        return [.none]
    }
}
