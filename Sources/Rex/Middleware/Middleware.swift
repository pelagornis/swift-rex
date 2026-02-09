import Foundation

public protocol Middleware: Sendable {
    associatedtype State: StateProtocol
    associatedtype Action: ActionProtocol

    func process(
        state: State,
        action: Action,
        emit: @escaping @Sendable (Action) -> Void
    ) async -> [Effect<Action>]
}
