import Foundation

public protocol Middleware: Sendable {
    associatedtype State: Statable
    associatedtype Action: Actionable

    func process(
        state: State,
        action: Action,
        emit: @escaping @Sendable (Action) -> Void
    ) async -> [Effect<Action>]
}
