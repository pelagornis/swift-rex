import Foundation

/// Combines multiple reducers that share the same state and action types.
public struct CombineReducer<State: Statable, Action: Actionable>: Reducer {
    private let reducers: [AnyReducer<State, Action>]

    public init(_ reducers: [AnyReducer<State, Action>]) {
        self.reducers = reducers
    }

    public func reduce(state: inout State, action: Action) -> [Effect<Action>] {
        var effects: [Effect<Action>] = []
        for reducer in reducers {
            effects.append(contentsOf: reducer.reduce(state: &state, action: action))
        }
        return effects
    }
}

public extension Reducer {
    /// Combines this reducer with another, running both for every action.
    func combine<R: Reducer>(with other: R) -> CombineReducer<State, Action>
    where R.State == State, R.Action == Action {
        CombineReducer([AnyReducer(self), AnyReducer(other)])
    }

    /// Combines this reducer with others, running each in sequence for every action.
    func combine(with others: [AnyReducer<State, Action>]) -> CombineReducer<State, Action> {
        CombineReducer([AnyReducer(self)] + others)
    }
}
