import Rex

public enum AppAction: ActionType {
    case increment
    case decrement
    case reset
    case loadFromServer
    case loadedFromServer(Int)
}
