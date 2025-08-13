import Rex

public struct AppState: StateType {
    var count: Int = 0
    var isLoading: Bool = false
    
    public init() {}
}
