import Foundation

public protocol Reducer {
    associatedtype State: StateType
    associatedtype Action: ActionType

    func reduce(state: inout State, action: Action) -> [Effect<Action>]
}
