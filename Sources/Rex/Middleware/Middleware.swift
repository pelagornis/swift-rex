import Foundation

public protocol Middleware: Sendable {
    associatedtype State: StateType
    associatedtype Action: ActionType

    func process(
        state: State,
        action: Action,
        emit: @escaping @Sendable (Action) -> Void
    ) async -> [Effect<Action>]
}
